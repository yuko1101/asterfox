import 'dart:io';

import 'package:asterfox/screens/asterfox_screen.dart';
import 'package:asterfox/system/theme/theme.dart';
import 'package:easy_app/utils/languages.dart';
import 'package:easy_app/utils/os.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fluttertoast/fluttertoast.dart';

class AuthScreen extends StatefulWidget {
  AuthScreen({Key? key}) : super(key: key);

  final TextEditingController emailController = TextEditingController();

  final TextEditingController passwordController = TextEditingController();

  final formKey = GlobalKey<FormState>();

  @override
  State<AuthScreen> createState() => _AuthScreenState();

  static Future<void> login(
      GlobalKey<FormState> formKey,
      TextEditingController emailController,
      TextEditingController passwordController,
      BuildContext context) async {
    if (!formKey.currentState!.validate()) return;
    final String email = emailController.text.trim();
    final String password = passwordController.text.trim();
    // print("email: $email, password: $value");
    final dialogRoute = DialogRoute(
      context: context,
      barrierDismissible: false,
      builder: (_) => WillPopScope(
        onWillPop: () async => false,
        child: const Center(
          child: CircularProgressIndicator(),
        ),
      ),
    );

    AsterfoxScreen.loadingNotifier.value = true;

    try {
      await FirebaseAuth.instance
          .signInWithEmailAndPassword(email: email, password: password);
    } on FirebaseAuthException catch (e) {
      if (e.code == "network-request-failed") {
        Fluttertoast.showToast(msg: Language.getText("network_not_connected"));
      } else if (e.code == "invalid-email" ||
          e.code == "user-not-found" ||
          e.code == "wrong-password") {
        emailController.clear();
        passwordController.clear();
        Fluttertoast.showToast(
            msg: Language.getText("invalid_email_or_password"));
      } else if (e.code == "user-disabled") {
        emailController.clear();
        passwordController.clear();
        Fluttertoast.showToast(msg: Language.getText("disabled_user"));
      } else {
        rethrow;
      }
    }
    AsterfoxScreen.loadingNotifier.value = false;
  }

  static Future<void> signUp(
      GlobalKey<FormState> formKey,
      TextEditingController emailController,
      TextEditingController passwordController,
      BuildContext context) async {
    if (!formKey.currentState!.validate()) return;
    final String email = emailController.text.trim();
    final String password = passwordController.text.trim();

    AsterfoxScreen.loadingNotifier.value = true;

    try {
      await FirebaseAuth.instance
          .createUserWithEmailAndPassword(email: email, password: password);
    } on FirebaseAuthException catch (e) {
      if (e.code == "email-already-in-use") {
        emailController.clear();
        passwordController.clear();
        Fluttertoast.showToast(msg: Language.getText("email_already_in_use"));
      } else if (e.code == "invalid-email") {
        emailController.clear();
        passwordController.clear();
        Fluttertoast.showToast(msg: Language.getText("invalid_email"));
      } else if (e.code == "weak-password") {
        passwordController.clear();
        Fluttertoast.showToast(msg: Language.getText("weak_password"));
      } else {
        rethrow;
      }
    }
    AsterfoxScreen.loadingNotifier.value = false;
  }
}

class _AuthScreenState extends State<AuthScreen> {
  bool signUp = false;

  void changeMode(bool signUp) {
    setState(() {
      this.signUp = signUp;
    });
  }

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
        // TODO: fix that singlechildscrollview can be scrolled after opened keyboard and scrolled it, even if the height of its child is less than max size
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Container(
            padding: const EdgeInsets.only(left: 30, right: 30),
            child: Form(
              key: widget.formKey,
              child: AutofillGroup(
                child: Column(
                  mainAxisSize: MainAxisSize.max,
                  children: [
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
                      signUp
                          ? Language.getText("welcome")
                          : Language.getText("welcome_back"),
                      style: const TextStyle(
                          fontSize: 40, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(
                      height: 40,
                    ),
                    EmailField(
                      formKey: widget.formKey,
                      emailController: widget.emailController,
                      passwordController: widget.passwordController,
                      signUp: signUp,
                    ),
                    const SizedBox(
                      height: 20,
                    ),
                    PasswordField(
                      formKey: widget.formKey,
                      passwordController: widget.passwordController,
                      emailController: widget.emailController,
                      signUp: signUp,
                    ),
                    const SizedBox(
                      height: 40,
                    ),
                    ConfirmButton(
                      formKey: widget.formKey,
                      passwordController: widget.passwordController,
                      emailController: widget.emailController,
                      signUp: signUp,
                    ),
                    const SizedBox(
                      height: 10,
                    ),
                    AuthMessage(
                      signUp: signUp,
                      changeMode: changeMode,
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
        ),
      ),
    );
  }
}

class EmailField extends StatefulWidget {
  static final emailRegExp = RegExp(
      r"^[a-zA-Z0-9_+-]+(.[a-zA-Z0-9_+-]+)*@([a-zA-Z0-9][a-zA-Z0-9-]*[a-zA-Z0-9]*\.)+[a-zA-Z]{2,}$");

  const EmailField({
    required this.formKey,
    required this.emailController,
    required this.passwordController,
    required this.signUp,
    Key? key,
  }) : super(key: key);
  final GlobalKey<FormState> formKey;
  final TextEditingController emailController;
  final TextEditingController passwordController;

  final bool signUp;

  @override
  State<EmailField> createState() => _EmailFieldState();
}

class _EmailFieldState extends State<EmailField> {
  bool isEmpty = true;
  @override
  Widget build(BuildContext context) {
    return TextFormField(
      autofillHints: const [AutofillHints.email],
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
        if (input == null || !EmailField.emailRegExp.hasMatch(input.trim())) {
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
          if (widget.signUp) {
            AuthScreen.signUp(widget.formKey, widget.emailController,
                widget.passwordController, context);
          } else {
            AuthScreen.login(widget.formKey, widget.emailController,
                widget.passwordController, context);
          }
        }
      },
    );
  }
}

class PasswordField extends StatefulWidget {
  const PasswordField({
    required this.formKey,
    required this.passwordController,
    required this.emailController,
    required this.signUp,
    Key? key,
  }) : super(key: key);
  final GlobalKey<FormState> formKey;
  final TextEditingController passwordController;
  final TextEditingController emailController;

  final bool signUp;

  static final passwordRegExp =
      RegExp("[a-zA-Z0-9*.!@#\$%^&(){}[\\]:\";'<>,\\.\\?\\/~`_\\+-=\\|]{8,32}");

  @override
  State<PasswordField> createState() => _PasswordFieldState();
}

class _PasswordFieldState extends State<PasswordField> {
  bool showPassword = false;
  @override
  Widget build(BuildContext context) {
    return TextFormField(
      autofillHints: widget.signUp
          ? const [AutofillHints.newPassword]
          : const [AutofillHints.password],
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
        } else if (!PasswordField.passwordRegExp.hasMatch(input)) {
          return Language.getText("invalid_password_format");
        }
        return null;
      },
      onFieldSubmitted: (value) {
        if (widget.signUp) {
          AuthScreen.signUp(widget.formKey, widget.emailController,
              widget.passwordController, context);
        } else {
          AuthScreen.login(widget.formKey, widget.emailController,
              widget.passwordController, context);
        }
      },
      obscureText: !showPassword,
    );
  }
}

class ConfirmButton extends StatelessWidget {
  const ConfirmButton({
    required this.formKey,
    required this.passwordController,
    required this.emailController,
    required this.signUp,
    Key? key,
  }) : super(key: key);
  final GlobalKey<FormState> formKey;
  final TextEditingController passwordController;
  final TextEditingController emailController;
  final bool signUp;

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
                  if (signUp) {
                    AuthScreen.signUp(
                        formKey, emailController, passwordController, context);
                  } else {
                    AuthScreen.login(
                        formKey, emailController, passwordController, context);
                  }
                },
                child: Center(
                  child: Text(
                    signUp
                        ? Language.getText("sign_up")
                        : Language.getText("login"),
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

class AuthMessage extends StatelessWidget {
  const AuthMessage({
    required this.signUp,
    required this.changeMode,
    Key? key,
  }) : super(key: key);

  final bool signUp;
  final void Function(bool) changeMode;

  @override
  Widget build(BuildContext context) {
    final text = signUp
        ? Language.getText("login_message")
        : Language.getText("sign_up_message");
    final clickables = RegExp(r"\{[^{}]+\}").allMatches(text).toList();
    final List<TextSpan> textSpans = [];

    int currentIndex = 0;
    int clickableIndex = 0;
    while (currentIndex < text.length) {
      final RegExpMatch? clickable = clickableIndex < clickables.length
          ? clickables[clickableIndex]
          : null;
      final int nextStart = clickable?.start ?? text.length;
      if (currentIndex < nextStart) {
        textSpans.add(TextSpan(
            text: text.substring(currentIndex, nextStart),
            style: TextStyle(color: Theme.of(context).extraColors.primary)));
        currentIndex = nextStart;
      } else if (currentIndex == nextStart) {
        final rawText = text.substring(currentIndex, clickable!.end);
        textSpans.add(
          TextSpan(
            text: rawText.substring(1, rawText.length - 1),
            style: TextStyle(
                color: Colors.amber[600], decoration: TextDecoration.underline),
            recognizer: TapGestureRecognizer()
              ..onTap = () {
                changeMode(!signUp);
              },
          ),
        );
        currentIndex = clickable.end;
        clickableIndex++;
      }
    }
    return RichText(text: TextSpan(children: textSpans));
  }
}
