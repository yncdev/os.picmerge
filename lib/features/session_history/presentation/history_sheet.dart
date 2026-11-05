import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/config/limits.dart';
import '../../../l10n/app_localizations.dart';
import '../../../l10n/l10n_messages.dart';
import '../../../shared/format.dart';
import '../../../shared/theme.dart';
import '../domain/session_record.dart';
import 'history_provider.dart';

Future<void> showHistorySheet(BuildContext context) => showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) => AnnotatedRegion<SystemUiOverlayStyle>(
        value: navBarOverlayStyle(context, background: Theme.of(context).colorScheme.surface),
        child: const FractionallySizedBox(heightFactor: 0.75, child: HistorySheet()),
      ),
    );

/// 최근 기록 (DESIGN §2.2). 읽기 전용.
class HistorySheet extends ConsumerWidget {
  const HistorySheet({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final history = ref.watch(historyProvider);
    final l = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
          child: Text(l.recentHistory, style: theme.textTheme.titleLarge),
        ),
        Expanded(
          child: switch (history) {
            AsyncData(:final value) => _HistoryBody(summary: value),
            AsyncError() => Center(child: Text(l.errorLoadHistory)),
            _ => const Center(child: CircularProgressIndicator()),
          },
        ),
      ],
    );
  }
}

class _HistoryBody extends StatelessWidget {
  const _HistoryBody({required this.summary});

  final HistorySummary summary;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l = AppLocalizations.of(context);
    final rate = summary.rate;
    final ratio = rate.ratio;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
          child: Text(
            ratio == null
                ? l.historyRateEmpty(kHistoryRateDays)
                : l.historyRate(kHistoryRateDays, (ratio * 100).round(), rate.success, rate.total),
            style: theme.textTheme.bodyMedium,
          ),
        ),
        const Divider(height: 1),
        Expanded(
          child: summary.records.isEmpty
              ? Center(child: Text(l.historyEmpty))
              : ListView.separated(
                  itemCount: summary.records.length,
                  separatorBuilder: (_, _) => const Divider(height: 1, indent: 56),
                  itemBuilder: (_, i) => _HistoryTile(record: summary.records[i]),
                ),
        ),
      ],
    );
  }
}

class _HistoryTile extends StatelessWidget {
  const _HistoryTile({required this.record});

  final SessionRecord record;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final l = AppLocalizations.of(context);
    final (IconData icon, Color color) = switch (record.status) {
      SessionStatus.success => (Icons.check_circle, Colors.green),
      SessionStatus.failed => (Icons.error, colors.error),
      SessionStatus.crashed => (Icons.warning_amber, Colors.orange),
      SessionStatus.cancelled => (Icons.cancel_outlined, colors.outline),
      SessionStatus.running => (Icons.hourglass_empty, colors.outline),
    };
    final details = [
      formatDateTime(record.startedAt),
      record.format.label,
      l.imageCount(record.imageCount),
      if (record.outputBytes != null && record.status == SessionStatus.success)
        formatBytes(record.outputBytes!),
      if (record.outputFolder != null) l.outputFolderName(record.outputFolder!),
    ].join(' · ');
    final error = record.errorCode;
    return ListTile(
      leading: Icon(icon, color: color),
      title: Text(
        record.outputName ?? l.sessionStatus(record.status),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Text(
        error == null ? details : '$details\n${l.mergeError(error)}',
      ),
      isThreeLine: error != null,
    );
  }
}
