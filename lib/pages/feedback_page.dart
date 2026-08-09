import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../services/track_service.dart';
import '../utils/theme.dart';

/// 意见反馈：分类 + 内容 + 联系方式（可选）→ 提交到后台
class FeedbackPage extends StatefulWidget {
  const FeedbackPage({super.key});

  @override
  State<FeedbackPage> createState() => _FeedbackPageState();
}

class _FeedbackPageState extends State<FeedbackPage> {
  static const _categories = {
    'bug': '问题反馈',
    'suggest': '功能建议',
    'content': '内容纠错',
    'other': '其他',
  };

  String _category = 'bug';
  final _contentController = TextEditingController();
  final _contactController = TextEditingController();
  bool _submitting = false;

  @override
  void dispose() {
    _contentController.dispose();
    _contactController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final content = _contentController.text.trim();
    if (content.length < 5) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('反馈内容不少于 5 个字')));
      return;
    }
    if (content.length > 1000) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('反馈内容不能超过 1000 字')));
      return;
    }
    setState(() => _submitting = true);
    TrackService().fire('feedback_submit');
    final ok = await ApiService().submitFeedback(
      category: _category,
      content: content,
      contact: _contactController.text.trim(),
    );
    if (!mounted) return;
    setState(() => _submitting = false);
    if (ok) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('已收到，感谢反馈！')));
      Navigator.of(context).pop();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('网络错误，提交失败，请稍后再试')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('意见反馈')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('反馈类型', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.of(context).ink)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: _categories.entries
                        .map((c) => ChoiceChip(
                              label: Text(c.value,
                                  style: TextStyle(
                                      fontSize: 12,
                                      color: _category == c.key ? Colors.white : AppColors.of(context).ink)),
                              selected: _category == c.key,
                              selectedColor: AppColors.primary,
                              onSelected: (_) => setState(() => _category = c.key),
                            ))
                        .toList(),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('反馈内容', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.of(context).ink)),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _contentController,
                    maxLines: 6,
                    maxLength: 1000,
                    decoration: InputDecoration(
                      hintText: '请描述你遇到的问题或建议（不少于 5 个字）',
                      hintStyle: TextStyle(fontSize: 13, color: AppColors.of(context).inkLight),
                      filled: true,
                      fillColor: AppColors.of(context).bg,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('联系方式（可选）', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.of(context).ink)),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _contactController,
                    decoration: InputDecoration(
                      hintText: 'QQ / 邮箱，方便我们联系你',
                      hintStyle: TextStyle(fontSize: 13, color: AppColors.of(context).inkLight),
                      filled: true,
                      fillColor: AppColors.of(context).bg,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          FilledButton(
            onPressed: _submitting ? null : _submit,
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.primary,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: _submitting
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : const Text('提交反馈', style: TextStyle(fontSize: 15)),
          ),
        ],
      ),
    );
  }
}
