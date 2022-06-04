final List<String> logs = [];

void log(dynamic string) {
  logs.add(string.toString());
  print(string.toString());
}