import 'package:flutter/material.dart';
import 'package:re_source/pages/edit_resource.dart';
import 'package:re_source/pages/login.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:re_source/widgets/back_title.dart';
import 'package:re_source/widgets/custom_appbar.dart';
import 'package:re_source/widgets/custom_drawer.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:re_source/pages/in_app_webview.dart';

class ResourceDetails extends StatelessWidget {
  final String resourceId;
  final String title;
  final String description;
  final String? image;
  final String? storagePath;
  final String link;
  final String categoryId;
  final String categoryName;
  final Color categoryColor;

  const ResourceDetails({
    super.key,
    required this.resourceId,
    required this.title,
    required this.description,
    required this.link,
    this.image,
    required this.categoryId,
    required this.categoryName,
    required this.categoryColor,
    this.storagePath,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final isLight = cs.brightness == Brightness.light;
    final cardColor = isLight ? cs.surfaceVariant : cs.surface;

    return Scaffold(
      appBar: const CustomAppBar(),
      drawer: const CustomDrawer(),
      backgroundColor: cs.background,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(
              vertical: 20.0,
              horizontal: 30.0,
            ),
            child: Column(
              children: [
                BackTitle(title: title),
                const SizedBox(height: 30),
                Card(
                  color: cardColor,
                  child: Padding(
                    padding: const EdgeInsets.all(30.0),
                    child: Column(
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Padding(
                              padding: const EdgeInsets.only(
                                right: 5.0,
                                top: 5,
                              ),
                              child: Container(
                                width: 9,
                                height: 9,
                                decoration: BoxDecoration(
                                  color: categoryColor,
                                  shape: BoxShape.circle,
                                ),
                              ),
                            ),
                            // Category name text
                            Flexible(
                              child: Text(
                                categoryName,
                                maxLines: 1,
                                textAlign: TextAlign.center,
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                          ],
                        ),
                        SizedBox(height: 10),
                        Container(
                          decoration: const BoxDecoration(
                            borderRadius: BorderRadius.all(Radius.circular(10)),
                          ),
                          clipBehavior: Clip.antiAlias,
                          child:
                              (image != null &&
                                  image!.isNotEmpty &&
                                  !image!.startsWith('/'))
                              ? Image.network(
                                  image!,
                                  width: double.infinity,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) =>
                                      Image.asset(
                                        "assets/images/success.png",
                                        fit: BoxFit.cover,
                                      ),
                                )
                              : Image.asset(
                                  "assets/images/success.png",
                                  width: double.infinity,
                                  fit: BoxFit.cover,
                                ),
                        ),
                        const SizedBox(height: 15),
                        Text(description, style: theme.textTheme.bodyMedium),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 25),
                FilledButton.icon(
                  onPressed: () async {
                    if (link.isEmpty) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'No link provided for this resource.',
                            ),
                          ),
                        );
                      }
                      return;
                    }

                    // Prepare the URL. Ensure it has a scheme; prefer https when missing.
                    String processed = link.trim();
                    if (!RegExp(
                      r'^[a-zA-Z][a-zA-Z0-9+.-]*://',
                    ).hasMatch(processed)) {
                      processed = 'https://$processed';
                    }

                    // Try several parsing/launch strategies to handle spaces, tokens, or odd characters.
                    Uri? uri;
                    try {
                      uri = Uri.parse(processed);
                      if (!uri.hasScheme) {
                        uri = Uri.parse('https://$processed');
                      }
                    } catch (_) {
                      // Last resort: percent-encode the full string and try again
                      try {
                        uri = Uri.tryParse(Uri.encodeFull(processed));
                      } catch (_) {
                        uri = null;
                      }
                    }

                    if (uri == null) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Invalid URL: $link')),
                        );
                      }
                      return;
                    }

                    try {
                      // Primary attempt
                      if (await canLaunchUrl(uri)) {
                        final didLaunch = await launchUrl(
                          uri,
                          mode: LaunchMode.externalApplication,
                        );
                        if (didLaunch) return;
                      }

                      // Fallback: encoded full-string URI
                      final Uri? encodedUri = Uri.tryParse(
                        Uri.encodeFull(processed),
                      );
                      if (encodedUri != null &&
                          await canLaunchUrl(encodedUri)) {
                        final didLaunch = await launchUrl(
                          encodedUri,
                          mode: LaunchMode.externalApplication,
                        );
                        if (didLaunch) return;
                      }

                      // If still not launched, open an in-app webview as a fallback
                      if (context.mounted) {
                        final Uri fallbackUri = encodedUri ?? uri;
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => InAppWebViewPage(
                              uri: fallbackUri,
                              title: title,
                            ),
                          ),
                        );
                      }
                    } catch (e, s) {
                      FirebaseCrashlytics.instance.recordError(
                        e,
                        s,
                        reason: 'Failed to launch resource link',
                        fatal: false,
                      );
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Could not open link: $e')),
                        );
                      }
                    }
                  },
                  icon: Icon(Icons.link, color: cs.onPrimary),
                  label: Text(
                    "Visit Resource",
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: cs.onPrimary,
                    ),
                  ),
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
                ),
                const SizedBox(height: 15),
                FilledButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      PageRouteBuilder(
                        pageBuilder: (context, animation, secondaryAnimation) =>
                            EditResource(
                              resourceId: resourceId,
                              link: link,
                              title: title,
                              description: description,
                              category: categoryName,
                              image: image, // Pass image from Firestore
                              existingResource: true,
                            ),
                        transitionDuration: Duration.zero,
                        reverseTransitionDuration: Duration.zero,
                      ),
                    );
                  },
                  icon: Icon(Icons.edit, color: cs.onSurfaceVariant),
                  label: Text(
                    "Edit Resource",
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: cs.onSurfaceVariant,
                    ),
                  ),
                  style: ButtonStyle(
                    minimumSize: WidgetStateProperty.all(
                      const Size(double.infinity, 45),
                    ),
                    shape: WidgetStateProperty.all(
                      RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    backgroundColor: WidgetStateProperty.all(cardColor),
                  ),
                ),
                const SizedBox(height: 15),
                FilledButton.icon(
                  onPressed: () async {
                    final confirm = await showDialog<bool>(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('Delete Resource'),
                        content: const Text(
                          'Are you sure you want to delete this resource? This action cannot be undone.',
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.of(context).pop(false),
                            child: const Text('Cancel'),
                          ),
                          TextButton(
                            onPressed: () => Navigator.of(context).pop(true),
                            child: const Text(
                              'Delete',
                              style: TextStyle(color: Colors.red),
                            ),
                          ),
                        ],
                      ),
                    );

                    if (confirm != true) return;

                    try {
                      final user = FirebaseAuth.instance.currentUser;
                      if (user == null) {
                        if (context.mounted) {
                          Navigator.of(context).pushReplacement(
                            MaterialPageRoute(builder: (_) => const Login()),
                          );
                        }
                        return;
                      }

                      if (categoryId.isEmpty) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Category ID missing; cannot delete resource.',
                              ),
                            ),
                          );
                        }
                        return;
                      }

                      // Attempt to delete associated image from Firebase Storage.
                      try {
                        // Prefer deleting by stored storage path if available (more reliable)
                        if (storagePath != null && storagePath!.isNotEmpty) {
                          await FirebaseStorage.instance
                              .ref()
                              .child(storagePath!)
                              .delete();
                        } else if (image != null &&
                            image!.isNotEmpty &&
                            image!.contains('firebasestorage.googleapis.com')) {
                          // Fallback: try to derive ref from download URL
                          final storageRef = FirebaseStorage.instance
                              .refFromURL(image!);
                          await storageRef.delete();
                        }
                      } catch (e, s) {
                        // Log but continue with deleting the firestore document
                        FirebaseCrashlytics.instance.recordError(
                          e,
                          s,
                          reason:
                              'Failed to delete resource image from storage',
                          fatal: false,
                        );
                      }

                      await FirebaseFirestore.instance
                          .collection('users')
                          .doc(user.uid)
                          .collection('categories')
                          .doc(categoryId)
                          .collection('resources')
                          .doc(resourceId)
                          .delete();

                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Resource deleted.')),
                        );
                        Navigator.of(context).pop(true);
                      }
                    } catch (e, s) {
                      FirebaseCrashlytics.instance.recordError(
                        e,
                        s,
                        reason: 'Failed to delete resource',
                      );
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Failed to delete resource: $e'),
                          ),
                        );
                      }
                    }
                  },
                  icon: Icon(Icons.delete, color: cs.onError),
                  label: Text(
                    'Delete Resource',
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: cs.onError,
                    ),
                  ),
                  style: ButtonStyle(
                    minimumSize: WidgetStateProperty.all(
                      const Size(double.infinity, 45),
                    ),
                    shape: WidgetStateProperty.all(
                      RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    backgroundColor: WidgetStateProperty.all(cs.error),
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
