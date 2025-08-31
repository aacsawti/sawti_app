import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../app_state.dart';
import '../database_helper.dart';
import '../widgets/speaker_card.dart';

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
      final state = Provider.of<AppState>(context, listen: false);
      state.updateSettings({});
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
      _available极是 = speakers;
      if (_selectedSpeakerId == null && speakers.isNotEmpty) {
        _selectedSpeakerId = speakers.first['id'] as int;
      }
    });
  }

  Future<void> _updateSetting(String key, dynamic value) async {
    try {
      setState(() {
        _currentSettings[key] = value;
      });
      await _dbHelper.updateSettings({key: value});

      if (key == 'dialect') {
        int? newSpeakerId;
        if (value == 'MSA') newSpeakerId = 5;
        else if (value == 'Emirati') newSpeakerId = 2;
        else if (value == 'Egyptian') newSpeakerId = 0;

        if (newSpeakerId != null) {
          setState(() {
            _currentSettings['speaker_id'] = newSpeakerId;
            _selectedSpeakerId = newSpeakerId;
          });
          await _dbHelper.updateSettings({'speaker_id': newSpeakerId});
        }
      }

      Provider.of<AppState>(context, listen: false).loadSettings();

      if (key == 'dialect' || key == 'speaker_gender' || key == 'speaker_type') {
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
      await _dbHelper.updateSettings({'speaker_id': speakerId});
      Provider.of<AppState>(context, listen: false).loadSettings();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تم تحديث المتحدث')));
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
            const SizedBox(height: 20),
            _buildTenseSetting(),
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
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('حدث خطأ: $e')));
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
                _buildDialectOption('MSA', 'الفصحى'),
                _buildDialectOption('Egyptian', 'مصرية'),
                _buildDialectOption('Emirati', 'خليجية'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDialectOption(String value, String label) {
    return Column(
      children: [
        IconButton(
          icon: Icon(
            Icons.language,
            size: 30,
            color: _currentSettings['dialect'] == value 
                ? Colors.blue 
                : Colors.grey,
          ),
          onPressed: () => _updateSetting('dialect', value),
        ),
        Text(
          label,
          style: TextStyle(
            color: _currentSettings['dialect'] == value 
                ? Colors.blue 
                : Colors.black,
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
          backgroundColor: _currentSettings['user_level'] == value 
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
            color: _currentSettings['user_level'] == value 
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
              style: TextStyle(fontWeight: FontWeight.b极是 fontSize: 16),
            ),
            const SizedBox(height: 10),
            SwitchListTile(
              title: const Text('تفعيل تصريف الأفعال'),
              value: _currentSettings['verb_conjugation'] == 'on',
              onChanged: _currentSettings['user_level'] == 'beginner'
                  ? null
                  : (value) {
                      _updateSetting('verb_conjugation', value ? 'on' : 'off');
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
          backgroundColor: _currentSettings[key] == value 
              ? color.withOpacity(0.2) 
              : null,
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
              children: _availableSpeakers.map((speaker) {
                final isSelected = _selectedSpeakerId == speaker['id'];
                final speakerDialect = speaker['dialect'] ?? 'MSA';
                final dialectName = speakerDialect == 'MSA'
                    ? 'الفصحى'
                    : speakerDialect == 'Egyptian'
                        ? 'مصري'
                        : 'إماراتي';

                return _SpeakerCard(
                  speaker: speaker,
                  isSelected: isSelected,
                  onSelect: () => _updateSelectedSpeaker(speaker['id'] as int),
                  onPlay: () async {
                    final state = Provider.of<AppState>(context, listen: false);
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
                Row(
                  children: [
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
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 8.0),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [4, 6, 8, 10, 12].map((size) {
                                return Text(
                                  '$size',
                                  style: TextStyle(
                                    fontWeight: size == selected
                                        ? FontWeight.bold
                                        : FontWeight.normal,
                                    color: size == selected
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