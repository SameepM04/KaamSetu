import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/app_colors.dart';

/// A row of 6 individual OTP digit boxes with auto-focus, auto-advance,
/// backspace-to-previous, and paste support.
class OtpFieldRow extends StatefulWidget {
  const OtpFieldRow({
    super.key,
    required this.length,
    required this.onChanged,
    required this.onCompleted,
  });

  final int length;
  final ValueChanged<String> onChanged;
  final ValueChanged<String> onCompleted;

  @override
  State<OtpFieldRow> createState() => OtpFieldRowState();
}

class OtpFieldRowState extends State<OtpFieldRow> {
  late final List<TextEditingController> _controllers =
      List.generate(widget.length, (_) => TextEditingController());
  late final List<FocusNode> _nodes =
      List.generate(widget.length, (_) => FocusNode());

  @override
  void dispose() {
    for (final c in _controllers) {
      c.dispose();
    }
    for (final n in _nodes) {
      n.dispose();
    }
    super.dispose();
  }

  String get _code => _controllers.map((c) => c.text).join();

  void clear() {
    for (final c in _controllers) {
      c.clear();
    }
    _nodes.first.requestFocus();
    widget.onChanged('');
  }

  void _handlePaste(String pasted, int startIndex) {
    final digits = pasted.replaceAll(RegExp(r'\D'), '');
    if (digits.isEmpty) return;
    var i = startIndex;
    for (final d in digits.split('')) {
      if (i >= widget.length) break;
      _controllers[i].text = d;
      i++;
    }
    final nextIndex = i.clamp(0, widget.length - 1);
    _nodes[nextIndex].requestFocus();
    widget.onChanged(_code);
    if (_code.length == widget.length) widget.onCompleted(_code);
  }

  void _onChanged(int index, String value) {
    if (value.length > 1) {
      // Pasted content landed in one field.
      _handlePaste(value, index);
      return;
    }
    if (value.isNotEmpty && index < widget.length - 1) {
      _nodes[index + 1].requestFocus();
    }
    widget.onChanged(_code);
    if (_code.length == widget.length) {
      widget.onCompleted(_code);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Responsive: each box flexes to share the available width equally
    // (with a small gap between boxes) instead of using a fixed pixel
    // width, so the row never overflows on narrower screens while keeping
    // the same look on the approved design's target widths.
    return Row(
      children: List.generate(widget.length, (index) {
        final isLast = index == widget.length - 1;
        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(right: isLast ? 0 : 8),
            child: _DigitBox(
              controller: _controllers[index],
              focusNode: _nodes[index],
              autofocus: index == 0,
              onChanged: (value) => _onChanged(index, value),
              onBackspaceEmpty: () {
                if (index > 0) {
                  _controllers[index - 1].clear();
                  _nodes[index - 1].requestFocus();
                  widget.onChanged(_code);
                }
              },
            ),
          ),
        );
      }),
    );
  }
}

class _DigitBox extends StatefulWidget {
  const _DigitBox({
    required this.controller,
    required this.focusNode,
    required this.autofocus,
    required this.onChanged,
    required this.onBackspaceEmpty,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final bool autofocus;
  final ValueChanged<String> onChanged;
  final VoidCallback onBackspaceEmpty;

  @override
  State<_DigitBox> createState() => _DigitBoxState();
}

class _DigitBoxState extends State<_DigitBox> {
  @override
  void initState() {
    super.initState();
    widget.focusNode.addListener(() => setState(() {}));
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 56,
      child: KeyboardListener(
        focusNode: FocusNode(skipTraversal: true, canRequestFocus: false),
        onKeyEvent: (event) {
          if (event is KeyDownEvent &&
              event.logicalKey == LogicalKeyboardKey.backspace &&
              widget.controller.text.isEmpty) {
            widget.onBackspaceEmpty();
          }
        },
        child: TextField(
          controller: widget.controller,
          focusNode: widget.focusNode,
          autofocus: widget.autofocus,
          textAlign: TextAlign.center,
          keyboardType: TextInputType.number,
          maxLength: 6, // allow paste of the whole code into one box
          style: const TextStyle(
            color: AppColors.navy,
            fontSize: 22,
            fontWeight: FontWeight.w700,
          ),
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          decoration: InputDecoration(
            counterText: '',
            filled: true,
            fillColor: Colors.white,
            contentPadding: EdgeInsets.zero,
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: AppColors.line, width: 1.4),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: AppColors.blue, width: 2),
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: AppColors.line, width: 1.4),
            ),
          ),
          onChanged: widget.onChanged,
        ),
      ),
    );
  }
}
