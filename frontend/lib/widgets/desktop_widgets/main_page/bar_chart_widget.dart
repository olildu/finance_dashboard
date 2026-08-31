import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

class BarChartSample1 extends StatefulWidget {
  final Map financialData;
  final bool? showTitle;

  BarChartSample1({super.key, required this.financialData, this.showTitle});

  List<Color> get availableColors => const <Color>[
        Colors.purple,
        Colors.yellow,
        Colors.blue,
        Colors.orange,
        Colors.pink,
        Colors.red,
      ];

  final Color barBackgroundColor = Colors.white.withAlpha((0.3 * 255).toInt());
  final Color barColor = Colors.white;
  final Color touchedBarColor = Colors.green;

  @override
  State<StatefulWidget> createState() => BarChartSample1State();
}

class BarChartSample1State extends State<BarChartSample1> {
  final Duration animDuration = const Duration(milliseconds: 250);

  int touchedIndex = -1;

  bool isPlaying = false;

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 1,
      child: Stack(
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      widget.showTitle == null ? 'Expense Chart' : 'Fixed Expenses',
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontSize: 24.sp,
                        fontWeight: FontWeight.w300,
                      ),
                    ),
                    CircleAvatar(
                      radius: 14.r,
                      backgroundColor: const Color.fromARGB(255, 90, 90, 90),
                      child: IconButton(
                        padding: EdgeInsets.zero,
                        icon: const Icon(
                          Icons.arrow_forward_ios,
                          color: Color.fromARGB(255, 254, 254, 254),
                          size: 13,
                        ),
                        onPressed: () {
                          GoRouter.of(context).push('/transactions');
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(
                  height: 4,
                ),
                const SizedBox(
                  height: 38,
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: BarChart(
                      mainBarData(),
                      duration: animDuration,
                    ),
                  ),
                ),
                const SizedBox(
                  height: 12,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  BarChartGroupData makeGroupData(
    int x,
    double y, {
    bool isTouched = false,
    Color? barColor,
    double width = 22,
    List<int> showTooltips = const [],
  }) {
    barColor ??= widget.barColor;
    return BarChartGroupData(
      x: x,
      barRods: [
        BarChartRodData(
          toY: isTouched ? y + 1 : y,
          color: isTouched ? widget.touchedBarColor : barColor,
          width: width,
          borderSide: isTouched ? const BorderSide(color: Colors.grey) : const BorderSide(color: Colors.white, width: 0),
          backDrawRodData: BackgroundBarChartRodData(
            show: true,
            toY: 20,
            color: widget.barBackgroundColor,
          ),
        ),
      ],
      showingTooltipIndicators: showTooltips,
    );
  }

  List<BarChartGroupData> showingGroups() => List.generate(6, (i) {
        switch (i) {
          case 0:
            return makeGroupData(
              0,
              (((widget.financialData["category_percentages"]["Food & Drinks"] ?? 0).toDouble()) * 22),
              isTouched: i == touchedIndex,
            );
          case 1:
            return makeGroupData(
              1,
              (((widget.financialData["category_percentages"]["Laundry"] ?? 0).toDouble()) * 22),
              isTouched: i == touchedIndex,
            );
          case 2:
            return makeGroupData(
              2,
              (((widget.financialData["category_percentages"]["Travel"] ?? 0).toDouble()) * 22),
              isTouched: i == touchedIndex,
            );
          case 3:
            return makeGroupData(
              3,
              (((widget.financialData["category_percentages"]["Bill"] ?? 0).toDouble()) * 22),
              isTouched: i == touchedIndex,
            );
          case 4:
            return makeGroupData(
              4,
              (((widget.financialData["category_percentages"]["Shopping"] ?? 0).toDouble()) * 22),
              isTouched: i == touchedIndex,
            );
          case 5:
            return makeGroupData(
              5,
              (((widget.financialData["category_percentages"]["Others"] ?? 0).toDouble()) * 22),
              isTouched: i == touchedIndex,
            );
          default:
            throw Error();
        }
      });

  BarChartData mainBarData() {
    return BarChartData(
      barTouchData: BarTouchData(
        touchTooltipData: BarTouchTooltipData(
          getTooltipColor: (_) => Colors.blueGrey,
          tooltipHorizontalAlignment: FLHorizontalAlignment.right,
          tooltipMargin: -10,
          getTooltipItem: (group, groupIndex, rod, rodIndex) {
            String item;
            switch (group.x) {
              case 0:
                item = 'Food & Drinks';
                break;
              case 1:
                item = 'Laundry';
                break;
              case 2:
                item = 'Travel';
                break;
              case 3:
                item = 'Bill';
                break;
              case 4:
                item = 'Shopping';
                break;
              case 5:
                item = 'Others';
                break;
              default:
                throw Error();
            }
            return BarTooltipItem(
              '$item\n',
              const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
              children: <TextSpan>[
                TextSpan(
                  text: widget.financialData["category_totals"][item].toString(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            );
          },
        ),
        touchCallback: (FlTouchEvent event, barTouchResponse) {
          setState(() {
            if (!event.isInterestedForInteractions || barTouchResponse == null || barTouchResponse.spot == null) {
              touchedIndex = -1;
              return;
            }
            touchedIndex = barTouchResponse.spot!.touchedBarGroupIndex;
          });
        },
      ),
      titlesData: FlTitlesData(
        show: true,
        rightTitles: const AxisTitles(
          sideTitles: SideTitles(showTitles: false),
        ),
        topTitles: const AxisTitles(
          sideTitles: SideTitles(showTitles: false),
        ),
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            getTitlesWidget: getTitles,
            reservedSize: 38,
          ),
        ),
        leftTitles: const AxisTitles(
          sideTitles: SideTitles(
            showTitles: false,
          ),
        ),
      ),
      borderData: FlBorderData(
        show: false,
      ),
      barGroups: showingGroups(),
      gridData: const FlGridData(show: false),
    );
  }

  Widget getTitles(double value, TitleMeta meta) {
    const style = TextStyle(
      color: Colors.white,
      fontWeight: FontWeight.bold,
      fontSize: 14,
    );
    Widget text;
    switch (value.toInt()) {
      case 0:
        text = const Text('F&D', style: style);
        break;
      case 1:
        text = const Text('LD', style: style);
        break;
      case 2:
        text = const Text('Tr', style: style);
        break;
      case 3:
        text = const Text('Bi', style: style);
        break;
      case 4:
        text = const Text('Sh', style: style);
        break;
      case 5:
        text = const Text('Ot', style: style);
        break;
      case 6:
        text = const Text('S', style: style);
        break;
      default:
        text = const Text('', style: style);
        break;
    }
    return SideTitleWidget(
      fitInside: SideTitleFitInsideData.fromTitleMeta(meta),
      space: 16,
      meta: meta,
      child: text,
    );
  }
}
