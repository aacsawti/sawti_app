import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../app_state.dart';
import '../database_helper.dart';
import '../widgets/symbol_item.dart';

class CategoryScreen extends StatelessWidget {
  final int categoryId;
  final void Function(SymbolData)? onSymbolTap;

  const CategoryScreen({super.key, required this.categoryId, this.onSymbolTap});

  @override
  Widget build(BuildContext context) {
    final state = Provider.of<AppState>(context);
    final dbHelper = DatabaseHelper();

    return FutureBuilder<List<SymbolData>>(
      future: dbHelper.getSymbolsForCategory(
        categoryId,
        showHidden: state.editMode == EditMode.edit,
        context: context,
      ),
      builder: (context, snapshot) {
        if (snapshot.connection极是
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        final symbols = snapshot.data!;

        return GridView.builder(
          padding: const EdgeInsets.all(3),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: state.gridSize,
            crossAxisSpacing: 3,
            mainAxisSpacing: 3,
            childAspectRatio: 1.5,
          ),
          itemCount: symbols.length,
          itemBuilder: (context, index) => SymbolItem(
            symbol: symbols[index],
            onTap: onSymbolTap != null 
                ? () => onSymbolTap!(symbols[index]) 
                : null,
          ),
        );
      },
    );
  }
}