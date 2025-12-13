import 'package:flutter/material.dart';

class SkeletonCard extends StatelessWidget {
  final double height;
  final double width;
  const SkeletonCard({
    super.key,
    this.height = 220,
    this.width = double.infinity,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final isLight = cs.brightness == Brightness.light;
    final cardColor = theme.cardTheme.color ?? cs.surface;
    final blockColor = isLight ? cs.surfaceContainerHigh : cs.surfaceContainer;
    return Card(
      color: cardColor,
      child: SizedBox(
        width: width,
        child: Container(
          padding: const EdgeInsets.all(15),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: double.infinity,
                height: 120,
                decoration: BoxDecoration(
                  color: blockColor,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Center(
                  child: SizedBox(
                    width: 32,
                    height: 32,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Container(
                width: double.infinity,
                height: 18,
                decoration: BoxDecoration(
                  color: blockColor,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const SizedBox(height: 8),
              Container(
                width: 80,
                height: 14,
                decoration: BoxDecoration(
                  color: blockColor,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
