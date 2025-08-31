import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart' as path;
import 'database_helper.dart';
import 'dart:async';
import 'dart:math';

enum AppScreen { home, category, settings, profile }
enum EditMode { normal, edit }
enum ItemType { category, symbol }

class SelectedItem {
  final int id;
  final ItemType type;

  SelectedItem(this.id, this.type);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SelectedItem &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          type == other.type;

  @override
  int get hashCode => id.hashCode ^ type.hashCode;
}

class AppState extends ChangeNotifier {
  AppScreen _currentScreen = AppScreen.home;
  EditMode _editMode = EditMode.normal;
  String _currentDialect = 'MSA';
  int? _currentCategoryId;
  bool _showConjugations = false;
  final List<SymbolData> _selectedSymbols = [];
  final Set<SelectedItem> _selectedItems = {};
  SymbolData? _copiedSymbol;
  Timer? _conjugationTimer;
  int _menuPressCount = 0;
  bool _showMenuInstruction = false;
  Timer? _menuPressTimer;

  int get menuPressCount => _menuPressCount;
  bool get showMenuInstruction => _showMenuInstruction;

  Map<String, dynamic> _settings = {
    'dialect': 'MSA',
    'user_level': 'beginner',
    'verb_conjugation': 'off',
    'speaker_gender': 'male',
    'speaker_type': 'adult',
    'grid_size': 8,
    'tense': 'present',
    'dark_mode': 'fulse',
  };

  void showConjugations(List<SymbolData> conjugations) {
    // إلغاء المؤقت الحالي إذا كان موجوداً
    if (_conjugationTimer != null && _conjugationTimer!.isActive) {
      _conjugationTimer!.cancel();
    }

    _conjugationsController.add(
      ConjugationDisplayData(conjugations: conjugations),
    );

    // بدء مؤقت جديد لإغلاق النافذة بعد 20 ثانية
    _conjugationTimer = Timer(const Duration(seconds: 20), () {
      hideConjugations();
    });
  }

  void hideConjugations() {
    // إلغاء المؤقت الحالي إذا كان موجوداً
    if (_conjugationTimer != null && _conjugationTimer!.isActive) {
      _conjugationTimer!.cancel();
    }
    _conjugationTimer = null;

    _conjugationsController.add(null);
  }

  final StreamController<ConjugationDisplayData?> _conjugationsController =
      StreamController<ConjugationDisplayData?>.broadcast();
  Stream<ConjugationDisplayData?> get conjugationsStream =>
      _conjugationsController.stream;
  List<Map<String, dynamic>> _availableSpeakers = [];

  // دالة للحصول على المتحدثين المتاحين
  Future<List<Map<String, dynamic>>> getAvailableSpeakers() async {
    final dbHelper = DatabaseHelper();
    _availableSpeakers = await dbHelper.getAvailableSpeakers(
      _settings['dialect'] ?? 'MSA',
      _settings['speaker_gender'] ?? 'male',
      _settings['speaker_type'] ?? 'adult',
    );
    return _availableSpeakers;
  }

  void _resetMenuPress() {
    _menuPressCount = 0;
    _showMenuInstruction = false;
    _menuPressTimer?.cancel();
    _menuPressTimer = null;
    notifyListeners();
  }

  // Handle menu button press
  void handleMenuPress() {
    _menuPressCount++;

    if (_menuPressCount == 1) {
      // First press: show instruction and start reset timer
      _showMenuInstruction = true;
      _menuPressTimer = Timer(const Duration(seconds: 2), _resetMenuPress);
    } else if (_menuPressCount == 2) {
      // Second press: reset the instruction timer
      _menuPressTimer?.cancel();
      _menuPressTimer = Timer(const Duration(seconds: 1), _resetMenuPress);
    }

    notifyListeners();
  }

  // Handle menu long press
  void handleMenuLongPress() {
    if (_menuPressCount == 2) {
      _isSidebarOpen = !_isSidebarOpen;
      _resetMenuPress();
    }
  }

  Map<String, dynamic> _userProfile = {
    'username': 'مستخدم',
    'avatar': 'assets/images/default_avatar.png',
  };
  final AudioPlayer _audioPlayer = AudioPlayer();
  List<SymbolData>? _currentConjugations;
  // bool _showConjugations = false;
  bool _isSidebarOpen = false;
  //int _menuPressCount = 0;

  AppScreen get currentScreen => _currentScreen;
  EditMode get editMode => _editMode;
  String get currentDialect => _currentDialect;
  int? get currentCategoryId => _currentCategoryId;
  List<SymbolData> get selectedSymbols => _selectedSymbols;
  Set<SelectedItem> get selectedItems => _selectedItems;
  SymbolData? get copiedSymbol => _copiedSymbol;
  Map<String, dynamic> get settings => _settings;
  Map<String, dynamic> get userProfile => _userProfile;
  int get gridSize => _settings['grid_size'] ?? 8;
  List<SymbolData>? get currentConjugations => _currentConjugations;
  // bool get showConjugations => _showConjugations;
  SelectedItem? get firstSelected =>
      _selectedItems.isNotEmpty ? _selectedItems.first : null;
  bool get isSidebarOpen => _isSidebarOpen;
  String? currentCategoryName;
  bool _isDarkMode = false;

  final DatabaseHelper _dbHelper = DatabaseHelper();
  bool get isDarkMode => _isDarkMode;

  Future<void> initSettings() async {
    final settings = await _dbHelper.getSettings();
    if (settings.isNotEmpty) {
      _isDarkMode = settings['dark_mode'] == 'true';
    }
    notifyListeners();
  } // أضف هذا السطر
  // Future<void> toggleDarkMode(bool value) async {
  //   _isDarkMode = value;
  //   await _dbHelper.updateSettings({'dark_mode': value ? 'true' : 'false'});
  //   notifyListeners();
  // }

  void goToCategoryScreen(int categoryId, String categoryName) {
    _currentScreen = AppScreen.category;
    _currentCategoryId = categoryId;
    currentCategoryName = categoryName;
    notifyListeners();
  }

  void toggleSidebar() {
    _menuPressCount++;
    if (_menuPressCount >= 3) {
      _isSidebarOpen = !_isSidebarOpen;
      _menuPressCount = 0;
      notifyListeners();
    } else {
      Future.delayed(const Duration(seconds: 1), () {
        _menuPressCount = 0;
      });
    }
  }

  void closeSidebar() {
    _isSidebarOpen = false;
    notifyListeners();
  }

  // ... المتغيرات الأخرى ...
  Future<void> playSpeakerAudio(int speakerId) async {
    final dbHelper = DatabaseHelper();
    final speaker = await dbHelper.getSpeakerById(speakerId);

    if (speaker != null && speaker['voice_path'] != null) {
      try {
        await _audioPlayer.stop();
        await _audioPlayer.setAsset(speaker['voice_path']);
        await _audioPlayer.play();
      } catch (e) {
        debugPrint("Error playing speaker audio: $e");
      }
    }
  }

  Future<void> toggleDarkMode(bool value) async {
    // إنشاء نسخة جديدة من الخريطة قبل التعديل
    final newSettings = Map<String, dynamic>.from(_settings);
    newSettings['dark_mode'] = value.toString();

    _isDarkMode = value;
    _settings = newSettings; // استبدال الخريطة القديمة بالجديدة

    try {
      await _dbHelper.updateSettings({'dark_mode': value.toString()});
      debugPrint('تم تغيير الوضع المظلم إلى: $value');
    } catch (e) {
      debugPrint('خطأ في حفظ الوضع المظلم: $e');
    }

    notifyListeners();
  }

  Future<void> loadSettings22() async {
    final settings = await _dbHelper.getSettings();
    if (settings.isNotEmpty) {
      // إنشاء نسخة جديدة من الخريطة
      _settings = Map<String, dynamic>.from(settings);
      _isDarkMode = _settings['dark_mode'] == 'true';
    }
    notifyListeners();
  }

  Future<void> updateSelectedSpeaker(int speakerId) async {
    final dbHelper = DatabaseHelper();
    await dbHelper.updateSelectedSpeaker(speakerId);

    // تشغيل الصوت التعريفي
    await playSpeakerAudio(speakerId);

    // تحديث الإعدادات المحلية
    final speaker = await dbHelper.getSpeakerById(speakerId);
    if (speaker != null) {
      final newSettings = Map<String, dynamic>.from(_settings);
      newSettings['speaker_id'] = speakerId;

      _settings = newSettings;
      notifyListeners();
    }
  }

  // Future<List<Map<String, dynamic>>> getAvailableSpeakers() async {
  //   final dbHelper = DatabaseHelper();
  //   return await dbHelper.getAvailableSpeakers(
  //     _settings['dialect'],
  //     _settings['speaker_gender'],
  //     _settings['speaker_type'],
  //   );
  // }

  Future<Map<String, dynamic>?> getSpeakerById(int id) async {
    final dbHelper = DatabaseHelper();
    return await dbHelper.getSpeakerById(id);
  }

  Future<void> playSymbolAudio(SymbolData symbol, BuildContext context) async {
    // 1. التحقق من وجود متحدث متوافق
    if (_settings['speaker_id'] == null) {
      debugPrint("لا يوجد متحدث متوافق مع الإعدادات الحالية");

      // محاولة اختيار متحدث تلقائياً
      await updateSettings({});

      if (_settings['speaker_id'] == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('لا يوجد متحدث متوافق مع الإعدادات الحالية'),
            duration: Duration(seconds: 2),
          ),
        );
        return;
      }
    }

    // 2. استمرار عملية التشغيل العادية
    final dbHelper = DatabaseHelper();
    String? audioPath;

    if (symbol.isConjugation) {
      audioPath = await dbHelper.getConjugationAudioPath(
        symbol.id,
        _settings['speaker_id'],
      );
    } else {
      audioPath = await dbHelper.getSymbolAudioPath(
        symbol.originalId,
        _settings['speaker_id'],
      );
    }

    if (audioPath != null) {
      try {
        await _audioPlayer.stop();
        await _audioPlayer.setAsset(audioPath);
        await _audioPlayer.seek(Duration.zero);
        await _audioPlayer.play();
      } catch (e) {
        debugPrint("Error playing audio: $e");
      }
    } else {
      debugPrint("لم يتم العثور على مسار صوتي للرمز");
    }
  }

  Future<void> playConjugationAudio(int conjugationId) async {
    final dbHelper = DatabaseHelper();
    if (_settings['speaker_id'] == null) return;

    /// *** NEW – fallback path to use when DB returns null
    const String _fallbackAudioPath =
        'assets/voices/Shamma/Female_Shamma__.ياكلون.mp3';

    /// ***

    final String? audioPath = await dbHelper.getConjugationAudioPath(
      // unchanged
      conjugationId,
      _settings['speaker_id'],
    );

    // Debug prints (Arabic text left as is)
    print('مساااااااااااااااررررررالصوت');
    print(audioPath);
    print('نهااااايةساااااااااااااااررررررالصوت');

    /// *** NEW – choose DB path if present, otherwise fallback
    final String selectedPath = audioPath ?? _fallbackAudioPath;

    /// ***
    print(selectedPath);
    try {
      await _audioPlayer.stop();
      await _audioPlayer.setAsset(selectedPath);

      /// *** MODIFIED
      await _audioPlayer.seek(Duration.zero);
      await _audioPlayer.play();
    } catch (e) {
      debugPrint("Error playing audio: $e");
    }
  }

  Future<void> loadSettings() async {
    final dbHelper = DatabaseHelper();
    _settings = await dbHelper.getSettings();
    if (_settings['user_level'] == 'beginner') {
      _settings['verb_conjugation'] = 'off';
    }
    if (settings.isNotEmpty) {
      // إنشاء نسخة جديدة من الخريطة
      _settings = Map<String, dynamic>.from(settings);
      _isDarkMode = _settings['dark_mode'] == 'true';
    }
    _currentDialect = _settings['dialect'] ?? 'MSA';
    notifyListeners();
  }

  Future<void> loadUserProfile() async {
    final dbHelper = DatabaseHelper();
    final user = await dbHelper.getUser();
    _userProfile = {
      'username': user['name'],
      'avatar': user['avatar'] ?? 'assets/images/default_avatar.png',
    };
    notifyListeners();
  }

  Future<void> updateUserName(String newName) async {
    final dbHelper = DatabaseHelper();
    await dbHelper.updateUserName(newName);
    _userProfile['username'] = newName;
    notifyListeners();
  }
  ///////////////////////////////////////////////////////////////////////////////////////////////////////////
  // final audioPlayer = AudioPlayer();
  // Future<void> playSymbolAudio(SymbolData symbol) async {
  //   final dbHelper = DatabaseHelper();
  //   print(symbol.originalId);
  //   final audioPath = await dbHelper.getSymbolAudioPath(
  //     symbol.originalId,
  //     _settings['dialect'],
  //     _settings['speaker_type'],
  //     _settings['speaker_gender'],
  //   );
  //   print(audioPath);
  //   if (audioPath != null) {
  //     try {
  //       await _audioPlayer.stop();
  //       await _audioPlayer.setAsset(audioPath);
  //       await _audioPlayer.seek(Duration.zero);
  //       await _audioPlayer.play();
  //     } catch (e) {
  //       print("Error playing audio: $e");
  //     }
  //   }
  // }

  // Future<void> playConjugationAudio(int conjugationId) async {
  //   final dbHelper = DatabaseHelper();
  //   final audioPath = await dbHelper.getConjugationAudioPath(
  //     conjugationId,
  //     _settings['dialect'],
  //     _settings['speaker_type'],
  //     _settings['speaker_gender'],
  //   );
  //   print(audioPath);
  //   if (audioPath != null) {
  //     try {
  //       await audioPlayer.setAsset(audioPath);
  //       await audioPlayer.play();
  //     } catch (e) {
  //       print("Error playing audio: $e");
  //     }
  //   }
  // }>
  Future<void> updateSettings(Map<String, dynamic> newSettings) async {
    final dbHelper = DatabaseHelper();

    // 1. نسخ الإعدادات الحالية
    final updatedSettings = Map<String, dynamic>.from(_settings);

    // 2. تطبيق التغييرات الجديدة
    updatedSettings.addAll(newSettings);

    // 3. تحديد ما إذا كانت الإعدادات المؤثرة على المتحدث قد تغيرت
    final speakerSettingsChanged =
        newSettings.containsKey('dialect') ||
        newSettings.containsKey('speaker_gender') ||
        newSettings.containsKey('speaker_type');

    if (speakerSettingsChanged) {
      try {
        // 4. جلب المتحدثين المتوافقين مع الإعدادات الجديدة
        final compatibleSpeakers = await dbHelper.getAvailableSpeakers(
          updatedSettings['dialect'] ?? 'MSA',
          updatedSettings['speaker_gender'] ?? 'male',
          updatedSettings['speaker_type'] ?? 'adult',
        );

        // 5. تحديث المتحدث تلقائيًا إذا وجد متحدثون
        if (compatibleSpeakers.isNotEmpty) {
          updatedSettings['speaker_id'] = compatibleSpeakers.first['id'];
          debugPrint(
            'تم اختيار المتحدث تلقائيًا: ${compatibleSpeakers.first['name']}',
          );

          // 6. حفظ المتحدث المحدد في قاعدة البيانات
          await dbHelper.updateSelectedSpeaker(
            compatibleSpeakers.first['id'] as int,
          );
        } else {
          updatedSettings['speaker_id'] = null;
          debugPrint('لا يوجد متحدثون متوافقون مع الإعدادات الجديدة');
        }
      } catch (e) {
        debugPrint('خطأ في تحديث المتحدث: $e');
      }
    }

    // 7. حفظ جميع الإعدادات
    await dbHelper.updateSettings(updatedSettings);

    // 8. تحديث الحالة المحلية
    _settings = updatedSettings;
    _currentDialect = _settings['dialect'] ?? 'MSA';

    // 9. إعادة تحميل المتحدثين المتاحين
    _availableSpeakers = await dbHelper.getAvailableSpeakers(
      _settings['dialect'] ?? 'MSA',
      _settings['speaker_gender'] ?? 'male',
      _settings['speaker_type'] ?? 'adult',
    );

    // 10. إعلام الواجهات بالتغيير
    notifyListeners();
  }

  Future<void> loadUserAndSettings() async {
    final dbHelper = DatabaseHelper();

    try {
      // 1. جلب الإعدادات الحالية
      final settings = await dbHelper.getSettings();
      _settings = settings;

      // 2. التحقق من توافق المتحدث الحالي
      if (_settings['speaker_id'] != null) {
        final isCompatible = await dbHelper.isSpeakerCompatible(
          _settings['speaker_id'],
          _settings['dialect'] ?? 'MSA',
          _settings['speaker_gender'] ?? 'male',
          _settings['speaker_type'] ?? 'adult',
        );

        if (!isCompatible) {
          await updateSettings({}); // سيؤدي هذا إلى اختيار متحدث جديد تلقائياً
        }
      } else {
        await updateSettings({}); // إذا لم يكن هناك متحدث محدد
      }

      // 3. تحميل بيانات المستخدم
      final user = await dbHelper.getUser();
      _userProfile = {
        'username': user['name'] ?? 'مستخدم',
        'avatar': user['avatar'] ?? 'assets/images/default_avatar.png',
      };

      notifyListeners();
    } catch (e) {
      debugPrint('خطأ في تحميل الإعدادات: $e');
    }
  }

  Future<void> handleSymbolTap(SymbolData symbol, BuildContext context) async {
    addSelectedSymbol(symbol);
    await playSymbolAudio(symbol, context);
    //
  }


  void addConjugationToBar(SymbolData conjugation) {
    hideConjugations(); // إغلاف النافذة وإلغاء المؤقت
    addSelectedSymbol(conjugation);
    playConjugationAudio(conjugation.id);
  }

  void changeDialect(String dialect) {
    _currentDialect = dialect;
    _settings['dialect'] = dialect;
    notifyListeners();
  }

  Future<void> updateGridSize(int newSize) async {
    final dbHelper = DatabaseHelper();

    // إنشاء خريطة جديدة بدلاً من تعديل الخريطة الحالية
    final newSettings = Map<String, dynamic>.from(_settings);
    newSettings['grid_size'] = newSize;

    _settings = newSettings; // استبدال الخريطة القديمة بالجديدة
    notifyListeners(); // إعلام الواجهات بالتغيير

    final result = await dbHelper.updateSettings({'grid_size': newSize});
    if (result == 0) {
      debugPrint('فشل حفظ الإعدادات في قاعدة البيانات');
    }
  }

  void toggleEditMode() {
    _editMode = _editMode == EditMode.normal ? EditMode.edit : EditMode.normal;
    _selectedItems.clear();
    notifyListeners();
  }

  void goToHomeScreen() {
    _currentScreen = AppScreen.home;
    _currentCategoryId = null;
    notifyListeners();
  }

  void goToCategoryScreen22(int categoryId) {
    _currentScreen = AppScreen.category;
    _currentCategoryId = categoryId;
    notifyListeners();
  }

  void goToSettingsScreen() {
    _currentScreen = AppScreen.settings;
    notifyListeners();
  }

  void goToProfileScreen() {
    _currentScreen = AppScreen.profile;
    notifyListeners();
  }

  
  void toggleSelection(int id, ItemType type) {
    final item = SelectedItem(id, type);
    if (_selectedItems.contains(item)) {
      _selectedItems.remove(item);
    } else {
      _selectedItems.clear();
      _selectedItems.add(item);
    }
    notifyListeners();
  }

  bool isSelected(int id, ItemType type) {
    return _selectedItems.contains(SelectedItem(id, type));
  }

  void clearAllSelections() {
    _selectedItems.clear();
    notifyListeners();
  }

  void copySelectedItem(SymbolData symbol) {
    _copiedSymbol = symbol;
    notifyListeners();
  }

  void clearCopiedSymbol() {
    _copiedSymbol = null;
    notifyListeners();
  }

  Future<void> pasteCopiedSymbol(BuildContext context) async {
    if (_copiedSymbol == null) return;

    final dbHelper = DatabaseHelper();
    final targetCategory = _currentCategoryId ?? 0;

    try {
      await dbHelper.copySymbolToCategory(_copiedSymbol!.id, targetCategory);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('تم لصق ${_copiedSymbol!.getName(_currentDialect)}'),
        ),
      );

      _refreshScreen();
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('فشل اللصق: ${e.toString()}')));
    }
  }

  void _refreshScreen() {
    if (_currentScreen == AppScreen.home) {
      goToHomeScreen();
    } else {
      goToCategoryScreen22(_currentCategoryId!);
    }
  }

  final StreamController<List<SymbolData>> _selectedSymbolsController =
      StreamController<List<SymbolData>>.broadcast();
  Stream<List<SymbolData>> get selectedSymbolsStream =>
      _selectedSymbolsController.stream;

  
  void addSelectedSymbol(SymbolData symbol) {
    _selectedSymbols.add(symbol);
    _selectedSymbolsController.add(List.from(_selectedSymbols));
    // لا حاجة لـ notifyListeners()
  }

  void removeLastSymbol() {
    if (_selectedSymbols.isNotEmpty) {
      _selectedSymbols.removeLast();
      _selectedSymbolsController.add(List.from(_selectedSymbols));
    }
  }

  void clearSelectedSymbols() {
    _selectedSymbols.clear();
    _selectedSymbolsController.add(List.from(_selectedSymbols));
  }

  final StreamController<String> _tenseController =
      StreamController<String>.broadcast();

  
  Stream<String> get tenseStream => _tenseController.stream;

 
  Future<void> updateTense(String tense) async {
    if (_settings['tense'] == tense) return;

    final newSettings = Map<String, dynamic>.from(_settings);
    newSettings['tense'] = tense;

    final dbHelper = DatabaseHelper();
    await dbHelper.updateSettings({'tense': tense});

    _settings = newSettings;
    _tenseController.add(tense); 
  }

  
  @override
  void dispose() {
    _tenseController.close();
    super.dispose();
  }

 
  Future<void> playSelectedSymbols() async {
    // التحقق من وجود متحدث
    if (_settings['speaker_id'] == null) {
      debugPrint("لا يوجد متحدث متوافق مع الإعدادات الحالية");
      return;
    }

    if (_selectedSymbols.isEmpty) return;

    final dbHelper = DatabaseHelper();
    List<AudioSource> audioSources = [];

    for (final symbol in _selectedSymbols) {
      String? audioPath;

      if (symbol.isConjugation) {
        audioPath = await dbHelper.getConjugationAudioPath(
          symbol.id,
          _settings['speaker_id'],
        );
      } else {
        audioPath = await dbHelper.getSymbolAudioPath(
          symbol.originalId,
          _settings['speaker_id'],
        );
      }

      if (audioPath != null) {
        audioSources.add(AudioSource.asset(audioPath));
      }
    }

    if (audioSources.isEmpty) return;

    try {
      await _audioPlayer.stop();
      await _audioPlayer.setAudioSource(
        ConcatenatingAudioSource(
          useLazyPreparation: false,
          children: audioSources,
        ),
      );
      await _audioPlayer.play();
    } catch (e) {
      debugPrint("خطأ في تشغيل الصوت: $e");
    }
  }

  Future<void> handleSymbolLongPress(
    SymbolData symbol,
    BuildContext context,
  ) async {
    if (_settings['verb_conjugation'] != 'on' || !symbol.isVerb) return;

    final dbHelper = DatabaseHelper();
    final conjugations = await dbHelper.getConjugations(
      symbol.originalId,
      _settings['tense'],
      _settings['dialect'],
    );

    if (conjugations.isNotEmpty) {
      showConjugations(conjugations); // سيؤدي هذا لإلغاء أي مؤقت قائم
    }
  }
}

class ConjugationDisplayData {
  final List<SymbolData> conjugations;

  ConjugationDisplayData({required this.conjugations});
}

class CategoryData {
  final int id;
  final String name;
  final String imagePath;
  final bool isHidden;

  CategoryData({
    required this.id,
    required this.name,
    required this.imagePath,
    this.isHidden = false,
  });

  factory CategoryData.fromMap(Map<String, dynamic> map) {
    return CategoryData(
      id: map['id'] as int,
      name: map['name'] as String,
      imagePath: map['image_path'] as String,
      isHidden: map['is_hidden'] == 1,
    );
  }
}

class SymbolData {
  final int id;
  final int categoryId;
  final int originalId;
  final String label;
  final String imagePath;
  final bool isVerb;
  final bool isPronoun;
  final bool isHidden;
  final bool isFaded;
  final bool isAvailable;
  final String color;
  final Map<String, String>? namesByDialect;
  final bool isConjugation; // إضافة هذه الخاصية

  SymbolData({
    required this.id,
    required this.categoryId,
    required this.originalId,
    required this.label,
    required this.imagePath,
    this.isVerb = false,
    this.isPronoun = false,
    this.isHidden = false,
    this.isFaded = false,
    this.isAvailable = true,
    this.color = "#FFFFFF",
    this.namesByDialect,
    this.isConjugation = false, // قيمة افتراضية
  });

  String getName(String dialect) {
    if (namesByDialect != null && namesByDialect!.containsKey(dialect)) {
      return namesByDialect![dialect]!;
    }
    return label;
  }

  factory SymbolData.fromMap(Map<String, dynamic> map) {
    return SymbolData(
      id: map['id'] as int,
      categoryId: map['category_id'] as int,
      originalId: map['original_Id'] as int,
      label: map['label'] as String,
      imagePath: map['image_path'] as String,
      isVerb: map['is_verb'] == 1,
      isPronoun: map['is_pronoun'] == 1,
      isHidden: map['is_hidden'] == 1,
      isFaded: map['is_faded'] == 1,
      isAvailable: map['is_available'] == 1,
      color: map['color'] ?? "#FFFFFF", // <-- استرجاع اللون من الداتا
    );
  }

  SymbolData copyWith({Map<String, String>? namesByDialect, String? color}) {
    return SymbolData(
      id: id,
      categoryId: categoryId,
      originalId: originalId,
      label: label,
      imagePath: imagePath,
      isVerb: isVerb,
      isPronoun: isPronoun,
      isHidden: isHidden,
      isFaded: isFaded,
      isAvailable: isAvailable,
      color: color ?? this.color,
      namesByDialect: namesByDialect ?? this.namesByDialect,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'category_id': categoryId,
      'original_Id': originalId,
      'label': label,
      'image_path': imagePath,
      'is_verb': isVerb ? 1 : 0,
      'is_pronoun': isPronoun ? 1 : 0,
      'is_hidden': isHidden ? 1 : 0,
      'is_faded': isFaded ? 1 : 0,
      'is_available': isAvailable ? 1 : 0,
      'color': color, // <-- تخزين اللون
    };
  }
}