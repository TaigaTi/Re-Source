import 'package:flutter/material.dart';
// Removed profile and menu imports; using theme toggle instead
// no extra imports needed
import 'package:re_source/app.dart';

class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  const CustomAppBar({super.key});

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: const Image(
        image: AssetImage("assets/images/logo-horizontal.png"),
        width: 60,
      ),
      backgroundColor: Theme.of(context).colorScheme.surface,
      automaticallyImplyLeading: false,
      actions: [
        IconButton(
          tooltip: 'Toggle theme',
          icon: ValueListenableBuilder<ThemeMode>(
            valueListenable: appThemeMode,
            builder: (context, mode, _) {
              final isDark = mode == ThemeMode.dark;
              return Icon(
                isDark ? Icons.dark_mode : Icons.light_mode,
                color: Theme.of(context).colorScheme.onSurface,
              );
            },
          ),
          onPressed: () {
            final isDark = appThemeMode.value == ThemeMode.dark;
            appThemeMode.value = isDark ? ThemeMode.light : ThemeMode.dark;
          },
        ),
      ],
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}

// Removed profile avatar and menu. Replaced with theme toggle.
