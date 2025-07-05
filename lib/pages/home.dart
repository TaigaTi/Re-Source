import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:re_source/pages/category.dart';
import 'package:re_source/pages/library.dart';
import 'package:re_source/pages/login.dart';
import 'package:re_source/pages/new_resource.dart';
import 'package:re_source/widgets/custom_appbar.dart';
import 'package:re_source/widgets/custom_drawer.dart';
// import 'package:re_source/widgets/resource_card.dart';

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  HomeState createState() => HomeState();
}

class HomeState extends State<Home> {
  final List<Widget> resourceCards = const [];

  Future<List<Map<String, dynamic>>> fetchCategories() async {
    final FirebaseFirestore database = FirebaseFirestore.instance;
    final FirebaseAuth auth = FirebaseAuth.instance;

    final User? user = auth.currentUser;

    if (user == null) {
      if (mounted) {
        Navigator.of(
          context,
        ).pushReplacement(MaterialPageRoute(builder: (_) => Login()));
      }
      throw Exception('User not logged in.');
    }

    final QuerySnapshot<Map<String, dynamic>> snapshot = await database
        .collection('users')
        .doc(user.uid)
        .collection('categories')
        .get();

    return snapshot.docs.map((doc) {
      final data = doc.data();
      final String categoryName =
          (data['name'] as String?) ?? 'Untitled Category';
      final int? colorValue = data['color'];
      final Color categoryColor = colorValue != null
          ? Color(colorValue)
          : Colors.grey; // Default color if not found

      return {"name": categoryName, "color": categoryColor};
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: CustomAppBar(),
      drawer: CustomDrawer(),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(30, 20, 30, 50),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                SearchBar(
                  onChanged: (value) {},
                  hintText: "Looking for something?",
                  leading: const Icon(Icons.search),
                  shape: WidgetStateProperty.all(
                    RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(50.0),
                      side: const BorderSide(
                        color: Color.fromRGBO(233, 233, 233, 1.0),
                      ),
                    ),
                  ),
                  backgroundColor: WidgetStateProperty.all(
                    const Color.fromRGBO(233, 233, 233, 1.0),
                  ),
                  padding: WidgetStateProperty.all(
                    const EdgeInsets.symmetric(horizontal: 15.0, vertical: 8.0),
                  ),
                  elevation: WidgetStateProperty.all(0),
                ),
                const SizedBox(height: 15),
                // Recent Categories
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
                          style: ButtonStyle(
                            overlayColor: WidgetStateProperty.all(
                              Colors.transparent,
                            ),
                          ),
                          child: const Text("View All"),
                          onPressed: () => {
                            Navigator.push(
                              context,
                              PageRouteBuilder(
                                pageBuilder:
                                    (context, animation, secondaryAnimation) =>
                                        const Library(),
                                transitionDuration: Duration.zero,
                                reverseTransitionDuration: Duration.zero,
                              ),
                            ),
                          },
                        ),
                      ],
                    ),
                    SizedBox(
                      width: double.infinity,
                      height: 40,
                      child: FutureBuilder<List<Map<String, dynamic>>>(
                        future:
                            fetchCategories(), // Call the async function here
                        builder: (context, snapshot) {
                          if (snapshot.connectionState ==
                              ConnectionState.waiting) {
                            return const Center(
                              child: CircularProgressIndicator(),
                            );
                          } else if (snapshot.hasError) {
                            return Center(
                              child: Text('Error: ${snapshot.error}'),
                            );
                          } else if (!snapshot.hasData ||
                              snapshot.data!.isEmpty) {
                            return const Center(
                              child: Text('No categories found.'),
                            );
                          } else {
                            final categories = snapshot.data!;
                            // Display only the first 3 categories or fewer if not available
                            final int displayCount = categories.length > 3
                                ? 3
                                : categories.length;
                            return Row(
                              children: List.generate(displayCount, (index) {
                                return Expanded(
                                  child: Padding(
                                    padding: EdgeInsets.only(
                                      right: index < displayCount - 1
                                          ? 10.0
                                          : 0,
                                    ),
                                    child: TextButton(
                                      onPressed: () {
                                        Navigator.push(
                                          context,
                                          PageRouteBuilder(
                                            pageBuilder:
                                                (
                                                  context,
                                                  animation,
                                                  secondaryAnimation,
                                                ) =>
                                                    const Category(), // You might want to pass category data here
                                            transitionDuration: Duration.zero,
                                            reverseTransitionDuration:
                                                Duration.zero,
                                          ),
                                        );
                                      },
                                      style: TextButton.styleFrom(
                                        padding: const EdgeInsets.symmetric(
                                          vertical: 10.0,
                                          horizontal: 8.0,
                                        ),
                                        backgroundColor:
                                            categories[index]['color'],
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            10,
                                          ),
                                        ),
                                      ),
                                      child: Text(
                                        categories[index]['name'],
                                        style: const TextStyle(
                                          color: Colors.white,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ),
                                );
                              }),
                            );
                          }
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 475,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Recent Links",
                        style: TextStyle(
                          fontSize: 20.0,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Expanded(
                        child: MasonryGridView.count(
                          crossAxisCount: 2,
                          crossAxisSpacing: 10,
                          mainAxisSpacing: 10,
                          itemCount: resourceCards
                              .length, // Ensure resourceCards is populated
                          itemBuilder: (context, index) => resourceCards[index],
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 20),
                  child: FilledButton(
                    onPressed: () => {
                      Navigator.push(
                        context,
                        PageRouteBuilder(
                          pageBuilder:
                              (context, animation, secondaryAnimation) =>
                                  const NewResource(),
                          transitionDuration: Duration.zero,
                          reverseTransitionDuration: Duration.zero,
                        ),
                      ),
                    },
                    style: ButtonStyle(
                      minimumSize: WidgetStateProperty.all(
                        const Size(double.infinity, 45),
                      ),
                      shape: WidgetStateProperty.all(
                        RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      backgroundColor: WidgetStateProperty.all(
                        const Color.fromARGB(255, 87, 175, 161),
                      ),
                    ),
                    child: const Text(
                      "Add Resource",
                      style: TextStyle(fontSize: 16),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
