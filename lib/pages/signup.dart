import 'package:flutter/material.dart';
import 'package:re_source/pages/home.dart';
import 'package:re_source/pages/login.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class SignUp extends StatefulWidget {
  const SignUp({super.key});

  @override
  State<SignUp> createState() => _SignUpState();
}

class _SignUpState extends State<SignUp> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();
  String? _errorMessage;
  bool _isLoading = false;

  bool _isValidEmail(String email) {
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    return emailRegex.hasMatch(email);
  }

  Future<void> addUser(String uid, String email) async {
    final FirebaseFirestore database = FirebaseFirestore.instance;
    try {
      await database.collection('users').doc(uid).set({
        'email': email,
      });
    } catch (e, stack) {
      await FirebaseCrashlytics.instance.recordError(e, stack, reason: 'Error adding user to Firestore');
      rethrow;
    }
  }

  Future<void> signUpWithEmailAndPassword(String email, String password) async {
    try {
      UserCredential userCredential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      if (userCredential.user != null) {
        await addUser(userCredential.user!.uid, email);
      }
      if (mounted) {
        Navigator.pushReplacement(
          context,
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) => const Home(),
            transitionDuration: Duration.zero,
            reverseTransitionDuration: Duration.zero,
          ),
        );
      }
    } on FirebaseAuthException catch (e, stack) {
      await FirebaseCrashlytics.instance.recordError(
        e,
        stack,
        reason: e.message,
      );
      setState(() {
        _errorMessage = e.message;
        _isLoading = false;
      });
    } catch (e, stack) {
      await FirebaseCrashlytics.instance.recordError(
        e,
        stack,
        reason: 'Error during sign up',
      );
      setState(() {
        _errorMessage = "An error occurred. Please try again.";
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Container(
            padding: EdgeInsets.symmetric(vertical: 55, horizontal: 30),
            child: Column(
              children: [
                Center(
                  child: Text(
                    "Sign Up",
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                ),
                SizedBox(height: 8),
                Card(
                  color: isDark
                      ? theme.colorScheme.surfaceContainerHighest
                      : const Color.fromARGB(255, 233, 233, 233),
                  child: SizedBox(
                    width: double.infinity,
                    child: Container(
                      padding: EdgeInsets.all(35),
                      child: Column(
                        children: [
                          Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.all(
                                Radius.circular(50),
                              ),
                            ),
                            clipBehavior: Clip.antiAlias,
                            child: Image(
                              image: AssetImage(
                                "assets/images/logo-vertical.png",
                              ),
                              width: 200,
                            ),
                          ),
                          SizedBox(height: 20),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.start,
                            children: [
                              Text(
                                "Email",
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                  color: theme.colorScheme.onSurface,
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 10),
                          TextField(
                            controller: _emailController,
                            decoration: InputDecoration(
                              filled: true,
                              fillColor: isDark
                                  ? theme.colorScheme.surfaceContainer
                                  : Colors.white,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: BorderSide.none,
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: BorderSide.none,
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: BorderSide.none,
                              ),
                              hintText: 'Email',
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 12,
                              ),
                            ),
                            keyboardType: TextInputType.emailAddress,
                          ),
                          SizedBox(height: 20),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.start,
                            children: [
                              Text(
                                "Password",
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                  color: theme.colorScheme.onSurface,
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 10),
                          TextField(
                            controller: _passwordController,
                            decoration: InputDecoration(
                              filled: true,
                              fillColor: isDark
                                  ? theme.colorScheme.surfaceContainer
                                  : Colors.white,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: BorderSide.none,
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: BorderSide.none,
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: BorderSide.none,
                              ),
                              hintText: 'Password',
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 12,
                              ),
                            ),
                            obscureText: true,
                            keyboardType: TextInputType.text,
                          ),
                          SizedBox(height: 20),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.start,
                            children: [
                              Text(
                                "Confirm Password",
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                  color: theme.colorScheme.onSurface,
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 10),
                          TextField(
                            controller: _confirmPasswordController,
                            decoration: InputDecoration(
                              filled: true,
                              fillColor: isDark
                                  ? theme.colorScheme.surfaceContainer
                                  : Colors.white,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: BorderSide.none,
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: BorderSide.none,
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: BorderSide.none,
                              ),
                              hintText: 'Confirm Password',
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 12,
                              ),
                            ),
                            obscureText: true,
                            keyboardType: TextInputType.text,
                          ),
                          if (_errorMessage != null) ...[
                            SizedBox(height: 16),
                            Text(
                              _errorMessage!,
                              style: TextStyle(color: Colors.red),
                            ),
                          ],
                          SizedBox(height: 25),
                          FilledButton(
                            onPressed: _isLoading ? null : () async {
                              setState(() {
                                _errorMessage = null;
                                _isLoading = true;
                              });

                              final email = _emailController.text.trim();
                              final password = _passwordController.text.trim();
                              final confirmPassword = _confirmPasswordController.text.trim();

                              if (email.isEmpty || password.isEmpty || confirmPassword.isEmpty) {
                                setState(() {
                                  _errorMessage = "Please fill in all fields.";
                                  _isLoading = false;
                                });
                                return;
                              }

                              if (!_isValidEmail(email)) {
                                setState(() {
                                  _errorMessage = "Please enter a valid email address.";
                                  _isLoading = false;
                                });
                                return;
                              }

                              if (password.length < 6) {
                                setState(() {
                                  _errorMessage = "Password must be at least 6 characters.";
                                  _isLoading = false;
                                });
                                return;
                              }

                              if (password != confirmPassword) {
                                setState(() {
                                  _errorMessage = "Passwords do not match.";
                                  _isLoading = false;
                                });
                                return;
                              }

                              await signUpWithEmailAndPassword(email, password);
                            },
                            style: ButtonStyle(
                              minimumSize: WidgetStateProperty.all(
                                Size(double.infinity, 45),
                              ),
                              shape: WidgetStateProperty.all(
                                RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                              backgroundColor: WidgetStateProperty.all(
                                theme.colorScheme.primary,
                              ),
                            ),
                            child: _isLoading
                                ? SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        theme.colorScheme.onPrimary,
                                      ),
                                    ),
                                  )
                                : Text(
                                    "Sign Up",
                                    style: TextStyle(fontSize: 16),
                                  ),
                          ),
                          Center(
                            child: TextButton(
                              style: ButtonStyle(
                                overlayColor: WidgetStateProperty.all(
                                  Colors.transparent,
                                ),
                              ),
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  PageRouteBuilder(
                                    pageBuilder:
                                        (
                                          context,
                                          animation,
                                          secondaryAnimation,
                                        ) => const Login(),
                                    transitionDuration: Duration.zero,
                                    reverseTransitionDuration: Duration.zero,
                                  ),
                                );
                              },
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    "Already have an account? ",
                                    style: TextStyle(
                                      color: theme.colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                                  Text(
                                    "Log In!",
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: theme.colorScheme.primary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
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
