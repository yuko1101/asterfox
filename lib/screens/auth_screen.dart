import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../main.dart';
import '../system/theme/theme.dart';
import '../utils/os.dart';
import '../widget/loading_dialog.dart';

// TODO: alert users to connect to the Internet when offline
class AuthScreen extends StatefulWidget {
  AuthScreen({super.key});

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

    final future = () async {
      try {
        await FirebaseAuth.instance
            .signInWithEmailAndPassword(email: email, password: password);
      } on FirebaseAuthException catch (e) {
        if (e.code == "network-request-failed") {
          Fluttertoast.showToast(msg: l10n.value.network_not_connected);
        } else if (e.code == "invalid-email" ||
            e.code == "user-not-found" ||
            e.code == "wrong-password" ||
            e.code == "invalid-credential") {
          emailController.clear();
          passwordController.clear();
          Fluttertoast.showToast(msg: l10n.value.invalid_email_or_password);
        } else if (e.code == "user-disabled") {
          emailController.clear();
          passwordController.clear();
          Fluttertoast.showToast(msg: l10n.value.disabled_user);
        } else {
          rethrow;
        }
      }
    }();

    await LoadingDialog.showLoading(context: context, future: future);
  }

  static Future<void> signUp(
      GlobalKey<FormState> formKey,
      TextEditingController emailController,
      TextEditingController passwordController,
      BuildContext context) async {
    if (!formKey.currentState!.validate()) return;
    final String email = emailController.text.trim();
    final String password = passwordController.text.trim();

    final future = () async {
      try {
        await FirebaseAuth.instance
            .createUserWithEmailAndPassword(email: email, password: password);
      } on FirebaseAuthException catch (e) {
        if (e.code == "email-already-in-use") {
          emailController.clear();
          passwordController.clear();
          Fluttertoast.showToast(msg: l10n.value.email_already_in_use);
        } else if (e.code == "invalid-email") {
          emailController.clear();
          passwordController.clear();
          Fluttertoast.showToast(msg: l10n.value.invalid_email);
        } else if (e.code == "weak-password") {
          passwordController.clear();
          Fluttertoast.showToast(msg: l10n.value.weak_password);
        } else {
          rethrow;
        }
      }
    }();

    await LoadingDialog.showLoading(context: context, future: future);
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
          tooltip: l10n.value.exit_app,
          icon: const RotatedBox(
            quarterTurns: 2,
            child: Icon(Icons.exit_to_app),
          ),
          onPressed: exitApp,
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
                      signUp ? l10n.value.welcome : l10n.value.welcome_back,
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
                    const Visibility(child: ForgotPassword()),
                    AuthMessage(
                      signUp: signUp,
                      changeMode: changeMode,
                    ),
                    const SizedBox(
                      height: 20,
                    ),
                    if (GoogleSignInWidget.isAvailable)
                      const GoogleSignInWidget(),
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
    super.key,
  });
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
      keyboardType: TextInputType.emailAddress,
      decoration: InputDecoration(
        labelText: l10n.value.email,
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
          return l10n.value.invalid_email;
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
    super.key,
  });
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
      obscureText: !showPassword,
      controller: widget.passwordController,
      decoration: InputDecoration(
        labelText: l10n.value.password,
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
          return l10n.value.input_password;
        } else if (!PasswordField.passwordRegExp.hasMatch(input)) {
          return l10n.value.invalid_password_format;
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
      onEditingComplete: () => TextInput.finishAutofillContext(),
    );
  }
}

class ConfirmButton extends StatelessWidget {
  const ConfirmButton({
    required this.formKey,
    required this.passwordController,
    required this.emailController,
    required this.signUp,
    super.key,
  });
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
                clipper: LoginButtonClipper(),
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
                    signUp ? l10n.value.sign_up : l10n.value.login,
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
    super.key,
  });

  final bool signUp;
  final void Function(bool) changeMode;

  @override
  Widget build(BuildContext context) {
    final text = signUp ? l10n.value.login_message : l10n.value.sign_up_message;
    final clickableTexts = RegExp(r"%.+?%").allMatches(text).toList();
    final List<TextSpan> textSpans = [];

    int currentIndex = 0;
    int clickableIndex = 0;
    while (currentIndex < text.length) {
      final RegExpMatch? clickable = clickableIndex < clickableTexts.length
          ? clickableTexts[clickableIndex]
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
              color: Colors.amber[600],
              decoration: TextDecoration.underline,
            ),
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

class ForgotPassword extends StatelessWidget {
  const ForgotPassword({super.key});

  @override
  Widget build(BuildContext context) {
    return RichText(
      text: TextSpan(
        text: l10n.value.forgot_password,
        style: TextStyle(
          color: Colors.amber[600],
          decoration: TextDecoration.underline,
        ),
        recognizer: TapGestureRecognizer()
          ..onTap = () {
            resetPassword(context);
          },
      ),
    );
  }

  static void resetPassword(BuildContext context) {
    final controller = TextEditingController();
    final formKey = GlobalKey<FormState>();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.value.reset_password),
        content: Form(
          key: formKey,
          child: TextFormField(
            controller: controller,
            autofillHints: const [AutofillHints.email],
            autovalidateMode: AutovalidateMode.onUserInteraction,
            decoration: InputDecoration(
              labelText: l10n.value.email,
            ),
            validator: (String? input) {
              if (input == null ||
                  !EmailField.emailRegExp.hasMatch(input.trim())) {
                return l10n.value.invalid_email;
              }
              return null;
            },
          ),
        ),
        actions: [
          TextButton(
            child: Text(l10n.value.send),
            onPressed: () async {
              if (!formKey.currentState!.validate()) return;
              Navigator.of(context).pop();

              final resetPasswordMsg = l10n.value.reset_password_email_sent;

              // TODO: handle [There is no user record corresponding to this identifier. The user may have been deleted.]
              final future = FirebaseAuth.instance
                  .sendPasswordResetEmail(email: controller.text);
              await LoadingDialog.showLoading(context: context, future: future);

              Fluttertoast.showToast(msg: resetPasswordMsg);
            },
          )
        ],
      ),
    );
  }
}

// https://developers.google.com/identity/branding-guidelines?hl=ja
class GoogleSignInWidget extends StatelessWidget {
  const GoogleSignInWidget({super.key});

  static final bool isAvailable =
      OS.isAndroid || OS.isIOS || OS.isWeb || OS.isMacOS;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final compactMode = width < 300; // mostly for watches
    // TODO: Rippleエフェクトを修正したままで、各言語での「Sign in with Google」の長さに応じてボタンのサイズが変わるようにする
    return Container(
      height: 40,
      margin:
          !compactMode ? EdgeInsets.symmetric(horizontal: width * 0.05) : null,
      color: Colors.white,
      width: compactMode ? 40 : null,
      child: Stack(
        children: [
          Positioned.fill(
            child: !compactMode
                ? Padding(
                    padding: const EdgeInsets.only(left: 8, right: 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SvgPicture.asset(
                          "assets/images/btn_google_light_normal_ios.svg",
                          fit: BoxFit.fitWidth,
                        ),
                        const SizedBox(
                          width: 24,
                        ),
                        Text(
                          l10n.value.sign_in_with_google,
                          style: const TextStyle(color: Colors.black),
                        ),
                        const SizedBox(
                          width: 40,
                        ),
                      ],
                    ),
                  )
                : SvgPicture.asset(
                    "assets/images/btn_google_light_normal_ios.svg",
                    fit: BoxFit.fitWidth,
                  ),
          ),
          Positioned.fill(
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () {
                  googleLogin(context);
                },
                child: Container(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  static bool _initialized = false;
  static final ValueNotifier<GoogleSignInAuthenticationEvent?> signInState =
      ValueNotifier(null);
  static Future<void> googleLogin(BuildContext context) async {
    final future = () async {
      if (!_initialized) {
        GoogleSignIn.instance.authenticationEvents.listen((event) {
          signInState.value = event;
        });
        await GoogleSignIn.instance.initialize();
        _initialized = true;
      }

      GoogleSignInAccount? googleUser;
      try {
        googleUser = await GoogleSignIn.instance.authenticate();
      } on GoogleSignInException {
        Fluttertoast.showToast(msg: l10n.value.something_went_wrong);
      }

      if (googleUser == null) {
        // The user canceled the sign-in
        return;
      }

      final authzClient = googleUser.authorizationClient;
      final scopes = ["email", "profile"];

      final authz = await authzClient.authorizeScopes(scopes);

      final credential = GoogleAuthProvider.credential(
        accessToken: authz.accessToken,
        idToken: googleUser.authentication.idToken,
      );

      await FirebaseAuth.instance.signInWithCredential(credential);
    }();

    await LoadingDialog.showLoading(context: context, future: future);
  }
}
