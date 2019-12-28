import 'package:flutter/material.dart';
import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:sign_app/screens/progress.dart';
import 'package:sign_app/models/user.dart';
import 'package:flutter/src/widgets/text.dart';
import 'package:sign_app/screens/activity_feed.dart';
import 'package:transparent_image/transparent_image.dart';
final _firestore=Firestore.instance;
class Search extends StatefulWidget {
  static String id='search_screen';
  @override
  _SearchState createState() => _SearchState();
}

class _SearchState extends State<Search> {
  TextEditingController searchController = TextEditingController();
  Future<QuerySnapshot> searchResultsFuture;

  handleSearch(String query) {
    Future<QuerySnapshot> users = _firestore.collection('Users')
        .where("username", isGreaterThanOrEqualTo: query)
        .getDocuments();
    setState(() {
      searchResultsFuture = users;
    });
  }

  clearSearch() {
    searchController.clear();
  }

  AppBar buildSearchField() {
    return AppBar(
        backgroundColor: Colors.white,
        title: Container(
          width: 500.0,
          child: TextFormField(
            controller: searchController,
            decoration: InputDecoration(
              hintText: "Search for a user..",
              filled: true,
              prefixIcon: Icon(
                Icons.account_box,
                size: 28.0,
              ),
              suffixIcon: IconButton(
                icon: Icon(Icons.clear),
                onPressed: clearSearch,
              ),
            ),
            onFieldSubmitted: handleSearch,
          ),
        ),

    );
  }

  Container buildNoContent() {
    return Container(
      color: Colors.white,
      child: Center(
        child: ListView(
          shrinkWrap: true,
          children: <Widget>[

          ],
        ),
      ),
    );
  }
  buildSearchResults() {
    return FutureBuilder(
      future: searchResultsFuture,
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return circularProgress();
        }
        if(snapshot.connectionState == ConnectionState.waiting){
          return circularProgress();
        }
        List<UserResult> searchResults = [];
        final doc = snapshot.data.documents;
        snapshot.data.documents.forEach((doc) {
          User user = User.fromDocument(doc);
          UserResult searchResult = UserResult(user);
          searchResults.add(searchResult);
        });

        return ListView(
          children: searchResults,
        );
      },
    );


  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: buildSearchField(),
      body:  searchResultsFuture == null ? buildNoContent() : buildSearchResults(),

    );
  }
}

class UserResult extends StatelessWidget {
  final User user;

  UserResult(this.user);

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      child: Column(
        children: <Widget>[
          GestureDetector(
            onTap: () => showProfile(context, profileId: user.id),
            child: Card(
              margin: EdgeInsets.all(8),
              elevation: .8,
              child: ListTile(
                leading: Container(
                  child:ClipRRect(
                    borderRadius: BorderRadius.circular(25.0),
                    child: FadeInImage.memoryNetwork(
                      placeholder: kTransparentImage,
                      image: user.photoUrl,
                    ),
                  ),
                ),
                title: Text(
                  user.username ,
                  style:
                  TextStyle(color: Colors.blue, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ),

        ],
      ),
    );
  }
}