import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../models/conversation.dart';
import '../../providers/auth_provider.dart';
import '../../services/api_service.dart';
import '../../utils/datetime_utils.dart';

class ChatListScreen extends StatefulWidget {
  const ChatListScreen({super.key});

  @override
  State<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends State<ChatListScreen> {
  List<Conversation> _conversations = [];
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchConversations();
  }

  Future<void> _fetchConversations() async {
    if (!mounted) return;
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    if (!authProvider.isLoggedIn || authProvider.user == null) {
      setState(() {
        _isLoading = false;
        _errorMessage = '请先登录';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final response = await ApiService.getConversations(authProvider.user!.id);
      final List<dynamic> conversationsJson = response['conversations'] ?? [];

      setState(() {
        _conversations = conversationsJson
            .map((json) => Conversation.fromJson(json))
            .toList();
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = '获取对话列表失败: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  Future<void> _createNewConversation() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    if (!authProvider.isLoggedIn || authProvider.user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请先登录以创建新对话')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final response = await ApiService.createConversation(authProvider.user!.id);
      final String conversationId = response['conversation']['id'];
      
      if (mounted) {
        // 导航到新创建的对话详情页面
        context.go('/chat/$conversationId');
        
        // 刷新对话列表
        _fetchConversations();
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('新对话创建成功')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('创建对话失败: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _renameConversation(String conversationId, String currentTitle) async {
    String? newTitle = await _showRenameDialog(currentTitle);
    if (newTitle != null && newTitle.isNotEmpty && newTitle != currentTitle) {
      setState(() {
        _isLoading = true;
      });

      try {
        await ApiService.renameConversation(conversationId, newTitle);
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('重命名对话成功')),
          );
          // 刷新对话列表
          _fetchConversations();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('重命名对话失败: ${e.toString()}')),
          );
        }
      } finally {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    }
  }

  Future<String?> _showRenameDialog(String currentTitle) async {
    TextEditingController controller = TextEditingController(text: currentTitle);
    return showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('重命名对话'),
          content: TextField(
            controller: controller,
            autofocus: true,
            decoration: const InputDecoration(hintText: '输入新标题'),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('取消'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, controller.text.trim()),
              child: const Text('确定'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _deleteConversation(String conversationId) async {
    bool? confirm = await _showDeleteConfirmationDialog();
    if (confirm == true) {
      setState(() {
        _isLoading = true;
      });

      try {
        await ApiService.deleteConversation(conversationId);
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('删除对话成功')),
          );
          // 刷新对话列表
          _fetchConversations();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('删除对话失败: ${e.toString()}')),
          );
        }
      } finally {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    }
  }

  Future<bool?> _showDeleteConfirmationDialog() async {
    return showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('确认删除'),
          content: const Text('确定要删除此对话吗？此操作无法撤销。'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('取消'),
            ),
            TextButton(
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              onPressed: () => Navigator.pop(context, true),
              child: const Text('删除'),
            ),
          ],
        );
      },
    );
  }

  String _formatDateTime(DateTime? dateTime) {
    return DateTimeUtils.formatDateTime(dateTime);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('健康咨询'),
        // Removed Home button, navigation handled by MainLayout
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: ElevatedButton.icon(
              icon: const Icon(Icons.add, size: 18),
              label: const Text('新建对话'),
              onPressed: _createNewConversation,
              style: ElevatedButton.styleFrom(
                // foregroundColor: Theme.of(context).colorScheme.onPrimary,
                // backgroundColor: Theme.of(context).colorScheme.primary,
              ),
            ),
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(_errorMessage!, style: const TextStyle(color: Colors.red)),
            const SizedBox(height: 16),
            ElevatedButton(onPressed: _fetchConversations, child: const Text('重试')),
          ],
        ),
      );
    }

    if (_conversations.isEmpty) {
      return const Center(child: Text('暂无健康咨询记录'));
    }

    // Use GridView for card layout if needed, or ListView for simpler list
    // Using ListView here for simplicity, adjust crossAxisCount for GridView
    return RefreshIndicator(
      onRefresh: _fetchConversations,
      child: ListView.builder(
        padding: const EdgeInsets.all(16.0),
        itemCount: _conversations.length,
        itemBuilder: (context, index) {
          final conversation = _conversations[index];
          return _buildConversationCard(conversation);
        },
      ),
    );
    /* Example using GridView:
    return RefreshIndicator(
      onRefresh: _fetchConversations,
      child: GridView.builder(
        padding: const EdgeInsets.all(16.0),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2, // Adjust as needed
          crossAxisSpacing: 16.0,
          mainAxisSpacing: 16.0,
          childAspectRatio: 1.5, // Adjust aspect ratio
        ),
        itemCount: _conversations.length,
        itemBuilder: (context, index) {
          final conversation = _conversations[index];
          return _buildConversationCard(conversation);
        },
      ),
    );
    */
  }

  Widget _buildConversationCard(Conversation conversation) {
    return Card(
      elevation: 2.0,
      margin: const EdgeInsets.only(bottom: 16.0),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              conversation.title ?? '新对话',
              style: Theme.of(context).textTheme.titleMedium,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 8),
            Text(
              '创建时间: ${_formatDateTime(conversation.createdAt)}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            Text(
              '最后更新: ${_formatDateTime(conversation.lastUpdated)}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const Divider(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton.icon(
                  icon: const Icon(Icons.message_outlined, size: 16),
                  label: const Text('继续对话'),
                  onPressed: () => context.go('/chat/${conversation.id}'),
                  style: TextButton.styleFrom(visualDensity: VisualDensity.compact),
                ),
                const SizedBox(width: 8),
                TextButton.icon(
                  icon: const Icon(Icons.edit_outlined, size: 16),
                  label: const Text('重命名'),
                  onPressed: () => _renameConversation(conversation.id, conversation.title ?? '新对话'),
                  style: TextButton.styleFrom(visualDensity: VisualDensity.compact),
                ),
                const SizedBox(width: 8),
                TextButton.icon(
                  icon: const Icon(Icons.delete_outline, size: 16, color: Colors.red),
                  label: const Text('删除', style: TextStyle(color: Colors.red)),
                  onPressed: () => _deleteConversation(conversation.id),
                  style: TextButton.styleFrom(visualDensity: VisualDensity.compact),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}