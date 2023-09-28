import 'package:flutter/material.dart';

class NonNullStreamBuilder<T> extends StatefulWidget {
  const NonNullStreamBuilder({
    required this.stream,
    required this.initialData,
    required this.builder,
    super.key,
  });

  final Stream<T> stream;
  final T initialData;
  final Widget Function(BuildContext, T) builder;

  @override
  State<NonNullStreamBuilder> createState() => _NonNullStreamBuilderState<T>();
}

class _NonNullStreamBuilderState<T> extends State<NonNullStreamBuilder<T>> {
  late T _data;

  @override
  void initState() {
    super.initState();
    _data = widget.initialData;

    widget.stream.listen((data) {
      setState(() {
        _data = data;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return widget.builder(context, _data);
  }
}
