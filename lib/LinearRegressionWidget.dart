import 'package:flutter/material.dart';
import 'dart:math';
import 'dart:ui';

class LinearRegressionWidget extends StatelessWidget {
  final List<double> xValues;
  final List<double> yValues;

  LinearRegressionWidget({required this.xValues, required this.yValues});

  @override
  Widget build(BuildContext context) {
    double slope = calculateSlope(xValues, yValues);
    double intercept = calculateIntercept(xValues, yValues, slope);

    return Scaffold(
      appBar: AppBar(
        title: Text('Linear Regression'),
      ),
      body: Container(
        height: MediaQuery.of(context).size.height, // Set height to full screen height
        child: CustomPaint(
          size: Size.infinite,
          painter: RegressionPainter(
            xValues: xValues,
            yValues: yValues,
            slope: slope,
            intercept: intercept,
          ),
        ),
      ),
    );
  }

  double calculateSlope(List<double> xValues, List<double> yValues) {
    double sumXY = 0;
    double sumX = 0;
    double sumY = 0;
    double sumXSquare = 0;

    for (int i = 0; i < xValues.length; i++) {
      sumXY += xValues[i] * yValues[i];
      sumX += xValues[i];
      sumY += yValues[i];
      sumXSquare += pow(xValues[i], 2);
    }

    return ((xValues.length * sumXY) - (sumX * sumY)) /
        ((xValues.length * sumXSquare) - pow(sumX, 2));
  }

  double calculateIntercept(
      List<double> xValues, List<double> yValues, double slope) {
    double sumX = 0;
    double sumY = 0;

    for (int i = 0; i < xValues.length; i++) {
      sumX += xValues[i];
      sumY += yValues[i];
    }

    return (sumY - (slope * sumX)) / xValues.length;
  }
}

class RegressionPainter extends CustomPainter {
  final List<double> xValues;
  final List<double> yValues;
  final double slope;
  final double intercept;

  RegressionPainter(
      {required this.xValues,
        required this.yValues,
        required this.slope,
        required this.intercept});

  @override
  void paint(Canvas canvas, Size size) {
    Paint pointPaint = Paint()
      ..color = Colors.blue
      ..strokeWidth = 5
      ..strokeCap = StrokeCap.round;

    Paint linePaint = Paint()
      ..color = Colors.red
      ..strokeWidth = 3;

    for (int i = 0; i < xValues.length; i++) {
      canvas.drawPoints(PointMode.points, [Offset(xValues[i], yValues[i])], pointPaint);
    }

    double startX = xValues.reduce((a, b) => a < b ? a : b);
    double endX = xValues.reduce((a, b) => a > b ? a : b);
    double startY = slope * startX + intercept;
    double endY = slope * endX + intercept;

    canvas.drawLine(
        Offset(startX, startY), Offset(endX, endY), linePaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return false;
  }
}
