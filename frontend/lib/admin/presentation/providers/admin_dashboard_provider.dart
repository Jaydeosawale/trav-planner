import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/datasources/admin_dashboard_api.dart';
import '../../data/models/admin_dashboard_model.dart';

final adminDashboardApiProvider = Provider<AdminDashboardApi>(
  (ref) => AdminDashboardApi(),
);

final adminDashboardProvider = FutureProvider.autoDispose<AdminDashboardModel>((
  ref,
) async {
  final api = ref.read(adminDashboardApiProvider);

  return api.getDashboard();
});
