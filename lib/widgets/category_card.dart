import 'package:flutter/material.dart';
import 'package:re_source/pages/category.dart';

class CategoryCard extends StatelessWidget {
  final Map<String, dynamic> category;
  final void Function(bool modified)? onReturn;

  const CategoryCard({super.key, required this.category, this.onReturn});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final isLight = cs.brightness == Brightness.light;
    final cardColor = isLight ? cs.surfaceContainerHighest : cs.surfaceContainerHigh;
    final textColor = theme.textTheme.bodyMedium?.color ?? cs.onSurface;
    final secondaryText = cs.onSurfaceVariant;

    final Color catColor = category['color'] as Color? ?? Colors.blue;
    final String name = category['name'] as String? ?? '';
    final String id = category['id'] as String? ?? '';

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () async {
          final result = await Navigator.push<bool?>(
            context,
            PageRouteBuilder(
              pageBuilder: (context, animation, secondaryAnimation) =>
                  Category(name: name, color: catColor, id: id),
              transitionDuration: Duration.zero,
              reverseTransitionDuration: Duration.zero,
            ),
          );
          if (result == true) {
            if (onReturn != null) onReturn!(true);
          }
        },
        child: Container(
          constraints: const BoxConstraints(minHeight: 84),
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(12),
            boxShadow: isLight
                ? null
                : [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
          ),
          child: Row(
            children: [
              // Color circle with subtle shadow and white inner ring
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: catColor,
                ),
                child: Center(
                  child: Container(
                    width: 30,
                    height: 30,
                    decoration: BoxDecoration(
                      color: Colors.white.withAlpha((0.15 * 255).round()),
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  name,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: textColor,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 12),
              Icon(Icons.chevron_right, color: secondaryText),
            ],
          ),
        ),
      ),
    );
  }
}
