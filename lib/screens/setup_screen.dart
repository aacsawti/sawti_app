import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../database_helper.dart';
import '../app_state.dart';

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
              'اللهجة المصرية',
              'Egyptian',
              Icons.language,
              Colors.green,
            ),
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

      await dbHelper.insertUser(_nameController.text);
      await dbHelper.updateSettings({
        'dialect': _selectedDialect,
        'user_level': _selectedLevel,
      });

      final appState = Provider.of<AppState>(context, listen: false);
      await appState.loadUserAndSettings();

      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const MainScaffold()),
      );
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }
}