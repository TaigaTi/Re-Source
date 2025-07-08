import 'package:flutter/material.dart';

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
              const CircleAvatar(
                radius: 12,
                backgroundColor: Colors.transparent,
                backgroundImage: AssetImage("assets/images/profile.png"),
              ),
              IconButton(
                onPressed: Scaffold.of(context).openDrawer,
                icon: const Icon(Icons.menu),
                color: Colors.black87, // optional: color tweak
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
