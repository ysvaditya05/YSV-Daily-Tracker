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
  
  static String _formatAxis(Duration duration) {
	  final hours = duration.inHours;
	  final minutes = duration.inMinutes.remainder(60);

	  if (hours == 0 && minutes == 0) {
	    return '0m';
	  }

	  if (hours == 0) {
	    return '${minutes}m';
	  }

	  if (minutes == 0) {
	    return '${hours}h';
	  }

	  return '${hours}h ${minutes}m';
	}

  @override
  Widget build(BuildContext context) {
    final maximumDuration = dailyDurations.fold<Duration>(
      Duration.zero,
      (maximum, duration) => duration > maximum ? duration : maximum,
    );
    final colorScheme = Theme.of(context).colorScheme;

    final maxDuration = maximumDuration;

	final midDuration = Duration(
	  seconds: maximumDuration.inSeconds ~/ 2,
	);

	return SizedBox(
	  height: 180,
	  child: Row(
	    crossAxisAlignment: CrossAxisAlignment.stretch,
	    children: [

	      // ---------- Y AXIS ----------
	      SizedBox(
		width: 52,
		child: Column(
		  mainAxisAlignment: MainAxisAlignment.spaceBetween,
		  crossAxisAlignment: CrossAxisAlignment.end,
		  children: [
			  Text(
			    _formatAxis(maxDuration),
			    style: const TextStyle(fontSize: 11),
			  ),

			  Text(
			    _formatAxis(midDuration),
			    style: const TextStyle(fontSize: 11),
			  ),

			  const Text(
			    '0m',
			    style: TextStyle(fontSize: 11),
			  ),
			],
		),
	      ),

	      const SizedBox(width: 8),

	      // ---------- GRAPH ----------
	      Expanded(
		  child: Stack(
		    children: [

		      // Horizontal guide lines
		      Positioned.fill(
			child: Column(
			  mainAxisAlignment: MainAxisAlignment.spaceBetween,
			  children: [
			    Divider(
			      color: Colors.grey.withOpacity(0.15),
			      height: 1,
			      thickness: 1,
			    ),
			    Divider(
			      color: Colors.grey.withOpacity(0.15),
			      height: 1,
			      thickness: 1,
			    ),
			    Divider(
			      color: Colors.grey.withOpacity(0.15),
			      height: 1,
			      thickness: 1,
			    ),
			  ],
			),
		      ),

		      Row(
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
		    ],
		  ),
		),
	    ],
	  ),
	);
  }
}
