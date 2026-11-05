import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers.dart';
import '../domain/session_record.dart';

class HistorySummary {
  const HistorySummary({required this.records, required this.rate});

  final List<SessionRecord> records;
  final SuccessRate rate;
}

/// 시트를 열 때마다 새로 읽는다.
final historyProvider = FutureProvider.autoDispose<HistorySummary>((ref) async {
  final repo = ref.watch(sessionRepositoryProvider);
  return HistorySummary(records: await repo.recent(), rate: await repo.successRate());
});
