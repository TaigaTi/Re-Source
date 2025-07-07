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
import 'package:re_source/widgets/searchable_dropdown.dart';

class EditResource extends StatefulWidget {
  final String? link;

  const EditResource({super.key, required this.link});

  @override
  State<EditResource> createState() => _EditResourceState();
}

class _EditResourceState extends State<EditResource> {
  late TextEditingController _titleController;
  late TextEditingController _descriptionController;
  String? _selectedCategory;
  List<Map<String, Object>> _categories = [];

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController();
    _descriptionController = TextEditingController();
    _fetchCategories();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _fetchCategories() async {
    final FirebaseFirestore database = FirebaseFirestore.instance;
    final FirebaseAuth auth = FirebaseAuth.instance;
    final User? user = auth.currentUser;

    if (user == null) {
      if (mounted) {
        Navigator.of(
          context,
        ).pushReplacement(MaterialPageRoute(builder: (_) => const Login()));
      }
      FirebaseCrashlytics.instance.recordError(
        Exception('Attempt to fetch categories while not logged in.'),
        StackTrace.current,
        reason: 'User session missing',
        fatal: false,
      );
      return;
    }

    try {
      final QuerySnapshot<Map<String, dynamic>> snapshot = await database
          .collection('users')
          .doc(user.uid)
          .collection('categories')
          .get();

      setState(() {
        _categories = snapshot.docs.map((doc) {
          final data = doc.data();
          return {
            "id": doc.id,
            "name": (data['name'] as String?) ?? 'Untitled Category',
            "color": (data['color'] as int?) ?? Colors.grey,
          };
        }).toList();

        if (_categories.isNotEmpty && _selectedCategory == null) {
          _selectedCategory = _categories.first['name'] as String?;
        }
      });
    } catch (e, s) {
      FirebaseCrashlytics.instance.recordError(
        e,
        s,
        reason: 'Failed to fetch categories for dropdown.',
        fatal: false,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load categories: $e')),
        );
      }
    }
  }

  Future<void> _createNewCategory(String categoryName) async {
    final FirebaseFirestore database = FirebaseFirestore.instance;
    final FirebaseAuth auth = FirebaseAuth.instance;
    final User? user = auth.currentUser;

    if (user == null) return;

    int getRandomCategoryColor() {
      final Random random = Random();
      int randomIndex = random.nextInt(colors.length);
      return colors[randomIndex].toARGB32();
    }

    try {
      final userCategoriesRef = database
          .collection('users')
          .doc(user.uid)
          .collection('categories');

      final newCategoryDocRef = await userCategoriesRef.add({
        'name': categoryName,
        'createdAt': FieldValue.serverTimestamp(),
        'color': getRandomCategoryColor(),
      });

      // Add the new category to the local list
      setState(() {
        _categories.add({
          "id": newCategoryDocRef.id,
          "name": categoryName,
          "color": getRandomCategoryColor(),
        });
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Category "$categoryName" created successfully!'),
          ),
        );
      }
    } catch (e, s) {
      FirebaseCrashlytics.instance.recordError(
        e,
        s,
        reason: 'Failed to create new category.',
        fatal: false,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to create category: $e')),
        );
      }
    }
  }

  Future<void> addResource() async {
    final FirebaseFirestore database = FirebaseFirestore.instance;
    final FirebaseAuth auth = FirebaseAuth.instance;

    final String title = _titleController.text.trim();
    final String? categoryName = _selectedCategory;
    final String description = _descriptionController.text.trim();

    if (title.isEmpty ||
        categoryName == null ||
        categoryName.isEmpty ||
        description.isEmpty) {
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
        ).pushReplacement(MaterialPageRoute(builder: (_) => const Login()));
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
                        crossAxisAlignment: CrossAxisAlignment.start,
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
                            controller: _titleController,
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
                          const SizedBox(height: 15),

                          const Text(
                            "Category",
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 5),
                          SearchableCategoryDropdown(
                            categories: _categories,
                            selectedCategory: _selectedCategory,
                            onCategorySelected: (categoryName) {
                              setState(() {
                                _selectedCategory = categoryName;
                              });
                            },
                            onCreateCategory: (categoryName) async {
                              await _createNewCategory(categoryName);
                              setState(() {
                                _selectedCategory = categoryName;
                              });
                            },
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
