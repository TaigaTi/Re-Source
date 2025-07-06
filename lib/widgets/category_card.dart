import 'package:flutter/material.dart';
import 'package:re_source/pages/category.dart';

class CategoryCard extends StatelessWidget {
  final Map<String, dynamic> category;
  const CategoryCard({super.key, required this.category});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      dense: true,
      tileColor: category['color'] as Color,
      title: Text(
        category['name'] as String,
        style: const TextStyle(color: Colors.white, fontSize: 16),
        textAlign: TextAlign.center,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      onTap: () {
        Navigator.push(
          context,
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) => Category(
              name: category['name'] as String,
              color: category['color'] as Color,
              id: category['id'] as String,
            ),
            transitionDuration: Duration.zero,
            reverseTransitionDuration: Duration.zero,
          ),
        );
      },
    );
  }
}
