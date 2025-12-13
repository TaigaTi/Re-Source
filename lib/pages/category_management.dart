import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/material.dart';
import 'package:re_source/colors.dart';
import 'package:re_source/widgets/back_title.dart';
import 'package:re_source/widgets/custom_appbar.dart';
import 'package:re_source/widgets/custom_drawer.dart';

class CategoryManagement extends StatefulWidget {
  const CategoryManagement({super.key});

  @override
  State<CategoryManagement> createState() => _CategoryManagementState();
}

class _CategoryManagementState extends State<CategoryManagement> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _categories = [];
  final TextEditingController _newCategoryController = TextEditingController();
  Color _selectedColor = colors[0];

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  @override
  void dispose() {
    _newCategoryController.dispose();
    super.dispose();
  }

  Future<void> _loadCategories() async {
    setState(() => _isLoading = true);
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      final snapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('categories')
          .get();

      final categories = snapshot.docs.map((doc) {
        final data = doc.data();
        return {
          'id': doc.id,
          'name': data['name'] as String? ?? 'Untitled',
          'color': data['color'] as int?,
        };
      }).toList();

      setState(() {
        _categories = categories;
        _isLoading = false;
      });
    } catch (e, s) {
      await FirebaseCrashlytics.instance.recordError(
        e,
        s,
        reason: 'Failed to load categories',
      );
      setState(() => _isLoading = false);
    }
  }

  Future<void> _addCategory() async {
    final name = _newCategoryController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a category name')),
      );
      return;
    }

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('categories')
          .add({
        'name': name,
        'color': _selectedColor.value,
        'createdAt': FieldValue.serverTimestamp(),
        'lastAccessed': FieldValue.serverTimestamp(),
      });

      _newCategoryController.clear();
      setState(() => _selectedColor = colors[0]);
      await _loadCategories();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Category added successfully')),
        );
      }
    } catch (e, s) {
      await FirebaseCrashlytics.instance.recordError(
        e,
        s,
        reason: 'Failed to add category',
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to add category: $e')),
        );
      }
    }
  }

  Future<Color?> _showPreciseColorPicker(Color currentColor) async {
    Color tempColor = currentColor;
    
    return showDialog<Color>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Pick a Color'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 200,
                  height: 60,
                  decoration: BoxDecoration(
                    color: tempColor,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.grey),
                  ),
                ),
                const SizedBox(height: 20),
                // Hue Slider
                const Text('Hue', style: TextStyle(fontWeight: FontWeight.w500)),
                Slider(
                  value: HSVColor.fromColor(tempColor).hue,
                  max: 360,
                  divisions: 360,
                  onChanged: (value) {
                    setState(() {
                      final hsv = HSVColor.fromColor(tempColor);
                      tempColor = hsv.withHue(value).toColor();
                    });
                  },
                ),
                // Saturation Slider
                const Text('Saturation', style: TextStyle(fontWeight: FontWeight.w500)),
                Slider(
                  value: HSVColor.fromColor(tempColor).saturation,
                  onChanged: (value) {
                    setState(() {
                      final hsv = HSVColor.fromColor(tempColor);
                      tempColor = hsv.withSaturation(value).toColor();
                    });
                  },
                ),
                // Value Slider
                const Text('Brightness', style: TextStyle(fontWeight: FontWeight.w500)),
                Slider(
                  value: HSVColor.fromColor(tempColor).value,
                  onChanged: (value) {
                    setState(() {
                      final hsv = HSVColor.fromColor(tempColor);
                      tempColor = hsv.withValue(value).toColor();
                    });
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, tempColor),
              child: const Text('Select'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _deleteCategory(String categoryId, String categoryName) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Category'),
        content: Text(
          'Are you sure you want to delete "$categoryName"? All resources in this category will also be deleted.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      final categoryRef = FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('categories')
          .doc(categoryId);

      // Delete all resources in the category
      final resources = await categoryRef.collection('resources').get();
      for (final doc in resources.docs) {
        await doc.reference.delete();
      }

      // Delete the category
      await categoryRef.delete();

      await _loadCategories();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Category deleted successfully')),
        );
      }
    } catch (e, s) {
      await FirebaseCrashlytics.instance.recordError(
        e,
        s,
        reason: 'Failed to delete category',
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to delete category: $e')),
        );
      }
    }
  }

  Future<void> _editCategory(Map<String, dynamic> category) async {
    final controller = TextEditingController(text: category['name'] as String);
    Color selectedColor = category['color'] != null
        ? Color(category['color'] as int)
        : colors[0];

    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Edit Category'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: controller,
                  decoration: const InputDecoration(
                    labelText: 'Category Name',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Quick Colors',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    ...colors.map((color) {
                      final isSelected = color.value == selectedColor.value;
                      return GestureDetector(
                        onTap: () => setState(() => selectedColor = color),
                        child: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: color,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: isSelected ? Colors.black : Colors.transparent,
                              width: 3,
                            ),
                          ),
                        ),
                      );
                    }),
                    GestureDetector(
                      onTap: () async {
                        final newColor = await _showPreciseColorPicker(selectedColor);
                        if (newColor != null) {
                          setState(() => selectedColor = newColor);
                        }
                      },
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.surfaceContainerHighest,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Theme.of(context).colorScheme.outline,
                            width: 2,
                          ),
                        ),
                        child: Icon(
                          Icons.colorize,
                          size: 20,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context, {
                  'name': controller.text.trim(),
                  'color': selectedColor.value,
                });
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );

    if (result == null) return;

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('categories')
          .doc(category['id'] as String)
          .update({
        'name': result['name'],
        'color': result['color'],
      });

      await _loadCategories();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Category updated successfully')),
        );
      }
    } catch (e, s) {
      await FirebaseCrashlytics.instance.recordError(
        e,
        s,
        reason: 'Failed to update category',
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update category: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: const CustomAppBar(),
      drawer: const CustomDrawer(),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(30),
          child: Column(
            children: [
              const BackTitle(title: "Category Management"),
              const SizedBox(height: 20),
              Card(
                color: isDark
                    ? theme.colorScheme.surfaceContainerHighest
                    : theme.colorScheme.surfaceContainerLow,
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Add New Category',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: _newCategoryController,
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: isDark
                              ? theme.colorScheme.surfaceContainerHigh
                              : theme.colorScheme.surfaceContainerLowest,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide.none,
                          ),
                          hintText: 'Category Name',
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Padding(
                        padding: const EdgeInsets.only(right: 5),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Quick Colors',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            Row(
                              children: [
                                const Text(
                                  'Selected: ',
                                  style: TextStyle(fontSize: 12),
                                ),
                                Container(
                                  width: 20,
                                  height: 20,
                                  decoration: BoxDecoration(
                                    color: _selectedColor,
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: theme.colorScheme.outline,
                                      width: 2,
                                    ),
                                  ),
                                ),
                                SizedBox(width: 20),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 15),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          ...colors.map((color) {
                            final isSelected = color.value == _selectedColor.value;
                            return GestureDetector(
                              onTap: () => setState(() => _selectedColor = color),
                              child: Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  color: color,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: isSelected
                                        ? theme.colorScheme.primary
                                        : Colors.transparent,
                                    width: 3,
                                  ),
                                ),
                              ),
                            );
                          }),
                          GestureDetector(
                            onTap: () async {
                              final color = await _showPreciseColorPicker(_selectedColor);
                              if (color != null) {
                                setState(() => _selectedColor = color);
                              }
                            },
                            child: Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: isDark
                                    ? theme.colorScheme.surfaceContainerHigh
                                    : theme.colorScheme.surfaceContainerLowest,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: theme.colorScheme.outline,
                                  width: 2,
                                ),
                              ),
                              child: Icon(
                                Icons.colorize,
                                size: 20,
                                color: theme.colorScheme.primary,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      FilledButton(
                        onPressed: _addCategory,
                        style: ButtonStyle(
                          minimumSize: WidgetStateProperty.all(
                            const Size(double.infinity, 45),
                          ),
                          shape: WidgetStateProperty.all(
                            RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        ),
                        child: const Text(
                          'Add Category',
                          style: TextStyle(fontSize: 16),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Card(
                color: isDark
                    ? theme.colorScheme.surfaceContainerHighest
                    : theme.colorScheme.surfaceContainerLow,
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Your Categories',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 16),
                      _isLoading
                          ? const Center(
                              child: Padding(
                                padding: EdgeInsets.all(24),
                                child: CircularProgressIndicator(),
                              ),
                            )
                          : _categories.isEmpty
                              ? const Padding(
                                  padding: EdgeInsets.all(24),
                                  child: Center(
                                    child: Text('No categories yet'),
                                  ),
                                )
                              : ListView.separated(
                                  shrinkWrap: true,
                                  physics: const NeverScrollableScrollPhysics(),
                                  itemCount: _categories.length,
                                  separatorBuilder: (context, index) =>
                                      const Divider(height: 1),
                                  itemBuilder: (context, index) {
                                    final category = _categories[index];
                                    final categoryColor = category['color'] != null
                                        ? Color(category['color'] as int)
                                        : Colors.grey;

                                    return ListTile(
                                      contentPadding: const EdgeInsets.symmetric(
                                        vertical: 8,
                                        horizontal: 0,
                                      ),
                                      leading: Container(
                                        width: 40,
                                        height: 40,
                                        decoration: BoxDecoration(
                                          color: categoryColor,
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                      title: Text(
                                        category['name'] as String,
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                      trailing: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          IconButton(
                                            icon: const Icon(Icons.edit),
                                            onPressed: () => _editCategory(category),
                                          ),
                                          IconButton(
                                            icon: const Icon(
                                              Icons.delete,
                                              color: Colors.red,
                                            ),
                                            onPressed: () => _deleteCategory(
                                              category['id'] as String,
                                              category['name'] as String,
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                  },
                                ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
