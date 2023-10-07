import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'pages.dart';
import 'package:flutter_firebase/constants/color_constants.dart';
import 'dart:io';

class ProfileScreen extends StatefulWidget {
  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}
class _ProfileScreenState extends State<ProfileScreen> {

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final DatabaseReference _databaseReference = FirebaseDatabase.instance.ref();
  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  //String? _fcmToken;
  Map<String, dynamic>? userData;

  @override
  void initState() {
    super.initState();
    _fetchUserData();
    _getFCMToken();
  }

  Future<void> _fetchUserData() async {
    try {
      User? user = _auth.currentUser;
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? userId = prefs.getString('userId');

      if (user != null) {
        DataSnapshot snapshot =
        await _databaseReference.child('Staffs/$userId').get();
        var snapshotValue = snapshot.value;

        if (snapshotValue is Map<dynamic, dynamic>) {
          setState(() {
            userData = {
              'UserName': snapshotValue['UserName'],
              'UserId': snapshotValue['UserId'],
              'EmailAddress': snapshotValue['Profile']['EmailAddress'],
              'ContactNo': snapshotValue['Profile']['ContactNo'],
              'Remark1': snapshotValue['Profile']['Remark1']
            };
            _checkRemark1();
          });
        } else {}
      } else {}
    } catch (e) {}
  }

  Future<void> _getFCMToken() async {
    try {
      // Request permission for notifications (optional, but recommended)
      NotificationSettings settings = await _firebaseMessaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );

      if (settings.authorizationStatus == AuthorizationStatus.authorized) {
        // Permission granted
        String? fcmToken = await _firebaseMessaging.getToken();
        SharedPreferences prefs = await SharedPreferences.getInstance();
        String? userId = prefs.getString('userId');
        await _databaseReference
            .child('Staffs/$userId/Profile/Remark3')
            .set(fcmToken);
      } else {
        print('Permission denied');
      }
    } catch (e) {
      print('Error getting FCM token: $e');
    }
  }

  Future<void> _signOut(BuildContext context) async {
    try {
      await FirebaseAuth.instance.signOut();
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => LoginPage()),
            (Route<dynamic> route) => false,
      );
    } catch (e) {}
  }

  void _checkRemark1() {
    if (userData != null) {
      String? remark1Value = userData!['Remark1'];
      if (remark1Value == null || remark1Value.isEmpty) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => FacePageR(),
            fullscreenDialog: true,
          ),
        );
      }
    }
  }

  Future<bool> _onBackPressed() async {
    bool confirmExit = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Confirm Exit'),
        content: Text('Are you sure you want to quit the app?'),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text('No'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop(true);
              // Close the app when "Yes" is pressed
              exit(0); // This will exit the app
            },
            child: Text('Yes'),
          ),
        ],
      ),
    );

    return confirmExit; // Ensure that we return false if the dialog is dismissed
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _onBackPressed, // Intercept the back button press
      child: Scaffold(
        appBar: AppBar(
          title: Text('Profile'),
          automaticallyImplyLeading: false,
          actions: <Widget>[
            IconButton(
              icon: Icon(Icons.logout),
              onPressed: () {
                _showLogoutConfirmationDialog(context);
              },
            ),
          ],
        ),
        body: Column(
          children: <Widget>[
            SizedBox(height: 16),
            Expanded(
              child: Align(
                alignment: Alignment.topCenter,
                child: _buildUserData(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUserData() {
    if (userData == null) {
      return CircularProgressIndicator();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: <Widget>[
        GestureDetector(
          onTap: () {
            _showImagePreviewDialog(userData!['Remark1'] ?? '');
          },
          child: Stack(
            children: [
              Container(
                width: 150,
                height: 150,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: ColorConstants.themeColor,
                    width: 3.0,
                  ),
                ),
                child: ClipOval(
                  child: Image.network(
                    userData!['Remark1'] ?? '',
                    width: 150,
                    height: 150,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Center(
                        child: Icon(
                          Icons.error_outline,
                          size: 100,
                          color: ColorConstants.orangeColor,
                        ),
                      );
                    },
                  ),
                ),
              ),
              Positioned(
                bottom: 10,
                right: 10,
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: ColorConstants.greyColor,
                  ),
                  child: IconButton(
                    icon: Icon(
                      Icons.edit,
                      color: ColorConstants.whiteColor,
                    ),
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => FacePage(),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: 16),
        Card(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20.0),
          ),
          elevation: 3,
          child: ListTile(
            leading: Icon(Icons.person),
            title: Text(
              'Name',
              style: TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
            subtitle: Text(userData!['UserName']),
          ),
        ),
        Card(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20.0),
          ),
          elevation: 3,
          child: ListTile(
            leading: Icon(Icons.account_circle),
            title: Text(
              'User ID',
              style: TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
            subtitle: Text(userData!['UserId']),
          ),
        ),
        Card(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20.0),
          ),
          elevation: 3,
          child: ListTile(
            leading: Icon(Icons.email),
            title: Text(
              'Email Address',
              style: TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
            subtitle: Text(userData!['EmailAddress']),
          ),
        ),
        Card(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20.0),
          ),
          elevation: 3,
          child: ListTile(
            leading: Icon(Icons.phone),
            title: Text(
              'Contact No',
              style: TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
            subtitle: Text(userData!['ContactNo']),
          ),
        ),
      ],
    );
  }

  void _showImagePreviewDialog(String imageUrl) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          child: Container(
            width: double.infinity,
            child: Image.network(
              imageUrl,
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) {
                // Handle the error here and return a fallback widget or message.
                return Container(
                  width: double.infinity,
                  height: 200, // Set a suitable height for the error message or image.
                  alignment: Alignment.center,
                  child: Text(
                    "Image not found\nPlease upload your face again",
                    style: TextStyle(fontSize: 20, color: ColorConstants.orangeColor),
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }


  Future<void> _showLogoutConfirmationDialog(BuildContext context) async {
    return showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Confirm Logout'),
          content: Text('Are you sure you want to log out?'),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                _signOut(context);
              },
              child: Text('Logout'),
            ),
          ],
        );
      },
    );
  }
}

