import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../app_state.dart';
import '../database_helper.dart';

class CategoryItem extends StatefulWidget {
  final CategoryData category;
  final VoidCallback onTap;

  const CategoryItem({super.key, required this.category, required this.onTap});

  @override
  State<CategoryItem> createState() => _CategoryItemState();
}

class _CategoryItemState extends State<CategoryItem> {
  bool _isTapped = false;

  @override
  Widget build(BuildContext context) {
    final state = Provider.of<AppState>(context);
    final category = widget.category;
    final isSelected = state.isSelected(category.id, ItemType.category);
    final isEditMode = state.editMode == EditMode.edit;

    return GestureDetector(
      onTapDown: (_) {
        setState(() => _isTapped = true);
      },
      onTapUp: (_) {
        setState(() => _isTapped = false);
        isEditMode
            ? state.toggleSelection(category.id, ItemType.category)
            : widget.onTap();
      },
      onTapCancel: () {
        setState(() => _isTapped = false);
      },
      child: AspectRatio(
        aspectRatio: 1 / 1,
        child: LayoutBuilder(
          builder: (context, constraints) {
            double fontSize = constraints.maxHeight * 0.15;
            double imageHeight =
                constraints.maxHeight * 0.55; // نسبة من ارتفاع الفولدر
            double imageTopPadding =
                constraints.maxHeight * 0.17; // هامش علوي نسبي

            return Stack(
              children: [
                // خلفية الفولدر
                Container(
                  decoration: BoxDecoration(
                    border:
                        isSelected
                            ? Border.all(color: Colors.blue, width: 1)
                            : null,
                    borderRadius: BorderRadius.circular(9),
                    image: DecorationImage(
                      image: AssetImage(
                        _isTapped
                            ? 'assets/images/folder22.png'
                            : 'assets/images/folder33.png',
                      ),
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.topCenter,
                    ),
                  ),
                ),

                // الصورة
                Positioned(
                  top: imageTopPadding,
                  left: constraints.maxWidth * 0.1,
                  right: constraints.maxWidth * 0.1,
                  height: imageHeight,
                  child: Image.asset(category.imagePath, fit: BoxFit.contain),
                ),

                // الاسم
                Positioned(
                  bottom: constraints.maxHeight * 0.05,
                  left: 4,
                  right: 4,
                  child: Text(
                    category.name,
                    style: TextStyle(
                      fontSize: fontSize,
                      fontWeight: FontWeight.w600,
                      color: Colors.black,
                      decoration:
                          category.isHidden ? TextDecoration.lineThrough : null,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),

                // التغبيش عند الإخفاء
                if (category.isHidden)
                  Positioned.fill(
                    child: Container(
                      color: Colors.black54,
                      child: const Center(
                        child: Icon(Icons.visibility_off, color: Colors.white),
                      ),
                    ),
                  ),

                // مؤشر التحديد
                if (isEditMode && isSelected)
                  Positioned(
                    top: 2,
                    right: 2,
                    child: Container(
                      width: 20,
                      height: 20,
                      decoration: const BoxDecoration(
                        color: Colors.blue,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.check,
                        size: 14,
                        color: Colors.white,
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}