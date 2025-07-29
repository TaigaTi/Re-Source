import 'dart:ffi';

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
  final String? title;
  final String? link;
  final String? category;
  final String? description;
  final Bool existingResource;

  const EditResource({
    super.key,
    required this.link,
    this.title,
    this.category,
    this.description,
    required this.existingResource,
  });

  @override
  State<EditResource> createState() => _EditResourceState();
}

class _EditResourceState extends State<EditResource> {
  late TextEditingController _titleController = TextEditingController(
    text: widget.title ?? "",
  );
  late TextEditingController _descriptionController = TextEditingController(
    text: widget.description ?? "",
  );
  String? _selectedCategory;
  List<Map<String, Object>> _categories = [];
  XFile? _pickedImageFile;
  String? _imageUrl;
  bool _isUploadingImage = false;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController();
    _descriptionController = TextEditingController();

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
        if (_descriptionController.text.isEmpty) {
          _descriptionController.text = metadata['description'] ?? '';
        }
        if (_imageUrl == null && (metadata['image'] ?? '').isNotEmpty) {
          _imageUrl = metadata['image'];
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

  Future<String?> _uploadImageIfNeeded() async {
    if (_pickedImageFile == null) {
      return _imageUrl;
    }

    setState(() {
      _isUploadingImage = true;
    });

    try {
      final FirebaseStorage storage = FirebaseStorage.instance;
      final String fileName =
          'resource_images/${DateTime.now().millisecondsSinceEpoch}_${_pickedImageFile!.name}';
      final Reference ref = storage.ref().child(fileName);

      final UploadTask uploadTask = ref.putData(
        await _pickedImageFile!.readAsBytes(),
      );
      final TaskSnapshot snapshot = await uploadTask;
      final String downloadUrl = await snapshot.ref.getDownloadURL();

      return downloadUrl;
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
      if (_pickedImageFile != null) {
        imageUrlToSave = await _uploadImageIfNeeded();
        if (imageUrlToSave == null) return; // Stop if upload failed
      }

      final String linkToSave = await ensureLinkProtocol(widget.link);

      await resourcesCollectionRef.add({
        'title': title,
        'link': linkToSave,
        'description': description,
        'image': imageUrlToSave ?? '',
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
      if (_pickedImageFile != null) {
        imageUrlToSave = await _uploadImageIfNeeded();
        if (imageUrlToSave == null) return; // Stop if upload failed
      }

      final String linkToSave = await ensureLinkProtocol(widget.link);

      await resourcesCollectionRef.add({
        'title': title,
        'link': linkToSave,
        'description': description,
        'image': imageUrlToSave ?? '',
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
                            maxLength: 35,
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
                                    : const Text("Change Image"),
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
                                : (_imageUrl != null && _imageUrl!.isNotEmpty
                                      ? Image.network(
                                          _imageUrl!,
                                          fit: BoxFit.cover,
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
