import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:fluttertoast/fluttertoast.dart';

import '../system/exceptions/network_exception.dart';
import 'os.dart';

class NetworkUtils {
  /// Stream of connectivity status.
  static late StreamSubscription connectivitySubscription;

  /// Current network status. Until the first one is known, the network is
  /// taken to be there, so that nothing is refused for a status not yet read.
  static List<ConnectivityResult> connectivityResults = [
    ConnectivityResult.other,
  ];

  /// Minimum network level
  static ConnectivityResult minimum = ConnectivityResult.mobile;

  /// Initialize network utils
  static Future<void> init(ConnectivityResult minimumNetworkLevel) async {
    minimum = minimumNetworkLevel;
    final connectivity = Connectivity();
    connectivityResults = await connectivity.checkConnectivity();
    connectivitySubscription =
        connectivity.onConnectivityChanged.listen((data) {
      connectivityResults = data;
    });
  }

  /// Set minimum network level
  static void setMinimumNetworkLevel(ConnectivityResult minimumNetworkLevel) {
    minimum = minimumNetworkLevel;
  }

  /// Stop listening to connectivity changes
  static void dispose() {
    connectivitySubscription.cancel();
  }

  /// Check if there is internet connection
  static bool networkConnected() {
    return OS.isWeb ||
        connectivityResults.any((c) => c != ConnectivityResult.none);
  }

  /// Check if the internet connection is accessible
  static bool networkAccessible() {
    return OS.isWeb || connectivityResults.any((c) => c.index <= minimum.index);
  }

  /// Show a message when there is no internet connection
  static void showNetworkAccessDeniedMessage({
    required String notConnectedMessage,
    required String notAccessibleMessage,
  }) {
    if (!networkConnected()) {
      Fluttertoast.showToast(
        msg: notConnectedMessage,
      );
    } else if (!networkAccessible()) {
      Fluttertoast.showToast(
        msg: notAccessibleMessage,
      );
    }
  }

  static void check() {
    if (!NetworkUtils.networkConnected()) {
      throw NetworkException();
    }
  }
}
