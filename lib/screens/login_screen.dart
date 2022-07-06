import 'package:easy_app/utils/languages.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class LoginScreen extends StatelessWidget {
  static final emailRegExp = RegExp(
      r"^[a-zA-Z0-9_+-]+(.[a-zA-Z0-9_+-]+)*@([a-zA-Z0-9][a-zA-Z0-9-]*[a-zA-Z0-9]*\.)+[a-zA-Z]{2,}$");

  LoginScreen({Key? key}) : super(key: key);

  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwardController = TextEditingController();

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
              TextFormField(
                controller: emailController,
                textInputAction: TextInputAction.next,
                decoration: InputDecoration(
                  labelText: Language.getText("email"),
                  border: const OutlineInputBorder(),
                  // fillColor: Colors.black45,
                  hintText: "username@example.com",
                ),
                autovalidateMode: AutovalidateMode.always,
                validator: (String? input) {
                  if (input == null || !emailRegExp.hasMatch(input)) {
                    return Language.getText("invalid_email");
                  }
                  return null;
                },
                onFieldSubmitted: (value) {
                  if (passwardController.text.isNotEmpty) {
                    login(value, passwardController.text);
                  }
                },
              ),
              const SizedBox(
                height: 30,
              ),
              TextFormField(
                controller: passwardController,
                decoration: InputDecoration(
                  labelText: Language.getText("password"),
                  border: const OutlineInputBorder(),
                ),
                autovalidateMode: AutovalidateMode.always,
                validator: (String? input) {
                  if (input == null || input.isEmpty) {
                    return Language.getText("input_password");
                  }
                  return null;
                },
                onFieldSubmitted: (value) {
                  final String email = emailController.text;
                  final String password = value;
                  print("email: ${emailController.text}, password: $value");
                  login(email, password);
                },
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
