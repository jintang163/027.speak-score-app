import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:speak_score_flutter/models/material_info.dart';
import 'package:speak_score_flutter/screens/material/video_player_screen.dart';
import 'package:speak_score_flutter/services/auth_service.dart';
import 'package:speak_score_flutter/services/material_service.dart';

class MaterialDetailScreen extends StatefulWidget {
  final int materialId;

  const MaterialDetailScreen({super.key, required this.materialId});

  @override
  State<MaterialDetailScreen> createState() => _MaterialDetailScreenState();
}

class _MaterialDetailScreenState extends State<MaterialDetailScreen> {
  final _materialService = MaterialService();
  final _commentController = TextEditingController();

  MaterialInfo? _material;
  bool _isLoading = true;
  bool _isReviewing = false;
  bool _isDeleting = false;

  @override
  void initState() {
    super.initState();
    _loadDetail();
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _loadDetail() async {
    setState(() => _isLoading = true);
    try {
      final detail =
          await _materialService.getMaterialDetail(widget.materialId);
      if (mounted) {
        setState(() {
          _material = detail;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _isLoading = false);
        _showError('加载资料详情失败');
      }
    }
  }

  bool get _isEduOffice {
    final roles = context.read<AuthService>().userInfo?.roles ?? [];
    return roles.contains('EDU_OFFICE');
  }

  bool get _isUploader {
    final userId = context.read<AuthService>().userInfo?.id;
    return _material?.uploaderId != null && _material!.uploaderId == userId;
  }

  Future<void> _reviewMaterial(String action) async {
    setState(() => _isReviewing = true);
    try {
      final comment = _commentController.text.trim();
      final success = await _materialService.reviewMaterial(
        widget.materialId,
        action,
        comment: comment.isEmpty ? null : comment,
      );
      if (mounted) {
        setState(() => _isReviewing = false);
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text(action == 'APPROVE' ? '审核通过' : '已拒绝'),
                backgroundColor: Colors.green),
          );
          _loadDetail();
        } else {
          _showError('审核操作失败');
        }
      }
    } catch (_) {
      if (mounted) {
        setState(() => _isReviewing = false);
        _showError('审核操作失败');
      }
    }
  }

  Future<void> _deleteMaterial() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('确认删除'),
        content: const Text('确定要删除这个资料吗？此操作不可撤销。'),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('取消')),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('删除', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _isDeleting = true);
    try {
      final success =
          await _materialService.deleteMaterial(widget.materialId);
      if (mounted) {
        setState(() => _isDeleting = false);
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text('已删除'), backgroundColor: Colors.green),
          );
          Navigator.of(context).pop();
        } else {
          _showError('删除失败');
        }
      }
    } catch (_) {
      if (mounted) {
        setState(() => _isDeleting = false);
        _showError('删除失败');
      }
    }
  }

  void _openVideoPlayer() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => VideoPlayerScreen(materialId: widget.materialId),
      ),
    );
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
        title: Text(_material?.title ?? '资料详情'),
        actions: [
          if (_isUploader && !_isDeleting)
            IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.red),
              onPressed: _deleteMaterial,
            ),
          if (_isUploader && _isDeleting)
            const Padding(
              padding: EdgeInsets.all(16),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _material == null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.error_outline,
                          size: 64, color: Colors.grey[400]),
                      const SizedBox(height: 16),
                      Text('加载失败',
                          style: TextStyle(
                              fontSize: 16, color: Colors.grey[500])),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadDetail,
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildPreviewSection(),
                        const SizedBox(height: 16),
                        _buildInfoSection(),
                        const SizedBox(height: 16),
                        if (_isEduOffice) _buildReviewSection(),
                      ],
                    ),
                  ),
                ),
    );
  }

  Widget _buildPreviewSection() {
    switch (_material!.materialType) {
      case 'VIDEO':
        return GestureDetector(
          onTap: _openVideoPlayer,
          child: Stack(
            alignment: Alignment.center,
            children: [
              AspectRatio(
                aspectRatio: 16 / 9,
                child: Container(
                  color: Colors.black,
                  child: _material!.coverUrl != null
                      ? Image.network(
                          _material!.coverUrl!,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => const Center(
                            child: Icon(Icons.play_circle_filled,
                                size: 64, color: Colors.white70),
                          ),
                        )
                      : const Center(
                          child: Icon(Icons.play_circle_filled,
                              size: 64, color: Colors.white70),
                        ),
                ),
              ),
              Container(
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.3),
                  shape: BoxShape.circle,
                ),
                padding: const EdgeInsets.all(16),
                child: const Icon(Icons.play_arrow,
                    size: 48, color: Colors.white),
              ),
            ],
          ),
        );
      case 'PDF':
        return SizedBox(
          width: double.infinity,
          child: FilledButton.icon(
            onPressed: () {
              _showError('PDF预览功能开发中');
            },
            icon: const Icon(Icons.picture_as_pdf),
            label: const Text('打开PDF文件'),
          ),
        );
      case 'IMAGE':
        return ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: _material!.fileUrl != null
              ? Image.network(
                  _material!.fileUrl!,
                  fit: BoxFit.contain,
                  errorBuilder: (_, __, ___) => Container(
                    height: 200,
                    color: Colors.grey[200],
                    child: const Center(
                      child: Icon(Icons.broken_image,
                          size: 64, color: Colors.grey),
                    ),
                  ),
                )
              : Container(
                  height: 200,
                  color: Colors.grey[200],
                  child: const Center(
                    child: Icon(Icons.image, size: 64, color: Colors.grey),
                  ),
                ),
        );
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildInfoSection() {
    final m = _material!;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    m.title ?? '',
                    style: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
                _buildTypeBadge(m.materialType),
              ],
            ),
            const SizedBox(height: 8),
            if (m.description != null && m.description!.isNotEmpty) ...[
              Text(
                m.description!,
                style: TextStyle(fontSize: 14, color: Colors.grey[700]),
              ),
              const SizedBox(height: 12),
            ],
            if (m.tags != null && m.tags!.isNotEmpty)
              Wrap(
                spacing: 6,
                children: m.tags!
                    .map((tag) => Chip(
                          label: Text(tag.tagName ?? '',
                              style: const TextStyle(fontSize: 12)),
                          materialTapTargetSize:
                              MaterialTapTargetSize.shrinkWrap,
                          visualDensity: VisualDensity.compact,
                        ))
                    .toList(),
              ),
            const Divider(height: 24),
            _buildInfoRow(Icons.person, '上传者', m.uploaderName ?? '-'),
            _buildInfoRow(Icons.visibility, '浏览次数', '${m.viewCount ?? 0}'),
            _buildInfoRow(Icons.insert_drive_file, '文件大小', m.fileSizeLabel),
            _buildInfoRow(Icons.school, '学校', m.schoolName ?? '-'),
            if (m.className != null)
              _buildInfoRow(Icons.class_, '班级', m.className!),
            if (m.gradeLevel != null)
              _buildInfoRow(Icons.grade, '年级', '${m.gradeLevel}年级'),
            _buildInfoRow(Icons.access_time, '上传时间', m.createdAt ?? '-'),
            const SizedBox(height: 8),
            _buildReviewStatusBadge(m.reviewStatus),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 18, color: Colors.grey[600]),
          const SizedBox(width: 8),
          Text(label, style: TextStyle(fontSize: 14, color: Colors.grey[600])),
          const Spacer(),
          Text(value, style: const TextStyle(fontSize: 14)),
        ],
      ),
    );
  }

  Widget _buildTypeBadge(String? type) {
    Color color;
    switch (type) {
      case 'VIDEO':
        color = Colors.red;
      case 'PDF':
        color = Colors.orange;
      case 'IMAGE':
        color = Colors.green;
      default:
        color = Colors.blue;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        _material?.typeLabel ?? '资料',
        style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w600),
      ),
    );
  }

  Widget _buildReviewStatusBadge(String? status) {
    Color color;
    String label;
    switch (status) {
      case 'APPROVED':
        color = Colors.green;
        label = '已通过';
      case 'REJECTED':
        color = Colors.red;
        label = '已拒绝';
      default:
        color = Colors.orange;
        label = '待审核';
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.verified, size: 16, color: color),
          const SizedBox(width: 6),
          Text(label, style: TextStyle(color: color, fontSize: 14)),
          if (_material?.reviewComment != null &&
              _material!.reviewComment!.isNotEmpty) ...[
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                '原因: ${_material!.reviewComment}',
                style: TextStyle(color: color, fontSize: 12),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildReviewSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '审核操作',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _commentController,
              decoration: const InputDecoration(
                labelText: '审核意见（可选）',
                border: OutlineInputBorder(),
                hintText: '输入审核意见...',
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: FilledButton.icon(
                    onPressed:
                        _isReviewing ? null : () => _reviewMaterial('APPROVE'),
                    icon: const Icon(Icons.check),
                    label: const Text('通过'),
                    style: FilledButton.styleFrom(
                        backgroundColor: Colors.green),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed:
                        _isReviewing ? null : () => _reviewMaterial('REJECT'),
                    icon: const Icon(Icons.close, color: Colors.red),
                    label: const Text('拒绝',
                        style: TextStyle(color: Colors.red)),
                    style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Colors.red)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
