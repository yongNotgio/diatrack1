import 'package:flutter/material.dart';

class OverviewCards extends StatelessWidget {
  final double avgGlucose;
  final double avgSystolic;
  final double avgDiastolic;
  final String riskClassification;

  const OverviewCards({
    Key? key,
    required this.avgGlucose,
    required this.avgSystolic,
    required this.avgDiastolic,
    required this.riskClassification,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 0.95,
      children: [
        _OverviewCard(
          title: 'Blood\nGlucose',
          value: avgGlucose.toStringAsFixed(1),
          unit: 'mg/dL',
          color: const Color(0xFFAC191F),
          backgroundColor: const Color(0xFFFFE5E6),
          label: 'AVG',
        ),
        _OverviewCard(
          title: 'BP\nSystolic',
          value: avgSystolic.toStringAsFixed(1),
          unit: 'mmHg',
          color: const Color(0xFF199DAC),
          backgroundColor: const Color(0xFFE5FCFF),
          label: 'AVG',
        ),
        _OverviewCard(
          title: 'BP\nDiastolic',
          value: avgDiastolic.toStringAsFixed(1),
          unit: 'mmHg',
          color: const Color(0xFF19AC4A),
          backgroundColor: const Color(0xFFE5FFEE),
          label: 'AVG',
        ),
        _OverviewCard(
          title: 'Risk\nClassification',
          value: riskClassification.toUpperCase(),
          unit: 'Surgical Risk',
          color: const Color(0xFF7619AC),
          backgroundColor: const Color(0xFFF6E5FF),
          label: 'MODE',
        ),
      ],
    );
  }
}

class _OverviewCard extends StatelessWidget {
  final String title;
  final String value;
  final String unit;
  final Color color;
  final Color? backgroundColor;
  final String? label;

  const _OverviewCard({
    required this.title,
    required this.value,
    required this.unit,
    required this.color,
    this.backgroundColor,
    this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: backgroundColor ?? Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(14.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (label != null)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: color,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      label!,
                      style: const TextStyle(
                        fontSize: 10,
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontFamily: 'Poppins',
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                const SizedBox(height: 4),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 21,
                    color: color,
                    fontWeight: FontWeight.w500,
                    fontFamily: 'Poppins',
                    height: 1.0,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.visible,
                ),
              ],
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    value,
                    style: TextStyle(
                      fontSize: 52,
                      fontWeight: FontWeight.w700,
                      color: color,
                      fontFamily: 'Poppins',
                      height: 0.95,
                    ),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  unit,
                  style: TextStyle(
                    fontSize: 13,
                    color: color,
                    fontWeight: FontWeight.w400,
                    fontFamily: 'Poppins',
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
