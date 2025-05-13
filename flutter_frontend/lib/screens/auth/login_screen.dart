import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import 'package:go_router/go_router.dart'; // Import GoRouter

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (_formKey.currentState!.validate()) {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final success = await authProvider.login(
        _usernameController.text,
        _passwordController.text,
      );

      if (success && mounted) {
        // Navigate to dashboard or home on successful login
        // GoRouter will handle the redirect based on auth state
      } else if (mounted) {
        // Show error message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(authProvider.errorMessage ?? 'Login failed')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    
    // 获取屏幕尺寸和方向
    final screenSize = MediaQuery.of(context).size;
    final isLandscape = screenSize.width > screenSize.height;
    final isSmallScreen = screenSize.width < 600;
    
    return Scaffold(
      appBar: AppBar(title: const Text('登录')),
      body: LayoutBuilder(
        builder: (context, constraints) {
          // 根据屏幕方向调整布局
          if (isLandscape && !isSmallScreen) {
            // 横屏模式下的布局
            return Row(
              children: [
                // 左侧可以放置图片或标志
                Expanded(
                  flex: 1,
                  child: Container(
                    color: Theme.of(context).colorScheme.primaryContainer.withOpacity(0.3),
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.health_and_safety,
                            size: constraints.maxWidth * 0.1,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            '健康顾问',
                            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                              color: Theme.of(context).colorScheme.primary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                // 右侧登录表单
                Expanded(
                  flex: 1,
                  child: _buildLoginForm(authProvider, constraints),
                ),
              ],
            );
          } else {
            // 竖屏模式下的布局
            return SingleChildScrollView(
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: isSmallScreen ? 16.0 : constraints.maxWidth * 0.1,
                  vertical: 16.0,
                ),
                child: _buildLoginForm(authProvider, constraints),
              ),
            );
          }
        },
      ),
    );
  }
  
  // 提取登录表单为单独的方法，便于复用
  Widget _buildLoginForm(AuthProvider authProvider, BoxConstraints constraints) {
    final isSmallScreen = constraints.maxWidth < 600;
    
    return Form(
      key: _formKey,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          // 在小屏幕竖屏模式下显示图标和标题
          if (isSmallScreen || constraints.maxHeight > constraints.maxWidth)
            Column(
              children: [
                Icon(
                  Icons.health_and_safety,
                  size: constraints.maxWidth * 0.15,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(height: 16),
                Text(
                  '健康顾问',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    color: Theme.of(context).colorScheme.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 32),
              ],
            ),
          
          TextFormField(
            controller: _usernameController,
            decoration: InputDecoration(
              labelText: '用户名',
              prefixIcon: const Icon(Icons.person),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8.0),
              ),
              contentPadding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 16.0),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return '请输入用户名';
              }
              return null;
            },
          ),
          SizedBox(height: isSmallScreen ? 16 : 24),
          TextFormField(
            controller: _passwordController,
            decoration: InputDecoration(
              labelText: '密码',
              prefixIcon: const Icon(Icons.lock),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8.0),
              ),
              contentPadding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 16.0),
            ),
            obscureText: true,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return '请输入密码';
              }
              return null;
            },
          ),
          SizedBox(height: isSmallScreen ? 24 : 32),
          authProvider.isLoading
              ? const Center(child: CircularProgressIndicator())
              : SizedBox(
                  height: 48,
                  child: ElevatedButton(
                    onPressed: _login,
                    style: ElevatedButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                    ),
                    child: const Text('登录', style: TextStyle(fontSize: 16)),
                  ),
                ),
          const SizedBox(height: 16),
          TextButton(
            onPressed: () {
              // Navigate to Register screen
              context.go('/register'); // Use GoRouter for navigation
            },
            child: const Text('没有账号？点击注册'),
          ),
        ],
      ),
    );
  }
}