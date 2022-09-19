import 'dart:math';

import 'package:flutter/material.dart';

import '../../data/custom_colors.dart';
import '../../main.dart';
import '../../system/theme/theme.dart';
import '../../utils/math.dart';
import '../notifiers_widget.dart';

final _tween = Tween<double>(begin: 0, end: 1);

class VolumeWidget extends StatefulWidget {
  VolumeWidget({Key? key}) : super(key: key);

  static IconData getVolumeIcon(num volume, bool mute) {
    if (volume == 0 || mute) {
      return Icons.volume_off;
    } else if (volume < 1) {
      return Icons.volume_down;
    } else {
      return Icons.volume_up;
    }
  }

  // if the base is 2,
  // when moved the volume slider, the volume is set to 2^x, where x is the value of the slider.
  // when get the slider position, the position is log2(volume).
  static const num base = 4;

  static const double max = 1.0;
  static const double min = -1.0;

  final ValueNotifier<bool> openedNotifier = ValueNotifier(false);

  @override
  State<VolumeWidget> createState() => VolumeWidgetState();
}

class VolumeWidgetState extends State<VolumeWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  late Animation<double> _progress;

  double _sliderValue = 0;

  void close() {
    _controller.reverse();
  }

  @override
  void initState() {
    super.initState();

    _sliderValue =
        MathUtils.log(musicManager.baseVolumeNotifier.value, VolumeWidget.base);
    _sliderValue = max(_sliderValue, VolumeWidget.min);
    _sliderValue = min(_sliderValue, VolumeWidget.max);

    _controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _progress = _controller.drive(_tween);

    _controller.addListener(() {
      if (_controller.isAnimating) {
        widget.openedNotifier.value = _controller.velocity >= 0;
      } else {
        widget.openedNotifier.value = _controller.isCompleted;
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _progress,
      builder: (context, _) => DoubleNotifierWidget<num, bool>(
        notifier1: musicManager.baseVolumeNotifier,
        notifier2: musicManager.muteNotifier,
        builder: (context, volume, mute, child) {
          return Column(
            mainAxisAlignment: MainAxisAlignment.end,
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                margin: const EdgeInsets.only(bottom: 5),
                height: _progress.value * 120,
                width: 55,
                decoration: BoxDecoration(
                  color: Theme.of(context).backgroundColor,
                  borderRadius: BorderRadius.circular(40),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.3),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: (_progress.value > 0.4)
                    ? RotatedBox(
                        quarterTurns: 3,
                        child: Slider(
                          value: _sliderValue,
                          max: VolumeWidget.max,
                          min: VolumeWidget.min,
                          thumbColor: CustomColors.getColor("accent"),
                          activeColor: CustomColors.getColor("accent"),
                          inactiveColor:
                              CustomColors.getColor("accent").withOpacity(0.2),
                          onChanged: (value) {
                            setState(() {
                              _sliderValue = value;
                            });
                          },
                          onChangeStart: (value) {
                            musicManager.setMute(false);
                          },
                          onChangeEnd: (value) {
                            musicManager.setBaseVolume(
                                pow(VolumeWidget.base, value).toDouble());
                          },
                        ),
                      )
                    : null,
              ),
              InkWell(
                onDoubleTap: () {
                  musicManager.setMute(!mute);
                },
                onTap: () {},
                child: FloatingActionButton(
                  onPressed: _progress.value == 0
                      ? _controller.forward
                      : _controller.reverse,
                  child: Icon(VolumeWidget.getVolumeIcon(volume, mute)),
                  backgroundColor: Theme.of(context).backgroundColor,
                  foregroundColor: Theme.of(context).extraColors.primary,
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
