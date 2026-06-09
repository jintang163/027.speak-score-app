import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:speak_score_flutter/models/material_info.dart';
import 'package:speak_score_flutter/services/auth_service.dart';
import 'package:speak_score_flutter/services/material_service.dart';

class MaterialUploadScreen extends StatefulWidget {
  const MaterialUploadScreen({super.key});

  @override
  State<MaterialUploadScreen> createState() => _MaterialUploadScreenState();
}

class _MaterialUploadScreenState extends State<MaterialUploadScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _materialService = MaterialService();

  String _selectedType = 'VIDEO';
  String _selectedScope = 'SCHOOL';
  int? _selectedGradeLevel;
  Set<int> _selectedTagIds = {};

  List<MaterialTag> _allTags = [];
  bool _isLoadingTags = false;
  bool _isUploading = false;
  double _uploadProgress = 0;

  String? _pickedFilePath;
  String? _pickedFileName;
  int? _pickedFileSize;

  static const List<MapEntry<String, String>> _typeOptions = [
    MapEntry('VIDEO', '视频'),
    MapEntry('PDF', 'PDF'),
    MapEntry('IMAGE', '图片'),
  ];

  static const List<MapEntry<String, String>> _scopeOptions = [
    MapEntry('SCHOOL', '全校'),
    MapEntry('CLASS', '班级'),
  ];

  static const List<int> _gradeLevels = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12];

  @override
  void initState() {
    super.initState();
    _loadTags();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _loadTags() async {
    setState(() => _isLoadingTags = true);
    try {
      final tags = await _materialService.getAllTags();
      if (mounted) {
        setState(() {
          _allTags = tags;
          _isLoadingTags = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _isLoadingTags = false);
      }
    }
  }

  Future<void> _pickFile() async {
    try {
      if (_selectedType == 'IMAGE') {
        final picker = ImagePicker();
        final image = await picker.pickImage(source: ImageSource.gallery);
        if (image != null) {
          setState(() {
            _pickedFilePath = image.path;
            _pickedFileName = image.name;
            _pickedFileSize = await image.length();
          });
        }
      } else {
        FileType fileType;
        List<String>? allowedExtensions;
        if (_selectedType == 'VIDEO') {
          fileType = FileType.video;
          allowedExtensions = ['mp4'];
        } else {
          fileType = FileType.custom;
          allowedExtensions = ['pdf'];
        }

        final result = await FilePicker.platform.pickFiles(
          type: fileType,
          allowedExtensions: allowedExtensions,
        );

        if (result != null && result.files.single.path != null) {
          final file = result.files.single;
          setState(() {
            _pickedFilePath = file.path;
            _pickedFileName = file.name;
            _pickedFileSize = file.size;
          });
        }
      }
    } catch (_) {
      _showError('选择文件失败');
    }
  }

  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_pickedFilePath == null) {
      _showError('请选择文件');
      return;
    }

    setState(() {
      _isUploading = true;
      _uploadProgress = 0;
    });

    try {
      final authService = context.read<AuthService>();
      final userInfo = authService.userInfo;

      final result = await _materialService.uploadMaterial(
        filePath: _pickedFilePath!,
        fileName: _pickedFileName ?? 'file',
        title: _titleController.text.trim(),
        materialType: _selectedType,
        description: _descriptionController.text.trim().isEmpty
            ? null
            : _descriptionController.text.trim(),
        tagIds: _selectedTagIds.toList(),
        scope: _selectedScope,
        schoolId: userInfo?.schoolId,
        classId: _selectedScope == 'CLASS' ? userInfo?.classId : null,
        gradeLevel: _selectedGradeLevel,
        onSendProgress: (sent, total) {
          if (total > 0) {
            setState(() => _uploadProgress = sent / total);
          }
        },
      );

      if (mounted) {
        setState(() => _isUploading = false);
        if (result != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text('上传成功'), backgroundColor: Colors.green),
          );
          Navigator.of(context).pop(true);
        } else {
          _showError('上传失败，请稍后重试');
        }
      }
    } catch (_) {
      if (mounted) {
        setState(() => _isUploading = false);
        _showError('上传失败，请稍后重试');
      }
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('上传资料'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: '标题 *',
                  prefixIcon: Icon(Icons.title),
                  border: OutlineInputBorder(),
                  hintText: '请输入资料标题',
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return '请输入标题';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: '描述',
                  prefixIcon: Icon(Icons.description),
                  border: OutlineInputBorder(),
                  hintText: '请输入资料描述（可选）',
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 16),
              const Text('资料类型',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: _typeOptions.map((entry) {
                  final isSelected = _selectedType == entry.key;
                  return ChoiceChip(
                    label: Text(entry.value),
                    selected: isSelected,
                    onSelected: (_) {
                      setState(() {
                        _selectedType = entry.key;
                        _pickedFilePath = null;
                        _pickedFileName = null;
                        _pickedFileSize = null;
                      });
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: _isUploading ? null : _pickFile,
                  icon: const Icon(Icons.attach_file),
                  label: Text(_pickedFileName ?? '选择文件'),
                ),
              ),
              if (_pickedFileName != null && _pickedFileSize != null) ...[
                const SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsets.only(left: 12),
                  child: Text(
                    '$_pickedFileName  (${_formatFileSize(_pickedFileSize!)})',
                    style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                  ),
                ),
              ],
              const SizedBox(height: 16),
              const Text('标签',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
              const SizedBox(height: 8),
              _isLoadingTags
                  ? const Center(
                      child: SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    )
                  : Wrap(
                      spacing: 8,
                      children: _allTags.map((tag) {
                        final isSelected =
                            _selectedTagIds.contains(tag.id);
                        return FilterChip(
                          label: Text(tag.tagName ?? ''),
                          selected: isSelected,
                          onSelected: (selected) {
                            setState(() {
                              if (selected && tag.id != null) {
                                _selectedTagIds.add(tag.id!);
                              } else if (tag.id != null) {
                                _selectedTagIds.remove(tag.id!);
                              }
                            });
                          },
                        );
                      }).toList(),
                    ),
              const SizedBox(height: 16),
              const Text('可见范围',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: _scopeOptions.map((entry) {
                  final isSelected = _selectedScope == entry.key;
                  return ChoiceChip(
                    label: Text(entry.value),
                    selected: isSelected,
                    onSelected: (_) {
                      setState(() => _selectedScope = entry.key);
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<int>(
                value: _selectedGradeLevel,
                decoration: const InputDecoration(
                  labelText: '年级',
                  prefixIcon: Icon(Icons.grade),
                  border: OutlineInputBorder(),
                ),
                items: [
                  const DropdownMenuItem<int>(
                    value: null,
                    child: Text('不选择年级'),
                  ),
                  ..._gradeLevels.map((level) => DropdownMenuItem<int>(
                        value: level,
                        child: Text('$level年级'),
                      )),
                ],
                onChanged: (value) {
                  setState(() => _selectedGradeLevel = value);
                },
              ),
              const SizedBox(height: 24),
              if (_isUploading) ...[
                LinearProgressIndicator(value: _uploadProgress),
                const SizedBox(height: 8),
                Center(
                  child: Text(
                    '上传中... ${(_uploadProgress * 100).toStringAsFixed(0)}%',
                    style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                  ),
                ),
                const SizedBox(height: 16),
              ],
              SizedBox(
                width: double.infinity,
                height: 48,
                child: FilledButton(
                  onPressed: _isUploading ? null : _submit,
                  child: _isUploading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text('上传', style: TextStyle(fontSize: 16)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
