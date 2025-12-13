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
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .get();
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
      final XFile? picked = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );
      if (picked == null) return;

      setState(() => _uploading = true);

      final file = File(picked.path);
      final storageRef = FirebaseStorage.instance.ref().child(
        'users/${user.uid}/profile.jpg',
      );
      final uploadTask = await storageRef.putFile(
        file,
        SettableMetadata(contentType: 'image/jpeg'),
      );
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
      await FirebaseCrashlytics.instance.recordError(
        e,
        s,
        reason: 'Failed to change profile image',
      );
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to upload image: $e')));
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
  bool _isChangingPassword = false;

  Future<void> _showChangePasswordDialog() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null || !mounted) return;

    final currentController = TextEditingController();
    final newController = TextEditingController();
    final confirmController = TextEditingController();
    String? errorText;

    bool? confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setState) {
            return AlertDialog(
              title: const Text('Change Password'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    TextField(
                      controller: currentController,
                      obscureText: true,
                      decoration: const InputDecoration(
                        labelText: 'Current Password',
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: newController,
                      obscureText: true,
                      decoration: const InputDecoration(
                        labelText: 'New Password',
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: confirmController,
                      obscureText: true,
                      decoration: const InputDecoration(
                        labelText: 'Confirm New Password',
                      ),
                    ),
                    if (errorText != null) ...[
                      const SizedBox(height: 10),
                      Text(
                        errorText!,
                        style: const TextStyle(color: Colors.red),
                      ),
                    ],
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: _isChangingPassword
                      ? null
                      : () => Navigator.of(ctx).pop(false),
                  child: const Text('Cancel'),
                ),
                _isChangingPassword
                    ? const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 16),
                        child: SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      )
                    : TextButton(
                        onPressed: () async {
                          final current = currentController.text.trim();
                          final next = newController.text.trim();
                          final confirm = confirmController.text.trim();

                          if (current.isEmpty ||
                              next.isEmpty ||
                              confirm.isEmpty) {
                            setState(() {
                              errorText = 'Please fill in all fields.';
                            });
                            return;
                          }
                          if (next.length < 6) {
                            setState(() {
                              errorText =
                                  'New password must be at least 6 characters.';
                            });
                            return;
                          }
                          if (next != confirm) {
                            setState(() {
                              errorText = 'New passwords do not match.';
                            });
                            return;
                          }

                          setState(() => _isChangingPassword = true);
                          try {
                            final email = user.email;
                            if (email == null) {
                              throw FirebaseAuthException(
                                code: 'no-email',
                                message: 'User email not available.',
                              );
                            }

                            final credential = EmailAuthProvider.credential(
                              email: email,
                              password: current,
                            );
                            await user.reauthenticateWithCredential(credential);
                            await user.updatePassword(next);

                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'Password updated successfully.',
                                  ),
                                ),
                              );
                            }
                            // Close dialog
                            // ignore: use_build_context_synchronously
                            Navigator.of(ctx).pop(true);
                          } on FirebaseAuthException catch (e, s) {
                            FirebaseCrashlytics.instance.recordError(
                              e,
                              s,
                              reason: 'Change password failed',
                            );
                            String message = 'Failed to change password.';
                            if (e.code == 'wrong-password') {
                              message = 'Current password is incorrect.';
                            } else if (e.code == 'weak-password') {
                              message = 'New password is too weak.';
                            } else if (e.code == 'requires-recent-login') {
                              message = 'Please log in again and retry.';
                            }
                            setState(() {
                              errorText = message;
                              _isChangingPassword = false;
                            });
                          } catch (e, s) {
                            FirebaseCrashlytics.instance.recordError(
                              e,
                              s,
                              reason: 'Change password unexpected error',
                            );
                            setState(() {
                              errorText =
                                  'Unexpected error occurred. Please try again.';
                              _isChangingPassword = false;
                            });
                          }
                        },
                        child: const Text('Update'),
                      ),
              ],
            );
          },
        );
      },
    );

    if (confirmed != true) {
      setState(() => _isChangingPassword = false);
    }
  }

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
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(vertical: 30.0, horizontal: 30.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Text(
                  "Profile",
                  style:
                      Theme.of(context).textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.primary,
                      ) ??
                      TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                ),
              ),
              const SizedBox(height: 12),
              Card(
                color: Theme.of(context).brightness == Brightness.dark
                    ? Theme.of(context).colorScheme.surfaceContainerHighest
                    : Theme.of(context).colorScheme.surface,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24.0,
                    vertical: 24.0,
                  ),
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
                              child:
                                  _profileImageUrl == null ||
                                      _profileImageUrl!.isEmpty
                                  ? const Image(
                                      image: AssetImage(
                                        'assets/images/profile.png',
                                      ),
                                      fit: BoxFit.cover,
                                    )
                                  : CachedNetworkImage(
                                      imageUrl: _profileImageUrl!,
                                      fit: BoxFit.cover,
                                      placeholder: (context, url) =>
                                          const Image(
                                            image: AssetImage(
                                              'assets/images/profile.png',
                                            ),
                                            fit: BoxFit.cover,
                                          ),
                                      errorWidget:
                                          (context, error, stackTrace) =>
                                              const Image(
                                                image: AssetImage(
                                                  'assets/images/profile.png',
                                                ),
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
                                  color: Theme.of(context).colorScheme.primary,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.onPrimary,
                                    width: 2,
                                  ),
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
                                          valueColor:
                                              AlwaysStoppedAnimation<Color>(
                                                Colors.white,
                                              ),
                                        ),
                                      )
                                    : const Icon(
                                        Icons.photo_camera,
                                        color: Colors.white,
                                        size: 18,
                                      ),
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
                              style:
                                  Theme.of(
                                    context,
                                  ).textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.w500,
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.onSurface,
                                  ) ??
                                  const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w500,
                                  ),
                            ),
                      const SizedBox(height: 30),
                      // Change Password Button
                      ElevatedButton(
                        onPressed: _showChangePasswordDialog,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Theme.of(
                            context,
                          ).colorScheme.secondary,
                          foregroundColor: Theme.of(
                            context,
                          ).colorScheme.onSecondary,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 35,
                            vertical: 12,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: const Text(
                          'Change Password',
                          style: TextStyle(fontSize: 16),
                        ),
                      ),
                      const SizedBox(height: 16),
                      // Logout Button
                      ElevatedButton(
                        onPressed: _logout,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Theme.of(
                            context,
                          ).colorScheme.primary,
                          foregroundColor: Theme.of(
                            context,
                          ).colorScheme.onPrimary,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 35,
                            vertical: 12,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: const Text(
                          'Logout',
                          style: TextStyle(fontSize: 16),
                        ),
                      ),
                      const SizedBox(height: 16),
                      // Delete Account Button
                      ElevatedButton(
                        onPressed: _deleteAccount,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Theme.of(context).colorScheme.error,
                          foregroundColor: Theme.of(
                            context,
                          ).colorScheme.onError,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 35,
                            vertical: 12,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
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
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
