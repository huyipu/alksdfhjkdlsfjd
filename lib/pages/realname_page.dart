import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/app_config.dart';
import '../services/api_service.dart';
import '../services/track_service.dart';
import '../utils/flow_controller.dart';
import '../utils/prefs.dart';
import '../utils/theme.dart';

/// 实名认证页（移植自 xxddtt_app，主题已适配；校验简化为：姓名≥2字、身份证18位）
class RealnamePage extends StatefulWidget {
  final AppConfig config;
  const RealnamePage({super.key, required this.config});

  @override
  State<RealnamePage> createState() => _RealnamePageState();
}

class _RealnamePageState extends State<RealnamePage> {
  final _nameController = TextEditingController();
  final _idCardController = TextEditingController();
  String? _nameError;
  String? _idCardError;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    TrackService().fire('page_enter:realname');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _idCardController.dispose();
    super.dispose();
  }

  /// 校验姓名：2-20个中文字符或间隔号
  bool _validateName(String value) {
    if (value.isEmpty) {
      setState(() => _nameError = '请输入姓名');
      return false;
    }
    final reg = RegExp(r'^[一-龥·]{2,20}$');
    if (!reg.hasMatch(value)) {
      setState(() => _nameError = '请输入正确的中文姓名（至少2个字）');
      return false;
    }
    setState(() => _nameError = null);
    return true;
  }

  /// 校验身份证号：18位，前17位数字+末位数字或X
  bool _validateIdCard(String value) {
    if (value.isEmpty) {
      setState(() => _idCardError = '请输入身份证号');
      return false;
    }
    final reg = RegExp(r'^\d{17}[\dXx]$');
    if (!reg.hasMatch(value)) {
      setState(() => _idCardError = '身份证号应为18位（末位可为X）');
      return false;
    }
    setState(() => _idCardError = null);
    return true;
  }

  Future<void> _submit() async {
    final name = _nameController.text.trim();
    final idCard = _idCardController.text.trim();
    final nameValid = _validateName(name);
    final idValid = _validateIdCard(idCard);
    if (!nameValid || !idValid) return;

    setState(() => _submitting = true);
    final prefs = Prefs();
    await prefs.setString(Prefs.keyRealnameName, name);
    await prefs.setString(Prefs.keyRealnameIdCard, idCard);
    await prefs.setBool(Prefs.keyRealnameDone, true);
    ApiService().reportStat('realname');
    if (mounted) {
      FlowController().onRealnameDone(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(gradient: AppColors.of(context).bgGradient),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                const SizedBox(height: 40),
                const Icon(Icons.verified_user_outlined, size: 56, color: AppColors.primary),
                const SizedBox(height: 24),
                Text(
                  widget.config.realnameTitle.isNotEmpty
                      ? widget.config.realnameTitle
                      : '实名认证',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: AppColors.of(context).ink,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  widget.config.realnameContent.isNotEmpty
                      ? widget.config.realnameContent
                      : '根据国家法律法规，使用本应用需要进行实名认证。请填写真实信息。',
                  style: TextStyle(
                    fontSize: 14,
                    height: 1.6,
                    color: AppColors.of(context).inkLight,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                // 姓名输入
                TextField(
                  controller: _nameController,
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[一-龥·]')),
                    LengthLimitingTextInputFormatter(20),
                  ],
                  decoration: InputDecoration(
                    labelText: '真实姓名',
                    hintText: '请输入您的真实姓名',
                    errorText: _nameError,
                    prefixIcon: const Icon(Icons.person_outline),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(height: 16),
                // 身份证号输入
                TextField(
                  controller: _idCardController,
                  keyboardType: TextInputType.text,
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[\dXx]')),
                    LengthLimitingTextInputFormatter(18),
                    UpperCaseTextFormatter(),
                  ],
                  decoration: InputDecoration(
                    labelText: '身份证号',
                    hintText: '请输入您的18位身份证号',
                    errorText: _idCardError,
                    prefixIcon: const Icon(Icons.badge_outlined),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  '我们仅用于实名认证，不会泄露您的个人信息',
                  style: TextStyle(fontSize: 12, color: AppColors.of(context).inkLight),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: _submitting ? null : _submit,
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: _submitting
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : const Text('提交认证', style: TextStyle(fontSize: 16)),
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// 自动将输入转为大写（身份证末位X）
class UpperCaseTextFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    return TextEditingValue(
      text: newValue.text.toUpperCase(),
      selection: newValue.selection,
    );
  }
}
