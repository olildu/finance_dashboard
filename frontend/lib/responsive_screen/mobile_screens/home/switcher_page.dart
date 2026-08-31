// lib/responsive_screen/mobile_screens/home/switcher_page.dart
import 'package:finance_dashboard/constants/colors.dart';
import 'package:finance_dashboard/responsive_screen/mobile_screens/home/overview_page.dart';
import 'package:finance_dashboard/responsive_screen/mobile_screens/home/transactions_page.dart';
import 'package:finance_dashboard/widgets/common_widgets/text_widget.dart';
import 'package:finance_dashboard/widgets/desktop_widgets/main_page/bar_chart_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';

class SwitcherWithFade extends StatefulWidget {
  final Map financialData;

  const SwitcherWithFade({
    super.key,
    required this.financialData,
  });

  @override
  State<SwitcherWithFade> createState() => _SwitcherWithFadeState();
}

class _SwitcherWithFadeState extends State<SwitcherWithFade> with SingleTickerProviderStateMixin {
  bool showOverview = true;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Switcher row
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildIconButton(
              icon: Icons.dashboard_rounded,
              isActive: showOverview,
              onTap: () => setState(() => showOverview = true),
            ),
            Gap(10.w),
            _buildIconButton(
              icon: Icons.auto_graph_rounded,
              isActive: !showOverview,
              onTap: () => setState(() => showOverview = false),
            ),
          ],
        ),

        Gap(20.h),

        // Animated content
        Expanded(
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 400),
            transitionBuilder: (child, animation) => FadeTransition(
              opacity: animation,
              child: child,
            ),
            layoutBuilder: (Widget? currentChild, List<Widget> previousChildren) {
              return currentChild ?? Container();
            },
            child: showOverview
                ? OverviewPage(
                    key: const ValueKey('overview'),
                    financialData: widget.financialData,
                  )
                : TransactionsPage(
                    key: const ValueKey('graph'),
                    financialData: widget.financialData,
                  ),
          ),
        ),
      ],
    );
  }

  Widget _buildIconButton({
    required IconData icon,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeInOut,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: isActive ? Colors.white : const Color(0xFF1E1E1E),
          boxShadow: isActive
              ? [
                  BoxShadow(
                    color: Colors.white.withOpacity(0.3),
                    blurRadius: 12,
                    spreadRadius: 1,
                  )
                ]
              : [],
        ),
        child: Padding(
          padding: EdgeInsets.all(10.r),
          child: Icon(
            icon,
            size: 26.sp,
            color: isActive ? Colors.black : Colors.white,
          ),
        ),
      ),
    );
  }
}
