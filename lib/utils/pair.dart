class Pair<T, U> {
  Pair(this.first, this.second);

  final T first;
  final U second;

  @override
  String toString() => 'Pair[$first, $second]';
}
