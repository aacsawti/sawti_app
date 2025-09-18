import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart' as path;
import './db/database_helper.dart';
import 'package:just_audio/just_audio.dart';
import 'dart:async';
import 'dart:math';

import 'dart:ui' as ui;

import 'dart:io';
import 'package:flutter/foundation.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // تحديد الاتجاهات بناءً على النظام الأساسي
  if (Platform.isAndroid || Platform.isIOS) {
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
  }

  // إخفاء شريط الحالة عند الإقلاع (لـ Android وiOS فقط)
  if (Platform.isAndroid || Platform.isIOS) {
    await _hideSystemUI();

    // بدء فحص دوري لإخفاء الشريط كل 5 ثوانٍ
    Timer.periodic(const Duration(seconds: 7), (timer) async {
      await _hideSystemUI();
    });
  }

  final dbHelper = DatabaseHelper();
  final users = await dbHelper.getUsers();
  final appState = AppState();

  // تحميل الإعدادات أولاً قبل بناء التطبيق
  await appState.loadUserAndSettings();

  // الحصول على الإعدادات من حالة التطبيق بدلاً من قاعدة البيانات مباشرة
  final isDarkMode = appState.settings['dark_mode'] == 'true';

  runApp(
    ChangeNotifierProvider(
      create: (_) => appState,
      child: MyApp(hasUser: users.isNotEmpty, isDarkMode: isDarkMode),
    ),
  );
}

// دالة لإخفاء شريط الحالة وشريط التنقل (لـ Android وiOS فقط)
Future<void> _hideSystemUI() async {
  try {
    if (Platform.isAndroid || Platform.isIOS) {
      await SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    }
  } catch (e) {
    debugPrint('فشل إخفاء شريط النظام: $e');
  }
}

class MyApp extends StatelessWidget {
  final bool hasUser;
  final bool isDarkMode;

  const MyApp({super.key, required this.hasUser, this.isDarkMode = false});

  @override
  Widget build(BuildContext context) {
    // تحديد اسم التطبيق بناءً على لغة الجهاز
    final deviceLocale = ui.window.locale;
    final appName = deviceLocale.languageCode == 'ar' ? 'صوتي' : 'Sawti';

    return MaterialApp(
      title: appName,
      home: hasUser ? const MainScaffold() : const SetupScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class SetupScreen extends StatefulWidget {
  const SetupScreen({super.key});

  @override
  _SetupScreenState createState() => _SetupScreenState();
}

class _SetupScreenState extends State<SetupScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  String _selectedDialect = 'MSA';
  String _selectedLevel = 'beginner';

  @override
  Widget build(BuildContext context) {
    final isLandscape =
        MediaQuery.of(context).orientation == Orientation.landscape;
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      appBar: AppBar(
        title: const Text('تهيئة المستخدم'),
        centerTitle: true,
        toolbarHeight: 44,
      ),
      body:
          isLandscape
              ? Row(
                children: [
                  // Logo Section
                  Expanded(
                    flex: 1,
                    child: Center(
                      child: Image.asset(
                        'assets/images/app_logo.png',
                        height: 200,
                      ),
                    ),
                  ),

                  // Form Section
                  Expanded(
                    flex: 2,
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 30,
                        vertical: 20,
                      ),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildUserNameField(),
                            const SizedBox(height: 30),
                            const Text(
                              'اختر اللهجة:',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 10),
                            _buildDialectSelector(),
                            const SizedBox(height: 30),
                            const Text(
                              'مستوى المستخدم:',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 10),
                            _buildLevelSelector(),
                            const SizedBox(height: 40),
                            Center(child: _buildSubmitButton()),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              )
              : const Center(
                child: Text(
                  'يرجى تدوير الجهاز للوضع الأفقي لعرض هذه الشاشة.',
                  style: TextStyle(fontSize: 18, color: Colors.grey),
                ),
              ),
    );
  }

  Widget _buildUserNameField() {
    return TextFormField(
      controller: _nameController,
      decoration: InputDecoration(
        labelText: 'اسم المستخدم',
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        prefixIcon: const Icon(Icons.person),
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'الرجاء إدخال اسم المستخدم';
        }
        return null;
      },
    );
  }

  Widget _buildDialectSelector() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Column(
          children: [
            _buildRadioTile('الفصحى', 'MSA', Icons.language, Colors.blue),
            const Divider(height: 1),

            _buildRadioTile(
              'اللهجة الإماراتية',
              'Emirati',
              Icons.language,
              Colors.orange,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLevelSelector() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Column(
          children: [
            _buildRadioTile(
              'مبتدئ',
              'beginner',
              Icons.school,
              Colors.blue,
              subtitle: 'للمستخدمين الجدد',
            ),
            const Divider(height: 1),
            _buildRadioTile(
              'متقدم',
              'advanced',
              Icons.workspace_premium,
              Colors.green,
              subtitle: 'للمستخدمين المحترفين',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRadioTile(
    String title,
    String value,
    IconData icon,
    Color iconColor, {
    String? subtitle,
  }) {
    return ListTile(
      leading: Icon(icon, color: iconColor),
      title: Text(title),
      subtitle: subtitle != null ? Text(subtitle) : null,
      trailing: Radio<String>(
        value: value,
        groupValue:
            value == 'MSA' || value == 'Egyptian' || value == 'Emirati'
                ? _selectedDialect
                : _selectedLevel,
        onChanged: (val) {
          setState(() {
            if (value == 'MSA' || value == 'Egyptian' || value == 'Emirati') {
              _selectedDialect = val!;
            } else {
              _selectedLevel = val!;
            }
          });
        },
      ),
    );
  }

  Widget _buildSubmitButton() {
    return ElevatedButton(
      onPressed: _saveAndContinue,
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        backgroundColor: Colors.blue,
      ),
      child: const Text(
        'بدء الاستخدام',
        style: TextStyle(fontSize: 18, color: Colors.white),
      ),
    );
  }

  Future<void> _saveAndContinue() async {
    if (_formKey.currentState!.validate()) {
      final dbHelper = DatabaseHelper();
      final appState = Provider.of<AppState>(context, listen: false);

      try {
        // إدخال المستخدم أولاً
        final userId = await dbHelper.insertUser(_nameController.text);

        if (userId > 0) {
          // استخدام الدالة الجديدة لتغيير اللهجة فوراً
          await appState.changeDialectImmediately(_selectedDialect);

          // تحديث مستوى المستخدم أيضاً
          await appState.updateSettings({'user_level': _selectedLevel});

          // تحميل بيانات المستخدم الجديدة فوراً
          await appState.loadUserAndSettings();

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('تم حفظ البيانات بنجاح'),
              duration: Duration(seconds: 2),
            ),
          );

          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (context) => const MainScaffold()),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('فشل في حفظ البيانات'),
              duration: Duration(seconds: 2),
            ),
          );
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('حدث خطأ: ${e.toString()}'),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }
}

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

  Future<void> initializeApp() async {
    await loadUserAndSettings();

    // إذا لم تكن هناك إعدادات محفوظة، قم بتهيئة الإعدادات الافتراضية
    if (_settings.isEmpty) {
      await updateSettings({
        'dialect': 'MSA',
        'user_level': 'beginner',
        'verb_conjugation': 'off',
        'speaker_gender': 'male',
        'speaker_type': 'adult',
        'grid_size': 8,
        'tense': 'present',
        'dark_mode': 'false',
      });
    }

    // تعيين اللهجة الحالية من الإعدادات
    _currentDialect = _settings['dialect'] ?? 'MSA';

    notifyListeners();
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

  Future<void> changeDialectImmediately(String dialect) async {
    _currentDialect = dialect;

    // تحديث الإعدادات المحلية
    final newSettings = Map<String, dynamic>.from(_settings);
    newSettings['dialect'] = dialect;
    _settings = newSettings;

    // تعيين المتحدث المناسب بناءً على اللهجة
    int speakerId;
    if (dialect == 'MSA') {
      speakerId = 5; // المتحدث للهجة الفصحى
    } else if (dialect == 'Emirati') {
      speakerId = 2; // المتحدث للهجة الإماراتية
    } else {
      speakerId = 1; // المتحدث الافتراضي للهجة المصرية
    }

    newSettings['speaker_id'] = speakerId;

    // حفظ التغيير في قاعدة البيانات
    final dbHelper = DatabaseHelper();
    await dbHelper.updateSettings({
      'dialect': dialect,
      'speaker_id': speakerId,
    });

    // إعادة تحميل المتحدثين المتوافقين مع اللهجة الجديدة
    await updateSettings({});

    // إخطار جميع الواجهات بالتحديث
    notifyListeners();
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

      // 2. تعيين اللهجة الحالية من الإعدادات
      _currentDialect = _settings['dialect'] ?? 'MSA';

      // 3. تعيين المتحدث المناسب بناءً على اللهجة
      if (_settings['speaker_id'] == null) {
        int speakerId;
        if (_currentDialect == 'MSA') {
          speakerId = 2; // المتحدث للهجة الفصحى
        } else if (_currentDialect == 'Emirati') {
          speakerId = 4; // المتحدث للهجة الإماراتية
        } else {
          speakerId = 1; // المتحدث للهجة المصرية
        }

        await updateSettings({'speaker_id': speakerId});
      }

      // 4. التحقق من توافق المتحدث الحالي
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

      // 5. تحميل بيانات المستخدم
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
                onTap:
                    () => onCategoryTap(
                      categories[index].id,
                      categories[index].name,
                    ),
              );
            } else {
              final symbol = symbols[index - categories.length];
              return SymbolItem(
                symbol: symbol,
                isMainScreen: true,
                // أضفنا هذا الجزء لإضافة الرمز للشريط العلوي عند النقر
                onTap: () => state.handleSymbolTap(symbol, context),
              );
            }
          },
        );
      },
    );
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
        if (snapshot.connectionState == ConnectionState.waiting) {
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
          itemBuilder:
              (context, index) => SymbolItem(
                symbol: symbols[index],
                onTap:
                    onSymbolTap != null
                        ? () => onSymbolTap!(symbols[index])
                        : null,
              ),
        );
      },
    );
  }
}

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

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  _SettingsScreenState createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late Map<String, dynamic> _currentSettings;
  final DatabaseHelper _dbHelper = DatabaseHelper();
  bool _isLoading = true;
  List<Map<String, dynamic>> _availableSpeakers = [];
  int? _selectedSpeakerId;

  @override
  void initState() {
    super.initState();
    _loadSettings().then((_) {
      // تحديث المتحدث فور تحميل الإعدادات
      final state = Provider.of<AppState>(context, listen: false);
      state.updateSettings({}); // إعادة حساب المتحدث المتوافق
    });
  }

  Future<void> _loadSettings() async {
    try {
      final settings = await _dbHelper.getSettings();
      setState(() {
        _currentSettings = Map.from(settings);
        _isLoading = false;
        _selectedSpeakerId = _currentSettings['speaker_id'];
      });
      _loadAvailableSpeakers();
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('فشل تحميل الإعدادات: ${e.toString()}')),
      );
    }
  }

  Future<void> _loadAvailableSpeakers() async {
    final dbHelper = DatabaseHelper();
    final speakers = await dbHelper.getAvailableSpeakers(
      _currentSettings['dialect'] ?? 'MSA',
      _currentSettings['speaker_gender'] ?? 'male',
      _currentSettings['speaker_type'] ?? 'adult',
    );

    setState(() {
      _availableSpeakers = speakers;

      // تحديد المتحدث المختار إذا كان متاحاً
      if (_selectedSpeakerId == null && speakers.isNotEmpty) {
        _selectedSpeakerId = speakers.first['id'] as int;
      }
    });
  }

  Future<void> _updateSetting(String key, dynamic value) async {
    try {
      // تحديث الإعدادات المحلية
      setState(() {
        _currentSettings[key] = value;
      });

      // تحديث قاعدة البيانات فوراً
      await _dbHelper.updateSettings({key: value});

      // إذا كانت الإعدادات التي تم تغييرها هي اللهجة
      if (key == 'dialect') {
        // تعيين المتحدث المناسب بناءً على اللهجة المختارة
        int? newSpeakerId;

        if (value == 'MSA') {
          newSpeakerId = 5; // المتحدث للهجة الفصحى
        } else if (value == 'Emirati') {
          newSpeakerId = 2; // المتحدث للهجة الإماراتية
        } else if (value == 'Egyptian') {
          newSpeakerId = 0;
        }

        if (newSpeakerId != null) {
          // تحديث rالمتحدث في الإعدادات المحلية
          setState(() {
            _currentSettings['speaker_id'] = newSpeakerId;
            _selectedSpeakerId = newSpeakerId;
          });

          // تحديث قاعدة البيانات بمعرف المتحدث الجديد
          await _dbHelper.updateSettings({'speaker_id': newSpeakerId});
        }
      }

      // تحديث حالة التطبيق
      Provider.of<AppState>(context, listen: false).loadSettings();

      // إعادة تحميل المتحدثين إذا تغيرت الإعدادات المؤثرة
      if (key == 'dialect' ||
          key == 'speaker_gender' ||
          key == 'speaker_type') {
        _loadAvailableSpeakers();
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('فشل حفظ التغييرات: ${e.toString()}')),
      );
    }
  }

  Future<void> _updateSelectedSpeaker(int speakerId) async {
    try {
      setState(() {
        _selectedSpeakerId = speakerId;
      });

      // تحديث قاعدة البيانات فوراً
      await _dbHelper.updateSettings({'speaker_id': speakerId});

      // تحديث حالة التطبيق
      Provider.of<AppState>(context, listen: false).loadSettings();

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('تم تحديث المتحدث')));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('فشل تحديث المتحدث: ${e.toString()}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(title: const Text('الإعدادات'), centerTitle: true),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            _buildDarkModeSetting(),
            const SizedBox(height: 20),
            _buildDialectSetting(),
            const SizedBox(height: 20),
            _buildUserLevelSetting(),
            const SizedBox(height: 20),
            _buildVerbConjugationSetting(),
            const SizedBox(height: 20),
            _buildSpeakerGenderSetting(),
            const SizedBox(height: 20),
            _buildSpeakerTypeSetting(),
            const SizedBox(height: 20),
            _buildSpeakerSelection(),
            const SizedBox(height: 20),
            _buildGridSizeSetting(),
            // const SizedBox(height: 20),
            // _buildTenseSetting(),
          ],
        ),
      ),
    );
  }

  Widget _buildDarkModeSetting() {
    return Consumer<AppState>(
      builder: (context, appState, _) {
        return Card(
          elevation: 2,
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: SwitchListTile(
              title: const Text('الوضع المظلم'),
              value: appState.isDarkMode,
              onChanged: (value) async {
                try {
                  await appState.toggleDarkMode(value);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'تم ${value ? 'تفعيل' : 'تعطيل'} الوضع المظلم',
                      ),
                    ),
                  );
                } catch (e) {
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(SnackBar(content: Text('حدث خطأ: $e')));
                }
              },
              secondary: Icon(
                appState.isDarkMode ? Icons.dark_mode : Icons.light_mode,
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildDialectSetting() {
    return Consumer<AppState>(
      builder: (context, appState, child) {
        return Card(
          elevation: 2,
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'اختر اللهجة:',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildDialectOption(
                      'MSA',
                      'الفصحى',
                      appState.currentDialect,
                    ),
                    // _buildDialectOption(
                    //   'Egyptian',
                    //   'مصرية',
                    //   appState.currentDialect,
                    // ),
                    _buildDialectOption(
                      'Emirati',
                      'خليجية',
                      appState.currentDialect,
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildDialectOption(
    String value,
    String label,
    String currentDialect,
  ) {
    return Column(
      children: [
        IconButton(
          icon: Icon(
            Icons.language,
            size: 30,
            color: currentDialect == value ? Colors.blue : Colors.grey,
          ),
          onPressed: () {
            final appState = Provider.of<AppState>(context, listen: false);
            appState.changeDialectImmediately(value);
          },
        ),
        Text(
          label,
          style: TextStyle(
            color: currentDialect == value ? Colors.blue : Colors.black,
          ),
        ),
      ],
    );
  }

  Widget _buildUserLevelSetting() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'مستوى المستخدم:',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                _buildLevelOption('beginner', 'مبتدئ'),
                const SizedBox(width: 16),
                _buildLevelOption('advanced', 'متقدم'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLevelOption(String value, String label) {
    return Expanded(
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor:
              _currentSettings['user_level'] == value
                  ? Colors.blue
                  : Colors.grey[300],
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
        onPressed: () async {
          await _updateSetting('user_level', value);
          if (value == 'beginner') {
            await _updateSetting('verb_conjugation', 'off');
          }
        },
        child: Text(
          label,
          style: TextStyle(
            color:
                _currentSettings['user_level'] == value
                    ? Colors.white
                    : Colors.black,
          ),
        ),
      ),
    );
  }

  Widget _buildVerbConjugationSetting() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'تصريف الأفعال:',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 10),
            SwitchListTile(
              title: const Text('تفعيل تصريف الأفعال'),
              value: _currentSettings['verb_conjugation'] == 'on',
              onChanged:
                  (_currentSettings['user_level'] == 'beginner')
                      ? null
                      : (value) {
                        _updateSetting(
                          'verb_conjugation',
                          value ? 'on' : 'off',
                        );
                      },
              secondary: const Icon(Icons.auto_fix_high),
            ),
            if (_currentSettings['user_level'] == 'beginner')
              const Text(
                'هذه الخاصية غير متاحة للمبتدئين',
                style: TextStyle(color: Colors.grey, fontSize: 12),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSpeakerGenderSetting() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'جنس المتحدث:',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                _buildSpeakerOption(
                  'speaker_gender',
                  'male',
                  'ذكر',
                  Icons.male,
                  Colors.blue,
                ),
                const SizedBox(width: 16),
                _buildSpeakerOption(
                  'speaker_gender',
                  'female',
                  'أنثى',
                  Icons.female,
                  Colors.pink,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSpeakerTypeSetting() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'نوع المتحدث:',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                _buildSpeakerOption(
                  'speaker_type',
                  'adult',
                  'بالغ',
                  Icons.person,
                  Colors.green,
                ),
                const SizedBox(width: 16),
                _buildSpeakerOption(
                  'speaker_type',
                  'child',
                  'طفل',
                  Icons.child_care,
                  Colors.orange,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSpeakerOption(
    String key,
    String value,
    String label,
    IconData icon,
    Color color,
  ) {
    return Expanded(
      child: OutlinedButton.icon(
        icon: Icon(icon, size: 24),
        label: Text(label),
        style: OutlinedButton.styleFrom(
          backgroundColor:
              _currentSettings[key] == value ? color.withOpacity(0.2) : null,
          side: BorderSide(
            color: _currentSettings[key] == value ? color : Colors.grey,
          ),
        ),
        onPressed: () => _updateSetting(key, value),
      ),
    );
  }

  Widget _buildSpeakerSelection() {
    if (_availableSpeakers.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              const Icon(Icons.warning, size: 50, color: Colors.orange),
              const SizedBox(height: 10),
              Text(
                'لا يوجد متحدثون متاحون للإعدادات الحالية',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.error,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 5),
              const Text(
                'الرجاء تغيير اللهجة أو نوع المتحدث',
                style: TextStyle(color: Colors.grey),
              ),
            ],
          ),
        ),
      );
    }

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'اختر المتحدث:',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 15,
              runSpacing: 15,
              children:
                  _availableSpeakers.map((speaker) {
                    final isSelected = _selectedSpeakerId == speaker['id'];
                    final speakerDialect = speaker['dialect'] ?? 'MSA';
                    final dialectName =
                        speakerDialect == 'MSA'
                            ? 'الفصحى'
                            : speakerDialect == 'Egyptian'
                            ? 'مصري'
                            : 'إماراتي';

                    return _SpeakerCard(
                      speaker: speaker,
                      isSelected: isSelected,
                      onSelect:
                          () => _updateSelectedSpeaker(speaker['id'] as int),
                      onPlay: () async {
                        final state = Provider.of<AppState>(
                          context,
                          listen: false,
                        );
                        await state.playSpeakerAudio(speaker['id'] as int);
                      },
                    );
                  }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGridSizeSetting() {
    return Consumer<AppState>(
      builder: (context, state, _) {
        final selected = state.settings['grid_size'] ?? 6;

        return Card(
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // العنوان المصغر
                const Row(
                  children: [
                    Icon(Icons.grid_view, color: Colors.blue, size: 20),
                    SizedBox(width: 8),
                    Text(
                      'عناصر في الصف',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // تصميم مضغوط: رقم حي وسلايدر في صف واحد
                Row(
                  children: [
                    // رقم حيّ في تصميم دائري مصغر
                    Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.blue.withOpacity(0.1),
                        border: Border.all(
                          color: Colors.blueAccent,
                          width: 1.5,
                        ),
                      ),
                      child: Center(
                        child: Text(
                          '$selected',
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.blueAccent,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),

                    Expanded(
                      child: Column(
                        children: [
                          // السلايدر المصغر
                          SliderTheme(
                            data: SliderThemeData(
                              trackHeight: 4,
                              thumbShape: const RoundSliderThumbShape(
                                enabledThumbRadius: 10,
                              ),
                              activeTrackColor: Colors.blue,
                              inactiveTrackColor: Colors.blue[100],
                              thumbColor: Colors.blueAccent,
                            ),
                            child: Slider(
                              value: selected.toDouble(),
                              min: 4,
                              max: 12,
                              divisions: 4,
                              label: '$selected عناصر',
                              onChanged: (double value) async {
                                await state.updateGridSize(value.round());
                              },
                            ),
                          ),

                          // مؤشرات القيم المختصرة
                          Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8.0,
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children:
                                  [4, 6, 8, 10, 12].map((size) {
                                    return Text(
                                      '$size',
                                      style: TextStyle(
                                        fontWeight:
                                            size == selected
                                                ? FontWeight.bold
                                                : FontWeight.normal,
                                        color:
                                            size == selected
                                                ? Colors.blue
                                                : Colors.grey,
                                        fontSize: 12,
                                      ),
                                    );
                                  }).toList(),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildTenseSetting() {
    final currentTense = (_currentSettings['tense'] ?? 'present').toLowerCase();

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'زمن التصريف:',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 10),
            DropdownButtonFormField<String>(
              value: currentTense,
              items: const [
                DropdownMenuItem(value: 'present', child: Text('المضارع')),
                DropdownMenuItem(value: 'past', child: Text('الماضي')),
                DropdownMenuItem(value: 'command', child: Text('الأمر')),
              ],
              onChanged: (value) {
                if (value != null) {
                  _updateSetting('tense', value);
                }
              },
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(horizontal: 10),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SpeakerCard extends StatefulWidget {
  final Map<String, dynamic> speaker;
  final bool isSelected;
  final VoidCallback onSelect;
  final VoidCallback onPlay;

  const _SpeakerCard({
    required this.speaker,
    required this.isSelected,
    required this.onSelect,
    required this.onPlay,
  });

  @override
  __SpeakerCardState createState() => __SpeakerCardState();
}

class __SpeakerCardState extends State<_SpeakerCard> {
  bool _isPlaying = false;
  Timer? _playTimer;

  @override
  void dispose() {
    _playTimer?.cancel();
    super.dispose();
  }

  Future<void> _handlePlay() async {
    if (_isPlaying) return;

    setState(() => _isPlaying = true);
    widget.onPlay();

    // محاكاة مدة التشغيل (3 ثواني)
    _playTimer = Timer(const Duration(seconds: 5), () {
      if (mounted) {
        setState(() => _isPlaying = false);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final speakerDialect = widget.speaker['dialect'] ?? 'MSA';
    final dialectName =
        speakerDialect == 'MSA'
            ? 'الفصحى'
            : speakerDialect == 'Egyptian'
            ? 'مصري'
            : 'إماراتي';

    return GestureDetector(
      onTap: widget.onSelect,
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color:
              widget.isSelected
                  ? Theme.of(context).primaryColor.withOpacity(0.2)
                  : Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(15),
          border: Border.all(
            color:
                widget.isSelected
                    ? Theme.of(context).primaryColor
                    : Colors.transparent,
            width: 2,
          ),
        ),
        child: Column(
          children: [
            CircleAvatar(
              backgroundImage: AssetImage(
                widget.speaker['avatar_path'] as String? ??
                    'assets/images/default_avatar.png',
              ),
              radius: 30,
            ),
            const SizedBox(height: 5),
            Text(
              '${widget.speaker['name']} ($dialectName)',
              style: TextStyle(
                fontWeight:
                    widget.isSelected ? FontWeight.bold : FontWeight.normal,
                color:
                    widget.isSelected
                        ? Theme.of(context).primaryColor
                        : Theme.of(context).textTheme.bodyLarge?.color,
              ),
            ),
            // زر تجربة الصوت
            IconButton(
              icon: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color:
                      _isPlaying
                          ? Colors.green
                          : Theme.of(context).primaryColor,
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.volume_up, color: Colors.white, size: 20),
              ),
              onPressed: _handlePlay,
            ),
          ],
        ),
      ),
    );
  }
}

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen>
    with WidgetsBindingObserver {
  late TextEditingController _nameController;
  bool _isEditing = false;
  final FocusNode _focusNode = FocusNode();
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    final state = Provider.of<AppState>(context, listen: false);
    _nameController = TextEditingController(
      text: state.userProfile['username'],
    );

    _focusNode.addListener(() {
      if (_focusNode.hasFocus) {
        Future.delayed(const Duration(milliseconds: 300), () {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        });
      }
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _nameController.dispose();
    _focusNode.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  void didChangeMetrics() {
    if (_focusNode.hasFocus) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      });
    }
    super.didChangeMetrics();
  }

  @override
  Widget build(BuildContext context) {
    final state = Provider.of<AppState>(context);
    final user = state.userProfile;
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final screenWidth = MediaQuery.of(context).size.width;

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        appBar: AppBar(
          title: const Text('الملف الشخصي'),
          actions: [
            IconButton(
              icon: Icon(_isEditing ? Icons.check : Icons.edit),
              onPressed: () async {
                if (_isEditing) {
                  await state.updateUserName(_nameController.text);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('تم تحديث الاسم بنجاح')),
                  );
                }
                setState(() {
                  _isEditing = !_isEditing;
                  if (!_isEditing) FocusScope.of(context).unfocus();
                });
              },
            ),
          ],
        ),
        body: Padding(
          padding: EdgeInsets.only(bottom: bottomInset),
          child: SingleChildScrollView(
            controller: _scrollController,
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: screenWidth - 70, // ترك مساحة 70px للقائمة الجانبية
                ),
                child: _buildLandscapeLayout(user, state),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLandscapeLayout(Map<String, dynamic> user, AppState state) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            children: [
              _buildAvatar(user),
              const SizedBox(height: 20),
              _buildUsername(),
              const SizedBox(height: 20),
              _buildSettingsButton(state),
              const SizedBox(height: 30),
            ],
          ),
        ),
        const SizedBox(width: 30),
        Expanded(child: _buildProfileInfoCard(state)),
      ],
    );
  }

  Widget _buildAvatar(Map<String, dynamic> user) {
    return CircleAvatar(
      radius: 60,
      backgroundImage: AssetImage(user['avatar']),
    );
  }

  Widget _buildUsername() {
    return _isEditing
        ? Padding(
          padding: const EdgeInsets.symmetric(horizontal: 30),
          child: TextField(
            controller: _nameController,
            focusNode: _focusNode,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              contentPadding: EdgeInsets.symmetric(
                vertical: 10,
                horizontal: 15,
              ),
            ),
          ),
        )
        : Text(
          _nameController.text,
          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        );
  }

  Widget _buildProfileInfoCard(AppState state) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.all(0),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            _buildProfileInfoRow(
              'اللهجة المفضلة',
              state.settings['dialect'] == 'standard'
                  ? 'الفصحى'
                  : state.settings['dialect'] == 'Egyptian'
                  ? 'مصري'
                  : 'إماراتي',
            ),
            const Divider(),
            _buildProfileInfoRow(
              'حجم الشبكة',
              '${state.settings['grid_size']} عناصر في الصف',
            ),
            const Divider(),
            _buildProfileInfoRow(
              'زمن التصريف',
              state.settings['tense'] == 'Present'
                  ? 'المضارع'
                  : state.settings['tense'] == 'Past'
                  ? 'الماضي'
                  : 'المستقبل',
            ),
            const Divider(),
            _buildProfileInfoRow(
              'مستوى المستخدم',
              state.settings['user_level'] == 'beginner' ? 'مبتدئ' : 'متقدم',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingsButton(AppState state) {
    return ElevatedButton.icon(
      onPressed: () {
        state.goToSettingsScreen();
      },
      icon: const Icon(Icons.settings),
      label: const Text('تعديل الإعدادات', style: TextStyle(fontSize: 18)),
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  Widget _buildProfileInfoRow(String title, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Expanded(
            flex: 4,
            child: Text(
              title,
              style: const TextStyle(fontSize: 16, color: Colors.grey),
            ),
          ),
          Expanded(
            flex: 5,
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }
}
