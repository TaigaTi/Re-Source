import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:re_source/pages/login.dart';
import 'package:re_source/widgets/custom_appbar.dart';
import 'package:re_source/widgets/custom_drawer.dart';

class ProfilePage extends StatelessWidget {
  final String userEmail; // To display the user's email

  const ProfilePage({super.key, this.userEmail = 'example@email.com'});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(),
      drawer: CustomDrawer(),
      backgroundColor: Colors.white,
      body: Padding(
        padding: const EdgeInsets.symmetric(vertical: 70.0, horizontal: 30.0),
        child: Column(
          children: [
            Center(
              child: Text(
                "Profile",
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: const Color.fromARGB(255, 78, 173, 162),
                ),
              ),
            ),
            SizedBox(height: 5),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(30.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircleAvatar(
                      radius: 75,
                      backgroundColor: Colors.transparent, // No border
                      backgroundImage: AssetImage("assets/images/success.png"),
                    ),
                    SizedBox(height: 20),
                    Text(
                      userEmail,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w500,
                        color: Colors.black87,
                      ),
                    ),
                    SizedBox(height: 80),
                    // Logout Button
                    ElevatedButton(
                      onPressed: () async {
                        await FirebaseAuth.instance.signOut();
                        if (context.mounted) {
                          Navigator.pushAndRemoveUntil(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const Login(),
                            ),
                            (route) => false,
                          );
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.teal.shade400,
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(
                          horizontal: 35,
                          vertical: 12,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        minimumSize: Size(double.infinity, 36),
                      ),
                      child: Text('Logout', style: TextStyle(fontSize: 16)),
                    ),
                    SizedBox(height: 25),
                    // Delete Account Button
                    ElevatedButton(
                      onPressed: () {},
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red.shade600,
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(
                          horizontal: 35,
                          vertical: 12,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        minimumSize: Size(double.infinity, 36),
                      ),
                      child: Text(
                        'Delete Account',
                        style: TextStyle(fontSize: 16),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
