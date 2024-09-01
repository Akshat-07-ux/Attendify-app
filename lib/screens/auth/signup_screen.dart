import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import '../../widgets/input_field.dart';
import 'login_screen.dart';
import 'package:another_flushbar/flushbar.dart';
import '../home_screen.dart';
import '../../methods/auth_methods.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({Key? key}) : super(key: key);

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  void showFlushBar(BuildContext context, String title, String message) {
    Flushbar(
      title: title,
      message: message,
      duration: const Duration(seconds: 3),
    ).show(context);
  }

  void _signup(String email, String password) async {
    showFlushBar(context, "Wait", "Processing");
    String result = await AuthMethods().signUpUser(
      email: email,
      password: password
    );
    if (result == "Success") {
      showFlushBar(context, result, "Successfully Signed Up");
      Future.delayed(const Duration(seconds: 2), () {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => HomeScreen(
              targetLatitude: 25.596802,
              targetLongitude:  85.088756,
            ),
            settings: RouteSettings(arguments: {'email': email}),
          ),
        );
      });
    } else {
      showFlushBar(context, "Error occurred", result);
    }
  }

  @override
  Widget build(BuildContext context) {
    var width = MediaQuery.of(context).size.width;

    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Adding the GIF above the sign-up box
              Image.asset(
                'assets/agrix.gif',
                width: 150, // Adjust the width and height as needed
                height: 150,
              ),
              const SizedBox(height: 20),
              Container(
                width: kIsWeb ? width / 4 : width / 1.2,
                padding: const EdgeInsets.all(16.0),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10.0),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.5),
                      spreadRadius: 5,
                      blurRadius: 7,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      const Text(
                        "Sign Up",
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 35),
                      InputField(hintText: "Email", controller: _emailController),
                      const SizedBox(height: 25),
                      InputField(hintText: "Password", controller: _passwordController, obscureText: true),
                      const SizedBox(height: 25),
                      ElevatedButton(
                        onPressed: () {
                          if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
                            showFlushBar(context, "Error", "Email or Password cannot be empty");
                          } else {
                            _signup(_emailController.text, _passwordController.text);
                          }
                        },
                        child: const Text("Sign Up"),
                      ),
                      const SizedBox(height: 20),
                      const Text("Already have an account?"),
                      TextButton(
                        onPressed: () {
                          Navigator.of(context).pushReplacement(
                           MaterialPageRoute(
                            builder: (context) => LoginScreen(
                              targetLatitude: 23.377794, // Replace with your actual target latitude
                              targetLongitude: 85.319072, // Replace with your actual target longitude
                            ),
                          ),
                        );
                      },
                        child: const Text("Login"),
                      ),
                    ],
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
