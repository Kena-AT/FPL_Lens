import 'dart:async';
import 'package:flutter/material.dart';
import '../theme/tokens.dart';
import 'app_text_field.dart';

enum TeamIdStatus {
  idle,
  checking,
  valid,
  notFound,
  alreadyRegistered,
}

class TeamIdField extends StatefulWidget {
  final TextEditingController? controller;
  final ValueChanged<int?>? onResolved;
  final Future<TeamIdStatus> Function(int teamId)? onValidate;
  final bool enabled;

  const TeamIdField({
    super.key,
    this.controller,
    this.onResolved,
    this.onValidate,
    this.enabled = true,
  });

  @override
  State<TeamIdField> createState() => _TeamIdFieldState();
}

class _TeamIdFieldState extends State<TeamIdField> {
  late final TextEditingController _controller;
  Timer? _debounceTimer;
  TeamIdStatus _status = TeamIdStatus.idle;
  int _latestQueryId = 0;

  @override
  void initState() {
    super.initState();
    _controller = widget.controller ?? TextEditingController();
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    if (widget.controller == null) {
      _controller.dispose();
    }
    super.dispose();
  }

  void _onChanged(String val) {
    _debounceTimer?.cancel();
    final trimmed = val.trim();
    if (trimmed.isEmpty) {
      setState(() => _status = TeamIdStatus.idle);
      widget.onResolved?.call(null);
      return;
    }

    final id = int.tryParse(trimmed);
    if (id == null || id <= 0) {
      setState(() => _status = TeamIdStatus.notFound);
      widget.onResolved?.call(null);
      return;
    }

    setState(() => _status = TeamIdStatus.checking);
    final queryId = ++_latestQueryId;

    _debounceTimer = Timer(const Duration(milliseconds: 500), () async {
      if (widget.onValidate != null) {
        final result = await widget.onValidate!(id);
        if (queryId == _latestQueryId && mounted) {
          setState(() => _status = result);
          if (result == TeamIdStatus.valid) {
            widget.onResolved?.call(id);
          } else {
            widget.onResolved?.call(null);
          }
        }
      } else {
        if (queryId == _latestQueryId && mounted) {
          setState(() => _status = TeamIdStatus.valid);
          widget.onResolved?.call(id);
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    Widget? suffix;
    String? error;
    String? helper = "Find your team ID on the FPL website under Points.";

    switch (_status) {
      case TeamIdStatus.idle:
        break;
      case TeamIdStatus.checking:
        suffix = const Padding(
          padding: EdgeInsets.all(AppTokens.space12),
          child: SizedBox(
            width: 16.0,
            height: 16.0,
            child: CircularProgressIndicator(strokeWidth: 2.0, color: AppTokens.neonPrimary),
          ),
        );
        break;
      case TeamIdStatus.valid:
        suffix = const Icon(Icons.check_circle_outline, color: AppTokens.statusAvailable, size: 20.0);
        helper = "Team found";
        break;
      case TeamIdStatus.notFound:
        error = "We couldn't find a team with that ID. Check it on the FPL website and try again.";
        break;
      case TeamIdStatus.alreadyRegistered:
        error = "This FPL team is already linked to an FPL Lens account.";
        break;
    }

    return AppTextField(
      label: "FPL team ID",
      hint: "e.g. 123456",
      controller: _controller,
      type: AppTextFieldType.numeric,
      maxLength: 10,
      enabled: widget.enabled,
      helper: error == null ? helper : null,
      error: error,
      suffix: suffix,
      onChanged: _onChanged,
    );
  }
}
