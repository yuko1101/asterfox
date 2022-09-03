class MapUtils {
  // https://github.com/yuko1101/discord-core/blob/main/src/utils/utils.js
  static Map<String, dynamic> bindOptions(
      Map<String, dynamic> baseOptions, Map<String, dynamic> options) {
    var result = {...baseOptions};

    final nullPath = getNullPath(baseOptions);
    for (final option in getValuesWithPath(options,
        path: [], defaultOptionsNullPath: nullPath)) {
      final path = (option["path"] as List).map((e) => e as String).toList();
      final value = option["value"];

      // もしパスが途中で途切れていたら、その奥は直接コピーする
      if (!hasPath(result, path)) {
        for (var i = 0; i < path.length; i++) {
          final checkPath = path.sublist(0, i + 1);

          if (!hasPath(result, checkPath)) {
            final resultPath = checkPath.sublist(0, checkPath.length - 1);

            if (getPath(result, resultPath) == null) {
              resultPath.removeLast();
              var object = resultPath.fold(
                  result, (acc, key) => (acc! as Map<String, dynamic>)[key]);
              final adjustPath = path.sublist(i - 1, path.length);
              final key = adjustPath.removeLast();
              object = setPath(object, adjustPath, {key: value});
              break;
            } else {
              var object = resultPath.fold(
                  result, (acc, key) => (acc! as Map<String, dynamic>)[key]);
              object = setPath(object, path.sublist(i, path.length), value);
              break;
            }
          }
        }
      } else {
        result = Map<String, dynamic>.from(setPath(result, path, value));
      }
    }
    return result;
  }
}

List<List<String>> getNullPath(Map<String, dynamic> object,
    {List<String> path = const []}) {
  final List<List<String>> result = [];
  for (final key in object.keys) {
    final value = object[key];
    final newPath = [...path, key];
    if (value is Map<String, dynamic>) {
      result.addAll(getNullPath(value, path: newPath));
    } else if (value == null) {
      result.add(newPath);
    }
  }
  return result;
}

List<Map<String, dynamic>> getValuesWithPath(Map<String, dynamic> object,
    {List<String> path = const [],
    List<List<String>> defaultOptionsNullPath = const []}) {
  final List<Map<String, dynamic>> result = [];
  for (final key in object.keys) {
    final value = object[key];
    final newPath = [...path, key];
    if (defaultOptionsNullPath.isNotEmpty) {
      if (defaultOptionsNullPath.any((p) =>
          newPath.length == p.length &&
          p
              .asMap()
              .entries
              .every((entry) => entry.value == newPath[entry.key]))) {
        result.add({"path": newPath, "value": value});
        continue;
      }
    }
    if (value is Map<String, dynamic>) {
      result.addAll(getValuesWithPath(value,
          path: newPath, defaultOptionsNullPath: defaultOptionsNullPath));
    } else {
      result.add({"path": newPath, "value": value});
    }
  }
  return result;
}

dynamic getPath(Map<String, dynamic> object, List<String> path) {
  dynamic result = object;
  for (final key in path) {
    if (!result.containsKey(key)) {
      return null;
    }
    result = result[key];
  }
  return result;
}

bool hasPath(Map<String, dynamic> object, List<String> path) {
  dynamic result = object;
  for (final key in path) {
    if (result is! Map<String, dynamic>) return false;
    if (!result.containsKey(key)) {
      return false;
    }
    result = result[key];
  }
  return true;
}

dynamic setPath(dynamic object, List<String> path, dynamic value, [int i = 0]) {
  if (i == path.length) {
    return value;
  } else {
    if (object is! Map) {
      object = {};
    }

    object = Map<dynamic, dynamic>.from(object);
    object[path[i]] = setPath(object[path[i]], path, value, ++i);
    return object;
  }
}
