import 'package:socket_io_client/socket_io_client.dart' as io;
import 'package:image_picker/image_picker.dart';
import 'package:get_storage/get_storage.dart';
import 'package:http/http.dart' as requests;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:typed_data';
import 'dart:convert';
import 'dart:io';

void main() async {
  await GetStorage.init();
  runApp(const App());
}

String ip = '72.192.95.115'; // IP for requests and socket
// Socket
io.Socket socket = io.io('ws://$ip:8456', <String, dynamic> {
      'transports': ['websocket'],
      'autoConnect': false,
});
final storage = GetStorage();
String activeGroupName = '';

// Colors
// https://dribbble.com/shots/10750209-Interior-Mobile-App
// Credit to: Anastasia Marinicheva
var textColor = const Color(0xFFFFF4E8);
var textColorDark = const Color(0xFFACCDDD);
var backgroundColor = const Color(0xFF325261);
var backgroundColorDark = const Color(0xFF234050);
var backgroundColorLight = const Color(0xFF607B89);
var activeColor = const Color(0xFFF5B688);
var activeColorDark = const Color(0xFFCF997B);
var activeColorLight = const Color(0xFFEBCFB0);


//! --- MATERIALAPP ---


class App extends StatelessWidget {
  const App({ Key? key }) : super(key: key);

  // Route user to login or home depending on whether they are logged in or not
  getInitialRoute() {
    if (storage.read('userid') != null) {
      return '/home';
    }
    return '/login';
  }

  @override
  Widget build(BuildContext context) {
    SystemChrome.setPreferredOrientations([
        DeviceOrientation.portraitUp,
    ]);
    return MaterialApp (
      theme: ThemeData (
        fontFamily: 'Comfortaa',
        scaffoldBackgroundColor: backgroundColor
      ),
      initialRoute: getInitialRoute(),
      routes: {
        // Login section
        '/login': (context) => const LoginPage(),

        '/login/create_account': (context) => const CreateAccountPage(),
        '/login/create_account/verify_email': (context) => const VerifyEmailPage(),


        // Home section
        '/home': (context) => const HomePage(),
        '/home/profile': (context) => const ProfilePage(),
        '/home/create_group': (context) => const CreateGroupPage(),

        '/home/group': (context) => const GroupTextPage(),
        '/home/group/settings': (context) => const GroupSettingsPage(),
        '/home/group/leave': (context) => const GroupLeavePage(),
      },

      debugShowCheckedModeBanner: false,
      builder: (context, child) {
        // I got this bit of code from here:
        // https://stackoverflow.com/questions/59143443/how-to-make-flutter-app-font-size-independent-from-device-settings
        // This makes the font size independent of the device settings
        return MediaQuery (
          child: child!,
          data: MediaQuery.of(context).copyWith(textScaleFactor: 1.0),
        );
      },
    );
  }
}


//! --- LOGIN PAGE ---


class LoginPage extends StatefulWidget {
  const LoginPage({ Key? key }) : super(key: key);

  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  bool obscurePassword = true;
  var passwordVisibleIcon = Icon (
      Icons.remove_red_eye_outlined,
      color: activeColor
    );

  TextEditingController passwordController = TextEditingController();
  TextEditingController usernameController = TextEditingController();

  loginSubmit() async {
    String username = usernameController.text;
    String password = passwordController.text;

    var queries = {
      'username': username,
      'password': password,
    };
    var response = await sendRequest('login', queries, context);
        if (response['msg'] == 'bad') {
      alert('Incorrect username or password', context);
    } else if (response['msg'] == 'success') {
      storage.write('userid', response['userid']);
      storage.write('username', username);
      Navigator.of(context).pushNamedAndRemoveUntil('/home', (Route<dynamic> route) => false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold (
      backgroundColor: backgroundColorDark,
      resizeToAvoidBottomInset: false, 
      body: Center (
        child: Column (
          children: [
            Container (
              margin: EdgeInsets.only(bottom: MediaQuery.of(context).size.height / 20, top: MediaQuery.of(context).size.height / 10),
              child: Text (
                'Chatty',
                style: TextStyle (
                  fontSize: 70.0,
                  color: textColor
                )
              ),
            ),
            Expanded (
              child: Container (
                width: double.infinity,
                padding: const EdgeInsets.only(top: 30.0, left: 30.0, right: 30.0, bottom: 15.0),
                decoration: BoxDecoration (
                  color: backgroundColor,
                  borderRadius: const BorderRadius.only (
                    topRight: Radius.circular(50.0),
                    topLeft: Radius.circular(50.0),
                  )
                ),
                child: Column (
                  mainAxisSize: MainAxisSize.max,
                  children: [
                    Align (
                      alignment: Alignment.centerLeft,
                      child: Container (
                        margin: EdgeInsets.only(bottom: MediaQuery.of(context).size.height / 40),
                        child:  Text (
                          'Sign in',
                          style: TextStyle (
                            fontSize: 30.0,
                            color: textColor
                          )
                        ),
                      ),
                    ),
                    TextField (
                      cursorColor: textColor,
                      controller: usernameController,
                      style: TextStyle (
                        fontSize: 14.0,
                        color: textColor,
                      ),
                      decoration: InputDecoration (
                        prefixIcon: Icon (
                          Icons.person,
                          color: activeColor
                        ),
                        isDense: true,
                        labelText: 'Username',
                        labelStyle: TextStyle (
                          color: activeColor
                        ),
                        focusedBorder: OutlineInputBorder (
                          borderRadius: const BorderRadius.all(Radius.circular(15)),
                          borderSide: BorderSide (
                            width: 3.0,
                            style: BorderStyle.solid,
                            color: activeColor,
                          )
                        ),
                        enabledBorder: OutlineInputBorder (
                          borderRadius: const BorderRadius.all(Radius.circular(15)),
                          borderSide: BorderSide (
                            width: 3.0,
                            style: BorderStyle.solid,
                            color: activeColor,
                          )
                        ),
                      ),
                    ),
                    SizedBox (
                      height: MediaQuery.of(context).size.height / 35,
                    ),
                    TextField (
                      cursorColor: textColor,
                      controller: passwordController,
                      obscureText: obscurePassword,
                      style: TextStyle (
                        fontSize: 14.0,
                        color: textColor,
                      ),
                      decoration: InputDecoration (
                        prefixIcon: Icon (
                          Icons.lock,
                          color: activeColor
                        ),
                        isDense: true,
                        labelText: 'Password',
                        labelStyle: TextStyle (
                          color: activeColor
                        ),
                        focusedBorder: OutlineInputBorder (
                          borderRadius: const BorderRadius.all(Radius.circular(15)),
                          borderSide: BorderSide (
                            width: 3.0,
                            style: BorderStyle.solid,
                            color: activeColor,
                          )
                        ),
                        enabledBorder: OutlineInputBorder (
                          borderRadius: const BorderRadius.all(Radius.circular(15)),
                          borderSide: BorderSide (
                            width: 3.0,
                            style: BorderStyle.solid,
                            color: activeColor,
                          )
                        ),
                        suffixIcon: IconButton (
                          icon: passwordVisibleIcon,
                          onPressed: () {
                            setState(() {
                              obscurePassword = !obscurePassword;
                              if (obscurePassword) {
                                passwordVisibleIcon = Icon (
                                  Icons.remove_red_eye_outlined,
                                  color: activeColor
                                );
                              }
                              else {
                                passwordVisibleIcon = Icon (
                                  Icons.remove_red_eye,
                                  color: activeColor
                                );
                              }
                            });
                          },
                        )
                      ),
                    ),
                    SizedBox (
                      height: MediaQuery.of(context).size.height / 25,
                    ),
                    SizedBox (
                      width: double.infinity,
                      child: OutlinedButton (
                        style: ButtonStyle (
                          padding: MaterialStateProperty.all(const EdgeInsets.all(12.0)),
                          backgroundColor: MaterialStateProperty.all(activeColor),
                          side: MaterialStateProperty.all(BorderSide(color: activeColor)),
                          shape: MaterialStateProperty.all (
                            RoundedRectangleBorder(
                              side: BorderSide(color: activeColor),
                              borderRadius: BorderRadius.circular(15.0),
                            ),
                          ),
                        ),
                        child: Text (
                          'Submit',
                          style: TextStyle (
                            color: backgroundColor,
                            fontSize: 20.0,
                          )
                        ),
                        onPressed: () => loginSubmit(),
                      ),
                    ),
                    const Spacer(),
                    Row (
                      mainAxisSize: MainAxisSize.max,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text (
                          'New user?',
                          style: TextStyle (
                            color: textColor,
                            fontSize: 17.0,
                          )
                        ),
                        TextButton (
                          child: Text (
                            'Sign up',
                            style: TextStyle (
                              color: activeColor,
                              fontSize: 17.0,
                            ),
                          ),
                          onPressed: () {
                            Navigator.of(context).pushNamedAndRemoveUntil('/login/create_account', (Route<dynamic> route) => false);
                          },
                        )
                      ]
                    )
                  ]
                )
              ),
            ),
          ],
        ),
      )
    );
  }
}


//! --- CREATE ACCOUNT PAGE ---


class CreateAccountPage extends StatefulWidget {
  const CreateAccountPage({ Key? key }) : super(key: key);
  

  @override
  _CreateAccountPageState createState() => _CreateAccountPageState();
}

class _CreateAccountPageState extends State<CreateAccountPage> {
  bool passwordObscure = true;
  bool confirmPasswordObscure = true;
  var passwordVisibleIcon = Icon (
    Icons.remove_red_eye_outlined,
    color: activeColor
  );
  var confirmPasswordVisibleIcon = Icon (
    Icons.remove_red_eye_outlined,
    color: activeColor
  );

  TextEditingController usernameController = TextEditingController();
  TextEditingController passwordController = TextEditingController();
  TextEditingController confirmPasswordController = TextEditingController();
  TextEditingController emailController = TextEditingController();

  Image profileImage = Image.asset('assets/default_profile.png', width: 200, height: 200, fit: BoxFit.fill);
  var imageFile = '';

  var userInfoDict = {
    'username': '',
    'email': '',
    'password': '',
    'profile_picture': '',
  };

  Future pickImage() async {
    final image = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (image == null) {
      return;
    } else {
      imageFile = base64Encode(File(image.path).readAsBytesSync());
      setState(() {
        profileImage = Image.file(File(image.path), width: 200, height: 200, fit: BoxFit.cover);
      });
    }
  }

  createAccountSubmit() async {
    if (usernameController.text.isNotEmpty && passwordController.text.isNotEmpty && confirmPasswordController.text.isNotEmpty && emailController.text.isNotEmpty) {
      String username = usernameController.text;
      String password = passwordController.text;
      String confirmPassword = confirmPasswordController.text;
      String email = emailController.text;

      if (imageFile == '') {
        var tempDefaultImg = await rootBundle.load('assets/default_profile.png');
        imageFile = base64Encode(Uint8List.view(tempDefaultImg.buffer));
      }

      if (password == confirmPassword) {
        var queries = {
          'username': username
        };
        var response = await sendRequest('check_username', queries, context);

        if (response['msg'] == 'exist') {
          alert('Username already exists', context);
        } else if (response['msg'] == 'not_exist') {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => VerifyEmailPage(
                username: username,
                email: email,
                password: password,
                pfp: imageFile
              ),
            ),
          );
        }
      }
      else {
        alert('Passwords do not match', context);
      } 
    }
    else {
      alert('One or more fields are empty', context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold (
      resizeToAvoidBottomInset: false, 
      body: Container (
        margin: const EdgeInsets.only(left: 20.0, right: 20.0, top: 30.0, bottom: 15.0),
        child: Column (
          children: [
            SizedBox (
              height: MediaQuery.of(context).size.height / 20
            ),
            Align (
              alignment: Alignment.centerLeft,
              child: Container (
                margin: EdgeInsets.only(bottom: MediaQuery.of(context).size.height / 40),
                child: Text (
                  'Create Account',
                  style: TextStyle (
                    fontSize: 30.0,
                    color: textColor
                  )
                ),
              ),
            ),
            TextField (
              cursorColor: textColor,
              controller: usernameController,
              style: TextStyle (
                fontSize: 14.0,
                color: textColor,
              ),
              decoration: InputDecoration (
                prefixIcon: Icon (
                  Icons.person,
                  color: activeColor
                ),
                isDense: true,
                labelText: 'Username',
                labelStyle: TextStyle (
                  color: activeColor
                ),
                focusedBorder: OutlineInputBorder (
                  borderRadius: const BorderRadius.all(Radius.circular(15)),
                  borderSide: BorderSide (
                    width: 3.0,
                    style: BorderStyle.solid,
                    color: activeColor,
                  )
                ),
                enabledBorder: OutlineInputBorder (
                  borderRadius: const BorderRadius.all(Radius.circular(15)),
                  borderSide: BorderSide (
                    width: 3.0,
                    style: BorderStyle.solid,
                    color: activeColor,
                  )
                ),
              ),
            ),
            SizedBox (
              height: MediaQuery.of(context).size.height / 55,
            ),
            Row (
              children: [
                Expanded (
                  child: TextField (
                    cursorColor: textColor,
                      controller: passwordController,
                      obscureText: passwordObscure,
                      style: TextStyle (
                        fontSize: 14.0,
                        color: textColor,
                      ),
                      decoration: InputDecoration (
                        prefixIcon: Icon (
                          Icons.lock,
                          color: activeColor
                        ),
                        isDense: true,
                        labelText: 'Password',
                        labelStyle: TextStyle (
                          color: activeColor
                        ),
                        focusedBorder: OutlineInputBorder (
                          borderRadius: const BorderRadius.all(Radius.circular(15)),
                          borderSide: BorderSide (
                            width: 3.0,
                            style: BorderStyle.solid,
                            color: activeColor,
                          )
                        ),
                        enabledBorder: OutlineInputBorder (
                          borderRadius: const BorderRadius.all(Radius.circular(15)),
                          borderSide: BorderSide (
                            width: 3.0,
                            style: BorderStyle.solid,
                            color: activeColor,
                          )
                        ),
                      suffixIcon: IconButton (
                        icon: passwordVisibleIcon,
                        onPressed: () {
                          setState(() {
                            passwordObscure = !passwordObscure;
                            if (passwordObscure) {
                              passwordVisibleIcon = Icon (
                                Icons.remove_red_eye_outlined,
                                color: activeColor
                              );
                            }
                            else {
                              passwordVisibleIcon = Icon (
                                Icons.remove_red_eye,
                                color: activeColor
                              );
                            }
                          });
                        },
                      ),
                    ),
                  ),
                ),
                SizedBox (
                  width: MediaQuery.of(context).size.width / 100
                ),
                Expanded (
                  child: TextField (
                    cursorColor: textColor,
                      controller: confirmPasswordController,
                      obscureText: confirmPasswordObscure,
                      style: TextStyle (
                        fontSize: 14.0,
                        color: textColor,
                      ),
                      decoration: InputDecoration (
                        prefixIcon: Icon (
                          Icons.lock,
                          color: activeColor
                        ),
                        isDense: true,
                        labelText: 'Confirm',
                        labelStyle: TextStyle (
                          color: activeColor
                        ),
                        focusedBorder: OutlineInputBorder (
                          borderRadius: const BorderRadius.all(Radius.circular(15)),
                          borderSide: BorderSide (
                            width: 3.0,
                            style: BorderStyle.solid,
                            color: activeColor,
                          )
                        ),
                        enabledBorder: OutlineInputBorder (
                          borderRadius: const BorderRadius.all(Radius.circular(15)),
                          borderSide: BorderSide (
                            width: 3.0,
                            style: BorderStyle.solid,
                            color: activeColor,
                          )
                        ),
                      suffixIcon: IconButton (
                        icon: confirmPasswordVisibleIcon,
                        onPressed: () {
                          setState(() {
                            confirmPasswordObscure = !confirmPasswordObscure;
                            if (confirmPasswordObscure) {
                              confirmPasswordVisibleIcon = Icon (
                                Icons.remove_red_eye_outlined,
                                color: activeColor
                              );
                            }
                            else {
                              confirmPasswordVisibleIcon = Icon (
                                Icons.remove_red_eye,
                                color: activeColor
                              );
                            }
                          });
                        },
                      ),
                    ),
                  ),
                ),
              ]
            ),
            SizedBox (
              height: MediaQuery.of(context).size.height / 55,
            ),
            TextField (
              cursorColor: textColor,
              controller: emailController,
              style: TextStyle (
                fontSize: 14.0,
                color: textColor,
              ),
              decoration: InputDecoration (
                prefixIcon: Icon (
                  Icons.email,
                  color: activeColor
                ),
                isDense: true,
                labelText: 'Email',
                labelStyle: TextStyle (
                  color: activeColor
                ),
                focusedBorder: OutlineInputBorder (
                  borderRadius: const BorderRadius.all(Radius.circular(15)),
                  borderSide: BorderSide (
                    width: 3.0,
                    style: BorderStyle.solid,
                    color: activeColor,
                  )
                ),
                enabledBorder: OutlineInputBorder (
                  borderRadius: const BorderRadius.all(Radius.circular(15)),
                  borderSide: BorderSide (
                    width: 3.0,
                    style: BorderStyle.solid,
                    color: activeColor,
                  )
                ),
              ),
            ),
            SizedBox (
              height: MediaQuery.of(context).size.height / 40,
            ),
            ClipRRect (
              borderRadius: BorderRadius.circular(100.0),
              child: profileImage,
            ),
            SizedBox (
              height: MediaQuery.of(context).size.height / 100
            ),
            SizedBox (
              child: OutlinedButton (
                style: ButtonStyle (
                  padding: MaterialStateProperty.all(const EdgeInsets.symmetric(vertical: 12.0, horizontal: 20.0)),
                  backgroundColor: MaterialStateProperty.all(backgroundColor),
                  side: MaterialStateProperty.all(BorderSide(color: activeColor, width: 2.5)),
                  shape: MaterialStateProperty.all (
                    RoundedRectangleBorder(
                      side: BorderSide(color: activeColor),
                      borderRadius: BorderRadius.circular(15.0),
                    ),
                  ),
                ),
                child: Text (
                  'Choose Profile Picture',
                  style: TextStyle (
                    color: textColor,
                    fontSize: 15.0,
                  )
                ),
                onPressed: () => pickImage(),
              ),
            ),
            const Spacer(),
            SizedBox (
              width: double.infinity,
              child: OutlinedButton (
                style: ButtonStyle (
                  padding: MaterialStateProperty.all(const EdgeInsets.all(12.0)),
                  backgroundColor: MaterialStateProperty.all(activeColor),
                  side: MaterialStateProperty.all(BorderSide(color: activeColor)),
                  shape: MaterialStateProperty.all (
                    RoundedRectangleBorder(
                      side: BorderSide(color: activeColor),
                      borderRadius: BorderRadius.circular(15.0),
                    ),
                  ),
                ),
                child: Text (
                  'Create Account',
                  style: TextStyle (
                    color: backgroundColor,
                    fontSize: 20.0,
                  )
                ),
                onPressed: () => createAccountSubmit(),
              ),
            ),
            SizedBox (
              height: MediaQuery.of(context).size.height / 80
            ),
            Row (
              mainAxisSize: MainAxisSize.max,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text (
                  'Already have an account?',
                  style: TextStyle (
                    color: textColor,
                    fontSize: 14.0,
                  )
                ),
                TextButton (
                  child: Text (
                    'Sign in',
                    style: TextStyle (
                      color: activeColor,
                      fontSize: 14.0,
                    ),
                  ),
                  onPressed: () {
                    Navigator.of(context).pushNamedAndRemoveUntil('/login', (Route<dynamic> route) => false);
                  },
                )
              ]
            )
          ],
        )
      )
    );
  }
}


//! --- HOME PAGE ---


class HomePage extends StatefulWidget {
  const HomePage({ Key? key }) : super(key: key);

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  List groups = List.filled(0, '', growable: true);

  createGroup() {
    Navigator.of(context).pushNamed('/home/create_group');
  }

  getGroups() async {
    var queries = {'id': storage.read('userid')};
    var response = await sendRequest('get_user_groups', queries, context);
        setState(() {
      groups = response['group_names'];
      groups.sort();
    });
  }

  groupPressed(String group) {
    activeGroupName = group;
    Navigator.of(context).pushNamed('/home/group');
  }

  @override
  void initState() {
    getGroups();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold (
      backgroundColor: backgroundColorDark,
      appBar: AppBar (
        backgroundColor: backgroundColorDark,
        elevation: 0,
        leading: IconButton (
          icon: Icon (
            Icons.refresh,
            size: 40.0,
            color: activeColor
          ),
          onPressed: () {
            getGroups();
        }),
        title: Center(
          child: Text (
            'Home',
            style: TextStyle (
              color: textColor,
              fontSize: 40.0,
            )
          ),
        ),
        toolbarHeight: 65.0,
        actions: [
          Container (
            margin: EdgeInsets.only(right: MediaQuery.of(context).size.width / 50),
            child: IconButton (
              icon: Icon (
                Icons.person,
                size: 40.0,
                color: activeColor,
              ),
              onPressed: () {
                Navigator.of(context).pushNamed('/home/profile');
              },
            ),
          )
        ],
      ),
      body: Stack (
        children: [
          Container (
            margin: const EdgeInsets.only(left: 10.0, right: 10.0, bottom: 10.0, top: 0),
            decoration: BoxDecoration (
              color: backgroundColor,
              border: Border.all (
                color: backgroundColor,
              ),
              borderRadius: const BorderRadius.all(Radius.circular(20))
            ),
            child: Container (
              margin: const EdgeInsets.only(top: 5.0, bottom: 15.0),
              child: RawScrollbar (
                crossAxisMargin: -3.0,
                thumbColor: backgroundColorLight,
                radius: const Radius.circular(5.0),
                isAlwaysShown: true,
                child: ScrollConfiguration (
                  behavior: RemoveGlow(),
                  child: ListView (
                    children: [
                      for (String group in groups)
                      Container (
                        margin: const EdgeInsets.all(10.0),
                        padding: const EdgeInsets.all(0.0),
                        child: ButtonTheme (
                          minWidth: double.infinity,
                          child: TextButton (
                            style: ButtonStyle (
                              backgroundColor: MaterialStateProperty.all(activeColor),
                              padding: MaterialStateProperty.all(const EdgeInsets.all(20.0)),
                              shape: MaterialStateProperty.all<RoundedRectangleBorder>(
                                RoundedRectangleBorder (
                                  borderRadius: BorderRadius.circular(20.0),
                                  side: BorderSide (
                                    color: activeColor,
                                    width: 5.0,
                                  )
                                )
                              )
                            ),
                            onPressed: () => groupPressed(group),
                            child: Text (
                              group,
                              style: TextStyle (
                                color: backgroundColorDark,
                                fontSize: 30.0,
                              ),
                            ),
                          ),
                        )
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          Container (
            margin: const EdgeInsets.all(20.0),
            child: Align (
              alignment: Alignment.bottomRight,
              child: SizedBox (
                width: 60,
                height: 60,
                child: ElevatedButton (
                  onPressed: () => createGroup(),
                  style: ButtonStyle (
                    backgroundColor: MaterialStateProperty.all(activeColor),
                    elevation: MaterialStateProperty.all(10.0),
                    shape: MaterialStateProperty.all(RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20)
                    ),
                  )),
                  child: Icon (
                    Icons.add,
                    color: backgroundColorDark,
                    size: 30.0,
                  ),
                )
              ),
            ),
          )
        ]
      ),
    );
  }
}


//! --- GROUP TEXT PAGE ---


class GroupTextPage extends StatefulWidget {
  const GroupTextPage({ Key? key }) : super(key: key);

  @override
  State<GroupTextPage> createState() => _GroupTextPageState();
}

class _GroupTextPageState extends State<GroupTextPage> {
  List messages = List.filled(0, '', growable: true);
  List usernames = List.filled(0, '', growable: true);
  List pfps = List.filled(0, '', growable: true);
  bool isAdmin = false;
  TextEditingController messageController = TextEditingController();
  String myUsername = '';
  ScrollController scrollController = ScrollController();
  int numScrolled = 0;

  getAdmin() async {
    var queries = {
      'user_id': storage.read('userid'),
      'group_name': activeGroupName
    };
    var response = await sendRequest('get_user_admin', queries, context);
        
    if (response['msg'] == 'yes') {
      setState(() {
        isAdmin = true;
      });
    }
  }

  sendMessage() {
    String message = messageController.text;

    if (message != '' && message.length < 500) {
      var messageDict = {
        'room': activeGroupName,
        'username': storage.read('username'),
        'content': message
      };
      socket.emit('send_message', messageDict);
      messageController.text = '';
    }
  }

  initializeSocket() {
    socket.connect();

    var socketQueries = {
      'room': activeGroupName,
      'num_scrolled': numScrolled
    };
    socket.emit('join_room', socketQueries);
    socket.emit('get_messages', socketQueries);

    socket.on('broadcast_message', (messageDict) {
      if (mounted) {
        setState(() {
          messages.insert(0, messageDict['content']);
          usernames.insert(0, messageDict['username']);
          pfps.insert(0, messageDict['profile_picture']);
        });
      }
    });
    socket.on('get_first_messages', (messageDict) {
      if (mounted) {
        setState(() {
          messages += messageDict['messages'];
          usernames += messageDict['usernames'];
          pfps += messageDict['profile_pictures'];
        });
        numScrolled++;
      }
    });
  }

  isMyMessage(String username) {
    if (username == storage.read('username')) {
      return false;
    } else {
      return true;
    }
  }

  getMoreMessages() {
    var socketQueries = {
      'room': activeGroupName,
      'num_scrolled': numScrolled
    };
    socket.emit('get_messages', socketQueries);
  }

  @override
  void initState() {
    super.initState();
    initializeSocket();
    getAdmin();

    scrollController.addListener(() {
      if (scrollController.position.atEdge) {
        if (scrollController.position.pixels != 0) {
          getMoreMessages();
        }
      }
    });
  }

  @override
  void dispose() {
    socket.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold (
      backgroundColor: backgroundColorDark,
      appBar: AppBar (
        automaticallyImplyLeading: false,
        centerTitle: true,
        leading: IconButton (
          icon: Icon (
            Icons.arrow_back,
            size: 30.0,
            color: activeColor
          ),
          onPressed: () {
            Navigator.of(context).pop();
        }),
        title: Text (
          activeGroupName,
          style: TextStyle (
            color: textColor,
            fontSize: 30.0,
          )
        ),
        toolbarHeight: 65.0,
        backgroundColor: backgroundColorDark,
        elevation: 0,
        actions: <Widget> [
          Visibility (
            visible: isAdmin,
            child: IconButton (
              icon: Icon (
                Icons.settings,
                size: 30.0,
                color: activeColor,
              ),
              onPressed: () {
                Navigator.of(context).pushNamed('/home/group/settings');
              },
            ),
          ),
          Visibility (
            visible: !isAdmin,
            child: IconButton (
              icon: Icon (
                Icons.settings,
                size: 30.0,
                color: activeColor,
              ),
              onPressed: () {
                Navigator.of(context).pushNamed('/home/group/leave');
              },
            ),
          )
        ],
      ),
      body: Container (
        margin: const EdgeInsets.only(left: 10.0, right: 10.0, bottom: 10.0),
        child: Column (
          children: [
            Expanded (
              child: Container (
                decoration: BoxDecoration (
                  color: backgroundColor,
                  border: Border.all (
                    color: backgroundColor,
                  ),
                  borderRadius: const BorderRadius.all(Radius.circular(20))
                ),
                child: Align (
                  alignment: Alignment.topCenter,
                  child: Container (
                    margin: const EdgeInsets.only(top: 15.0, bottom: 15.0),
                    child: RawScrollbar (
                      controller: scrollController,
                      crossAxisMargin: 5.0,
                      thumbColor: backgroundColorLight,
                      radius: const Radius.circular(5.0),
                      isAlwaysShown: true,
                      child: ScrollConfiguration (
                        behavior: RemoveGlow(),
                        child: ListView.builder (
                          controller: scrollController,
                          itemCount: messages.length,
                          shrinkWrap: true,
                          reverse: true,
                          itemBuilder: (BuildContext context, int i) {
                            return Container (
                              margin: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
                              child: Stack (
                                children: [
                                  Visibility (
                                    visible: isMyMessage(usernames[i]),
                                    child: Row (
                                      children: [
                                        Container (
                                          margin: const EdgeInsets.only(right: 10.0),
                                          child: ClipRRect (
                                            borderRadius: BorderRadius.circular(100.0),
                                            child: Image.memory(base64Decode(pfps[i]), width: 50, height: 50, fit: BoxFit.fill),
                                          ),
                                        ),
                                        Expanded (
                                          child: Column (
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Container (
                                                margin: EdgeInsets.only(left: MediaQuery.of(context).size.width / 100),
                                                child: Text (
                                                  usernames[i],
                                                  style: TextStyle (
                                                      fontSize: 13.0,
                                                      color: textColor
                                                  )
                                                ),
                                              ),
                                              Flexible (
                                                fit: FlexFit.loose,
                                                child: Container (
                                                  decoration: BoxDecoration (
                                                    color: activeColor,
                                                    border: Border.all (
                                                      color: activeColor,
                                                    ),
                                                    borderRadius: const BorderRadius.all(Radius.circular(20))
                                                  ),
                                                  margin: const EdgeInsets.symmetric(vertical: 2.0),
                                                  padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 17.0),
                                                  child: Row (
                                                    mainAxisSize: MainAxisSize.min,
                                                    children: [
                                                      Flexible (
                                                        fit: FlexFit.loose,
                                                        child: Text (
                                                          messages[i],
                                                          style: TextStyle (
                                                            color: backgroundColor,
                                                            fontSize: 15.0,
                                                          )
                                                        ),
                                                      ),
                                                    ]
                                                  )
                                                ),
                                              ),
                                            ]
                                          ),
                                        )
                                      ]
                                    ),
                                  ),
                                  Visibility (
                                    visible: !isMyMessage(usernames[i]),
                                    child: Row (
                                      children: [
                                        Expanded (
                                          child: Column (
                                            crossAxisAlignment: CrossAxisAlignment.end,
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Container (
                                                margin: EdgeInsets.only(right: MediaQuery.of(context).size.width / 100),
                                                child: Text (
                                                  usernames[i],
                                                  style:TextStyle (
                                                      fontSize: 13.0,
                                                      color: textColor
                                                  )
                                                ),
                                              ),
                                              Flexible (
                                                fit: FlexFit.loose,
                                                child: Container (
                                                  decoration: BoxDecoration (
                                                    color: activeColorDark,
                                                    border: Border.all (
                                                      color: activeColorDark,
                                                    ),
                                                    borderRadius: const BorderRadius.all(Radius.circular(20))
                                                  ),
                                                  margin: const EdgeInsets.symmetric(vertical: 2.0),
                                                  padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 17.0),
                                                  child: Row (
                                                    mainAxisSize: MainAxisSize.min,
                                                    children: [
                                                      Flexible (
                                                        fit: FlexFit.loose,
                                                        child: Text (
                                                          messages[i],
                                                          style: TextStyle (
                                                            fontSize: 15.0,
                                                            color: backgroundColor,
                                                          )
                                                        ),
                                                      ),
                                                    ]
                                                  )
                                                ),
                                              ),
                                            ]
                                          ),
                                        ),
                                        Container (
                                          margin: const EdgeInsets.only(left: 10.0),
                                          child: ClipRRect (
                                            borderRadius: BorderRadius.circular(100.0),
                                            child: Image.memory(base64Decode(pfps[i]), width: 50, height: 50, fit: BoxFit.fill),
                                          ),
                                        ),
                                      ]
                                    ),
                                  ),
                                ]
                              )
                            );
                          }
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            SizedBox(
              height: MediaQuery.of(context).size.height / 60
            ),
            TextField (
              cursorColor: textColor,
              controller: messageController,
              style: TextStyle (
                fontSize: 14.0,
                color: textColor,
              ),
              decoration: InputDecoration (
                suffixIcon: IconButton (
                  icon: Icon (
                    Icons.send,
                    color: activeColor
                  ),
                  onPressed: () => sendMessage(),
                ),
                isDense: true,
                focusedBorder: OutlineInputBorder (
                  borderRadius: const BorderRadius.all(Radius.circular(15)),
                  borderSide: BorderSide (
                    width: 3.0,
                    style: BorderStyle.solid,
                    color: activeColor,
                  )
                ),
                enabledBorder: OutlineInputBorder (
                  borderRadius: const BorderRadius.all(Radius.circular(15)),
                  borderSide: BorderSide (
                    width: 3.0,
                    style: BorderStyle.solid,
                    color: activeColor,
                  )
                ),
              ),
            ),
          ]
        )
      )
    );
  }
}


//! --- GROUP SETTINGS PAGE ---


class GroupSettingsPage extends StatefulWidget {
  const GroupSettingsPage({ Key? key }) : super(key: key);

  @override
  State<GroupSettingsPage> createState() => _GroupSettingsPageState();
}

class _GroupSettingsPageState extends State<GroupSettingsPage> {
  TextEditingController usernameController = TextEditingController();
  List<dynamic> users = List.filled(0, '', growable: true);

  getUsers() async {
    var queries = {'group_name': activeGroupName};
    var response = await sendRequest('get_users_in_group', queries, context);
    if (response['msg'] == 'success') {
      var usernameQueries = {'id': storage.read('userid')};
      var usernameResponse = await sendRequest('get_user_info', usernameQueries, context);
      setState(() {
        users = response['usernames'];
        users.remove(usernameResponse['username']);
        users.sort();
      });
    }
  }

  addUser(BuildContext context) {
    showDialog (
      context: context,
      builder: (context) {
        return AlertDialog (
          backgroundColor: backgroundColor,
          content: TextField (
            controller: usernameController,
            style: TextStyle (
              fontSize: 14.0,
              color: textColor
            ),
            decoration: InputDecoration (
              enabledBorder: UnderlineInputBorder (
                borderSide: BorderSide (
                  color: textColor, 
                  width: 1.0, 
                  style: BorderStyle.solid
                ),
              ),
              focusedBorder: UnderlineInputBorder (
                borderSide: BorderSide (
                  color: textColor, 
                  width: 1.0, 
                  style: BorderStyle.solid
                ),
              ),
              isDense: true,
              labelText: 'Username',
              labelStyle: TextStyle (
                color: textColor
              )
            ),
          ),
          actions: [
            TextButton(
              child: Text (
                'Add',
                style: TextStyle (
                  color: activeColor
                )
              ),
              onPressed: () async {
                String newUsername = usernameController.text;
                if (newUsername != '') {
                  if (users.contains(newUsername)) {
                    usernameController.text = '';
                    Navigator.of(context).pop();
                    alert('User is already in group', context);
                  } else {
                    var queries = {'username': newUsername};
                    var response = await sendRequest('check_user_existence', queries, context);
                    
                    if (response['msg'] == 'success') {
                      var queries = {
                        'username': newUsername,
                        'group_name': activeGroupName
                      };
                      var response = await sendRequest('add_user', queries, context);
                      
                      if (response['msg'] == 'success') {
                      setState(() {
                        users.add(newUsername);
                        users.sort();
                      });
                        usernameController.text = '';
                        Navigator.of(context).pop();
                      }
                    } else {
                      Navigator.of(context).pop();
                      alert('User does not exist', context);
                    }
                  }
                }
              },
            ),
          ],
        );
      }
    );
  }

  deleteGroup() {
    confirm (
      RichText (
        text: TextSpan (
          children: [
            TextSpan (
              text: 'Are you sure that you want to delete the group ',
              style: TextStyle (
                color: textColor,
                fontSize: 18,
              )
            ),
            TextSpan (
              text: activeGroupName,
              style: TextStyle (
                color: textColor,
                fontSize: 18,
                fontWeight: FontWeight.bold
              )
            )
          ]
        )
      ),
      () async {
        var queries = {
          'group_name': activeGroupName
        };
        var response = await sendRequest('delete_group', queries, context);
        if (response['msg'] == 'success') {
          Navigator.of(context).pushNamedAndRemoveUntil('/home', (Route<dynamic> route) => false);
        }
      },
      context
    );
  }

  deleteUser(String user) {
    confirm (
      RichText (
        text: TextSpan (
          children: [
            TextSpan (
              text: 'Are you sure you want to remove ',
              style: TextStyle (
                color: textColor,
                fontSize: 18,
              )
            ),
            TextSpan (
              text: user,
              style: TextStyle (
                fontWeight: FontWeight.bold,
                color: textColor,
                fontSize: 18,
              )
            ),
            TextSpan (
              text: ' from ',
              style: TextStyle (
                color: textColor,
                fontSize: 18,
              )
            ),
            TextSpan (
              text: activeGroupName,
              style: TextStyle (
                fontWeight: FontWeight.bold,
                color: textColor,
                fontSize: 18,
              )
            )
          ]
        )
      ),
      () async {
        var queries = {
          'username': user,
          'group_name': activeGroupName
        };
        var response = await sendRequest('remove_user', queries, context);
        if (response['msg'] == 'success') {
          setState(() {
            users.remove(user);
          });
        }
      },
      context
    );
  }

  @override
  initState() {
    getUsers();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold (
      backgroundColor: backgroundColorDark,
      resizeToAvoidBottomInset: false,
      appBar: AppBar (
        automaticallyImplyLeading: false,
        centerTitle: true,
        leading: IconButton (
          icon: Icon (
            Icons.arrow_back,
            size: 30.0,
            color: activeColor
          ),
          onPressed: () {
            Navigator.of(context).pop();
        }),
        title: RichText (
          text: TextSpan (
            style: TextStyle (
              fontSize: 25.0,
              color: textColor
            ),
            children: [
              const TextSpan (
                text: 'Edit: ',
                style: TextStyle (
                  fontWeight: FontWeight.bold
                )
              ),
              TextSpan (
                text: activeGroupName
              ),
            ]
          ),
        ),
        toolbarHeight: 65.0,
        backgroundColor: backgroundColorDark,
        elevation: 0,
      ),
      body: Container (
        margin: const EdgeInsets.all(10.0),
        child: Column (
          children: [
            Container (
              margin: const EdgeInsets.only(top: 0.0, right: 10.0, left: 10.0),
              child: Row (
                mainAxisSize: MainAxisSize.max,
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Expanded (
                    child: SizedBox (
                      child: OutlinedButton (
                        style: ButtonStyle (
                          padding: MaterialStateProperty.all(const EdgeInsets.all(12.0)),
                          backgroundColor: MaterialStateProperty.all(activeColor),
                          side: MaterialStateProperty.all(BorderSide(color: activeColor)),
                          shape: MaterialStateProperty.all (
                            RoundedRectangleBorder(
                              side: BorderSide(color: activeColor),
                              borderRadius: BorderRadius.circular(15.0),
                            ),
                          ),
                        ),
                        child: Text (
                          'Add User',
                          style: TextStyle (
                            color: backgroundColor,
                            fontSize: 18.0,
                          )
                        ),
                        onPressed: () => addUser(context),
                      ),
                    ),
                  ),
                  SizedBox (
                    width: MediaQuery.of(context).size.width / 20
                  ),
                  Expanded (
                    child: SizedBox (
                      child: OutlinedButton (
                        style: ButtonStyle (
                          padding: MaterialStateProperty.all(const EdgeInsets.all(12.0)),
                          backgroundColor: MaterialStateProperty.all(activeColor),
                          side: MaterialStateProperty.all(BorderSide(color: activeColor)),
                          shape: MaterialStateProperty.all (
                            RoundedRectangleBorder(
                              side: BorderSide(color: activeColor),
                              borderRadius: BorderRadius.circular(15.0),
                            ),
                          ),
                        ),
                        child: Text (
                          'Delete Group',
                          style: TextStyle (
                            color: backgroundColor,
                            fontSize: 18.0,
                          )
                        ),
                        onPressed: () => deleteGroup(),
                      ),
                    ),
                  ),
                ]
              ),
            ),
            Expanded (
              child: Container (
                margin: const EdgeInsets.all(10.0),
                decoration: BoxDecoration (
                  color: backgroundColor,
                  border: Border.all (
                    color: backgroundColor
                  ),
                  borderRadius: const BorderRadius.all(Radius.circular(20))
                ),
                child: Container (
                  margin: const EdgeInsets.only(right: 8.0, top: 15.0, bottom: 15.0),
                  child: RawScrollbar (
                    thumbColor: backgroundColorLight,
                    radius: const Radius.circular(5.0),
                    isAlwaysShown: true,
                    child: ScrollConfiguration (
                      behavior: RemoveGlow(),
                      child: ListView (
                        children: [
                          Center (
                            child: Text (
                              'Users',
                              style: TextStyle (
                                fontWeight: FontWeight.bold,
                                color: textColor,
                                fontSize: 25.0,
                              ),
                            ),
                          ),
                          for (String user in users)
                          Container (
                            margin: const EdgeInsets.only(left: 10.0),
                            padding: const EdgeInsets.symmetric(horizontal: 8.0),
                            child: Row (
                              children: [
                                Text (
                                  user,
                                  style: TextStyle (
                                    color: textColorDark,
                                    fontSize: 23.0,
                                  ),
                                ),
                                const Spacer(),
                                IconButton (
                                  onPressed: () => deleteUser(user),
                                  icon: const Icon(Icons.backspace_rounded),
                                  color: Colors.red[500],
                                  iconSize: 25.0,
                                )
                              ]
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ]
        )
      )
    );
  }
}


//! --- LEAVE GROUP PAGE ---


class GroupLeavePage extends StatefulWidget {
  const GroupLeavePage({ Key? key }) : super(key: key);

  @override
  State<GroupLeavePage> createState() => _GroupLeavePageState();
}

class _GroupLeavePageState extends State<GroupLeavePage> {
  removeUser() {
    confirm (
      RichText (
        text: TextSpan (
          children: [
            TextSpan (
              text: 'Are you sure you want to leave the group ',
              style: TextStyle (
                color: textColor,
                fontSize: 18,
              )
            ),
            TextSpan (
              text: activeGroupName,
              style: TextStyle (
                fontWeight: FontWeight.bold,
                color: textColor,
                fontSize: 18,
              )
            )
          ]
        )
      ),
      () async {
        var queries = {
          'username': storage.read('username'),
          'group_name': activeGroupName
        };
        var response = await sendRequest('remove_user', queries, context);
        if (response['msg'] == 'success') {
          Navigator.of(context).pushNamedAndRemoveUntil('/home', (Route<dynamic> route) => false);
        }
      },
      context
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold (
      backgroundColor: backgroundColorDark,
      resizeToAvoidBottomInset: false,
      appBar: AppBar (
        automaticallyImplyLeading: false,
        centerTitle: true,
        leading: IconButton (
          icon: Icon (
            Icons.arrow_back,
            size: 30.0,
            color: activeColor
          ),
          onPressed: () {
            Navigator.of(context).pop();
        }),
        title: RichText (
          text: TextSpan (
            style: TextStyle (
              fontSize: 30.0,
              color: textColor
            ),
            children: [
              const TextSpan (
                text: 'Edit:  ',
                style: TextStyle (
                  fontWeight: FontWeight.bold
                )
              ),
              TextSpan (
                text: activeGroupName
              ),
            ]
          ),
        ),
        toolbarHeight: 65.0,
        backgroundColor: backgroundColorDark,
        elevation: 0,
      ),
      body: Container (
        margin: const EdgeInsets.all(50.0),
        child: SizedBox (
          width: double.infinity,
          child: OutlinedButton (
            style: ButtonStyle (
              padding: MaterialStateProperty.all(const EdgeInsets.symmetric(vertical: 12.0, horizontal: 20.0)),
              backgroundColor: MaterialStateProperty.all(activeColor),
              side: MaterialStateProperty.all(BorderSide(color: activeColor)),
              shape: MaterialStateProperty.all (
                RoundedRectangleBorder(
                  side: BorderSide(color: activeColor),
                  borderRadius: BorderRadius.circular(15.0),
                ),
              ),
            ),
            child: Text (
              'Leave Group',
              style: TextStyle (
                color: backgroundColor,
                fontSize: 20.0,
              )
            ),
            onPressed: () => removeUser(),
          ),
        ),
      )
    );
  }
}


//! --- PROFILE PAGE ---


class ProfilePage extends StatefulWidget {
  const ProfilePage({ Key? key }) : super(key: key);

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  String username = 'Name';
  String email = 'Email';
  late Image profileImage = Image.asset('assets/default_profile.png', width: 200, height: 200, fit: BoxFit.fill);

  getInfo() async {
    var queries = {'id': storage.read('userid')};
    var response = await sendRequest('get_user_info', queries, context);
        setState(() {
      username = response['username'];
      email = response['email'];
      profileImage = Image.memory(base64Decode(response['pfp']), width: 200, height: 200, fit: BoxFit.fill);
    });
  }

  Future changePFP() async {
    final image = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (image == null) {
      return;
    } else {
      var queries = {'username': username};
      var postBody = {'pfp': base64Encode(File(image.path).readAsBytesSync())};
      var response = await sendRequest('set_pfp', queries, context, postBody);

      if (response['msg'] == 'success') {
        Navigator.of(context).pop();
        Navigator.of(context).pushNamed('/home/profile');
      }
    }
  }

  logout() {
    confirm (
      Text (
        "Are you sure you want to log out?",
        style: TextStyle (
          color: textColor
        )
      ),
      () {
        storage.remove('userid');
        Navigator.of(context).pushNamedAndRemoveUntil('/login', (Route<dynamic> route) => false);
      },
      context
    );
  }

  @override
  void initState() {
    getInfo();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold (
      appBar: AppBar (
        automaticallyImplyLeading: false,
        centerTitle: true,
        leading: IconButton (
          icon: Icon (
            Icons.arrow_back,
            size: 30.0,
            color: activeColor
          ),
          onPressed: () {
            Navigator.of(context).pop();
        }),
        title: Text (
          'Profile',
          style: TextStyle (
            color: textColor,
            fontSize: 30.0,
          )
        ),
        toolbarHeight: 65.0,
        backgroundColor: backgroundColorDark,
        elevation: 0,
      ),
      body: Container (
        width: double.infinity,
        height: double.infinity,
        padding: const EdgeInsets.all(15.0),
        child: Column (
          mainAxisSize: MainAxisSize.max,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text (
              username,
              textAlign: TextAlign.start,
              style: TextStyle(
                fontSize: 75.0,
                color: activeColor,
              )
            ),
            SizedBox (
              width: double.infinity,
              child: Row (
                mainAxisSize: MainAxisSize.max,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon (
                    Icons.email,
                    color: textColorDark,
                  ),
                  Text (
                    email,
                    style: TextStyle(
                      fontSize: 17.0,
                      color: textColorDark,
                    )
                  ),
                ]
              ),
            ),
            Container (
              margin: const EdgeInsets.symmetric(horizontal: 20.0),
              child: Divider (
                height: 50.0,
                thickness: 4,
                color: backgroundColorDark,
              ),
            ),
            ClipRRect (
                borderRadius: BorderRadius.circular(100.0),
                child: profileImage,
            ),
            TextButton (
              child: Text (
                'Change Profile Picture',
                style: TextStyle (
                  color: activeColor
                )
              ),
              onPressed: () => changePFP(),
            ),
            const Spacer(),
            Align (
              alignment: Alignment.bottomCenter,
              child: TextButton (
                child: Text(
                  'Logout',
                  style: TextStyle (
                    fontSize: 20.0,
                    color: activeColor
                  )
                ),
                onPressed: () => logout(),
              ),
            )
          ],
        )
      )
    );
  }
}


//! --- GROUP CREATION PAGE ---


class CreateGroupPage extends StatefulWidget {
  const CreateGroupPage({ Key? key }) : super(key: key);

  @override
  State<CreateGroupPage> createState() => _CreateGroupPageState();
}

class _CreateGroupPageState extends State<CreateGroupPage> {
  TextEditingController groupNameController = TextEditingController();
  TextEditingController usernameController = TextEditingController();
  List<String> users = List.filled(0, '', growable: true);

  addUser(BuildContext context) {
    showDialog (
      context: context,
      builder: (context) {
        return AlertDialog (
          backgroundColor: backgroundColor,
          content: TextField (
            controller: usernameController,
            style: TextStyle (
              fontSize: 14.0,
              color: textColor
            ),
            decoration: InputDecoration (
              enabledBorder: UnderlineInputBorder (
                borderSide: BorderSide (
                  color: textColor, 
                  width: 1.0, 
                  style: BorderStyle.solid
                ),
              ),
              focusedBorder: UnderlineInputBorder (
                borderSide: BorderSide (
                  color: textColor, 
                  width: 1.0, 
                  style: BorderStyle.solid
                ),
              ),
              isDense: true,
              labelText: 'Username',
              labelStyle: TextStyle (
                color: textColor
              )
            ),
          ),
          actions: [
            TextButton(
              child: Text (
                'Add',
                style: TextStyle (
                  color: activeColor
                )
              ),
              onPressed: () async {
                String username = usernameController.text;
                if (username != '') {
                  if (username != storage.read('username')) {
                    if (!users.contains(username)) {
                      var queries = {'username': usernameController.text};
                      var response = await sendRequest('check_user_existence', queries, context);
                      
                      if (response['msg'] == 'success') {
                        setState(() {
                          users.add(usernameController.text);
                        });
                        usernameController.text = '';
                        Navigator.of(context).pop();
                      } else {
                        Navigator.of(context).pop();
                        alert('User does not exist', context);
                      }
                    }
                  }
                }
              },
            ),
          ],
        );
      }
    );
  }

  createGroup() async {
    String groupName = groupNameController.text;
    if (groupName != '') {
      var queries = {
        'user_id': storage.read('userid'),
        'usernames': users.toString(),
        'group_name': groupName
      };
      var response = await sendRequest('create_group', queries, context);
      
      if (response['msg'] == 'success') {
        Navigator.of(context).pushNamedAndRemoveUntil('/home', (Route<dynamic> route) => false);
        alert('Group successfully created', context);
      } else if(response['msg'] == 'group_exists') {
        alert('Group name already in use', context);
      }
    } else {
      alert('Please enter a group name', context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold (
      backgroundColor: backgroundColorDark,
      resizeToAvoidBottomInset: false,
      appBar: AppBar (
        automaticallyImplyLeading: false,
        centerTitle: true,
        leading: IconButton (
          icon: Icon (
            Icons.arrow_back,
            size: 30.0,
            color: activeColor
          ),
          onPressed: () {
            Navigator.of(context).pop();
        }),
        title: Text (
          'Create Group',
          style: TextStyle (
            color: textColor,
            fontSize: 30.0,
          )
        ),
        toolbarHeight: 65.0,
        backgroundColor: backgroundColorDark,
        elevation: 0,
      ),
      body: Container (
        margin: const EdgeInsets.all(10.0),
        child: Column (
          children: [
            Container (
              margin: const EdgeInsets.symmetric(horizontal: 10.0),
              child: TextField (
                cursorColor: textColor,
                controller: groupNameController,
                style: TextStyle (
                  fontSize: 14.0,
                  color: textColor,
                ),
                decoration: InputDecoration (
                  prefixIcon: Icon (
                    Icons.group,
                    color: activeColor
                  ),
                  isDense: true,
                  labelText: 'Group name',
                  labelStyle: TextStyle (
                    color: activeColor
                  ),
                  focusedBorder: OutlineInputBorder (
                    borderRadius: const BorderRadius.all(Radius.circular(15)),
                    borderSide: BorderSide (
                      width: 3.0,
                      style: BorderStyle.solid,
                      color: activeColor,
                    )
                  ),
                  enabledBorder: OutlineInputBorder (
                    borderRadius: const BorderRadius.all(Radius.circular(15)),
                    borderSide: BorderSide (
                      width: 3.0,
                      style: BorderStyle.solid,
                      color: activeColor,
                    )
                  ),
                ),
              ),
            ),
            Container (
              margin: const EdgeInsets.only(top: 10.0, right: 10.0, left: 10.0),
              child: Row (
                mainAxisSize: MainAxisSize.max,
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Expanded (
                    child: SizedBox (
                      child: OutlinedButton (
                        style: ButtonStyle (
                          padding: MaterialStateProperty.all(const EdgeInsets.all(12.0)),
                          backgroundColor: MaterialStateProperty.all(activeColor),
                          side: MaterialStateProperty.all(BorderSide(color: activeColor)),
                          shape: MaterialStateProperty.all (
                            RoundedRectangleBorder(
                              side: BorderSide(color: activeColor),
                              borderRadius: BorderRadius.circular(15.0),
                            ),
                          ),
                        ),
                        child: Text (
                          'Add User',
                          style: TextStyle (
                            color: backgroundColor,
                            fontSize: 18.0,
                          )
                        ),
                        onPressed: () => addUser(context),
                      ),
                    ),
                  ),
                  SizedBox (
                    width: MediaQuery.of(context).size.width / 20
                  ),
                  Expanded (
                    child: SizedBox (
                      child: OutlinedButton (
                        style: ButtonStyle (
                          padding: MaterialStateProperty.all(const EdgeInsets.all(12.0)),
                          backgroundColor: MaterialStateProperty.all(activeColor),
                          side: MaterialStateProperty.all(BorderSide(color: activeColor)),
                          shape: MaterialStateProperty.all (
                            RoundedRectangleBorder(
                              side: BorderSide(color: activeColor),
                              borderRadius: BorderRadius.circular(15.0),
                            ),
                          ),
                        ),
                        child: Text (
                          'Create Group',
                          style: TextStyle (
                            color: backgroundColor,
                            fontSize: 18.0,
                          )
                        ),
                        onPressed: () => createGroup(),
                      ),
                    ),
                  ),
                ]
              ),
            ),
            Expanded (
              child: Container (
                margin: const EdgeInsets.all(10.0),
                decoration: BoxDecoration (
                  color: backgroundColor,
                  border: Border.all (
                    color: backgroundColor,
                  ),
                  borderRadius: const BorderRadius.all(Radius.circular(20))
                ),
                child: Container (
                  margin: const EdgeInsets.only(right: 8.0, top: 15.0, bottom: 15.0),
                  child: RawScrollbar (
                    thumbColor: backgroundColorLight,
                    radius: const Radius.circular(5.0),
                    isAlwaysShown: true,
                    child: ScrollConfiguration (
                      behavior: RemoveGlow(),
                      child: ListView (
                        children: [
                          Center (
                            child: Text (
                              'Users',
                              style: TextStyle (
                                fontWeight: FontWeight.bold,
                                color: textColor,
                                fontSize: 25.0,
                              ),
                            ),
                          ),
                          for (String user in users)
                          Container (
                            margin: const EdgeInsets.only(left: 10.0),
                            padding: const EdgeInsets.symmetric(horizontal: 8.0),
                            child: Row (
                              children: [
                                Text (
                                  user,
                                  style: TextStyle (
                                    color: textColorDark,
                                    fontSize: 23.0,
                                  ),
                                ),
                                const Spacer(),
                                IconButton (
                                  onPressed: () {
                                    setState(() {
                                      users.remove(user);
                                    });
                                  },
                                  icon: const Icon(Icons.backspace_rounded),
                                  color: Colors.red[500],
                                  iconSize: 25.0,
                                )
                              ]
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ]
        )
      )
    );
  }
}


//! --- EMAIL VERIFICATION PAGE ---


class VerifyEmailPage extends StatefulWidget {
  const VerifyEmailPage({Key? key, this.username, this.password, this.email, this.pfp}) : super(key: key);

  final String? username;
  final String? password;
  final String? email;
  final String? pfp;

  @override
  State<VerifyEmailPage> createState() => _VerifyEmailPageState();
}

class _VerifyEmailPageState extends State<VerifyEmailPage> {
  TextEditingController codeController = TextEditingController();

  submitCode() {
    var socketQueries = {
      'code': codeController.text
    };
    socket.emit('submit_code', socketQueries);
  }

  sendCode() {
    var socketQueries = {
      'email': widget.email
    };
    socket.emit('email_code', socketQueries);
  }

  initSocket() {
    socket.connect();
    socket.on('code_response', (messageDict) async {
      if (messageDict['msg'] == 'success') {
        var queries = {
          'username': widget.username,
          'email': widget.email,
          'password': widget.password
        };

        var response = await sendRequest('create_account', queries, context);

        if (response['msg'] == 'success') {
          storage.write('userid', response['userid']);
          storage.write('username', widget.username);

          var pfpQueries = {'username': widget.username};
          var pfpPostBody = {'pfp': widget.pfp!};
          await sendRequest('set_pfp', pfpQueries, context, pfpPostBody);
          Navigator.of(context).pushNamedAndRemoveUntil('/home', (Route<dynamic> route) => false);
        }
      } else {
        alert('Incorrect verification code', context);
      }
    });
  }

  @override
  void initState() {
    super.initState();
    initSocket();
    sendCode();
  }

  @override
  void dispose() {
    socket.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold (
      resizeToAvoidBottomInset: false,
      body: Container (
        margin: const EdgeInsets.all(20.0),
        child: Stack (
          children: [
            Container (
              margin: const EdgeInsets.only(top: 40.0),
              child: Align (
                alignment: Alignment.topLeft,
                child: IconButton (
                  icon: Icon (
                    Icons.arrow_back,
                    color: textColor,
                    size: 40.0
                  ),
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                ),
              ),
            ),
            Center (
              child: Column (
                mainAxisSize: MainAxisSize.min,
                children: [
                  Align (
                    alignment: Alignment.topCenter,
                    child: Container (
                      margin: EdgeInsets.only(bottom: MediaQuery.of(context).size.height / 40),
                      child: Text (
                        'A code has been sent to ${widget.email}',
                        textAlign: TextAlign.center,
                        style: TextStyle (
                          fontSize: 20.0,
                          color: textColor
                        )
                      ),
                    ),
                  ),
                  SizedBox (
                    height: MediaQuery.of(context).size.height / 70
                  ),
                  TextField (
                    cursorColor: textColor,
                    controller: codeController,
                    style: TextStyle (
                      fontSize: 14.0,
                      color: textColor,
                    ),
                    decoration: InputDecoration (
                      prefixIcon: Icon (
                        Icons.code,
                        color: activeColor
                      ),
                      isDense: true,
                      labelText: '6-Digit Code',
                      labelStyle: TextStyle (
                        color: activeColor
                      ),
                      focusedBorder: OutlineInputBorder (
                        borderRadius: const BorderRadius.all(Radius.circular(15)),
                        borderSide: BorderSide (
                          width: 3.0,
                          style: BorderStyle.solid,
                          color: activeColor,
                        )
                      ),
                      enabledBorder: OutlineInputBorder (
                        borderRadius: const BorderRadius.all(Radius.circular(15)),
                        borderSide: BorderSide (
                          width: 3.0,
                          style: BorderStyle.solid,
                          color: activeColor,
                        )
                      ),
                    ),
                  ),
                  SizedBox (
                    height: MediaQuery.of(context).size.height / 50
                  ),
                  SizedBox (
                    child: OutlinedButton (
                      style: ButtonStyle (
                        padding: MaterialStateProperty.all(const EdgeInsets.symmetric(vertical: 12.0, horizontal: 30.0)),
                        backgroundColor: MaterialStateProperty.all(activeColor),
                        side: MaterialStateProperty.all(BorderSide(color: activeColor)),
                        shape: MaterialStateProperty.all (
                          RoundedRectangleBorder(
                            side: BorderSide(color: activeColor),
                            borderRadius: BorderRadius.circular(15.0),
                          ),
                        ),
                      ),
                      child: Text (
                        'Submit',
                        style: TextStyle (
                          color: backgroundColor,
                          fontSize: 17.0,
                        )
                      ),
                      onPressed: () => submitCode(),
                    ),
                  ),
                  TextButton (
                    child: Text (
                      'Resend Email',
                      style: TextStyle (
                        color: activeColor
                      )
                    ),
                    onPressed: () => sendCode(),
                  )
                ]
              ),
            ),
          ],
        )
      )
    );
  }
}


//! --- ALERT DIALOG WIDGET ---


alert(String message, BuildContext context) {
  showDialog (
    context: context,
    builder: (context) {
      return AlertDialog (
        backgroundColor: backgroundColor,
        content: Text (
          message,
          style: TextStyle (
            color: textColor,
            fontSize: 17.0
          )
        ),
        actions: [
          TextButton(
            child: Text (
              'Okay',
              style: TextStyle (
                color: activeColor
              )
            ),
            onPressed: () {
              Navigator.of(context).pop();
            },
          ),
        ],
      );
    }
  );
}


//! --- CONFIRMATION DIALOG WIDGET ---


confirm(Widget content, Function yesAction, BuildContext context) {
  showDialog (
      context: context,
      builder: (context) {
        return AlertDialog (
          backgroundColor: backgroundColor,
          content: content,
          actions: [
            TextButton (
              child: Text (
                'Yes',
                style: TextStyle (
                  color: activeColor
                )
              ),
              onPressed: () {
                Navigator.of(context).pop();
                yesAction();
              },
            ),
            TextButton(
              child:  Text (
                'No',
              style: TextStyle (
                color: activeColor
              )
              ),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      }
    );
}


//! --- PREVENT OVERSCROLL GLOW ---

// I got this bit of code from here:
// https://stackoverflow.com/questions/51119795/how-to-remove-scroll-glow
class RemoveGlow extends ScrollBehavior {
  @override
  Widget buildOverscrollIndicator (
      BuildContext context, Widget child, ScrollableDetails details) {
    return child;
  }
}


//! --- SEND HTTP REQUEST ---


sendRequest(String path, var queries, BuildContext context, [Map<String, String>? postBody]) async {
  try {await requests.get(Uri.parse('http://$ip:8457/test_api')).timeout(const Duration(seconds: 15));}
  catch(e) {
    alert('The server is down', context);
    return 0;
  }

  try {
    String request = 'http://$ip:8457/$path?'; // Create address to send request to
    queries.forEach((k, v) {
      request += '$k=$v&'; // Add request queries
    });
    if (postBody == null) {
      requests.Response response = await requests.get(Uri.parse(request)); // Make GET request
      return json.decode(response.body);
    } else {
      // Make POST request
      requests.Response response = await requests.post(
        Uri.parse(request),
        body: jsonEncode(postBody),
        headers: {'Content-Type':'application/json','accept':'application/json'}
      );
      return json.decode(response.body);
    }
  }
  catch(e) {
    alert('Something went wrong', context);
    return 0;
  }
}
