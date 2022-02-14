import 'package:fluttertoast/fluttertoast.dart';

Future<bool> networkConnectedSync() async {
  return true;
}

Future<bool> networkAccessibleSync() async {
  return true;
}
bool networkAccessible() {
  return true;
}

Future<void> showNetworkAccessDeniedMessage() async {
  if (!await networkConnectedSync()) Fluttertoast.showToast(msg: "インターネットに接続できませんでした");
  if (!await networkAccessibleSync()) Fluttertoast.showToast(msg: "インターネット接続方法が制限されています");
}

