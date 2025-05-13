import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import '../../models/record.dart';
import '../../providers/auth_provider.dart';
import '../../services/api_service.dart';
import '../../utils/datetime_utils.dart';

class RecordDetailScreen extends StatefulWidget {
  final String recordId;

  const RecordDetailScreen({super.key, required this.recordId});

  @override
  State<RecordDetailScreen> createState() => _RecordDetailScreenState();
}

class _RecordDetailScreenState extends State<RecordDetailScreen> {
  Record? _record;
  bool _isLoading = true;
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
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            // 双重检查导航栈状态
            if (Navigator.of(context).canPop()) {
              Navigator.of(context).pop();
            } else {
              // 当导航栈为空时使用绝对路径跳转
              GoRouter.of(context).go('/records');
            }
          }
        ),
        title: const Text('病历详情'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? Center(child: Text(_errorMessage!))
              : _record == null
                  ? const Center(child: Text('未找到病历记录'))
                  : SingleChildScrollView(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildInfoCard(),
                          const SizedBox(height: 16),
                          if (_record!.file != null) _buildFileCard(),
                          const SizedBox(height: 16),
                          _buildContentCard(),
                        ],
                      ),
                    ),
    );
  }

  @override
  void initState() {
    super.initState();
    _fetchRecordDetails();
  }

  Future<void> _fetchRecordDetails() async {
    if (!mounted) return;
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    if (!authProvider.isLoggedIn || authProvider.user == null) {
      setState(() {
        _isLoading = false;
        _errorMessage = '用户未登录';
      });
      return;
    }

    try {
      final response = await ApiService.getRecordDetail(
        widget.recordId,
        authProvider.user!.id,
      );
      if (mounted) {
        setState(() {
          _record = Record.fromJson(response['record']);
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = '获取病历详情失败：$e';
        });
      }
    }
  }

  Future<void> _downloadFile() async {
    if (_record?.file == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('无法下载，文件不存在')),
      );
      return;
    }
    
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    if (!authProvider.isLoggedIn || authProvider.user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请先登录')),
      );
      return;
    }

    BuildContext? dialogContext;
    // 显示下载进度对话框
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        dialogContext = context;
        return const Center(
          child: CircularProgressIndicator(),
        );
      },
    );

    try {

      // 下载文件
      final fileBytes = await ApiService.downloadRecordFile(
        _record!.id,
        authProvider.user!.id,
      );

      // 保存文件
      if (fileBytes.isNotEmpty) {
        final fileName = _record!.file!.originalName ?? '病历文件';
        Directory directory;
      if (Platform.isAndroid) {
        directory = Directory('/storage/emulated/0/Download');
        if (!await directory.exists()) {
          directory = await getExternalStorageDirectory() ?? await getApplicationDocumentsDirectory();
        }
      } else {
        directory = await getApplicationDocumentsDirectory();
      }
        final filePath = '${directory.path}/$fileName';
        final file = File(filePath);
        await file.writeAsBytes(fileBytes);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('文件已下载到: $filePath')),
          );
        }
      } else {
        throw Exception('下载的文件内容为空');
      }
    } catch (e) {
      // 显示错误信息
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('下载失败: $e')),
        );
      }
    } finally {
      // 确保在所有情况下都关闭进度对话框
      if (dialogContext != null && mounted) {
        Navigator.of(dialogContext!).pop();
      }
    }
  }

  Widget _buildInfoCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _record!.description ?? _record!.recordType,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              '类型：${_recordTypeMap[_record!.recordType] ?? _record!.recordType}',
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: 8),
            Text(
              '上传时间：${DateTimeUtils.formatDateTime(_record?.uploadDate)}',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFileCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '附件',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            ListTile(
              leading: const Icon(Icons.attach_file),
              title: Text(_record!.file!.originalName),
              subtitle: Text(
                '文件大小：${(_record!.file!.size / 1024).toStringAsFixed(2)} KB',
              ),
              trailing: IconButton(
                icon: const Icon(Icons.download),
                onPressed: _downloadFile,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContentCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '内容',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(_record!.textContent.isEmpty ? '无文本内容' : _record!.textContent),
          ],
        ),
      ),
    );
  }
}