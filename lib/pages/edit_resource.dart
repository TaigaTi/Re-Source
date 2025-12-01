import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:re_source/pages/login.dart';
import 'package:re_source/pages/success.dart';
import 'package:re_source/widgets/back_title.dart';
import 'package:re_source/widgets/custom_appbar.dart';
import 'package:re_source/widgets/custom_drawer.dart';
import 'dart:math';
import 'package:re_source/colors.dart';
import 'package:re_source/widgets/searchable_dropdown.dart';
import 'package:http/http.dart' as http;
import 'package:html/dom.dart' as html_dom;
import 'package:html/parser.dart' as html_parser;
import 'dart:io';

class EditResource extends StatefulWidget {
  final String? resourceId;
  final String? title;
  final String? link;
  final String? category;
  final String? description;
  final String? image;
  final bool existingResource;

  const EditResource({
    super.key,
    this.resourceId,
    required this.link,
    this.title,
    this.category,
    this.description,
    this.image,
    required this.existingResource,
  });

  @override
  State<EditResource> createState() => _EditResourceState();
}

class _EditResourceState extends State<EditResource> {
  Future<void> _deleteResource() async {
    final FirebaseFirestore database = FirebaseFirestore.instance;
    final FirebaseAuth auth = FirebaseAuth.instance;
    final FirebaseStorage storage = FirebaseStorage.instance;
    final User? user = auth.currentUser;
    if (user == null ||
        widget.resourceId == null ||
        widget.resourceId!.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('User or resource ID missing.')),
        );
      }
      return;
    }
    // Find category ID
    String? categoryId = widget.category;
    if (categoryId == null || categoryId.isEmpty) {
      // Try to find from Firestore
      final userCategoriesRef = database
          .collection('users')
          .doc(user.uid)
          .collection('categories');
      final query = await userCategoriesRef
          .where('name', isEqualTo: widget.category)
          .limit(1)
          .get();
      if (query.docs.isNotEmpty) {
        categoryId = query.docs.first.id;
      }
    }
    if (categoryId == null || categoryId.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Category not found.')));
      }
      return;
    }
    final resourceRef = database
        .collection('users')
        .doc(user.uid)
        .collection('categories')
        .doc(categoryId)
        .collection('resources')
        .doc(widget.resourceId);
    try {
      final resourceDoc = await resourceRef.get();
      if (resourceDoc.exists) {
        final data = resourceDoc.data() ?? {};
        final String? storagePath = data['storagePath'] as String?;
        // Delete image from Firebase Storage if storagePath exists
        if (storagePath != null && storagePath.isNotEmpty) {
          try {
            await storage.ref().child(storagePath).delete();
          } catch (e) {
            debugPrint('Failed to delete image from storage: $e');
          }
        }
        await resourceRef.delete();
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('Resource deleted.')));
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
      }
    } catch (e, s) {
      await FirebaseCrashlytics.instance.recordError(
        e,
        s,
        reason: 'Error deleting resource',
        fatal: false,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to delete resource: $e')),
        );
      }
    }
  }

  late TextEditingController _titleController;
  late TextEditingController _descriptionController;
  String? _selectedCategory;
  List<Map<String, Object>> _categories = [];
  XFile? _pickedImageFile;
  String? _imageUrl;
  bool _isUploadingImage = false;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.title ?? "");
    _descriptionController = TextEditingController(
      text: widget.description ?? "",
    );
    _selectedCategory = widget.category;
    _imageUrl = widget.image;
    if (_imageUrl != null && _imageUrl!.isNotEmpty) {
      debugPrint('EditResource: imageUrl from Firestore: $_imageUrl');
    }
    _fetchCategories();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _populateMetadataFromUrl();
    });
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<Map<String, String>> fetchUrlMetadata(String url) async {
    String ensureProtocol(String url, String protocol) {
      return url.startsWith('http://') || url.startsWith('https://')
          ? url.replaceFirst(RegExp(r'^https?://'), '$protocol://')
          : '$protocol://$url';
    }

    String httpsUrl = ensureProtocol(url, 'https');
    String httpUrl = ensureProtocol(url, 'http');

    http.Response? response;

    try {
      response = await http.get(Uri.parse(httpsUrl));
      if (response.statusCode != 200) {
        response = await http.get(Uri.parse(httpUrl));
      }
    } catch (_) {
      try {
        response = await http.get(Uri.parse(httpUrl));
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error fetching metadata: $e')),
          );
        }
        rethrow;
      }
    }

    if (response.statusCode == 200) {
      final html_dom.Document document = html_parser.parse(response.body);

      final html_dom.Element? titleTag = document.querySelector('title');
      final html_dom.Element? descriptionTag = document.querySelector(
        'meta[name="description"]',
      );
      final html_dom.Element? imageTag =
          document.querySelector('meta[property="og:image"]') ??
          document.querySelector('meta[name="twitter:image"]');

      final String titleText = titleTag?.text.trim() ?? '';
      final String descriptionText =
          descriptionTag?.attributes['content']?.trim() ?? '';
      final String imageUrl = imageTag?.attributes['content']?.trim() ?? '';

      if (mounted) {
        setState(() {
          _titleController.text = titleText;
          _descriptionController.text = descriptionText;
          if (imageUrl.isNotEmpty) {
            _imageUrl = imageUrl;
          }
        });
      }

      return {
        'title': titleText,
        'description': descriptionText,
        'image': imageUrl,
      };
    } else {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to load URL metadata.')));
      }
      return {};
    }
  }

  Future<void> _populateMetadataFromUrl() async {
    if (widget.link == null || widget.link!.isEmpty) return;

    final metadata = await fetchUrlMetadata(widget.link!);
    if (mounted && metadata.isNotEmpty) {
      setState(() {
        if (_titleController.text.isEmpty) {
          _titleController.text = metadata['title'] ?? '';
        }
        // Only autofill description if both controller and widget.description are empty
        // Never overwrite description if widget.description is non-empty
        if ((_descriptionController.text.isEmpty) &&
            (widget.description == null || widget.description!.isEmpty)) {
          _descriptionController.text = metadata['description'] ?? '';
        }
        // Prevent overwriting passed-in description
        if (widget.description != null && widget.description!.isNotEmpty) {
          _descriptionController.text = widget.description!;
        }
        // Only autofill image if not already set from Firestore
        if ((_imageUrl == null || _imageUrl!.isEmpty) &&
            (metadata['image'] ?? '').isNotEmpty) {
          _imageUrl = metadata['image'];
          debugPrint('EditResource: imageUrl from metadata: $_imageUrl');
        }
      });
    }
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

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile == null) return;
    setState(() {
      _pickedImageFile = pickedFile;
      _imageUrl = pickedFile.path;
    });
  }

  /// Uploads picked image and returns both the download URL and the storage path.
  /// Returned map keys: 'downloadUrl' and 'storagePath'.
  Future<Map<String, String>?> _uploadImageIfNeeded() async {
    if (_pickedImageFile == null) {
      // Nothing picked, return existing image if any (no storagePath)
      if (_imageUrl != null && _imageUrl!.isNotEmpty) {
        return {'downloadUrl': _imageUrl!, 'storagePath': ''};
      }
      return null;
    }

    setState(() {
      _isUploadingImage = true;
    });

    try {
      final FirebaseStorage storage = FirebaseStorage.instance;
      final String storagePath =
          'resource_images/${DateTime.now().millisecondsSinceEpoch}_${_pickedImageFile!.name}';
      final Reference ref = storage.ref().child(storagePath);

      final UploadTask uploadTask = ref.putData(
        await _pickedImageFile!.readAsBytes(),
      );
      final TaskSnapshot snapshot = await uploadTask;
      final String downloadUrl = await snapshot.ref.getDownloadURL();

      return {'downloadUrl': downloadUrl, 'storagePath': storagePath};
    } catch (e, s) {
      await FirebaseCrashlytics.instance.recordError(
        e,
        s,
        reason: 'Failed to upload image.',
        fatal: false,
      );
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to upload image: $e')));
      }
      return null;
    } finally {
      if (mounted) {
        setState(() {
          _isUploadingImage = false;
        });
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

    Future<String> ensureLinkProtocol(String? link) async {
      if (link == null || link.isEmpty) return '';

      if (link.startsWith('http://') || link.startsWith('https://')) {
        return link;
      }

      final httpsUrl = Uri.parse('https://$link');
      final httpUrl = Uri.parse('http://$link');

      try {
        final httpsResponse = await http
            .head(httpsUrl)
            .timeout(const Duration(seconds: 2));
        if (httpsResponse.statusCode < 400) return httpsUrl.toString();
      } catch (_) {}

      try {
        final httpResponse = await http
            .head(httpUrl)
            .timeout(const Duration(seconds: 2));
        if (httpResponse.statusCode < 400) return httpUrl.toString();
      } catch (_) {}

      // If both fail, default to https
      return httpsUrl.toString();
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

      String? imageUrlToSave = _imageUrl;
      String? storagePathToSave;
      if (_pickedImageFile != null) {
        final uploadResult = await _uploadImageIfNeeded();
        if (uploadResult == null) return; // Stop if upload failed
        imageUrlToSave = uploadResult['downloadUrl'];
        storagePathToSave = uploadResult['storagePath'];
      }

      final String linkToSave = await ensureLinkProtocol(widget.link);

      await resourcesCollectionRef.add({
        'title': title,
        'link': linkToSave,
        'description': description,
        'image': imageUrlToSave ?? '',
        'storagePath': storagePathToSave ?? '',
        'addedAt': FieldValue.serverTimestamp(),
        'ownerId': user.uid,
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

  Future<void> updateResource() async {
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
            content: Text('You must be logged in to update resources.'),
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

    Future<String> ensureLinkProtocol(String? link) async {
      if (link == null || link.isEmpty) return '';

      if (link.startsWith('http://') || link.startsWith('https://')) {
        return link;
      }

      final httpsUrl = Uri.parse('https://$link');
      final httpUrl = Uri.parse('http://$link');

      try {
        final httpsResponse = await http
            .head(httpsUrl)
            .timeout(const Duration(seconds: 2));
        if (httpsResponse.statusCode < 400) return httpsUrl.toString();
      } catch (_) {}

      try {
        final httpResponse = await http
            .head(httpUrl)
            .timeout(const Duration(seconds: 2));
        if (httpResponse.statusCode < 400) return httpUrl.toString();
      } catch (_) {}

      // If both fail, default to https
      return httpsUrl.toString();
    }

    try {
      final userCategoriesRef = database
          .collection('users')
          .doc(user.uid)
          .collection('categories');

      // Find the new category ID
      String newCategoryId;
      final newCategoryQuery = await userCategoriesRef
          .where('name', isEqualTo: categoryName)
          .limit(1)
          .get();

      if (newCategoryQuery.docs.isNotEmpty) {
        newCategoryId = newCategoryQuery.docs.first.id;
      } else {
        final newCategoryDocRef = await userCategoriesRef.add({
          'name': categoryName,
          'createdAt': FieldValue.serverTimestamp(),
          'color': getRandomCategoryColor(),
        });
        newCategoryId = newCategoryDocRef.id;
      }

      // Find the old category ID (from widget.category)
      String? oldCategoryId;
      if (widget.category != null && widget.category!.isNotEmpty) {
        final oldCategoryQuery = await userCategoriesRef
            .where('name', isEqualTo: widget.category)
            .limit(1)
            .get();
        if (oldCategoryQuery.docs.isNotEmpty) {
          oldCategoryId = oldCategoryQuery.docs.first.id;
        }
      }

      // Prepare image upload if needed
      String? imageUrlToSave = _imageUrl;
      String? storagePathToSave;
      if (_pickedImageFile != null) {
        final uploadResult = await _uploadImageIfNeeded();
        if (uploadResult == null) return; // Stop if upload failed
        imageUrlToSave = uploadResult['downloadUrl'];
        storagePathToSave = uploadResult['storagePath'];
      }

      final String linkToSave = await ensureLinkProtocol(widget.link);

      // Only proceed if resourceId is present
      if (widget.resourceId == null || widget.resourceId!.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Resource ID missing. Cannot update resource.'),
            ),
          );
        }
        return;
      }

      // If category changed, move resource
      if (oldCategoryId != null && oldCategoryId != newCategoryId) {
        // Delete from old category
        final oldResourceRef = userCategoriesRef
            .doc(oldCategoryId)
            .collection('resources')
            .doc(widget.resourceId);

        final oldResourceSnapshot = await oldResourceRef.get();
        if (oldResourceSnapshot.exists) {
          await oldResourceRef.delete();
        }

        // Add to new category with same resourceId
        final newResourceRef = userCategoriesRef
            .doc(newCategoryId)
            .collection('resources')
            .doc(widget.resourceId);

        await newResourceRef.set({
          'title': title,
          'link': linkToSave,
          'description': description,
          'image': imageUrlToSave ?? '',
          'storagePath': storagePathToSave ?? '',
          'addedAt': FieldValue.serverTimestamp(),
          'ownerId': user.uid,
        });
      } else if (oldCategoryId != null) {
        // Category did not change, just update resource
        final resourceRef = userCategoriesRef
            .doc(oldCategoryId)
            .collection('resources')
            .doc(widget.resourceId);

        final updateData = {
          'title': title,
          'link': linkToSave,
          'description': description,
          'image': imageUrlToSave ?? '',
          'ownerId': user.uid,
        };
        if (storagePathToSave != null) {
          updateData['storagePath'] = storagePathToSave;
        }
        await resourceRef.update(updateData);
      }

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
        reason: 'Error updating resource.',
        fatal: false,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update resource: $e')),
        );
      }
      rethrow;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final isLight = cs.brightness == Brightness.light;
    final cardColor = isLight ? cs.surfaceVariant : cs.surface;
    final inputFill = cs.surface;
    final inputTextColor = theme.textTheme.bodyMedium?.color ?? cs.onSurface;

    return Scaffold(
      backgroundColor: cs.background,
      appBar: CustomAppBar(),
      drawer: CustomDrawer(),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Container(
            padding: const EdgeInsets.all(30),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: BackTitle(
                        title: widget.existingResource
                            ? "Edit Resource"
                            : "Add Resource",
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 15),
                Card(
                  color: cardColor,
                  child: SizedBox(
                    width: double.infinity,
                    child: Container(
                      padding: const EdgeInsets.all(35),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("Title", style: theme.textTheme.titleMedium),
                          const SizedBox(height: 5),
                          TextField(
                            controller: _titleController,
                            maxLength: 35,
                            decoration: InputDecoration(
                              filled: true,
                              fillColor: inputFill,
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
                            style: TextStyle(color: inputTextColor),
                          ),
                          const SizedBox(height: 15),

                          Text("Category", style: theme.textTheme.titleMedium),
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

                          Text(
                            "Description",
                            style: theme.textTheme.titleMedium,
                          ),
                          const SizedBox(height: 5),
                          TextField(
                            controller: _descriptionController,
                            maxLines: null,
                            minLines: 3,
                            keyboardType: TextInputType.multiline,
                            decoration: InputDecoration(
                              filled: true,
                              fillColor: inputFill,
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
                            style: TextStyle(color: inputTextColor),
                          ),
                          const SizedBox(height: 15),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text("Image", style: theme.textTheme.titleMedium),
                              TextButton(
                                onPressed: _isUploadingImage
                                    ? null
                                    : _pickImage,
                                child: _isUploadingImage
                                    ? const SizedBox(
                                        width: 18,
                                        height: 18,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                        ),
                                      )
                                    : Text(
                                        "Change Image",
                                        style: TextStyle(color: cs.primary),
                                      ),
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
                            child: _pickedImageFile != null
                                ? Image.file(
                                    File(_pickedImageFile!.path),
                                    fit: BoxFit.cover,
                                  )
                                : (_imageUrl != null &&
                                          _imageUrl!.startsWith('http')
                                      ? Image.network(
                                          _imageUrl!,
                                          fit: BoxFit.cover,
                                          loadingBuilder: (context, child, loadingProgress) {
                                            if (loadingProgress == null)
                                              return child;
                                            return Container(
                                              color: cs.surfaceVariant,
                                              child: Center(
                                                child: SizedBox(
                                                  width: 40,
                                                  height: 40,
                                                  child: CircularProgressIndicator(
                                                    value:
                                                        loadingProgress
                                                                .expectedTotalBytes !=
                                                            null
                                                        ? loadingProgress
                                                                  .cumulativeBytesLoaded /
                                                              (loadingProgress
                                                                      .expectedTotalBytes ??
                                                                  1)
                                                        : null,
                                                  ),
                                                ),
                                              ),
                                            );
                                          },
                                          errorBuilder:
                                              (context, error, stackTrace) =>
                                                  Image.asset(
                                                    'assets/images/success.png',
                                                    fit: BoxFit.cover,
                                                  ),
                                        )
                                      : Image.asset(
                                          'assets/images/success.png',
                                          fit: BoxFit.cover,
                                        )),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                FilledButton(
                  onPressed: () => {
                    widget.existingResource ? updateResource() : addResource(),
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
                    backgroundColor: WidgetStateProperty.all(cs.primary),
                  ),
                  child: Text(
                    "Next",
                    style:
                        theme.textTheme.titleMedium?.copyWith(
                          color: cs.onPrimary,
                        ) ??
                        const TextStyle(fontSize: 18),
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
