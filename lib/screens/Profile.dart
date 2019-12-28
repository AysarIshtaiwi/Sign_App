import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:sign_app/models/user.dart';
import 'package:flutter/material.dart';
import 'package:sign_app/screens/home.dart' as home;
import 'package:sign_app/screens/header.dart';
import 'package:sign_app/screens/progress.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/services.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:transparent_image/transparent_image.dart';
final GoogleSignIn googleSignIn = GoogleSignIn();
final _firestore = Firestore.instance;
final userref = _firestore.collection('Users');
final DateTime timestamp = DateTime.now();
final _auth = FirebaseAuth.instance;
User currentuser;
FirebaseUser user_current;
User user_profile_owner;
final friendsRef = Firestore.instance.collection('friends');
final activityFeedRef = Firestore.instance.collection('feed');

class Profile extends StatefulWidget {
  final String profileId;

  Profile({this.profileId});

  @override
  _ProfileState createState() => _ProfileState();
}

class _ProfileState extends State<Profile> {

  bool isFriend = false;
  String name;
  String currentUserId;
  String currentUserName;
  String profileUserId;
  String profileUserName;
  String profileUserImg;

  void initState() {
    super.initState();
    getcurrentuser();
    getprofile_owner();
  }

  void getcurrentuser() async {
    try {

       GoogleSignInAccount user = googleSignIn.currentUser;
      if(user == null){
          user = await googleSignIn.signInSilently();
      }
      if (user != null) {
        DocumentSnapshot doc = await _firestore
            .collection('Users')
            .document(user.id)
            .get();
        if (this.mounted) {
          setState(() async{
            currentuser = User.fromDocument(doc);
            currentUserId=currentuser.id;
            currentUserName = currentuser.username;

            checkIfFriend();
          });
        }

      }
    } catch (e) {
      print(e.toString());
    }
  }

  void getprofile_owner() async {
    try {
      DocumentSnapshot doc =
          await _firestore.collection('Users').document(widget.profileId).get();
      if (this.mounted) {
        setState(() {
          user_profile_owner = User.fromDocument(doc);
          profileUserId = user_profile_owner.id;
          profileUserName = user_profile_owner.username;
          profileUserImg=user_profile_owner.photoUrl;
        });
      }
    } catch (e) {
      print(e.toString());
    }
  }

  checkIfFriend() async {
    DocumentSnapshot doc = await friendsRef
        .document(widget.profileId)
        .collection('userFriends')
        .document(currentUserId)
        .get();
    if (this.mounted) {
      setState(() {
        isFriend =  doc.exists;
      });
    }

  }


  Container buildButton({String text, Function function}) {
    return Container(
      padding: EdgeInsets.only(top: 2.0),
      child: FlatButton(
        onPressed: function,
        child: Container(
          width: 250.0,
          height: 27.0,
          child: Text(
            text,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: isFriend ? Colors.black : Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: isFriend ? Colors.white : Colors.blue,
            border: Border.all(
              color: isFriend ? Colors.grey : Colors.blue,
            ),
            borderRadius: BorderRadius.circular(5.0),
          ),
        ),
      ),
    );
  }
  Container buildmyprofile({String text, Function function}) {
    return Container(
      padding: EdgeInsets.only(top: 2.0),
      child: FlatButton(
        onPressed: function,
        child: Container(
          width: 200.0,
          height: 27.0,
          child: Text(
            text,

          ),

        ),
      ),
    );
  }

  buildProfileButton() {
    bool isProfileOwner = currentUserId == widget.profileId;
    if (isProfileOwner) {
      return buildButton(
        text: "Logout",
        function: logout,
      );
    }else  if (isFriend) {
      return buildButton(
        text: "Unfriend",
        function: handleunfriendUser,
      );
    } else if (!isFriend) {
      return buildButton(
        text: "Add friend",
        function: handlefriendUser,
      );
    }
  }

   logout() async{
     await googleSignIn.signOut();
     SystemNavigator.pop();


   }
  handleunfriendUser() {
    if (this.mounted) {
      setState(() {
        isFriend = false;
      });
    }

    // Make auth user follower of THAT user (update THEIR followers collection)
    friendsRef
        .document(widget.profileId)
        .collection('userFriends')
        .document(currentUserId)
        .get()
        .then((doc) {
      if (doc.exists) {
        doc.reference.delete();
      }
    });

    // Put THAT user on YOUR friend collection (update your following collection)
    friendsRef
        .document(currentUserId)
        .collection('userFriends')
        .document(widget.profileId)
        .get()
        .then((doc) {
      if (doc.exists) {
        doc.reference.delete();
      }
    });

    // add activity feed item for that user to notify about new follower (us)
    activityFeedRef
        .document(widget.profileId)
        .collection('feedItems')
        .document(currentUserId)
          ..get().then((doc) {
            if (doc.exists) {
              doc.reference.delete();
            }
          });
  }

  handlefriendUser() {
    if (this.mounted) {
      setState(() {
        isFriend = true;
      });
    }
    // Make auth user friend of THAT user (update THEIR followers collection)
    friendsRef
        .document(widget.profileId)
        .collection('userFriends')
        .document(currentUserId)
        .setData({
      "username": currentUserName,
      "userId": currentUserId,
      "userProfileImg": currentuser.photoUrl,
      "timestamp": timestamp,
    });
    // Put THAT user on YOUR friend collection (update your following collection)
    friendsRef
        .document(currentUserId)
        .collection('userFriends')
        .document(widget.profileId)
        .setData({
      "username": profileUserName,
      "userId": profileUserId,
      "userProfileImg": profileUserImg,
      "timestamp": timestamp,
    });
    // add activity feed item for that user to notify about new follower (us)
    activityFeedRef
        .document(widget.profileId)
        .collection('feedItems')
        .document(currentUserId)
        .setData({
      "type": "added you",
      "ownerId": widget.profileId,

      "username": currentUserName,
      "userId": currentUserId,
      "userProfileImg": currentuser.photoUrl,
      "timestamp": timestamp,
    });
  }

  buildProfileHeader() {
    return FutureBuilder(
      future: userref.document(widget.profileId).get(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return circularProgress();
        }
        if(snapshot.connectionState == ConnectionState.waiting){
          return circularProgress();
        }
        return Padding(
          padding: EdgeInsets.all(20.0),
          child: Column(
            children: <Widget>[
              Row(
                children: <Widget>[
                  Container(
                    padding: EdgeInsets.only(right: 15,left: 15,top: 20),
                    alignment: Alignment.center,
                    child:ClipRRect(
                      borderRadius: BorderRadius.circular(25.0),
                    child: FadeInImage.memoryNetwork(
                      imageScale:0.3,
                      placeholder: kTransparentImage,
                      image: profileUserImg,
                    ),
                  ),
                  ),
                ],
              ),
              Container(
                alignment: Alignment.center,
                padding: EdgeInsets.only(top: 12.0),
                child: Center(
                  child: Text(
                    user_profile_owner.username,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16.0,
                    ),
                  ),
                ),
              ),
              Container(
                alignment: Alignment.center,
                child:
                  buildProfileButton(),
              ),

            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: header(context, titleText: "Profile"),
      body: ListView(
        children: <Widget>[buildProfileHeader()],
      ),
    );
  }
}
