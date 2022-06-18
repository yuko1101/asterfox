import 'package:easy_app/utils/network_utils.dart';

import '../system/exceptions/network_exception.dart';

class NetworkCheck {
  static void check() {
    if (!NetworkUtils.networkAccessible()) {
      throw NetworkException();
    }
  }
}
