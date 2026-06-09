import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:speak_score_flutter/models/material_info.dart';
import 'package:speak_score_flutter/screens/material/material_detail_screen.dart';
import 'package:speak_score_flutter/screens/material/material_upload_screen.dart';
import 'package:speak_score_flutter/services/auth_service.dart';
import 'package:speak_score_flutter/services/material_service.dart';

class MaterialListScreen extends StatefulWidget {
  const MaterialListScreen({super.key});

  @override
  State<MaterialListScreen> createState() => _MaterialListScreenState();
}

class _MaterialListScreenState extends State<MaterialListScreen> {
  final _searchController = TextEditingController();
  final _materialService = MaterialService();

  List<MaterialInfo> _materials = [];
  List<MaterialTag> _allTags = [];
  bool _isLoading = false;

  String _selectedType = '全部';
  int? _selectedTagId;

  static const List<String> _typeFilters = ['全部', '视频', 'PDF', '图片'];
  static const Map<String, String?> _typeFilterMap = {
    '全部': null,
    '视频': 'VIDEO',
    'PDF': 'PDF',
    '图片': 'IMAGE',
  };

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    await Future.wait([
      _loadTags(),
      _searchMaterials(),
    ]);
  }

  Future<void> _loadTags() async {
    try {
      final tags = await _materialService.getAllTags();
      if (mounted) {
        setState(() => _allTags = tags);
      }
    } catch (_) {}
  }

  Future<void> _searchMaterials() async {
    setState(() => _isLoading = true);
    try {
      final keyword = _searchController.text.trim();
      final materialType = _typeFilterMap[_selectedType];
      final results = await _materialService.searchMaterials(
        keyword: keyword.isEmpty ? null : keyword,
        materialType: materialType,
        tagId: _selectedTagId,
      );
      if (mounted) {
        setState(() {
          _materials = results;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _isLoading = false);
        _showError('加载资料失败，请稍后重试');
      }
    }
  }

  void _onSearchSubmitted(_) => _searchMaterials();

  void _onTypeFilterChanged(String type) {
    setState(() => _selectedType = type);
    _searchMaterials();
  }

  void _onTagFilterChanged(int? tagId) {
    setState(() => _selectedTagId = tagId);
    _searchMaterials();
  }

  void _navigateToDetail(MaterialInfo material) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => MaterialDetailScreen(materialId: material.id!),
      ),
    ).then((_) => _searchMaterials());
  }

  void _navigateToUpload() {
    Navigator.of(context)
        .push(MaterialPageRoute(builder: (_) => const MaterialUploadScreen()))
        .then((result) {
      if (result == true) _searchMaterials();
    });
  }

  bool get _canUpload {
    final roles = context.watch<AuthService>().userInfo?.roles ?? [];
    return roles.contains('TEACHER') || roles.contains('EDU_OFFICE');
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
        title: const Text('学习资料'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: '搜索资料...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          _searchMaterials();
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
              ),
              textInputAction: TextInputAction.search,
              onSubmitted: _onSearchSubmitted,
              onChanged: (_) => setState(() {}),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: Row(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Wrap(
                      spacing: 8,
                      children: _typeFilters.map((type) {
                        final isSelected = _selectedType == type;
                        return FilterChip(
                          label: Text(type),
                          selected: isSelected,
                          onSelected: (_) => _onTypeFilterChanged(type),
                        );
                      }).toList(),
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (_allTags.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: DropdownButtonFormField<int>(
                value: _selectedTagId,
                decoration: const InputDecoration(
                  labelText: '标签筛选',
                  prefixIcon: Icon(Icons.label_outline),
                  border: OutlineInputBorder(),
                  isDense: true,
                  contentPadding: EdgeInsets.symmetric(vertical: 8),
                ),
                items: [
                  const DropdownMenuItem<int>(
                    value: null,
                    child: Text('全部标签'),
                  ),
                  ..._allTags.map((tag) => DropdownMenuItem<int>(
                        value: tag.id,
                        child: Text(tag.tagName ?? ''),
                      )),
                ],
                onChanged: _onTagFilterChanged,
              ),
            ),
          const SizedBox(height: 8),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _materials.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.folder_open,
                                size: 80, color: Colors.grey[300]),
                            const SizedBox(height: 16),
                            Text(
                              '暂无资料',
                              style: TextStyle(
                                  fontSize: 16, color: Colors.grey[500]),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '还没有上传任何学习资料',
                              style: TextStyle(
                                  fontSize: 14, color: Colors.grey[400]),
                            ),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _searchMaterials,
                        child: GridView.builder(
                          padding: const EdgeInsets.all(16),
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            childAspectRatio: 0.72,
                            crossAxisSpacing: 12,
                            mainAxisSpacing: 12,
                          ),
                          itemCount: _materials.length,
                          itemBuilder: (context, index) {
                            final material = _materials[index];
                            return _MaterialCard(
                              material: material,
                              onTap: () => _navigateToDetail(material),
                            );
                          },
                        ),
                      ),
          ),
        ],
      ),
      floatingActionButton: _canUpload
          ? FloatingActionButton(
              onPressed: _navigateToUpload,
              child: const Icon(Icons.upload_file),
            )
          : null,
    );
  }
}

class _MaterialCard extends StatelessWidget {
  final MaterialInfo material;
  final VoidCallback onTap;

  const _MaterialCard({required this.material, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              flex: 3,
              child: _buildCover(),
            ),
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      material.title ?? '',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    if (material.tags != null && material.tags!.isNotEmpty)
                      Wrap(
                        spacing: 4,
                        children: material.tags!
                            .take(2)
                            .map((tag) => Chip(
                                  label: Text(
                                    tag.tagName ?? '',
                                    style: const TextStyle(fontSize: 10),
                                  ),
                                  materialTapTargetSize:
                                      MaterialTapTargetSize.shrinkWrap,
                                  padding: EdgeInsets.zero,
                                  visualDensity: VisualDensity.compact,
                                ))
                            .toList(),
                      ),
                    const Spacer(),
                    Row(
                      children: [
                        Icon(Icons.visibility,
                            size: 14, color: Colors.grey[500]),
                        const SizedBox(width: 2),
                        Text(
                          '${material.viewCount ?? 0}',
                          style: TextStyle(
                              fontSize: 12, color: Colors.grey[500]),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          material.fileSizeLabel,
                          style: TextStyle(
                              fontSize: 12, color: Colors.grey[500]),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCover() {
    if (material.coverUrl != null && material.coverUrl!.isNotEmpty) {
      return Image.network(
        material.coverUrl!,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _buildTypePlaceholder(),
      );
    }
    return _buildTypePlaceholder();
  }

  Widget _buildTypePlaceholder() {
    return Container(
      color: Colors.blue.withValues(alpha: 0.08),
      child: Center(
        child: Icon(
          material.typeIcon,
          size: 48,
          color: Colors.blue,
        ),
      ),
    );
  }
}
