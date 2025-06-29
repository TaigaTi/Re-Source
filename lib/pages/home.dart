import 'package:flutter/material.dart';

class Home extends StatelessWidget {
  const Home({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Re-Source'),
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
      body: SingleChildScrollView(
        child: Container(
          padding: EdgeInsets.all(20),
          child: Center(
            child: Column(
              spacing: 20,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: 10.0,
                    vertical: 8.0,
                  ),
                  child: TextField(
                    decoration: InputDecoration(
                      hintText: 'Looking for something?',
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 15.0,
                        vertical: 8.0,
                      ),
                      prefixIcon: Icon(Icons.search),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.all(Radius.circular(50.0)),
                      ),
                    ),
                  ),
                ),
                Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          "Recent Categories",
                          style: TextStyle(
                            fontSize: 20.0,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        TextButton(
                          child: const Text("View All"),
                          onPressed: () => const {},
                        ),
                      ],
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      spacing: 10,
                      children: [
                        Expanded(
                          child: Container(
                            padding: EdgeInsets.symmetric(
                              vertical: 10.0,
                              horizontal: 15.0,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.black,
                              borderRadius: BorderRadius.all(
                                Radius.circular(10),
                              ),
                            ),
                            child: Text(
                              "Category 1",
                              style: TextStyle(color: Colors.white),
                            ),
                          ),
                        ),
                        Expanded(
                          child: Container(
                            padding: EdgeInsets.symmetric(
                              vertical: 10.0,
                              horizontal: 15.0,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.black,
                              borderRadius: BorderRadius.all(
                                Radius.circular(10),
                              ),
                            ),
                            child: Text(
                              "Category 1",
                              style: TextStyle(color: Colors.white),
                            ),
                          ),
                        ),
                        Expanded(
                          child: Container(
                            padding: EdgeInsets.symmetric(
                              vertical: 10.0,
                              horizontal: 15.0,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.black,
                              borderRadius: BorderRadius.all(
                                Radius.circular(10),
                              ),
                            ),
                            child: Text(
                              "Category 1",
                              style: TextStyle(color: Colors.white),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          "Recent Links",
                          style: TextStyle(
                            fontSize: 20.0,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        TextButton(
                          child: const Text("View All"),
                          onPressed: () => const {},
                        ),
                      ],
                    ),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            spacing: 10,
                            children: [
                              Card(
                                color: Colors.blue.shade100,
                                child: SizedBox(
                                  height: 200, // fixed height
                                  width: double
                                      .infinity, // take full width of column
                                  child: Center(child: Text("Card 1")),
                                ),
                              ),
                              Card(
                                color: Colors.green.shade100,
                                child: SizedBox(
                                  height: 150,
                                  width: double.infinity,
                                  child: Center(child: Text("Card 2")),
                                ),
                              ),
                              Card(
                                color: Colors.blue.shade100,
                                child: SizedBox(
                                  height: 200, // fixed height
                                  width: double
                                      .infinity, // take full width of column
                                  child: Center(child: Text("Card 1")),
                                ),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(width: 10), // spacing between the columns
                        Expanded(
                          child: Column(
                            spacing: 10,
                            children: [
                              Card(
                                color: const Color.fromARGB(255, 208, 200, 230),
                                child: SizedBox(
                                  height: 150,
                                  width: double.infinity,
                                  child: Center(child: Text("Card 2")),
                                ),
                              ),
                              Card(
                                color: Colors.green.shade100,
                                child: SizedBox(
                                  height: 150,
                                  width: double.infinity,
                                  child: Center(child: Text("Card 2")),
                                ),
                              ),
                              Card(
                                color: const Color.fromARGB(255, 230, 204, 200),
                                child: SizedBox(
                                  height: 150,
                                  width: double.infinity,
                                  child: Center(child: Text("Card 2")),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
