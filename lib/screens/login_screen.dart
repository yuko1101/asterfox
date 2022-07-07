import 'package:asterfox/system/theme/theme.dart';
import 'package:easy_app/utils/languages.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class LoginScreen extends StatelessWidget {
  LoginScreen({Key? key}) : super(key: key);

  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(Language.getText("login")),
      ),
      body: SingleChildScrollView(
        child: Container(
          padding: const EdgeInsets.only(left: 30, right: 30),
          child: Column(
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
                style:
                    const TextStyle(fontSize: 40, fontWeight: FontWeight.bold),
              ),
              const SizedBox(
                height: 40,
              ),
              EmailField(
                emailController: emailController,
                passwordController: passwordController,
              ),
              const SizedBox(
                height: 30,
              ),
              PasswordField(
                passwordController: passwordController,
                emailController: emailController,
              )
              // TODO: Add login button
              // TODO: Add Google account login
            ],
          ),
        ),
      ),
    );
  }

  static Future<void> login(String email, String password) async {
    await FirebaseAuth.instance
        .signInWithEmailAndPassword(email: email, password: password);
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
          LoginScreen.login(value, widget.passwordController.text);
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
        LoginScreen.login(email, password);
      },
      obscureText: !showPassword,
    );
  }
}
