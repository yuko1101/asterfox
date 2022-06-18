import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class SingleNotifierWidget<T> extends StatelessWidget {
  const SingleNotifierWidget({
    required this.notifier,
    required this.builder,
    Key? key,
  }) : super(key: key);

  final ValueListenable<T> notifier;
  final Widget Function(BuildContext, T, Widget?) builder;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<T>(
      valueListenable: notifier,
      builder: builder,
    );
  }
}

class DoubleNotifierWidget<T, U> extends StatelessWidget {
  const DoubleNotifierWidget({
    required this.notifier1,
    required this.notifier2,
    required this.builder,
    Key? key,
  }) : super(key: key);

  final ValueListenable<T> notifier1;
  final ValueListenable<U> notifier2;
  final Widget Function(BuildContext, T, U, Widget?) builder;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<T>(
      valueListenable: notifier1,
      builder: (context, value1, child) {
        return ValueListenableBuilder<U>(
          valueListenable: notifier2,
          builder: (context, value2, child) {
            return builder(context, value1, value2, child);
          },
        );
      },
    );
  }
}

class TripleNotifierWidget<T, U, V> extends StatelessWidget {
  const TripleNotifierWidget({
    required this.notifier1,
    required this.notifier2,
    required this.notifier3,
    required this.builder,
    Key? key,
  }) : super(key: key);

  final ValueListenable<T> notifier1;
  final ValueListenable<U> notifier2;
  final ValueListenable<V> notifier3;
  final Widget Function(BuildContext, T, U, V, Widget?) builder;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<T>(
      valueListenable: notifier1,
      builder: (context, value1, child) {
        return ValueListenableBuilder<U>(
          valueListenable: notifier2,
          builder: (context, value2, child) {
            return ValueListenableBuilder<V>(
              valueListenable: notifier3,
              builder: (context, value3, child) {
                return builder(context, value1, value2, value3, child);
              },
            );
          },
        );
      },
    );
  }
}

class QuadNotifierWidget<T, U, V, W> extends StatelessWidget {
  const QuadNotifierWidget({
    required this.notifier1,
    required this.notifier2,
    required this.notifier3,
    required this.notifier4,
    required this.builder,
    Key? key,
  }) : super(key: key);

  final ValueListenable<T> notifier1;
  final ValueListenable<U> notifier2;
  final ValueListenable<V> notifier3;
  final ValueListenable<W> notifier4;
  final Widget Function(BuildContext, T, U, V, W, Widget?) builder;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<T>(
      valueListenable: notifier1,
      builder: (context, value1, child) {
        return ValueListenableBuilder<U>(
          valueListenable: notifier2,
          builder: (context, value2, child) {
            return ValueListenableBuilder<V>(
              valueListenable: notifier3,
              builder: (context, value3, child) {
                return ValueListenableBuilder<W>(
                  valueListenable: notifier4,
                  builder: (context, value4, child) {
                    return builder(
                        context, value1, value2, value3, value4, child);
                  },
                );
              },
            );
          },
        );
      },
    );
  }
}

class QuintNotifierWidget<T, U, V, W, X> extends StatelessWidget {
  const QuintNotifierWidget({
    required this.notifier1,
    required this.notifier2,
    required this.notifier3,
    required this.notifier4,
    required this.notifier5,
    required this.builder,
    Key? key,
  }) : super(key: key);

  final ValueListenable<T> notifier1;
  final ValueListenable<U> notifier2;
  final ValueListenable<V> notifier3;
  final ValueListenable<W> notifier4;
  final ValueListenable<X> notifier5;
  final Widget Function(BuildContext, T, U, V, W, X, Widget?) builder;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<T>(
      valueListenable: notifier1,
      builder: (context, value1, child) {
        return ValueListenableBuilder<U>(
          valueListenable: notifier2,
          builder: (context, value2, child) {
            return ValueListenableBuilder<V>(
              valueListenable: notifier3,
              builder: (context, value3, child) {
                return ValueListenableBuilder<W>(
                  valueListenable: notifier4,
                  builder: (context, value4, child) {
                    return ValueListenableBuilder<X>(
                      valueListenable: notifier5,
                      builder: (context, value5, child) {
                        return builder(context, value1, value2, value3, value4,
                            value5, child);
                      },
                    );
                  },
                );
              },
            );
          },
        );
      },
    );
  }
}
