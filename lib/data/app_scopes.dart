/// The names of the data the app stores.
///
/// Rows are keyed by scope so that the data of a user can be told apart from
/// the data that only exists on this device. The scope of a row is built by
/// [AppDatabase.userScopeOf].
class AppScopes {
  /// The scope of the data that only exists on this device.
  static const String local = "local";

  /// App settings, which are stored outside of the device scope so that they
  /// can follow the user.
  static const String settings = "__settings";

  /// Custom colors, which were stored in their own file and stay on this
  /// device.
  static const String customColors = "__custom_colors";

  static const String songs = "songs";
  static const String playlists = "playlists";
  static const String history = "history";

  /// Device settings, which stay on this device.
  static const String deviceSettings = "device_settings";
}
