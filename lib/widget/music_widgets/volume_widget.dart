import 'dart:math';

import 'package:asterfox/data/custom_colors.dart';
import 'package:asterfox/main.dart';
import 'package:asterfox/system/theme/theme.dart';
import 'package:asterfox/utils/math.dart';
import 'package:asterfox/widget/notifiers_widget.dart';
import 'package:flutter/material.dart';

final _tween = Tween<double>(begin: 0, end: 1);

class VolumeWidget extends StatefulWidget {
  const VolumeWidget({Key? key}) : super(key: key);

  static IconData getVolumeIcon(double volume, bool mute) {
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
  static const num base = 3;

  @override
  State<VolumeWidget> createState() => _VolumeWidgetState();
}

class _VolumeWidgetState extends State<VolumeWidget> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  late Animation<double> _progress;

  double _sliderValue = 0;

  @override
  void initState() {
    super.initState();
    _sliderValue = MathUtils.log(musicManager.audioDataManager.volume, VolumeWidget.base);
    _controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this
    );
    _progress = _controller.drive(_tween);
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
        builder: (context, _) => DoubleNotifierWidget<double, bool>(
            notifier1: musicManager.baseVolumeNotifier,
            notifier2: musicManager.muteNotifier,
            builder: (context, volume, mute, child) {
              // animation is not started yet
              if (_progress.value == 0) {
                // TODO: fix that onPressed ripple doesn't work
                return InkWell(
                  onLongPress: () {
                    musicManager.setMute(!mute);
                  },
                  onTap: () {},
                  child: FloatingActionButton(
                    onPressed: _controller.forward,
                    child: Icon(VolumeWidget.getVolumeIcon(volume, mute)),
                    backgroundColor: Theme.of(context).backgroundColor,
                    foregroundColor: Theme.of(context).extraColors.primary,
                  ),
                );
              }
              // animation is started
              else {
                return Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      margin: const EdgeInsets.only(bottom: 5),
                      height: _progress.value * 120,
                      width: 50,
                      decoration: BoxDecoration(
                        color: Theme.of(context).backgroundColor,
                        borderRadius: BorderRadius.circular(40),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.3),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          )
                        ]
                      ),
                      child: RotatedBox(
                        quarterTurns: 3,
                        child: Slider(
                          value: _sliderValue,
                          max: 1,
                          min: -1,
                          thumbColor: CustomColors.getColor("accent"),
                          activeColor: CustomColors.getColor("accent"),
                          inactiveColor: CustomColors.getColor("accent").withOpacity(0.2),
                          onChanged: (value) {
                            setState(() {
                              _sliderValue = value;
                            });
                          },
                          onChangeEnd: (value) {
                            if (value == -1) {
                              musicManager.setMute(true);
                              return;
                            }
                            musicManager.setBaseVolume(pow(VolumeWidget.base, value).toDouble());
                          },
                        ),
                      ),
                    ),
                    FloatingActionButton(
                      onPressed: _controller.reverse,
                      child: Icon(VolumeWidget.getVolumeIcon(volume, mute)),
                      backgroundColor: Theme.of(context).backgroundColor,
                      foregroundColor: Theme.of(context).extraColors.primary,
                    ),
                  ],
                );
              }
            }
        ),
    );
  }
}