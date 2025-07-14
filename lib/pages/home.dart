import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:re_source/pages/category.dart';
import 'package:re_source/pages/library.dart';
import 'package:re_source/pages/login.dart';
import 'package:re_source/pages/new_resource.dart';
import 'package:re_source/pages/resource_details.dart';
import 'package:re_source/widgets/custom_appbar.dart';
import 'package:re_source/widgets/custom_drawer.dart';
import 'package:re_source/widgets/resource_card.dart';

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  HomeState createState() => HomeState();
}

class HomeState extends State<Home> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  List<Map<String, dynamic>> _allResources = [];
  List<Map<String, dynamic>> _filteredResources = [];
  bool _isSearching = false;
  OverlayEntry? _overlayEntry;
  final GlobalKey _searchBarKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
    _searchFocusNode.addListener(_onFocusChanged);
    _loadAllResources();
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
          final description = (resource['description'] as String? ?? '')
              .toLowerCase();
          final categoryName = (resource['categoryName'] as String? ?? '')
              .toLowerCase();
          return title.contains(query) ||
              description.contains(query) ||
              categoryName.contains(query);
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
    final categoryName = resource['categoryName'] as String? ?? 'Uncategorized';
    final categoryColor = resource['categoryColor'] as Color? ?? Colors.grey;

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
                  // resourceId: resource['resourceId'] as String,
                  // title: title,
                  // description: description,
                  // link: resource['link'] as String? ?? '',
                  // categoryId: resource['categoryId'] as String,
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

  Future<void> _loadAllResources() async {
    try {
      final resources = await fetchAllResources();
      setState(() {
        _allResources = resources;
      });
    } catch (e) {
      print('Error loading resources: $e');
    }
  }

  Future<List<Map<String, dynamic>>> fetchAllResources() async {
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

    List<Map<String, dynamic>> allResourcesWithCategoryInfo = [];

    final QuerySnapshot<Map<String, dynamic>> categoriesSnapshot =
        await database
            .collection('users')
            .doc(user.uid)
            .collection('categories')
            .get();

    for (QueryDocumentSnapshot<Map<String, dynamic>> categoryDoc
        in categoriesSnapshot.docs) {
      final String categoryId = categoryDoc.id;
      final String categoryName =
          (categoryDoc.data()['name'] as String?) ?? 'Uncategorized';
      final int? categoryColorValue = categoryDoc.data()['color'];
      final Color categoryColor = categoryColorValue != null
          ? Color(categoryColorValue)
          : Colors.grey;

      final QuerySnapshot<Map<String, dynamic>> resourcesSnapshot =
          await categoryDoc.reference.collection('resources').get();

      for (QueryDocumentSnapshot<Map<String, dynamic>> resourceDoc
          in resourcesSnapshot.docs) {
        final Map<String, dynamic> resourceData = resourceDoc.data();
        allResourcesWithCategoryInfo.add({
          ...resourceData,
          'resourceId': resourceDoc.id,
          'categoryId': categoryId,
          'categoryName': categoryName,
          'categoryColor': categoryColor,
        });
      }
    }

    return allResourcesWithCategoryInfo;
  }

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
          : Colors.grey;

      return {"id": doc.id, "name": categoryName, "color": categoryColor};
    }).toList();
  }

  Future<List<Widget>> fetchRecentResources() async {
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

    List<Map<String, dynamic>> allResourcesWithCategoryInfo = [];

    final QuerySnapshot<Map<String, dynamic>> categoriesSnapshot =
        await database
            .collection('users')
            .doc(user.uid)
            .collection('categories')
            .get();

    for (QueryDocumentSnapshot<Map<String, dynamic>> categoryDoc
        in categoriesSnapshot.docs) {
      final String categoryId = categoryDoc.id;
      final String categoryName =
          (categoryDoc.data()['name'] as String?) ?? 'Uncategorized';
      final int? categoryColorValue = categoryDoc.data()['color'];
      final Color categoryColor = categoryColorValue != null
          ? Color(categoryColorValue)
          : Colors.grey;

      final QuerySnapshot<Map<String, dynamic>> resourcesSnapshot =
          await categoryDoc.reference.collection('resources').get();

      for (QueryDocumentSnapshot<Map<String, dynamic>> resourceDoc
          in resourcesSnapshot.docs) {
        final Map<String, dynamic> resourceData = resourceDoc.data();
        allResourcesWithCategoryInfo.add({
          ...resourceData,
          'resourceId': resourceDoc.id,
          'categoryId': categoryId,
          'categoryName': categoryName,
          'categoryColor': categoryColor,
        });
      }
    }

    allResourcesWithCategoryInfo.sort((a, b) {
      final Timestamp? tsA = a['createdAt'] as Timestamp?;
      final Timestamp? tsB = b['createdAt'] as Timestamp?;

      if (tsA == null && tsB == null) return 0;
      if (tsA == null) return 1;
      if (tsB == null) return -1;

      return tsB.compareTo(tsA);
    });

    final int displayCount = allResourcesWithCategoryInfo.length > 6
        ? 6
        : allResourcesWithCategoryInfo.length;
    final List<Map<String, dynamic>> recentResources =
        allResourcesWithCategoryInfo.take(displayCount).toList();

    return recentResources.map((resource) {
      final String resourceId = resource['resourceId'] as String;
      final String title =
          (resource['title'] as String?) ?? 'Untitled Resource';
      final String description =
          (resource['description'] as String?) ?? 'No description';
      final String link = (resource['link'] as String?) ?? '';
      final String categoryId = resource['categoryId'] as String;
      final String categoryName = resource['categoryName'] as String;
      final Color categoryColor = resource['categoryColor'] as Color;

      return ResourceCard(
        id: resourceId,
        title: title,
        description: description,
        link: link,
        categoryId: categoryId,
        categoryName: categoryName,
        categoryColor: categoryColor,
        textColor: const Color.fromARGB(255, 89, 89, 89),
        backgroundColor: Color.fromARGB(255, 233, 233, 233),
        indicator: true,
      );
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
                const SizedBox(height: 15),
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
                          child: const Text(
                            "View All",
                            style: TextStyle(
                              color: Color.fromARGB(255, 87, 175, 161),
                            ),
                          ),
                          onPressed: () {
                            Navigator.push(
                              context,
                              PageRouteBuilder(
                                pageBuilder:
                                    (context, animation, secondaryAnimation) =>
                                        const Library(),
                                transitionDuration: Duration.zero,
                                reverseTransitionDuration: Duration.zero,
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                    SizedBox(
                      width: double.infinity,
                      height: 40,
                      child: FutureBuilder<List<Map<String, dynamic>>>(
                        future: fetchCategories(),
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
                            final int displayCount = categories.length > 3
                                ? 3
                                : categories.length;
                            return Row(
                              children: List.generate(displayCount, (index) {
                                final category = categories[index];
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
                                                ) => Category(
                                                  id: category['id'],
                                                  name: category['name'],
                                                  color: category['color'],
                                                ),
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
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  height: 470,
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
                        child: FutureBuilder<List<Widget>>(
                          future: fetchRecentResources(),
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
                                child: Text('No recent resources found.'),
                              );
                            } else {
                              return MasonryGridView.count(
                                crossAxisCount: 2,
                                crossAxisSpacing: 10,
                                mainAxisSpacing: 10,
                                itemCount: snapshot.data!.length,
                                itemBuilder: (context, index) =>
                                    snapshot.data![index],
                              );
                            }
                          },
                        ),
                      ),
                    ],
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
