import 'package:flutter/material.dart';

import '../../data/models/device_command.dart';
import '../../data/repositories/aquarium_repository.dart';
import '../../widgets/glass_panel.dart';

class ControlScreen extends StatefulWidget {
  const ControlScreen({required this.repository, super.key});

  final AquariumRepository? repository;

  @override
  State<ControlScreen> createState() => _ControlScreenState();
}

class _ControlScreenState extends State<ControlScreen> {
  bool _isSubmitting = false;
  bool _isRefreshingStatus = false;
  String? _activeAction;
  DeviceCommand? _lastCommand;
  String? _errorMessage;

  bool get _commandsEnabled => widget.repository?.commandControlEnabled ?? false;

  Future<void> _submitPumpCommand(bool turnOn) async {
    await _submit(
      action: turnOn ? 'pump_on' : 'pump_off',
      request: (repository) => repository.requestPumpState(turnOn),
    );
  }

  Future<void> _submitFeedCommand() async {
    final lastCommand = _lastCommand;
    if (lastCommand != null &&
        lastCommand.command == 'FEED_NOW' &&
        !lastCommand.isTerminal &&
        !lastCommand.isExpiredAt(DateTime.now())) {
      _showMessage('A feeding command is still awaiting device confirmation.');
      return;
    }

    await _submit(
      action: 'feed',
      request: (repository) => repository.requestFeeding(),
    );
  }

  Future<void> _submit({
    required String action,
    required Future<DeviceCommand> Function(AquariumRepository repository) request,
  }) async {
    final repository = widget.repository;
    if (!_commandsEnabled || repository == null || _isSubmitting) return;

    setState(() {
      _isSubmitting = true;
      _activeAction = action;
      _errorMessage = null;
    });

    try {
      final command = await request(repository);
      if (!mounted) return;
      setState(() => _lastCommand = command);
      _showMessage(
        'Command published. This does not confirm that the equipment operated.',
      );
    } catch (error) {
      if (!mounted) return;
      setState(() => _errorMessage = error.toString());
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
          _activeAction = null;
        });
      }
    }
  }

  Future<void> _refreshStatus() async {
    final repository = widget.repository;
    final command = _lastCommand;
    if (repository == null || command == null || _isRefreshingStatus) return;

    setState(() {
      _isRefreshingStatus = true;
      _errorMessage = null;
    });

    try {
      final updated = await repository.refreshCommandStatus(command.commandId);
      if (!mounted) return;
      setState(() => _lastCommand = updated);
    } catch (error) {
      if (!mounted) return;
      setState(() => _errorMessage = error.toString());
    } finally {
      if (mounted) setState(() => _isRefreshingStatus = false);
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final repositoryAvailable = widget.repository != null;
    final command = _lastCommand;
    final now = DateTime.now();
    final feedPending = command != null &&
        command.command == 'FEED_NOW' &&
        !command.isTerminal &&
        !command.isExpiredAt(now);

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(title: const Text('Equipment control'), titleSpacing: 20),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(18, 12, 18, 28),
        children: [
          _SafetyNotice(
            enabled: _commandsEnabled,
            repositoryAvailable: repositoryAvailable,
          ),
          const SizedBox(height: 16),
          _PumpGlassCard(
            enabled: _commandsEnabled && !_isSubmitting,
            isSubmitting: _isSubmitting && _activeAction?.startsWith('pump_') == true,
            onTurnOn: () => _submitPumpCommand(true),
            onTurnOff: () => _submitPumpCommand(false),
          ),
          const SizedBox(height: 12),
          _FeederGlassCard(
            enabled: _commandsEnabled && !_isSubmitting && !feedPending,
            isSubmitting: _isSubmitting && _activeAction == 'feed',
            onFeedNow: _submitFeedCommand,
          ),
          if (_errorMessage != null) ...[
            const SizedBox(height: 12),
            GlassCard(
              color: theme.colorScheme.errorContainer.withValues(alpha: 0.28),
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Text(
                  _errorMessage!,
                  style: TextStyle(color: theme.colorScheme.onErrorContainer),
                ),
              ),
            ),
          ],
          if (command != null) ...[
            const SizedBox(height: 18),
            _CommandStatusGlassCard(
              command: command,
              now: now,
              isRefreshing: _isRefreshingStatus,
              onRefresh: _refreshStatus,
            ),
          ],
          const SizedBox(height: 18),
          Text(
            'A published command is not proof of operation. Only a device acknowledgement with verified physical feedback can confirm an actuator state.',
            style: theme.textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}

class _SafetyNotice extends StatelessWidget {
  const _SafetyNotice({
    required this.enabled,
    required this.repositoryAvailable,
  });

  final bool enabled;
  final bool repositoryAvailable;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final title = enabled ? 'Development controls enabled' : 'Controls are safely locked';
    final message = enabled
        ? 'The local command API is enabled. The ESP32 must still validate command expiry and safety interlocks, then acknowledge the actual actuator state.'
        : repositoryAvailable
            ? 'Command control is disabled by default. It can only be enabled after the ESP32 command handler, expiry checks, safe boot states, and physical feedback have been implemented and tested.'
            : 'The application has no initialized device repository. Configure the local development API before attempting command integration.';

    return GlassCard(
      color: theme.colorScheme.surfaceContainerHigh.withValues(alpha: 0.42),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              enabled ? Icons.info_outline : Icons.lock_outline,
              color: theme.colorScheme.primary,
              size: 28,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: theme.textTheme.titleSmall),
                  const SizedBox(height: 5),
                  Text(message, style: theme.textTheme.bodySmall),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PumpCard extends StatelessWidget {
  const _PumpGlassCard({
    required this.enabled,
    required this.isSubmitting,
    required this.onTurnOn,
    required this.onTurnOff,
  });

  final bool enabled;
  final bool isSubmitting;
  final VoidCallback onTurnOn;
  final VoidCallback onTurnOff;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.water_drop_outlined),
                SizedBox(width: 10),
                Text('Water pump', style: TextStyle(fontWeight: FontWeight.w700)),
              ],
            ),
            const SizedBox(height: 8),
            const Text('Current physical state: unknown'),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: FilledButton.icon(
                    onPressed: enabled && !isSubmitting ? onTurnOn : null,
                    icon: isSubmitting
                        ? const SizedBox.square(
                            dimension: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.play_arrow),
                    label: const Text('Turn ON'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: enabled && !isSubmitting ? onTurnOff : null,
                    icon: const Icon(Icons.stop),
                    label: const Text('Turn OFF'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _FeederCard extends StatelessWidget {
  const _FeederGlassCard({
    required this.enabled,
    required this.isSubmitting,
    required this.onFeedNow,
  });

  final bool enabled;
  final bool isSubmitting;
  final VoidCallback onFeedNow;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.pets_outlined),
                SizedBox(width: 10),
                Text('Automatic feeder', style: TextStyle(fontWeight: FontWeight.w700)),
              ],
            ),
            const SizedBox(height: 8),
            const Text('Manual feeding request. The device must enforce its own feeding limits.'),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: FilledButton.tonalIcon(
                onPressed: enabled && !isSubmitting ? onFeedNow : null,
                icon: isSubmitting
                    ? const SizedBox.square(
                        dimension: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.restaurant),
                label: const Text('Feed now'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CommandStatusCard extends StatelessWidget {
  const _CommandStatusGlassCard({
    required this.command,
    required this.now,
    required this.isRefreshing,
    required this.onRefresh,
  });

  final DeviceCommand command;
  final DateTime now;
  final bool isRefreshing;
  final VoidCallback onRefresh;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final verified = command.isVerifiedSuccess;
    final expired = command.isExpiredAt(now);
    final statusColor = verified
        ? theme.colorScheme.primary
        : command.status == 'failed' || command.status == 'rejected' || expired
            ? theme.colorScheme.error
            : theme.colorScheme.tertiary;

    final description = switch (command.command) {
      'SET_PUMP' => 'Pump target: ${command.requestedState ?? 'unknown'}',
      'FEED_NOW' => 'Manual feeding request',
      _ => command.command,
    };

    return GlassCard(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Latest command', style: TextStyle(fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            Text(description),
            const SizedBox(height: 6),
            Text(
              command.statusLabelAt(now),
              style: TextStyle(color: statusColor, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 6),
            Text(
              'Command ID: ${command.commandId}',
              style: theme.textTheme.bodySmall,
            ),
            if (command.acknowledgedAt != null) ...[
              const SizedBox(height: 4),
              Text(
                'Acknowledged: ${command.acknowledgedAt!.toLocal()}',
                style: theme.textTheme.bodySmall,
              ),
            ],
            if (command.message != null) ...[
              const SizedBox(height: 6),
              Text(command.message!, style: theme.textTheme.bodySmall),
            ],
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: isRefreshing ? null : onRefresh,
              icon: isRefreshing
                  ? const SizedBox.square(
                      dimension: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.refresh),
              label: const Text('Check device acknowledgement'),
            ),
            if (verified) ...[
              const SizedBox(height: 6),
              const Text('The device reported execution and verified the resulting state.'),
            ] else if (command.status == 'executed') ...[
              const SizedBox(height: 6),
              const Text('The device acknowledged execution, but physical state verification was not provided.'),
            ] else if (expired) ...[
              const SizedBox(height: 6),
              const Text('The app has reached the command expiry time. The device result remains unconfirmed until the backend reports an acknowledgement.'),
            ],
          ],
        ),
      ),
    );
  }
}
