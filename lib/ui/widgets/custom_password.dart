import 'package:flutter/material.dart';

class CustomPassword extends StatefulWidget {
  final TextEditingController controller;
  final String fieldLabel;
  final String hintText;
  final String errorMessage;
  final bool? needTitle;
  final TextInputAction? textInputAction;
  final TextStyle? hintTextStyle;
  final TextStyle? inputTextStyle;
  final Key? itemkey;
  final TextStyle? titleStyle;
  final FormFieldValidator<String>? validatorClass;

  const CustomPassword({
    super.key,
    required this.controller,
    required this.fieldLabel,
    required this.hintText,
    required this.errorMessage,
    this.needTitle,
    this.textInputAction,
    this.hintTextStyle,
    this.itemkey,
    this.titleStyle,
    this.validatorClass,
    this.inputTextStyle,
  });

  @override
  State<CustomPassword> createState() => _CustomPasswordState();
}

class _CustomPasswordState extends State<CustomPassword> {
  late FocusNode _focusNode;
  late ValueNotifier<bool> isFocusedNotifier;
  late ValueNotifier<bool> obscureTextNotifier;

  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode();
    isFocusedNotifier = ValueNotifier(false);
    obscureTextNotifier = ValueNotifier(true);

    _focusNode.addListener(() {
      isFocusedNotifier.value = _focusNode.hasFocus;
    });
  }

  @override
  void dispose() {
    _focusNode.dispose();
    isFocusedNotifier.dispose();
    obscureTextNotifier.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final onSurface60 = cs.onSurface.withAlpha(153);

    return ValueListenableBuilder<bool>(
      valueListenable: isFocusedNotifier,
      builder: (context, isFocused, _) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (widget.needTitle ?? true) ...[
              Text(
                widget.fieldLabel,
                style:
                    widget.titleStyle ??
                    theme.textTheme.titleMedium?.copyWith(color: cs.onSurface),
              ),
              const SizedBox(height: 8),
            ],
            ValueListenableBuilder<bool>(
              valueListenable: obscureTextNotifier,
              builder: (context, isObscure, _) {
                return TextFormField(
                  key: widget.itemkey,
                  controller: widget.controller,
                  focusNode: _focusNode,
                  obscureText: isObscure,
                  keyboardType: TextInputType.visiblePassword,
                  textInputAction:
                      widget.textInputAction ?? TextInputAction.done,
                  autovalidateMode: AutovalidateMode.onUnfocus,
                  style:
                      widget.inputTextStyle ??
                      theme.textTheme.bodyLarge?.copyWith(color: cs.onSurface),
                  decoration: InputDecoration(
                    hintText: widget.hintText,
                    hintStyle:
                        widget.hintTextStyle ??
                        theme.textTheme.bodyLarge?.copyWith(color: onSurface60),
                    filled: true,
                    fillColor: cs.surface,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 16,
                    ),
                    suffixIcon: IconButton(
                      icon: Icon(
                        isObscure ? Icons.visibility_off : Icons.visibility,
                        color: cs.onSurface.withAlpha(180),
                      ),
                      onPressed: () {
                        obscureTextNotifier.value = !isObscure;
                      },
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: cs.onSurface.withAlpha(60), // Light version of primary
                        width: 1.5,
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: cs.onSurface.withAlpha(60), // Same here
                        width: 1.5,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: cs.primary, width: 2),
                    ),
                    errorBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: cs.error, width: 1.5),
                    ),
                    focusedErrorBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: cs.error, width: 2),
                    ),
                  ),
                  validator:
                      widget.validatorClass ??
                      (value) {
                        if (value == null || value.isEmpty) {
                          return "Password is required";
                        } else if (!RegExp(r'[A-Z]').hasMatch(value)) {
                          return "Include at least one uppercase letter";
                        } else if (!RegExp(r'[a-z]').hasMatch(value)) {
                          return "Include at least one lowercase letter";
                        } else if (!RegExp(r'[0-9]').hasMatch(value)) {
                          return "Include at least one number";
                        } else if (!RegExp(
                          r'[!@#\$&*~%^()_+=<>?/-]',
                        ).hasMatch(value)) {
                          return "Include at least one special character";
                        } else if (value.length < 6) {
                          return "Password must be at least 6 characters";
                        }

                        return null;
                      },
                );
              },
            ),
          ],
        );
      },
    );
  }
}
