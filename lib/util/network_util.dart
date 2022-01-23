import 'package:fluttertoast/fluttertoast.dart';

Future<bool> networkConnected() async {
  return true;
}

Future<bool> networkAccessible() async {
  return true;
}

Future<void> showNetworkAccessDeniedMessage() async {
  if (!await networkConnected()) Fluttertoast.showToast(msg: "インターネットに接続できませんでした");
  if (!await networkAccessible()) Fluttertoast.showToast(msg: "インターネット接続方法が制限されています");
}

