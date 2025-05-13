import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../providers/auth_provider.dart';
import '../../models/user.dart'; // Assuming User model exists
import '../../services/api_service.dart'; // Assuming ApiService exists

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('设置'),
      ),
      body: Column(
        children: [
          TabBar(
            controller: _tabController,
            tabs: const [
              Tab(text: '个人资料'),
              Tab(text: '账户设置'),
              Tab(text: '外观设置'),
              Tab(text: '语言设置'),
            ],
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                const PersonalInfoTab(),
                // Placeholder for other tabs
                _buildPlaceholderTab('账户设置'),
                _buildPlaceholderTab('外观设置'),
                _buildPlaceholderTab('语言设置'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlaceholderTab(String title) {
    if (title == '账户设置') {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 200,
              child: ElevatedButton(
                onPressed: () {
                  final authProvider = Provider.of<AuthProvider>(context, listen: false);
                  authProvider.logout();
                  GoRouter.of(context).go('/login');
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                ),
                child: const Text('退出登录'),
              ),
            ),
          ],
        ),
      );
    }
    return Center(
      child: Text('$title 内容加载中...'),
    );
  }
}

// Personal Info Tab Widget
class PersonalInfoTab extends StatefulWidget {
  const PersonalInfoTab({super.key});

  @override
  State<PersonalInfoTab> createState() => _PersonalInfoTabState();
}

class _PersonalInfoTabState extends State<PersonalInfoTab> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  User? _currentUser;

  // Controllers for form fields
  late TextEditingController _usernameController;
  late TextEditingController _emailController;
  late TextEditingController _fullNameController;
  late TextEditingController _phoneController;

  @override
  void initState() {
    super.initState();
    _usernameController = TextEditingController();
    _emailController = TextEditingController();
    _fullNameController = TextEditingController();
    _phoneController = TextEditingController();
    _loadUserData();
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _emailController.dispose();
    _fullNameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _loadUserData() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    if (authProvider.isLoggedIn && authProvider.user != null) {
      setState(() {
        _currentUser = authProvider.user;
        _usernameController.text = _currentUser!.username;
        _emailController.text = _currentUser!.email;
        _fullNameController.text = _currentUser!.username ?? '';
      });
    } else {
      // Handle case where user data is not available (should not happen if routed correctly)
    }
  }

  Future<void> _updateProfile() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      // No need to check _currentUser here as AuthProvider handles the logged-in state

      try {
        // Prepare updated data map
        Map<String, dynamic> updatedData = {
          // Only include fields that might change
          'fullName': _fullNameController.text,
          'phone': _phoneController.text,
          // Add other fields if they are editable
          // Ensure email and username are not sent if they are not meant to be updated
        };

        // Call AuthProvider to update user profile
        final success = await authProvider.updateUserProfile(updatedData);

        setState(() {
          _isLoading = false;
        });

        if (success) {
          // Reload data from provider after successful update
          _loadUserData(); 
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('个人资料更新成功')),
          );
        } else {
          // Error message is handled by AuthProvider, show generic message or provider's message
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('更新失败: ${authProvider.errorMessage ?? '未知错误'}')),
          );
        }

      } catch (e) { // Catch potential errors during the process (less likely now with provider handling)
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('更新时发生错误: ${e.toString()}')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_currentUser == null) {
      return const Center(child: CircularProgressIndicator()); // Or a message
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 40,
                  // Placeholder for avatar - replace with actual image loading
                  child: Text(_currentUser!.username.isNotEmpty ? _currentUser!.username[0].toUpperCase() : '?'),
                ),
                const SizedBox(width: 16),
                TextButton.icon(
                  icon: const Icon(Icons.upload_file_outlined, size: 16),
                  label: const Text('上传头像'),
                  onPressed: () {
                    // Placeholder for avatar upload logic
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('上传头像功能待实现')),
                    );
                  },
                ),
              ],
            ),
            const SizedBox(height: 32),
            TextFormField(
              controller: _usernameController,
              decoration: const InputDecoration(
                labelText: '用户名 *',
                prefixIcon: Icon(Icons.person_outline),
                border: OutlineInputBorder(),
              ),
              readOnly: true, // Username might not be editable
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return '请输入用户名';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _emailController,
              decoration: const InputDecoration(
                labelText: '邮箱 *',
                prefixIcon: Icon(Icons.email_outlined),
                border: OutlineInputBorder(),
              ),
              readOnly: true, // Email might not be editable
              validator: (value) {
                if (value == null || value.isEmpty || !value.contains('@')) {
                  return '请输入有效的邮箱地址';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _fullNameController,
              decoration: const InputDecoration(
                labelText: '姓名',
                prefixIcon: Icon(Icons.badge_outlined),
                border: OutlineInputBorder(),
              ),
              // Add validator if needed
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _phoneController,
              decoration: const InputDecoration(
                labelText: '电话',
                prefixIcon: Icon(Icons.phone_outlined),
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.phone,
              // Add validator if needed
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _updateProfile,
                style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
                child: _isLoading
                    ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Text('保存修改'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}