import 'package:socket_io_client/socket_io_client.dart' as io;
import 'package:image_picker/image_picker.dart';
import 'package:get_storage/get_storage.dart';
import 'package:http/http.dart' as requests;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:typed_data';
import 'dart:convert';
import 'dart:io';

// Runs when app starts
void main() async {
  await GetStorage.init();
  runApp(const App());
}

String ip = ''; // IP for requests and socket
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
  bool obscurePassword = true; // Whether password is obscured or not
  var passwordVisibleIcon = Icon (
      Icons.remove_red_eye_outlined,
      color: activeColor
    );

  TextEditingController passwordController = TextEditingController();
  TextEditingController usernameController = TextEditingController();

  // Login information submitted
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
    } else if (response['msg'] == 'success') { // User has successfully logged in
      // Write user id and name to device storage
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
              // Title text
              child: Text (
                'Chatty',
                style: TextStyle (
                  fontSize: 70.0,
                  color: textColor
                )
              ),
            ),
            // Rounded box that contains page content
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
                        // 'Sign in' text at top of container
                        child:  Text (
                          'Sign in',
                          style: TextStyle (
                            fontSize: 30.0,
                            color: textColor
                          )
                        ),
                      ),
                    ),
                    // Username input field
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
                    // Password input text field
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
                    // Submit button
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
                    // Sign up text button at bottom of page
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
  bool passwordObscure = true; // Whether password field is obscured
  bool confirmPasswordObscure = true; // Whether confirm password field is obscured
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

  Image profileImage = Image.asset('assets/default_profile.png', width: 200, height: 200, fit: BoxFit.fill); // Set profile picture to default image
  var imageFile = '';

  var userInfoDict = {
    'username': '',
    'email': '',
    'password': '',
    'profile_picture': '',
  };

  // Get image from device
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

  // Create account
  createAccountSubmit() async {
    if (usernameController.text.isNotEmpty && passwordController.text.isNotEmpty && confirmPasswordController.text.isNotEmpty && emailController.text.isNotEmpty) {
      String username = usernameController.text;
      String password = passwordController.text;
      String confirmPassword = confirmPasswordController.text;
      String email = emailController.text;

      // Set profile picture to default picture or picture chosen from device
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
          // Move to email verification page
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
            // 'Create Account' text at top of page
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
            // Username input field
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
            // Password and confirm password input fields
            Row (
              children: [
                Expanded (
                  // Password input field
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
                // Confirm password input field
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
            // Email input field
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
            // Profile picture
            ClipRRect (
              borderRadius: BorderRadius.circular(100.0),
              child: profileImage,
            ),
            SizedBox (
              height: MediaQuery.of(context).size.height / 100
            ),
            // Choose profile picture button
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
            // Create account button
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
            // Text button that takes you to sign in
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
  List groups = List.filled(0, '', growable: true); // List with names of groups that user is a member of

  // Group creation button press
  createGroup() {
    Navigator.of(context).pushNamed('/home/create_group');
  }

  // Gets group names from server
  // Called on page init and refresh button press
  getGroups() async {
    var queries = {'id': storage.read('userid')};
    var response = await sendRequest('get_user_groups', queries, context);
        setState(() {
      groups = response['group_names'];
      groups.sort();
    });
  }

  // Group button is pressed
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
        // Refresh button
        leading: IconButton (
          icon: Icon (
            Icons.refresh,
            size: 40.0,
            color: activeColor
          ),
          onPressed: () {
            getGroups();
        }),
        // 'Home' text
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
        // Profile page button
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
          // Box that contains all groups 
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
                      for (String group in groups) // Create button for each group
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
          // Group creation button
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
  // Each list contains all information needed to display each message
  List messages = List.filled(0, '', growable: true);
  List usernames = List.filled(0, '', growable: true);
  List pfps = List.filled(0, '', growable: true);
  
  bool isAdmin = false; // Whether the user is the admin of the current group
  TextEditingController messageController = TextEditingController();
  String myUsername = '';
  ScrollController scrollController = ScrollController(); // Allows us to determine when user has scrolled to top of messages
  int numScrolled = 0; // Number of times the user has requested messages

  // Determine whether user is admin of group
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

  // Send message to group
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

  // Use socket connection on page init
  initializeSocket() {
    socket.connect();

    var socketQueries = {
      'room': activeGroupName,
      'num_scrolled': numScrolled
    };
    socket.emit('join_room', socketQueries); // Join group on socket server
    socket.emit('get_messages', socketQueries); // Request messages

    // broadcast_message is emitted from the server when a user sends a message to the group
    socket.on('broadcast_message', (messageDict) {
      if (mounted) {
        setState(() {
          messages.insert(0, messageDict['content']);
          usernames.insert(0, messageDict['username']);
          pfps.insert(0, messageDict['profile_picture']);
        });
      }
    });
    
    // get_first_messages is emitted from the server when a user loads pre-existing messages
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

  // Determine whether message is from current device
  isMyMessage(String username) {
    if (username == storage.read('username')) {
      return false;
    } else {
      return true;
    }
  }

  // Load past messages from server
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

    // Add listener that checks for when the user has scrolled all the way up
    scrollController.addListener(() {
      if (scrollController.position.atEdge) {
        if (scrollController.position.pixels != 0) {
          getMoreMessages(); // Request additional messages
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
        // Back button
        leading: IconButton (
          icon: Icon (
            Icons.arrow_back,
            size: 30.0,
            color: activeColor
          ),
          onPressed: () {
            Navigator.of(context).pop();
        }),
        // Title (the name of the current group)
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
        // Settings button
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
              // Container that displays messages
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
                          reverse: true, // Reverse ListView so the scrollbar defaults to the bottom of the page
                          itemBuilder: (BuildContext context, int i) {
                            return Container (
                              margin: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
                              child: Stack (
                                children: [
                                  // This visibility displays if the message is not from the current user
                                  Visibility (
                                    visible: isMyMessage(usernames[i]),
                                    child: Row (
                                      children: [
                                        Container (
                                          margin: const EdgeInsets.only(right: 10.0),
                                          // Profile picture
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
                                                // Username text
                                                child: Text (
                                                  usernames[i],
                                                  style: TextStyle (
                                                      fontSize: 13.0,
                                                      color: textColor
                                                  )
                                                ),
                                              ),
                                              // The flexible widgets allow the text to wrap
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
                                                        // Message text
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
                                  // This visibility displays if the message is from the current user
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
                                                // Username text
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
                                                        // Message text
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
                                          // Profile picture
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
            // Message input text field
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
  List<dynamic> users = List.filled(0, '', growable: true); // List of all users in a group

  // Get all users in group from server
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

  // Add user to group
  addUser(BuildContext context) {
    showDialog (
      context: context,
      builder: (context) {
        return AlertDialog (
          backgroundColor: backgroundColor,
          // Username text field
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
            TextButton (
              // Add user button
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
                    var response = await sendRequest('check_user_existence', queries, context); // Make sure user exists in db
                    
                    if (response['msg'] == 'success') {
                      var queries = {
                        'username': newUsername,
                        'group_name': activeGroupName
                      };
                      var response = await sendRequest('add_user', queries, context); // Send request to add user to group in db
                      
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

  // Delete group
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

  // Remove user from group
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
        // Back button
        leading: IconButton (
          icon: Icon (
            Icons.arrow_back,
            size: 30.0,
            color: activeColor
          ),
          onPressed: () {
            Navigator.of(context).pop();
        }),
        // Title
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
                  // Add user button
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
                  // Delete group button
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
            // Container where users in group are listed
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
                                // Remove user button
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
  // Remove current user from group
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
        var response = await sendRequest('remove_user', queries, context); // Send request to remove user from group
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
        // Back button
        leading: IconButton (
          icon: Icon (
            Icons.arrow_back,
            size: 30.0,
            color: activeColor
          ),
          onPressed: () {
            Navigator.of(context).pop();
        }),
        // Title
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
          // Leave group button
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
  late Image profileImage = Image.asset('assets/default_profile.png', width: 200, height: 200, fit: BoxFit.fill); // Set profile to default before it loads

  // Get info about user
  getInfo() async {
    var queries = {'id': storage.read('userid')};
    var response = await sendRequest('get_user_info', queries, context);
        setState(() {
      username = response['username'];
      email = response['email'];
      profileImage = Image.memory(base64Decode(response['pfp']), width: 200, height: 200, fit: BoxFit.fill);
    });
  }

  // Change profile picture
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

  // Log out of app
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
          // Back button
          icon: Icon (
            Icons.arrow_back,
            size: 30.0,
            color: activeColor
          ),
          onPressed: () {
            Navigator.of(context).pop();
        }),
        // 'Profile' title
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
            // Username text
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
                  // Email icon
                  Icon (
                    Icons.email,
                    color: textColorDark,
                  ),
                  // Email text
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
            // Profile picture
            ClipRRect (
                borderRadius: BorderRadius.circular(100.0),
                child: profileImage,
            ),
            // Change profile picture button
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
            // Logout button
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
  List<String> users = List.filled(0, '', growable: true); // List of users to be added to group

  // Add user to users list
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
                      var response = await sendRequest('check_user_existence', queries, context); // Make sure user exists in db
                      
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

  // Create group
  createGroup() async {
    String groupName = groupNameController.text;
    if (groupName != '') {
      var queries = {
        'user_id': storage.read('userid'),
        'usernames': users.toString(),
        'group_name': groupName
      };
      var response = await sendRequest('create_group', queries, context); // Send request to server to create group
      
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
          // Back button
          icon: Icon (
            Icons.arrow_back,
            size: 30.0,
            color: activeColor
          ),
          onPressed: () {
            Navigator.of(context).pop();
        }),
        // 'Create Group' title
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
              // Group name text field
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
                        // Add user button
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
                      // Create grop button
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
                            // 'Users' text
                            child: Text (
                              'Users',
                              style: TextStyle (
                                fontWeight: FontWeight.bold,
                                color: textColor,
                                fontSize: 25.0,
                              ),
                            ),
                          ),
                          // Create a text and removal button for each user
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

  // Get information from previous page
  final String? username;
  final String? password;
  final String? email;
  final String? pfp;

  @override
  State<VerifyEmailPage> createState() => _VerifyEmailPageState();
}

class _VerifyEmailPageState extends State<VerifyEmailPage> {
  TextEditingController codeController = TextEditingController();

  // Submit verification code
  submitCode() {
    var socketQueries = {
      'code': codeController.text
    };
    socket.emit('submit_code', socketQueries);
  }

  // Send code to email
  sendCode() {
    var socketQueries = {
      'email': widget.email
    };
    socket.emit('email_code', socketQueries);
  }

  // Start and manage the socket connection
  initSocket() {
    socket.connect();
    
    // Add listener for server determining if code is correct or not
    socket.on('code_response', (messageDict) async {
      if (messageDict['msg'] == 'success') {
        var queries = {
          'username': widget.username,
          'email': widget.email,
          'password': widget.password
        };

        var response = await sendRequest('create_account', queries, context); // Send request to create account

        if (response['msg'] == 'success') {
          
          // Write account details to local storage if account creation is successful
          storage.write('userid', response['userid']);
          storage.write('username', widget.username);

          var pfpQueries = {'username': widget.username};
          var pfpPostBody = {'pfp': widget.pfp!};
          await sendRequest('set_pfp', pfpQueries, context, pfpPostBody); // Set user profile picture
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
                // Back button
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
                      // Text telling the user that a code has been emailed
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
                  // Code input field
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
                    // Submit button
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
                  // Resend email button
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
// Usually used to let the user know something has gone wrong


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
// Used for comfirming an action


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
