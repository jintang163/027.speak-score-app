import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:speak_score_flutter/models/material_info.dart';
import 'package:speak_score_flutter/screens/material/material_detail_screen.dart';
import 'package:speak_score_flutter/services/auth_service.dart';
import 'package:speak_score_flutter/services/material_service.dart';

class MaterialReviewScreen extends StatefulWidget {
  const MaterialReviewScreen({super.key});

  @override
  State<MaterialReviewScreen> createState() => _MaterialReviewScreenState();
}

class _MaterialReviewScreenState extends State<MaterialReviewScreen> {
  final _materialService = MaterialService();

  List<MaterialInfo> _pendingMaterials = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadPendingMaterials();
  }

  Future<void> _loadPendingMaterials() async {
    setState(() => _isLoading = true);
    try {
      final authService = context.read<AuthService>();
      final schoolId = authService.userInfo?.schoolId;
      if (schoolId == null) {
        if (mounted) {
          setState(() => _isLoading = false);
          _showError('无法获取学校信息');
        }
        return;
      }

      final results = await _materialService.getPendingReviewMaterials(schoolId);
      if (mounted) {
        setState(() {
          _pendingMaterials = results;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _isLoading = false);
        _showError('加载审核列表失败');
      }
    }
  }

  void _navigateToDetail(MaterialInfo material) {
    Navigator.of(context)
        .push(
      MaterialPageRoute(
        builder: (_) => MaterialDetailScreen(materialId: material.id!),
      ),
    )
        .then((_) => _loadPendingMaterials());
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  IconData _typeIcon(String? type) {
    switch (type) {
      case 'VIDEO':
        return Icons.play_circle_filled;
      case 'PDF':
        return Icons.picture_as_pdf;
      case 'IMAGE':
        return Icons.image;
      default:
        return Icons.insert_drive_file;
    }
  }

  Color _typeColor(String? type) {
    switch (type) {
      case 'VIDEO':
        return Colors.red;
      case 'PDF':
        return Colors.orange;
      case 'IMAGE':
        return Colors.green;
      default:
        return Colors.blue;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('资料审核'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _pendingMaterials.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.check_circle_outline,
                          size: 80, color: Colors.grey[300]),
                      const SizedBox(height: 16),
                      Text(
                        '暂无待审核资料',
                        style: TextStyle(
                            fontSize: 16, color: Colors.grey[500]),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '所有资料已审核完毕',
                        style: TextStyle(
                            fontSize: 14, color: Colors.grey[400]),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadPendingMaterials,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _pendingMaterials.length,
                    itemBuilder: (context, index) {
                      final material = _pendingMaterials[index];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: InkWell(
                          onTap: () => _navigateToDetail(material),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Row(
                              children: [
                                Container(
                                  width: 48,
                                  height: 48,
                                  decoration: BoxDecoration(
                                    color: _typeColor(material.materialType)
                                        .withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Icon(
                                    _typeIcon(material.materialType),
                                    color:
                                        _typeColor(material.materialType),
                                    size: 28,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        material.title ?? '',
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        material.typeLabel,
                                        style: TextStyle(
                                          fontSize: 13,
                                          color: _typeColor(
                                              material.materialType),
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Row(
                                        children: [
                                          Icon(Icons.person,
                                              size: 14,
                                              color: Colors.grey[500]),
                                          const SizedBox(width: 4),
                                          Text(
                                            material.uploaderName ?? '-',
                                            style: TextStyle(
                                                fontSize: 13,
                                                color: Colors.grey[500]),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 2),
                                      Row(
                                        children: [
                                          Icon(Icons.access_time,
                                              size: 14,
                                              color: Colors.grey[500]),
                                          const SizedBox(width: 4),
                                          Text(
                                            material.createdAt ?? '-',
                                            style: TextStyle(
                                                fontSize: 13,
                                                color: Colors.grey[500]),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                                const Icon(Icons.chevron_right,
                                    color: Colors.grey),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}
