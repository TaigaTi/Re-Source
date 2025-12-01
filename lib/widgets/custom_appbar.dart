import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:re_source/pages/profile.dart';

class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  const CustomAppBar({super.key});

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: const Image(
        image: AssetImage("assets/images/logo-horizontal.png"),
        width: 60,
      ),
      backgroundColor: Colors.white,
      automaticallyImplyLeading: false,
      actions: [
        Builder(
          builder: (context) => Row(
            children: [
              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    PageRouteBuilder(
                      pageBuilder: (context, animation, secondaryAnimation) =>
                          const ProfilePage(),
                      transitionDuration: Duration.zero,
                      reverseTransitionDuration: Duration.zero,
                    ),
                  );
                },
                child: _ProfileAvatar(),
              ),
              IconButton(
                onPressed: Scaffold.of(context).openDrawer,
                icon: const Icon(Icons.menu),
                color: Colors.black87,
              ),
            ],
          ),
        ),
      ],
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}

class _ProfileAvatar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final User? user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return const CircleAvatar(
        radius: 12,
        backgroundColor: Colors.transparent,
        backgroundImage: AssetImage('assets/images/profile.png'),
      );
    }

    final docStream = FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .snapshots();

    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: docStream,
      builder: (context, snapshot) {
        final String? url = snapshot.hasData
            ? (snapshot.data!.data()?['profileImageUrl'] as String?)
            : null;
        if (url == null || url.isEmpty) {
          return const CircleAvatar(
            radius: 12,
            backgroundColor: Colors.transparent,
            backgroundImage: AssetImage('assets/images/profile.png'),
          );
        }
        // Use CachedNetworkImage widget with error handling, clipped to a circle
        return SizedBox(
          width: 24,
          height: 24,
          child: ClipOval(
            child: CachedNetworkImage(
              imageUrl: url,
              fit: BoxFit.cover,
              errorWidget: (context, error, stackTrace) => const Image(
                image: AssetImage('assets/images/profile.png'),
                fit: BoxFit.cover,
              ),
            ),
          ),
        );
      },
    );
  }
}
