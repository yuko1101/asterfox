import 'dart:async';

class BubbleSort<T> {
  /// `move` is just a move function, not a swap function.
  BubbleSort({
    required this.move,
  });
  final dynamic Function(int, int) move;

  Future<void> sort(List<T> list, int Function(T, T) compare,
      [int Function(T)? corrector]) async {
    for (int i = 0; i < list.length - 1; i++) {
      for (int j = i + 1; j < list.length; j++) {
        // if (correct != null) {
        //   print(list.map(correct).map((e) {
        //     final index = list.map(correct).toList().indexOf(e);
        //     return (index == i || index == j) ? ">$e<" : "$e";
        //   }));
        // }
        if (compare(list[i], list[j]) > 0) {
          // print("change ($i, $j) => ${compare(result[i], result[j])}");
          await move(j, i);
        }
      }
    }
  }

  Future<void> sortWithCorrector(
    List<T> list,
    int Function(T) corrector,
  ) async {
    final dummyList = [...list];

    for (int i = 0; i < dummyList.length - 1; i++) {
      for (int j = i + 1; j < dummyList.length; j++) {
        // print(dummyList.map(corrector).map((correctIndex) {
        //   final currentIndex =
        //       dummyList.map(corrector).toList().indexOf(correctIndex);
        //   return (currentIndex == i || currentIndex == j)
        //       ? ">$correctIndex<"
        //       : "$correctIndex";
        // }));
        if (corrector(dummyList[i]) > corrector(dummyList[j])) {
          await move(j, i);
          final temp = dummyList.removeAt(j);
          dummyList.insert(i, temp);
        }
      }
    }
  }
}
