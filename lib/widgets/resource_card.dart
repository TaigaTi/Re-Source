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
  final Color? backgroundColor;
  final bool indicator; // Controls the visibility of the circle indicator

  const ResourceCard({
    super.key,
    required this.id,
    required this.title,
    required this.link,
    required this.description,
    this.categoryId,
    this.categoryName,
    this.categoryColor,
    this.textColor,
    this.backgroundColor,
    required this.indicator,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: backgroundColor ?? categoryColor,
      child: SizedBox(
        width: double.infinity,
        child: Container(
          padding: const EdgeInsets.all(15),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
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
              const SizedBox(height: 10),

              Center(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Visibility(
                      visible: indicator,
                      child: Padding(
                        padding: const EdgeInsets.only(right: 5.0, top: 5),
                        child: Container(
                          width: 9,
                          height: 9,
                          decoration: BoxDecoration(
                            color: categoryColor,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                    ),
                    // Title text
                    Flexible(
                      child: Text(
                        "Five Roads Meet Under One Moon My Dear",
                        maxLines: 2,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: textColor ?? Colors.white,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                    SizedBox(width: 8),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
