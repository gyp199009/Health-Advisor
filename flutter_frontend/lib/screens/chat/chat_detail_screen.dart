import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_selector/file_selector.dart';
import 'dart:io';
import '../../models/message.dart';
import '../../models/record.dart';
import '../../providers/auth_provider.dart';
import '../../services/api_service.dart';
import '../../utils/datetime_utils.dart';

class ChatDetailScreen extends StatefulWidget {
  final String conversationId;

  const ChatDetailScreen({super.key, required this.conversationId});

  @override
  State<ChatDetailScreen> createState() => _ChatDetailScreenState();
}

class _ChatDetailScreenState extends State<ChatDetailScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<Message> _messages = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadMessages();
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadMessages() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // 从API获取消息
      final response = await ApiService.getMessages(widget.conversationId);
      final List<dynamic> messagesJson = response['messages'] ?? [];
      
      final messages = messagesJson
          .map((json) => Message.fromJson(json))
          .toList();
      
      setState(() {
        _messages.clear();
        _messages.addAll(messages);
        _isLoading = false;
      });
      
      // 滚动到底部
      _scrollToBottom();
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('获取消息失败: ${e.toString()}')),
      );
    }
  }

  File? _selectedFile;
  String? _selectedFileName;
  
  Future<void> _pickFile() async {
    try {
      // 使用file_selector替代file_picker
      final XFile? result = await openFile();
      
      if (result != null) {
        setState(() {
          _selectedFile = File(result.path);
          _selectedFileName = result.name;
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('已选择文件: $_selectedFileName')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('选择文件失败: ${e.toString()}')),
      );
    }
  }
  
  void _clearSelectedFile() {
    setState(() {
      _selectedFile = null;
      _selectedFileName = null;
    });
  }

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty && _selectedFile == null) return;

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    if (!authProvider.isLoggedIn) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请先登录')),
      );
      return;
    }
    
    final userId = authProvider.user!.id;

    // 清空输入框并显示发送中状态
    _messageController.clear();
    setState(() {
      _isLoading = true;
    });

    try {
      // 调用API发送消息
      if (_selectedFile != null) {
        // 发送带附件的消息
        await ApiService.sendMessageWithAttachment(
          widget.conversationId,
          userId,
          text.isEmpty ? '发送了一个附件' : text,
          _selectedFile!.path,
        );
        
        // 清除已选择的文件
        _clearSelectedFile();
      } else {
        // 发送普通文本消息
        await ApiService.sendMessage(
          widget.conversationId,
          userId,
          text,
        );
      }
      
      // 重新加载所有消息以获取最新状态
      await _loadMessages();
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('发送消息失败: ${e.toString()}')),
      );
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // 获取屏幕尺寸
    final screenSize = MediaQuery.of(context).size;
    final isSmallScreen = screenSize.width < 600;
    
    return Scaffold(
      appBar: AppBar(
        title: Text('健康咨询', 
          style: TextStyle(fontSize: isSmallScreen ? 16 : 18)),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadMessages,
            tooltip: '刷新消息',
            iconSize: isSmallScreen ? 20 : 24,
          ),
          IconButton(
            icon: const Icon(Icons.list),
            onPressed: () => context.go('/chat'),
            tooltip: '返回列表',
            iconSize: isSmallScreen ? 20 : 24,
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: _buildMessageList(),
            ),
            _buildMessageInput(),
          ],
        ),
      ),
    );
  }
  
  Widget _buildMessageList() {
    // 获取屏幕尺寸
    final screenSize = MediaQuery.of(context).size;
    final isSmallScreen = screenSize.width < 600;
    
    if (_isLoading && _messages.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    
    if (_messages.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.chat_bubble_outline, 
              size: isSmallScreen ? 48 : 64, 
              color: Colors.grey),
            SizedBox(height: isSmallScreen ? 12 : 16),
            Text('暂无消息记录', 
              style: TextStyle(fontSize: isSmallScreen ? 16 : 18, color: Colors.grey)),
            SizedBox(height: isSmallScreen ? 16 : 24),
            ElevatedButton(
              onPressed: () => _messageController.text = '您好，我想咨询一下健康问题',
              child: const Text('开始咨询'),
              style: ElevatedButton.styleFrom(
                padding: EdgeInsets.symmetric(
                  horizontal: isSmallScreen ? 16 : 24, 
                  vertical: isSmallScreen ? 8 : 12
                ),
              ),
            ),
          ],
        ),
      );
    }
    
    return RefreshIndicator(
      onRefresh: _loadMessages,
      child: ListView.builder(
        controller: _scrollController,
        padding: EdgeInsets.all(isSmallScreen ? 12.0 : 16.0),
        itemCount: _messages.length,
        itemBuilder: (context, index) {
          final message = _messages[index];
          return _buildMessageBubble(message);
        },
      ),
    );
  }

  Widget _buildMessageBubble(Message message) {
    final isUser = message.role == 'user';
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10.0),
      child: Column(
        crossAxisAlignment: isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (!isUser)
                const CircleAvatar(
                  backgroundColor: Colors.blue,
                  radius: 16,
                  child: Icon(Icons.health_and_safety, color: Colors.white, size: 18),
                ),
              const SizedBox(width: 8.0),
              Flexible(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                  decoration: BoxDecoration(
                    color: isUser ? Colors.blue[100] : Colors.grey[200],
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(isUser ? 16.0 : 4.0),
                      topRight: Radius.circular(isUser ? 4.0 : 16.0),
                      bottomLeft: const Radius.circular(16.0),
                      bottomRight: const Radius.circular(16.0),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 2,
                        offset: const Offset(0, 1),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        message.content,
                        style: TextStyle(
                          color: isUser ? Colors.black87 : Colors.black,
                          fontSize: 15,
                        ),
                      ),
                      // 显示附件（如果有）
                      if (message.attachments != null && message.attachments!.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 8.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: message.attachments!.map((attachment) {
                              return _buildAttachmentItem(attachment);
                            }).toList(),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 8.0),
              if (isUser)
                const CircleAvatar(
                  backgroundColor: Colors.blue,
                  radius: 16,
                  child: Icon(Icons.person, color: Colors.white, size: 18),
                ),
            ],
          ),
          Padding(
            padding: EdgeInsets.only(left: isUser ? 0 : 40, right: isUser ? 40 : 0, top: 4),
            child: Text(
              _formatMessageTime(message.timestamp),
              style: TextStyle(fontSize: 11, color: Colors.grey[600]),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildAttachmentItem(MessageAttachment attachment) {
    return FutureBuilder<Map<String, dynamic>>(
      future: ApiService.getRecordDetail(attachment.recordId, Provider.of<AuthProvider>(context, listen: false).user!.id),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 8.0),
            child: SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2)),
          );
        }
        
        if (snapshot.hasError || !snapshot.hasData) {
          return Container(
            padding: const EdgeInsets.all(8.0),
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(8.0),
            ),
            child: const Text('附件加载失败', style: TextStyle(fontSize: 12)),
          );
        }
        
        final record = Record.fromJson(snapshot.data!['record']);
        final fileData = record.file;
        
        if (fileData == null) {
          return Container(
            padding: const EdgeInsets.all(8.0),
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(8.0),
            ),
            child: const Text('附件数据不完整', style: TextStyle(fontSize: 12)),
          );
        }
        
        // 根据文件类型显示不同的图标
        IconData iconData = Icons.insert_drive_file;
        if (fileData.mimetype.startsWith('image/')) {
          iconData = Icons.image;
        } else if (fileData.mimetype.startsWith('video/')) {
          iconData = Icons.video_file;
        } else if (fileData.mimetype.startsWith('audio/')) {
          iconData = Icons.audio_file;
        } else if (fileData.mimetype.contains('pdf')) {
          iconData = Icons.picture_as_pdf;
        }
        
        return Container(
          margin: const EdgeInsets.only(top: 8.0),
          padding: const EdgeInsets.all(8.0),
          decoration: BoxDecoration(
            color: Colors.grey[300],
            borderRadius: BorderRadius.circular(8.0),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(iconData, size: 24, color: Colors.blue[700]),
              const SizedBox(width: 8.0),
              Flexible(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      fileData.originalName,
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      '${(fileData.size / 1024).toStringAsFixed(1)} KB',
                      style: TextStyle(fontSize: 10, color: Colors.grey[700]),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.download, size: 20),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                onPressed: () {
                  // TODO: 实现文件下载功能
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('文件下载功能即将推出')),
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }
  
  String _formatMessageTime(DateTime time) {
    return DateTimeUtils.formatMessageTime(time);
  }

  Widget _buildMessageInput() {
    // 获取屏幕尺寸
    final screenSize = MediaQuery.of(context).size;
    final isSmallScreen = screenSize.width < 600;
    
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isSmallScreen ? 8.0 : 12.0, 
        vertical: isSmallScreen ? 6.0 : 8.0
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            spreadRadius: 1,
            blurRadius: 3,
            offset: const Offset(0, -1),
          ),
        ],
        border: Border(
          top: BorderSide(color: Colors.grey.shade200, width: 1),
        ),
      ),
      child: Column(
        children: [
          // 显示已选择的文件（如果有）
          if (_selectedFileName != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
              margin: const EdgeInsets.only(bottom: 8.0),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.blue[200]!, width: 1),
              ),
              child: Row(
                children: [
                  Icon(Icons.attach_file, 
                    size: isSmallScreen ? 16 : 20, 
                    color: Colors.blue),
                  SizedBox(width: isSmallScreen ? 6.0 : 8.0),
                  Expanded(
                    child: Text(
                      _selectedFileName!,
                      style: TextStyle(fontSize: isSmallScreen ? 12 : 14),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.close, 
                      size: isSmallScreen ? 16 : 18, 
                      color: Colors.grey),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    onPressed: _clearSelectedFile,
                  ),
                ],
              ),
            ),
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.attach_file, color: Colors.grey),
                onPressed: _isLoading ? null : _pickFile,
                tooltip: '添加附件',
                iconSize: isSmallScreen ? 20 : 24,
                padding: EdgeInsets.all(isSmallScreen ? 6.0 : 8.0),
                constraints: BoxConstraints(
                  minWidth: isSmallScreen ? 32 : 40,
                  minHeight: isSmallScreen ? 32 : 40,
                ),
              ),
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(isSmallScreen ? 20 : 24),
                    border: Border.all(color: Colors.grey.shade300, width: 1),
                  ),
                  child: TextField(
                    controller: _messageController,
                    decoration: InputDecoration(
                      hintText: '输入您的健康问题...',
                      hintStyle: TextStyle(fontSize: isSmallScreen ? 14 : 16),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: isSmallScreen ? 12.0 : 16.0, 
                        vertical: isSmallScreen ? 8.0 : 12.0
                      ),
                    ),
                    style: TextStyle(fontSize: isSmallScreen ? 14 : 16),
                    maxLines: null,
                    textInputAction: TextInputAction.send,
                    onSubmitted: (_) => _sendMessage(),
                  ),
                ),
              ),
              SizedBox(width: isSmallScreen ? 6.0 : 8.0),
              FloatingActionButton(
                onPressed: _isLoading ? null : _sendMessage,
                mini: true,
                backgroundColor: Colors.blue,
                child: _isLoading
                    ? SizedBox(
                        width: isSmallScreen ? 20 : 24,
                        height: isSmallScreen ? 20 : 24,
                        child: const CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : Icon(Icons.send, color: Colors.white, size: isSmallScreen ? 18 : 24),
              ),
            ],
          ),
        ],
      ),
    );
  }
}