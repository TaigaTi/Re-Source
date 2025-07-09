import 'package:flutter/material.dart';
import 'package:re_source/widgets/back_title.dart';
import 'package:re_source/widgets/custom_appbar.dart';
import 'package:re_source/widgets/custom_drawer.dart';

class ResourceDetails extends StatelessWidget {
  const ResourceDetails({super.key});

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
                BackTitle(title: "Resource Name"),
                SizedBox(height: 30),
                Card(
                  color: Color.fromARGB(255, 233, 233, 233),
                  child: Padding(
                    padding: const EdgeInsets.all(30.0),
                    child: Column(
                      spacing: 15,
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
                                  color: Colors.blue,
                                  shape: BoxShape.circle,
                                ),
                              ),
                            ),
                            // Title text
                            Flexible(
                              child: Text(
                                "Category",
                                maxLines: 1,
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontWeight: FontWeight.w400,
                                  color: Colors.black,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ),
                            SizedBox(width: 8),
                          ],
                        ),
                        Container(
                          decoration: const BoxDecoration(
                            borderRadius: BorderRadius.all(Radius.circular(10)),
                          ),
                          clipBehavior: Clip.antiAlias,
                          child: Image(
                            image: AssetImage("assets/images/success.png"),
                            width: double.infinity,
                            fit: BoxFit.cover,
                          ),
                        ),
                        Column(
                          spacing: 5,
                          children: [
                            Text(
                              "Lorem ipsum dolor something or the other idk what it is tbh but we push. If you've read all of this, you're so cool, I hope you have a great day!",
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                SizedBox(height: 25),
                FilledButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.link),
                  label: const Text(
                    "Visit Resource Name",
                    style: TextStyle(fontSize: 16),
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
                SizedBox(height: 15),
                FilledButton.icon(
                  onPressed: () {},
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
