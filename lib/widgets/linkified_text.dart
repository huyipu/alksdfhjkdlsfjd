import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

/// 纯文本中的 http(s) 链接自动转为可点击（外部浏览器打开）
class LinkifiedText extends StatelessWidget {
  final String text;
  final TextStyle style;
  final Color linkColor;

  const LinkifiedText({
    super.key,
    required this.text,
    required this.style,
    this.linkColor = const Color(0xFF9C7A3C),
  });

  static final _urlReg = RegExp(r'https?://[^\s，。；）)】」]+');

  @override
  Widget build(BuildContext context) {
    final spans = <TextSpan>[];
    var last = 0;
    for (final m in _urlReg.allMatches(text)) {
      if (m.start > last) {
        spans.add(TextSpan(text: text.substring(last, m.start)));
      }
      final url = m.group(0)!;
      spans.add(TextSpan(
        text: url,
        style: TextStyle(color: linkColor, decoration: TextDecoration.underline),
        recognizer: TapGestureRecognizer()
          ..onTap = () => launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication),
      ));
      last = m.end;
    }
    if (last < text.length) {
      spans.add(TextSpan(text: text.substring(last)));
    }
    return Text.rich(TextSpan(children: spans), style: style);
  }
}
