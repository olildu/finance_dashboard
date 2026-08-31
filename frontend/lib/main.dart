import 'package:finance_dashboard/responsive_screen/mobile_screens/home/new_mobile_home_page.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:finance_dashboard/constants/globals.dart';
import 'package:finance_dashboard/core/network/api_client.dart';
import 'package:finance_dashboard/core/network/token_manager.dart';
import 'package:finance_dashboard/features/accounts/business/accounts_provider.dart';
import 'package:finance_dashboard/features/accounts/data/accounts_api.dart';
import 'package:finance_dashboard/features/auth/business/auth_provider.dart';
import 'package:finance_dashboard/features/auth/data/auth_api.dart';
import 'package:finance_dashboard/features/auth/presentation/login_register_page.dart';
import 'package:finance_dashboard/features/budgets/business/budgets_provider.dart';
import 'package:finance_dashboard/features/budgets/data/budgets_api.dart';
import 'package:finance_dashboard/features/budgets/presentation/budgets_page.dart';
import 'package:finance_dashboard/features/credit/business/credit_provider.dart';
import 'package:finance_dashboard/features/credit/data/credit_api.dart';
import 'package:finance_dashboard/features/credit/presentation/credit_balance_widget.dart';
import 'package:finance_dashboard/features/dashboard/business/dashboard_provider.dart';
import 'package:finance_dashboard/features/dashboard/presentation/home_page.dart';
import 'package:finance_dashboard/features/transactions/business/transactions_provider.dart';
import 'package:finance_dashboard/features/transactions/data/transactions_api.dart';
import 'package:finance_dashboard/features/transactions/presentation/transaction_entry_page.dart';
import 'package:finance_dashboard/features/transactions/presentation/transaction_list_page.dart';
import 'package:finance_dashboard/providers/data_provider.dart';
import 'package:finance_dashboard/providers/transaction_card_provider.dart';
import 'package:finance_dashboard/responsive_screen/screen_decider.dart';
import 'package:finance_dashboard/responsive_screen/desktop_screens/desktop_home_page.dart';
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
        child: HomePage(),
      ),
    ),
    GoRoute(
      path: "/auth",
      pageBuilder: (context, state) => const CupertinoPage(
        child: LoginRegisterPage(),
      ),
    ),
    GoRoute(
      path: "/transactions",
      pageBuilder: (context, state) => const CupertinoPage(
        child: TransactionListPage(),
      ),
    ),
    GoRoute(
      path: "/transactions/new",
      pageBuilder: (context, state) => const CupertinoPage(
        child: TransactionEntryPage(),
      ),
    ),
    GoRoute(
      path: "/credit",
      pageBuilder: (context, state) => const CupertinoPage(
        child: Scaffold(body: CreditBalanceWidget()),
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
    GoRoute(
      path: "/budgets",
      pageBuilder: (context, state) => const CupertinoPage(
        child: BudgetsPage(),
      ),
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
        final apiClient = ApiClient();
        final tokenManager = TokenManager();
        final authApi = AuthApi(apiClient.dio);
        final accountsApi = AccountsApi(apiClient.dio);
        final transactionsApi = TransactionsApi(apiClient.dio);
        final creditApi = CreditApi(apiClient.dio);
        final budgetsApi = BudgetsApi(apiClient.dio);

        return MultiProvider(
          providers: [
            ChangeNotifierProvider(create: (_) => SimpleProvider()),
            ChangeNotifierProvider(create: (_) => TransactionCardProvider()),
            ChangeNotifierProvider(
              create: (_) => AuthProvider(
                authApi: authApi,
                tokenManager: tokenManager,
              ),
            ),
            ChangeNotifierProvider(
              create: (_) => AccountsProvider(accountsApi: accountsApi),
            ),
            ChangeNotifierProvider(
              create: (_) => TransactionsProvider(transactionsApi: transactionsApi),
            ),
            ChangeNotifierProvider(
              create: (_) => CreditProvider(creditApi: creditApi),
            ),
            ChangeNotifierProvider(
              create: (_) => BudgetsProvider(budgetsApi: budgetsApi),
            ),
            ChangeNotifierProxyProvider4<AccountsProvider, BudgetsProvider, CreditProvider, TransactionsProvider, DashboardProvider>(
              create: (_) => DashboardProvider(
                accountsProvider: AccountsProvider(accountsApi: accountsApi),
                budgetsProvider: BudgetsProvider(budgetsApi: budgetsApi),
                creditProvider: CreditProvider(creditApi: creditApi),
                transactionsProvider: TransactionsProvider(transactionsApi: transactionsApi),
              ),
              update: (_, accountsProvider, budgetsProvider, creditProvider, transactionsProvider, previous) =>
                  DashboardProvider(
                    accountsProvider: accountsProvider,
                    budgetsProvider: budgetsProvider,
                    creditProvider: creditProvider,
                    transactionsProvider: transactionsProvider,
                  ),
            ),
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
