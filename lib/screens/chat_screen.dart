import 'package:sign_app/main.dart';
import 'package:sign_app/models/User.dart';
import 'package:sign_app/screens/CameraChatScreen.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/widgets.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';
final GoogleSignIn googleSignIn = GoogleSignIn();
final DateTime timestamp = DateTime.now();
final _firestore = Firestore.instance;
final userref = _firestore.collection('Users');
User loggedin;
User currentuser;
String id;
User frienduser;


class ChatScreen extends StatefulWidget {
  static String id = 'chat_screen';
  final String profileId;
  static String result;

  ChatScreen({this.profileId});

  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  String friendId;
  String current_email;
  String friendName;
  String friendemail;
  final messageTextController = TextEditingController();
  final _auth = FirebaseAuth.instance;

  String messagetext;

  @override
  void initState() {
    super.initState();
    getcurrentuser();
    getfrienduser();
  }

  void getcurrentuser() async {
    try {
      GoogleSignInAccount user = await googleSignIn.currentUser;
      if(user == null){
        print("user null **************************************************");
        user = await googleSignIn.signInSilently();
      }
      if (user != null) {
        DocumentSnapshot doc = await userref.document(user.id).get();
        print("insiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiide");
        currentuser = User.fromDocument(doc);
        setState(() {
          current_email=currentuser.email;
        });
      }
    } catch (e) {
      print(e);
    }
  }
  toCamera() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => CameraChatScreen(cameras)),
    );
    setState(() {
      messageTextController.text=result;
      messagetext=result;

    });


    print("resaaaaaaaaaaaaaaalt"+ await result);

  }
  toCamera1()  {
    Navigator.of(this.context).push(new MaterialPageRoute(
        builder: (BuildContext context) =>CameraChatScreen(cameras)));


  }

  getfrienduser() async {
    try {
      DocumentSnapshot doc =
      await _firestore.collection('Users').document(widget.profileId).get();
      setState(() {
        frienduser = User.fromDocument(doc);
        friendId = frienduser.id;
        friendName = frienduser.username;
        friendemail = frienduser.email;
      });
    } catch (e) {
      print(e.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: null,
        title: Text(friendName == null ? "" : friendName),
        backgroundColor: Colors.lightBlueAccent,
      ),
      body: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            StreamBuilder<QuerySnapshot>(
              stream: _firestore.collection('Messages').orderBy('timestamp', descending: false).snapshots(),
              builder: (context, snapshot) {
                if(snapshot.connectionState == ConnectionState.waiting){
                  return CircularProgressIndicator();
                }
                if(snapshot.hasError){
                  return CircularProgressIndicator();
                }
                if (!snapshot.hasData) {
                  return Center(
                    child: CircularProgressIndicator(
                      backgroundColor: Colors.lightBlueAccent,
                    ),
                  );
                }
                final messages = snapshot.data.documents;
                List<MessageBubble> messageBubbles = [];
                for (var message in messages) {
                  final messagetext = message.data['text'];
                  final messagesender = message.data['sender'];
                  final currentuseremail = current_email;
                  final messagesendto = message.data['sendto'];
                  final messageBubble = MessageBubble(
                    sender: messagesender,
                    text: messagetext,
                    isme: currentuseremail == messagesender,
                    isfriend: friendemail == messagesendto,
                  );
                  if ((messagesender == currentuseremail &&
                      messagesendto == friendemail) ||
                      (messagesender == friendemail &&
                          messagesendto == currentuseremail)) {
                    messageBubbles.add(messageBubble);
                  }
                }
                return Expanded(
                  child: ListView(
                    reverse: true,
                    padding: EdgeInsets.all(10.0),
                    children: messageBubbles,
                  ),
                );

              },
            ),
            Container(
              decoration: BoxDecoration(
                border: Border(
                  top: BorderSide(color: Colors.lightBlueAccent, width: 2.0),
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: <Widget>[
                  Expanded(
                    child: TextField(
                      controller: messageTextController,
                      onChanged: (value) {
                        messagetext = value;
                        print(messagetext+"##############");
                      },
                      decoration: InputDecoration(
                        contentPadding: EdgeInsets.symmetric(vertical: 10.0, horizontal: 20.0),
                        hintText: 'Type your message here...',
                        border: InputBorder.none,
                      ),
                    ),
                  ),
                  FlatButton(
                    onPressed: () {
                      toCamera();
//                      Navigator.push(
//                        context,
//                        MaterialPageRoute(
//                          builder: (context) => CameraHomeScreen(
//                            cameras,2,widget.profileId
//                          ),
//                        ),
//                      );
                    },
                    child: Icon(
                      Icons.photo_camera,
                      size: 25.0,
                    ),
                  ),
                  FlatButton(
                    onPressed: () {
                      messageTextController.clear();
                      if(messagetext != null){
                        messageTextController.clear();
                        _firestore.collection('Messages').add({
                          'text': messagetext,
                          'sender': current_email,
                          'sendto': friendemail,
                          'timestamp': timestamp,
                        });
                        messagetext=null;
                      }

                    },
                    child: Text(
                      'Send',
                      style: TextStyle(
                        color: Colors.lightBlueAccent,
                        fontWeight: FontWeight.bold,
                        fontSize: 18.0,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class MessageBubble extends StatelessWidget {
  MessageBubble(
      {this.sender, this.text, this.isme, this.isfriend, this.sendto});

  final String sender;
  final String sendto;
  final String text;
  final bool isme;
  final bool isfriend;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.all(10.0),
      child: Column(
        crossAxisAlignment:
        isme ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: <Widget>[
          // Text(
          // sender,
          //  style: TextStyle(fontSize: 12.0, color: Colors.black54),
          //  ),
          Material(
            borderRadius: isme
                ? BorderRadius.only(
              topLeft: Radius.circular(150.0),
              topRight: Radius.circular(150.0),
              bottomLeft: Radius.circular(150.0),
            )
                : BorderRadius.only(
              topRight: Radius.circular(50.0),
              bottomRight: Radius.circular(50.0),
              topLeft: Radius.circular(50.0),
            ),
            elevation: 5.0,
            color: isme ? Colors.lightBlueAccent : Colors.white,
            child: Text(
              '$text ',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: isme ? Colors.white : Colors.black54,
                fontSize: 15.0,
                height: 2.0,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
