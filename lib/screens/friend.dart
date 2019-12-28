import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:sign_app/screens/header.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:sign_app/screens/home.dart' as home;
import 'package:sign_app/models//User.dart';
import 'package:sign_app/screens/progress.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:transparent_image/transparent_image.dart';
import 'chat_screen.dart';
import 'package:google_sign_in/google_sign_in.dart';

final GoogleSignIn googleSignIn = GoogleSignIn();
final friendsRef = Firestore.instance.collection('friends');
final _firestore = Firestore.instance;
final activityFeedRef = Firestore.instance.collection('feed');
final _auth = FirebaseAuth.instance;
User currentuser;
FirebaseUser user_current;

class Contact extends StatefulWidget {
  @override
  _ContactState createState() => _ContactState();
}

class _ContactState extends State<Contact> {
  String currentUserId;

  String currentUserName;

  void initState() {
    super.initState();
    getcurrentuser();
  }

  void getcurrentuser() async {
    print('enter getcurrentuser metod');
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
        setState(() {
          currentuser = User.fromDocument(doc);
          currentUserId = currentuser.id;
          currentUserName = currentuser.username;
        });
      }
    } catch (e) {
      print(e.toString());
    }
  }


  getContact() async {
    QuerySnapshot snapshot = await friendsRef
        .document(currentUserId)
        .collection('userFriends')
        .orderBy('timestamp', descending: true)
        .limit(50)
        .getDocuments();
    List<ContactItem> contact = [];
    snapshot.documents.forEach((doc) {
      contact.add(ContactItem.fromDocument(doc));
      // print('Activity Feed Item: ${doc.data}');
    });
    return contact;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: header(context, titleText: "Friends"),
      body: Container(
          child: FutureBuilder(
        future: getContact(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return circularProgress();
          } else if (snapshot.hasError) {
            return circularProgress();
          }
            return ListView(
              children: snapshot.data,
            );

        },
      )),
    );
  }
}

Widget mediaPreview;

class ContactItem extends StatelessWidget {
  final String username;
  final String userId;

  final String userProfileImg;
  final Timestamp timestamp;

  ContactItem({
    this.username,
    this.userId,
    this.userProfileImg,
    this.timestamp,
  });

  factory ContactItem.fromDocument(DocumentSnapshot doc) {
    return ContactItem(
      username: doc.data['username'],
      userId: doc.data['userId'],
      userProfileImg: doc['userProfileImg'],
      timestamp: doc.data['timestamp'],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: 2.0),
      child: Container(
        color: Colors.white54,
        child: Card(
          margin: EdgeInsets.all(8),
          elevation: .9,
          child: ListTile(
            title: GestureDetector(
              onTap: () => showChatScreen(context, profileId: userId),
              child: RichText(
                overflow: TextOverflow.ellipsis,
                text: TextSpan(
                    style: TextStyle(
                      fontSize: 14.0,
                      color: Colors.black,
                    ),
                    children: [
                      TextSpan(
                        text: username,
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ]),
              ),
            ),
            leading: Container(
              child:ClipRRect(
                borderRadius: BorderRadius.circular(25.0),
                child: FadeInImage.memoryNetwork(
                  placeholder: kTransparentImage,
                  image: userProfileImg,
                ),
              ),
                ),
            subtitle: Text(
              timeago.format(timestamp.toDate()),
              overflow: TextOverflow.ellipsis,
            ),
            trailing: mediaPreview,
          ),
        ),
      ),
    );
  }
}

showChatScreen(BuildContext context, {String profileId}) {
  print(profileId);
  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (context) => ChatScreen(
        profileId: profileId,
      ),
    ),
  );
}
