import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/environment_data.dart';
import '../services/firebase_service.dart';
import '../state/providers.dart';

class DataSyncWrapper extends ConsumerWidget {
  final Widget child;

  const DataSyncWrapper({super.key, required this.child});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // ── Sync Environment Data ──
    ref.listen(firebaseSensorProvider, (previous, next) {
      if (next.hasValue) {
        ref.read(environmentProvider.notifier).update(next.value!);
      }
    });

    // ── Sync Devices Data ──
    ref.listen(firebaseDevicesProvider, (previous, next) {
      if (next.hasValue) {
        ref.read(devicesProvider.notifier).updateFromMap(next.value!);
      }
    });
    
    // We can also handle auth state syncing here if needed, 
    // but authStateProvider is usually watched directly by the router/UI.

    return child;
  }
}
