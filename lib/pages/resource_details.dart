import 'package:flutter/material.dart';
import 'package:re_source/widgets/back_title.dart';
import 'package:re_source/widgets/custom_appbar.dart';
import 'package:re_source/widgets/custom_drawer.dart';

class ResourceDetails extends StatelessWidget {
  final String resourceId;
  final String title;
  final String description;
  final String? image;
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
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(),
      drawer: const CustomDrawer(),
      backgroundColor: Colors.white,
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
                  color: const Color.fromARGB(255, 233, 233, 233),
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
                                style: const TextStyle(
                                  fontWeight: FontWeight.w400,
                                  color: Colors.black,
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
                          child: (image != null && image!.isNotEmpty && !image!.startsWith('/'))
                              ? Image.network(
                                  image!,
                                  width: double.infinity,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) =>
                                      Image.asset("assets/images/success.png", fit: BoxFit.cover),
                                )
                              : Image.asset(
                                  "assets/images/success.png",
                                  width: double.infinity,
                                  fit: BoxFit.cover,
                                ),
                        ),
                        const SizedBox(height: 15),

                        Text(description, style: const TextStyle(fontSize: 15)),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 25),
                FilledButton.icon(
                  onPressed: () {
                    if (link.isNotEmpty) {
                      // Open the link using url_launcher or similar
                      // launchUrl(Uri.parse(link));
                    }
                  },
                  icon: const Icon(Icons.link),
                  label: Text(
                    "Visit $title",
                    style: const TextStyle(fontSize: 16),
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
                    backgroundColor: WidgetStateProperty.all(
                      const Color.fromARGB(255, 87, 175, 161),
                    ),
                  ),
                ),
                const SizedBox(height: 15),
                FilledButton.icon(
                  onPressed: () {
                    // Implement edit resource functionality
                  },
                  icon: const Icon(
                    Icons.edit,
                    color: Color.fromARGB(255, 110, 110, 110),
                  ),
                  label: const Text(
                    "Edit Resource",
                    style: TextStyle(
                      fontSize: 16,
                      color: Color.fromARGB(255, 110, 110, 110),
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
                    backgroundColor: WidgetStateProperty.all(
                      const Color.fromARGB(255, 233, 233, 233),
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
