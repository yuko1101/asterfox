import 'dart:async';

class BubbleSort<T> {
  BubbleSort({
    required this.move,
    required this.compare,
  });
  final FutureOr<List<T>> Function(int, int) move;
  final int Function(T, T) compare;

  FutureOr<List<T>> sort(List<T> list, [int Function(T)? corrector]) async {
    List<T> result = list;
    for (int i = 0; i < result.length - 1; i++) {
      for (int j = i + 1; j < result.length; j++) {
        // if (correct != null) {
        //   print(result.map(correct).map((e) {
        //     final index = result.map(correct).toList().indexOf(e);
        //     return (index == i || index == j) ? ">$e<" : "$e";
        //   }));
        // }
        if (compare(result[i], result[j]) > 0) {
          // print("change ($i, $j) => ${compare(result[i], result[j])}");
          result = await move(j, i);
        }
      }
    }
    return result;
  }

  FutureOr<List<T>> sortWithCorrector(
      List<T> list, int Function(T) corrector) async {
    List<T> result = list;
    for (int i = 0; i < result.length - 1; i++) {
      for (int j = i + 1; j < result.length; j++) {
        // print(result.map(correct).map((e) {
        //   final index = result.map(correct).toList().indexOf(e);
        //   return (index == i || index == j) ? ">$e<" : "$e";
        // }));
        if (corrector(result[i]) > corrector(result[j])) {
          // print("change ($i, $j) => ${correct(result[i])} > ${correct(result[j])}");
          result = await move(j, i);
        }
      }
    }
    return result;
  }
}
