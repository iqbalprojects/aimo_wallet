import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/app_theme.dart';

/// Secure Text Field
/// 
/// Text field for PIN entry with security features:
/// - Obscured text
/// - Numeric keyboard
/// - Max length enforcement
/// - No copy/paste
/// 
/// Usage:
/// ```dart
/// SecureTextField(
///   label: 'Enter PIN',
///   onChanged: (pin) => controller.updatePin(pin),
///   maxLength: 6,
/// )
/// ```
class SecureTextField extends StatefulWidget {
  final String label;
  final String? hint;
  final ValueChanged<String>? onChanged;
  final VoidCallback? onSubmitted;
  final int maxLength;
  final TextEditingController? controller;
  final String? errorText;
  final bool autofocus;

  const SecureTextField({
    super.key,
    required this.label,
    this.hint,
    this.onChanged,
    this.onSubmitted,
    this.maxLength = 6,
    this.controller,
    this.errorText,
    this.autofocus = false,
  });

  @override
  State<SecureTextField> createState() => _SecureTextFieldState();
}

class _SecureTextFieldState extends State<SecureTextField> {
  bool _isObscured = true;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.label,
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: AppTheme.spacingS),
        TextField(
          controller: widget.controller,
          obscureText: _isObscured,
          autofocus: widget.autofocus,
          keyboardType: TextInputType.number,
          maxLength: widget.maxLength,
          onChanged: widget.onChanged,
          onSubmitted: (_) => widget.onSubmitted?.call(),
          // Security: Disable copy/paste for PIN
          enableInteractiveSelection: false,
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
            LengthLimitingTextInputFormatter(widget.maxLength),
          ],
          decoration: InputDecoration(
            hintText: widget.hint ?? '••••••',
            counterText: '',
            errorText: widget.errorText,
            suffixIcon: IconButton(
              icon: Icon(
                _isObscured ? Icons.visibility_off : Icons.visibility,
                color: AppTheme.textSecondary,
              ),
              onPressed: () {
                setState(() {
                  _isObscured = !_isObscured;
                });
              },
            ),
          ),
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            letterSpacing: 4,
          ),
        ),
      ],
    );
  }
}
