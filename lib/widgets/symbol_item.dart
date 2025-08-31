import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../app_state.dart';
import '../database_helper.dart';

class SymbolItem extends StatefulWidget {
  final SymbolData symbol;
  final bool isMainScreen;
  final VoidCallback? onTap;
  final Alignment imageAlignment;
  final Alignment textAlignment;

  const SymbolItem({
    super.key,
    required this.symbol,
    this.isMainScreen = false,
    this.onTap,
    this.imageAlignment = Alignment.center,
    this.textAlignment = Alignment.center,
  });

  @override
  State<SymbolItem> createState() => _SymbolItemState();
}

class _SymbolItemState extends State<SymbolItem> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final state = Provider.of<AppState>(context);
    final isSelected = state.isSelected(widget.symbol.id, ItemType.symbol);
    final isEditMode = state.editMode == EditMode.edit;
    final defaultColor = _hexToColor(widget.symbol.color ?? '#FFFFFF');

    return LayoutBuilder(
      builder: (context, constraints) {
        final imageSize = constraints.maxHeight * 0.65;

        return GestureDetector(
          onTapDown: (details) {
            setState(() => _isPressed = true);
          },
          onTapUp: (details) {
            setState(() => _isPressed = false);
            if (isEditMode) {
              state.toggleSelection(widget.symbol.id, ItemType.symbol);
            } else {
              widget.onTap?.call();
            }
          },
          onTapCancel: () {
            setState(() => _isPressed = false);
          },
          onLongPress: () {
            final state = Provider.of<AppState>(context, listen: false);
            state.handleSymbolLongPress(widget.symbol, context);
          },
          child: Stack(
            children: [
              Container(
                decoration: BoxDecoration(
                  color: _isPressed ? Colors.orange : defaultColor,
                  border:
                      isSelected
                          ? Border.all(color: Colors.blue, width: 1)
                          : null,
                  borderRadius: BorderRadius.circular(9),
                ),
                width: double.infinity,
                height: double.infinity,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Align(
                      alignment: widget.imageAlignment,
                      child:
                          widget.symbol.imagePath.isNotEmpty
                              ? Image.asset(
                                widget.symbol.imagePath,
                                fit: BoxFit.contain,
                                width: imageSize,
                                height: imageSize,
                              )
                              : const SizedBox.shrink(),
                    ),
                    const SizedBox(height: 0),
                    Align(
                      alignment: widget.textAlignment,
                      child: Container(
                        width: constraints.maxWidth,
                        alignment: Alignment.center,
                        child: Text(
                          widget.symbol.getName(state.currentDialect),
                          style: TextStyle(
                            fontSize: constraints.maxHeight * 0.2,
                            decoration:
                                widget.symbol.isHidden
                                    ? TextDecoration.lineThrough
                                    : null,
                          ),
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          softWrap: false,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              if (widget.symbol.isHidden)
                Positioned.fill(
                  child: Container(
                    color: Colors.black54,
                    child: const Center(
                      child: Icon(Icons.visibility_off, color: Colors.white),
                    ),
                  ),
                ),
              if (isEditMode && isSelected)
                const Positioned(
                  top: 5,
                  right: 5,
                  child: CircleAvatar(
                    radius: 10,
                    backgroundColor: Colors.blue,
                    child: Icon(Icons.check, size: 14, color: Colors.white),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Color _hexToColor(String hexColor) {
    hexColor = hexColor.replaceAll('#', ''); // إزالة # إن وجدت
    if (hexColor.length == 6) {
      hexColor =
          'FF$hexColor'; // إضافة قناة Alpha إذا كانت مفقودة (FF = opaque)
    } else if (hexColor.length != 8) {
      return const Color.fromARGB(
        255,
        248,
        246,
        246,
      ); // افتراضي إذا كان الكود غير صالح
    }
    print(hexColor);
    print('حححححححححححححححححححححححححححححححححححححححححححححححححححححححححححححححح');
    print(int.parse(hexColor, radix: 16));
    return Color(int.parse(hexColor, radix: 16));
  }
}