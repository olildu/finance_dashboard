import 'package:finance_dashboard/constants/colors.dart';
import 'package:finance_dashboard/services/common_services.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lottie/lottie.dart';

class DonePage extends StatefulWidget {
  final String title;
  final int index;
  final int amount;
  final bool isDebit;

  const DonePage({super.key, required this.title, required this.index, required this.amount, required this.isDebit});

  @override
  State<DonePage> createState() => _DonePageState();
}

class _DonePageState extends State<DonePage> with TickerProviderStateMixin {
  bool showText = false;
  late AnimationController _animationController;

  List<String> returnMethod() {
    if (widget.isDebit == true) {
      return ["Debited", "From"];
    } else {
      return ["Credited", "To"];
    }
  }

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );

    _animationController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        setState(() {
          showText = true;
        });

        Future.delayed(const Duration(seconds: 2), () {
          GoRouter.of(context).push('/');
        });
      }
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    List<String> method = returnMethod();

    return Scaffold(
      backgroundColor: backgroundColor,
      body: Center(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Lottie.network(
              "https://lottie.host/1072eab7-6393-4788-8ef4-2724a44bab04/36K9jO4pOd.json",
              controller: _animationController,
              onLoaded: (composition) {
                _animationController.forward();
              },
              repeat: false,
              height: 600.h,
            ),

            AnimatedOpacity(
              opacity: showText ? 1.0 : 0.0,
              duration: const Duration(milliseconds: 500),
              child: Text(
                "${method[0]} ₹${formatIndianSystem(widget.amount)} ${method[1]} ${widget.title}",
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontSize: 20.sp,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}