import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/connectivity_service.dart';
import '../services/sync_service.dart';
import '../../data/local/offline_database.dart';

// ═══════════════════════════════════════════════════════════════════════════════
//  حالة الاتصال بالإنترنت
// ═══════════════════════════════════════════════════════════════════════════════

/// Provider يُعطي حالة الاتصال الحالية (true = متصل، false = غير متصل)
final connectivityProvider =
    StreamNotifierProvider<ConnectivityNotifier, bool>(ConnectivityNotifier.new);

class ConnectivityNotifier extends StreamNotifier<bool> {
  @override
  Stream<bool> build() {
    final service = ConnectivityService.instance;

    // نعيد stream التغيّرات مع قيمة أولية
    return Stream.value(service.isOnline)
        .asyncExpand((_) => service.onConnectivityChanged);
  }
}

/// هل الجهاز أونلاين حالياً (مباشر)
final isOnlineProvider = Provider<bool>((ref) {
  return ref.watch(connectivityProvider).valueOrNull ?? true;
});

// ═══════════════════════════════════════════════════════════════════════════════
//  حالة المزامنة
// ═══════════════════════════════════════════════════════════════════════════════

/// Provider يُعطي حالة المزامنة الحالية
final syncStatusProvider =
    StreamNotifierProvider<SyncStatusNotifier, SyncStatus>(
        SyncStatusNotifier.new);

class SyncStatusNotifier extends StreamNotifier<SyncStatus> {
  @override
  Stream<SyncStatus> build() {
    final service = SyncService.instance;
    return Stream.value(service.lastStatus)
        .asyncExpand((_) => service.syncStatusStream);
  }
}

/// تشغيل مزامنة يدوية
final syncNowProvider = FutureProvider.autoDispose<void>((ref) async {
  await SyncService.instance.syncAll();
});

/// عدد العمليات المعلقة (لم تُرفع بعد)
final pendingOperationsCountProvider = FutureProvider.autoDispose<int>((ref) {
  // إعادة الحساب كل مرة يتغير فيها حالة المزامنة
  ref.watch(syncStatusProvider);
  return OfflineDatabase.instance.getPendingCount();
});
