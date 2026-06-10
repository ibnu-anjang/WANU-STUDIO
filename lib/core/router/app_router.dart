import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../features/auth/presentation/login_screen.dart';
import '../../features/cart/presentation/cart_screen.dart';
import '../../features/checkout/presentation/checkout_screen.dart';
import '../../features/feed/presentation/feed_screen.dart';
import '../../features/feed/presentation/manage_feed_screen.dart';
import '../../features/feed/presentation/upload_video_screen.dart';
import '../../features/order/presentation/admin_orders_screen.dart';
import '../../features/order/presentation/order_detail_screen.dart';
import '../../features/order/presentation/orders_screen.dart';
import '../../features/profile/application/profile_controller.dart';
import '../../features/profile/data/address.dart';
import '../../features/profile/presentation/address_form_screen.dart';
import '../../features/profile/presentation/addresses_screen.dart';
import '../../features/profile/presentation/edit_profile_screen.dart';
import '../../features/profile/presentation/promote_admin_screen.dart';
import '../../features/product/data/product.dart';
import '../../features/product/presentation/catalog_screen.dart';
import '../../features/product/presentation/product_detail_screen.dart';
import '../../features/product/presentation/product_form_screen.dart';
import '../../features/product/presentation/product_list_screen.dart';
import '../../features/profile/presentation/profile_screen.dart';
import '../../shared/widgets/main_scaffold.dart';
import '../supabase/supabase_providers.dart';

part 'app_router.g.dart';

@riverpod
GoRouter goRouter(Ref ref) {
  final auth = ref.watch(supabaseClientProvider).auth;
  final refresh = _AuthRefreshStream(auth.onAuthStateChange);
  ref.onDispose(refresh.dispose);

  return GoRouter(
    initialLocation: '/feed',
    refreshListenable: refresh,
    redirect: (context, state) {
      final loggedIn = auth.currentSession != null;
      final atLogin = state.matchedLocation == '/login';
      if (!loggedIn) return atLogin ? null : '/login';
      if (atLogin) return '/feed';
      return null;
    },
    routes: [
      GoRoute(path: '/login', builder: (_, _) => const LoginScreen()),
      StatefulShellRoute.indexedStack(
        builder: (_, _, shell) => MainScaffold(navigationShell: shell),
        branches: [
          StatefulShellBranch(
            routes: [GoRoute(path: '/feed', builder: (_, _) => const FeedScreen())],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(path: '/explore', builder: (_, _) => const _ExploreBranch()),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(path: '/profile', builder: (_, _) => const ProfileScreen()),
            ],
          ),
        ],
      ),
      GoRoute(
        path: '/profile/edit',
        builder: (_, _) => const EditProfileScreen(),
      ),
      GoRoute(
        path: '/profile/addresses',
        builder: (_, _) => const AddressesScreen(),
      ),
      GoRoute(
        path: '/profile/addresses/form',
        builder: (_, state) =>
            AddressFormScreen(existing: state.extra as Address?),
      ),
      GoRoute(
        path: '/admin/products',
        builder: (_, _) => const ProductListScreen(),
      ),
      GoRoute(
        path: '/admin/products/form',
        builder: (_, state) =>
            ProductFormScreen(existing: state.extra as Product?),
      ),
      GoRoute(
        path: '/admin/feed',
        builder: (_, _) => const ManageFeedScreen(),
      ),
      GoRoute(
        path: '/admin/promote',
        builder: (_, _) => const PromoteAdminScreen(),
      ),
      GoRoute(
        path: '/product/:id',
        builder: (_, state) =>
            ProductDetailScreen(productId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: '/feed/upload',
        builder: (_, _) => const UploadVideoScreen(),
      ),
      GoRoute(path: '/cart', builder: (_, _) => const CartScreen()),
      GoRoute(path: '/checkout', builder: (_, _) => const CheckoutScreen()),
      GoRoute(path: '/orders', builder: (_, _) => const OrdersScreen()),
      GoRoute(
        path: '/orders/:id',
        builder: (_, state) =>
            OrderDetailScreen(orderId: state.pathParameters['id']!),
      ),
    ],
  );
}

// Tab kedua: buyer lihat katalog, admin lihat kontrol pesanan masuk.
class _ExploreBranch extends ConsumerWidget {
  const _ExploreBranch();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isAdmin = ref.watch(currentProfileProvider).value?.isAdmin ?? false;
    return isAdmin ? const AdminOrdersScreen() : const CatalogScreen();
  }
}

class _AuthRefreshStream extends ChangeNotifier {
  _AuthRefreshStream(Stream<AuthState> stream) {
    _sub = stream.asBroadcastStream().listen((_) => notifyListeners());
  }

  late final StreamSubscription<AuthState> _sub;

  @override
  void dispose() {
    _sub.cancel();
    super.dispose();
  }
}
