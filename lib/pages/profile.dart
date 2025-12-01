import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/material.dart';
import 'package:re_source/pages/login.dart';
import 'package:re_source/widgets/custom_appbar.dart';
import 'package:re_source/widgets/custom_drawer.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  String? _userEmail;
  bool _isLoading = true;
  String? _profileImageUrl;
  bool _uploading = false;

  @override
  void initState() {
    super.initState();
    _loadUserEmail();
  }

  void _loadUserEmail() {
    final User? user = FirebaseAuth.instance.currentUser;

    if (user != null) {
      setState(() {
        _userEmail = user.email;
        _isLoading = false;
      });
      _loadProfileImage(user.uid);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('You must be logged in to view your profile.'),
          ),
        );
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const Login()),
          (route) => false,
        );
      }
    }
  }

  Future<void> _loadProfileImage(String uid) async {
    try {
      final doc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
      setState(() {
        _profileImageUrl = doc.data()?['profileImageUrl'] as String?;
      });
    } catch (_) {}
  }

  Future<void> _changeProfileImage() async {
    final User? user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      final picker = ImagePicker();
      final XFile? picked = await picker.pickImage(source: ImageSource.gallery, maxWidth: 1024, maxHeight: 1024, imageQuality: 85);
      if (picked == null) return;

      setState(() => _uploading = true);

      final file = File(picked.path);
      final storageRef = FirebaseStorage.instance.ref().child('users/${user.uid}/profile.jpg');
      final uploadTask = await storageRef.putFile(file, SettableMetadata(contentType: 'image/jpeg'));
      final url = await uploadTask.ref.getDownloadURL();

      await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
        'profileImageUrl': url,
        'profileImageStoragePath': 'users/${user.uid}/profile.jpg',
      }, SetOptions(merge: true));

      setState(() {
        _profileImageUrl = url;
        _uploading = false;
      });
    } catch (e, s) {
      await FirebaseCrashlytics.instance.recordError(e, s, reason: 'Failed to change profile image');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to upload image: $e')));
      }
      setState(() => _uploading = false);
    }
  }

  Future<void> _logout() async {
    try {
      await FirebaseAuth.instance.signOut();
      if (mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const Login()),
          (route) => false,
        );
      }
    } catch (e, stack) {
      await FirebaseCrashlytics.instance.recordError(
        e,
        stack,
        reason: 'Error during logout',
      );
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to log out: $e')));
      }
    }
  }

  bool _isDeleting = false;

  Future<void> deleteUserData(String userId) async {
    final db = FirebaseFirestore.instance;

    final categoriesSnapshot = await db
        .collection('users')
        .doc(userId)
        .collection('categories')
        .get();

    for (final categoryDoc in categoriesSnapshot.docs) {
      final resourcesSnapshot = await categoryDoc.reference
          .collection('resources')
          .get();

      for (final resourceDoc in resourcesSnapshot.docs) {
        await resourceDoc.reference.delete();
      }

      await categoryDoc.reference.delete();
    }

    await db.collection('users').doc(userId).delete();
  }

  Future<void> _deleteAccount() async {
    final User? user = FirebaseAuth.instance.currentUser;

    if (!mounted || user == null) return;

    bool? confirm = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text(
                'Delete Account',
                style: TextStyle(fontWeight: FontWeight.w500),
              ),
              content: const Text(
                'Are you sure you want to permanently delete your account?\n\nThis action cannot be undone.',
                style: TextStyle(fontSize: 16),
              ),
              actions: [
                TextButton(
                  onPressed: _isDeleting
                      ? null
                      : () => Navigator.of(context).pop(false),
                  child: const Text('Cancel'),
                ),
                _isDeleting
                    ? Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      )
                    : TextButton(
                        onPressed: () async {
                          setState(() => _isDeleting = true);
                          Navigator.of(context).pop(true);
                        },
                        child: const Text(
                          'Delete',
                          style: TextStyle(color: Colors.red),
                        ),
                      ),
              ],
            );
          },
        );
      },
    );

    if (confirm != true) {
      _isDeleting = false;
      return;
    }

    try {
      setState(() => _isDeleting = true);

      final database = FirebaseFirestore.instance;
      final userRecord = database.collection('users').doc(user.uid);

      await deleteUserData(user.uid);
      await userRecord.delete();
      await user.delete();

      if (mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const Login()),
          (route) => false,
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to delete account: $e')));
        setState(() => _isDeleting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(),
      drawer: const CustomDrawer(),
      backgroundColor: Colors.white,
      body: Padding(
        padding: const EdgeInsets.symmetric(vertical: 70.0, horizontal: 30.0),
        child: Column(
          children: [
            const Center(
              child: Text(
                "Profile",
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Color.fromARGB(255, 78, 173, 162),
                ),
              ),
            ),
            const SizedBox(height: 5),
            Card(
              color: Color.fromARGB(255, 233, 233, 233),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 30.0, vertical: 50.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Stack(
                      alignment: Alignment.center,
                      children: [
                        SizedBox(
                          width: 150,
                          height: 150,
                          child: ClipOval(
                            child: _profileImageUrl == null || _profileImageUrl!.isEmpty
                                ? const Image(
                                    image: AssetImage('assets/images/profile.png'),
                                    fit: BoxFit.cover,
                                  )
                                : CachedNetworkImage(
                                    imageUrl: _profileImageUrl!,
                                    fit: BoxFit.cover,
                                    errorWidget: (context, error, stackTrace) => const Image(
                                      image: AssetImage('assets/images/profile.png'),
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                          ),
                        ),
                        Positioned(
                          right: 6,
                          bottom: 6,
                          child: GestureDetector(
                            onTap: _uploading ? null : _changeProfileImage,
                            child: Container(
                              width: 34,
                              height: 34,
                              decoration: BoxDecoration(
                                color: Colors.black87,
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.white, width: 2),
                                boxShadow: const [
                                  BoxShadow(
                                    color: Color.fromARGB(60, 0, 0, 0),
                                    blurRadius: 6,
                                    offset: Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: _uploading
                                  ? const Padding(
                                      padding: EdgeInsets.all(8.0),
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                      ),
                                    )
                                  : const Icon(Icons.photo_camera, color: Colors.white, size: 18),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    _isLoading
                        ? const CircularProgressIndicator()
                        : Text(
                            _userEmail ?? 'Email not available',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w500,
                              color: Colors.black87,
                            ),
                          ),
                    const SizedBox(height: 70),
                    // Logout Button
                    ElevatedButton(
                      onPressed: _logout,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.teal.shade400,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 35,
                          vertical: 12,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        minimumSize: const Size(double.infinity, 36),
                      ),
                      child: const Text(
                        'Logout',
                        style: TextStyle(fontSize: 16),
                      ),
                    ),
                    const SizedBox(height: 25),
                    // Delete Account Button
                    ElevatedButton(
                      onPressed: _deleteAccount,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red.shade600,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 35,
                          vertical: 12,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        minimumSize: const Size(double.infinity, 36),
                      ),
                      child: const Text(
                        'Delete Account',
                        style: TextStyle(fontSize: 16),
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
