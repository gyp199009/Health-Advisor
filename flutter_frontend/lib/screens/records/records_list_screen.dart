import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:file_selector/file_selector.dart';
import 'dart:io';
import '../../models/record.dart';
import '../../providers/auth_provider.dart';
import '../../services/api_service.dart';
import '../../utils/datetime_utils.dart';
import 'record_upload_dialog.dart';

class RecordsListScreen extends StatefulWidget {
  const RecordsListScreen({super.key});

  @override
  State<RecordsListScreen> createState() => _RecordsListScreenState();
}

class _RecordsListScreenState extends State<RecordsListScreen> {
  bool _isLoading = false;
  List<Record> _records = [];
  String? _errorMessage;

  final Map<String, String> _recordTypeMap = {
    'exam_report': '检查报告',
    'diagnosis': '诊断证明',
    'medication': '处方',
    'outpatient': '门诊记录',
    'inpatient': '住院记录',
    'surgery': '手术记录',
    'imaging': '影像资料',
    'lab_report': '化验报告',
    'other': '其他',
  };

  @override
  void initState() {
    super.initState();
    _loadRecords();
  }

  Future<void> _loadRecords() async {
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
      final userId = authProvider.user!.id;
      final response = await ApiService.getRecords(userId);
      final List<dynamic> recordsJson = response['records'] ?? [];

      setState(() {
        _records = recordsJson.map((json) => Record.fromJson(json)).toList();
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = '获取记录失败: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  Future<void> _uploadRecord() async {
    // 显示上传对话框
    final bool? result = await showDialog<bool>(
      context: context,
      builder: (context) => const RecordUploadDialog(),
    );

    // 如果上传成功，刷新列表
    if (result == true) {
      await _loadRecords();
    }
  }

  Future<void> _editRecord(Record record) async {
    // Placeholder for edit logic (e.g., change description)
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('编辑记录 ${record.id} (待实现)')),
    );
    // Potentially show a dialog to edit details
    // Refresh list on success
    // _loadRecords();
  }

  Future<void> _deleteRecord(String recordId) async {
    bool? confirm = await _showDeleteConfirmationDialog();
    if (confirm == true) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      try {
        final authProvider = Provider.of<AuthProvider>(context, listen: false);
        if (!authProvider.isLoggedIn || authProvider.user == null) {
          throw Exception('用户未登录');
        }
        await ApiService.deleteRecord(recordId, authProvider.user!.id);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('病历记录已删除')),
        );
        await _loadRecords(); // 刷新列表
      } catch (e) {
        setState(() {
          _errorMessage = '删除失败: ${e.toString()}';
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('删除失败: ${e.toString()}')),
        );
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
          content: const Text('确定要删除此病历记录吗？此操作无法撤销。'),
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
        title: const Text('病历管理'),
        // Removed Home button, navigation handled by MainLayout
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: ElevatedButton.icon(
              icon: const Icon(Icons.add, size: 18),
              label: const Text('上传病历'),
              onPressed: _uploadRecord,
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
            ElevatedButton(onPressed: _loadRecords, child: const Text('重试')),
          ],
        ),
      );
    }

    if (_records.isEmpty) {
      return const Center(child: Text('暂无病历记录'));
    }

    // 使用LayoutBuilder来获取可用空间的约束条件
    return LayoutBuilder(
      builder: (context, constraints) {
        // 获取屏幕尺寸和方向
        final screenSize = MediaQuery.of(context).size;
        final isLandscape = screenSize.width > screenSize.height;
        final isSmallScreen = screenSize.width < 600;
        
        // 根据屏幕尺寸和方向动态计算网格列数和宽高比
        int crossAxisCount;
        double childAspectRatio;
        double padding;
        
        if (isSmallScreen) {
          // 手机屏幕
          crossAxisCount = isLandscape ? 3 : 1; // 横屏3列，竖屏1列
          childAspectRatio = isLandscape ? 3 : 2.5; // 调整宽高比
          padding = 8.0;
        } else if (screenSize.width < 900) {
          // 中等屏幕（平板）
          crossAxisCount = isLandscape ? 4 : 2;
          childAspectRatio = isLandscape ? 3 : 2.5;
          padding = 12.0;
        } else {
          // 大屏幕
          crossAxisCount = isLandscape ? 5 : 3;
          childAspectRatio = 3;
          padding = 16.0;
        }
        
        return RefreshIndicator(
          onRefresh: _loadRecords,
          child: GridView.builder(
            padding: EdgeInsets.all(padding),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: crossAxisCount,
              crossAxisSpacing: 12.0,
              mainAxisSpacing: 12.0,
              childAspectRatio: childAspectRatio,
            ),
            itemCount: _records.length,
            itemBuilder: (context, index) {
              final record = _records[index];
              return _buildRecordCard(record);
            },
          ),
        );
      },
    );
  }

  Widget _buildRecordCard(Record record) {
    // 获取屏幕尺寸和方向
    final screenSize = MediaQuery.of(context).size;
    final isLandscape = screenSize.width > screenSize.height;
    final isSmallScreen = screenSize.width < 600;
    
    // 根据屏幕尺寸调整组件大小
    final double iconSize = isSmallScreen ? 16.0 : 20.0;
    final double chipFontSize = isSmallScreen ? 10.0 : 12.0;
    final double verticalSpacing = isSmallScreen ? 4.0 : 8.0;
    final double horizontalSpacing = isSmallScreen ? 4.0 : 8.0;
    final double cardPadding = isSmallScreen ? 8.0 : 12.0;
    
    // Determine icon based on type or use a default
    IconData recordIcon = Icons.description; // Default
    if (record.recordType.toLowerCase().contains('检查')) {
      recordIcon = Icons.science_outlined;
    } else if (record.recordType.toLowerCase().contains('体检')) {
      recordIcon = Icons.health_and_safety_outlined;
    }

    return Card(
      elevation: 2.0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0)),
      child: Padding(
        padding: EdgeInsets.all(cardPadding),
        child: LayoutBuilder(
          builder: (context, constraints) {
            // 在横屏模式下使用不同的布局
            if (isLandscape && !isSmallScreen) {
              return Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // 左侧信息区
                  Expanded(
                    flex: 3,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          children: [
                            Icon(recordIcon, size: iconSize, color: Colors.blueGrey),
                            SizedBox(width: horizontalSpacing),
                            Expanded(
                              child: Text(
                                record.description ?? record.recordType,
                                style: Theme.of(context).textTheme.titleSmall,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: verticalSpacing),
                        Chip(
                          label: Text(
                            _recordTypeMap[record.recordType] ?? record.recordType,
                            style: Theme.of(context).textTheme.labelSmall?.copyWith(fontSize: chipFontSize),
                          ),
                          padding: EdgeInsets.zero,
                          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          visualDensity: VisualDensity.compact,
                          backgroundColor: Colors.blue.shade50,
                        ),
                        SizedBox(height: verticalSpacing),
                        Text(
                          '上传时间: ${_formatDateTime(record.uploadDate)}',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                  // 右侧操作区
                  Expanded(
                    flex: 1,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton.icon(
                          icon: Icon(Icons.visibility_outlined, size: iconSize),
                          label: const Text('查看'),
                          onPressed: () => context.go('/records/${record.id}'),
                          style: TextButton.styleFrom(visualDensity: VisualDensity.compact),
                        ),
                        IconButton(
                          icon: Icon(Icons.delete_outline, size: iconSize, color: Colors.red),
                          tooltip: '删除',
                          onPressed: () => _deleteRecord(record.id),
                          visualDensity: VisualDensity.compact,
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                      ],
                    ),
                  ),
                ],
              );
            } else {
              // 竖屏模式下的布局
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(recordIcon, size: iconSize, color: Colors.blueGrey),
                      SizedBox(width: horizontalSpacing),
                      Expanded(
                        child: Text(
                          record.description ?? record.recordType,
                          style: Theme.of(context).textTheme.titleSmall,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: verticalSpacing),
                  Chip(
                    label: Text(
                      _recordTypeMap[record.recordType] ?? record.recordType,
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(fontSize: chipFontSize),
                    ),
                    padding: EdgeInsets.zero,
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    visualDensity: VisualDensity.compact,
                    backgroundColor: Colors.blue.shade50,
                  ),
                  SizedBox(height: verticalSpacing),
                  Text(
                    '上传时间: ${_formatDateTime(record.uploadDate)}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const Spacer(),
                  Divider(height: verticalSpacing * 2),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton.icon(
                        icon: Icon(Icons.visibility_outlined, size: iconSize),
                        label: const Text('查看详情'),
                        onPressed: () => context.go('/records/${record.id}'),
                        style: TextButton.styleFrom(visualDensity: VisualDensity.compact),
                      ),
                      SizedBox(width: horizontalSpacing),
                      IconButton(
                        icon: Icon(Icons.delete_outline, size: iconSize, color: Colors.red),
                        tooltip: '删除',
                        onPressed: () => _deleteRecord(record.id),
                        visualDensity: VisualDensity.compact,
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ],
                  ),
                ],
              );
            }
          },
        ),
      ),
    );
  }
}