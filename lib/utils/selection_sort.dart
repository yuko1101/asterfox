class SelectionSort<T> {
  /// `move` is just a move function, not a swap function.
  SelectionSort({
    required this.move,
  });
  final dynamic Function(int, int) move;

  Future<void> sort(List<T> list, int Function(T, T) compare,
      [int Function(T)? corrector]) async {
    final dummyList = [...list];
    for (int i = 0; i < dummyList.length - 1; i++) {
      T itemToMove = dummyList[i];
      int itemIndex = i;
      for (int j = i + 1; j < dummyList.length; j++) {
        if (corrector != null) {
          print(dummyList.map(corrector).map((e) {
            final index = dummyList.map(corrector).toList().indexOf(e);
            return (index == itemIndex || index == j) ? ">$e<" : "$e";
          }));
        }
        if (compare(itemToMove, dummyList[j]) > 0) {
          itemToMove = dummyList[j];
          itemIndex = j;
        }
      }
      if (itemIndex == i) continue;
      await move(itemIndex, i);
      final temp = dummyList.removeAt(itemIndex);
      dummyList.insert(i, temp);
    }
  }

  Future<void> sortWithCorrector(
    List<T> list,
    int Function(T) corrector,
  ) async {
    final dummyList = [...list];

    for (int i = 0; i < dummyList.length - 1; i++) {
      final currentIndex =
          dummyList.indexWhere((element) => corrector(element) == i);
      await move(currentIndex, i);
      final temp = dummyList.removeAt(currentIndex);
      dummyList.insert(i, temp);
    }
  }
}
