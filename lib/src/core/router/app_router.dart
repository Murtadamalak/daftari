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

final GlobalKey<NavigatorState> _rootNavigatorKey = GlobalKey<NavigatorState>();

class RouterNotifier extends ChangeNotifier {
  final Ref ref;
  RouterNotifier(this.ref) {
    ref.listen<AppAuthState>(authProvider, (_, __) => notifyListeners());
  }
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
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/subscription',
        builder: (context, state) => const SubscriptionScreen(),
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
                builder: (context, state) => const AdminDashboardScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/admin/requests',
                builder: (context, state) => const AdminRequestsScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/admin/users',
                builder: (context, state) => const AdminUsersScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/admin/settings',
                builder: (context, state) => const AdminSettingsScreen(),
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
                pageBuilder: (context, state) => MaterialPage(
                  key: state.pageKey,
                  child: const ProductsScreen(),
                ),
                routes: [
                  GoRoute(
                    path: 'add',
                    pageBuilder: (context, state) => MaterialPage(
                      key: state.pageKey,
                      child: const AddEditProductScreen(),
                    ),
                  ),
                  GoRoute(
                    path: 'edit/:id',
                    pageBuilder: (context, state) {
                      final id = state.pathParameters['id']!;
                      return MaterialPage(
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
                pageBuilder: (context, state) => MaterialPage(
                  key: state.pageKey,
                  child: const CustomersScreen(),
                ),
                routes: [
                  GoRoute(
                    path: 'details/:id',
                    pageBuilder: (context, state) {
                      final id = state.pathParameters['id']!;
                      // We can pass the customer object as an extra if needed, or just fetch it by ID in the screen.
                      return MaterialPage(
                        key: state.pageKey,
                        child: CustomerDebtsScreen(customerId: id),
                      );
                    },
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
                pageBuilder: (context, state) => MaterialPage(
                  key: state.pageKey,
                  child: const InvoicesScreen(),
                ),
                routes: [
                  GoRoute(
                    path: 'create',
                    pageBuilder: (context, state) => MaterialPage(
                      key: state.pageKey,
                      child: const CreateInvoiceScreen(),
                    ),
                  ),
                  GoRoute(
                    path: 'details/:id',
                    pageBuilder: (context, state) {
                      final id = state.pathParameters['id']!;
                      return MaterialPage(
                        key: state.pageKey,
                        child: InvoiceDetailsScreen(invoiceId: id),
                      );
                    },
                  ),
                  GoRoute(
                    path: 'edit/:id',
                    pageBuilder: (context, state) {
                      final id = state.pathParameters['id']!;
                      return MaterialPage(
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
                pageBuilder: (context, state) => MaterialPage(
                  key: state.pageKey,
                  child: const ReportsScreen(),
                ),
                routes: [
                  GoRoute(
                    path: 'comprehensive',
                    pageBuilder: (context, state) => MaterialPage(
                      key: state.pageKey,
                      child: const ComprehensiveReportsScreen(),
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
                pageBuilder: (context, state) => MaterialPage(
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
