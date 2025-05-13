import 'package:flutter/material.dart';
import 'package:file_selector/file_selector.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../services/api_service.dart';

class RecordUploadDialog extends StatefulWidget {
  const RecordUploadDialog({super.key});

  @override
  State<RecordUploadDialog> createState() => _RecordUploadDialogState();
}

class _RecordUploadDialogState extends State<RecordUploadDialog> {
  final _formKey = GlobalKey<FormState>();
  final _descriptionController = TextEditingController();
  final _textContentController = TextEditingController();
  String _selectedType = 'exam_report';  // 默认为检查报告
  String _uploadType = 'file';  // 默认为文件上传
  XFile? _selectedFile;
  bool _isUploading = false;
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

  final List<String> _recordTypes = [
    'exam_report',
    'diagnosis',
    'medication',
    'outpatient',
    'inpatient',
    'surgery',
    'imaging',
    'lab_report',
    'other',
  ];

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _pickFile() async {
    try {
      // 定义允许的文件类型
      final typeGroup = XTypeGroup(
        label: '支持的文件类型',
        extensions: ['pdf', 'jpg', 'png', 'jpeg', 'doc', 'docx', 'txt'],
      );
      
      // 打开文件选择器
      final XFile? file = await openFile(
        acceptedTypeGroups: [typeGroup],
      );

      if (file != null) {
        setState(() {
          _selectedFile = file;
          _errorMessage = null;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = '选择文件失败：${e.toString()}';
      });
    }
  }

  Future<void> _uploadRecord() async {
    if (!_formKey.currentState!.validate()) return;
    if (_uploadType == 'file' && _selectedFile == null) {
      setState(() {
        _errorMessage = '请选择要上传的文件';
      });
      return;
    } else if (_uploadType == 'text' && (_textContentController.text.isEmpty || _textContentController.text.trim().isEmpty)) {
      setState(() {
        _errorMessage = '请输入病历内容';
      });
      return;
    }

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    if (!authProvider.isLoggedIn || authProvider.user == null) {
      setState(() {
        _errorMessage = '请先登录';
      });
      return;
    }

    setState(() {
      _isUploading = true;
      _errorMessage = null;
    });

    try {
      final userId = authProvider.user!.id;
      final response = _uploadType == 'file'
          ? await ApiService.uploadRecord(
              userId: userId,
              file: _selectedFile!,
              recordType: _selectedType,
              description: _descriptionController.text,
            )
          : await ApiService.uploadTextRecord(
              userId,
              _textContentController.text,
              _selectedType,
              _descriptionController.text,
            );

      if (!mounted) return;

      // 上传成功，关闭对话框并返回true
      Navigator.of(context).pop(true);
    } catch (e) {
      setState(() {
        _errorMessage = '上传失败：${e.toString()}';
        _isUploading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('上传病历'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              DropdownButtonFormField<String>(
                value: _selectedType,
                decoration: const InputDecoration(labelText: '病历类型'),
                items: _recordTypes.map((type) {
                  return DropdownMenuItem(
                    value: type,
                    child: Text(_recordTypeMap[type] ?? type),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      _selectedType = value;
                    });
                  }
                },
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return '请选择病历类型';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: '描述',
                  hintText: '请简要描述此病历记录，如：2023年6月血常规检查',
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return '请输入病历描述';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton.icon(
                    icon: const Icon(Icons.upload_file),
                    label: const Text('文件上传'),
                    onPressed: _isUploading ? null : () => setState(() => _uploadType = 'file'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _uploadType == 'file' ? Theme.of(context).highlightColor : null,
                    ),
                  ),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.text_fields),
                    label: const Text('文本记录'),
                    onPressed: _isUploading ? null : () => setState(() => _uploadType = 'text'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _uploadType == 'text' ? Theme.of(context).highlightColor : null,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              if (_uploadType == 'file') ...[                Row(
                  children: [
                    ElevatedButton.icon(
                      icon: const Icon(Icons.upload_file),
                      label: const Text('选择文件'),
                      onPressed: _isUploading ? null : _pickFile,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _selectedFile?.name ?? '未选择文件',
                        style: Theme.of(context).textTheme.bodySmall,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  '支持PDF、图片、Word和文本文件，大小不超过10MB',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.grey,
                      ),
                ),
              ] else ...[                TextFormField(
                  controller: _textContentController,
                  decoration: const InputDecoration(
                    labelText: '病历内容',
                    hintText: '请输入病历内容...',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 8,
                  validator: (value) {
                    if (_uploadType == 'text' && (value == null || value.trim().isEmpty)) {
                      return '请输入病历内容';
                    }
                    return null;
                  },
                ),
              ],
              if (_errorMessage != null) ...[                const SizedBox(height: 16),
                Text(
                  _errorMessage!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isUploading ? null : () => Navigator.of(context).pop(false),
          child: const Text('取消'),
        ),
        ElevatedButton(
          onPressed: _isUploading ? null : _uploadRecord,
          child: _isUploading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('上传'),
        ),
      ],
    );
  }
}