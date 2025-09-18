import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../main.dart';
import 'package:provider/provider.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._internal();
  static Database? _database;

  factory DatabaseHelper() => instance;

  DatabaseHelper._internal();

  Future<Database> get database async {
    if (_database != null) {
      print('✅ قاعدة البيانات مفتوحة مسبقًا');
      return _database!;
    }
    print('🔄 جاري تهيئة قاعدة البيانات لأول مرة');
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'aac_app.db');

    // تأكد أن قاعدة البيانات موجودة في المسار المطلوب
    if (!await databaseExists(path)) {
      try {
        await Directory(dirname(path)).create(recursive: true);

        // نسخ من الأصول فقط إذا لم تكن موجودة
        ByteData data = await rootBundle.load('assets/db/aac_app.db');
        List<int> bytes = data.buffer.asUint8List(
          data.offsetInBytes,
          data.lengthInBytes,
        );
        await File(path).writeAsBytes(bytes, flush: true);
        print('✅ تم نسخ قاعدة البيانات الأولية');
      } catch (e) {
        print('❌ فشل نسخ قاعدة البيانات: $e');
        // إنشاء قاعدة بيانات جديدة فارغة إذا فشل النسخ
        return await openDatabase(path);
      }
    }

    // فتح قاعدة البيانات مع تفعيل FOREIGN_KEY
    return await openDatabase(
      path,
      version: 1,
      onConfigure: (db) async {
        await db.execute('PRAGMA foreign_keys = ON');
      },
    );
  }

  Future<void> close() async {
    final db = await database;
    await db.close();
    print('🛑 تم إغلاق قاعدة البيانات');
  }
  // class DatabaseHelper {
  //   static final DatabaseHelper instance = DatabaseHelper._internal();
  //   static Database? _database;

  //   factory DatabaseHelper() => instance;

  //   DatabaseHelper._internal();

  //   Future<Database> get database async {
  //     if (_database != null) {
  //       print('✅ قاعدة البيانات مفتوحة مسبقًا');
  //       return _database!;
  //     }
  //     print('🔄 جاري تهيئة قاعدة البيانات لأول مرة');
  //     _database = await _initDatabase();
  //     return _database!;
  //   }

  //   Future<Database> _initDatabase() async {
  //     final dbPath = await getDatabasesPath();
  //     final path = join(dbPath, 'aac_app.db');

  //     final exists = await databaseExists(path);

  //     // 🟥// أثناء التطوير فقط: حذف قاعدة البيانات لإجبار إعادة نسخها من الأصول
  //     if (exists) {
  //       print('🧹 حذف قاعدة البيانات القديمة لإعادة نسخها من جديد');
  //       await deleteDatabase(path);
  //     }

  //     print('📂 جاري نسخ قاعدة البيانات من الأصول');
  //     try {
  //       ByteData data = await rootBundle.load('assets/db/aac_app.db');
  //       List<int> bytes = data.buffer.asUint8List(
  //         data.offsetInBytes,
  //         data.lengthInBytes,
  //       );
  //       await File(path).writeAsBytes(bytes, flush: true);
  //       print('✅ تم نسخ قاعدة البيانات بنجاح إلى $path');
  //     } catch (e) {
  //       print('❌ فشل نسخ قاعدة البيانات: $e');
  //     }

  //     try {
  //       final db = await openDatabase(path);
  //       print('✅ تم فتح قاعدة البيانات بنجاح');
  //       return db;
  //     } catch (e) {
  //       print('❌ فشل فتح قاعدة البيانات: $e');
  //       rethrow;
  //     }
  //   }

  //   Future<void> close() async {
  //     final db = await database;
  //     await db.close();
  //     print('🛑 تم إغلاق قاعدة البيانات');

  //   }

  Future<bool> isSpeakerCompatible(
    int? speakerId,
    String dialect,
    String gender,
    String type,
  ) async {
    if (speakerId == null) return false;

    final db = await database;
    final speaker = await db.query(
      'speakers',
      where: 'id = ? AND dialect = ? AND gender = ? AND type = ?',
      whereArgs: [speakerId, dialect, gender, type],
    );

    return speaker.isNotEmpty;
  }
  // Future<bool> isSpeakerCompatible(
  //   int? speakerId,
  //   String dialect,
  //   String gender,
  //   String type,
  // ) async {
  //   if (speakerId == null) return false;

  //   final db = await database;
  //   final speaker = await db.query(
  //     'speakers',
  //     where: 'id = ? AND dialect = ? AND gender = ? AND type = ?',
  //     whereArgs: [speakerId, dialect, gender, type],
  //   );

  // return speaker.isNotEmpty;
  // }

  Future<List<Map<String, dynamic>>> getAvailableSpeakers(
    String dialect,
    String gender,
    String type,
  ) async {
    final db = await database;

    // استعلام أكثر دقة للتأكد من توافق المتحدثين
    return await db.query(
      'speakers',
      where: 'dialect = ? AND gender = ? AND type = ?',
      whereArgs: [dialect, gender, type],
    );
  }

  Future<int> updateSelectedSpeaker(int? speakerId) async {
    final db = await database;
    return await db.update('Settings', {'speaker_id': speakerId}, where: '1=1');
  }

  Future<Map<String, dynamic>?> getSpeakerById(int? id) async {
    if (id == null) return null;

    final db = await database;
    final result = await db.query(
      'Speakers',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    return result.isNotEmpty ? result.first : null;
  }

  Future<String?> getSymbolAudioPath(int symbolId, int speakerId) async {
    final db = await database;
    final result = await db.query(
      'SymbolAudios',
      where: 'original_Id = ? AND speaker_id = ?',
      whereArgs: [symbolId, speakerId],
      limit: 1,
    );
    return result.isNotEmpty ? result.first['audio_path'] as String? : null;
  }

  Future<String?> getConjugationAudioPath(
    int conjugationId,
    int speakerId,
  ) async {
    final db = await database;
    final result = await db.query(
      'ConjugationAudios',
      where: 'conjugation_id = ? AND speaker_id = ?',
      whereArgs: [conjugationId, speakerId],
      limit: 1,
    );
    return result.isNotEmpty ? result.first['audio_path'] as String? : null;
  }

  Future<int> updateSettings(Map<String, dynamic> settings) async {
    final db = await database;
    try {
      // إضافة وقت التحديث
      settings['last_updated'] = DateTime.now().toIso8601String();

      final result = await db.update(
        'settings',
        settings,
        where: 'id = ?',
        whereArgs: [1],
      );

      debugPrint('تم تحديث الإعدادات في DB: ${settings.toString()}');
      return result;
    } catch (e) {
      debugPrint('خطأ في تحديث الإعدادات: $e');
      return 0;
    }
  }

  Future<int> insertCategory(CategoryData category) async {
    final db = await database;
    return await db.insert('Categories', {
      'id': category.id,
      'name': category.name,
      'image_path': category.imagePath,
      'is_hidden': category.isHidden ? 1 : 0,
    });
  }

  Future<List<CategoryData>> getCategories({bool showHidden = false}) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'Categories',
      where:
          showHidden
              ? 'id != 1  AND id != (0)  AND id !=12 AND id != (11)'
              : 'is_hidden = 0 AND id != (1) AND id != (0)  AND id !=12 AND id != (11)',
    );
    return maps.map((map) => CategoryData.fromMap(map)).toList();
  }

  Future<int> toggleCategoryVisibility(int id, bool hide) async {
    final db = await database;
    return await db.update(
      'Categories',
      {'is_hidden': hide ? 1 : 0},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> deleteCategory(int id) async {
    final db = await database;
    return await db.delete('Categories', where: 'id = ?', whereArgs: [id]);
  }

  // Symbol operations
  Future<int> insertSymbol(SymbolData symbol) async {
    final db = await database;
    return await db.insert('Symbols', {
      'image_path': symbol.imagePath,
      'label': symbol.label,
      'category_id': symbol.categoryId,
      'is_hidden': symbol.isHidden ? 1 : 0,
      'is_available': symbol.isAvailable ? 1 : 0,
    });
  }

  Future<List<SymbolData>> getSymbolsByCategory(
    int categoryId, {
    bool showHidden = false,
  }) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'Symbols',
      where: 'category_id = ? ${showHidden ? '' : 'AND is_hidden = 0'}',
      whereArgs: [categoryId],
    );
    return maps.map((map) => SymbolData.fromMap(map)).toList();
  }

  Future<SymbolData?> getSymbolById(int id) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'Symbols',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    return maps.isNotEmpty ? SymbolData.fromMap(maps.first) : null;
  }

  Future<bool> isOriginalSymbol(int symbolId) async {
    final db = await database;
    final maps = await db.query(
      'Symbols',
      where: 'id = ? ',
      whereArgs: [symbolId],
    );
    return maps.isNotEmpty;
  }

  Future<List<Map<String, dynamic>>> getUsers() async {
    final db = await database;
    return await db.query('users');
  }

  Future<int> insertUser(String name) async {
    final db = await database;
    try {
      // حاول التحديث أولاً
      final result = await db.update(
        'users',
        {'name': name},
        where: 'id = ?',
        whereArgs: [1],
      );

      // إذا لم يتم تحديث أي صف، قم بالإدراج
      if (result == 0) {
        return await db.insert('users', {'id': 1, 'name': name});
      }
      return result;
    } catch (e) {
      // إذا حدث خطأ، قم بالإدراج
      return await db.insert('users', {'id': 1, 'name': name});
    }
  }

  Future<Map<String, dynamic>> getUser() async {
    final db = await database;
    final users = await db.query(
      'users',
      where: 'id = ?',
      whereArgs: [1],
      limit: 1,
    );

    if (users.isEmpty) {
      return {'name': 'مستخدم'};
    }

    return users.first;
  }

  Future<int> updateUserName(String newName) async {
    final db = await database;
    return await db.update(
      'users',
      {'name': newName},
      where: 'id = ?',
      whereArgs: [1], // تأكد من وجود مستخدم بهذا ID
    );
  }

  Future<void> updateVisibility(int id, ItemType type, bool hide) async {
    final db = await database;
    await db.update(
      type == ItemType.category ? 'Categories' : 'Symbols',
      {'is_hidden': hide ? 1 : 0},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> deleteItem(int id, ItemType type) async {
    final db = await database;

    if (type == ItemType.category) {
      await db.delete('Categories', where: 'id = ?', whereArgs: [id]);
    } else {
      if (type == ItemType.symbol) {
        await db.delete('Symbols', where: 'id = ?', whereArgs: [id]);
      }
    }
  }

  // قراءة كل الرموز من جدول Symbols
  Future<List<Map<String, dynamic>>> getAllSymbols() async {
    final db = await database;
    return await db.query('Symbols');
  }

  // قراءة كل المستخدمين من جدول Users
  Future<List<Map<String, dynamic>>> getAllUsers() async {
    final db = await database;
    return await db.query('Users');
  }

  // قراءة كل الإعدادات من جدول Settings
  Future<List<Map<String, dynamic>>> getAllSettings() async {
    final db = await database;
    return await db.query('Settings');
  }

  // قراءة كل التصريفات من جدول Conjugations
  Future<List<Map<String, dynamic>>> getAllConjugations() async {
    final db = await database;
    return await db.query('Conjugations');
  }

  // قراءة كل الصوتيات من جدول Audio
  Future<List<Map<String, dynamic>>> getAllAudio() async {
    final db = await database;
    return await db.query('Audio');
  }

  // قراءة إعدادات مستخدم معين
  Future<Map<String, dynamic>?> getSettingsByUserId(int userId) async {
    final db = await database;
    final result = await db.query(
      'Settings',
      where: 'user_id = ?',
      whereArgs: [userId],
    );
    return result.isNotEmpty ? result.first : null;
  }

  Future<bool> hasUsers() async {
    final db = await database;
    final result = await db.rawQuery('SELECT COUNT(*) as count FROM users');
    return result.first['count'] as int > 0;
  }

  Future<int> createUser(String name) async {
    final db = await database;
    return await db.insert('users', {'name': name});
  }

  Future<List<SymbolData>> getSymbolsForCategory(
    int categoryId, {
    bool showHidden = false,
    required BuildContext context,
  }) async {
    final db = await database;
    final state = Provider.of<AppState>(context, listen: false);

    final where =
        showHidden ? 'category_id = ?' : 'category_id = ? AND is_hidden = 0';
    final symbols = await db.query(
      'Symbols',
      where: where,
      whereArgs: [categoryId],
      columns: [
        'id',
        'category_id',
        'original_Id',
        'label',
        'image_path',
        'is_verb',
        'is_pronoun',
        'is_hidden',
        'is_faded',
        'color',
      ],
    );

    final names = await getSymbolNamesForDialect(state.currentDialect);

    return symbols.map((map) {
      final symbol = SymbolData.fromMap(map);
      final name = names[symbol.id] ?? symbol.label;

      return symbol.copyWith(namesByDialect: {state.currentDialect: name});
    }).toList();
  }

  Future<List<SymbolData>> getMainScreenSymbols({
    bool showHidden = false,
    required BuildContext context,
  }) async {
    final db = await database;
    final state = Provider.of<AppState>(context, listen: false);

    // بناء شرط WHERE لعدة فئات
    final categoryCondition = 'category_id IN (0, 1, 11)';
    final hiddenCondition = showHidden ? '' : 'AND is_hidden = 0';
    final where = '$categoryCondition $hiddenCondition';

    final symbols = await db.query('Symbols', where: where);

    final names = await getSymbolNamesForDialect(state.currentDialect);

    return symbols.map((map) {
      final symbol = SymbolData.fromMap(map);
      return symbol.copyWith(
        namesByDialect: {
          state.currentDialect: names[symbol.originalId] ?? symbol.label,
        },
      );
    }).toList();
  }

  Future<Map<int, String>> getSymbolNamesForDialect(String dialect) async {
    final db = await database;
    final result = <int, String>{};

    // جلب كل الأسماء حسب اللهجة المطلوبة
    final names = await db.query(
      'SymbolNames',
      where: 'dialect = ?',
      whereArgs: [dialect],
    );

    // تحويل النتائج إلى خريطة: original_Id → name
    for (final name in names) {
      final originalId = name['original_Id'] as int;
      final label = name['name'] as String;
      result[originalId] = label;
    }

    return result;
  }

  // Future<String?> getSymbolAudioPath(
  //   int originalId,
  //   String dialect,
  //   String speakerType,
  //   String speakerGender,
  // ) async {
  //   final db = await database;
  //   print(speakerType);
  //   final audio = await db.query(
  //     'SymbolAudios',
  //     where: 'original_Id = ?  AND speaker_type = ? AND speaker_gender = ?',
  //     whereArgs: [originalId, speakerType, speakerGender],
  //   );

  //   return audio.isNotEmpty ? audio.first['audio_path'] as String : null;
  // }
  Future<Map<String, dynamic>> getSettings() async {
    final db = await database;
    final result = await db.query('settings');

    if (result.isEmpty) {
      return {
        'dark_mode': 'false',
        // ... القيم الافتراضية الأخرى ...
      };
    }

    // تحويل QueryRow إلى Map عادية
    return Map<String, dynamic>.from(result.first);
  }

  Future<List<SymbolData>> getConjugations(
    int originalId,
    String tense,
    String dialect,
  ) async {
    final db = await database;

    // جلب التصريفات من قاعدة البيانات
    final conjugations = await db.query(
      'Conjugations',
      where: 'original_Id = ? AND tense = ?',
      whereArgs: [originalId, tense],
    );

    if (conjugations.isEmpty) return [];

    // استخراج معرفات التصريفات
    final List<int> ids = conjugations.map((c) => c['id'] as int).toList();

    // جلب الأسماء حسب اللهجة
    final names = await db.query(
      'ConjugationNames',
      where:
          'dialect = ? AND conjugation_id IN (${List.filled(ids.length, '?').join(',')})',
      whereArgs: [dialect, ...ids],
    );

    // دمج البيانات في كائنات SymbolData
    return conjugations.map((c) {
      final id = c['id'] as int;
      final name = names.firstWhere(
        (n) => n['conjugation_id'] == id,
        orElse: () => {'name': 'تصريف'}, // قيمة افتراضية
      );

      return SymbolData(
        id: id, // استخدام ID الخاص بالتصريف
        categoryId: 0,
        originalId: originalId,
        label: name['name'] as String,
        imagePath:
            c['image_path'] as String? ?? 'assets/images/default_symbol.png',
        isVerb: true,
        isConjugation: true, // تمييز التصريف
      );
    }).toList();
  }

  // Future<String?> getConjugationAudioPath(
  //   int conjugationId,
  //   String dialect,
  //   String speakerType,
  //   String speakerGender,
  // ) async {
  //   final db = await database;

  //   final name = await db.query(
  //     'ConjugationNames',
  //     where: 'conjugation_id = ? AND dialect = ?',
  //     whereArgs: [conjugationId, dialect],
  //   );

  //   if (name.isEmpty) return null;

  //   final nameId = name.first['id'] as int;

  //   final audio = await db.query(
  //     'ConjugationAudios',
  //     where:
  //         'conjugation_name_id = ? AND speaker_type = ? AND speaker_gender = ?',
  //     whereArgs: [nameId, speakerType, speakerGender],
  //   );

  //   return audio.isNotEmpty ? audio.first['audio_path'] as String : null;
  // }

  //الة الحصول على الإعدادات
  Future<Map<String, dynamic>> getSettings22222222222222() async {
    final db = await database;
    final settings = await db.query(
      'settings',
      where: 'id = ?',
      whereArgs: [1],
      limit: 1,
    );

    return settings.first;
  }

  Future<CategoryData?> getCategoryById(String id) async {
    final db = await database;
    final maps = await db.query(
      'categories',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );

    if (maps.isNotEmpty) {
      return CategoryData.fromMap(maps.first);
    }
    return null;
  }

  // دالة للاشتراك في تغييرات الإعدادات
  Stream<Map<String, dynamic>> watchSettings() async* {
    final db = await database;
    final settings = await db.query('settings');
    yield settings.isNotEmpty ? Map<String, dynamic>.from(settings.first) : {};
  }

  Future<String> getSymbolName(int symbolId, String dialect) async {
    final db = await database;

    final names = await db.query(
      'SymbolNames',
      where: 'original_Id = ? AND dialect = ?',
      whereArgs: [symbolId, dialect],
      limit: 1,
    );

    if (names.isNotEmpty) {
      return names.first['name'] as String;
    }

    // في حال لم يوجد اسم للهجة المحددة، يرجع الاسم الأساسي
    final symbols = await db.query(
      'Symbols',
      where: 'id = ?',
      whereArgs: [symbolId],
      columns: ['label'],
      limit: 1,
    );

    return symbols.isNotEmpty ? symbols.first['label'] as String : 'غير معروف';
  }

  // جلب مستخدم أول (لاختباره افتراضياً)
  Future<Map<String, dynamic>?> getFirstUser() async {
    final db = await database;
    final result = await db.query('Users', limit: 1);
    return result.isNotEmpty ? result.first : null;
  }

  // جلب إعدادات أول مستخدم
  Future<Map<String, dynamic>?> getFirstUserSettings() async {
    final user = await getFirstUser();
    if (user != null) {
      return await getSettingsByUserId(user['id']);
    }
    return null;
  }

  Future<int> copySymbolToCategory(
    int symbolIdToCopy,
    int targetCategoryId,
  ) async {
    final db = await database;

    // 1. جلب العنصر المطلوب نسخه
    final symbolToCopy = await db.query(
      'Symbols',
      where: 'id = ?',
      whereArgs: [symbolIdToCopy],
    );

    if (symbolToCopy.isEmpty) {
      throw Exception('العنصر المطلوب غير موجود');
    }

    final original = symbolToCopy.first;

    // 2. إنشاء النسخة الجديدة بنفس البيانات
    final newSymbolId = await db.insert('Symbols', {
      'category_id': targetCategoryId,
      'original_Id': original['original_Id'],
      'label': original['label'],
      'image_path': original['image_path'],
      'is_verb': original['is_verb'],
      'is_pronoun': original['is_pronoun'],
      'is_hidden': original['is_hidden'],
      'is_faded': original['is_faded'],
      'color': original['color'], // 🟦 إضافة اللون هنا
    });

    return newSymbolId;
  }

  // إدخال إعدادات جديدة
  Future<int> insertSettings(Map<String, dynamic> settings) async {
    final db = await database;
    return await db.insert('Settings', settings);
  }

  Future<List<Map<String, dynamic>>> ForCategory(int categoryId) async {
    final db = await database;

    // جلب الرموز الأصلية المرتبطة بالفئة
    final symbols = await db.query(
      'symbols',
      where: 'category_id = ?',
      whereArgs: [categoryId],
    );

    // جلب الرموز المنسوخة من جدول copy
    final copiedSymbols = await db.query(
      'copy',
      where: 'category_id = ?',
      whereArgs: [categoryId],
    );

    // دمج الرمزين في قائمة واحدة
    return [...symbols, ...copiedSymbols];
  }

  Future<String?> getSymbolNameByDialect(int symbolId, String dialect) async {
    final db = await instance.database;
    final result = await db.query(
      'SymbolNames',
      where: 'symbol_id = ? AND dialect = ?',
      whereArgs: [symbolId, dialect],
    );
    return result.isNotEmpty ? result.first['name'] as String? : null;
  }

  // دالة لجلب الفئات مع خيار عرض المخفية
  Future<List<CategoryData>> getAllCategories({bool showHidden = false}) async {
    final db = await instance.database;
    final where = showHidden ? null : 'is_hidden = 0';
    final result = await db.query('categories', where: where);
    return result
        .map(
          (e) => CategoryData(
            id: e['id'] as int,
            name: e['name']?.toString() ?? '', // 👈 يقبل null ويعطي ""
            imagePath:
                e['image_path']?.toString() ?? '', // 👈 يقبل null ويعطي ""
            isHidden: e['is_hidden'] == 1,
          ),
        )
        .toList();
  }

  // // دالة لجلب الرموز حسب معرفاتها

  Future<List<SymbolData>> getSymbolsByIds(List<int> ids) async {
    final db = await this.database;

    if (ids.isEmpty) return []; // تجنب استعلام فارغ

    // تحويل القائمة إلى نص متوافق مع SQL (مثل "3, 5, 7")
    final idsPlaceholder = ids.join(', ');

    final List<Map<String, dynamic>> maps = await db.rawQuery(
      'SELECT * FROM symbols WHERE id IN ($idsPlaceholder)',
    );

    return maps.map((map) => SymbolData.fromMap(map)).toList();
  }

  Future<void> toggleItemVisibility(int id, bool hide) async {
    final db = await database;
    await db.update(
      'symbols',
      {'is_hidden': hide ? 1 : 0},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // دالة جديدة للحصول على الرموز المكررة
  Future<List<SymbolData>> getDuplicateSymbols(String imagePath) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'symbols',
      where: 'image_path = ?',
      whereArgs: [imagePath],
    );
    return maps.map((map) => SymbolData.fromMap(map)).toList();
  }

  Future<List<SymbolData>> getSymbolsByOriginalId(int originalId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'symbols',
      where: 'original_id = ? OR id = ?',
      whereArgs: [originalId, originalId],
    );
    return maps.map((map) => SymbolData.fromMap(map)).toList();
  }

  Future<int> toggleSymbolVisibility(int id, bool hide) async {
    final db = await database;
    return await db.update(
      'symbols',
      {'is_hidden': hide ? 1 : 0},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> deleteSymbol(int id) async {
    final db = await database;
    return await db.delete('symbols', where: 'id = ?', whereArgs: [id]);
  }

  Future<int> copySymbol(SymbolData original, int targetCategoryId) async {
    final db = await database;
    return await db.insert('Symbols', {
      'image_path': original.imagePath,
      'label': original.label,
      'category_id': targetCategoryId,
      'is_hidden': original.isHidden ? 1 : 0,
    });
  }

  Future<int> updateTenseSetting(String tense) async {
    final db = await database;
    return await db.update(
      'Settings',
      {'value': tense},
      where: 'key = ?',
      whereArgs: ['tense'],
    );
  }
}
