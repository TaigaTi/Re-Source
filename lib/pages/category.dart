import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:re_source/pages/new_resource.dart';
import 'package:re_source/widgets/back_title.dart';
import 'package:re_source/widgets/custom_appbar.dart';
import 'package:re_source/widgets/custom_drawer.dart';
import 'package:re_source/widgets/resource_card.dart';

const resourceCards = [
  ResourceCard(height: 120),
  ResourceCard(height: 170),
  ResourceCard(height: 140),
  ResourceCard(height: 130),
  ResourceCard(height: 100),
  ResourceCard(height: 120),
];

class Category extends StatelessWidget {
  const Category({super.key});

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
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                BackTitle(title: "Category Name"),
                const SizedBox(height: 12),
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
                const SizedBox(height: 15),
                SizedBox(
                  width: double.infinity,
                  height: 550,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: MasonryGridView.count(
                          crossAxisCount: 2,
                          crossAxisSpacing: 10,
                          mainAxisSpacing: 10,
                          itemCount: resourceCards.length,
                          itemBuilder: (context, index) => resourceCards[index],
                        ),
                      ),
                    ],
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
