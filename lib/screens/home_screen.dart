import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../app_state.dart';
import '../database_helper.dart';
import '../widgets/category_item.dart';
import '../widgets/symbol_item.dart';

class HomeScreen extends StatelessWidget {
  final void Function(int categoryId, String categoryName) onCategoryTap;

  const HomeScreen({super.key, required this.onCategoryTap});

  @override
  Widget build(BuildContext context) {
    final state = Provider.of<AppState>(context);
    final dbHelper = DatabaseHelper();

    return FutureBuilder(
      future: Future.wait([
        dbHelper.getCategories(showHidden: state.editMode == EditMode.edit),
        dbHelper.getMainScreenSymbols(
          showHidden: state.editMode == EditMode.edit,
          context: context,
        ),
      ]),
      builder: (context, AsyncSnapshot<List<dynamic>> snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        final categories = snapshot.data![0] as List<CategoryData>;
        final symbols = snapshot.data![1] as List<SymbolData>;

        return GridView.builder(
          padding: const EdgeInsets.all(3),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: state.gridSize,
            crossAxisSpacing: 3,
            mainAxisSpacing: 3,
            childAspectRatio: 1.5,
          ),
          itemCount: categories.length + symbols.length,
          itemBuilder: (context, index) {
            if (index < categories.length) {
              return CategoryItem(
                category: categories[index],
                onTap: () => onCategoryTap(
                  categories[index].id,
                  categories[index].name,
                ),
              );
            } else {
              final symbol = symbols[index - categories.length];
              return SymbolItem(
                symbol: symbol,
                isMainScreen: true,
                onTap: () => state.handleSymbolTap(symbol, context),
              );
            }
          },
        );
      },
    );
  }
}