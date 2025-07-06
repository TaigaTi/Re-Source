import 'package:flutter/material.dart';

class ResourceCard extends StatelessWidget {
  final String id;
  final String title;
  final String link;
  final String? description;
  final String? categoryId;
  final String? categoryName;
  final Color? categoryColor;
  final Color? textColor;
  const ResourceCard({
    super.key,
    required this.id,
    required this.title,
    required this.link,
    required this.description,
    this.categoryId,
    this.categoryName,
    this.categoryColor,
    this.textColor
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: categoryColor,
      child: SizedBox(
        width: double.infinity, 
        child: Container(
          padding: EdgeInsets.all(15),
          child: Column(
            spacing: 10,
            children: [
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.all(Radius.circular(10)),
                ),
                clipBehavior: Clip.antiAlias,
                child: Image(
                  image: AssetImage("assets/images/success.png"),
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
              ),
              Center(
                child: Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: textColor ?? Colors.white,
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
