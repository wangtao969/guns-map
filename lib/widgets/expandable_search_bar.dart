import 'package:flutter/material.dart';

/// 小药丸式可展开搜索框：平时只是一个带放大镜图标的小药丸，
/// 点一下展开成输入框，右边有关闭按钮可缩回去。主页和板块内页共用。
class ExpandableSearchBar extends StatefulWidget {
  final String hint;
  final TextEditingController? controller;
  final bool initiallyExpanded;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  const ExpandableSearchBar({
    super.key,
    required this.hint,
    this.controller,
    this.initiallyExpanded = false,
    this.onChanged,
    this.onSubmitted,
  });

  @override
  State<ExpandableSearchBar> createState() => _ExpandableSearchBarState();
}

class _ExpandableSearchBarState extends State<ExpandableSearchBar> {
  late bool _expanded;
  late final TextEditingController _ctrl;
  late final FocusNode _focus;

  @override
  void initState() {
    super.initState();
    _expanded = widget.initiallyExpanded;
    _ctrl = widget.controller ?? TextEditingController();
    _focus = FocusNode();
  }

  @override
  void dispose() {
    if (widget.controller == null) _ctrl.dispose();
    _focus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final grey = dark ? const Color(0xFF8A8578) : const Color(0xFF9A917F);
    final border = dark ? const Color(0xFF4A4238) : const Color(0xFFD8D0BE);
    if (!_expanded) {
      return Align(
        alignment: Alignment.centerLeft,
        child: InkWell(
          onTap: () {
            setState(() => _expanded = true);
            _focus.requestFocus();
          },
          borderRadius: BorderRadius.circular(20),
          child: Container(
            height: 40,
            padding: const EdgeInsets.symmetric(horizontal: 14),
            decoration: BoxDecoration(
              border: Border.all(color: border),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.search, size: 20),
                const SizedBox(width: 8),
                Text(widget.hint, style: TextStyle(color: grey, fontSize: 13)),
              ],
            ),
          ),
        ),
      );
    }
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: _ctrl,
            focusNode: _focus,
            autofocus: true,
            onChanged: widget.onChanged,
            onSubmitted: widget.onSubmitted,
            decoration: InputDecoration(
              hintText: widget.hint,
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(20),
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        IconButton(
          onPressed: () {
            _ctrl.clear();
            widget.onChanged?.call('');
            setState(() => _expanded = false);
            _focus.unfocus();
          },
          icon: const Icon(Icons.close),
        ),
      ],
    );
  }
}
