import 'package:flutter/material.dart';

class Library extends StatelessWidget {
  const Library({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Image(
          image: AssetImage("assets/images/logo-horizontal.png"),
          width: 60,
        ),
        backgroundColor: Colors.white,
        automaticallyImplyLeading: false,
        actions: [
          Builder(
            builder: (context) => IconButton(
              onPressed: Scaffold.of(context).openDrawer,
              icon: const Icon(Icons.menu),
            ),
          ),
        ],
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            const DrawerHeader(
              child: Image(
                image: AssetImage("assets/images/logo-horizontal.png"),
              ),
            ),
            ListTile(title: const Text('Home'), onTap: () {}),
            ListTile(title: const Text('Library'), onTap: () {}),
          ],
        ),
      ),
      body: Container(),
    );
  }
}
