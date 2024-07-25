import 'dart:convert';
import 'dart:io';

import 'os.dart';

/// ConfigFile is a class that helps you to create JSON config files easily.
class ConfigFile {
  ConfigFile(this.file, this.defaultValue, {this.route = const []});

  /// The file that stores the config data.
  final File file;

  /// The default config data.
  final Map<String, dynamic> defaultValue;

  /// The JSON route to the current path.
  List<String> route;

  /// The config data.
  late Map<String, dynamic> data;

  /// Save the config data to the file.
  Future<ConfigFile> save({bool compact = false}) async {
    if (OS.isWeb) return this;
    if (!file.existsSync()) {
      file.createSync(recursive: true);
      data = defaultValue;
    }
    if (compact) {
      await file.writeAsString(jsonEncode(data));
    } else {
      await file
          .writeAsString(const JsonEncoder.withIndent("  ").convert(data));
    }
    return this;
  }

  /// Load the config data from the file.
  Future<ConfigFile> load() async {
    if (OS.isWeb) {
      data = defaultValue;
      return this;
    }
    if (!file.existsSync()) await save();
    data = jsonDecode(file.readAsStringSync());
    return this;
  }

  /// Set value to JSON object.
  ConfigFile set({String? key, dynamic value}) {
    final path = [...route];
    if (key != null) path.add(key);
    data = _set(data, path, value, 0);
    return this;
  }

  /// Delete key from JSON object.
  ConfigFile delete({String? key}) {
    if (key == null) {
      if (route.isEmpty) return this;
      getPreObjectFromPath().remove(route.last);
      return this;
    }
    getObjectFromPath().remove(key);
    return this;
  }

  /// Get value from JSON object. If key is not provided, return the value at current path.
  dynamic getValue([String? key]) {
    if (key == null) {
      if (route.isEmpty) return data;
      return getPreObjectFromPath()[route.last];
    } else {
      return getObjectFromPath()[key];
    }
  }

  /// Get PathResolver instance of the path.
  PathResolver get(List<String> keys) {
    List<String> newRoute = [...route];
    newRoute.addAll(keys);
    return PathResolver(route: newRoute, configFile: this);
  }

  /// Check if the key exists in the JSON object.
  bool has(String key) {
    return getObjectFromPath().containsKey(key);
  }

  /// Check if the current path exists.
  bool exists() {
    if (route.isEmpty) return true;
    return getPreObjectFromPath().containsKey(route.last);
  }

  /// Reset the config data to the default value.
  ConfigFile resetData() {
    data = defaultValue;
    return this;
  }

  /// Clear the stored route. This means that you can get the root ConfigFile instance.
  ConfigFile resetPath() {
    route.clear();
    return this;
  }

  // if the target object is {}, it cannot be cast to Map<String, dynamic>
  /// Get the JSON object at the current path.
  Map<dynamic, dynamic> getObjectFromPath() {
    Map<dynamic, dynamic> mutableData = data;
    for (int i = 0; i < route.length; i++) {
      final k = route[i];
      if (!mutableData.containsKey(k)) mutableData[k] = {};
      mutableData = mutableData[k];
    }
    return mutableData;
  }

  // if the target object is {}, it cannot be cast to Map<String, dynamic>
  /// Get the parent JSON object of the current path.
  Map<dynamic, dynamic> getPreObjectFromPath() {
    Map<dynamic, dynamic> mutableData = data;
    for (int i = 0; i < route.length - 1; i++) {
      final k = route[i];
      if (!mutableData.containsKey(k)) {
        mutableData[k] = {};
      }
      mutableData = mutableData[k];
    }
    return mutableData;
  }

  dynamic _set(dynamic data, List<String> path, dynamic value, int i) {
    if (i == path.length) {
      return value;
    } else {
      if (data is Map<String, dynamic>) {
        data = Map<String, dynamic>.from(data);
      } else {
        data = {};
      }
      data[path[i]] = _set(data[path[i]], path, value, ++i);
      return data;
    }
  }
}

/// PathResolver is a class to set a value deelpy.
///
/// PathResolvers store respective routes not to
/// change their base ConfigFile instances' routes.
class PathResolver extends ConfigFile {
  PathResolver({
    required this.configFile,
    required List<String> route,
  }) : super(configFile.file, configFile.defaultValue, route: route);

  /// Base ConfigFile instance for this PathResolver
  final ConfigFile configFile;

  /// The config data.
  @override
  Map<String, dynamic> get data => configFile.data;
  @override
  set data(Map<String, dynamic> newData) {
    configFile.data = newData;
  }

  /// Get PathResolver instance of the path.
  @override
  PathResolver get(List<String> keys) {
    List<String> newRoute = [...route];
    newRoute.addAll(keys);
    return PathResolver(route: newRoute, configFile: configFile);
  }
}
