import 'package:flutter/material.dart';

class NumberWeeklyProgressChart extends StatelessWidget {
  const NumberWeeklyProgressChart({
	  super.key,
	  required this.dailyValues,
	  required this.todayIndex,
	  required this.unit,
	});

  final List<double> dailyValues;
  final String unit;
  final int todayIndex;

  static const _dayLabels = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
  
  static String _formatAxis(double value, String unit) {
	  if (value == value.roundToDouble()) {
	    return '${value.toInt()}$unit';
	  }

	  return '${value.toStringAsFixed(1)}$unit';
	}

  @override
  Widget build(BuildContext context) {
    final maximumValue = dailyValues.fold<double>(
	  0,
	  (maximum, value) => value > maximum ? value : maximum,
	);
    final colorScheme = Theme.of(context).colorScheme;

    final maxValue = maximumValue;

	final midValue = maximumValue / 2;

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
			    _formatAxis(maxValue, unit),
			    style: const TextStyle(fontSize: 11),
			  ),

			  Text(
			    _formatAxis(midValue, unit),
			    style: const TextStyle(fontSize: 11),
			  ),

			  Text(
  				_formatAxis(0, unit),
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
			      color: Colors.grey.withValues(alpha: 0.15),
			      height: 1,
			      thickness: 1,
			    ),
			    Divider(
			      color: Colors.grey.withValues(alpha: 0.15),
			      height: 1,
			      thickness: 1,
			    ),
			    Divider(
			      color: Colors.grey.withValues(alpha: 0.15),
			      height: 1,
			      thickness: 1,
			    ),
			  ],
			),
		      ),

		      Row(
			crossAxisAlignment: CrossAxisAlignment.stretch,
			children: List.generate(dailyValues.length, (index) {
			  final value = dailyValues[index];

			  final heightFactor = maximumValue == 0
				    ? 0.0
				    : value / maximumValue;

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
