import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/material.dart';
import 'package:re_source/pages/login.dart';
import 'package:re_source/pages/success.dart';
import 'package:re_source/widgets/back_title.dart';
import 'package:re_source/widgets/custom_appbar.dart';
import 'package:re_source/widgets/custom_drawer.dart';
import 'dart:math';
import 'package:re_source/colors.dart';

class EditResource extends StatefulWidget {
  final String? link;

  const EditResource({super.key, required this.link});

  @override
  State<EditResource> createState() => _EditResourceState();
}

class _EditResourceState extends State<EditResource> {
  late TextEditingController _titleController;
  late TextEditingController _categoryController;
  late TextEditingController _descriptionController;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController();
    _categoryController = TextEditingController();
    _descriptionController = TextEditingController();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _categoryController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> addResource() async {
    final FirebaseFirestore database = FirebaseFirestore.instance;
    final FirebaseAuth auth = FirebaseAuth.instance;

    final String title = _titleController.text.trim();
    final String categoryName = _categoryController.text.trim();
    final String description = _descriptionController.text.trim();

    if (title.isEmpty || categoryName.isEmpty || description.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please fill in all fields.')),
        );
      }
      return;
    }

    final User? user = auth.currentUser;

    if (user == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('You must be logged in to add resources.'),
          ),
        );
        Navigator.of(
          context,
        ).pushReplacement(MaterialPageRoute(builder: (_) => Login()));
      }
      return;
    }

    int getRandomCategoryColor() {
      final Random random = Random();

      int randomIndex = random.nextInt(colors.length);

      return colors[randomIndex].toARGB32();
    }

    try {
      String actualCategoryId;

      final userCategoriesRef = database
          .collection('users')
          .doc(user.uid)
          .collection('categories');

      final existingCategories = await userCategoriesRef
          .where('name', isEqualTo: categoryName)
          .limit(1)
          .get();

      if (existingCategories.docs.isNotEmpty) {
        actualCategoryId = existingCategories.docs.first.id;
      } else {
        final newCategoryDocRef = await userCategoriesRef.add({
          'name': categoryName,
          'createdAt': FieldValue.serverTimestamp(),
          'color': getRandomCategoryColor(),
        });
        actualCategoryId = newCategoryDocRef.id;
      }

      final resourcesCollectionRef = userCategoriesRef
          .doc(actualCategoryId)
          .collection('resources');

      await resourcesCollectionRef.add({
        'title': title,
        'link': widget.link,
        'description': description,
        'addedAt': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Resource added successfully!')),
        );
        Navigator.pushReplacement(
          context,
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) =>
                const SuccessPage(),
            transitionDuration: Duration.zero,
            reverseTransitionDuration: Duration.zero,
          ),
        );
      }
    } catch (e, stack) {
      await FirebaseCrashlytics.instance.recordError(
        e,
        stack,
        reason: 'Error adding new resource.',
        fatal: false,
      );
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to add resource: $e')));
      }
      rethrow;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: CustomAppBar(),
      drawer: CustomDrawer(),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Container(
            padding: const EdgeInsets.all(30),
            child: Column(
              children: [
                const BackTitle(title: "Edit Resource"),
                const SizedBox(height: 15),
                Card(
                  color: const Color.fromARGB(255, 233, 233, 233),
                  child: SizedBox(
                    width: double.infinity,
                    child: Container(
                      padding: const EdgeInsets.all(35),
                      child: Column(
                        crossAxisAlignment:
                            CrossAxisAlignment.start, // Align labels to start
                        children: [
                          const Text(
                            "Title",
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 5),
                          TextField(
                            controller: _titleController, // Correctly assigned
                            decoration: InputDecoration(
                              filled: true,
                              fillColor: Colors.white,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: BorderSide.none,
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: BorderSide.none,
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: BorderSide.none,
                              ),
                              hintText: 'Title',
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 12,
                              ),
                            ),
                            keyboardType: TextInputType.text,
                          ),
                          const SizedBox(height: 15), // Spacing between fields

                          const Text(
                            "Category",
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 5),
                          TextField(
                            controller: _categoryController,
                            decoration: InputDecoration(
                              filled: true,
                              fillColor: Colors.white,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: BorderSide.none,
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: BorderSide.none,
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: BorderSide.none,
                              ),
                              hintText: 'E.g. Technology',
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 12,
                              ),
                            ),
                            keyboardType: TextInputType.text,
                          ),
                          const SizedBox(height: 15),

                          const Text(
                            "Description",
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 5),
                          TextField(
                            controller: _descriptionController,
                            maxLines: null,
                            minLines: 3,
                            keyboardType: TextInputType.multiline,
                            decoration: InputDecoration(
                              filled: true,
                              fillColor: Colors.white,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: BorderSide.none,
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: BorderSide.none,
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: BorderSide.none,
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 12,
                              ),
                            ),
                          ),
                          const SizedBox(height: 15),

                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                "Image",
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              TextButton(
                                onPressed: () => {},
                                child: const Text("Change Image"),
                              ),
                            ],
                          ),
                          Container(
                            width: double.infinity,
                            height: 150,
                            clipBehavior: Clip.hardEdge,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Image.asset(
                              'assets/images/success.png',
                              fit: BoxFit.cover,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                FilledButton(
                  onPressed: () => {addResource()},
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
                  child: const Text("Next", style: TextStyle(fontSize: 18)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
