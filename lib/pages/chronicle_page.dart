import 'package:flutter/material.dart';
import '../services/data_service.dart';
import '../services/track_service.dart';
import '../utils/theme.dart';

/// 版本编年史：竖向时间线，按年份分节
class ChroniclePage extends StatefulWidget {
  const ChroniclePage({super.key});

  @override
  State<ChroniclePage> createState() => _ChroniclePageState();
}

class _ChroniclePageState extends State<ChroniclePage> {
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    TrackService().fire('page_enter:chronicle');
    DataService().load().then((_) {
      if (mounted) setState(() => _loading = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    final list = DataService().chronicle;
    return Scaffold(
      appBar: AppBar(title: const Text('版本编年史')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : list.isEmpty
              ? Center(child: Text('编年史整理中，敬请期待', style: TextStyle(color: AppColors.of(context).inkLight)))
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                  itemCount: list.length,
                  itemBuilder: (_, i) {
                    final e = list[i];
                    final isYearStart = i == 0 || list[i - 1].year != e.year;
                    final isLast = i == list.length - 1 || list[i + 1].year != e.year;
                    return _buildEntry(e, isYearStart: isYearStart, isLastOfYear: isLast);
                  },
                ),
    );
  }

  Widget _buildEntry(ChronicleEntry e, {required bool isYearStart, required bool isLastOfYear}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (isYearStart)
          Padding(
            padding: const EdgeInsets.only(top: 16, bottom: 8),
            child: Text(
              '${e.year}',
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
                fontFamilyFallback: ['STKaiti', 'KaiTi', 'SimSun'],
              ),
            ),
          ),
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 左侧时间轴：圆点 + 竖线
              SizedBox(
                width: 24,
                child: Column(
                  children: [
                    const SizedBox(height: 6),
                    Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        shape: BoxShape.circle,
                        border: Border.all(color: AppColors.primaryLight, width: 2),
                      ),
                    ),
                    if (!isLastOfYear)
                      Expanded(child: Container(width: 2, color: AppColors.primaryLight.withOpacity(0.4))),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              // 右侧内容
              Expanded(
                child: Padding(
                  padding: EdgeInsets.only(bottom: isLastOfYear ? 8 : 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(e.date, style: TextStyle(fontSize: 12, color: AppColors.of(context).inkLight)),
                      const SizedBox(height: 2),
                      Text(e.title, style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.of(context).ink)),
                      if (e.desc.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(e.desc, style: TextStyle(fontSize: 13, color: AppColors.of(context).inkLight, height: 1.6)),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
