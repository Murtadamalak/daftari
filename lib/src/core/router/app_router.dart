import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/auth_provider.dart';
import '../../screens/auth/login_screen.dart';
import '../../screens/admin/admin_shell_screen.dart';
import '../../screens/admin/admin_dashboard_screen.dart';
import '../../screens/admin/admin_requests_screen.dart';
import '../../screens/admin/admin_users_screen.dart';
import '../../screens/admin/admin_settings_screen.dart';
import '../../screens/subscription_screen.dart';

import '../../screens/add_edit_product_screen.dart';
import '../../screens/customers_screen.dart';
import '../../screens/invoices_screen.dart';
import '../../screens/create_invoice_screen.dart';
import '../../screens/invoice_details_screen.dart';
import '../../screens/main_shell_screen.dart';
import '../../screens/products_screen.dart';
import '../../screens/reports_screen.dart';
import '../../screens/settings_screen.dart';
import '../../screens/comprehensive_reports_screen.dart';
import '../../screens/customer_debts_screen.dart';
import '../../screens/transactions_log_screen.dart';
import '../../screens/delayed_debts_screen.dart';

final GlobalKey<NavigatorState> _rootNavigatorKey = GlobalKey<NavigatorState>();

class RouterNotifier extends ChangeNotifier {
  final Ref ref;
  RouterNotifier(this.ref) {
    ref.listen<AppAuthState>(authProvider, (_, __) => notifyListeners());
  }
}

CustomTransitionPage<dynamic> _buildSmoothPage({
  required LocalKey key,
  required Widget child,
}) {
  return CustomTransitionPage<dynamic>(
    key: key,
    child: child,
    transitionDuration: const Duration(milliseconds: 260),
    reverseTransitionDuration: const Duration(milliseconds: 200),
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      final curvedAnimation = CurvedAnimation(
        parent: animation,
        curve: Curves.easeOutCubic,
        reverseCurve: Curves.easeInCubic,
      );

      return FadeTransition(
        opacity: Tween<double>(begin: 0.0, end: 1.0).animate(curvedAnimation),
        child: SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0.03, 0.0),
            end: Offset.zero,
          ).animate(curvedAnimation),
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.985, end: 1.0).animate(curvedAnimation),
            child: child,
          ),
        ),
      );
    },
  );
}

final appRouterProvider = Provider<GoRouter>((ref) {
  final refreshNotifier = RouterNotifier(ref);

  return GoRouter(
    refreshListenable: refreshNotifier,
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/login',
    redirect: (context, state) {
      final isLoggingIn = state.uri.path == '/login';
      final isSubScreen = state.uri.path == '/subscription';
      final authState = ref.read(authProvider);

      // If waiting for initialization
      if (authState.isLoading) return null;

      final role = authState.role;

      // Unauthenticated
      if (role == AuthRole.guest || role == AuthRole.initial) {
        return isLoggingIn ? null : '/login';
      }

      // Admin routing
      if (role == AuthRole.admin) {
        if (!state.uri.path.startsWith('/admin')) {
          return '/admin';
        }
        return null;
      }

      // Normal User routing (role == AuthRole.user)
      if (role == AuthRole.user) {
        final needsActivation =
            authState.planType == 'free' || authState.subStatus != 'active';

        if (needsActivation) {
          return isSubScreen ? null : '/subscription';
        }

        // If active user tries to access login, sub, or admin, go to invoices
        if (isLoggingIn || isSubScreen || state.uri.path.startsWith('/admin')) {
          return '/invoices';
        }

        return null;
      }

      return null;
    },
    routes: [
      GoRoute(
        path: '/login',
        pageBuilder: (context, state) => _buildSmoothPage(
          key: state.pageKey,
          child: const LoginScreen(),
        ),
      ),
      GoRoute(
        path: '/subscription',
        pageBuilder: (context, state) => _buildSmoothPage(
          key: state.pageKey,
          child: const SubscriptionScreen(),
        ),
      ),

      // ── Admin Shell ──────────────────────────────────────────────────
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return AdminShellScreen(navigationShell: navigationShell);
        },
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/admin',
                pageBuilder: (context, state) => _buildSmoothPage(
                  key: state.pageKey,
                  child: const AdminDashboardScreen(),
                ),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/admin/requests',
                pageBuilder: (context, state) => _buildSmoothPage(
                  key: state.pageKey,
                  child: const AdminRequestsScreen(),
                ),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/admin/users',
                pageBuilder: (context, state) => _buildSmoothPage(
                  key: state.pageKey,
                  child: const AdminUsersScreen(),
                ),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/admin/settings',
                pageBuilder: (context, state) => _buildSmoothPage(
                  key: state.pageKey,
                  child: const AdminSettingsScreen(),
                ),
              ),
            ],
          ),
        ],
      ),

      // ── Main Shell (User Flow) ─────────────────────────────────────────────────
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return MainShellScreen(navigationShell: navigationShell);
        },
        branches: [
          // ── Products ───────────────────────────────────────────────────────
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/products',
                pageBuilder: (context, state) => _buildSmoothPage(
                  key: state.pageKey,
                  child: const ProductsScreen(),
                ),
                routes: [
                  GoRoute(
                    path: 'add',
                    parentNavigatorKey: _rootNavigatorKey,
                    pageBuilder: (context, state) => _buildSmoothPage(
                      key: state.pageKey,
                      child: const AddEditProductScreen(),
                    ),
                  ),
                  GoRoute(
                    path: 'edit/:id',
                    parentNavigatorKey: _rootNavigatorKey,
                    pageBuilder: (context, state) {
                      final id = state.pathParameters['id']!;
                      return _buildSmoothPage(
                        key: state.pageKey,
                        child: AddEditProductScreen(productId: id),
                      );
                    },
                  ),
                ],
              ),
            ],
          ),

          // ── Customers ──────────────────────────────────────────────────────
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/customers',
                pageBuilder: (context, state) => _buildSmoothPage(
                  key: state.pageKey,
                  child: const CustomersScreen(),
                ),
                routes: [
                  GoRoute(
                    path: 'details/:id',
                    parentNavigatorKey: _rootNavigatorKey,
                    pageBuilder: (context, state) {
                      final id = state.pathParameters['id']!;
                      return _buildSmoothPage(
                        key: state.pageKey,
                        child: CustomerDebtsScreen(customerId: id),
                      );
                    },
                  ),
                  GoRoute(
                    path: 'delayed',
                    parentNavigatorKey: _rootNavigatorKey,
                    pageBuilder: (context, state) => _buildSmoothPage(
                      key: state.pageKey,
                      child: const DelayedDebtsScreen(),
                    ),
                  ),
                ],
              ),
            ],
          ),

          // ── Invoices ───────────────────────────────────────────────────────
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/invoices',
                pageBuilder: (context, state) => _buildSmoothPage(
                  key: state.pageKey,
                  child: const InvoicesScreen(),
                ),
                routes: [
                  GoRoute(
                    path: 'create',
                    parentNavigatorKey: _rootNavigatorKey,
                    pageBuilder: (context, state) => _buildSmoothPage(
                      key: state.pageKey,
                      child: const CreateInvoiceScreen(),
                    ),
                  ),
                  GoRoute(
                    path: 'details/:id',
                    parentNavigatorKey: _rootNavigatorKey,
                    pageBuilder: (context, state) {
                      final id = state.pathParameters['id']!;
                      return _buildSmoothPage(
                        key: state.pageKey,
                        child: InvoiceDetailsScreen(invoiceId: id),
                      );
                    },
                  ),
                  GoRoute(
                    path: 'edit/:id',
                    parentNavigatorKey: _rootNavigatorKey,
                    pageBuilder: (context, state) {
                      final id = state.pathParameters['id']!;
                      return _buildSmoothPage(
                        key: state.pageKey,
                        child: CreateInvoiceScreen(invoiceId: id),
                      );
                    },
                  ),
                ],
              ),
            ],
          ),

          // ── Reports / Dashboard ────────────────────────────────────────────
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/reports',
                pageBuilder: (context, state) => _buildSmoothPage(
                  key: state.pageKey,
                  child: const ReportsScreen(),
                ),
                routes: [
                  GoRoute(
                    path: 'comprehensive',
                    parentNavigatorKey: _rootNavigatorKey,
                    pageBuilder: (context, state) => _buildSmoothPage(
                      key: state.pageKey,
                      child: const ComprehensiveReportsScreen(),
                    ),
                  ),
                  GoRoute(
                    path: 'transactions',
                    parentNavigatorKey: _rootNavigatorKey,
                    pageBuilder: (context, state) => _buildSmoothPage(
                      key: state.pageKey,
                      child: const TransactionsLogScreen(),
                    ),
                  ),
                ],
              ),
            ],
          ),

          // ── Settings ───────────────────────────────────────────────────────
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/settings',
                pageBuilder: (context, state) => _buildSmoothPage(
                  key: state.pageKey,
                  child: const SettingsScreen(),
                ),
              ),
            ],
          ),
        ],
      ),
    ],
  );
});
