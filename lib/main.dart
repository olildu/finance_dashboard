import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:finance_dashboard/services/token_services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:finance_dashboard/constants/globals.dart';
import 'package:finance_dashboard/providers/data_provider.dart';
import 'package:finance_dashboard/providers/transaction_card_provider.dart';
import 'package:finance_dashboard/responsive_screen/screen_decider.dart';
import 'package:finance_dashboard/responsive_screen/desktop_screens/desktop_home_page.dart';
import 'package:finance_dashboard/responsive_screen/mobile_screens/home/mobile_home_page.dart';
import 'package:finance_dashboard/responsive_screen/desktop_screens/desktop_login_register_page.dart';
import 'package:finance_dashboard/responsive_screen/mobile_screens/auth/mobile_login_register_page.dart';
import 'package:finance_dashboard/responsive_screen/desktop_screens/desktop_transactions_page.dart';
import 'package:finance_dashboard/responsive_screen/mobile_screens/transactions/mobile_transactions_page.dart';
import 'package:finance_dashboard/responsive_screen/mobile_screens/debit_credit/mobile_monthly_expense_catergories_page.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

final GoRouter _router = GoRouter(
  navigatorKey: navigatorkey,
  initialLocation: '/',
  routes: <RouteBase>[
    GoRoute(
      path: "/",
      pageBuilder: (context, state) => const CupertinoPage(
        child: ScreenDecider(
          mobilePage: MobileHomePage(),
          desktopPage: DesktopHomePage(),
        ),
      ),
    ),
    GoRoute(
      path: "/auth",
      pageBuilder: (context, state) => const CupertinoPage(
        child: ScreenDecider(
          mobilePage: MobileLoginRegisterPage(),
          desktopPage: DesktopLoginRegisterPage(),
        ),
      ),
    ),
    GoRoute(
      path: "/transactions",
      pageBuilder: (context, state) => const CupertinoPage(
        child: ScreenDecider(
          mobilePage: MobileTransactionPage(),
          desktopPage: DesktopTransactionsPage(),
        ),
      ),
    ),
    GoRoute(
      path: "/debit",
      pageBuilder: (context, state) {
        final int? amount = int.tryParse(state.uri.queryParameters['amount'] ?? '');
        return CupertinoPage(
          child: MobileMonthlyExpenseCatergoriesPage(
            index: 0,
            isDebit: true,
            amount: amount,
          ),
        );
      },
    ),
  ],
  redirect: (BuildContext context, GoRouterState state) async {
    final tokenManager = TokenManager();
    final bool isLoggedIn = await tokenManager.hasValidRefreshToken();
    final bool isLoggingIn = state.matchedLocation == '/auth';
    if (!isLoggedIn && !isLoggingIn) {
      return '/auth';
    }

    if (isLoggedIn && isLoggingIn) {
      return '/';
    }

    return null;
  },
);

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ScreenUtilInit(
      designSize: MediaQuery.of(context).size.width > 800 ? const Size(1536, 695.2) : const Size(500, 729.6),
      minTextAdapt: true,
      builder: (context, child) {
        return MultiProvider(
          providers: [
            ChangeNotifierProvider(create: (_) => SimpleProvider()),
            ChangeNotifierProvider(create: (_) => TransactionCardProvider()),
          ],
          child: MaterialApp.router(
            title: 'NoBroke',
            debugShowCheckedModeBanner: false,
            theme: ThemeData(
              colorScheme: ColorScheme.fromSeed(
                seedColor: const Color.fromARGB(255, 174, 222, 52),
              ),
              useMaterial3: true,
              textTheme: GoogleFonts.poppinsTextTheme(),
            ),
            routerConfig: _router,
          ),
        );
      },
    );
  }
}
