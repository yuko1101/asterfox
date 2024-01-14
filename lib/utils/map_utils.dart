class MapUtils {
  // https://github.com/yuko1101/ConfigFile.js/blob/main/src/utils.ts
  static Map<String, dynamic> bindOptions(
      Map<String, dynamic> baseOptions, Map<String, dynamic> options) {
    var result = {...baseOptions};

    final defaultKeys = result.keys;

    for (final key in options.keys) {
      final value = options[key];
      if (!defaultKeys.contains(key)) {
        // since the key is not in the default options, just add it
        result[key] = value;
        continue;
      }
      // check if the value is an pure object
      final defaultValue = result[key];
      if (value is Map<String, dynamic> &&
          defaultValue is Map<String, dynamic>) {
        result[key] = bindOptions(defaultValue, value);
      } else {
        result[key] = value;
      }
    }

    return result;
  }
}
