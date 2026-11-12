import 'package:material_ui/material_ui.dart';

/// Reusable Search Input Box matching HyperData Lab / ResearchPulse Design System
/// - Height: 38px (sleek, compact)
/// - Normal: #F8FAFC background, #E2E8F0 border, #94A3B8 icon
/// - Focused: White background, #0071BC crisp border (1.5px), #0071BC icon
/// - Zero white-corner / anti-aliasing artifacts: Uses clean native OutlineInputBorder
///   with matched borderRadius and no conflicting outer container fills.
/// - Clear button on text input
class SearchInputBox extends StatefulWidget {
  final TextEditingController? controller;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final String hintText;
  final double? width;
  final double height;
  final bool expandOnFocus;
  final double expandedWidth;

  const SearchInputBox({
    super.key,
    this.controller,
    this.onChanged,
    this.onSubmitted,
    this.hintText = 'Tìm kiếm...',
    this.width,
    this.height = 38,
    this.expandOnFocus = false,
    this.expandedWidth = 320,
  });

  @override
  State<SearchInputBox> createState() => _SearchInputBoxState();
}

class _SearchInputBoxState extends State<SearchInputBox> {
  late final TextEditingController _controller;
  final FocusNode _focusNode = FocusNode();
  bool _isFocused = false;
  bool _ownsController = false;

  @override
  void initState() {
    super.initState();
    if (widget.controller != null) {
      _controller = widget.controller!;
    } else {
      _controller = TextEditingController();
      _ownsController = true;
    }
    _focusNode.addListener(() {
      if (mounted) setState(() => _isFocused = _focusNode.hasFocus);
    });
    _controller.addListener(() {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _focusNode.dispose();
    if (_ownsController) {
      _controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const duration = Duration(milliseconds: 160);
    const curve = Cubic(0.16, 1.0, 0.3, 1.0);
    final borderRadius = BorderRadius.circular(8);

    final double? containerWidth = widget.expandOnFocus
        ? (_isFocused ? widget.expandedWidth : (widget.width ?? 270))
        : widget.width;

    return AnimatedContainer(
      duration: duration,
      curve: curve,
      width: containerWidth,
      height: widget.height,
      child: ClipRRect(
        borderRadius: borderRadius,
        clipBehavior: Clip.antiAlias,
        child: TextField(
          controller: _controller,
          focusNode: _focusNode,
          onChanged: widget.onChanged,
          onSubmitted: widget.onSubmitted,
          textAlignVertical: TextAlignVertical.center,
          style: const TextStyle(
            fontSize: 13,
            fontFamily: 'Manrope',
            color: Color(0xFF0F172A),
            fontWeight: FontWeight.w500,
          ),
          decoration: InputDecoration(
            isDense: true,
            filled: true,
            fillColor: _isFocused ? Colors.white : const Color(0xFFF8FAFC),
            hintText: widget.hintText,
            hintStyle: const TextStyle(
              fontSize: 12.5,
              color: Color(0xFF94A3B8),
              fontFamily: 'Manrope',
              fontWeight: FontWeight.w400,
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 10,
              vertical: 0,
            ),
            border: OutlineInputBorder(
              borderRadius: borderRadius,
              borderSide: const BorderSide(
                color: Color(0xFFE2E8F0),
                width: 1.0,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: borderRadius,
              borderSide: const BorderSide(
                color: Color(0xFFE2E8F0),
                width: 1.0,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: borderRadius,
              borderSide: const BorderSide(
                color: Color(0xFF0071BC),
                width: 1.5,
              ),
            ),
            prefixIcon: Padding(
              padding: const EdgeInsets.only(left: 10, right: 8),
              child: TweenAnimationBuilder<Color?>(
                duration: duration,
                curve: curve,
                tween: ColorTween(
                  end: _isFocused
                      ? const Color(0xFF0071BC)
                      : const Color(0xFF94A3B8),
                ),
                builder: (context, color, _) =>
                    Icon(Icons.search_rounded, size: 17, color: color),
              ),
            ),
            prefixIconConstraints: BoxConstraints(
              minWidth: 35,
              minHeight: widget.height,
            ),
            suffixIcon: _controller.text.isNotEmpty
                ? IconButton(
                    icon: const Icon(
                      Icons.clear_rounded,
                      size: 15,
                      color: Color(0xFF94A3B8),
                    ),
                    onPressed: () {
                      _controller.clear();
                      widget.onChanged?.call('');
                      setState(() {});
                    },
                    padding: EdgeInsets.zero,
                    constraints: BoxConstraints(
                      minWidth: 30,
                      minHeight: widget.height,
                    ),
                  )
                : null,
          ),
        ),
      ),
    );
  }
}
