import 'package:flutter/material.dart';

class CustomInput extends StatefulWidget {
  final TextEditingController controller;
  final String fieldLabel;
  final String hintText;
  final bool validation;
  final String errorMessage;
  final bool? needTitle;
  final TextInputAction? textInputAction;
  final TextAlign? textAlign;
  final TextStyle? hintTextStyle;
  final TextStyle? inputTextStyle;
  final Key? itemkey;
  final TextStyle? titleStyle;
  final Widget? prefixWidget;
  final Widget? suffixWidget;
  final bool? viewOnly;
  final FormFieldValidator<String>? validatorClass;
  final TextInputType? inputType;
  final Function(String)? onChanged;
  final VoidCallback? onTap;
  final bool? showLoading;
  final int? maxLines;
  final int? minLines;
  final bool? autofocus;

  const CustomInput({
    super.key,
    required this.controller,
    required this.fieldLabel,
    required this.hintText,
    required this.validation,
    required this.errorMessage,
    this.needTitle,
    this.textInputAction,
    this.textAlign,
    this.hintTextStyle,
    this.itemkey,
    this.titleStyle,
    this.prefixWidget,
    this.suffixWidget,
    this.viewOnly,
    this.validatorClass,
    this.inputTextStyle,
    this.inputType,
    this.onChanged,
    this.onTap,
    this.showLoading,
    this.maxLines,
    this.minLines,
    this.autofocus,
  });

  @override
  State<CustomInput> createState() => _CustomInputState();
}

class _CustomInputState extends State<CustomInput> {
  late FocusNode _focusNode;
  late ValueNotifier<bool> isFocusedNotifier;

  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode();
    isFocusedNotifier = ValueNotifier(false);

    _focusNode.addListener(() {
      isFocusedNotifier.value = _focusNode.hasFocus;
    });
  }

  @override
  void dispose() {
    _focusNode.dispose();
    isFocusedNotifier.dispose();
    super.dispose();
  }

  Widget? _buildSuffixWidget() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    if (widget.showLoading == true) {
      return Padding(
        padding: const EdgeInsets.all(12),
        child: SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: colorScheme.primary,
          ),
        ),
      );
    }

    return widget.suffixWidget;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    // Define custom colors with alpha (153 is 60% opacity)
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
            TextFormField(
              key: widget.itemkey,
              controller: widget.controller,
              focusNode: _focusNode,
              readOnly: widget.viewOnly ?? false,
              autofocus: widget.autofocus ?? false,
              keyboardType: widget.inputType ?? TextInputType.text,
              textInputAction: widget.textInputAction ?? TextInputAction.next,
              autovalidateMode: widget.validation 
                  ? AutovalidateMode.onUnfocus 
                  : AutovalidateMode.disabled,
              textAlign: widget.textAlign ?? TextAlign.start,
              maxLines: widget.maxLines ?? 1,
              minLines: widget.minLines,
              onChanged: widget.onChanged,
              onTap: widget.onTap,
              style:
                  widget.inputTextStyle ??
                  theme.textTheme.bodyLarge?.copyWith(
                    color: widget.viewOnly == true ? onSurface60 : cs.onSurface,
                  ),
              decoration: InputDecoration(
                prefixIcon: widget.prefixWidget,
                suffixIcon: _buildSuffixWidget(),
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

                // Border states
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: cs.onSurface.withAlpha(60),
                    width: 1.5,
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: cs.onSurface.withAlpha(60),
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
              validator: widget.validation ? widget.validatorClass : null,
            ),
          ],
        );
      },
    );
  }
}