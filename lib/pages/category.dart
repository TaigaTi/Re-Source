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
  State<Category> createState() => _CategoryState();
}

class _CategoryState extends State<Category> {
  final TextEditingController _searchController = TextEditingController();
  // We'll use a realtime stream to get resource updates
  bool _modified = false;

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<List<Map<String, dynamic>>> fetchResources() async {
    final FirebaseFirestore database = FirebaseFirestore.instance;
    final FirebaseAuth auth = FirebaseAuth.instance;

    final User? user = auth.currentUser;

    if (user == null) {
      if (mounted) {
        Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => const Login()));
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
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to load resources: $e')));
      }
      return [];
    }
  }

  Future<void> _refreshResources() async {
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return PopScope(
      canPop: true,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop && _modified) {
          // The pop already happened, we just need to ensure modified state is communicated
        }
      },
      child: Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        appBar: const CustomAppBar(),
        drawer: const CustomDrawer(),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(30, 20, 30, 50),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                BackTitle(title: widget.name ?? "Untitled"),
                const SizedBox(height: 20),
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Looking for something?',
                    prefixIcon: const Icon(Icons.search),
                    filled: true,
                    fillColor: isDark
                        ? theme.colorScheme.surfaceContainer
                        : const Color.fromRGBO(233, 233, 233, 1.0),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(50.0),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  onChanged: (value) {
                    // For simplicity, we'll filter client-side after fetch
                    setState(() {});
                  },
                ),
                const SizedBox(height: 20),
                Expanded(
                  child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                    stream: (widget.id != null && widget.id!.isNotEmpty)
                        ? FirebaseFirestore.instance
                            .collection('users')
                            .doc(FirebaseAuth.instance.currentUser?.uid)
                            .collection('categories')
                            .doc(widget.id)
                            .collection('resources')
                            .orderBy('addedAt', descending: true)
                            .snapshots()
                        : const Stream.empty(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      } else if (snapshot.hasError) {
                        return Center(child: Text('Error: ${snapshot.error}'));
                      } else if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                        return const Center(
                          child: Text('No resources found in this category.'),
                        );
                      } else {
                        List<Map<String, dynamic>> resources = snapshot.data!.docs
                            .map((d) => {'id': d.id, ...d.data()})
                            .toList();

                        final query = _searchController.text.toLowerCase().trim();
                        if (query.isNotEmpty) {
                          resources = resources.where((r) {
                            final title = (r['title'] as String? ?? '').toLowerCase();
                            final description = (r['description'] as String? ?? '').toLowerCase();
                            return title.contains(query) || description.contains(query);
                          }).toList();
                        }

                        return MasonryGridView.count(
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
                              image: resourceData['image'] ?? '',
                              storagePath: resourceData['storagePath'] ?? '',
                              textColor: theme.colorScheme.onSurface,
                              backgroundColor: theme.colorScheme.surfaceContainerHighest,
                              onOpen: (ctx) async {
                                final result = await Navigator.push<bool?>(
                                  ctx,
                                  MaterialPageRoute(
                                    builder: (_) => ResourceDetails(
                                      resourceId: resourceData['id'] as String,
                                      title: resourceData['title'] ?? '',
                                      description: resourceData['description'] ?? '',
                                      link: resourceData['link'] ?? '',
                                      categoryId: widget.id ?? '',
                                      categoryName: widget.name ?? '',
                                      categoryColor: widget.color ?? Colors.grey,
                                      storagePath: resourceData['storagePath'] ?? '',
                                    ),
                                  ),
                                );

                                if (result == true) {
                                  // Resource was deleted/modified in details, refresh flag
                                  _modified = true;
                                }
                                return null;
                              },
                            );
                          },
                        );
                      }
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
        bottomNavigationBar: Container(
          color: theme.scaffoldBackgroundColor,
          padding: const EdgeInsets.fromLTRB(30.0, 40.0, 30.0, 50.0),
          child: SafeArea(
            top: false,
            child: FilledButton(
              onPressed: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const NewResource()),
                );
                await _refreshResources();
                _modified = true;
              },
              style: ButtonStyle(
                minimumSize: WidgetStateProperty.all(const Size(double.infinity, 45)),
                shape: WidgetStateProperty.all(RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                backgroundColor: WidgetStateProperty.all(theme.colorScheme.primary),
              ),
              child: const Text("Add Resource", style: TextStyle(fontSize: 16)),
            ),
          ),
        ),
      ),
    );
  }
}
