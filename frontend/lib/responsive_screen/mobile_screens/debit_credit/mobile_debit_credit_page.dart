import 'dart:async';
import 'dart:developer';

import 'package:finance_dashboard/constants/colors.dart';
import 'package:finance_dashboard/responsive_screen/mobile_screens/debit_credit/done_page.dart';
import 'package:finance_dashboard/services/http_services.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter/services.dart';
import 'package:gap/gap.dart';
import 'package:google_fonts/google_fonts.dart';

class MobileDebitCreditPage extends StatefulWidget {
  final String title;
  final bool isDebit;
  final int index;
  final int? amount;
  final List? choices;

  const MobileDebitCreditPage({
    super.key, 
    required this.title, 
    required this.index,
    required this.isDebit,
    this.choices,
    this.amount,
  });

  @override
  State<MobileDebitCreditPage> createState() => _MobileDebitCreditPageState();
}

class _MobileDebitCreditPageState extends State<MobileDebitCreditPage> {
  int cardIndex = -1;
  TextEditingController amountController = TextEditingController();
  TextEditingController noteController = TextEditingController();
  List choices = [];

  Timer? _debounce; 

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      
      appBar: AppBar(
        backgroundColor: backgroundColor,
        leading: Padding(
          padding: EdgeInsets.symmetric(horizontal: 10.r),
          child: ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            style: ElevatedButton.styleFrom(
              shape: const CircleBorder(),
              padding: EdgeInsets.zero,
              backgroundColor: primaryColor,
            ),
            child: Center(
              child: Icon(
                Icons.arrow_back_ios_new_rounded,
                color: Colors.white,
                size: 17.sp,
              ),
            ),
          ),
        ),
        title: Text(
          widget.title,
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontSize: 18.sp,
          ),
        ),
      ),
      body: Stack(
        fit: StackFit.passthrough,
        children: [
          Padding(
            padding: EdgeInsets.all(20.h),
            child: Center(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IntrinsicWidth(
                    child: TextField(
                      controller: amountController,
                      style: TextStyle(
                        fontSize: 32.sp,
                        color: Colors.white,
                      ),
                      textAlign: TextAlign.center,
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                      ],
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: backgroundColor,
                        hintText: "0",
                        labelStyle: TextStyle(
                          color: Colors.white,
                          fontSize: 18.sp,
                        ),
                        hintStyle: TextStyle(
                          color: Colors.grey,
                          fontSize: 28.sp,
                        ),
                        prefixIcon: Padding(
                          padding: EdgeInsets.only(left: 10.w, right: 5.w),
                          child: Text(
                            "₹",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 32.sp,
                            ),
                          ),
                        ),
                        prefixIconConstraints: const BoxConstraints(
                          minWidth: 0,
                          minHeight: 0,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                  ),
                  Gap(15.h),
                 
                  IntrinsicWidth(
                    stepWidth: 90,
                    child: Container(
                      decoration: BoxDecoration(
                        color: primaryColor,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: TextField(
                        controller: noteController,
                        style: const TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: Colors.transparent,
                          hintText: "Add a note",
                          hintStyle: TextStyle(
                            color: Colors.grey,
                            fontSize: 15.sp,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                          suffixIcon: Padding(
                            padding: EdgeInsets.only(right: 2.w),
                            child: IconButton(
                              padding: EdgeInsets.zero,  
                              onPressed: () {
                                noteController.clear();
                              },
                              icon: Container(
                                padding: EdgeInsets.all(6.sp),
                                decoration: const BoxDecoration(
                                  color: Color.fromARGB(255, 46, 46, 46),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  Icons.clear_rounded,
                                  color: Colors.white,
                                  size: 20.sp,
                                ),
                              ),
                            ),
                          ),
                          contentPadding: EdgeInsets.symmetric(horizontal: 10.w)
                        ),
                      ),
                    ),
                  ),
                  Gap(20.h),

                  if (choices.isNotEmpty)
                    Wrap(
                      children: List.generate(
                        choices.length, 
                        (index) => GestureDetector(
                          onTap: () {
                            setState(() {
                              cardIndex = index;
                              noteController.text += choices[index];
                            });
                          },
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 400),
                            curve: Curves.easeInOut,
                            padding: EdgeInsets.symmetric(vertical: 10.h, horizontal: 20.w),
                            margin: EdgeInsets.all(10.h),
                            decoration: BoxDecoration(
                              color: primaryColor,
                              borderRadius: BorderRadius.circular(10.r),
                              border: Border.all(
                                color: cardIndex == index ? Colors.yellow : Colors.transparent,
                              ),
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.spaceAround,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Text(
                                  choices[index],
                                  style: GoogleFonts.poppins(
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),

                ],
              ),
            ),
          ),
          Positioned(
            bottom: 0.h,
            left: 0,
            right: 0,
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 50.w, vertical: 20.h),
              child: GestureDetector(
                onTap: () async {
                  if (amountController.text.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text("Amount cannot be empty"),
                      ),
                    );
                    return;
                  }

                  widget.isDebit 
                    ? await HttpServices().debitTransaction(amountController.text, noteController.text, widget.title, widget.index)
                    : await HttpServices().creditTransaction(amountController.text, noteController.text, widget.title, widget.index);

                  Navigator.of(context).push(
                    CupertinoPageRoute(
                      builder: (context) => DonePage(
                        title: widget.title,
                        index: widget.index,
                        amount: int.parse(amountController.text),
                        isDebit: widget.isDebit,
                      ),
                    ),
                  );
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 400),
                  curve: Curves.easeInOut,
                  width: double.infinity,
                  height: 50.h,
                  decoration: BoxDecoration(
                    color: primaryColor,
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Center(
                    child: Text(
                      widget.isDebit ? "Debit" : "Credit",
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontSize: 20.sp,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void initState() {
    if (widget.amount != null) {
      amountController.text = widget.amount.toString();
    }
    if (widget.choices != null) {
      choices = widget.choices!;
    }
    amountController.addListener(_onAmountChange);
    super.initState();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    amountController.removeListener(_onAmountChange);
    amountController.dispose();
    noteController.dispose();
    super.dispose();
  }

  void _onAmountChange() {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () async {
      if (amountController.text.isNotEmpty) {
        log("Amount Changed");
        List results = await HttpServices().getChoices(amountController.text);
        choices = results;
      } else {
        choices.clear();
      }
      setState(() {});
    });
  }


}
