import 'package:fl_chart/chart/bar_chart/bar_chart_data.dart';
import 'package:fl_chart/chart/base/fl_axis_chart/fl_axis_chart_painter.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

class BarChartPainter extends FlAxisChartPainter {
  final BarChartData data;

  Paint barPaint;

  BarChartPainter(
    this.data,
    ) : super(data) {
    barPaint = Paint()
      ..color = Colors.red
      ..style = PaintingStyle.fill
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 10;
  }

  @override
  void paint(Canvas canvas, Size viewSize) {
    if (data.spots.length == 0) {
      return;
    }
    super.paint(canvas, viewSize);

    List<double> barsX = calculateGroupsX(viewSize, data.barGroups, data.alignment);
    drawBars(canvas, viewSize, barsX);
    drawTitles(canvas, viewSize, barsX);
  }

  List<double> calculateGroupsX(Size viewSize,
    List<BarChartGroupData> barGroups, BarChartAlignment alignment) {
    Size drawSize = getChartUsableDrawSize(viewSize);

    List<double> groupsX = List(barGroups.length);

    double leftTextsSpace = getLeftOffsetDrawSize();

    switch (alignment) {
      case BarChartAlignment.start:
        double tempX = 0;
        barGroups.asMap().forEach((i, group) {
          groupsX[i] = leftTextsSpace + tempX + group.width / 2;
          tempX += group.width;
        });
        break;

      case BarChartAlignment.end:
        double tempX = 0;
        for (int i = barGroups.length - 1; i >= 0; i--) {
          var group = barGroups[i];
          groupsX[i] = (leftTextsSpace + drawSize.width) - tempX - group.width / 2;
          tempX += group.width;
        }
        break;

      case BarChartAlignment.center:
        double sumWidth = barGroups.map((group) => group.width).reduce((a, b) => a + b);

        double horizontalMargin = (drawSize.width - sumWidth) / 2;

        double tempX = 0;
        for (int i = 0; i < barGroups.length; i++) {
          var group = barGroups[i];
          groupsX[i] = leftTextsSpace + horizontalMargin + tempX + group.width / 2;
          tempX += group.width;
        }
        break;

      case BarChartAlignment.spaceBetween:
        double sumWidth = barGroups.map((group) => group.width).reduce((a, b) => a + b);
        double spaceAvailable = drawSize.width - sumWidth;
        double eachSpace = spaceAvailable / (barGroups.length - 1);

        double tempX = 0;
        barGroups.asMap().forEach((index, group) {
          tempX += (group.width / 2);
          if (index != 0) {
            tempX += eachSpace;
          }
          groupsX[index] = leftTextsSpace + tempX;
          tempX += (group.width / 2);
        });
        break;

      case BarChartAlignment.spaceAround:
        double sumWidth = barGroups.map((group) => group.width).reduce((a, b) => a + b);
        double spaceAvailable = drawSize.width - sumWidth;
        double eachSpace = spaceAvailable / (barGroups.length * 2);

        double tempX = 0;
        barGroups.asMap().forEach((i, group) {
          tempX += eachSpace;
          tempX += group.width / 2;
          groupsX[i] = leftTextsSpace + tempX;
          tempX += group.width / 2;
          tempX += eachSpace;
        });
        break;
      case BarChartAlignment.spaceEvenly:
        double sumWidth = barGroups.map((group) => group.width).reduce((a, b) => a + b);
        double spaceAvailable = drawSize.width - sumWidth;
        double eachSpace = spaceAvailable / (barGroups.length + 1);

        double tempX = 0;
        barGroups.asMap().forEach((i, group) {
          tempX += eachSpace;
          tempX += group.width / 2;
          groupsX[i] = leftTextsSpace + tempX;
          tempX += group.width / 2;
        });
        break;
    }

    return groupsX;
  }

  void drawBars(Canvas canvas, Size viewSize, List<double> barsX) {
    Size drawSize = getChartUsableDrawSize(viewSize);

    data.barGroups.asMap().forEach((groupIndex, barGroup) {
      /*
      * If the height of rounded bars is less than their roundedRadius,
      * we can't draw them properly,
      * then we try to make them width lower,
      * */
      List<BarChartRodData> resizedWidthRods = barGroup.barRods.map((barRod) {
        if (!barRod.isRound) {
          return barRod;
        }

        double fromY = getPixelY(0, drawSize);
        double toY = getPixelY(barRod.y, drawSize);

        double barWidth = barRod.width;

        double barHeight = (fromY - toY).abs();
        while (barHeight < barWidth) {
          barWidth -= barWidth * 0.1;
        }

        if (barWidth == barRod.width) {
          return barRod;
        } else {
          return barRod.copyWith(width: barWidth);
        }
      }).toList();

      double tempX = 0;
      resizedWidthRods.asMap().forEach((barIndex, barRod) {
        double widthHalf = barRod.width / 2;
        double roundedRadius = barRod.isRound ? widthHalf : 0;

        double x = barsX[groupIndex] - (barGroup.width / 2) + tempX + widthHalf;

        Offset from, to;

        // Draw Bars
        barPaint.strokeWidth = barRod.width;
        barPaint.strokeCap = barRod.isRound ? StrokeCap.round : StrokeCap.butt;

        // Back Draw
        if(barRod.backDrawRodData.show) {
          from = Offset(
            x,
            getPixelY(0, drawSize) - roundedRadius,
          );

          to = Offset(
            x,
            getPixelY(barRod.backDrawRodData.y, drawSize) + roundedRadius,
          );

          barPaint.color = barRod.backDrawRodData.color;
          canvas.drawLine(from, to, barPaint);
        }

        // Main Rod
        from = Offset(
          x,
          getPixelY(0, drawSize) - roundedRadius,
        );

        to = Offset(
          x,
          getPixelY(barRod.y, drawSize) + roundedRadius,
        );

        barPaint.color = barRod.color;
        canvas.drawLine(from, to, barPaint);

        tempX += barRod.width + barGroup.barsSpace;
      });
    });
  }

  void drawTitles(Canvas canvas, Size viewSize, List<double> groupsX) {
    if (!data.titlesData.show) {
      return;
    }
    Size drawSize = getChartUsableDrawSize(viewSize);

    // Vertical Titles
    if (data.titlesData.showVerticalTitles) {
      int verticalCounter = 0;
      while (data.gridData.verticalInterval * verticalCounter <= data.maxY) {
        double x = 0 + getLeftOffsetDrawSize();
        double y = getPixelY(data.gridData.verticalInterval * verticalCounter, drawSize) +
          getTopOffsetDrawSize();

        String text =
        data.titlesData.getVerticalTitle(data.gridData.verticalInterval * verticalCounter);

        TextSpan span = new TextSpan(style: data.titlesData.verticalTitlesTextStyle, text: text);
        TextPainter tp = new TextPainter(
          text: span, textAlign: TextAlign.center, textDirection: TextDirection.ltr);
        tp.layout(maxWidth: getExtraNeededHorizontalSpace());
        x -= tp.width + data.titlesData.verticalTitleMargin;
        y -= (tp.height / 2);
        tp.paint(canvas, new Offset(x, y));

        verticalCounter++;
      }
    }

    // Horizontal titles
    groupsX.asMap().forEach((int index, double x) {
      String text = data.titlesData.getHorizontalTitle(index.toDouble());

      TextSpan span = new TextSpan(style: data.titlesData.horizontalTitlesTextStyle, text: text);
      TextPainter tp = new TextPainter(
        text: span, textAlign: TextAlign.center, textDirection: TextDirection.ltr);
      tp.layout();

      double textX = x - (tp.width / 2);
      double textY = drawSize.height + getTopOffsetDrawSize() + data.titlesData.horizontalTitleMargin;

      tp.paint(canvas, Offset(textX, textY));
    });
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}