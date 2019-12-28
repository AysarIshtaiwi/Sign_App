import 'dart:ui';
import 'package:sign_app/main.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:sign_app/screens/Profile.dart';
import 'package:sign_app/screens/search.dart';
import 'package:sign_app/screens/CameraHomeScreen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:sign_app/models/user.dart';
import 'package:sign_app/screens/activity_feed.dart';
import 'package:sign_app/screens/friend.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:animated_text_kit/animated_text_kit.dart';
final GoogleSignIn googleSignIn = GoogleSignIn();
final _auth=FirebaseAuth.instance;
final usersRef = Firestore.instance.collection('Users');
FirebaseUser user_current;
User currentUser;
bool isAuth = false;
class Home extends StatefulWidget {
  static String id='home_screen';
  @override
  _HomeState createState() => _HomeState();
}
class _HomeState extends State<Home>  with SingleTickerProviderStateMixin{
  //bool isAuth = false;
  PageController pageController;
  int pageIndex = 0;
  AnimationController controller;
  Animation animation;
  void initState() {
    super.initState();
    getcurrentuser();
    pageController = PageController();
    controller=AnimationController(
      duration: Duration(seconds: 1),
      vsync: this,
    );
    animation=CurvedAnimation(parent: controller,curve: Curves.easeIn);
    controller.forward();
    animation.addStatusListener((status){
    });
    controller.addListener((){
      setState(() {
      });
    });
    googleSignIn.onCurrentUserChanged.listen((account) async {
      await handleSignIn(account);
    }, onError: (err) {
      //print('Error signing in: $err');
    });
    // Reauthenticate user when app is opened
    googleSignIn.signInSilently(suppressErrors: false).then((account) async {
      await handleSignIn(account);
    }).catchError((err) {
      //print('Error signing in: $err');
    });
  }
  handleSignIn(GoogleSignInAccount account) async{
    if (account != null) {
      await createUserInFirestore();
      setState(() {
        isAuth = true;
      });
    } else {
      setState(() {
        isAuth = false;
      });
    }
  }

  createUserInFirestore() async {
    final GoogleSignInAccount user = googleSignIn.currentUser;
    DocumentSnapshot doc = await usersRef.document(user.id).get();

    if (!doc.exists ) {
      usersRef.document(user.id).setData({
        "id": user.id,
        "username": user.displayName,
        "photoUrl": user.photoUrl,
        "email": user.email,
      });

      doc = await usersRef.document(user.id).get();
    }

    currentUser = User.fromDocument(doc);
  }

  @override
  void dispose() {
    pageController.dispose();
    super.dispose();
  }

  void getcurrentuser() async{
    try {
      final user = await _auth.currentUser();
      if(user !=null){
        user_current = user;
        DocumentSnapshot doc = await usersRef.document(user_current.uid).get();
        currentUser = User.fromDocument(doc);
      }

    }catch(e){
      print(e.toString());
    }
  }
  login() {
    googleSignIn.signIn();
  }




  onPageChanged(int pageIndex) {
    setState(() {
      this.pageIndex = pageIndex;
    });
  }
  onTap(int pageIndex) {
    pageController.animateToPage(
      pageIndex,
      duration: Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }
  Scaffold buildAuthScreen() {
    return Scaffold(
      body: PageView(
        children: <Widget>[
          Contact(),
          ActivityFeed(),
          CameraHomeScreen(cameras),
          Search(),
          Profile(profileId: currentUser?.id),
        ],
        controller: pageController,
        onPageChanged: onPageChanged,
        physics: NeverScrollableScrollPhysics(),
      ),
      bottomNavigationBar: CupertinoTabBar(
          currentIndex: pageIndex,
          onTap: onTap,
          activeColor: Theme.of(context).primaryColor,
          items: [
            BottomNavigationBarItem(icon: Icon(Icons.group)),
            BottomNavigationBarItem(icon: Icon(Icons.notifications)),
            BottomNavigationBarItem(
              icon: Icon(
                Icons.photo_camera,
                size: 35.0,
              ),
            ),
            BottomNavigationBarItem(icon: Icon(Icons.search)),
            BottomNavigationBarItem(icon: Icon(Icons.account_circle)),
          ]),
    );
    // return RaisedButton(
    //   child: Text('Logout'),
    //   onPressed: logout,
    // );
  }
  Scaffold buildUnAuthScreen() {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Padding(
        padding: EdgeInsets.symmetric(horizontal: 24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Row(
              children: <Widget>[
                Hero(
                  tag:'logo',
                  child: Container(
                    child: Image.asset('images/ic_flutter_devs_logo.png'),
                    height: animation.value *40,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 25.0),
                  child: ColorizeAnimatedTextKit(
                    text:['Sign Chat'],
                    textStyle: TextStyle(
                      fontSize: 55.0,
                      fontWeight: FontWeight.w700,
                      fontStyle: FontStyle.italic,
                    ),
                      colors: [
                        Colors.black87,
                        Colors.grey,
                        Colors.white,
                        Colors.grey,
                        Colors.black54,
                        Colors.black87,
                      ],
                      textAlign: TextAlign.start,
                      alignment: AlignmentDirectional.topStart // or Alignment.topLeft
                  ),
                ),
              ],
            ),
            SizedBox(
              height: 48.0,
            ),
            GestureDetector(
              onTap: login,
              child: Container(
                width: 260.0,
                height: 60.0,
                decoration: BoxDecoration(
                  image: DecorationImage(
                    image: AssetImage(
                      'images/google_button.png',
                    ),
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            )
          ],
        ),
      ),
    );
  }
  @override
  Widget build(BuildContext context) {
    return isAuth ? buildAuthScreen() : buildUnAuthScreen();
  }
}