import 'package:flutter/material.dart';
import 'package:re_source/pages/home.dart';
import 'package:re_source/pages/library.dart';
import 'package:re_source/pages/login.dart';

class CustomDrawer extends StatelessWidget {
  const CustomDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          const DrawerHeader(
            child: Image(
              image: AssetImage("assets/images/logo-horizontal.png"),
            ),
          ),
          ListTile(
            title: const Text('Home'),
            onTap: () => {
              Navigator.push(
                context,
                PageRouteBuilder(
                  pageBuilder: (context, animation, secondaryAnimation) =>
                      const Home(),
                  transitionDuration: Duration.zero, // 👈 No animation
                  reverseTransitionDuration: Duration.zero,
                ),
              ),
            },
          ),
          ListTile(
            title: const Text('Library'),
            onTap: () => {
              Navigator.push(
                context,
                PageRouteBuilder(
                  pageBuilder: (context, animation, secondaryAnimation) =>
                      const Library(),
                  transitionDuration: Duration.zero, // 👈 No animation
                  reverseTransitionDuration: Duration.zero,
                ),
              ),
            },
          ),
          ListTile(
            title: const Text('Login'),
            onTap: () => {
              Navigator.push(
                context,
                PageRouteBuilder(
                  pageBuilder: (context, animation, secondaryAnimation) =>
                      const Login(),
                  transitionDuration: Duration.zero, // 👈 No animation
                  reverseTransitionDuration: Duration.zero,
                ),
              ),
            },
          ),
        ],
      ),
    );
  }
}
