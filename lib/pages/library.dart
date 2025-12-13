import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:re_source/pages/category_management.dart';
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
  final TextEditingController _searchController = TextEditingController();
  bool _isSearching = false;
  bool _isLoading = false;
  List<Map<String, dynamic>> _allCategories = [];
  List<Map<String, dynamic>> _filteredCategories = [];

  @override
  void initState() {
    super.initState();
    _loadCategories();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadCategories() async {
    setState(() {
      _isLoading = true;
    });
    try {
      final categories = await fetchCategories();
      setState(() {
        _allCategories = categories;
        _filteredCategories = categories;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _allCategories = [];
        _filteredCategories = [];
        _isLoading = false;
      });
    }
  }

  void _onSearchChanged() async {
    final query = _searchController.text.trim().toLowerCase();
    setState(() {
      _isSearching = query.isNotEmpty;
      _isLoading = true;
    });

    await Future.delayed(const Duration(milliseconds: 180));

    if (query.isEmpty) {
      setState(() {
        _filteredCategories = _allCategories;
        _isLoading = false;
      });
      return;
    }

    final filtered = _allCategories.where((cat) {
      final name = (cat['name'] as String? ?? '').toLowerCase();
      return name.contains(query);
    }).toList();

    setState(() {
      _filteredCategories = filtered;
      _isLoading = false;
    });
  }

  Future<List<Map<String, dynamic>>> fetchCategories() async {
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
        final categoryColor = colorValue != null
            ? Color(colorValue)
            : Colors.grey;

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

  void _clearSearch() {
    _searchController.clear();
    setState(() {
      _filteredCategories = _allCategories;
      _isSearching = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: CustomAppBar(),
      drawer: CustomDrawer(),
      body: SafeArea(
        child: Column(
        children: [
          Container(
            color: theme.scaffoldBackgroundColor,
            padding: const EdgeInsets.fromLTRB(30, 20, 30, 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "Library",
                      style: Theme.of(
                        context,
                      ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w500),
                    ),
                    IconButton(
                      icon: const Icon(Icons.settings),
                      onPressed: () {
                        Navigator.push(
                          context,
                          PageRouteBuilder(
                            pageBuilder: (context, animation, secondaryAnimation) =>
                                const CategoryManagement(),
                            transitionDuration: Duration.zero,
                            reverseTransitionDuration: Duration.zero,
                          ),
                        ).then((_) => _loadCategories());
                      },
                      tooltip: 'Manage Categories',
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                SearchBar(
                  controller: _searchController,
                  onChanged: (value) {},
                  hintText: "Looking for something?",
                  leading: const Icon(Icons.search),
                  trailing: [
                    _searchController.text.isNotEmpty
                        ? InkWell(
                            onTap: _clearSearch,
                            borderRadius: BorderRadius.circular(50),
                            child: Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Icon(
                                Icons.close,
                                size: 18,
                                color: Colors.grey[600],
                              ),
                            ),
                          )
                        : const SizedBox(width: 34, height: 34),
                  ],
                  shape: WidgetStateProperty.all(
                    RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(50.0),
                      side: BorderSide(
                        color: Theme.of(context).colorScheme.outlineVariant,
                      ),
                    ),
                  ),
                  backgroundColor: WidgetStateProperty.all(
                    Theme.of(context).colorScheme.surface,
                  ),
                  padding: WidgetStateProperty.all(
                    const EdgeInsets.symmetric(horizontal: 15.0, vertical: 8.0),
                  ),
                  elevation: WidgetStateProperty.all(0),
                ),
              ],
            ),
          ),

          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 20),
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _filteredCategories.isEmpty
                  ? Center(
                      child: Text(
                        _isSearching
                            ? 'No matching categories found.'
                            : 'No categories found. Start by adding one!',
                      ),
                    )
                  : GridView.count(
                      crossAxisSpacing: 10,
                      mainAxisSpacing: 10,
                      childAspectRatio: 5,
                      crossAxisCount: 1,
                      children: _filteredCategories
                          .map(
                            (category) => CategoryCard(
                              category: category,
                              onReturn: (modified) {
                                if (modified) {
                                  _loadCategories();
                                }
                              },
                            ),
                          )
                          .toList(),
                    ),
            ),
          ),
        ],
        ),
      ),
      bottomNavigationBar: Container(
        color: theme.scaffoldBackgroundColor,
        padding: const EdgeInsets.fromLTRB(30.0, 40.0, 30.0, 50.0),
        child: SafeArea(
          top: false,
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
              minimumSize: WidgetStateProperty.all(
                const Size(double.infinity, 45),
              ),
              shape: WidgetStateProperty.all(
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              backgroundColor: WidgetStateProperty.all(
                Theme.of(context).colorScheme.primary,
              ),
            ),
            child: const Text("Add Resource", style: TextStyle(fontSize: 16)),
          ),
        ),
      ),
    );
  }
}
