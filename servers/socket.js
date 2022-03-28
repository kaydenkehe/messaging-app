const nodemailer = require('nodemailer');
const socketio = require('socket.io');
const express = require('express');
const sqlite = require('sqlite3');
const http = require('http');
const fs = require('fs');

const app = express();
const server = http.createServer(app);
const io = socketio(server);

const PORT = 8456
const DBLOC = '../storage/appdb.db'; // Location of DB
const EMAIL = 'appemailconfirmer@gmail.com';
const PW = '$kSC?x4cFVS5zxLd';


io.on('connection', socket => {
    // Log number of active connections
    server.getConnections(function(err, count) {
        console.log(`[CONNECTION] New connection from ${socket.handshake.address} | Active connections: ${count}`);
    });

    // Add user to room (group)
    socket.on('join_room', info_dict => {
        room = info_dict['room'];
        socket.join(room);
    });

    // Grab messages for user. Happens when they load group or scroll up
    socket.on('get_messages', info_dict => {
        room = info_dict['room'];
        offset = Number(info_dict['num_scrolled']) * 15;

        db = new sqlite.Database(DBLOC);
        db.serialize(function() {
            db.all(`SELECT messages.content, users.username FROM messages, users WHERE (users.user_id = messages.sender_id AND group_id = (SELECT group_id FROM groups WHERE group_name = '${room}')) ORDER BY message_id DESC LIMIT 15 OFFSET ${offset};`, (err, rows) => {
                messages = [];
                usernames = [];
                profile_pictures = [];
                
                // Add the data for all the messages to the three lists
                rows.forEach(row => {
                    messages.push(row['content'].replaceAll('|@|', "'")); // The '|@|' is used to make the program not break when someone sends a message with a comma
                    usernames.push(row['username']);
                    profile_pictures.push(fs.readFileSync(`../storage/pfp_downscale/${row['username']}.png`, 'base64'))
                });

                firstMessagesDict = {
                    'messages': messages,
                    'usernames': usernames,
                    'profile_pictures': profile_pictures
                };
                socket.emit('get_first_messages', firstMessagesDict);
            });
            db.close();
        });
    });

    // Message sent by user
    socket.on('send_message', info_dict => {
        room = info_dict['room'];
        username = info_dict['username'];
        content = info_dict['content'];

        db = new sqlite.Database(DBLOC);
        db.serialize(function() {
            // Write message to db
            db.run(
                `INSERT INTO messages (sender_id, group_id, content)
                VALUES (
                    (SELECT user_id FROM users WHERE username = '${username}'),
                    (SELECT group_id FROM groups WHERE group_name = '${room}'),
                    '${content.replaceAll("'", '|@|')}'
                );`
            );

            messageDict = {
                'content': content.replaceAll('|@|', "'"),
                'username': username,
                'profile_picture': fs.readFileSync(`../storage/pfp_downscale/${username}.png`, 'base64') // Convert raw image data to base 64
            };

            io.to(room).emit('broadcast_message', messageDict); // Broadcast message to entire room
            db.close();
        });
    });

    // Email verification code
    socket.on('email_code', info_dict => {
        email = info_dict['email'];
        socket.code = Math.floor(Math.random() * (1000000 - 100000) + 100000).toString(); // Create random 6 digit numerical code and attribute it to the socket connection

        transport = nodemailer.createTransport({
            service: 'gmail',
            auth: {user: EMAIL, pass: PW}
        });
        
        mail_info = {
            from: EMAIL,
            to: email,
            subject: 'Email Verification',
            text: `Your verification code is: ${socket.code}`
        };
        
        // Send email with code
        transport.sendMail(mail_info, function(err) {

        });
    });

    socket.on('submit_code', info_dict => {
        code = info_dict['code'];
        if (code == socket.code) {
            socket.emit('code_response', {'msg': 'success'});
        } else {
            socket.emit('code_response', {'msg': 'bad'});
        }
    });
});


// Run server
server.listen(PORT, () => console.log(`[SERVER] Running on port ${PORT}`));
