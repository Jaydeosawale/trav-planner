import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:in_app_update/in_app_update.dart';

/// Google Play owns update consent, download and installation. Unsupported
/// installs and offline checks must never prevent access to Trav.
class AppUpdatePrompt extends StatefulWidget {
  const AppUpdatePrompt({
    required this.messengerKey,
    required this.child,
    super.key,
  });

  final GlobalKey<ScaffoldMessengerState> messengerKey;
  final Widget child;

  @override
  State<AppUpdatePrompt> createState() => _AppUpdatePromptState();
}

class _AppUpdatePromptState extends State<AppUpdatePrompt>
    with WidgetsBindingObserver {
  bool _checking = false;
  bool _downloading = false;
  bool _installing = false;
  bool _ready = false;
  bool _readyShown = false;
  int? _promptedVersion;
  DateTime? _lastCheck;

  bool get _supported =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) => _check());
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // Also recovers a download completed while Trav was in the background.
      unawaited(_check());
    }
  }

  Future<void> _check() async {
    if (!_supported || !mounted || _checking || _installing) return;
    if (_ready) {
      _showReady();
      return;
    }
    if (_downloading) return;
    final now = DateTime.now();
    if (_lastCheck != null &&
        now.difference(_lastCheck!) < const Duration(minutes: 5)) {
      return;
    }
    _checking = true;
    _lastCheck = now;
    try {
      final info = await InAppUpdate.checkForUpdate();
      if (!mounted) return;
      if (info.installStatus == InstallStatus.downloaded) {
        _ready = true;
        _showReady();
      } else if (info.updateAvailability ==
              UpdateAvailability.updateAvailable &&
          info.flexibleUpdateAllowed &&
          info.availableVersionCode != null &&
          _promptedVersion != info.availableVersionCode) {
        final messenger = widget.messengerKey.currentState;
        if (messenger == null) return;
        _promptedVersion = info.availableVersionCode;
        messenger.showSnackBar(
          SnackBar(
            content: const Text('A new version of Trav is available.'),
            duration: const Duration(seconds: 12),
            action: SnackBarAction(
              label: 'Update',
              onPressed: () => unawaited(_download()),
            ),
          ),
        );
      }
    } catch (_) {
      // Play can be unavailable offline, on emulators or for sideloaded APKs.
    } finally {
      _checking = false;
    }
  }

  Future<void> _download() async {
    if (_downloading || !mounted) return;
    _downloading = true;
    try {
      final result = await InAppUpdate.startFlexibleUpdate();
      if (!mounted) return;
      if (result == AppUpdateResult.success) {
        _ready = true;
        _showReady();
      } else if (result == AppUpdateResult.inAppUpdateFailed) {
        _showFailure();
      }
    } catch (_) {
      if (mounted) _showFailure();
    } finally {
      _downloading = false;
      // A resumed lifecycle check can recover a completed download.
      _lastCheck = null;
    }
  }

  void _showReady() {
    if (!mounted || _readyShown || _installing) return;
    final messenger = widget.messengerKey.currentState;
    if (messenger == null) return;
    _readyShown = true;
    messenger
        .showSnackBar(
          SnackBar(
            content: const Text(
              'Trav is ready to update. Restart when convenient.',
            ),
            duration: const Duration(days: 1),
            action: SnackBarAction(
              label: 'Restart',
              onPressed: () => unawaited(_install()),
            ),
          ),
        )
        .closed
        .then((_) => _readyShown = false);
  }

  Future<void> _install() async {
    if (_installing) return;
    _installing = true;
    try {
      await InAppUpdate.completeFlexibleUpdate();
    } catch (_) {
      if (mounted) _showFailure();
    } finally {
      _installing = false;
    }
  }

  void _showFailure() {
    widget.messengerKey.currentState?.showSnackBar(
      const SnackBar(
        content: Text('Update unavailable right now. You can keep using Trav.'),
      ),
    );
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
