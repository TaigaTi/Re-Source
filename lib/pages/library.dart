import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:re_source/pages/login.dart';
import 'package:re_source/pages/new_resource.dart';
import 'package:re_source/widgets/category_card.dart';
import 'package:re_source/widgets/custom_appbar.dart';
import 'package:re_source/widgets/custom_drawer.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';

class Library extends StatefulWidget {
  const Library({super.key});

  @override
  LibraryState createState() => LibraryState();
}

class LibraryState extends State<Library> {
  Future<List<Map<String, dynamic>>> fetchCategories() async {
    final FirebaseFirestore database = FirebaseFirestore.instance;
    final FirebaseAuth auth = FirebaseAuth.instance;

    final User? user = auth.currentUser;

    if (user == null) {
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const Login()),
        );
      }
      FirebaseCrashlytics.instance.recordError(
        Exception('Attempt to access Library while not logged in.'),
        StackTrace.current,
        reason: 'User session missing',
        fatal: false,
      );
      throw Exception('User not logged in.');
    }

    try {
      final snapshot = await database
          .collection('users')
          .doc(user.uid)
          .collection('categories')
          .get();

      return snapshot.docs.map((doc) {
        final data = doc.data();
        final categoryName = (data['name'] as String?) ?? 'Untitled Category';
        final int? colorValue = data['color'];
        final categoryColor =
            colorValue != null ? Color(colorValue) : Colors.grey;

        return {"id": doc.id, "name": categoryName, "color": categoryColor};
      }).toList();
    } catch (e, s) {
      FirebaseCrashlytics.instance.recordError(
        e,
        s,
        reason: 'Failed to fetch categories.',
        fatal: false,
      );
      return [];
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: CustomAppBar(),
      drawer: CustomDrawer(),
      body: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 130.0, bottom: 80.0),
            child: FutureBuilder<List<Map<String, dynamic>>>(
              future: fetchCategories(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                } else if (snapshot.hasError) {
                  return Center(
                    child: Text(
                      'Failed to load categories. Please try again.\nError: ${snapshot.error}',
                    ),
                  );
                } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Center(
                    child: Text('No categories found. Start by adding one!'),
                  );
                } else {
                  final categories = snapshot.data!;
                  return ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 30),
                    itemCount: categories.length,
                    itemBuilder: (context, index) {
                      final category = categories[index];
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8.0),
                        child: CategoryCard(category: category),
                      );
                    },
                  );
                }
              },
            ),
          ),

          // Fixed top section
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Container(
              color: Colors.white,
              padding: const EdgeInsets.fromLTRB(30, 20, 30, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Library",
                    style: TextStyle(
                      fontSize: 20.0,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 10),
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
                      const EdgeInsets.symmetric(
                        horizontal: 15.0,
                        vertical: 8.0,
                      ),
                    ),
                    elevation: WidgetStateProperty.all(0),
                  ),
                ],
              ),
            ),
          ),

          // Fixed bottom button
          Positioned(
            bottom: 0,
            left: 30,
            right: 30,
            child: Container(
              decoration: BoxDecoration(color: Colors.white),
              padding: EdgeInsets.fromLTRB(0.0, 30.0, 0.0, 70.0),
              child: FilledButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    PageRouteBuilder(
                      pageBuilder: (context, animation, secondaryAnimation) =>
                          const NewResource(),
                      transitionDuration: Duration.zero,
                      reverseTransitionDuration: Duration.zero,
                    ),
                  );
                },
                style: ButtonStyle(
                  minimumSize:
                      WidgetStateProperty.all(const Size(double.infinity, 45)),
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
          ),
        ],
      ),
    );
  }
}
