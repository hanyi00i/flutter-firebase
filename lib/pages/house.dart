import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_firebase/constants/color_constants.dart';
import 'dart:io';
import 'pages.dart';

class HouseScreen extends StatefulWidget {
  @override
  _HouseScreenState createState() => _HouseScreenState();
}

class _HouseScreenState extends State<HouseScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final DatabaseReference _databaseReference = FirebaseDatabase.instance.ref();
  Map<String, dynamic>? userData;
  List<String> houseMembers = [];
  bool master = false;

  @override
  void initState() {
    super.initState();
    _fetchUserData();
  }

  Future<void> _fetchUserData() async {
    try {
      User? user = _auth.currentUser;
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? userId = prefs.getString('userId');
      if (userId != null) { // Check if userId is not null before accessing its length property
        master = userId.length == 5;
      }

      if (user != null) {

        DataSnapshot snapshot = await _databaseReference.child('Staffs').get();
        final dynamic data = snapshot.value;

        if (data is Map<dynamic, dynamic>) {
          // Find house members with the same prefix
          houseMembers.clear();
          houseMembers = data.keys
              .where((key) {
            String prefix = userId?.substring(0, 5) ?? '';
            return key.startsWith(prefix);
          })
              .toList()
              .cast<String>();
          // Sort house members by UserID
          houseMembers.sort();

          if (data.containsKey(userId)) {
            var snapshotValue = data[userId];
            setState(() {
              userData = {
                'UserName': snapshotValue['UserName'],
                'UserId': snapshotValue['UserId'],
                'EmailAddress': snapshotValue['Profile']['EmailAddress'],
                'ContactNo': snapshotValue['Profile']['ContactNo'],
                'Remark1': snapshotValue['Profile']['Remark1']
              };
            });
          }
        }
        }
    } catch (e) {
      print('Error fetching data: $e');
    }
  }


  @override
  Widget build(BuildContext context) {
    bool isMasterUser = master;

    return WillPopScope(
      onWillPop: _onBackPressed,
      child: Scaffold(
        appBar: AppBar(
          title: Text('House'),
          automaticallyImplyLeading: false,
        ),
        body: ListView.builder(
          itemCount: houseMembers.length,
          itemBuilder: (context, index) {
            String memberUserId = houseMembers[index];
            return _buildHouseMemberCard(memberUserId);
          },
        ),
        floatingActionButton: isMasterUser
            ? FloatingActionButton(
          onPressed: () async {
            // Navigate to HouseEditScreen when the button is pressed
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => HouseEditScreen(refreshCallback: _fetchUserData),
              ),
            );
          },
          child: Icon(Icons.add),
        )
            : null, // Don't show the button for non-master users
      ),
    );
  }


  Widget _buildHouseMemberCard(String userId) {
    bool normal = userId.length > 5;
    return FutureBuilder(
      future: _fetchMemberProfile(userId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return CircularProgressIndicator(); // Display loading indicator while fetching data
        } else if (snapshot.hasError) {
          return Text('Error: ${snapshot.error}');
        } else {
          Map<String, dynamic>? memberData = snapshot.data;
          if (memberData == null) {
            return SizedBox(); // Return an empty widget if no data is available
          }

          String userName = memberData['UserName'] ?? 'N/A';
          String emailAddress = memberData['EmailAddress'] ?? 'N/A';
          String contactNo = memberData['ContactNo'] ?? 'N/A';
          String profileImageUrl = memberData['Remark1'] ?? ''; // Assuming Remark1 contains the image URL

          Widget trailingWidget;

          if (normal && master) {
            // Only show the delete icon when both normal and master are true
            trailingWidget = IconButton(
              icon: Icon(Icons.delete),
              onPressed: () {
                _confirmDeleteUser(userId);
              },
            );
          } else {
            trailingWidget = SizedBox.shrink();
          }

          if (Uri.tryParse(profileImageUrl)?.isAbsolute == true) {
            // If it's a valid absolute URL, load the image
            return Card(
              elevation: 3,
              margin: EdgeInsets.all(8),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundImage: NetworkImage(profileImageUrl),
                  backgroundColor: ColorConstants.themeColor,
                ),
                title: Text(userId),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Username: $userName'),
                    Text('Email Address: $emailAddress'),
                    Text('Contact: $contactNo'),
                    // Add more fields as needed
                  ],
                ),
                trailing: trailingWidget,
              ),
            );
          } else {
            return Card(
              elevation: 3,
              margin: EdgeInsets.all(8),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: ColorConstants.themeColor,
                  child: Icon(
                    Icons.error_outline,
                    color: ColorConstants.orangeColor,
                  ),
                ),
                title: Text(userId),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Username: $userName'),
                    Text('Email Address: $emailAddress'),
                    Text('Contact: $contactNo'),
                    // Add more fields as needed
                  ],
                ),
                trailing: trailingWidget,
              ),
            );
          }
        }
      },
    );
  }


  Future<Map<String, dynamic>?> _fetchMemberProfile(String userId) async {
    try {
      DataSnapshot snapshot = await _databaseReference.child('Staffs/$userId').get();
      var snapshotValue = snapshot.value;

      if (snapshotValue is Map<dynamic, dynamic>) {
        final String userName = snapshotValue['UserName'] ?? 'N/A';
        final String emailAddress = snapshotValue['Profile']['EmailAddress'] ?? 'N/A';
        final String contactNo = snapshotValue['Profile']['ContactNo'] ?? 'N/A';
        final String remark1 = snapshotValue['Profile']['Remark1'] ?? 'N/A';

        return {
          'UserName': userName,
          'EmailAddress': emailAddress,
          'ContactNo': contactNo,
          'Remark1': remark1,
        };
      }
    } catch (e) {
      print('Error fetching member profile: $e');
    }
    return null;
  }


  void _confirmDeleteUser(String userId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Confirm Delete'),
        content: Text('Are you sure you want to delete the user $userId?'),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              try {
                // Implement the logic to delete the user from the database here
                await _databaseReference.child('Staffs').child(userId).remove();
                Navigator.of(context).pop(); // Close the dialog

                // Reload the data after deleting the user
                await _fetchUserData();
              } catch (e) {
                print('Error deleting user: $e');
                // Handle any errors that occur during deletion
                // You can show an error message to the user here if needed
              }
            },
            child: Text('Delete'),
          ),
        ],
      ),
    );
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
}
