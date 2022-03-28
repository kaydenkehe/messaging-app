const sqlite = require('sqlite3');
const crypto = require('crypto');
const sharp = require('sharp');
var http = require('http');
var url = require('url');
const fs = require('fs');

const PORT = 8457;
const DBLOC = '../storage/appdb.db'; // Location of DB

// All of the requests sent by the client are GETs
// The server gets the information it needs from url queries
var server = http.createServer(function (req, res) {
    query_dict = url.parse(req.url, true).query; // Get URL queries as dictionary
    response_dict = {}; // Dictionary where response information will be written

    // Make sure server is active
    if (url.parse(req.url, false).pathname == '/test_api') {
        res.write('working');
        res.end();
    }

    // Login
    if (url.parse(req.url, false).pathname == '/login') {
        username = query_dict['username'];
        password = query_dict['password'];

        db = new sqlite.Database(DBLOC);
        db.serialize(function() {
            db.all(`SELECT password, salt, user_id FROM users WHERE username = '${username}'`, (err, rows) => {
                if (rows.length > 0) {
                    if (rows[0]['password'] == crypto.createHash('sha512').update(rows[0]['salt'] + password).digest('hex')) { // Check actual password with given password
                        response_dict['msg'] = 'success';
                        response_dict['userid'] = rows[0]['user_id']
                        res.write(JSON.stringify(response_dict));
                        res.end();
                    } else { // If password is incorrect
                        response_dict['msg'] = 'bad';
                        res.write(JSON.stringify(response_dict));
                        res.end();
                    }
                } else { // If username doesn't exist
                    response_dict['msg'] = 'bad';
                    res.write(JSON.stringify(response_dict));
                    res.end();
                };
            });
            db.close();
        });
    };

    // Check if username exists
    if (url.parse(req.url, false).pathname == '/check_username') {
        username = query_dict['username'];

        db = new sqlite.Database(DBLOC);
        db.serialize(function() {
            db.all(`SELECT user_id FROM users WHERE username = '${username}'`, (err, rows) => {
                if (rows.length > 0) { // Check whether content exists in DB
                    response_dict['msg'] = 'exist';
                    res.write(JSON.stringify(response_dict));
                    res.end();
                } else {
                    response_dict['msg'] = 'not_exist';
                    res.write(JSON.stringify(response_dict));
                    res.end();
                }
            });
        });
    }

    // Create account
    if (url.parse(req.url, false).pathname == '/create_account') {
        username = query_dict['username'];
        email = query_dict['email'];
        password = query_dict['password'];

        // Generate salt and use it with password to create hash
        salt = Math.random().toString(16).substr(2, 8); // https://attacomsian.com/blog/javascript-generate-random-string
        hashed = crypto.createHash('sha512').update(salt + password).digest('hex');
        
        db = new sqlite.Database(DBLOC);
        db.serialize(function() {
            // Insert new user into db
            db.run(
                `INSERT INTO users (username, password, salt, email)
                VALUES ('${username}', '${hashed}', '${salt}', '${email}');`
            );

            // Get ID of new user and send it to client
            db.all(`SELECT user_id FROM users WHERE username = '${username}'`, (err, rows) => {
                response_dict['msg'] = 'success';
                response_dict['userid'] = String(rows[0]['user_id']);
                response_dict['username'] = username,
                res.write(JSON.stringify(response_dict));
                res.end();
            });
            db.close();
        });     
    };

    // Get info about user (Used when client views their account page)
    if (url.parse(req.url, false).pathname == '/get_user_info') {
        id = query_dict['id'];

        db = new sqlite.Database(DBLOC);
        db.serialize(function() {
            db.all(`SELECT email, username FROM users WHERE user_id = '${id}'`, (err, rows) => {
                response_dict['msg'] = 'success';
                response_dict['email'] = rows[0]['email'];
                response_dict['username'] = rows[0]['username'],
                response_dict['pfp'] = fs.readFileSync(`../storage/pfp/${rows[0]['username']}.png`, 'base64'); // Convert profile pic to base64 and send it with username and email
                res.write(JSON.stringify(response_dict));
                res.end();
            });
            db.close();
        });
    };

    // See if user exists (Used when adding user to group)
    if (url.parse(req.url, false).pathname == '/check_user_existence') {
        username = query_dict['username'];

        db = new sqlite.Database(DBLOC);
        db.serialize(function() {
            db.all(`SELECT user_id FROM users WHERE username = '${username}'`, (err, rows) => {
                if (rows.length > 0) {
                    response_dict['msg'] = 'success';
                    res.write(JSON.stringify(response_dict));
                    res.end();
                } else {
                    response_dict['msg'] = 'bad';
                    res.write(JSON.stringify(response_dict));
                    res.end();
                };
            });
        db.close();
        });
    };

    // Create group
    if (url.parse(req.url, false).pathname == '/create_group') {
        usernames_raw = query_dict['usernames'];
        
        // Convert stringified list into js list object
        if (usernames_raw.length > 2) {
            usernames = usernames_raw.replace('[', '').replace(']', '').split(', ');
        } else {
            usernames = [];
        };

        group_name = query_dict['group_name'];
        user_id = query_dict['user_id'];

        db = new sqlite.Database(DBLOC);
        db.serialize(function() {
            db.all(`SELECT group_id FROM groups WHERE group_name = '${group_name}'`, (err, rows) => {
                if (rows.length > 0) { // Group name is already in use
                    response_dict['msg'] = 'group_exists';
                    res.write(JSON.stringify(response_dict));
                    res.end();
                    db.close();
                } else {
                    db.serialize(function() {
                        // Create group
                        db.run(
                            `INSERT INTO groups (group_name)
                            VALUES ('${group_name}');`
                        );
                        // Add creating user to group and make them admin
                        db.run(
                            `INSERT INTO user_groups (user_id, group_id, is_admin)
                            VALUES (
                                (SELECT user_id FROM users WHERE user_id = '${user_id}'),
                                (SELECT group_id FROM groups WHERE group_name = '${group_name}'),
                                1
                            );`
                        );
                        // Add other users to group
                        for (var username of usernames) {
                            db.run(
                                `INSERT INTO user_groups (user_id, group_id, is_admin)
                                VALUES (
                                    (SELECT user_id FROM users WHERE username = '${username}'),
                                    (SELECT group_id FROM groups WHERE group_name = '${group_name}'),
                                    0
                                );`
                            );
                        };

                        response_dict['msg'] = 'success';
                        res.write(JSON.stringify(response_dict));
                        res.end();
                        db.close();
                    });
                };
            });
        });        
    };

    // Get all groups a particular user is in
    if (url.parse(req.url, false).pathname == '/get_user_groups') {
        id = query_dict['id'];

        db = new sqlite.Database(DBLOC);
        db.serialize(function() {
            db.all(`SELECT group_name FROM groups WHERE group_id IN (SELECT group_id FROM user_groups WHERE user_id = '${id}');`, (err, rows) => {
                if (rows.length > 0) {
                    groups = [];

                    rows.forEach(row => {
                        groups.push(row['group_name']);
                    });

                    response_dict['msg'] = 'success';
                    response_dict['group_names'] = groups;
                    res.write(JSON.stringify(response_dict));
                    res.end();
                };
            });
            db.close();
        });
    };

    // Find out if given user is admin of given group
    if (url.parse(req.url, false).pathname == '/get_user_admin') {
        user_id = query_dict['user_id'];
        group_name = query_dict['group_name'];

        db = new sqlite.Database(DBLOC);
        db.serialize(function() {
            db.all(`SELECT is_admin FROM user_groups WHERE (group_id = (SELECT group_id FROM groups WHERE group_name = '${group_name}') AND  user_id = '${user_id}');`, (err, rows) => {
                if (rows[0]['is_admin'] == '1') {
                    result = 'yes';
                } else {
                    result = 'no';
                };

                response_dict['msg'] = result;
                res.write(JSON.stringify(response_dict));
                res.end();
            });
            db.close();
        });
    };

    // Get name of all users in a group
    if (url.parse(req.url, false).pathname == '/get_users_in_group') {
        group_name = query_dict['group_name'];

        db = new sqlite.Database(DBLOC);
        db.serialize(function() {
            db.all(`SELECT username FROM users WHERE user_id IN (SELECT user_id FROM user_groups WHERE group_id IN (SELECT group_id FROM groups WHERE group_name = '${group_name}'));`, (err, rows) => {
                usernames = []
                
                // Loop through rows and push usernames to list
                rows.forEach(row => {
                    usernames.push(row['username']);
                });

                response_dict['msg'] = 'success';
                response_dict['usernames'] = usernames;
                res.write(JSON.stringify(response_dict));
                res.end();
            });
            db.close();
        });
    };

    // Add user to group
    if (url.parse(req.url, false).pathname == '/add_user') {
        group_name = query_dict['group_name'];
        username = query_dict['username'];

        db = new sqlite.Database(DBLOC);
        db.serialize(function() {
            db.run(
                `INSERT INTO user_groups (user_id, group_id, is_admin)
                VALUES (
                    (SELECT user_id FROM users WHERE username = '${username}'),
                    (SELECT group_id FROM groups WHERE group_name = '${group_name}'),
                    0
                );`
            ); 
            response_dict['msg'] = 'success';
            res.write(JSON.stringify(response_dict));
            res.end();
            db.close();
        });
    };

    // Remove user from group
    if (url.parse(req.url, false).pathname == '/remove_user') {
        group_name = query_dict['group_name'];
        username = query_dict['username'];

        db = new sqlite.Database(DBLOC);
        db.serialize(function() {
            db.run(`DELETE FROM user_groups WHERE (group_id = (SELECT group_id FROM groups WHERE group_name = '${group_name}') AND user_id = (SELECT user_id FROM users WHERE username = '${username}'));`); 
            response_dict['msg'] = 'success';
            res.write(JSON.stringify(response_dict));
            res.end();
            db.close();
        });
    };

    // Delete group
    if (url.parse(req.url, false).pathname == '/delete_group') {
        group_name = query_dict['group_name'];

        db = new sqlite.Database(DBLOC);
        db.serialize(function() {
            db.run(`DELETE FROM user_groups WHERE group_id = (SELECT group_id FROM groups WHERE group_name = '${group_name}');`);
            db.run(`DELETE FROM messages WHERE group_id = (SELECT group_id FROM groups WHERE group_name = '${group_name}');`);
            db.run(`DELETE FROM groups WHERE group_name = '${group_name}';`);

            response_dict['msg'] = 'success';
            res.write(JSON.stringify(response_dict));
            res.end();
            db.close();
        });
    };

    // Set profile picture
    if (url.parse(req.url, false).pathname == '/set_pfp' && req.method == "POST") {
        username = query_dict['username'];

        buffer = '';
        req.on('data', chunk => {
            buffer += chunk;
        });
        req.on('end', () => {
            body = JSON.parse(buffer);
            // Write high-res and low-res versions of photo to file as base 64
            sharp(Buffer.from(body['pfp'], 'base64')).resize({height:256, width:256}).toFile(`../storage/pfp/${username}.png`)
            sharp(Buffer.from(body['pfp'], 'base64')).resize({height:64, width:64}).toFile(`../storage/pfp_downscale/${username}.png`)
            response_dict['msg'] = 'success';
            res.write(JSON.stringify(response_dict));
            res.end();
        });
    };
});


// Run server
server.listen(PORT, () => console.log(`[SERVER] Running on port ${PORT}`));
