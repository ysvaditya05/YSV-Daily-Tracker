import 'package:flutter/material.dart';

class WeeklyProgressChart extends StatelessWidget {
  const WeeklyProgressChart({
    super.key,
    required this.dailyDurations,
    required this.todayIndex,
  });

  final List<Duration> dailyDurations;
  final int todayIndex;

  static const _dayLabels = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

  @override
  Widget build(BuildContext context) {
    final maximumDuration = dailyDurations.fold<Duration>(
      Duration.zero,
      (maximum, duration) => duration > maximum ? duration : maximum,
    );
    final colorScheme = Theme.of(context).colorScheme;

    return SizedBox(
      height: 180,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: List.generate(dailyDurations.length, (index) {
          final duration = dailyDurations[index];
          final heightFactor = maximumDuration == Duration.zero
              ? 0.0
              : duration.inSeconds / maximumDuration.inSeconds;

          return Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Column(
                children: [
                  Expanded(
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        return Align(
                          alignment: Alignment.bottomCenter,
                          child: Container(
                            width: 20,
                            height: constraints.maxHeight * heightFactor,
                            decoration: BoxDecoration(
                              color: index == todayIndex
                                  ? colorScheme.primary
                                  : colorScheme.primaryContainer,
                              borderRadius: const BorderRadius.vertical(
                                top: Radius.circular(4),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(_dayLabels[index]),
                ],
              ),
            ),
          );
        }),
      ),
    );
  }
}
