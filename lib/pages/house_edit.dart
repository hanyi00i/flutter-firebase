import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:shared_preferences/shared_preferences.dart';

class HouseEditScreen extends StatefulWidget {
  final Function()? refreshCallback; // Callback function
  HouseEditScreen({this.refreshCallback});
  @override
  _HouseEditScreenState createState() => _HouseEditScreenState();
}

class _HouseEditScreenState extends State<HouseEditScreen> {
  final DatabaseReference _databaseReference = FirebaseDatabase.instance.ref();

  TextEditingController usernameController = TextEditingController();
  TextEditingController emailController = TextEditingController();
  TextEditingController contactNoController = TextEditingController();

  Map<String, dynamic>? userData; // Store the fetched user data here

  @override
  void initState() {
    super.initState();
    _fetchUserData();
  }

  // Function to fetch user data from the database
  Future<void> _fetchUserData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? userId = prefs.getString('userId');
    DataSnapshot snapshot = await _databaseReference.child('Staffs/$userId')
        .get();
    if (snapshot.value != null) {
      setState(() {
        userData =
        Map<String, dynamic>.from(snapshot.value as Map<dynamic, dynamic>);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Create New User'),
      ),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          children: [
            if (userData != null) ...[
              TextField(
                controller: usernameController,
                decoration: InputDecoration(
                  labelText: 'Username',
                  hintText: userData!['UserName'], // Pre-fill with user data
                ),
              ),
              TextField(
                controller: emailController,
                decoration: InputDecoration(
                  labelText: 'Email Address',
                  hintText: userData!['Profile']['EmailAddress'], // Pre-fill with user data
                ),
              ),
              TextField(
                controller: contactNoController,
                decoration: InputDecoration(
                  labelText: 'Contact No',
                  hintText: userData!['Profile']['ContactNo'], // Pre-fill with user data
                ),
              ),
              ElevatedButton(
                onPressed: () {
                  _createNewUser();
                },
                child: Text('Save Changes'),
              ),
            ] else ...[
              CircularProgressIndicator()
            ],
          ],
        ),
      ),
    );
  }

  void _createNewUser() async {
    if (userData == null) {
      return; // Don't proceed if userData is not available
    }

    // Get the data from the text controllers
    String newUsername = usernameController.text;
    String newEmail = emailController.text;
    String newContactNo = contactNoController.text;

    // Duplicate the user data and update the relevant fields
    Map<String, dynamic> newUser = Map<String, dynamic>.from(userData!);
    newUser['UserName'] = newUsername;

    // Update the EmailAddress and ContactNo fields within the Profile section
    newUser['Profile']['EmailAddress'] = newEmail;
    newUser['Profile']['ContactNo'] = newContactNo;
    newUser['Profile']['Remark1'] = "";

    // Generate a newUserId by appending the last 3 characters of the existing UserId
    String userId = userData!['UserId'];
    String newUserId = userId + userId.substring(userId.length - 3);

    while (await _checkUserExists(newUserId)) {
      newUserId += userId.substring(userId.length - 3);
    }

    // Save the modified user data in the Firebase Realtime Database under the new user key
    newUser['UserId'] = newUserId;
    _databaseReference.child('Staffs/$newUserId').set(newUser);
    if (widget.refreshCallback != null) {
      widget.refreshCallback!();
    }
    Navigator.pop(context);
  }

  Future<bool> _checkUserExists(String userId) async {
    DataSnapshot snapshot = await _databaseReference.child('Staffs').child(
        userId).get();
    return snapshot.value != null;
  }

}
