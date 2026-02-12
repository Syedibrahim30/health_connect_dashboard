import 'package:flutter/material.dart';

import '../../core/constants/app_constants.dart';
import '../../core/utils/date_utils.dart' as app_date_utils;
import '../../domain/entities/chart_data.dart';

class HealthChartPainter extends CustomPainter {
  final ChartData data;
  final Color lineColor;
  final Color fillColor;
  final Color gridColor;
  final String title;
  final double translateX;
  final double translateY;
  final double scaleX;
  final double scaleY;
  final Offset? tooltipPosition;

  // Reusable paint objects to avoid per-frame allocations
  late final Paint _linePaint;
  late final Paint _fillPaint;
  late final Paint _gridPaint;
  late final Paint _tooltipPaint;
  late final TextPainter _textPainter;

  HealthChartPainter({
    required this.data,
    required this.lineColor,
    required this.fillColor,
    required this.gridColor,
    required this.title,
    this.translateX = 0.0,
    this.translateY = 0.0,
    this.scaleX = 1.0,
    this.scaleY = 1.0,
    this.tooltipPosition,
  }) {
    // Initialize reusable paint objects
    _linePaint = Paint()
      ..color = lineColor
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    _fillPaint = Paint()
      ..color = fillColor.withOpacity(0.2)
      ..style = PaintingStyle.fill;

    _gridPaint = Paint()
      ..color = gridColor
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;

    _tooltipPaint = Paint()
      ..color = AppConstants.tooltipBackground
      ..style = PaintingStyle.fill;

    _textPainter = TextPainter(
      textAlign: TextAlign.left,
      textDirection: TextDirection.ltr,
    );
  }

  @override
  void paint(Canvas canvas, Size size) {
    final stopwatch = Stopwatch()..start();

    if (data.points.isEmpty) {
      _drawEmptyState(canvas, size);
      return;
    }

    // Apply transformations
    canvas.save();
    canvas.translate(translateX, translateY);
    canvas.scale(scaleX, scaleY);

    // Draw grid
    _drawGrid(canvas, size);

    // Draw chart
    _drawChart(canvas, size);

    // Draw axes labels
    _drawAxes(canvas, size);

    canvas.restore();

    // Draw tooltip (outside transform)
    if (tooltipPosition != null) {
      _drawTooltip(canvas, size, tooltipPosition!);
    }

    stopwatch.stop();
    // Note: In production, we'd send this to PerformanceController
    // print('Paint time: ${stopwatch.elapsedMilliseconds}ms');
  }

  void _drawEmptyState(Canvas canvas, Size size) {
    _textPainter.text = const TextSpan(
      text: 'No data available',
      style: TextStyle(color: Colors.grey, fontSize: 16),
    );
    _textPainter.layout();
    _textPainter.paint(
      canvas,
      Offset(
        (size.width - _textPainter.width) / 2,
        (size.height - _textPainter.height) / 2,
      ),
    );
  }

  void _drawGrid(Canvas canvas, Size size) {
    const padding = 40.0;
    final chartWidth = size.width - padding * 2;
    final chartHeight = size.height - padding * 2;

    // Horizontal grid lines
    for (int i = 0; i <= 4; i++) {
      final y = padding + (chartHeight / 4) * i;
      canvas.drawLine(
        Offset(padding, y),
        Offset(size.width - padding, y),
        _gridPaint,
      );
    }

    // Vertical grid lines
    for (int i = 0; i <= 6; i++) {
      final x = padding + (chartWidth / 6) * i;
      canvas.drawLine(
        Offset(x, padding),
        Offset(x, size.height - padding),
        _gridPaint,
      );
    }
  }

  void _drawChart(Canvas canvas, Size size) {
    const padding = 40.0;
    final chartWidth = size.width - padding * 2;
    final chartHeight = size.height - padding * 2;

    if (data.points.isEmpty) return;

    final path = Path();
    final fillPath = Path();

    // Calculate scales
    final timeRange = data.endTime
        .difference(data.startTime)
        .inMilliseconds
        .toDouble();
    final valueRange = data.maxValue - data.minValue;

    if (timeRange == 0 || valueRange == 0) return;

    // Build paths
    bool isFirst = true;
    for (final point in data.points) {
      final timeDiff = point.timestamp
          .difference(data.startTime)
          .inMilliseconds;
      final x = padding + (timeDiff / timeRange) * chartWidth;
      final y =
          size.height -
          padding -
          ((point.value - data.minValue) / valueRange) * chartHeight;

      if (isFirst) {
        path.moveTo(x, y);
        fillPath.moveTo(x, size.height - padding);
        fillPath.lineTo(x, y);
        isFirst = false;
      } else {
        path.lineTo(x, y);
        fillPath.lineTo(x, y);
      }
    }

    // Complete fill path
    final lastPoint = data.points.last;
    final lastTimeDiff = lastPoint.timestamp
        .difference(data.startTime)
        .inMilliseconds;
    final lastX = padding + (lastTimeDiff / timeRange) * chartWidth;
    fillPath.lineTo(lastX, size.height - padding);
    fillPath.close();

    // Draw fill
    canvas.drawPath(fillPath, _fillPaint);

    // Draw line
    canvas.drawPath(path, _linePaint);
  }

  void _drawAxes(Canvas canvas, Size size) {
    const padding = 40.0;
    final chartHeight = size.height - padding * 2;

    // Y-axis labels
    for (int i = 0; i <= 4; i++) {
      final value = data.minValue + (data.maxValue - data.minValue) / 4 * i;
      final y = size.height - padding - (chartHeight / 4) * i;

      _textPainter.text = TextSpan(
        text: value.toStringAsFixed(0),
        style: const TextStyle(color: Colors.grey, fontSize: 10),
      );
      _textPainter.layout();
      _textPainter.paint(canvas, Offset(5, y - _textPainter.height / 2));
    }

    // X-axis labels (time)
    for (int i = 0; i <= 3; i++) {
      final timeFraction = i / 3.0;
      final time = data.startTime.add(
        Duration(
          milliseconds:
              (data.endTime.difference(data.startTime).inMilliseconds *
                      timeFraction)
                  .toInt(),
        ),
      );

      _textPainter.text = TextSpan(
        text: app_date_utils.DateUtils.formatChartTime(time),
        style: const TextStyle(color: Colors.grey, fontSize: 10),
      );
      _textPainter.layout();

      final x = padding + (size.width - padding * 2) * timeFraction;
      _textPainter.paint(
        canvas,
        Offset(x - _textPainter.width / 2, size.height - padding + 5),
      );
    }
  }

  void _drawTooltip(Canvas canvas, Size size, Offset position) {
    const padding = 40.0;
    final chartWidth = size.width - padding * 2;

    // Find nearest point
    final timeRange = data.endTime
        .difference(data.startTime)
        .inMilliseconds
        .toDouble();
    final relativeX = (position.dx - padding).clamp(0.0, chartWidth);
    final timeFraction = relativeX / chartWidth;
    final targetTime = data.startTime.add(
      Duration(milliseconds: (timeRange * timeFraction).toInt()),
    );

    ChartDataPoint? nearestPoint;
    double minDistance = double.infinity;

    for (final point in data.points) {
      final distance = (point.timestamp.difference(targetTime).inMilliseconds)
          .abs()
          .toDouble();
      if (distance < minDistance) {
        minDistance = distance;
        nearestPoint = point;
      }
    }

    if (nearestPoint == null) return;

    // Draw tooltip
    final tooltipText =
        '${nearestPoint.value.toStringAsFixed(1)}\n'
        '${app_date_utils.DateUtils.formatChartTime(nearestPoint.timestamp)}';

    _textPainter.text = TextSpan(
      text: tooltipText,
      style: const TextStyle(color: Colors.white, fontSize: 12),
    );
    _textPainter.layout();

    final tooltipWidth = _textPainter.width + 16;
    final tooltipHeight = _textPainter.height + 16;

    var tooltipX = position.dx - tooltipWidth / 2;
    var tooltipY = position.dy - tooltipHeight - 10;

    // Keep tooltip in bounds
    tooltipX = tooltipX.clamp(0.0, size.width - tooltipWidth);
    tooltipY = tooltipY.clamp(0.0, size.height - tooltipHeight);

    final tooltipRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(tooltipX, tooltipY, tooltipWidth, tooltipHeight),
      const Radius.circular(4),
    );

    canvas.drawRRect(tooltipRect, _tooltipPaint);
    _textPainter.paint(canvas, Offset(tooltipX + 8, tooltipY + 8));

    // Draw pointer to data point
    final pointX =
        padding +
        (nearestPoint.timestamp.difference(data.startTime).inMilliseconds /
                timeRange) *
            chartWidth;
    final pointY =
        size.height -
        padding -
        ((nearestPoint.value - data.minValue) /
                (data.maxValue - data.minValue)) *
            (size.height - padding * 2);

    canvas.drawCircle(Offset(pointX, pointY), 4, Paint()..color = lineColor);
  }

  @override
  bool shouldRepaint(HealthChartPainter oldDelegate) {
    return data != oldDelegate.data ||
        translateX != oldDelegate.translateX ||
        translateY != oldDelegate.translateY ||
        scaleX != oldDelegate.scaleX ||
        scaleY != oldDelegate.scaleY ||
        tooltipPosition != oldDelegate.tooltipPosition;
  }
}
