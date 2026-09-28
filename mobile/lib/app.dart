import 'package:flutter/material.dart';
import 'package:second_brain/core/auth/auth_service.dart';
import 'package:second_brain/core/theme/app_colors.dart';
import 'package:second_brain/core/theme/app_theme.dart';
import 'package:second_brain/features/auth/login_screen.dart';
import 'package:second_brain/features/auth/signup_screen.dart';
import 'package:second_brain/features/home/home_screen.dart';
import 'package:second_brain/features/expenses/expenses_screen.dart';
import 'package:second_brain/features/investments/investments_screen.dart';
import 'package:second_brain/features/documents/documents_screen.dart';
import 'package:second_brain/features/settings/settings_screen.dart';
import 'package:second_brain/features/reminders/services/automatic_reminder_service.dart';
import 'package:second_brain/features/reminders/services/notification_service.dart';
import 'package:second_brain/features/expenses/data/expense_repository.dart';
import 'package:second_brain/features/investments/data/investment_repository.dart';
import 'package:second_brain/features/documents/data/document_repository.dart';
import 'package:second_brain/features/reminders/data/reminder_repository.dart';
import 'package:second_brain/features/financial_goals/data/financial_repository.dart';
import 'package:second_brain/features/settings/data/user_profile_repository.dart';
import 'package:second_brain/shared/widgets/app_bottom_navigation.dart';

/// Root application widget for Second Brain.
class SecondBrainApp extends StatefulWidget {
  final GlobalKey<NavigatorState>? navigatorKey;

  const SecondBrainApp({super.key, this.navigatorKey});

  @override
  State<SecondBrainApp> createState() => _SecondBrainAppState();
}

class _SecondBrainAppState extends State<SecondBrainApp> {
  @override
  void initState() {
    super.initState();
    // Request Android 13+ notification permission once the widget tree is ready.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      NotificationService.instance.requestPermissions();
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Second Brain',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      navigatorKey: widget.navigatorKey,
      home: const AuthGate(),
    );
  }
}

/// Authentication Gate: displays LoginScreen or SignUpScreen until the user is authenticated.
class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  bool _showSignUp = false;
  String? _lastAuthenticatedUserId;

  void _reloadAllUserData() {
    final now = DateTime.now();
    UserProfileRepository.instance.loadProfile();
    ExpenseRepository.instance.loadExpensesForMonth(now.year, now.month);
    InvestmentRepository.instance.loadInvestments();
    DocumentRepository.instance.loadDocuments();
    ReminderRepository.instance.loadReminders();
    FinancialRepository.instance.loadAnalysis();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: AuthService.instance,
      builder: (context, _) {
        final isAuth = AuthService.instance.isAuthenticated;
        final currentUserId = AuthService.instance.currentUser?.id;

        if (isAuth) {
          if (currentUserId != null && currentUserId != _lastAuthenticatedUserId) {
            _lastAuthenticatedUserId = currentUserId;
            WidgetsBinding.instance.addPostFrameCallback((_) {
              _reloadAllUserData();
            });
          }
          return const AppShell();
        }

        _lastAuthenticatedUserId = null;
        if (_showSignUp) {
          return SignUpScreen(
            onSwitchToLogin: () => setState(() => _showSignUp = false),
          );
        }
        return LoginScreen(
          onSwitchToSignUp: () => setState(() => _showSignUp = true),
        );
      },
    );
  }
}

/// Primary application shell containing top-level navigation.
class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> with WidgetsBindingObserver {
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadDataFromDatabase();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  /// Loads live data from PostgreSQL database for all modules.
  void _loadDataFromDatabase() {
    final now = DateTime.now();
    UserProfileRepository.instance.loadProfile();
    ExpenseRepository.instance.loadExpensesForMonth(now.year, now.month);
    InvestmentRepository.instance.loadInvestments();
    DocumentRepository.instance.loadDocuments();
    ReminderRepository.instance.loadReminders();
    FinancialRepository.instance.loadAnalysis();
  }

  /// Re-sync automatic reminders and live data when the app comes back to the foreground.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _loadDataFromDatabase();
      AutomaticReminderService.instance.syncAutomaticReminders();
    }
  }

  static const List<_TabDestination> _destinations = [
    _TabDestination(title: 'Home'),
    _TabDestination(title: 'Expenses'),
    _TabDestination(title: 'Investments'),
    _TabDestination(title: 'Documents'),
    _TabDestination(title: 'Settings'),
  ];

  void _onNavigationTap(int index) {
    if (_currentIndex != index) {
      setState(() {
        _currentIndex = index;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentTab = _destinations[_currentIndex];

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: _currentIndex == 0
          ? null
          : AppBar(
              title: Text(currentTab.title),
              backgroundColor: AppColors.surface,
              elevation: 0,
              scrolledUnderElevation: 0,
              bottom: const PreferredSize(
                preferredSize: Size.fromHeight(1.0),
                child: Divider(height: 1.0, color: AppColors.border),
              ),
            ),
      body: SafeArea(
        child: IndexedStack(
          index: _currentIndex,
          children: const [
            HomeScreen(),
            ExpensesScreen(),
            InvestmentsScreen(),
            DocumentsScreen(),
            SettingsScreen(),
          ],
        ),
      ),
      bottomNavigationBar: AppBottomNavigation(
        currentIndex: _currentIndex,
        onTap: _onNavigationTap,
      ),
    );
  }
}

class _TabDestination {
  final String title;

  const _TabDestination({required this.title});
}
