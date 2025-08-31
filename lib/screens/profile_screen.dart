import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:ui' as ui;
import '../app_state.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> with WidgetsBindingObserver {
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