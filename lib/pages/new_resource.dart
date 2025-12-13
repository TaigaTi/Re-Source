import 'package:flutter/material.dart';
import 'package:re_source/pages/edit_resource.dart'; // Make sure this path is correct
import 'package:re_source/widgets/back_title.dart';
import 'package:re_source/widgets/custom_appbar.dart';
import 'package:re_source/widgets/custom_drawer.dart';

class NewResource extends StatefulWidget {
  const NewResource({super.key});

  @override
  State<NewResource> createState() => _NewResourceState();
}

class _NewResourceState extends State<NewResource> {
  late TextEditingController _linkInputController;

  @override
  void initState() {
    super.initState();
    _linkInputController = TextEditingController();
  }

  @override
  void dispose() {
    _linkInputController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: CustomAppBar(),
      drawer: CustomDrawer(),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Container(
            padding: const EdgeInsets.all(30),
            child: Column(
              children: [
                const BackTitle(title: "Add Resource"),
                const SizedBox(height: 15),
                Card(
                  color: isDark
                      ? theme.colorScheme.surfaceContainerHighest
                      : theme.colorScheme.surface,
                  child: SizedBox(
                    width: double.infinity,
                    child: Container(
                      padding: const EdgeInsets.all(35),
                      child: Column(
                        crossAxisAlignment:
                            CrossAxisAlignment.start, 
                        children: [
                          Container(
                            decoration: const BoxDecoration(
                              borderRadius: BorderRadius.all(
                                Radius.circular(10),
                              ),
                            ),
                            clipBehavior: Clip.antiAlias,
                            child: Image(
                              image: const AssetImage(
                                "assets/images/resource-holding.png",
                              ),
                              width: double.infinity,
                              fit: BoxFit
                                  .cover, 
                            ),
                          ),
                          const SizedBox(height: 20),
                          const Text(
                            "Resource Link",
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 10),
                          TextField(
                            controller:
                                _linkInputController,
                            decoration: InputDecoration(
                              filled: true,
                              fillColor: isDark
                                  ? theme.colorScheme.surfaceContainer
                                  : Colors.white,
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
                              hintText: 'Paste Resource Link',
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 12,
                              ),
                            ),
                            keyboardType: TextInputType
                                .url, 
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 40),
                FilledButton(
                  onPressed: () {
                    final String? link =
                        _linkInputController.text.trim().isEmpty
                        ? null
                        : _linkInputController.text.trim();

                    if (link == null || link.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Please enter a resource link.'),
                        ),
                      );
                      return;
                    }

                    Navigator.push(
                      context,
                      PageRouteBuilder(
                        pageBuilder: (context, animation, secondaryAnimation) =>
                            EditResource(link: link, existingResource: false,),
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
                      theme.colorScheme.primary,
                    ),
                  ),
                  child: const Text("Next", style: TextStyle(fontSize: 16)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
