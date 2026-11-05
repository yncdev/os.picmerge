import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../l10n/app_localizations.dart';
import '../merge_controller.dart';

/// 저장 중 진행 표시와 취소 버튼 (DESIGN §2.2).
class ProgressOverlay extends StatelessWidget {
  const ProgressOverlay({super.key, required this.state, required this.onCancel});

  final MergeRunning state;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l = AppLocalizations.of(context);
    final (String title, double? value) = switch (state.phase) {
      MergePhase.images => (
          l.processingImages(math.min(state.completed + 1, state.total), state.total),
          state.total == 0 ? 0.0 : state.completed / state.total,
        ),
      MergePhase.building => (l.buildingFile, null),
      MergePhase.saving => (state.isShare ? l.openingShare : l.saving, null),
    };

    return Stack(
      children: [
        const ModalBarrier(dismissible: false, color: Colors.black54),
        Center(
          child: Card(
            margin: const EdgeInsets.all(32),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 12),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    state.isShare ? l.shareTitle(state.format.label) : l.saveAs(state.format.label),
                    style: theme.textTheme.titleMedium,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  if (value != null)
                    LinearProgressIndicator(value: value)
                  else
                    const SizedBox(
                      width: 36,
                      height: 36,
                      child: CircularProgressIndicator(),
                    ),
                  const SizedBox(height: 12),
                  Text(state.cancelling ? l.cancelling : title, textAlign: TextAlign.center),
                  if (state.phase == MergePhase.building)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        l.mayTakeLong,
                        style: theme.textTheme.bodySmall,
                        textAlign: TextAlign.center,
                      ),
                    ),
                  const SizedBox(height: 4),
                  Text(
                    l.keepAppOpen,
                    style: theme.textTheme.bodySmall,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: state.canCancel ? onCancel : null,
                    child: Text(l.cancel),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
