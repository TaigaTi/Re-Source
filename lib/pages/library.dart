import 'package:flutter/material.dart';
import 'package:re_source/pages/new_resource.dart';
import 'package:re_source/widgets/custom_appbar.dart';
import 'package:re_source/widgets/custom_drawer.dart';

final List<Map<String, dynamic>> categories = const [
  {"title": "Technology", "color": Color.fromARGB(255, 153, 117, 210)},
  {"title": "UIUX", "color": Color.fromARGB(255, 219, 135, 141)},
  {"title": "Design", "color": Color.fromARGB(255, 133, 178, 130)},
  {"title": "Web Development", "color": Color.fromARGB(255, 216, 141, 117)},
  {"title": "Piano", "color": Color.fromARGB(255, 122, 139, 229)},
  {"title": "Art & Design", "color": Color.fromARGB(255, 213, 104, 215)},
];

class Library extends StatelessWidget {
  const Library({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: CustomAppBar(),
      drawer: CustomDrawer(),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(30, 20, 30, 50),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      "Library",
                      style: TextStyle(
                        fontSize: 20.0,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 10),
                SearchBar(
                  onChanged: (value) {},
                  hintText: "Looking for something?",
                  leading: const Icon(Icons.search),
                  shape: WidgetStateProperty.all(
                    RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(50.0),
                      side: const BorderSide(
                        color: Color.fromRGBO(233, 233, 233, 1.0),
                      ),
                    ),
                  ),
                  backgroundColor: WidgetStateProperty.all(
                    const Color.fromRGBO(233, 233, 233, 1.0),
                  ),
                  padding: WidgetStateProperty.all(
                    const EdgeInsets.symmetric(horizontal: 15.0, vertical: 8.0),
                  ),
                  elevation: WidgetStateProperty.all(0),
                ),
                SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  height: 550,
                  child: ListView.builder(
                    itemCount: categories.length,
                    itemBuilder: (context, index) {
                      final category = categories[index];
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 0.0),
                        child: ListTile(
                          dense: true,
                          tileColor: category['color'],
                          title: Text(
                            category['title'],
                            style: TextStyle(color: Colors.white, fontSize: 16),
                            textAlign: TextAlign.center,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)
                          ),
                        ),
                      );
                    },
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 20),
                  child: FilledButton(
                    onPressed: () => {
                      Navigator.push(
                        context,
                        PageRouteBuilder(
                          pageBuilder:
                              (context, animation, secondaryAnimation) =>
                                  const NewResource(),
                          transitionDuration: Duration.zero,
                          reverseTransitionDuration: Duration.zero,
                        ),
                      ),
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
                        const Color.fromARGB(255, 87, 175, 161),
                      ),
                    ),
                    child: const Text(
                      "Add Resource",
                      style: TextStyle(fontSize: 16),
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
