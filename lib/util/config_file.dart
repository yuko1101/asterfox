import 'dart:convert';
import 'dart:io';

class ConfigFile {
  ConfigFile(this.file, this.defaultValue, {this.route = const []});
  final File file;
  final Map<String, dynamic> defaultValue;
  final List<String> route;

  late Map<String, dynamic> data;

  Future<ConfigFile> save({bool compact = false}) async {
    if (!file.existsSync()) file.createSync(recursive: true);
    if (compact) {
      await file.writeAsString(jsonEncode(data));
    } else {
      await file.writeAsString(jsonEncode(data));
    }
    return this;
  }

  Future<ConfigFile> load() async {
    if (!file.existsSync()) await save();
    try {
      data = jsonDecode(file.readAsStringSync());
    } catch (e) {
      print(e);
      await save(); //ファイルを変更前に戻す
    }
    return this;
  }

  ConfigFile set({String? key, dynamic value}) {
    if (key == null) {
      if (route.isEmpty) return this;
      getPreObjectFromPath()[route.last] = value;
      return this;
    }
    getObjectFromPath()[key] = value;
    return this;
  }

  dynamic getValue(String? key) {
    if (key == null) {
      return getPreObjectFromPath()[route.last];
    } else {
      return getObjectFromPath()[key];
    }
  }

  ConfigFile get(List<String> keys) {
    List<String> newRoute = [...route];
    newRoute.addAll(keys);
    return ConfigFile(file, defaultValue, route: newRoute);
  }

  bool has(String key) {
    return getObjectFromPath().containsKey(key);
  }

  bool exists() {
    return getPreObjectFromPath().containsKey(route.last);
  }

  ConfigFile resetData() {
    data = defaultValue;
    return this;
  }

  ConfigFile resetPath() {
    route.clear();
    return this;
  }

  Map<String, dynamic> getObjectFromPath() {
    Map<String, dynamic> mutableData = data;
    for (int i = 0; i < route.length; i++) {
      final k = route[i];
      if (!mutableData.containsKey(k)) mutableData[k] = {};
      mutableData = mutableData[k];
    }
    return mutableData;
  }

  Map<String, dynamic> getPreObjectFromPath() {
    Map<String, dynamic> mutableData = data;
    for (int i = 0; i < route.length - 1; i++) {
      final k = route[i];
      if (!mutableData.containsKey(k)) mutableData[k] = {};
      mutableData = mutableData[k];
    }
    return mutableData;
  }
}