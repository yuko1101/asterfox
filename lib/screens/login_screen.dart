import 'dart:io';

import 'package:asterfox/system/theme/theme.dart';
import 'package:easy_app/utils/languages.dart';
import 'package:easy_app/utils/os.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class LoginScreen extends StatelessWidget {
  LoginScreen({Key? key}) : super(key: key);

  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Asterfox"),
        leading: IconButton(
          tooltip: Language.getText("exit_app"),
          icon: const RotatedBox(
            child: Icon(Icons.exit_to_app),
            quarterTurns: 2,
          ),
          onPressed: () {
            if (OS.getOS() == OSType.android) {
              SystemNavigator.pop();
            } else {
              exit(0);
            }
          },
        ),
      ),
      body: Center(
        // TODO: fix that singlechildscrollview can be scrolled after opened keyboard and scrolled it,
        // even if the height of its child is less than max size
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Container(
            padding: const EdgeInsets.only(left: 30, right: 30),
            child: Column(
              mainAxisSize: MainAxisSize.max,
              children: [
                // TODO: better ui
                SizedBox(
                  height: 200,
                  width: 200,
                  child: FittedBox(
                    fit: BoxFit.contain,
                    child: Image.asset(
                      "assets/images/asterfox.png",
                    ),
                  ),
                ),
                Text(
                  Language.getText("welcome_back"),
                  style: const TextStyle(
                      fontSize: 40, fontWeight: FontWeight.bold),
                ),
                const SizedBox(
                  height: 40,
                ),
                EmailField(
                  emailController: emailController,
                  passwordController: passwordController,
                ),
                const SizedBox(
                  height: 20,
                ),
                PasswordField(
                  passwordController: passwordController,
                  emailController: emailController,
                ),
                const SizedBox(
                  height: 40,
                ),
                LoginButton(
                  passwordController: passwordController,
                  emailController: emailController,
                ),
                const SizedBox(
                  height: 20,
                )
                // TODO: Add Google account login
              ],
            ),
          ),
        ),
      ),
    );
  }

  static Future<void> login(
      String email, String password, BuildContext context) async {
    showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Dialog(
              child: SizedBox(
                height: 200,
                width: 200,
                child: Center(
                  child: SizedBox(
                    height: 40,
                    width: 40,
                    child: FittedBox(
                      child: CircularProgressIndicator(),
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
              ),
            ));
    await FirebaseAuth.instance
        .signInWithEmailAndPassword(email: email, password: password);
    Navigator.pop(context);
  }
}

class EmailField extends StatefulWidget {
  static final emailRegExp = RegExp(
      r"^[a-zA-Z0-9_+-]+(.[a-zA-Z0-9_+-]+)*@([a-zA-Z0-9][a-zA-Z0-9-]*[a-zA-Z0-9]*\.)+[a-zA-Z]{2,}$");

  const EmailField({
    required this.emailController,
    required this.passwordController,
    Key? key,
  }) : super(key: key);
  final TextEditingController emailController;
  final TextEditingController passwordController;

  @override
  State<EmailField> createState() => _EmailFieldState();
}

class _EmailFieldState extends State<EmailField> {
  bool isEmpty = true;
  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: widget.emailController,
      textInputAction: TextInputAction.next,
      decoration: InputDecoration(
        labelText: Language.getText("email"),
        border: const OutlineInputBorder(),
        // fillColor: Colors.black45,
        hintText: "username@example.com",
        suffixIcon: isEmpty
            ? null
            : IconButton(
                icon: Icon(
                  Icons.clear,
                  color: Theme.of(context).extraColors.secondary,
                ),
                onPressed: () {
                  setState(() {
                    widget.emailController.clear();
                    isEmpty = true;
                  });
                },
              ),
      ),
      autovalidateMode: AutovalidateMode.onUserInteraction,
      validator: (String? input) {
        if (input == null || !EmailField.emailRegExp.hasMatch(input)) {
          return Language.getText("invalid_email");
        }
        return null;
      },
      onChanged: (value) {
        setState(() {
          isEmpty = value.isEmpty;
        });
      },
      onFieldSubmitted: (value) {
        if (widget.passwordController.text.isNotEmpty) {
          LoginScreen.login(value, widget.passwordController.text, context);
        }
      },
    );
  }
}

class PasswordField extends StatefulWidget {
  const PasswordField({
    required this.passwordController,
    required this.emailController,
    Key? key,
  }) : super(key: key);
  final TextEditingController passwordController;
  final TextEditingController emailController;

  @override
  State<PasswordField> createState() => _PasswordFieldState();
}

class _PasswordFieldState extends State<PasswordField> {
  bool showPassword = false;
  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: widget.passwordController,
      decoration: InputDecoration(
        labelText: Language.getText("password"),
        border: const OutlineInputBorder(),
        suffixIcon: IconButton(
          icon: Icon(
            showPassword ? Icons.visibility_off : Icons.visibility,
            color: Theme.of(context).extraColors.secondary,
          ),
          onPressed: () {
            setState(() {
              showPassword = !showPassword;
            });
          },
        ),
      ),
      autovalidateMode: AutovalidateMode.onUserInteraction,
      validator: (String? input) {
        if (input == null || input.isEmpty) {
          return Language.getText("input_password");
        }
        return null;
      },
      onFieldSubmitted: (value) {
        final String email = widget.emailController.text;
        final String password = value;
        print("email: $email, password: $value");
        LoginScreen.login(email, password, context);
      },
      obscureText: !showPassword,
    );
  }
}

class LoginButton extends StatelessWidget {
  const LoginButton({
    required this.passwordController,
    required this.emailController,
    Key? key,
  }) : super(key: key);
  final TextEditingController passwordController;
  final TextEditingController emailController;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 40,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: Stack(
          children: [
            Container(
              decoration: const BoxDecoration(
                  gradient: LinearGradient(
                colors: [
                  Colors.orange,
                  Color.fromARGB(255, 255, 204, 0),
                ],
                begin: FractionalOffset.bottomCenter,
              )),
            ),
            Align(
              alignment: Alignment.topLeft,
              child: ClipPath(
                child: Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.orange,
                        Colors.red,
                      ],
                    ),
                  ),
                ),
                clipper: LoginButtonClipper(),
              ),
            ),
            Material(
              color: Colors.transparent,
              child: InkWell(
                splashColor: Colors.white10,
                hoverColor: Colors.white10,
                onTap: () async {
                  final String email = emailController.text;
                  final String password = passwordController.text;

                  LoginScreen.login(email, password, context);
                },
                child: Center(
                  child: Text(
                    Language.getText("sign_in"),
                    style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                        shadows: [
                          Shadow(blurRadius: 1.0),
                        ]),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class LoginButtonClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    return Path()
      ..lineTo(0, 0)
      ..lineTo(size.width / 2 + 20, 0)
      ..lineTo(size.width / 2 - 20, size.height)
      ..lineTo(0, size.height);
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}
