// Category Model
class Category {
  final int? id;
  final String name;
  final String? iconPath;
  final String? color;

  Category({this.id, required this.name, this.iconPath, this.color});

  factory Category.fromMap(Map<String, dynamic> map) {
    return Category(
      id: map['id'],
      name: map['name'],
      iconPath: map['icon_path'],
      color: map['color'],
    );
  }

  Map<String, dynamic> toMap() {
    return {'id': id, 'name': name, 'icon_path': iconPath, 'color': color};
  }
}

// Symbol Model
class SymbolModel {
  final int? id;
  final int? categoryId;
  final String label;
  final String? rootVerb;
  final String? iconPath;
  final bool isVerb;
  final bool isPronoun;
  final bool isHidden;
  final bool isFaded;

  SymbolModel({
    this.id,
    this.categoryId,
    required this.label,
    this.rootVerb,
    this.iconPath,
    this.isVerb = false,
    this.isPronoun = false,
    this.isHidden = false,
    this.isFaded = false,
  });

  factory SymbolModel.fromMap(Map<String, dynamic> map) {
    return SymbolModel(
      id: map['id'],
      categoryId: map['category_id'],
      label: map['label'],
      rootVerb: map['root_verb'],
      iconPath: map['icon_path'],
      isVerb: map['is_verb'] == 1,
      isPronoun: map['is_pronoun'] == 1,
      isHidden: map['is_hidden'] == 1,
      isFaded: map['is_faded'] == 1,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'category_id': categoryId,
      'label': label,
      'root_verb': rootVerb,
      'icon_path': iconPath,
      'is_verb': isVerb ? 1 : 0,
      'is_pronoun': isPronoun ? 1 : 0,
      'is_hidden': isHidden ? 1 : 0,
      'is_faded': isFaded ? 1 : 0,
    };
  }
}

// User Model
class User {
  final int? id;
  final String? name;
  final String? preferredDialect;
  final String? speakerType;
  final String? userLevel;
  final int? gridSize;

  User({
    this.id,
    this.name,
    this.preferredDialect,
    this.speakerType,
    this.userLevel,
    this.gridSize,
  });

  factory User.fromMap(Map<String, dynamic> map) {
    return User(
      id: map['id'],
      name: map['name'],
      preferredDialect: map['preferred_dialect'],
      speakerType: map['speaker_type'],
      userLevel: map['user_level'],
      gridSize: map['grid_size'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'preferred_dialect': preferredDialect,
      'speaker_type': speakerType,
      'user_level': userLevel,
      'grid_size': gridSize,
    };
  }
}

// Settings Model
class Settings {
  final int? id;
  final int userId;
  final bool conjugationMode;
  final bool smartGrammarAudio;

  Settings({
    this.id,
    required this.userId,
    required this.conjugationMode,
    required this.smartGrammarAudio,
  });

  factory Settings.fromMap(Map<String, dynamic> map) {
    return Settings(
      id: map['id'],
      userId: map['user_id'],
      conjugationMode: map['conjugation_mode'] == 1,
      smartGrammarAudio: map['smart_grammar_audio'] == 1,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'user_id': userId,
      'conjugation_mode': conjugationMode ? 1 : 0,
      'smart_grammar_audio': smartGrammarAudio ? 1 : 0,
    };
  }
}

// Conjugation Model
class Conjugation {
  final int? id;
  final int symbolId;
  final String pronoun;
  final String tense;
  final String form;

  Conjugation({
    this.id,
    required this.symbolId,
    required this.pronoun,
    required this.tense,
    required this.form,
  });

  factory Conjugation.fromMap(Map<String, dynamic> map) {
    return Conjugation(
      id: map['id'],
      symbolId: map['symbol_id'],
      pronoun: map['pronoun'],
      tense: map['tense'],
      form: map['form'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'symbol_id': symbolId,
      'pronoun': pronoun,
      'tense': tense,
      'form': form,
    };
  }
}

// Audio Model
class AudioModel {
  final int? id;
  final int? symbolId;
  final int? conjugationId;
  final String dialect;
  final String speakerType;
  final String filePath;

  AudioModel({
    this.id,
    this.symbolId,
    this.conjugationId,
    required this.dialect,
    required this.speakerType,
    required this.filePath,
  });

  factory AudioModel.fromMap(Map<String, dynamic> map) {
    return AudioModel(
      id: map['id'],
      symbolId: map['symbol_id'],
      conjugationId: map['conjugation_id'],
      dialect: map['dialect'],
      speakerType: map['speaker_type'],
      filePath: map['file_path'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'symbol_id': symbolId,
      'conjugation_id': conjugationId,
      'dialect': dialect,
      'speaker_type': speakerType,
      'file_path': filePath,
    };
  }
}
