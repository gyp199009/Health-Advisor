import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'dart:math' as math;
import '../../providers/auth_provider.dart';
import '../../models/conversation.dart'; // Assuming Conversation model exists
import '../../models/record.dart'; // Assuming Record model exists
import '../../services/api_service.dart'; // Assuming ApiService exists
import '../records/record_upload_dialog.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _recordCount = 0;
  int _conversationCount = 0;
  List<Record> _recentRecords = [];
  List<Conversation> _recentConversations = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchDashboardData();
  }

  Future<void> _fetchDashboardData() async {
    if (!mounted) return;
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    if (!authProvider.isLoggedIn || authProvider.user == null) {
      setState(() {
        _isLoading = false;
        _errorMessage = '用户未登录';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final userId = authProvider.user!.id;
      // Fetch record count and recent records
      final recordsResponse = await ApiService.getRecords(userId);
      final List<dynamic> recordsJson = recordsResponse['records'] ?? [];
      _recordCount = recordsResponse['totalCount'] ?? recordsJson.length; // Assuming totalCount exists
      _recentRecords = recordsJson.map((json) => Record.fromJson(json)).toList();

      // Fetch conversation count and recent conversations
      final conversationsResponse = await ApiService.getConversations(userId);
      final List<dynamic> conversationsJson = conversationsResponse['conversations'] ?? [];
      _conversationCount = conversationsResponse['totalCount'] ?? conversationsJson.length; // Assuming totalCount exists
      _recentConversations = conversationsJson.map((json) => Conversation.fromJson(json)).toList();

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = '加载数据失败: ${e.toString()}';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final username = authProvider.user?.username ?? '用户';

    // AppBar is now handled by MainLayout
    return Scaffold(
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? Center(child: Text(_errorMessage!, style: const TextStyle(color: Colors.red)))
              : _buildDashboardContent(context, username),
    );
  }

  Widget _buildDashboardContent(BuildContext context, String username) {
    // 获取屏幕尺寸和方向
    final screenSize = MediaQuery.of(context).size;
    final isSmallScreen = screenSize.width < 600;
    final isLandscape = screenSize.width > screenSize.height;
    
    // 根据屏幕大小调整内边距
    final horizontalPadding = isSmallScreen ? 12.0 : 16.0;
    final verticalPadding = isSmallScreen ? 12.0 : 16.0;
    
    return ListView(
      padding: EdgeInsets.symmetric(horizontal: horizontalPadding, vertical: verticalPadding),
      children: [
        Text('欢迎, $username', 
          style: isSmallScreen 
            ? Theme.of(context).textTheme.titleLarge 
            : Theme.of(context).textTheme.headlineSmall),
        SizedBox(height: isSmallScreen ? 4 : 8),
        Text(
          '这是您的健康管理仪表盘，您可以在这里查看健康数据概览和使用相关功能。',
          style: TextStyle(fontSize: isSmallScreen ? 14 : 16),
        ),
        SizedBox(height: isSmallScreen ? 16 : 24),
        _buildSummaryCards(context),
        SizedBox(height: isSmallScreen ? 16 : 24),
        _buildQuickActions(context),
        SizedBox(height: isSmallScreen ? 16 : 24),
        _buildRecentLists(context),
      ],
    );
  }

  Widget _buildSummaryCards(BuildContext context) {
    // 获取屏幕尺寸
    final screenSize = MediaQuery.of(context).size;
    final isSmallScreen = screenSize.width < 600;
    final isVerySmallScreen = screenSize.width < 360; // 非常小的屏幕
    
    // 在非常小的屏幕上使用Column布局，否则使用Row布局
    return isVerySmallScreen
        ? Column(
            children: [
              _buildSummaryCard(context, '病历记录', _recordCount.toString(), Icons.folder_shared, Colors.orange, () => context.go('/records')),
              const SizedBox(height: 8),
              _buildSummaryCard(context, '健康咨询', _conversationCount.toString(), Icons.chat_bubble, Colors.blue, () => context.go('/chat')),
              const SizedBox(height: 8),
              _buildSummaryCard(context, '健康数据', '查看', Icons.monitor_heart, Colors.green, () => {}),
            ],
          )
        : Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildSummaryCard(context, '病历记录', _recordCount.toString(), Icons.folder_shared, Colors.orange, () => context.go('/records')),
              _buildSummaryCard(context, '健康咨询', _conversationCount.toString(), Icons.chat_bubble, Colors.blue, () => context.go('/chat')),
              _buildSummaryCard(context, '健康数据', '查看', Icons.monitor_heart, Colors.green, () => {}),
            ],
          );
  }

  Widget _buildSummaryCard(BuildContext context, String title, String value, IconData icon, Color color, VoidCallback onTap) {
    // 获取屏幕尺寸
    final screenSize = MediaQuery.of(context).size;
    final isSmallScreen = screenSize.width < 600;
    final isVerySmallScreen = screenSize.width < 360;
    
    // 根据屏幕大小调整内边距和图标大小
    final padding = isSmallScreen ? 12.0 : 16.0;
    final iconSize = isSmallScreen ? 28.0 : 32.0;
    
    return isVerySmallScreen
        ? Card(
            elevation: 2.0,
            child: InkWell(
              onTap: onTap,
              child: Padding(
                padding: EdgeInsets.all(padding),
                child: Column(
                  children: [
                    Icon(icon, size: iconSize, color: color),
                    SizedBox(height: isSmallScreen ? 6 : 8),
                    Text(title, style: Theme.of(context).textTheme.bodySmall),
                    SizedBox(height: isSmallScreen ? 2 : 4),
                    Text(value, 
                      style: isSmallScreen
                        ? Theme.of(context).textTheme.titleLarge?.copyWith(color: color)
                        : Theme.of(context).textTheme.headlineMedium?.copyWith(color: color)),
                    SizedBox(height: isSmallScreen ? 2 : 4),
                    Text(
                      title == '健康数据' ? '即将推出' : (title == '病历记录' ? '查看全部' : '开始咨询'), 
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(color: Colors.blue)
                    ),
                  ],
                ),
              ),
            ),
          )
        : Expanded(
            child: Card(
              elevation: 2.0,
              child: InkWell(
                onTap: onTap,
                child: Padding(
                  padding: EdgeInsets.all(padding),
                  child: Column(
                    children: [
                      Icon(icon, size: iconSize, color: color),
                      SizedBox(height: isSmallScreen ? 6 : 8),
                      Text(title, style: Theme.of(context).textTheme.bodySmall),
                      SizedBox(height: isSmallScreen ? 2 : 4),
                      Text(value, 
                        style: isSmallScreen
                          ? Theme.of(context).textTheme.titleLarge?.copyWith(color: color)
                          : Theme.of(context).textTheme.headlineMedium?.copyWith(color: color)),
                      SizedBox(height: isSmallScreen ? 2 : 4),
                      Text(
                        title == '健康数据' ? '即将推出' : (title == '病历记录' ? '查看全部' : '开始咨询'), 
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(color: Colors.blue)
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
  }

  Widget _buildQuickActions(BuildContext context) {
    // 获取屏幕尺寸
    final screenSize = MediaQuery.of(context).size;
    final isSmallScreen = screenSize.width < 600;
    final isVerySmallScreen = screenSize.width < 360;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('快速操作', 
          style: isSmallScreen 
            ? Theme.of(context).textTheme.titleSmall 
            : Theme.of(context).textTheme.titleMedium),
        SizedBox(height: isSmallScreen ? 12 : 16),
        isVerySmallScreen
            ? Column(
                children: [
                  _buildActionButton(
                    context,
                    icon: Icons.chat_outlined,
                    label: '开始咨询',
                    onPressed: () => context.go('/chat'),
                  ),
                  const SizedBox(height: 8),
                  _buildActionButton(
                    context,
                    icon: Icons.upload_file_outlined,
                    label: '上传病历',
                    onPressed: () async {
                      final bool? result = await showDialog<bool>(
                        context: context,
                        builder: (context) => const RecordUploadDialog(),
                      );
                      if (result == true) {
                        await _fetchDashboardData();
                      }
                    },
                  ),
                ],
              )
            : Row(
                children: [
                  Expanded(
                    child: _buildActionButton(
                      context,
                      icon: Icons.chat_outlined,
                      label: '开始咨询',
                      onPressed: () => context.go('/chat'),
                    ),
                  ),
                  SizedBox(width: isSmallScreen ? 12 : 16),
                  Expanded(
                    child: _buildActionButton(
                      context,
                      icon: Icons.upload_file_outlined,
                      label: '上传病历',
                      onPressed: () async {
                        final bool? result = await showDialog<bool>(
                          context: context,
                          builder: (context) => const RecordUploadDialog(),
                        );
                        if (result == true) {
                          await _fetchDashboardData();
                        }
                      },
                    ),
                  ),
                ],
              ),
      ],
    );
  }
  
  // 提取按钮创建逻辑为单独的方法
  Widget _buildActionButton(BuildContext context, {required IconData icon, required String label, required VoidCallback onPressed}) {
    final screenSize = MediaQuery.of(context).size;
    final isSmallScreen = screenSize.width < 600;
    
    return ElevatedButton.icon(
      icon: Icon(icon, size: isSmallScreen ? 18 : 24),
      label: Text(label, style: TextStyle(fontSize: isSmallScreen ? 14 : 16)),
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(padding: EdgeInsets.symmetric(vertical: isSmallScreen ? 8 : 12)),
    );
  }


  Widget _buildRecentLists(BuildContext context) {
    // 获取屏幕尺寸
    final screenSize = MediaQuery.of(context).size;
    final isSmallScreen = screenSize.width < 600;
    
    // 在小屏幕上使用Column布局，在大屏幕上使用Row布局
    return isSmallScreen
        ? Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildRecentListCard(
                context,
                '最近病历记录',
                _recentRecords,
                (record) => ListTile(
                  dense: true,
                  title: Text(record.description ?? record.recordType, maxLines: 1, overflow: TextOverflow.ellipsis),
                  subtitle: Text(_formatDate(record.uploadDate) ?? 'N/A'),
                  trailing: TextButton(child: const Text('查看'), onPressed: () => context.go('/records/${record.id}')),
                ),
                () => context.go('/records'),
              ),
              const SizedBox(height: 16),
              _buildRecentListCard(
                context,
                '最近健康咨询',
                _recentConversations,
                (conv) => ListTile(
                  dense: true,
                  title: Text(conv.title ?? '新对话', maxLines: 1, overflow: TextOverflow.ellipsis),
                  subtitle: Text('更新于: ${_formatDate(conv.lastUpdated) ?? 'N/A'}'),
                  trailing: TextButton(child: const Text('继续'), onPressed: () => context.go('/chat/${conv.id}')),
                ),
                () => context.go('/chat'),
              ),
            ],
          )
        : Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _buildRecentListCard(
                  context,
                  '最近病历记录',
                  _recentRecords,
                  (record) => ListTile(
                    dense: true,
                    title: Text(record.description ?? record.recordType, maxLines: 1, overflow: TextOverflow.ellipsis),
                    subtitle: Text(_formatDate(record.uploadDate) ?? 'N/A'),
                    trailing: TextButton(child: const Text('查看'), onPressed: () => context.go('/records/${record.id}')),
                  ),
                  () => context.go('/records'),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildRecentListCard(
                  context,
                  '最近健康咨询',
                  _recentConversations,
                  (conv) => ListTile(
                    dense: true,
                    title: Text(conv.title ?? '新对话', maxLines: 1, overflow: TextOverflow.ellipsis),
                    subtitle: Text('更新于: ${_formatDate(conv.lastUpdated) ?? 'N/A'}'),
                    trailing: TextButton(child: const Text('继续'), onPressed: () => context.go('/chat/${conv.id}')),
                  ),
                  () => context.go('/chat'),
                ),
              ),
            ],
          );
  }

  Widget _buildRecentListCard<T>(BuildContext context, String title, List<T> items, Widget Function(T item) itemBuilder, VoidCallback onViewAll) {
    // 获取屏幕尺寸
    final screenSize = MediaQuery.of(context).size;
    final isSmallScreen = screenSize.width < 600;
    
    // 根据屏幕大小调整内边距
    final padding = isSmallScreen ? 8.0 : 12.0;
    
    return Card(
      elevation: 1.0,
      child: Padding(
        padding: EdgeInsets.all(padding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(title, 
                  style: isSmallScreen 
                    ? Theme.of(context).textTheme.labelLarge 
                    : Theme.of(context).textTheme.titleSmall),
                TextButton(
                  onPressed: onViewAll, 
                  child: Text('查看全部', style: TextStyle(fontSize: isSmallScreen ? 12 : 14)),
                  style: TextButton.styleFrom(padding: EdgeInsets.symmetric(horizontal: isSmallScreen ? 8 : 12)),
                ),
              ],
            ),
            const Divider(),
            if (items.isEmpty)
              Padding(
                padding: EdgeInsets.symmetric(vertical: isSmallScreen ? 12.0 : 16.0),
                child: const Center(child: Text('暂无记录')),
              )
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                // 在小屏幕上限制显示的项目数量
                itemCount: isSmallScreen ? math.min(3, items.length) : items.length,
                itemBuilder: (context, index) => itemBuilder(items[index]),
              ),
          ],
        ),
      ),
    );
  }

  String? _formatDate(DateTime? date) {
    if (date == null) return null;
    // Simple date formatting, consider using the intl package for better formatting
    return '${date.year}/${date.month.toString().padLeft(2, '0')}/${date.day.toString().padLeft(2, '0')} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }
}
