import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../repositories/jobs_repository.dart';

/// Phase 3D — withdraw control for a single application. Only rendered by
/// callers while [entry] is Pending; disabled/hidden rules for every other
/// status live in the caller per the prompt's Button Rules, since whether
/// the control is shown at all is a layout decision, not this widget's.
class WithdrawApplicationButton extends StatefulWidget {
  const WithdrawApplicationButton({super.key, required this.entry});

  final ApplicationEntry entry;

  @override
  State<WithdrawApplicationButton> createState() =>
      _WithdrawApplicationButtonState();
}

class _WithdrawApplicationButtonState
    extends State<WithdrawApplicationButton> {
  var _withdrawing = false;

  Future<void> _confirmAndWithdraw() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Withdraw Application?'),
        content: const Text(
            'Are you sure you want to withdraw this application?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFFE5484D)),
            child: const Text('Withdraw'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    setState(() => _withdrawing = true);
    try {
      await JobsRepository.instance.withdrawApplication(widget.entry.jobId);
    } on FirebaseException catch (e) {
      if (mounted) _showError(_messageForFirebaseError(e));
    } on StateError catch (e) {
      if (mounted) _showError(e.message);
    } catch (_) {
      if (mounted) {
        _showError('Something went wrong. Please try again.');
      }
    } finally {
      if (mounted) setState(() => _withdrawing = false);
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  String _messageForFirebaseError(FirebaseException e) {
    return switch (e.code) {
      'unavailable' =>
        'You appear to be offline. Please try again once connected.',
      'permission-denied' =>
        'You do not have permission to withdraw this application.',
      'not-found' => 'This application no longer exists.',
      _ => 'Could not withdraw the application. Please try again.',
    };
  }

  @override
  Widget build(BuildContext context) {
    // Button Rules: hidden once Withdrawn, disabled for every other
    // non-Pending status, enabled only while Pending.
    if (widget.entry.status == ApplicationStatus.withdrawn) {
      return const SizedBox.shrink();
    }
    final enabled = widget.entry.canWithdraw && !_withdrawing;
    return TextButton.icon(
      onPressed: enabled ? _confirmAndWithdraw : null,
      icon: _withdrawing
          ? const SizedBox(
              width: 14,
              height: 14,
              child: CircularProgressIndicator(strokeWidth: 2))
          : const Icon(Icons.undo_rounded, size: 17),
      label: Text(_withdrawing ? 'Withdrawing...' : 'Withdraw'),
      style: TextButton.styleFrom(foregroundColor: const Color(0xFFE5484D)),
    );
  }
}
