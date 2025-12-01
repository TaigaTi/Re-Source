import 'package:flutter/material.dart';

class SearchableCategoryDropdown extends StatefulWidget {
  final List<Map<String, dynamic>> categories;
  final String? selectedCategory;
  final void Function(String) onCategorySelected;
  final Future<void> Function(String) onCreateCategory;

  const SearchableCategoryDropdown({
    super.key,
    required this.categories,
    this.selectedCategory,
    required this.onCategorySelected,
    required this.onCreateCategory,
  });

  @override
  State<SearchableCategoryDropdown> createState() =>
      _SearchableCategoryDropdownState();
}

class _SearchableCategoryDropdownState
    extends State<SearchableCategoryDropdown> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  final LayerLink _layerLink = LayerLink();

  OverlayEntry? _overlayEntry;
  List<Map<String, dynamic>> _filteredCategories = [];
  bool _isDropdownOpen = false;

  @override
  void initState() {
    super.initState();
    _filteredCategories = widget.categories;

    if (widget.selectedCategory != null) {
      _searchController.text = widget.selectedCategory!;
    }

    _focusNode.addListener(() {
      if (_focusNode.hasFocus) {
        _openDropdown();
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _focusNode.dispose();
    _closeDropdown();
    super.dispose();
  }

  void _filterCategories(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredCategories = widget.categories;
      } else {
        _filteredCategories = widget.categories
            .where(
              (category) =>
                  category['name'].toLowerCase().contains(query.toLowerCase()),
            )
            .toList();
      }
    });
    _updateOverlay();
  }

  void _openDropdown() {
    if (_isDropdownOpen) return;

    _filteredCategories = widget.categories;

    _isDropdownOpen = true;
    _overlayEntry = _createOverlayEntry();
    Overlay.of(context).insert(_overlayEntry!);
  }

  void _closeDropdown() {
    if (!_isDropdownOpen) return;

    _isDropdownOpen = false;
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  void _updateOverlay() {
    if (_isDropdownOpen && _overlayEntry != null) {
      _overlayEntry!.markNeedsBuild();
    }
  }

  bool _shouldShowCreateOption() {
    final searchText = _searchController.text.trim();
    return searchText.isNotEmpty &&
        !_filteredCategories.any(
          (cat) => cat['name'].toLowerCase() == searchText.toLowerCase(),
        );
  }

  OverlayEntry _createOverlayEntry() {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final isLight = cs.brightness == Brightness.light;
    final panelColor = isLight ? cs.surface : cs.surfaceVariant;
    final borderColor = cs.outlineVariant;
    final accent = cs.primary;

    RenderBox renderBox = context.findRenderObject() as RenderBox;
    Size size = renderBox.size;
    Offset offset = renderBox.localToGlobal(Offset.zero);

    return OverlayEntry(
      builder: (context) => Positioned(
        left: offset.dx,
        top: offset.dy + size.height + 5,
        width: size.width,
        child: Material(
          elevation: 2,
          borderRadius: BorderRadius.circular(10),
          color: panelColor,
          child: Container(
            constraints: const BoxConstraints(maxHeight: 200),
            decoration: BoxDecoration(
              color: panelColor,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: borderColor),
            ),
            child: ListView(
              padding: EdgeInsets.zero,
              shrinkWrap: true,
              children: [
                // Create new category option
                if (_shouldShowCreateOption())
                  InkWell(
                    onTap: () async {
                      final newCategoryName = _searchController.text.trim();
                      await widget.onCreateCategory(newCategoryName);
                      _searchController.text = newCategoryName;
                      _closeDropdown();
                      _focusNode.unfocus();
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        border: Border(
                          bottom: BorderSide(color: Colors.grey.shade200),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.add_circle_outline,
                            color: accent,
                            size: 20,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              "Create '${_searchController.text}' Category",
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: accent,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                // Existing categories
                ..._filteredCategories.map((category) {
                  return InkWell(
                    onTap: () {
                      widget.onCategorySelected(category['name']);
                      _searchController.text = category['name'];
                      _closeDropdown();
                      _focusNode.unfocus();
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 16,
                            height: 16,
                            decoration: BoxDecoration(
                              color: Color(category['color']),
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              category['name'],
                              style: theme.textTheme.bodyMedium,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }),

                // No results message
                if (_filteredCategories.isEmpty && !_shouldShowCreateOption())
                  Container(
                    padding: const EdgeInsets.all(16),
                    child: Text(
                      'No categories found',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: cs.onSurfaceVariant,
                        fontStyle: FontStyle.italic,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final inputFill = cs.surface;
    final suffixColor = cs.onSurfaceVariant;
    return CompositedTransformTarget(
      link: _layerLink,
      child: GestureDetector(
        onTap: () {
          if (_isDropdownOpen) {
            _closeDropdown();
            _focusNode.unfocus();
          } else {
            _focusNode.requestFocus();
          }
        },
        child: TextField(
          controller: _searchController,
          focusNode: _focusNode,
          onChanged: _filterCategories,
          onTap: _openDropdown,
          decoration: InputDecoration(
            filled: true,
            fillColor: inputFill,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide.none,
            ),
            hintText: 'Select or create category',
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 12,
            ),
            suffixIcon: Icon(
              _isDropdownOpen
                  ? Icons.keyboard_arrow_up
                  : Icons.keyboard_arrow_down,
              color: suffixColor,
            ),
          ),
        ),
      ),
    );
  }
}
