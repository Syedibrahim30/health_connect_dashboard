import 'package:flutter/material.dart';

import '../../domain/entities/chart_data.dart';
import '../painters/health_chart_painter.dart';

class InteractiveChart extends StatefulWidget {
  final ChartData data;
  final Color lineColor;
  final Color fillColor;
  final String title;
  final double height;

  const InteractiveChart({
    super.key,
    required this.data,
    required this.lineColor,
    required this.fillColor,
    required this.title,
    this.height = 300,
  });

  @override
  State<InteractiveChart> createState() => _InteractiveChartState();
}

class _InteractiveChartState extends State<InteractiveChart> {
  double _translateX = 0.0;
  double _translateY = 0.0;
  double _scaleX = 1.0;
  double _scaleY = 1.0;
  Offset? _tooltipPosition;

  double _baseScaleX = 1.0;
  double _baseScaleY = 1.0;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: widget.height,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              widget.title,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            child: GestureDetector(
              onScaleStart: _handleScaleStart,
              onScaleUpdate: _handleScaleUpdate,
              onScaleEnd: _handleScaleEnd,
              onTapDown: _handleTapDown,
              onTapUp: _handleTapUp,
              child: CustomPaint(
                size: Size.infinite,
                painter: HealthChartPainter(
                  data: widget.data,
                  lineColor: widget.lineColor,
                  fillColor: widget.fillColor,
                  gridColor: Colors.grey.shade300,
                  title: widget.title,
                  translateX: _translateX,
                  translateY: _translateY,
                  scaleX: _scaleX,
                  scaleY: _scaleY,
                  tooltipPosition: _tooltipPosition,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _handleScaleStart(ScaleStartDetails details) {
    _baseScaleX = _scaleX;
    _baseScaleY = _scaleY;
  }

  void _handleScaleUpdate(ScaleUpdateDetails details) {
    setState(() {
      // Pan
      _translateX += details.focalPointDelta.dx;
      _translateY += details.focalPointDelta.dy;

      // Zoom
      if (details.scale != 1.0) {
        _scaleX = (_baseScaleX * details.scale).clamp(0.5, 5.0);
        _scaleY = (_baseScaleY * details.scale).clamp(0.5, 5.0);
      }

      // Show tooltip at touch point
      _tooltipPosition = details.localFocalPoint;
    });
  }

  void _handleScaleEnd(ScaleEndDetails details) {
    setState(() {
      _tooltipPosition = null;
    });
  }

  void _handleTapDown(TapDownDetails details) {
    setState(() {
      _tooltipPosition = details.localPosition;
    });
  }

  void _handleTapUp(TapUpDetails details) {
    setState(() {
      _tooltipPosition = null;
    });
  }
}
