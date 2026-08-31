import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';

Widget drawer(){
  return Expanded(
    child: ClipRRect(
      borderRadius: BorderRadius.circular(20.r),
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 10.r),
        decoration: BoxDecoration(color: Colors.yellow, borderRadius: BorderRadius.circular(20.r)),
        child: Drawer(
          backgroundColor: Colors.yellow,
            child: ListView(
              padding: EdgeInsets.symmetric(vertical: 10.h, horizontal: 10.w),
              children: [
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 10.w),
                  child: Text(
                    "NoBroke",
                    style: TextStyle(
                      fontSize: 30.sp
                    ),
                  ),
                ),



                Gap(60.h),

                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 10.w),
                  child: Text( 
                    "Menu",
                    style: TextStyle( 
                      fontSize: 18.sp
                    ),
                  ),
                ),

                Gap(10.h),

                drawerChildren("Dashboard", Icons.home_rounded),

                Gap(20.h),

                drawerChildren("Transactions", Icons.auto_graph_sharp),
              ],
            ),
        ),    
      ),
    )
  );
}

Widget drawerChildren(String title, IconData icon){
  return ListTile(
    contentPadding: EdgeInsets.symmetric(horizontal: 7.w),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    title: Row(
      children: [
        Icon(icon),
  
        Gap(10.w), 
  
        Text(
          title,
          style: TextStyle(
            fontSize: 20.sp
          ),
        ),
      ],
    ),
    onTap: () {
  
    }, 
  );
}