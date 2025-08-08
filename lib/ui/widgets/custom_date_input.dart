import 'package:flutter/material.dart';

class CustomDateInput extends StatefulWidget {
  final DateTime? selectedDate;
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
  final String? Function(DateTime?)? validatorClass;
  final Function(DateTime?)? onChanged;
  final VoidCallback? onTap;
  final bool? showLoading;
  final bool? autofocus;
  final DateTime? firstDate;
  final DateTime? lastDate;
  final String? dateFormat; // Changed to String for simple formatting

  const CustomDateInput({
    super.key,
    required this.selectedDate,
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
    this.firstDate,
    this.lastDate,
    this.dateFormat,
  });

  @override
  State<CustomDateInput> createState() => _CustomDateInputState();
}

class _CustomDateInputState extends State<CustomDateInput> {
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
  void didUpdateWidget(CustomDateInput oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedDate != widget.selectedDate) {
      _updateControllerText();
    }
  }

  void _updateControllerText() {
    if (widget.selectedDate != null) {
      _controller.text = _formatDate(widget.selectedDate!);
    } else {
      _controller.clear();
    }
  }

  String _formatDate(DateTime date) {
    // Simple date formatting without external dependencies
    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    
    switch (widget.dateFormat) {
      case 'dd/MM/yyyy':
        return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
      case 'MM/dd/yyyy':
        return '${date.month.toString().padLeft(2, '0')}/${date.day.toString().padLeft(2, '0')}/${date.year}';
      case 'yyyy-MM-dd':
        return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
      default:
        return '${months[date.month - 1]} ${date.day.toString().padLeft(2, '0')}, ${date.year}';
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
          Icons.calendar_today,
          color: colorScheme.onSurface.withAlpha(153),
          size: 20,
        );
  }

  Future<void> _selectDate() async {
    if (widget.viewOnly == true) return;

    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: widget.selectedDate ?? DateTime.now(),
      firstDate: widget.firstDate ?? DateTime(1900),
      lastDate: widget.lastDate ?? DateTime(2100),
    );

    if (picked != null && picked != widget.selectedDate) {
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
                  ? (value) => widget.validatorClass?.call(widget.selectedDate) 
                  : null,
              onTap: () {
                widget.onTap?.call();
                _selectDate();
              },
            ),
          ],
        );
      },
    );
  }
}