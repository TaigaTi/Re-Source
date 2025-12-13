import 'package:flutter/material.dart';
import 'package:re_source/pages/resource_details.dart';

class ResourceCard extends StatelessWidget {
  final String id;
  final String title;
  final String link;
  final String? image;
  final String? storagePath;
  final String? description;
  final String? categoryId;
  final String? categoryName;
  final Color? categoryColor;
  final Color? textColor;
  final Color? backgroundColor;
  final bool indicator;
  final Future<bool?> Function(BuildContext)? onOpen;

  const ResourceCard({
    super.key,
    required this.id,
    required this.title,
    required this.link,
    this.image,
    this.storagePath,
    required this.description,
    this.categoryId,
    this.categoryName,
    this.categoryColor,
    this.textColor,
    this.backgroundColor,
    required this.indicator,
    this.onOpen,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final defaultCardColor = theme.cardTheme.color ?? cs.surface;
    final defaultTextColor = theme.textTheme.bodyMedium?.color ?? cs.onSurface;
    return InkWell(
      onTap: () async {
        if (onOpen != null) {
          await onOpen!(context);
          return;
        }

        await Navigator.push(
          context,
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) =>
                ResourceDetails(
                  resourceId: id,
                  title: title,
                  description: description ?? '',
                  link: link as String? ?? '',
                  image: image,
                  storagePath: storagePath,
                  categoryId: categoryId ?? '',
                  categoryName: categoryName ?? '',
                  categoryColor:
                      categoryColor ?? Color.fromARGB(255, 233, 233, 233),
                ),

            transitionDuration: Duration.zero,
            reverseTransitionDuration: Duration.zero,
          ),
        );
      },
      child: Card(
        color: backgroundColor ?? categoryColor ?? defaultCardColor,
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
                          title,
                          maxLines: 2,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: textColor ?? defaultTextColor,
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
      ),
    );
  }
}
