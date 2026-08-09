import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../services/data_service.dart';
import '../utils/theme.dart';
import 'icon_image.dart';

/// 分享卡片生成与分享（离屏渲染 RepaintBoundary → PNG → 系统分享）
class ShareCards {
  ShareCards._();

  /// 分享装备卡片
  static Future<void> shareEquipment(BuildContext context, Equipment e) {
    return _captureAndShare(
      context,
      EquipmentShareCard(equipment: e),
      'tlbb_equipment_${e.id}.png',
      icon: e.icon,
    );
  }

  /// 分享套装集满成就卡片
  static Future<void> shareAchievement({
    required BuildContext context,
    required String setName,
    required int collected,
    required int total,
  }) {
    return _captureAndShare(
      context,
      AchievementShareCard(setName: setName, collected: collected, total: total),
      'tlbb_set_$setName.png',
    );
  }

  /// 把卡片挂到 Overlay 屏幕外位置渲染一帧，截图存临时目录后调起系统分享
  static Future<void> _captureAndShare(BuildContext context, Widget card, String filename, {String icon = ''}) async {
    final overlay = Overlay.of(context);
    if (icon.isNotEmpty) {
      try {
        await precacheImage(AssetImage(icon), context);
      } catch (_) {}
    }
    if (!context.mounted) return;
    final key = GlobalKey();
    final entry = OverlayEntry(
      builder: (_) => Positioned(
        left: -4000,
        top: 0,
        child: RepaintBoundary(key: key, child: card),
      ),
    );
    overlay.insert(entry);
    try {
      await WidgetsBinding.instance.endOfFrame;
      await Future.delayed(const Duration(milliseconds: 50));
      final boundary = key.currentContext?.findRenderObject();
      if (boundary is! RenderRepaintBoundary) return;
      final image = await boundary.toImage(pixelRatio: 3.0);
      final data = await image.toByteData(format: ui.ImageByteFormat.png);
      if (data == null) return;
      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/$filename');
      await file.writeAsBytes(data.buffer.asUint8List());
      if (!context.mounted) return;
      // iPad 上分享弹窗必须给 sharePositionOrigin（取屏幕中央即可）
      final size = MediaQuery.of(context).size;
      await SharePlus.instance.share(ShareParams(
        files: [XFile(file.path)],
        sharePositionOrigin: Rect.fromCenter(center: Offset(size.width / 2, size.height / 2), width: 1, height: 1),
      ));
    } catch (err) {
      print('share card error: $err');
    } finally {
      entry.remove();
    }
  }
}

/// 装备分享卡片
class EquipmentShareCard extends StatelessWidget {
  final Equipment equipment;

  const EquipmentShareCard({super.key, required this.equipment});

  @override
  Widget build(BuildContext context) {
    final e = equipment;
    final qc = AppColors.qualityColor(e.quality);
    return Container(
      width: 340,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: qc, width: 2),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              IconImage(icon: e.icon, size: 56, fallbackColor: qc, fallback: Icons.shield, radius: 10),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(e.name, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: qc)),
                    const SizedBox(height: 4),
                    Text(
                      '${AppColors.qualityName(e.quality)}${e.slot.isNotEmpty ? ' · ${e.slot}' : ''}${e.level > 0 ? ' · Lv.${e.level}' : ''}',
                      style: const TextStyle(fontSize: 12, color: AppColors.inkLight),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (e.set.isNotEmpty) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(color: AppColors.primaryLight.withOpacity(0.2), borderRadius: BorderRadius.circular(6)),
              child: Text('套装：${e.set}', style: const TextStyle(fontSize: 11, color: AppColors.primary)),
            ),
          ],
          if (e.attrs.isNotEmpty) ...[
            const Divider(height: 24, color: Color(0xFFE0D6C0)),
            ...e.attrs.map((a) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: Text('· $a', style: const TextStyle(fontSize: 13, color: AppColors.ink, height: 1.5)),
                )),
          ],
          if (e.source.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text('出处：${e.source}', style: const TextStyle(fontSize: 11, color: AppColors.inkLight)),
          ],
          const SizedBox(height: 14),
          const _Watermark(),
        ],
      ),
    );
  }
}

/// 套装集满成就分享卡片
class AchievementShareCard extends StatelessWidget {
  final String setName;
  final int collected;
  final int total;

  const AchievementShareCard({super.key, required this.setName, required this.collected, required this.total});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 340,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
      decoration: BoxDecoration(
        gradient: AppColors.bgGradient,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.primary, width: 2),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.emoji_events, size: 44, color: AppColors.primary),
          const SizedBox(height: 8),
          const Text('套装集满', style: TextStyle(fontSize: 13, color: AppColors.inkLight, letterSpacing: 4)),
          const SizedBox(height: 8),
          Text(setName, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.primary)),
          const SizedBox(height: 12),
          Text('已收集 $collected / $total 件', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.ink)),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: const LinearProgressIndicator(
              value: 1,
              minHeight: 8,
              backgroundColor: Color(0xFFE0D6C0),
              valueColor: AlwaysStoppedAnimation(AppColors.primary),
            ),
          ),
          const SizedBox(height: 20),
          const _Watermark(),
        ],
      ),
    );
  }
}

class _Watermark extends StatelessWidget {
  const _Watermark();

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(color: AppColors.accent, borderRadius: BorderRadius.circular(4)),
          child: const Center(
            child: Text('龙',
                style: TextStyle(fontSize: 10, color: Color(0xFFE8D9B0), fontWeight: FontWeight.bold, fontFamilyFallback: ['STKaiti', 'KaiTi', 'SimSun'])),
          ),
        ),
        const SizedBox(width: 6),
        const Text('天龙亿旧 · 经典网游怀旧图鉴', style: TextStyle(fontSize: 11, color: AppColors.inkLight)),
      ],
    );
  }
}
