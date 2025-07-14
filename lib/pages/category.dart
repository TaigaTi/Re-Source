import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:re_source/pages/login.dart';
import 'package:re_source/pages/new_resource.dart';
import 'package:re_source/pages/resource_details.dart';
import 'package:re_source/widgets/back_title.dart';
import 'package:re_source/widgets/custom_appbar.dart';
import 'package:re_source/widgets/custom_drawer.dart';
import 'package:re_source/widgets/resource_card.dart';

class Category extends StatefulWidget {
  final String? name;
  final Color? color;
  final String? id;

  const Category({super.key, this.name, this.color, this.id});

  @override
  CategoryState createState() => CategoryState();
}

class CategoryState extends State<Category> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  final GlobalKey _searchBarKey = GlobalKey();
  OverlayEntry? _overlayEntry;
  bool _isSearching = false;

  List<Map<String, dynamic>> _allResources = [];
  List<Map<String, dynamic>> _filteredResources = [];

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
    _searchFocusNode.addListener(_onFocusChanged);
    _loadResources();
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    _searchFocusNode.removeListener(_onFocusChanged);
    _searchFocusNode.dispose();
    _removeOverlay();
    super.dispose();
  }

  void _onSearchChanged() {
    final query = _searchController.text.toLowerCase().trim();
    if (query.isEmpty) {
      setState(() {
        _filteredResources = [];
        _isSearching = false;
      });
      _removeOverlay();
    } else {
      setState(() {
        _isSearching = true;
        _filteredResources = _allResources.where((resource) {
          final title = (resource['title'] as String? ?? '').toLowerCase();
          final description = (resource['description'] as String? ?? '').toLowerCase();
          return title.contains(query) || description.contains(query);
        }).toList();
      });
      _showOverlay();
    }
  }

  void _onFocusChanged() {
    if (!_searchFocusNode.hasFocus) {
      // Delay removal to allow tap on search results
      Future.delayed(const Duration(milliseconds: 150), () {
        _removeOverlay();
        setState(() {
          _isSearching = false;
        });
      });
    }
  }

  void _showOverlay() {
    _removeOverlay();

    if (_filteredResources.isEmpty) return;

    _overlayEntry = OverlayEntry(builder: (context) => _buildSearchOverlay());

    Overlay.of(context).insert(_overlayEntry!);
  }

  void _removeOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  Widget _buildSearchOverlay() {
    return Positioned(
      top: _getSearchBarPosition() + 70, // Position below search bar
      left: 30,
      right: 30,
      child: Material(
        elevation: 3,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          constraints: const BoxConstraints(maxHeight: 800),
          decoration: BoxDecoration(
            color: const Color.fromARGB(255, 244, 244, 244),
            borderRadius: BorderRadius.circular(12),
          ),
          child: ListView.separated(
            shrinkWrap: true,
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: _filteredResources.length,
            separatorBuilder: (context, index) => const Divider(
              height: 1,
              color: Color.fromRGBO(207, 207, 207, 1),
            ),
            itemBuilder: (context, index) {
              final resource = _filteredResources[index];
              return _buildSearchResultItem(resource);
            },
          ),
        ),
      ),
    );
  }

  Widget _buildSearchResultItem(Map<String, dynamic> resource) {
    final title = resource['title'] as String? ?? 'Untitled Resource';
    final description = resource['description'] as String? ?? 'No description';
    final categoryName = widget.name ?? 'Uncategorized';
    final categoryColor = widget.color ?? Colors.grey;

    return InkWell(
      onTap: () {
        _removeOverlay();
        _searchController.clear();
        _searchFocusNode.unfocus();

        Navigator.push(
          context,
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) =>
                ResourceDetails(
                  // resourceId: resource['id'] as String,
                  // title: title,
                  // description: description,
                  // link: resource['link'] as String? ?? '',
                  // categoryId: widget.id ?? '',
                  // categoryName: categoryName,
                  // categoryColor: categoryColor,
                ),
            transitionDuration: Duration.zero,
            reverseTransitionDuration: Duration.zero,
          ),
        );
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Category indicator
            Padding(
              padding: const EdgeInsets.only(right: 12, top: 4),
              child: Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: categoryColor,
                  shape: BoxShape.circle,
                ),
              ),
            ),
            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: Colors.black,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  const SizedBox(height: 2),
                  // Category
                  Text(
                    'in $categoryName',
                    style: TextStyle(
                      fontSize: 13,
                      color: categoryColor,
                      fontWeight: FontWeight.w400,
                      fontStyle: FontStyle.italic,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  // Description
                  Text(
                    description,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Color.fromARGB(255, 110, 110, 110),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  double _getSearchBarPosition() {
    final RenderBox? renderBox =
        _searchBarKey.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox != null) {
      final position = renderBox.localToGlobal(Offset.zero);
      return position.dy;
    }
    return 100; // Fallback position
  }

  Future<void> _loadResources() async {
    final resources = await fetchResources();
    setState(() {
      _allResources = resources;
    });
  }

  Future<List<Map<String, dynamic>>> fetchResources() async {
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
        Exception('Attempt to access resources while not logged in.'),
        StackTrace.current,
        reason: 'User session missing for resource fetch',
        fatal: false,
      );
      return [];
    }

    if (widget.id == null) {
      FirebaseCrashlytics.instance.recordError(
        Exception('Category ID is null when fetching resources.'),
        StackTrace.current,
        reason: 'Missing category ID for resource fetch',
        fatal: false,
      );
      return [];
    }

    try {
      final QuerySnapshot<Map<String, dynamic>> snapshot = await database
          .collection('users')
          .doc(user.uid)
          .collection('categories')
          .doc(widget.id)
          .collection('resources')
          .get();

      return snapshot.docs.map((doc) => {'id': doc.id, ...doc.data()}).toList();
    } catch (e, s) {
      FirebaseCrashlytics.instance.recordError(
        e,
        s,
        reason: 'Failed to fetch resources for category ${widget.id}.',
        fatal: false,
      );
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to load resources: $e')));
      }
      return [];
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: const CustomAppBar(),
      drawer: const CustomDrawer(),
      body: SafeArea(
        child: Stack(
          children: [
            SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(30, 20, 30, 50),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    BackTitle(title: widget.name ?? "Untitled"),
                    const SizedBox(height: 20),
                    SearchBar(
                      key: _searchBarKey,
                      controller: _searchController,
                      focusNode: _searchFocusNode,
                      onChanged: (value) {}, // Handler moved to listener
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
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      height: 490,
                      child: FutureBuilder<List<Map<String, dynamic>>>(
                        future: fetchResources(),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState == ConnectionState.waiting) {
                            return const Center(child: CircularProgressIndicator());
                          } else if (snapshot.hasError) {
                            return Center(child: Text('Error: ${snapshot.error}'));
                          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                            return const Center(
                              child: Text('No resources found in this category.'),
                            );
                          } else {
                            List<Map<String, dynamic>> resources = snapshot.data!;
                            return MasonryGridView.count(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              crossAxisCount: 2,
                              crossAxisSpacing: 10,
                              mainAxisSpacing: 10,
                              itemCount: resources.length,
                              itemBuilder: (context, index) {
                                final resourceData = resources[index];
                                return ResourceCard(
                                  id: resourceData['id'],
                                  title: resourceData['title'] ?? 'No Title',
                                  link: resourceData['link'] ?? '',
                                  description: resourceData['description'] ?? '',
                                  categoryId: widget.id,
                                  categoryName: widget.name,
                                  categoryColor: widget.color,
                                  indicator: false,
                                );
                              },
                            );
                          }
                        },
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(top: 20),
                      child: FilledButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            PageRouteBuilder(
                              pageBuilder:
                                  (context, animation, secondaryAnimation) =>
                                      NewResource(),
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
          ],
        ),
      ),
    );
  }
}