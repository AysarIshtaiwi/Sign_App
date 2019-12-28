import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:sign_app/screens/profile.dart';
import 'package:sign_app/screens/header.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:sign_app/screens/home.dart' as home;
import 'package:sign_app/models//User.dart';
import 'package:sign_app/screens/progress.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:transparent_image/transparent_image.dart';
final _firestore=Firestore.instance;
final GoogleSignIn googleSignIn = GoogleSignIn();
final activityFeedRef = Firestore.instance.collection('feed');
final _auth=FirebaseAuth.instance;
User currentuser;
FirebaseUser user_current;
class ActivityFeed extends StatefulWidget {
  @override
  _ActivityFeedState createState() => _ActivityFeedState();
}

class _ActivityFeedState extends State<ActivityFeed> {
 String currentUserId ;
 String currentUserName ;
  void initState() {
    super.initState();
    getcurrentuser();
  }
  void getcurrentuser() async{
    print('enter getcurrentuser metod');
    try {
      GoogleSignInAccount user = googleSignIn.currentUser;
      if(user == null){
        user = await googleSignIn.signInSilently();
      }
      print('assign user to current user from auth');
      if(user !=null){
        DocumentSnapshot doc = await _firestore.collection('Users').document(user.id).get();
        if (this.mounted) {
          setState(() {
            currentuser = User.fromDocument(doc);
            currentUserId=currentuser.id;
            currentUserName=currentuser.username;
          });
        }

      }

    }catch(e){
      print(e.toString());
    }
  }
  getActivityFeed() async {
    QuerySnapshot snapshot = await activityFeedRef
        .document(currentUserId)
        .collection('feedItems')
        .orderBy('timestamp', descending: true)
        .limit(50)
        .getDocuments();
    List<ActivityFeedItem> feedItems = [];
    snapshot.documents.forEach((doc) {
      feedItems.add(ActivityFeedItem.fromDocument(doc));
      // print('Activity Feed Item: ${doc.data}');
    });
    return feedItems;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: header(context, titleText: "Activity Feed"),
      body: Container(
          child: FutureBuilder(
            future: getActivityFeed(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return circularProgress();
              }
              if(snapshot.connectionState == ConnectionState.waiting){
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
String activityItemText;

class ActivityFeedItem extends StatelessWidget {
  final String username;
  final String userId;
  final String type;
  final String userProfileImg;
  final Timestamp timestamp;

  ActivityFeedItem({
    this.username,
    this.userId,
    this.type,
    this.userProfileImg,
    this.timestamp,
  });

  factory ActivityFeedItem.fromDocument(DocumentSnapshot doc) {
    return ActivityFeedItem(
      username: doc.data['username'],
      userId: doc.data['userId'],
      type: doc.data['type'],
      userProfileImg: doc['userProfileImg'],
      timestamp: doc.data['timestamp'],
    );
  }

  configureMediaPreview() {
      mediaPreview = Text('');
    if (type == 'message') {
      activityItemText = "send you a message";
    } else if (type == 'added you') {
      activityItemText = "add you as friend";
    }  else {
      activityItemText = "Error: Unknown type '$type'";
    }
  }

  @override
  Widget build(BuildContext context) {
    configureMediaPreview();
    return Padding(
      padding: EdgeInsets.only(bottom: 2.0),
      child: Container(
        color: Colors.white54,
        child: Card(
          margin: EdgeInsets.all(8),
          elevation: .9,
          child: ListTile(
            title: GestureDetector(
              onTap: () => showProfile(context, profileId: userId),
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
                      TextSpan(
                        text: ' $activityItemText',
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
showProfile(BuildContext context, {String profileId}) {
  print(profileId);
  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (context) =>
          Profile(
            profileId: profileId,
          ),
    ),
  );
}
