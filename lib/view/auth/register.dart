import 'package:digifarmer/services/auth_service.dart';
import 'package:digifarmer/widgets/my_button.dart';
import 'package:digifarmer/widgets/my_text_field.dart';
import 'package:digifarmer/widgets/squre_tile.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class RegisterPage extends StatefulWidget {
  final VoidCallback onTap;
  const RegisterPage({super.key, required this.onTap});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  //text editing controllers
  final usernameController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmPasswordController = TextEditingController();

  // sign user in method
  void signUp() async {
    FocusScope.of(context).unfocus();
    showDialog(
      context: context,
      builder:
          (context) => Center(
            child: CircularProgressIndicator(color: Colors.blue[300]!),
          ),
    );

    try {
      if (passwordController.text == confirmPasswordController.text) {
        await AuthService().registerWithEmailAndPassword(
          usernameController.text,
          passwordController.text,
        );
        // If we get here, Firebase registration was successful
        Navigator.pop(context); // Dismiss progress indicator on success
      } else {
        Navigator.pop(context);
        wrongCredentialMessage('Passwords do not match');
        return;
      }
    } on FirebaseAuthException catch (e) {
      Navigator.pop(context);
      if (e.code == 'email-already-in-use') {
        wrongCredentialMessage('Email already in use');
      } else if (e.code == 'invalid-email') {
        wrongCredentialMessage('Invalid Email');
      } else if (e.code == 'weak-password') {
        wrongCredentialMessage('Password is too weak');
      } else {
        wrongCredentialMessage('Registration failed');
      }
      return;
    } catch (e) {
      print("Error during registration: $e");
      // Don't show backend errors to user, just log them
    }
  }

  String errorMessageContent(String message) {
    switch (message) {
      case 'Invalid Email':
        return 'Please enter a valid email';
      case 'User not found':
        return 'Sign up to create an account';
      case 'Invalid Password':
        return 'Invalid Password';
      case 'Email already in use':
        return 'This email is already registered';
      default:
        return 'An error occurred';
    }
  }

  void wrongCredentialMessage(String message) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            surfaceTintColor: Colors.grey[300]!,
            backgroundColor: Colors.white,
            title: Text(message),
            content: Text(errorMessageContent(message)),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                child: Text('OK', style: TextStyle(color: Colors.grey[800])),
              ),
            ],
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[300],
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: SafeArea(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 25.w),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  SizedBox(height: 30.h),
                  //logo
                  Icon(Icons.lock, size: 100.sp),
                  SizedBox(height: 30.h),
                  //welcome text
                  Text(
                    'Let\'s Get Started',
                    style: TextStyle(color: Colors.grey[700], fontSize: 16.sp),
                  ),
                  SizedBox(height: 20.h),

                  //text fields
                  MyTextField(
                    isPasswordTextField: false,
                    hintText: 'Username',
                    controller: usernameController,
                  ),
                  SizedBox(height: 8.h),
                  MyTextField(
                    isPasswordTextField: true,
                    hintText: 'Password',
                    controller: passwordController,
                  ),
                  SizedBox(height: 8.h),
                  //confirm password
                  MyTextField(
                    isPasswordTextField: true,
                    hintText: 'confirm password',
                    controller: confirmPasswordController,
                  ),
                  SizedBox(height: 20.h),
                  //login button
                  MyButton(text: 'Sign Up', ontap: signUp),
                  SizedBox(height: 25.h),
                  //google + apple sign in
                  Row(
                    children: [
                      Expanded(child: Divider(color: Colors.grey[400])),
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 10.w),
                        child: Text(
                          'Or continue with',
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                      ),
                      Expanded(child: Divider(color: Colors.grey[400])),
                    ],
                  ),
                  SizedBox(height: 25.h),
                  SquareTile(
                    onTap: () async {
                      showDialog(
                        context: context,
                        builder:
                            (context) => Center(
                              child: CircularProgressIndicator(
                                color: Colors.blue[300]!,
                              ),
                            ),
                      );
                      try {
                        await AuthService().signInWithGoogle();
                      } catch (e) {
                        // Handle Firebase errors here
                        print("Error during Google Sign-In: $e");
                        Navigator.pop(context);
                      }
                    },
                    imgUrl: 'assets/images/auth/google.png',
                  ),

                  SizedBox(height: 20.h),
                  //not a member? sign up
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        'Already member?',
                        style: TextStyle(color: Colors.grey),
                      ),
                      TextButton(
                        onPressed: widget.onTap,
                        child: const Text(
                          'Sign In',
                          style: TextStyle(color: Colors.blue),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
