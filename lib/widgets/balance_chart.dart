import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/transaction.dart';
import '../theme/app_theme.dart';

class BalanceChart extends StatelessWidget {
  final List<DbuxTransaction> transactions;
  final int currentBalance;

  const BalanceChart({
    super.key,
    required this.transactions,
    required this.currentBalance,
  });

  @override
  Widget build(BuildContext context) {
    final points = _buildBalancePoints();
    if (points.length < 2) {
      return SizedBox(
        height: 200,
        child: Center(
          child: Text(
            'Not enough data yet',
            style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
          ),
        ),
      );
    }

    return SizedBox(
      height: 220,
      child: CustomPaint(
        size: Size.infinite,
        painter: _ChartPainter(
          points: points,
          lineColor: AppTheme.lightScheme.primary,
          fillColor: AppTheme.lightScheme.primary.withValues(alpha: 0.1),
          labelColor: Theme.of(context).colorScheme.onSurfaceVariant,
          gridColor: Theme.of(context).colorScheme.outlineVariant.withValues(alpha: 0.3),
        ),
      ),
    );
  }

  List<_BalancePoint> _buildBalancePoints() {
    if (transactions.isEmpty) return [];

    // Walk transactions in chronological order, rebuilding balance over time
    final sorted = List<DbuxTransaction>.from(transactions)
      ..sort((a, b) => a.createdAt.compareTo(b.createdAt));

    // Work backwards from current balance to find starting balance
    int balance = currentBalance;
    for (final tx in sorted.reversed) {
      if (tx.type == TransactionType.earned) {
        balance -= tx.amount;
      } else {
        balance += tx.amount;
      }
    }

    // Now walk forward
    final points = <_BalancePoint>[
      _BalancePoint(sorted.first.createdAt, balance),
    ];

    for (final tx in sorted) {
      if (tx.type == TransactionType.earned) {
        balance += tx.amount;
      } else {
        balance -= tx.amount;
      }
      points.add(_BalancePoint(tx.createdAt, balance));
    }

    return points;
  }
}

class _BalancePoint {
  final DateTime date;
  final int balance;
  _BalancePoint(this.date, this.balance);
}

class _ChartPainter extends CustomPainter {
  final List<_BalancePoint> points;
  final Color lineColor;
  final Color fillColor;
  final Color labelColor;
  final Color gridColor;

  _ChartPainter({
    required this.points,
    required this.lineColor,
    required this.fillColor,
    required this.labelColor,
    required this.gridColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (points.length < 2) return;

    const leftPad = 40.0;
    const bottomPad = 24.0;
    const topPad = 12.0;
    const rightPad = 12.0;

    final chartWidth = size.width - leftPad - rightPad;
    final chartHeight = size.height - bottomPad - topPad;

    final minBal = points.map((p) => p.balance).reduce(math.min);
    final maxBal = points.map((p) => p.balance).reduce(math.max);
    final balRange = maxBal == minBal ? 1.0 : (maxBal - minBal).toDouble();

    final minDate = points.first.date.millisecondsSinceEpoch.toDouble();
    final maxDate = points.last.date.millisecondsSinceEpoch.toDouble();
    final dateRange = maxDate == minDate ? 1.0 : maxDate - minDate;

    double x(DateTime d) =>
        leftPad + ((d.millisecondsSinceEpoch - minDate) / dateRange) * chartWidth;
    double y(int bal) =>
        topPad + chartHeight - ((bal - minBal) / balRange) * chartHeight;

    // Grid lines
    final gridPaint = Paint()
      ..color = gridColor
      ..strokeWidth = 0.5;

    const gridLines = 4;
    final labelStyle = TextStyle(fontSize: 10, color: labelColor);
    for (int i = 0; i <= gridLines; i++) {
      final val = minBal + (balRange * i / gridLines).round();
      final yPos = y(val);
      canvas.drawLine(Offset(leftPad, yPos), Offset(size.width - rightPad, yPos), gridPaint);

      final tp = TextPainter(
        text: TextSpan(text: '$val', style: labelStyle),
        textDirection: ui.TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(leftPad - tp.width - 4, yPos - tp.height / 2));
    }

    // Date labels
    final fmt = DateFormat('M/d');
    for (final idx in [0, points.length ~/ 2, points.length - 1]) {
      final p = points[idx];
      final tp = TextPainter(
        text: TextSpan(text: fmt.format(p.date), style: labelStyle),
        textDirection: ui.TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(x(p.date) - tp.width / 2, size.height - bottomPad + 4));
    }

    // Build path
    final path = Path();
    path.moveTo(x(points.first.date), y(points.first.balance));
    for (int i = 1; i < points.length; i++) {
      path.lineTo(x(points[i].date), y(points[i].balance));
    }

    // Draw line
    final linePaint = Paint()
      ..color = lineColor
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    canvas.drawPath(path, linePaint);

    // Fill under line
    final fillPath = Path.from(path)
      ..lineTo(x(points.last.date), topPad + chartHeight)
      ..lineTo(x(points.first.date), topPad + chartHeight)
      ..close();
    canvas.drawPath(fillPath, Paint()..color = fillColor);

    // Dots at endpoints
    final dotPaint = Paint()..color = lineColor;
    canvas.drawCircle(Offset(x(points.first.date), y(points.first.balance)), 3, dotPaint);
    canvas.drawCircle(Offset(x(points.last.date), y(points.last.balance)), 4, dotPaint);
  }

  @override
  bool shouldRepaint(covariant _ChartPainter old) => old.points != points;
}
