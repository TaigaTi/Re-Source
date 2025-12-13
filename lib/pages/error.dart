import 'package:flutter/material.dart';
import 'package:re_source/pages/home.dart';
import 'package:re_source/pages/new_resource.dart';
import 'package:re_source/widgets/custom_appbar.dart';
import 'package:re_source/widgets/custom_drawer.dart';

class ErrorPage extends StatelessWidget {
  const ErrorPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: CustomAppBar(),
      drawer: CustomDrawer(),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 35.0,
              vertical: 75.0,
            ),
            child: Column(
              children: [
                Card(
                  color: isDark
                      ? theme.colorScheme.surfaceContainerHighest
                      : const Color.fromARGB(255, 233, 233, 233),
                  elevation: 2.0,
                  child: Padding(
                    padding: const EdgeInsets.all(30.0),
                    child: Column(
                      spacing: 15,
                      children: [
                        Center(
                          child: Text(
                            "Error!",
                            style: TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                              color: const Color.fromARGB(255, 207, 0, 0),
                            ),
                          ),
                        ),
                        Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(20),
                            color: Color.fromARGB(255, 255, 252, 241),
                          ),
                          clipBehavior: Clip.antiAlias,
                          child: Image(
                            height: 275,
                            image: AssetImage("assets/images/error.png"),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            vertical: 0,
                            horizontal: 50.0,
                          ),
                          child: Center(
                            child: Text(
                              "Something went wrong while processing your request. Please try again or contact support if the problem persists.",
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontWeight: FontWeight.w400,
                                fontSize: 16,
                                color: theme.colorScheme.onSurface,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 20),
                  child: FilledButton(
                    onPressed: () => {
                      Navigator.pushAndRemoveUntil(
                        context,
                        PageRouteBuilder(
                          pageBuilder:
                              (context, animation, secondaryAnimation) =>
                                  const NewResource(),
                          transitionDuration: Duration.zero,
                          reverseTransitionDuration: Duration.zero,
                        ),
                        (route) => false,
                      ),
                    },
                    style: ButtonStyle(
                      backgroundColor: WidgetStateProperty.all(
                        theme.colorScheme.primary,
                      ),
                      minimumSize: WidgetStateProperty.all(
                        const Size(double.infinity, 40),
                      ),
                      shape: WidgetStateProperty.all(
                        RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                    child: const Text(
                      "Try Again",
                      style: TextStyle(fontSize: 16),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 10),
                  child: FilledButton(
                    onPressed: () => {
                      Navigator.pushAndRemoveUntil(
                        context,
                        PageRouteBuilder(
                          pageBuilder:
                              (context, animation, secondaryAnimation) =>
                                  const Home(),
                          transitionDuration: Duration.zero,
                          reverseTransitionDuration: Duration.zero,
                        ),
                        (route) => false,
                      ),
                    },
                    style: ButtonStyle(
                      backgroundColor: WidgetStateProperty.all(
                        isDark
                            ? theme.colorScheme.surfaceContainerHighest
                            : const Color.fromARGB(255, 233, 233, 233),
                      ),
                      minimumSize: WidgetStateProperty.all(
                        const Size(double.infinity, 40),
                      ),
                      shape: WidgetStateProperty.all(
                        RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                    child: Text(
                      "Return Home",
                      style: TextStyle(fontSize: 16, color: theme.colorScheme.onSurfaceVariant),
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
