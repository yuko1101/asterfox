/// The names the app stores its data under.
///
/// Every row carries a scope, which separates the data of a user from the data
/// that only exists on this device. The shape of a scope tells what the rows
/// hold:
///
/// * a bare name (`songs`) is data of the signed in user; the scope of the row
///   is built by `AppDatabase.userScopeOf`.
/// * a name under [local] is data of this device, which is never uploaded.
/// * a name starting with `__` is neither, like [settings], which follows the
///   user through the cloud but is stored in one scope for every user.
class AppScopes {
  /// The device the app runs on, and the scope used while nobody is signed in.
  static const String local = "local";

  static const String songs = "songs";
  static const String playlists = "playlists";
  static const String history = "history";

  /// App settings, which follow the user. See the class comment for the `__`.
  static const String settings = "__settings";

  /// Device settings, which stay on this device.
  static const String deviceSettings = '$local/device_settings';

  /// Custom colors, which stay on this device.
  static const String customColors = '$local/custom_colors';
}
