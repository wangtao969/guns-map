import 'package:flutter/material.dart';
import '../widgets/app_toast.dart';
import '../community_store.dart';
import '../i18n.dart';
import '../widgets/app_top_bar.dart';
import '../widgets/community_theme.dart';
import 'community_account_dialogs.dart';

/// 首次进入社区的引导浮层（一次性 3 步）：
/// 1 选兴趣枪种 → 2 关注 2 个板块 → 3 完成每日签到拿第一枚勋章。
/// 跳过也可以，之后不再打扰（已登录账号会记 onboarded）。
class CommunityOnboardingScreen extends StatefulWidget {
  const CommunityOnboardingScreen({super.key});

  @override
  State<CommunityOnboardingScreen> createState() =>
      _CommunityOnboardingScreenState();
}

class _CommunityOnboardingScreenState
    extends State<CommunityOnboardingScreen> {
  int _step = 0;
  final _interests = <String>{};
  final _boards = <String>{};

  static const _categories = [
    '步枪',
    '手枪',
    '狙击步枪',
    '精确射手步枪',
    '反器材步枪',
    '霰弹枪',
    '冲锋枪',
    '机枪',
  ];

  void _skip() {
    final me = communityStore.current;
    if (me != null) communityStore.skipOnboarding();
    Navigator.of(context).pop();
  }

  void _finish() {
    final me = communityStore.current;
    if (me != null) {
      communityStore.completeOnboarding(
          _interests.toList(), _boards.toList());
    }
    Navigator.of(context).pop();
    showAppToast(context, '欢迎！第一枚勋章已点亮');
  }

  Widget _chip(String label, bool selected, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.only(right: 8, bottom: 8),
      child: ChoiceChip(
        label: Text(label),
        selected: selected,
        selectedColor: const Color(0xFF6B5B3E),
        labelStyle:
            TextStyle(color: selected ? Colors.white : null),
        side: selected
            ? const BorderSide(color: Color(0xFF6B5B3E))
            : null,
        onSelected: (_) => onTap(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final grey = communitySecondary(dark);
    return AnimatedBuilder(
      animation: communityStore,
      builder: (_, __) {
        final me = communityStore.current;
        final canNextStep1 = _interests.isNotEmpty;
        final canNextStep2 = _boards.length >= 2;
        return Scaffold(
          appBar: SubPageAppBar(title: '新手引导'),
          body: ListView(
            padding: const EdgeInsets.all(24),
            children: [
              Row(
                children: [
                  Text('第 ${_step + 1} / 3 步',
                      style: TextStyle(
                          color: grey,
                          fontWeight: FontWeight.bold)),
                  const Spacer(),
                  TextButton(onPressed: _skip, child: const Text('跳过')),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: List.generate(3, (i) {
                  return Expanded(
                    child: Container(
                      height: 4,
                      margin: EdgeInsets.only(right: i < 2 ? 6 : 0),
                      decoration: BoxDecoration(
                        color: i <= _step
                            ? communityAccent
                            : Colors.grey.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  );
                }),
              ),
              const SizedBox(height: 24),
              if (_step == 0) ...[
                const Text('选兴趣枪种',
                    style: TextStyle(
                        fontSize: 22, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Text('挑你感兴趣的品类，推荐内容会先推这些。',
                    style: TextStyle(color: grey)),
                const SizedBox(height: 20),
                Wrap(
                  children: _categories
                      .map((c) => _chip(c, _interests.contains(c), () {
                            setState(() {
                              if (_interests.contains(c)) {
                                _interests.remove(c);
                              } else {
                                _interests.add(c);
                              }
                            });
                          }))
                      .toList(),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: canNextStep1
                        ? () => setState(() => _step = 1)
                        : null,
                    child: const Text('下一步'),
                  ),
                ),
              ] else if (_step == 1) ...[
                const Text('关注 2 个板块',
                    style: TextStyle(
                        fontSize: 22, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Text('关注的板块会出现在首屏“关注”内容流里。',
                    style: TextStyle(color: grey)),
                const SizedBox(height: 20),
                Wrap(
                  children: communityBoards
                      .map((b) => _chip(b, _boards.contains(b), () {
                            setState(() {
                              if (_boards.contains(b)) {
                                _boards.remove(b);
                              } else {
                                _boards.add(b);
                              }
                            });
                          }))
                      .toList(),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => setState(() => _step = 0),
                        child: const Text('上一步'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: canNextStep2
                            ? () => setState(() => _step = 2)
                            : null,
                        child: const Text('下一步'),
                      ),
                    ),
                  ],
                ),
              ] else ...[
                const Text('完成每日签到',
                    style: TextStyle(
                        fontSize: 22, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Text('签到拿第一枚勋章“初来乍到”，之后每天签到都有经验。',
                    style: TextStyle(color: grey)),
                const SizedBox(height: 24),
                if (me == null) ...[
                  const Text('签到需要先登录账号'),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () async {
                            await showLoginDialog(context);
                            setState(() {});
                          },
                          child: Text(tr('login')),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () async {
                            await showRegisterDialog(context);
                            setState(() {});
                          },
                          child: Text(tr('register')),
                        ),
                      ),
                    ],
                  ),
                ] else if (me.checkedInToday) ...[
                  const Text('今天已经签到过了，直接完成引导吧。'),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _finish,
                      child: const Text('完成'),
                    ),
                  ),
                ] else ...[
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        communityStore.checkIn();
                        _finish();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: communityAccent,
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('每日签到，拿第一枚勋章'),
                    ),
                  ),
                ],
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: () => setState(() => _step = 1),
                    child: const Text('上一步'),
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}
