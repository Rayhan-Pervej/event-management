import 'package:flutter/material.dart';

class CustomTimeInput extends StatefulWidget {
  final TimeOfDay? selectedTime;
  final String fieldLabel;
  final String hintText;
  final bool validation;
  final String errorMessage;
  final bool? needTitle;
  final TextStyle? hintTextStyle;
  final TextStyle? inputTextStyle;
  final Key? itemkey;
  final TextStyle? titleStyle;
  final Widget? prefixWidget;
  final Widget? suffixWidget;
  final bool? viewOnly;
  final String? Function(TimeOfDay?)? validatorClass;
  final Function(TimeOfDay?)? onChanged;
  final VoidCallback? onTap;
  final bool? showLoading;
  final bool? autofocus;
  final bool? use24HourFormat;

  const CustomTimeInput({
    super.key,
    required this.selectedTime,
    required this.fieldLabel,
    required this.hintText,
    required this.validation,
    required this.errorMessage,
    this.needTitle,
    this.hintTextStyle,
    this.itemkey,
    this.titleStyle,
    this.prefixWidget,
    this.suffixWidget,
    this.viewOnly,
    this.validatorClass,
    this.inputTextStyle,
    this.onChanged,
    this.onTap,
    this.showLoading,
    this.autofocus,
    this.use24HourFormat,
  });

  @override
  State<CustomTimeInput> createState() => _CustomTimeInputState();
}

class _CustomTimeInputState extends State<CustomTimeInput> {
  late FocusNode _focusNode;
  late ValueNotifier<bool> isFocusedNotifier;
  late TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode();
    isFocusedNotifier = ValueNotifier(false);
    _controller = TextEditingController();

    _focusNode.addListener(() {
      isFocusedNotifier.value = _focusNode.hasFocus;
    });

    _updateControllerText();
  }

  @override
  void didUpdateWidget(CustomTimeInput oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedTime != widget.selectedTime) {
      _updateControllerText();
    }
  }

  void _updateControllerText() {
    if (widget.selectedTime != null) {
      _controller.text = _formatTime(widget.selectedTime!);
    } else {
      _controller.clear();
    }
  }

  String _formatTime(TimeOfDay time) {
    if (widget.use24HourFormat == true) {
      return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
    } else {
      final hour = time.hourOfPeriod == 0 ? 12 : time.hourOfPeriod;
      final period = time.period == DayPeriod.am ? 'AM' : 'PM';
      return '${hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')} $period';
    }
  }

  @override
  void dispose() {
    _focusNode.dispose();
    isFocusedNotifier.dispose();
    _controller.dispose();
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

    return widget.suffixWidget ?? 
        Icon(
          Icons.access_time,
          color: colorScheme.onSurface.withAlpha(153),
          size: 20,
        );
  }

  Future<void> _selectTime() async {
    if (widget.viewOnly == true) return;

    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: widget.selectedTime ?? TimeOfDay.now(),
      builder: (context, child) {
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(
            alwaysUse24HourFormat: widget.use24HourFormat ?? false,
          ),
          child: child!,
        );
      },
    );

    if (picked != null && picked != widget.selectedTime) {
      widget.onChanged?.call(picked);
    }
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
              controller: _controller,
              focusNode: _focusNode,
              readOnly: true,
              autofocus: widget.autofocus ?? false,
              autovalidateMode: widget.validation 
                  ? AutovalidateMode.onUnfocus 
                  : AutovalidateMode.disabled,
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
              validator: widget.validation 
                  ? (value) => widget.validatorClass?.call(widget.selectedTime) 
                  : null,
              onTap: () {
                widget.onTap?.call();
                _selectTime();
              },
            ),
          ],
        );
      },
    );
  }
}