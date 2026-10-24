import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../widgets/app_top_bar.dart';

/// 意见反馈：应用内填写 + 联系邮箱。
/// 暂未接后端：反馈只保存在本机当次有效，提交后可以一键复制，
/// 复制出来的文本直接发到聊天里或用邮箱发出去；联系邮箱填你
/// 自己的邮箱，方便回复你。
class FeedbackItem {
final String type;
final String content;
final String email;
final String time;
FeedbackItem({
required this.type,
required this.content,
required this.email,
required this.time,
});

String get shareText {
final mail = email.isEmpty? '未留邮箱': email;
return '类型：$type\n内容：$content\n联系邮箱：$mail\n时间：$time';
}
}

class FeedbackScreen extends StatefulWidget {
const FeedbackScreen({super.key});

@override
State<FeedbackScreen> createState() => _FeedbackScreenState();
}

class _FeedbackScreenState extends State<FeedbackScreen> {
static const _types = ['功能建议', '内容纠错', '闪退报错', '其他'];
String _type = _types.first;
final _contentCtrl = TextEditingController();
final _emailCtrl = TextEditingController(text: 'Toryphoto77@gmail.com');
final _submitted = <FeedbackItem>[];

@override
void dispose() {
_contentCtrl.dispose();
_emailCtrl.dispose();
super.dispose();
}

String _now() {
final n = DateTime.now();
return '${n.month}月${n.day}日 ${n.hour.toString().padLeft(2, '0')}:${n.minute.toString().padLeft(2, '0')}';
}

/// 点邮箱行直接跳转手机邮箱应用：走 gunsmap/mailto 原生通道，
/// 拉 ACTION_SENDTO + mailto 意图；没装邮箱应用时复制邮箱地址。
static const _mailChannel = MethodChannel('gunsmap/mailto');

Future<void> _openMailApp() async {
bool opened = false;
try {
opened = await _mailChannel.invokeMethod<bool>('openMail', {
'email': 'Toryphoto77@gmail.com',
'subject': "Gun's Map 反馈",
'body': _contentCtrl.text.trim(),
}) ??
false;
} catch (_) {
opened = false;
}
if (!mounted) return;
if (!opened) {
await Clipboard.setData(
const ClipboardData(text: 'Toryphoto77@gmail.com'));
ScaffoldMessenger.of(context).showSnackBar(
const SnackBar(content: Text('没有找到邮箱应用，邮箱地址已复制')),
);
}
}

void _submit() {
final content = _contentCtrl.text.trim();
if (content.isEmpty) {
ScaffoldMessenger.of(context).showSnackBar(
const SnackBar(content: Text('请先写反馈内容')),
);
return;
}
setState(() {
_submitted.insert(
0,
FeedbackItem(
type: _type,
content: content,
email: _emailCtrl.text.trim(),
time: _now(),
));
_contentCtrl.clear();
});
ScaffoldMessenger.of(context).showSnackBar(
const SnackBar(content: Text('反馈已记录在本机，可点复制发出去')),
);
}

@override
Widget build(BuildContext context) {
final dark = Theme.of(context).brightness == Brightness.dark;
final grey = dark? const Color(0xFF8A8578): const Color(0xFF9A917F);
return Scaffold(
appBar: const GunsMapAppBar(),
body: ListView(
padding: const EdgeInsets.all(16),
children: [
const Text('意见反馈',
style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
const SizedBox(height: 4),
Text('暂未接后端，反馈只保存在本机当次有效；点复制后可以发到聊天里或用邮箱发到 Toryphoto77@gmail.com。',
style: TextStyle(color: grey, fontSize: 12)),
const SizedBox(height: 16),
Card(
child: ListTile(
leading: const Icon(Icons.mail_outlined),
title: const Text('邮箱反馈'),
subtitle: const Text('Toryphoto77@gmail.com · 点此直接跳转手机邮箱应用'),
trailing: const Icon(Icons.open_in_new, size: 18),
onTap: _openMailApp,
),
),
const SizedBox(height: 16),
const Text('反馈类型',
style: TextStyle(fontWeight: FontWeight.bold)),
const SizedBox(height: 8),
Wrap(
spacing: 8,
children: _types
.map((t) => ChoiceChip(
label: Text(t),
selected: _type == t,
onSelected: (_) => setState(() => _type = t),
))
.toList(),
),
const SizedBox(height: 16),
TextField(
controller: _contentCtrl,
maxLines: 6,
decoration: const InputDecoration(
labelText: '反馈内容',
hintText: '比如：哪个页面有问题、哪条数据不对、想要什么功能',
border: OutlineInputBorder(),
),
),
const SizedBox(height: 12),
TextField(
controller: _emailCtrl,
keyboardType: TextInputType.emailAddress,
decoration: const InputDecoration(
labelText: '联系邮箱（可选）',
hintText: '填你的邮箱，方便回复你',
border: OutlineInputBorder(),
),
),
const SizedBox(height: 16),
ElevatedButton(
onPressed: _submit,
child: const Text('提交反馈'),
),
if (_submitted.isNotEmpty)...[
const SizedBox(height: 24),
const Text('已提交的反馈',
style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
const SizedBox(height: 8),
..._submitted.map((f) => Card(
margin: const EdgeInsets.only(bottom: 10),
child: Padding(
padding: const EdgeInsets.all(14),
child: Column(
crossAxisAlignment: CrossAxisAlignment.start,
children: [
Row(
children: [
Chip(label: Text(f.type)),
const SizedBox(width: 8),
Text(f.time,
style: TextStyle(color: grey, fontSize: 12)),
const Spacer(),
TextButton.icon(
onPressed: () async {
await Clipboard.setData(
ClipboardData(text: f.shareText));
if (!context.mounted) return;
ScaffoldMessenger.of(context).showSnackBar(
const SnackBar(
content: Text('反馈内容已复制')),
);
},
icon: const Icon(Icons.copy, size: 16),
label: const Text('复制'),
),
],
),
const SizedBox(height: 4),
Text(f.content),
if (f.email.isNotEmpty)...[
const SizedBox(height: 4),
Text('联系邮箱：${f.email}',
style: TextStyle(color: grey, fontSize: 12)),
],
],
),
),
)),
],
],
),
);
}
}
