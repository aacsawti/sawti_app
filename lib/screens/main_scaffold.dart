import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'home_screen.dart';
import 'category_screen.dart';
import 'settings_screen.dart';
import 'profile_screen.dart';
import '../app_state.dart';

class MainScaffold extends StatefulWidget {
  const MainScaffold({super.key});

  @override
  _MainScaffoldState createState() => _MainScaffoldState();
}

class _MainScaffoldState extends State<MainScaffold> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  bool _isLongPressActive = false;
  final ScrollController _scrollController = ScrollController();
  Timer? _doubleTapTimer;
  int _tapCount = 0;
  Timer? _conjugationTimer;
  bool _isWaitingForDoubleTap = false;
  final _menuState = _MenuState(); // أضف هذا المتغير
  void _handleDrawerPress() {
    if (!_isLongPressActive) {
      _isLongPressActive = true;
      Future.delayed(const Duration(milliseconds: 1000), () {
        if (_isLongPressActive) {
          _scaffoldKey.currentState?.openEndDrawer();
        }
        _isLongPressActive = false;
      });
    }
  }

  @override
  void initState() {
    super.initState();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersive);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final state = Provider.of<AppState>(context, listen: false);

    if (state.selectedSymbols.isNotEmpty && _scrollController.hasClients) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      });
    }
  }

  void _handleMenuTap() {
    _tapCount++;
    if (_tapCount >= 3) {
      _tapCount = 0;
    }

    if (_tapCount == 1) {
      _isWaitingForDoubleTap = true;
      _doubleTapTimer?.cancel();
      _doubleTapTimer = Timer(const Duration(milliseconds: 300), () {
        setState(() {
          _isWaitingForDoubleTap = false;
          _tapCount = 0;
        });
      });
    } else if (_tapCount == 2) {
      _doubleTapTimer?.cancel();
      _doubleTapTimer = Timer(const Duration(milliseconds: 300), () {
        setState(() {
          _isWaitingForDoubleTap = false;
          _tapCount = 0;
        });
      });
    }
    setState(() {});
  }

  void _handleMenuLongPress() {
    if (_tapCount == 2) {
      _scaffoldKey.currentState?.openEndDrawer();
    }
    setState(() {
      _tapCount = 0;
      _isWaitingForDoubleTap = false;
    });
    _doubleTapTimer?.cancel();
  }

  @override
  Widget build(BuildContext context) {
    final state = Provider.of<AppState>(context);
    final isSettingsOrProfile =
        state.currentScreen == AppScreen.settings ||
        state.currentScreen == AppScreen.profile;

    final double appBarHeight = isSettingsOrProfile ? 0 : 80;

    return Scaffold(
      key: _scaffoldKey,
      endDrawerEnableOpenDragGesture: false,
      endDrawer: _buildDrawer(context),
      backgroundColor:
          state.isDarkMode
              ? const Color.fromARGB(255, 21, 20, 36)
              : const Color.fromARGB(255, 255, 255, 255),
      body: Stack(
        children: [
          // 1. المحتوى الأساسي
          Padding(
            padding: EdgeInsets.only(top: appBarHeight, right: 70),
            child: _buildCurrentScreenContent(context),
          ),

          Positioned(
            top: 0,
            left: 0,
            right: 68,
            height: appBarHeight,
            child: StreamBuilder<List<SymbolData>>(
              stream: state.selectedSymbolsStream,
              builder: (context, snapshot) {
                return _buildCustomAppBar(context);
              },
            ),
          ),

          Positioned(
            top: 0,
            right: 0,
            bottom: 0,
            child: Container(
              width: 70,
              color: const Color.fromARGB(122, 20, 17, 52),
              child: _buildSideBar(context),
            ),
          ),
          if (state.showMenuInstruction)
            Positioned(
              top: 38, // Vertically centered with menu button
              right: 75, // Left of menu button
              child: _buildInstructionMessage(),
            ),
          // 2. نافذة التصاريف مع طبقة شفافة
          StreamBuilder<ConjugationDisplayData?>(
            stream: state.conjugationsStream,
            builder: (context, snapshot) {
              if (snapshot.hasData && snapshot.data != null) {
                return Stack(
                  children: [
                    // طبقة شفافة تغطي الشاشة بالكامل
                    Positioned.fill(
                      child: GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap:
                            () =>
                                state
                                    .hideConjugations(), // إغلاق النافذة وإلغاء المؤقت
                        child: Container(color: Colors.transparent),
                      ),
                    ),

                    // نافذة التصاريف
                    _buildConjugationOverlay(context, snapshot.data!),
                  ],
                );
              }
              return const SizedBox.shrink();
            },
          ),
        ],
      ),
    );
  }

  Widget _buildInstructionMessage() {
    return Container(
      width: 200,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 6,
            spreadRadius: 2,
          ),
        ],
      ),
      child: const Text(
        'اضغط مرتين متتاليتين ثم ضغطه مطوله',
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: Colors.blue,
        ),
      ),
    );
  }

  // دالة جديدة لبناء نافذة التصاريف المعدلة
  Widget _buildMinimalConjugationBar(AppState state, BuildContext context) {
    // حساب حجم النافذة بناءً على عدد الرموز
    final symbolWidth = 80.0;
    final symbolHeight = 60.0;
    final horizontalPadding = 0.1;
    final verticalPadding = 8.0;

    final columns = state.currentConjugations!.length;
    final width = columns * symbolWidth + (columns - 1) * horizontalPadding;
    final height = symbolHeight + verticalPadding * 2;

    return Positioned(
      bottom: 20,
      left: (MediaQuery.of(context).size.width - width) / 2,
      child: GestureDetector(
        onTap: () {}, // لمنع إغلاق النافذة عند النقر عليها
        child: Container(
          width: width,
          height: height,
          padding: EdgeInsets.symmetric(
            horizontal: horizontalPadding,
            vertical: verticalPadding,
          ),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 6,
                spreadRadius: 2,
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children:
                state.currentConjugations!.map((conjugation) {
                  return GestureDetector(
                    onTap: () => state.addConjugationToBar(conjugation),
                    child: Container(
                      width: symbolWidth - 2,
                      height: symbolHeight,
                      padding: const EdgeInsets.all(3),
                      decoration: BoxDecoration(
                        color: const Color.fromARGB(255, 109, 175, 222),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Image.asset(
                            conjugation.imagePath,
                            width: 40,
                            height: 30,
                            fit: BoxFit.contain,
                          ),
                          const SizedBox(height: 1),
                          Text(
                            conjugation.getName(state.currentDialect),
                            style: const TextStyle(fontSize: 11),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
          ),
        ),
      ),
    );
  }

  Widget _buildConjugationOverlay(
    BuildContext context,
    ConjugationDisplayData data,
  ) {
    final state = Provider.of<AppState>(context, listen: false);
    final screenSize = MediaQuery.of(context).size;
    final isPortrait =
        MediaQuery.of(context).orientation == Orientation.portrait;

    // تحديد عدد الأعمدة بناءً على حجم الشاشة
    int columns;
    if (screenSize.width < 400) {
      columns = min(2, data.conjugations.length);
    } else if (screenSize.width < 600) {
      columns = min(4, data.conjugations.length);
    } else {
      columns = min(4, data.conjugations.length);
    }

    // الحفاظ على النسبة الأصلية (80x60)
    const double aspectRatio = 80 / 60;

    // حساب حجم العنصر بناءً على حجم الشاشة
    double baseSize = screenSize.width * 0.1;
    double itemWidth = baseSize;
    double itemHeight = itemWidth / aspectRatio;

    // تقليل المسافات بين العناصر
    const double horizontalSpacing = 2.0;
    const double verticalSpacing = 2.0;

    // حساب عدد الصفوف
    int rows = (data.conjugations.length / columns).ceil();

    // حساب حجم النافذة الكلية
    double width = columns * itemWidth + (columns - 1) * horizontalSpacing;
    double height = rows * itemHeight + (rows - 1) * verticalSpacing;

    // التحقق من أن النافذة لا تتجاوز حجم الشاشة
    double maxHeight = screenSize.height * 0.8;
    if (height > maxHeight) {
      double scaleFactor = maxHeight / height;
      itemWidth *= scaleFactor;
      itemHeight = itemWidth / aspectRatio;
      width = columns * itemWidth + (columns - 1) * horizontalSpacing;
      height = rows * itemHeight + (rows - 1) * verticalSpacing;
    }

    // حساب الموضع الرأسي بشكل ديناميكي
    double topPosition;
    if (isPortrait) {
      topPosition = screenSize.height * 0.1;
    } else {
      topPosition = 45.0;
    }

    return Positioned(
      top: topPosition,
      left: (screenSize.width - width) / 2,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: screenSize.height * 0.7),
        child: SingleChildScrollView(
          child: Container(
            width: width,
            padding: const EdgeInsets.all(1.5),
            decoration: BoxDecoration(
              color: const Color.fromARGB(255, 255, 255, 255),
              borderRadius: BorderRadius.circular(10),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.5),
                  blurRadius: 9,
                  spreadRadius: 3,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Column(
              children: List.generate(rows, (rowIndex) {
                int startIndex = rowIndex * columns;
                int endIndex = min(
                  (rowIndex + 1) * columns,
                  data.conjugations.length,
                );

                return Row(
                  children: List.generate(endIndex - startIndex, (colIndex) {
                    final conjugation =
                        data.conjugations[startIndex + colIndex];

                    return Expanded(
                      child: Container(
                        margin: EdgeInsets.only(
                          bottom: rowIndex < rows - 1 ? verticalSpacing : 0,
                          right:
                              colIndex < endIndex - startIndex - 1
                                  ? horizontalSpacing
                                  : 0,
                        ),
                        height: itemHeight,
                        child: GestureDetector(
                          onTap: () {
                            state.addConjugationToBar(conjugation);
                          },
                          child: Container(
                            decoration: BoxDecoration(
                              color: const Color(0xFF4A86E8),
                              borderRadius: BorderRadius.circular(8),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.2),
                                  blurRadius: 4,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Image.asset(
                                  conjugation.imagePath,
                                  width: itemWidth * 0.6,
                                  height: itemHeight * 0.6,
                                  fit: BoxFit.contain,
                                ),
                                const SizedBox(height: 2),
                                FittedBox(
                                  fit: BoxFit.scaleDown,
                                  child: Text(
                                    conjugation.getName(state.currentDialect),
                                    style: TextStyle(
                                      fontSize: itemWidth * 0.12,
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                    textAlign: TextAlign.center,
                                    maxLines: 1,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  }),
                );
              }),
            ),
          ),
        ),
      ),
    );
  }

  double _calculateConjugationWidth(int count) {
    return (count + 1) * 80;
  }

  Widget _buildConjugationBar(AppState state) {
    return Container(
      height: 100,
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 10,
            spreadRadius: 2,
          ),
        ],
      ),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: state.currentConjugations!.length,
        itemBuilder: (context, index) {
          final conjugation = state.currentConjugations![index];
          return GestureDetector(
            onTap: () => state.addConjugationToBar(conjugation),
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 8),
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Image.asset(conjugation.imagePath, width: 40, height: 40),
                  const SizedBox(height: 5),
                  Text(
                    conjugation.getName(state.currentDialect),
                    style: const TextStyle(fontSize: 12),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildCustomAppBar(BuildContext context) {
    final state = Provider.of<AppState>(context);

    return Column(
      children: [
        if (state.editMode == EditMode.edit)
          _buildEditModeBar(context)
        else
          _buildSymbolsBar(context),
        _buildTitleBar(state),
      ],
    );
  }

  Widget _buildSymbolsBar(BuildContext context) {
    final state = Provider.of<AppState>(context);
    final scrollController = ScrollController();

    return StreamBuilder<List<SymbolData>>(
      stream: state.selectedSymbolsStream,
      initialData: const [],
      builder: (context, snapshot) {
        final symbols = snapshot.data ?? [];

        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (scrollController.hasClients) {
            scrollController.animateTo(
              scrollController.position.maxScrollExtent,
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOut,
            );
          }
        });

        return Container(
          height: 60,
          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 3),
          decoration: BoxDecoration(
            color: const Color.fromARGB(255, 21, 42, 83),
            borderRadius: BorderRadius.circular(3),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 2,
                spreadRadius: 11,
              ),
            ],
          ),
          child: Row(
            children: [
              Expanded(
                flex: 7,
                child: Container(
                  padding: const EdgeInsets.only(left: 0, right: 0),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child:
                      symbols.isNotEmpty
                          ? ListView.builder(
                            controller: scrollController,
                            scrollDirection: Axis.horizontal,
                            itemCount: symbols.length,
                            itemBuilder: (context, index) {
                              final item = symbols[index];
                              return Padding(
                                padding: EdgeInsets.only(
                                  right: index == symbols.length ? 1 : 14.0,
                                  left: index == 0 ? 0 : 1.0,
                                ),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Image.asset(
                                      item.imagePath,
                                      width: 32,
                                      height: 32,
                                    ),
                                    const SizedBox(height: 3),
                                    Text(
                                      item.getName(state.currentDialect),
                                      style: const TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.black87,
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          )
                          : const Center(
                            child: Text(
                              'اختر الرموز لبناء الجملة',
                              style: TextStyle(color: Colors.black45),
                            ),
                          ),
                ),
              ),
              const SizedBox(width: 5),
              Flexible(
                flex: 2,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children:
                      state.selectedSymbols.isNotEmpty
                          ? [
                            Container(
                              decoration: BoxDecoration(
                                border: Border.all(
                                  color: const Color.fromARGB(255, 244, 168, 4),
                                  width: 2,
                                ),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: IconButton(
                                icon: const Icon(
                                  Icons.play_circle_fill,
                                  color: Color.fromARGB(255, 255, 159, 4),
                                  size: 26,
                                ),
                                onPressed: () => state.playSelectedSymbols(),
                                tooltip: 'نطق الرموز',
                              ),
                            ),
                            Container(
                              decoration: BoxDecoration(
                                border: Border.all(
                                  color: const Color.fromARGB(255, 5, 252, 142),
                                  width: 1,
                                ),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: IconButton(
                                icon: const Icon(
                                  Icons.undo,
                                  color: Color.fromARGB(255, 5, 252, 141),
                                ),
                                onPressed: () => state.removeLastSymbol(),
                                tooltip: 'حذف آخر رمز',
                              ),
                            ),
                            Container(
                              decoration: BoxDecoration(
                                border: Border.all(
                                  color: const Color.fromARGB(255, 248, 47, 47),
                                  width: 1,
                                ),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: IconButton(
                                icon: const Icon(
                                  Icons.delete_forever,
                                  color: Color.fromARGB(255, 253, 51, 51),
                                ),
                                onPressed: () => state.clearSelectedSymbols(),
                                tooltip: 'حذف الكل',
                              ),
                            ),
                          ]
                          : [],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildEditModeBar(BuildContext context) {
    final state = Provider.of<AppState>(context);
    final hasSelection = state.selectedItems.isNotEmpty;
    final hasCopiedItem = state.copiedSymbol != null;

    return Container(
      height: 60,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: Colors.blue[900],
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(3),
          topRight: Radius.circular(3),
        ),
      ),
      child: Row(
        children: [
          Container(
            decoration: BoxDecoration(
              color: const Color.fromARGB(255, 234, 239, 234),
              borderRadius: BorderRadius.circular(8),
              boxShadow: [
                BoxShadow(
                  color: const Color.fromARGB(
                    255,
                    186,
                    181,
                    206,
                  ).withOpacity(0.29),
                  blurRadius: 4,
                  spreadRadius: 1,
                ),
              ],
            ),
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                shadowColor: Colors.transparent,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onPressed: () => state.toggleEditMode(),
              child: const Text(
                'تم',
                style: TextStyle(
                  color: Color.fromARGB(255, 4, 48, 113),
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),

          Text(
            'وضع التحرير${hasSelection ? ' (${state.selectedItems.length} مختار)' : ''}',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),

          if (hasSelection || hasCopiedItem)
            Expanded(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: _buildEditModeActions(context),
              ),
            ),
        ],
      ),
    );
  }

  List<Widget> _buildEditModeActions(BuildContext context) {
    final state = Provider.of<AppState>(context);
    final isCategorySelected = state.firstSelected?.type == ItemType.category;
    final hasCopiedItem = state.copiedSymbol != null;

    List<Widget> actions = [];

    // إخفاء - يظهر للفئات والعناصر
    actions.add(
      _buildEditActionButton(
        icon: Icons.visibility_off,
        color: Colors.orange[800]!,
        tooltip: 'إخفاء المحدد',
        onPressed: () => _handleEditAction(context, 'hide'),
      ),
    );

    // إظهار - يظهر للفئات والعناصر
    actions.add(
      _buildEditActionButton(
        icon: Icons.visibility,
        color: Colors.blue[600]!,
        tooltip: 'إظهار المحدد',
        onPressed: () => _handleEditAction(context, 'unhide'),
      ),
    );

    // فقط للعناصر (ليس الفئات)
    if (!isCategorySelected) {
      if (hasCopiedItem) {
        actions.add(
          _buildEditActionButton(
            icon: Icons.paste,
            color: Colors.purple[600]!,
            tooltip: 'لصق العنصر',
            onPressed: () => _handleEditAction(context, 'paste'),
          ),
        );
      }

      actions.add(
        _buildEditActionButton(
          icon: Icons.copy,
          color: Colors.teal[600]!,
          tooltip: 'نسخ المحدد',
          onPressed: () => _handleEditAction(context, 'copy'),
        ),
      );

      // إزالة خيار الحذف للفئات
      actions.add(
        _buildEditActionButton(
          icon: Icons.delete,
          color: Colors.red[600]!,
          tooltip: 'حذف المحدد',
          onPressed: () => _showDeleteConfirmationDialog(context),
        ),
      );
    }

    return actions;
  }

  Widget _buildEditActionButton({
    required IconData icon,
    required Color color,
    required String tooltip,
    required VoidCallback onPressed,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.5),
            blurRadius: 4,
            spreadRadius: 1,
          ),
        ],
      ),
      child: IconButton(
        icon: Icon(icon, color: Colors.white),
        onPressed: onPressed,
        tooltip: tooltip,
        style: IconButton.styleFrom(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
    );
  }

  Future<void> _showDeleteConfirmationDialog(BuildContext context) async {
    final state = Provider.of<AppState>(context, listen: false);
    final item = state.firstSelected;
    if (item == null) return;

    String? itemName;
    try {
      if (item.type == ItemType.symbol) {
        final symbol = await DatabaseHelper().getSymbolById(item.id);
        itemName = symbol?.getName(state.currentDialect);
      }
    } catch (e) {
      debugPrint('Error getting item name: $e');
    }

    return showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('تأكيد الحذف'),
            content: Text('هل أنت متأكد من حذف "${itemName ?? 'هذا العنصر'}"؟'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('إلغاء'),
              ),
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  _handleEditAction(context, 'delete');
                },
                child: const Text('حذف', style: TextStyle(color: Colors.red)),
              ),
            ],
          ),
    );
  }

  Widget _buildTitleBar(AppState state) {
    return Container(
      height: 16,
      color: Colors.blue[800],
      padding: const EdgeInsets.symmetric(horizontal: 5),
      child: Center(
        child: Text(
          _getScreenTitle(state),
          style: const TextStyle(
            color: Colors.white,
            fontSize: 11,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  String _getScreenTitle(AppState state) {
    if (state.currentScreen == AppScreen.home) {
      return 'الصفحة الرئيسية';
    } else if (state.currentScreen == AppScreen.category) {
      return state.currentCategoryName ?? 'الفئة';
    } else if (state.currentScreen == AppScreen.settings) {
      return 'الإعدادات';
    } else {
      return 'الملف الشخصي';
    }
  }

  Widget _buildSideBar(BuildContext context) {
    final state = Provider.of<AppState>(context);

    return Container(
      width: 76,
      decoration: BoxDecoration(
        color: Colors.blueGrey[900],
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 8,
            spreadRadius: 3,
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
            height: 76,
            color: Colors.blue[800],
            child: GestureDetector(
              onTap: () => _menuState.handleMenuTap(context), // تم التعديل هنا
              onLongPress: () => _menuState.handleMenuLongPress(_scaffoldKey),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.menu, color: Colors.white, size: 50),
                    if (_menuState.isWaitingForDoubleTap &&
                        _menuState.tapCount == 1)
                      const Text(
                        'انقر مرة أخرى',
                        style: TextStyle(fontSize: 10, color: Colors.white),
                      ),
                    if (_menuState.tapCount == 2)
                      const Text(
                        'اضغط مطولاً',
                        style: TextStyle(fontSize: 10, color: Colors.yellow),
                      ),
                  ],
                ),
              ),
            ),
          ),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              GestureDetector(
                onTap: () {
                  if (state.currentScreen != AppScreen.home) {
                    state.goToHomeScreen();
                  }
                },
                child: Image.asset(
                  'assets/images/back_icon.png',
                  width: 45,
                  height: 45,
                ),
              ),
              const SizedBox(height: 20),

              GestureDetector(
                onTap: state.goToHomeScreen,
                child: Image.asset(
                  'assets/images/home_icon.png',
                  width: 50,
                  height: 50,
                ),
              ),
            ],
          ),

          Column(
            children: [
              _buildTenseTextButton('Past', 'ماضي', state),
              _buildTenseTextButton('Present', 'مضارع', state),
              _buildTenseTextButton('Command', 'أمر', state),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTenseTextButton(String tense, String label, AppState state) {
    return StreamBuilder<String>(
      stream: state.tenseStream,
      initialData: state.settings['tense'],
      builder: (context, snapshot) {
        final currentTense = snapshot.data ?? 'present';
        final isActive = currentTense == tense;

        return AnimatedContainer(
          duration: const Duration(milliseconds: 100),
          margin: const EdgeInsets.symmetric(vertical: 5),
          decoration: BoxDecoration(
            color: isActive ? Colors.blue : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isActive ? Colors.blueAccent : Colors.white70,
              width: isActive ? 2 : 1,
            ),
            boxShadow:
                isActive
                    ? [
                      BoxShadow(
                        color: Colors.blue.withOpacity(0.4),
                        blurRadius: 6,
                        offset: const Offset(0, 3),
                      ),
                    ]
                    : [],
          ),
          child: TextButton(
            onPressed: () => state.updateTense(tense),
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              backgroundColor: Colors.transparent,
            ),
            child: Text(
              label,
              style: TextStyle(
                color: isActive ? Colors.white : Colors.white70,
                fontSize: isActive ? 16 : 14,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _handleEditAction(BuildContext context, String action) async {
    final state = Provider.of<AppState>(context, listen: false);
    final dbHelper = DatabaseHelper();

    if (state.firstSelected == null && action != 'paste') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('الرجاء تحديد عنصر واحد على الأقل')),
      );
      return;
    }

    try {
      switch (action) {
        case 'hide':
          await dbHelper.updateVisibility(
            state.firstSelected!.id,
            state.firstSelected!.type,
            true,
          );
          break;
        case 'unhide':
          await dbHelper.updateVisibility(
            state.firstSelected!.id,
            state.firstSelected!.type,
            false,
          );
          break;
        case 'delete':
          await dbHelper.deleteItem(
            state.firstSelected!.id,
            state.firstSelected!.type,
          );
          break;
        case 'copy':
          if (state.firstSelected!.type == ItemType.symbol) {
            final symbol = await dbHelper.getSymbolById(
              state.firstSelected!.id,
            );
            state.copySelectedItem(symbol!);
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('تم نسخ العنصر بنجاح')),
            );
          }
          break;
        case 'paste':
          await state.pasteCopiedSymbol(context);
          break;
      }

      state.clearAllSelections();
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('حدث خطأ: ${e.toString()}')));
    }
  }

  Future<void> _playAllSymbols(BuildContext context) async {
    final state = Provider.of<AppState>(context, listen: false);

    for (final symbol in state.selectedSymbols) {
      await state.playSymbolAudio(symbol, context);
      //await Future.delayed(const Duration(milliseconds: 1));
    }
  }

  Widget _buildDrawer(BuildContext context) {
    final state = Provider.of<AppState>(context);

    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          GestureDetector(
            onTap: () {
              Navigator.pop(context);
              state.goToProfileScreen();
            },
            child: UserAccountsDrawerHeader(
              accountName: Text(state.userProfile['username']),
              accountEmail: Text(
                state.settings['dialect'] == 'MSA'
                    ? 'الفصحى'
                    : state.settings['dialect'] == 'Egyptian'
                    ? 'مصري'
                    : 'إماراتي',
              ),
              currentAccountPicture: CircleAvatar(
                backgroundImage: AssetImage(state.userProfile['avatar']),
              ),
              decoration: const BoxDecoration(color: Colors.blue),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.home),
            title: const Text('الصفحة الرئيسية'),
            onTap: () {
              Navigator.pop(context);
              state.goToHomeScreen();
            },
          ),
          ListTile(
            leading: const Icon(Icons.settings),
            title: const Text('الإعدادات'),
            onTap: () {
              Navigator.pop(context);
              state.goToSettingsScreen();
            },
          ),
          ListTile(
            leading: Icon(
              state.editMode == EditMode.edit ? Icons.done : Icons.edit,
            ),
            title: Text(
              state.editMode == EditMode.edit ? 'إنهاء التحرير' : 'وضع التحرير',
            ),
            onTap: () {
              Navigator.pop(context);
              state.toggleEditMode();
            },
          ),
        ],
      ),
    );
  }

  Widget _buildCurrentScreenContent(BuildContext context) {
    final state = Provider.of<AppState>(context);

    switch (state.currentScreen) {
      case AppScreen.home:
        return HomeScreen(
          onCategoryTap: (categoryId, categoryName) {
            state.goToCategoryScreen(categoryId, categoryName);
          },
        );
      case AppScreen.category:
        return CategoryScreen(
          categoryId: state.currentCategoryId!,
          onSymbolTap: (symbol) => state.handleSymbolTap(symbol, context),
        );
      case AppScreen.settings:
        return SettingsScreen();
      case AppScreen.profile:
        return ProfileScreen();
    }
  }
}

class _MenuState {
  Timer? _doubleTapTimer;
  int tapCount = 0;
  bool isWaitingForDoubleTap = false;
  OverlayEntry? _currentOverlayEntry;

  void showInstruction(BuildContext context) {
    // إزالة أي رسالة سابقة
    _currentOverlayEntry?.remove();

    // الحصول على موضع زر القائمة بدقة
    final renderBox = context.findRenderObject() as RenderBox?;
    if (renderBox == null) return;

    final position = renderBox.localToGlobal(Offset.zero);
    final buttonSize = renderBox.size;

    final overlay = Navigator.of(context, rootNavigator: true)?.overlay;
    if (overlay == null) return;

    // إنشاء الرسالة الجديدة
    _currentOverlayEntry = OverlayEntry(
      builder:
          (context) => Positioned(
            top: position.dy + 10, //وق الزر مباشرة
            right: position.dx + 70,

            child: _buildInstructionMessage(),
          ),
    );

    overlay.insert(_currentOverlayEntry!);

    // إخفاء الرسالة بعد 4 ثواني
    Future.delayed(const Duration(seconds: 4), () {
      _currentOverlayEntry?.remove();
      _currentOverlayEntry = null;
    });
  }

  Widget _buildInstructionMessage() {
    return Material(
      color: Colors.transparent,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 180),
        padding: const EdgeInsets.all(7),
        decoration: BoxDecoration(
          color: const Color.fromARGB(255, 250, 251, 252),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 6,
              spreadRadius: 1,
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // السهم المؤشر (يشير لليمين نحو الزر)

            // المحتوى
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(
                    color: const Color.fromARGB(255, 32, 116, 175),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.touch_app,
                    size: 18,
                    color: Colors.blue,
                  ),
                ),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'اضغط مرتين ثم ضغطة مطولة',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: Color.fromARGB(255, 21, 48, 61),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void handleMenuTap(BuildContext context) {
    tapCount++;

    if (tapCount == 1) {
      // الضغطة الأولى: إظهار الرسالة
      showInstruction(context);
      isWaitingForDoubleTap = true;
      _doubleTapTimer?.cancel();
      _doubleTapTimer = Timer(const Duration(seconds: 3), () {
        isWaitingForDoubleTap = false;
        tapCount = 0;
      });
    } else if (tapCount == 2) {
      // الضغطة الثانية: إخفاء الرسالة بعد ثانية
      _doubleTapTimer?.cancel();
      _doubleTapTimer = Timer(const Duration(seconds: 1), () {
        isWaitingForDoubleTap = false;
        tapCount = 0;
      });
    }
  }

  void handleMenuLongPress(GlobalKey<ScaffoldState> scaffoldKey) {
    // إخفاء الرسالة عند فتح القائمة
    _currentOverlayEntry?.remove();
    _currentOverlayEntry = null;

    if (tapCount == 2) {
      scaffoldKey.currentState?.openEndDrawer();
    }
    tapCount = 0;
    isWaitingForDoubleTap = false;
    _doubleTapTimer?.cancel();
  }
}

class _ArrowPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint =
        Paint()
          ..color = Colors.white
          ..style = PaintingStyle.fill;

    final path = Path();
    path.moveTo(0, size.height / 2);
    path.lineTo(size.width, 0);
    path.lineTo(size.width, size.height);
    path.close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}