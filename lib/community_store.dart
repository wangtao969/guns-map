import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// 社区数据层：账号、帖子、评论、通知、私信、草稿、等级、勋章、收藏柜、
/// 靶场成绩全部保存在本机（原生 SharedPreferences，见 gunsmap/prefs 通道），
/// 不联网。接后端时把这里的方法换成接口调用，模型字段直接沿用。
/// 注意：验证码注册、密码找回、鉴权 Token、设备管理、APP 推送这些能力
/// 必须有后端和服务商才成立，本机版不做假流程。

/// 板块：帖子分类。现有 5 个打底，再按图鉴/配件/复装/名枪四个模块补 6 个。
const communityBoards = [
  '综合',
  '晒枪',
  '复装心得',
  '求助问答',
  '资讯',
  '枪械评测',
  '新手入门',
  '配件分享',
  '射击技巧',
  '历史名枪',
  '靶场日记',
];

/// 本机敏感词：发帖时命中直接拦截并提示，不做静默放行。
const sensitiveWords = [
  '赌博',
  '博彩',
  '赌场',
  '贷款',
  '放贷',
  '套现',
  '洗钱',
  '色情',
  '卖淫',
  '嫖娼',
  '毒品',
  '办证',
  '发票',
  '刷单',
  '代购',
];

/// 从正文里解析话题标签：#xxx# 形式。
List<String> parseTags(String content) {
  final tags = <String>[];
  for (final m in RegExp(r'#([^#\s]+)#').allMatches(content)) {
    final t = m.group(1)!;
    if (!tags.contains(t)) tags.add(t);
  }
  return tags;
}

/// 从正文里解析 @ID 提及：@xxx（到空白处为止）。
List<String> parseMentions(String content) {
  final ids = <String>[];
  for (final m in RegExp(r'@([^\s@#]+)').allMatches(content)) {
    final id = m.group(1)!;
    if (!ids.contains(id)) ids.add(id);
  }
  return ids;
}

String? findSensitiveWord(String text) {
  for (final w in sensitiveWords) {
    if (text.contains(w)) return w;
  }
  return null;
}

class CommunityAccount {
  String nickname;
  final String id;
  final String password;
  Color avatarColor;
  Uint8List? avatarBytes;
  String bio;
  /// 角色：user 普通用户 / moderator 版主 / admin 管理员。
  /// 本机版只有本机账号，角色字段为后端预留，权限判断先按本地管理走。
  String role;
  /// 账号状态：active 正常 / muted 禁言（不能发帖评论）/ banned 封禁（不能发帖评论）。
  String status;
  /// 隐私开关：帖子旁是否显示 ID、收藏是否对外可见。
  bool showIdPublic;
  bool favoritesPublic;
  final Set<String> followingIds;

  /// 成长体系（本机版，随账号一起落盘）：
  /// 经验、每日经验、签到日期、收藏柜、靶场成绩、关注板块、兴趣品类、引导。
  int totalXp;
  int dailyXp;
  String dailyXpDate;
  final List<String> checkInDates;
  final List<CollectionItem> collection;
  final List<RangeScore> rangeScores;
  final Set<String> followedBoards;
  final List<String> interests;
  bool onboarded;

  CommunityAccount({
    required this.nickname,
    required this.id,
    required this.password,
    required this.avatarColor,
    this.avatarBytes,
    this.bio = '',
    this.role = 'user',
    this.status = 'active',
    this.showIdPublic = true,
    this.favoritesPublic = true,
    Set<String>? followingIds,
    this.totalXp = 0,
    this.dailyXp = 0,
    this.dailyXpDate = '',
    List<String>? checkInDates,
    List<CollectionItem>? collection,
    List<RangeScore>? rangeScores,
    Set<String>? followedBoards,
    List<String>? interests,
    this.onboarded = false,
  })  : followingIds = followingIds ?? <String>{},
        checkInDates = checkInDates ?? [],
        collection = collection ?? [],
        rangeScores = rangeScores ?? [],
        followedBoards = followedBoards ?? <String>{},
        interests = interests ?? [];

  /// 升到下一级需要的经验：100 + (级数-1)*15。
  static int xpForNextLevel(int level) => 100 + (level - 1) * 15;

  /// 升到 level 级所需的累计经验。
  static int xpForLevel(int level) {
    var sum = 0;
    for (var i = 1; i < level; i++) {
      sum += xpForNextLevel(i);
    }
    return sum;
  }

  /// 当前等级（1–60），只升不降。
  int get level {
    var lv = 1;
    while (lv < 60 && totalXp >= xpForLevel(lv + 1)) {
      lv++;
    }
    return lv;
  }

  /// 本级已攒 / 本级共需。
  int get xpIntoLevel => totalXp - xpForLevel(level);
  int get xpNeedLevel => xpForNextLevel(level);

  /// 段位名与配色：铁灰 1–10 / 铜 11–20 / 银 21–35 / 金 36–48 / 钛 49–55 / 曜石 56–60。
  String get tierName {
    final lv = level;
    if (lv <= 10) return '铁灰';
    if (lv <= 20) return '铜';
    if (lv <= 35) return '银';
    if (lv <= 48) return '金';
    if (lv <= 55) return '钛';
    return '曜石';
  }

  Color get tierColor {
    final lv = level;
    if (lv <= 10) return const Color(0xFF8A8D91);
    if (lv <= 20) return const Color(0xFFB08D57);
    if (lv <= 35) return const Color(0xFFB9C0C7);
    if (lv <= 48) return const Color(0xFFD4A017);
    if (lv <= 55) return const Color(0xFF7FA8BC);
    return const Color(0xFF4A4A5A);
  }

  static String dateKey(DateTime t) =>
      '${t.year}-${t.month.toString().padLeft(2, '0')}-${t.day.toString().padLeft(2, '0')}';

  /// 今日已得经验（跨天自动归零）。
  int get todayXp {
    if (dailyXpDate != dateKey(DateTime.now())) return 0;
    return dailyXp;
  }

  /// 加经验：受每日 120 封顶约束，返回实际到账数。
  int addXp(int amount) {
    final today = dateKey(DateTime.now());
    if (dailyXpDate != today) {
      dailyXpDate = today;
      dailyXp = 0;
    }
    final granted = (amount < 120 - dailyXp) ? amount : (120 - dailyXp);
    if (granted <= 0) return 0;
    dailyXp += granted;
    totalXp += granted;
    return granted;
  }

  bool get checkedInToday => checkInDates.contains(dateKey(DateTime.now()));

  /// 连续签到天数：今天已签从今天往回数，今天没签且昨天签了则从昨天往回数，否则为 0。
  int get checkInStreak {
    final dates = checkInDates.toSet();
    var cursor = DateTime.now();
    if (!dates.contains(dateKey(cursor))) {
      cursor = cursor.subtract(const Duration(days: 1));
      if (!dates.contains(dateKey(cursor))) return 0;
    }
    var streak = 0;
    while (dates.contains(dateKey(cursor))) {
      streak++;
      cursor = cursor.subtract(const Duration(days: 1));
    }
    return streak;
  }

  Map<String, dynamic> toJson() => {
        'nickname': nickname,
        'id': id,
        'password': password,
        'avatarColor': avatarColor.toARGB32(),
        'avatarBytes':
            avatarBytes == null ? null : base64Encode(avatarBytes!),
        'bio': bio,
        'role': role,
        'status': status,
        'showIdPublic': showIdPublic,
        'favoritesPublic': favoritesPublic,
        'followingIds': followingIds.toList(),
        'totalXp': totalXp,
        'dailyXp': dailyXp,
        'dailyXpDate': dailyXpDate,
        'checkInDates': checkInDates,
        'collection': collection.map((c) => c.toJson()).toList(),
        'rangeScores': rangeScores.map((r) => r.toJson()).toList(),
        'followedBoards': followedBoards.toList(),
        'interests': interests,
        'onboarded': onboarded,
      };

  static CommunityAccount fromJson(Map<String, dynamic> j) {
    return CommunityAccount(
      nickname: j['nickname'] as String? ?? '',
      id: j['id'] as String? ?? '',
      password: j['password'] as String? ?? '',
      avatarColor: Color(j['avatarColor'] as int? ?? 0xFF6B5B3E),
      avatarBytes: j['avatarBytes'] == null
          ? null
          : base64Decode(j['avatarBytes'] as String),
      bio: j['bio'] as String? ?? '',
      role: j['role'] as String? ?? 'user',
      status: j['status'] as String? ?? 'active',
      showIdPublic: j['showIdPublic'] as bool? ?? true,
      favoritesPublic: j['favoritesPublic'] as bool? ?? true,
      followingIds: (j['followingIds'] as List? ?? []).cast<String>().toSet(),
      totalXp: j['totalXp'] as int? ?? 0,
      dailyXp: j['dailyXp'] as int? ?? 0,
      dailyXpDate: j['dailyXpDate'] as String? ?? '',
      checkInDates: (j['checkInDates'] as List? ?? []).cast<String>(),
      collection: (j['collection'] as List? ?? [])
          .map((e) => CollectionItem.fromJson(e as Map<String, dynamic>))
          .toList(),
      rangeScores: (j['rangeScores'] as List? ?? [])
          .map((e) => RangeScore.fromJson(e as Map<String, dynamic>))
          .toList(),
      followedBoards: (j['followedBoards'] as List? ?? []).cast<String>().toSet(),
      interests: (j['interests'] as List? ?? []).cast<String>(),
      onboarded: j['onboarded'] as bool? ?? false,
    );
  }
}

/// 收藏柜条目：登记拥有 / 上手过 / 想收集的枪。
class CollectionItem {
  final String gunName;
  final String vendor;
  final String caliber;
  final String category;
  String status; // owned 拥有 / handled 上手过 / wanted 想收集
  final DateTime addedTime;

  CollectionItem({
    required this.gunName,
    required this.vendor,
    required this.caliber,
    required this.category,
    required this.status,
    DateTime? addedTime,
  }) : addedTime = addedTime ?? DateTime.now();

  Map<String, dynamic> toJson() => {
        'gunName': gunName,
        'vendor': vendor,
        'caliber': caliber,
        'category': category,
        'status': status,
        'addedTime': addedTime.toIso8601String(),
      };

  static CollectionItem fromJson(Map<String, dynamic> j) => CollectionItem(
        gunName: j['gunName'] as String? ?? '',
        vendor: j['vendor'] as String? ?? '',
        caliber: j['caliber'] as String? ?? '',
        category: j['category'] as String? ?? '',
        status: j['status'] as String? ?? 'wanted',
        addedTime: DateTime.tryParse(j['addedTime'] as String? ?? '') ??
            DateTime.now(),
      );
}

/// 靶场成绩：分组（弹着散布）、距离、发数，绑定枪种。
class RangeScore {
  final String gunName;
  final int distance;
  final int shots;
  final double groupSize;
  final DateTime date;
  final String note;

  RangeScore({
    required this.gunName,
    required this.distance,
    required this.shots,
    required this.groupSize,
    DateTime? date,
    this.note = '',
  }) : date = date ?? DateTime.now();

  Map<String, dynamic> toJson() => {
        'gunName': gunName,
        'distance': distance,
        'shots': shots,
        'groupSize': groupSize,
        'date': date.toIso8601String(),
        'note': note,
      };

  static RangeScore fromJson(Map<String, dynamic> j) => RangeScore(
        gunName: j['gunName'] as String? ?? '',
        distance: j['distance'] as int? ?? 100,
        shots: j['shots'] as int? ?? 5,
        groupSize: (j['groupSize'] as num? ?? 0).toDouble(),
        date:
            DateTime.tryParse(j['date'] as String? ?? '') ?? DateTime.now(),
        note: j['note'] as String? ?? '',
      );
}

class CommunityComment {
  final String id;
  final String authorId;
  final String authorNickname;
  final Color authorColor;
  final Uint8List? authorAvatar;
  final String content;
  final DateTime time;
  final Set<String> likedBy;

  CommunityComment({
    required this.id,
    required this.authorId,
    required this.authorNickname,
    required this.authorColor,
    this.authorAvatar,
    required this.content,
    required this.time,
    Set<String>? likedBy,
  }) : likedBy = likedBy ?? <String>{};

  Map<String, dynamic> toJson() => {
        'id': id,
        'authorId': authorId,
        'authorNickname': authorNickname,
        'authorColor': authorColor.toARGB32(),
        'authorAvatar':
            authorAvatar == null ? null : base64Encode(authorAvatar!),
        'content': content,
        'time': time.toIso8601String(),
        'likedBy': likedBy.toList(),
      };

  static CommunityComment fromJson(Map<String, dynamic> j) =>
      CommunityComment(
        id: j['id'] as String? ?? '',
        authorId: j['authorId'] as String? ?? '',
        authorNickname: j['authorNickname'] as String? ?? '',
        authorColor: Color(j['authorColor'] as int? ?? 0xFF6B5B3E),
        authorAvatar: j['authorAvatar'] == null
            ? null
            : base64Decode(j['authorAvatar'] as String),
        content: j['content'] as String? ?? '',
        time: DateTime.tryParse(j['time'] as String? ?? '') ?? DateTime.now(),
        likedBy: (j['likedBy'] as List? ?? []).cast<String>().toSet(),
      );
}

class CommunityPost {
  final String id;
  String title;
  String content;
  String board;
  final String authorId;
  final String authorNickname;
  final Color authorColor;
  final Uint8List? authorAvatar;
  final DateTime time;
  final List<Uint8List> images;
  final Set<String> likedBy;
  final Set<String> favoritedBy;
  final List<CommunityComment> comments;
  bool pinned;
  bool essence;
  bool reported;

  CommunityPost({
    required this.id,
    required this.title,
    required this.content,
    required this.board,
    required this.authorId,
    required this.authorNickname,
    required this.authorColor,
    this.authorAvatar,
    required this.time,
    List<Uint8List>? images,
    Set<String>? likedBy,
    Set<String>? favoritedBy,
    List<CommunityComment>? comments,
    this.pinned = false,
    this.essence = false,
    this.reported = false,
  })  : images = images ?? [],
        likedBy = likedBy ?? <String>{},
        favoritedBy = favoritedBy ?? <String>{},
        comments = comments ?? [];

  List<String> get tags => parseTags(content);

  /// 热度：点赞 1 分，评论 2 分，收藏 1 分。
  int get hotScore => likedBy.length + comments.length * 2 + favoritedBy.length;

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'content': content,
        'board': board,
        'authorId': authorId,
        'authorNickname': authorNickname,
        'authorColor': authorColor.toARGB32(),
        'authorAvatar':
            authorAvatar == null ? null : base64Encode(authorAvatar!),
        'time': time.toIso8601String(),
        'images': images.map((b) => base64Encode(b)).toList(),
        'likedBy': likedBy.toList(),
        'favoritedBy': favoritedBy.toList(),
        'comments': comments.map((c) => c.toJson()).toList(),
        'pinned': pinned,
        'essence': essence,
        'reported': reported,
      };

  static CommunityPost fromJson(Map<String, dynamic> j) => CommunityPost(
        id: j['id'] as String? ?? '',
        title: j['title'] as String? ?? '',
        content: j['content'] as String? ?? '',
        board: j['board'] as String? ?? '综合',
        authorId: j['authorId'] as String? ?? '',
        authorNickname: j['authorNickname'] as String? ?? '',
        authorColor: Color(j['authorColor'] as int? ?? 0xFF6B5B3E),
        authorAvatar: j['authorAvatar'] == null
            ? null
            : base64Decode(j['authorAvatar'] as String),
        time: DateTime.tryParse(j['time'] as String? ?? '') ?? DateTime.now(),
        images: (j['images'] as List? ?? [])
            .map((e) => base64Decode(e as String))
            .toList(),
        likedBy: (j['likedBy'] as List? ?? []).cast<String>().toSet(),
        favoritedBy: (j['favoritedBy'] as List? ?? []).cast<String>().toSet(),
        comments: (j['comments'] as List? ?? [])
            .map((e) => CommunityComment.fromJson(e as Map<String, dynamic>))
            .toList(),
        pinned: j['pinned'] as bool? ?? false,
        essence: j['essence'] as bool? ?? false,
        reported: j['reported'] as bool? ?? false,
      );
}

class CommunityNotification {
  final String id;
  final String targetAccountId;
  final String kind; // system / interaction / dm
  final String title;
  final String body;
  final DateTime time;
  final String? postId;
  bool read;

  CommunityNotification({
    required this.id,
    required this.targetAccountId,
    required this.kind,
    required this.title,
    required this.body,
    required this.time,
    this.postId,
    this.read = false,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'targetAccountId': targetAccountId,
        'kind': kind,
        'title': title,
        'body': body,
        'time': time.toIso8601String(),
        'postId': postId,
        'read': read,
      };

  static CommunityNotification fromJson(Map<String, dynamic> j) =>
      CommunityNotification(
        id: j['id'] as String? ?? '',
        targetAccountId: j['targetAccountId'] as String? ?? '',
        kind: j['kind'] as String? ?? 'system',
        title: j['title'] as String? ?? '',
        body: j['body'] as String? ?? '',
        time: DateTime.tryParse(j['time'] as String? ?? '') ?? DateTime.now(),
        postId: j['postId'] as String?,
        read: j['read'] as bool? ?? false,
      );
}

class DirectMessage {
  final String id;
  final String fromId;
  final String toId;
  final String content;
  final DateTime time;

  DirectMessage({
    required this.id,
    required this.fromId,
    required this.toId,
    required this.content,
    required this.time,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'fromId': fromId,
        'toId': toId,
        'content': content,
        'time': time.toIso8601String(),
      };

  static DirectMessage fromJson(Map<String, dynamic> j) => DirectMessage(
        id: j['id'] as String? ?? '',
        fromId: j['fromId'] as String? ?? '',
        toId: j['toId'] as String? ?? '',
        content: j['content'] as String? ?? '',
        time: DateTime.tryParse(j['time'] as String? ?? '') ?? DateTime.now(),
      );
}

class PostDraft {
  String title;
  String content;
  String board;
  PostDraft({this.title = '', this.content = '', this.board = '综合'});

  Map<String, dynamic> toJson() =>
      {'title': title, 'content': content, 'board': board};

  static PostDraft fromJson(Map<String, dynamic> j) => PostDraft(
        title: j['title'] as String? ?? '',
        content: j['content'] as String? ?? '',
        board: j['board'] as String? ?? '综合',
      );
}

/// 单枪精通等级：0 未登记 / 1 了解 / 2 熟悉 / 3 上手 / 4 精通 / 5 权威（本机版不开放）。
const masteryNames = ['', '了解', '熟悉', '上手', '精通', '权威'];

/// 勋章定义：条件用函数算，界面直接拿已获得集合渲染勋章墙。
class MedalDef {
  final String id;
  final String name;
  final String desc;
  final String group;
  final String rarity; // N / R / SR / SSR
  final bool Function(CommunityStore store, CommunityAccount account) test;
  const MedalDef({
    required this.id,
    required this.name,
    required this.desc,
    required this.group,
    required this.rarity,
    required this.test,
  });
}

int _likesReceived(CommunityStore s, CommunityAccount a) {
  var n = 0;
  for (final p in s.posts.where((p) => p.authorId == a.id)) {
    n += p.likedBy.where((id) => id != a.id).length;
  }
  return n;
}

int _postsToday(CommunityStore s, CommunityAccount a) {
  final today = CommunityAccount.dateKey(DateTime.now());
  return s.posts
      .where((p) =>
          p.authorId == a.id &&
          CommunityAccount.dateKey(p.time) == today)
      .length;
}

int _commentsToday(CommunityStore s, CommunityAccount a) {
  final today = CommunityAccount.dateKey(DateTime.now());
  var n = 0;
  for (final p in s.posts) {
    n += p.comments
        .where((c) =>
            c.authorId == a.id &&
            CommunityAccount.dateKey(c.time) == today)
        .length;
  }
  return n;
}

/// 勋章目录（共 28 枚）：签到 4、收藏 4、发帖 3、获赞 3、靶场 3、品类 8、赛季 1、彩蛋 2。
final medalCatalog = <MedalDef>[
  MedalDef(
      id: 'checkin_1',
      name: '初来乍到',
      desc: '完成第一次每日签到',
      group: '签到',
      rarity: 'N',
      test: (s, a) => a.checkInDates.isNotEmpty),
  MedalDef(
      id: 'checkin_3',
      name: '持之以恒',
      desc: '连续签到 3 天',
      group: '签到',
      rarity: 'R',
      test: (s, a) => a.checkInStreak >= 3),
  MedalDef(
      id: 'checkin_7',
      name: '一周不辍',
      desc: '连续签到 7 天',
      group: '签到',
      rarity: 'SR',
      test: (s, a) => a.checkInStreak >= 7),
  MedalDef(
      id: 'checkin_30',
      name: '月度全勤',
      desc: '连续签到 30 天',
      group: '签到',
      rarity: 'SSR',
      test: (s, a) => a.checkInStreak >= 30),
  MedalDef(
      id: 'collect_1',
      name: '第一把',
      desc: '收藏柜登记第 1 把枪',
      group: '收藏',
      rarity: 'N',
      test: (s, a) => a.collection.length >= 1),
  MedalDef(
      id: 'collect_5',
      name: '小有规模',
      desc: '收藏柜登记 5 把枪',
      group: '收藏',
      rarity: 'R',
      test: (s, a) => a.collection.length >= 5),
  MedalDef(
      id: 'collect_20',
      name: '初具军火库',
      desc: '收藏柜登记 20 把枪',
      group: '收藏',
      rarity: 'SR',
      test: (s, a) => a.collection.length >= 20),
  MedalDef(
      id: 'collect_50',
      name: '收藏家',
      desc: '收藏柜登记 50 把枪',
      group: '收藏',
      rarity: 'SSR',
      test: (s, a) => a.collection.length >= 50),
  MedalDef(
      id: 'post_1',
      name: '首帖',
      desc: '发表第 1 条动态',
      group: '发帖',
      rarity: 'N',
      test: (s, a) => s.posts.any((p) => p.authorId == a.id)),
  MedalDef(
      id: 'post_10',
      name: '话痨',
      desc: '发表 10 条动态',
      group: '发帖',
      rarity: 'R',
      test: (s, a) =>
          s.posts.where((p) => p.authorId == a.id).length >= 10),
  MedalDef(
      id: 'post_50',
      name: '笔耕不辍',
      desc: '发表 50 条动态',
      group: '发帖',
      rarity: 'SR',
      test: (s, a) =>
          s.posts.where((p) => p.authorId == a.id).length >= 50),
  MedalDef(
      id: 'like_10',
      name: '初受认可',
      desc: '累计获赞 10 次',
      group: '获赞',
      rarity: 'N',
      test: (s, a) => _likesReceived(s, a) >= 10),
  MedalDef(
      id: 'like_50',
      name: '广受欢迎',
      desc: '累计获赞 50 次',
      group: '获赞',
      rarity: 'R',
      test: (s, a) => _likesReceived(s, a) >= 50),
  MedalDef(
      id: 'like_200',
      name: '社区明星',
      desc: '累计获赞 200 次',
      group: '获赞',
      rarity: 'SR',
      test: (s, a) => _likesReceived(s, a) >= 200),
  MedalDef(
      id: 'range_1',
      name: '首发命中',
      desc: '记录第 1 条靶场成绩',
      group: '靶场',
      rarity: 'N',
      test: (s, a) => a.rangeScores.isNotEmpty),
  MedalDef(
      id: 'range_10',
      name: '靶场常客',
      desc: '记录 10 条靶场成绩',
      group: '靶场',
      rarity: 'R',
      test: (s, a) => a.rangeScores.length >= 10),
  MedalDef(
      id: 'range_50',
      name: '神射手',
      desc: '记录 50 条靶场成绩',
      group: '靶场',
      rarity: 'SR',
      test: (s, a) => a.rangeScores.length >= 50),
  for (final c in [
    '步枪',
    '手枪',
    '狙击步枪',
    '精确射手步枪',
    '反器材步枪',
    '霰弹枪',
    '冲锋枪',
    '机枪'
  ])
    MedalDef(
        id: 'cat_$c',
        name: '$c收藏家',
        desc: '收藏柜登记任意 1 把$c',
        group: '品类',
        rarity: 'R',
        test: (s, a) => a.collection.any((i) => i.category == c)),
  MedalDef(
      id: 'season_joined',
      name: '本季参与者',
      desc: '本赛季完成一次签到',
      group: '赛季',
      rarity: 'SR',
      test: (s, a) {
        final start = s.seasonStartCurrent;
        return a.checkInDates.any((d) {
          final dt = DateTime.tryParse(d);
          return dt != null && !dt.isBefore(start);
        });
      }),
  MedalDef(
      id: 'egg_night',
      name: '夜猫子',
      desc: '在 0 点到 5 点之间发过动态（隐藏勋章）',
      group: '彩蛋',
      rarity: 'SSR',
      test: (s, a) => s.posts
          .any((p) => p.authorId == a.id && p.time.hour < 5)),
  MedalDef(
      id: 'egg_photo',
      name: '有图有真相',
      desc: '发表过带图片的动态（隐藏勋章）',
      group: '彩蛋',
      rarity: 'SSR',
      test: (s, a) => s.posts
          .any((p) => p.authorId == a.id && p.images.isNotEmpty)),
];

/// 社区全局状态（单例）。界面用 AnimatedBuilder 监听它。
class CommunityStore extends ChangeNotifier {
  static const _prefsChannel = MethodChannel('gunsmap/prefs');
  static const _prefsKey = 'community_store_v1';

  final List<CommunityAccount> accounts = [];
  CommunityAccount? current;
  final List<CommunityPost> posts = [];
  final List<CommunityNotification> notifications = [];
  final List<DirectMessage> dms = [];
  PostDraft? draft;

  /// 通知开关：系统 / 互动 / 私信三类可独立开关。
  bool notifySystem = true;
  bool notifyInteraction = true;
  bool notifyDm = true;

  /// 赛季起点（全社区共用一季）；赛季声望按窗口内数据现算。
  DateTime firstSeasonStart = DateTime.now();

  /// 被管理员关闭的板块：关闭后不再出现在板块入口与发帖板块选择里。
  final Set<String> disabledBoards = {};

  /// 赛季长度（天），管理员可调；每日经验封顶 120 固定不变。
  int seasonLengthDays = 70;

  bool _loaded = false;
  int _seq = 0;
  String _nextId() => 'c${DateTime.now().millisecondsSinceEpoch}_${_seq++}';

  CommunityStore() {
    notifications.add(CommunityNotification(
      id: _nextId(),
      targetAccountId: '',
      kind: 'system',
      title: '欢迎来到 Gun’s Map 社区',
      body: '在这里晒装备、聊复装、记靶场成绩、攒勋章；账号、帖子、收藏都保存在本机。',
      time: DateTime.now(),
    ));
  }

  /// 启动时从本机读回数据（main 里 await 调用，带超时兜底）。
  Future<void> init() async {
    try {
      final raw = await _prefsChannel
          .invokeMethod<String>('getString', {'key': _prefsKey}).timeout(
              const Duration(seconds: 2),
              onTimeout: () => null);
      if (raw != null && raw.isNotEmpty) {
        final j = jsonDecode(raw) as Map<String, dynamic>;
        accounts.clear();
        accounts.addAll((j['accounts'] as List? ?? []).map(
            (e) => CommunityAccount.fromJson(e as Map<String, dynamic>)));
        posts.clear();
        posts.addAll((j['posts'] as List? ?? []).map(
            (e) => CommunityPost.fromJson(e as Map<String, dynamic>)));
        notifications.clear();
        notifications.addAll((j['notifications'] as List? ?? []).map((e) =>
            CommunityNotification.fromJson(e as Map<String, dynamic>)));
        dms.clear();
        dms.addAll((j['dms'] as List? ?? []).map(
            (e) => DirectMessage.fromJson(e as Map<String, dynamic>)));
        draft = j['draft'] == null
            ? null
            : PostDraft.fromJson(j['draft'] as Map<String, dynamic>);
        notifySystem = j['notifySystem'] as bool? ?? true;
        notifyInteraction = j['notifyInteraction'] as bool? ?? true;
        notifyDm = j['notifyDm'] as bool? ?? true;
        firstSeasonStart =
            DateTime.tryParse(j['firstSeasonStart'] as String? ?? '') ??
                DateTime.now();
        disabledBoards.clear();
        disabledBoards.addAll(
            (j['disabledBoards'] as List? ?? []).map((e) => e.toString()));
        seasonLengthDays = j['seasonLengthDays'] as int? ?? 70;
        final currentId = j['currentId'] as String?;
        current = currentId == null ? null : findAccount(currentId);
      }
    } catch (_) {
      // 读不到就用默认状态（首条欢迎通知），不阻塞启动。
    }
    _loaded = true;
    notifyListeners();
  }

  Map<String, dynamic> toJson() => {
        'accounts': accounts.map((a) => a.toJson()).toList(),
        'currentId': current?.id,
        'posts': posts.map((p) => p.toJson()).toList(),
        'notifications': notifications.map((n) => n.toJson()).toList(),
        'dms': dms.map((d) => d.toJson()).toList(),
        'draft': draft?.toJson(),
        'notifySystem': notifySystem,
        'notifyInteraction': notifyInteraction,
        'notifyDm': notifyDm,
        'firstSeasonStart': firstSeasonStart.toIso8601String(),
        'disabledBoards': disabledBoards.toList(),
        'seasonLengthDays': seasonLengthDays,
      };

  void _save() {
    if (!_loaded) return;
    try {
      unawaited(_prefsChannel.invokeMethod(
          'setString', {'key': _prefsKey, 'value': jsonEncode(toJson())}));
    } catch (_) {}
  }

  /// 对外显式落盘（草稿编辑退出等不经过 notify 的路径用）。
  void persist() => _save();

  @override
  void notifyListeners() {
    super.notifyListeners();
    _save();
  }

  /// 本赛季起点与剩余天数（70 天一季）。
  DateTime get seasonStartCurrent {
    final elapsed = DateTime.now().difference(firstSeasonStart).inDays;
    if (elapsed < 0) return firstSeasonStart;
    return firstSeasonStart.add(
        Duration(days: (elapsed ~/ seasonLengthDays) * seasonLengthDays));
  }

  int get seasonRemainingDays {
    final elapsed = DateTime.now().difference(firstSeasonStart).inDays;
    if (elapsed < 0) return seasonLengthDays;
    final left = seasonLengthDays - (elapsed % seasonLengthDays);
    return left == 0 ? seasonLengthDays : left;
  }

  /// 赛季声望（本机版）：本赛季签到 10 分/天 + 发帖 5 分/条，现算。
  int seasonPrestige(CommunityAccount a) {
    final start = seasonStartCurrent;
    final checkins = a.checkInDates.where((d) {
      final dt = DateTime.tryParse(d);
      return dt != null && !dt.isBefore(start);
    }).length;
    final postCount = posts
        .where((p) => p.authorId == a.id && !p.time.isBefore(start))
        .length;
    return checkins * 10 + postCount * 5;
  }

  /// 某账号已获得的勋章。
  List<MedalDef> earnedMedals(CommunityAccount a) =>
      medalCatalog.where((m) => m.test(this, a)).toList();

  /// 单枪精通等级（0–4，本机版不开放 5 级权威）。
  int masteryForGun(CommunityAccount a, String gunName) {
    CollectionItem? item;
    for (final c in a.collection) {
      if (c.gunName == gunName) item = c;
    }
    if (item == null) return 0;
    var lv = 1;
    if (item.status == 'handled') lv = 2;
    if (item.status == 'owned') lv = 3;
    if (item.status == 'owned' &&
        (a.rangeScores.any((r) => r.gunName == gunName) ||
            posts.any((p) =>
                p.authorId == a.id &&
                (p.title.contains(gunName) ||
                    p.content.contains(gunName))))) {
      lv = 4;
    }
    return lv;
  }

  /// 每日签到：已签返回 -1，否则 +10 经验并返回到账数。
  int checkIn() {
    final me = current;
    if (me == null || me.checkedInToday) return -1;
    me.checkInDates.add(CommunityAccount.dateKey(DateTime.now()));
    final granted = me.addXp(10);
    notifyListeners();
    return granted;
  }

  void addCollectionItem(CollectionItem item) {
    final me = current;
    if (me == null) return;
    me.collection.removeWhere((c) => c.gunName == item.gunName);
    me.collection.insert(0, item);
    me.addXp(3);
    notifyListeners();
  }

  void removeCollectionItem(String gunName) {
    final me = current;
    if (me == null) return;
    me.collection.removeWhere((c) => c.gunName == gunName);
    notifyListeners();
  }

  void setCollectionStatus(String gunName, String status) {
    final me = current;
    if (me == null) return;
    for (final c in me.collection) {
      if (c.gunName == gunName) c.status = status;
    }
    notifyListeners();
  }

  void addRangeScore(RangeScore score) {
    final me = current;
    if (me == null) return;
    me.rangeScores.insert(0, score);
    me.addXp(5);
    notifyListeners();
  }

  void removeRangeScore(RangeScore score) {
    final me = current;
    if (me == null) return;
    me.rangeScores.remove(score);
    notifyListeners();
  }

  void toggleBoardFollow(String board) {
    final me = current;
    if (me == null) return;
    if (me.followedBoards.contains(board)) {
      me.followedBoards.remove(board);
    } else {
      me.followedBoards.add(board);
    }
    notifyListeners();
  }

  void completeOnboarding(List<String> interests, List<String> boards) {
    final me = current;
    if (me == null) return;
    me.interests
      ..clear()
      ..addAll(interests);
    me.followedBoards
      ..clear()
      ..addAll(boards);
    me.onboarded = true;
    notifyListeners();
  }

  void skipOnboarding() {
    final me = current;
    if (me == null) return;
    me.onboarded = true;
    notifyListeners();
  }

  CommunityAccount? findAccount(String id) {
    for (final a in accounts) {
      if (a.id == id) return a;
    }
    return null;
  }

  CommunityPost? findPost(String id) {
    for (final p in posts) {
      if (p.id == id) return p;
    }
    return null;
  }

  /// 初始管理员账号 ID：用这个 ID 登录即为管理员（本地版规则；正式版由服务器认角色）。
  static const adminBootstrapId = 'wangtao969';

  /// 是否管理员：初始管理员账号，或 role 为 admin 的账号。
  bool get isAdmin =>
      current != null &&
      (current!.id == adminBootstrapId || current!.role == 'admin');

  /// 是否版主（含管理员）：可审核帖子，不能管人员与配置。
  bool get isModerator =>
      current != null && (current!.role == 'moderator' || isAdmin);

  /// 注册：昵称、ID、密码；ID 不可重复。注册成功自动登录。
  /// 返回 null 表示成功，否则返回错误文案。
  String? register({
    required String nickname,
    required String id,
    required String password,
    required Color avatarColor,
    Uint8List? avatarBytes,
  }) {
    if (nickname.isEmpty || id.isEmpty || password.isEmpty) {
      return '昵称、ID、密码都不能为空';
    }
    if (findAccount(id) != null) return '这个 ID 已经被注册了';
    final account = CommunityAccount(
      nickname: nickname,
      id: id,
      password: password,
      avatarColor: avatarColor,
      avatarBytes: avatarBytes,
    );
    accounts.add(account);
    current = account;
    notifyListeners();
    return null;
  }

  /// 登录：ID + 密码对上本机账号才能进。
  String? login({required String id, required String password}) {
    final account = findAccount(id);
    if (account == null || account.password != password) {
      return 'ID 或密码不对';
    }
    current = account;
    notifyListeners();
    return null;
  }

  void logout() {
    current = null;
    notifyListeners();
  }

  /// 发帖：命中敏感词直接返回词本身，调用方弹提示；成功返回 null。
  String? createPost({
    required String title,
    required String content,
    required String board,
    required List<Uint8List> images,
  }) {
    final author = current;
    if (author == null) return '请先登录';
    if (author.status == 'banned') return '账号已被封禁';
    if (author.status == 'muted') return '账号已被禁言';
    if (disabledBoards.contains(board)) return '该板块已关闭';
    final bad = findSensitiveWord(title + content);
    if (bad != null) return bad;
    final post = CommunityPost(
      id: _nextId(),
      title: title.trim().isEmpty ? '无标题' : title.trim(),
      content: content.trim(),
      board: board,
      authorId: author.id,
      authorNickname: author.nickname,
      authorColor: author.avatarColor,
      authorAvatar: author.avatarBytes,
      time: DateTime.now(),
      images: images,
    );
    posts.insert(0, post);
    draft = null;
    // 经验：内容满 20 字才算（水贴不计）；当日首条 +5，之后 +2。
    if (content.trim().length >= 20) {
      final firstToday = _postsToday(this, author) <= 1;
      author.addXp(firstToday ? 5 : 2);
    }
    // @ 到的本机账号收到互动通知。
    for (final mentionedId in parseMentions(content)) {
      if (mentionedId != author.id && findAccount(mentionedId) != null) {
        _notify(
          targetAccountId: mentionedId,
          kind: 'interaction',
          title: '@了你',
          body: '${author.nickname} 在帖子《${post.title}》里 @了你',
          postId: post.id,
        );
      }
    }
    notifyListeners();
    return null;
  }

  void toggleLike(CommunityPost post) {
    final me = current;
    if (me == null) return;
    if (post.likedBy.contains(me.id)) {
      post.likedBy.remove(me.id);
    } else {
      post.likedBy.add(me.id);
      // 获赞给作者 +1（精华不直接给经验，防自授）。
      if (post.authorId != me.id) {
        findAccount(post.authorId)?.addXp(1);
      }
      if (post.authorId != me.id) {
        _notify(
          targetAccountId: post.authorId,
          kind: 'interaction',
          title: '有人点赞了你的帖子',
          body: '${me.nickname} 点赞了《${post.title}》',
          postId: post.id,
        );
      }
    }
    notifyListeners();
  }

  void toggleFavorite(CommunityPost post) {
    final me = current;
    if (me == null) return;
    if (post.favoritedBy.contains(me.id)) {
      post.favoritedBy.remove(me.id);
    } else {
      post.favoritedBy.add(me.id);
    }
    notifyListeners();
  }

  /// 评论：返回敏感词或 null。
  String? addComment(CommunityPost post, String content) {
    final me = current;
    if (me == null) return '请先登录';
    if (me.status == 'banned') return '账号已被封禁';
    if (me.status == 'muted') return '账号已被禁言';
    final bad = findSensitiveWord(content);
    if (bad != null) return bad;
    post.comments.add(CommunityComment(
      id: _nextId(),
      authorId: me.id,
      authorNickname: me.nickname,
      authorColor: me.avatarColor,
      authorAvatar: me.avatarBytes,
      content: content.trim(),
      time: DateTime.now(),
    ));
    // 经验：当日头 3 条评论 +2，之后 +1。
    me.addXp(_commentsToday(this, me) <= 3 ? 2 : 1);
    if (post.authorId != me.id) {
      _notify(
        targetAccountId: post.authorId,
        kind: 'interaction',
        title: '你的帖子有新回复',
        body: '${me.nickname} 回复了《${post.title}》',
        postId: post.id,
      );
    }
    for (final mentionedId in parseMentions(content)) {
      if (mentionedId != me.id &&
          mentionedId != post.authorId &&
          findAccount(mentionedId) != null) {
        _notify(
          targetAccountId: mentionedId,
          kind: 'interaction',
          title: '@了你',
          body: '${me.nickname} 在评论里 @了你',
          postId: post.id,
        );
      }
    }
    notifyListeners();
    return null;
  }

  void toggleCommentLike(CommunityPost post, CommunityComment comment) {
    final me = current;
    if (me == null) return;
    if (comment.likedBy.contains(me.id)) {
      comment.likedBy.remove(me.id);
    } else {
      comment.likedBy.add(me.id);
    }
    notifyListeners();
  }

  void reportPost(CommunityPost post) {
    post.reported = true;
    notifyListeners();
  }

  void setPinned(CommunityPost post, bool pinned) {
    post.pinned = pinned;
    notifyListeners();
  }

  void setEssence(CommunityPost post, bool essence) {
    post.essence = essence;
    notifyListeners();
  }

  void deletePost(CommunityPost post) {
    posts.remove(post);
    notifyListeners();
  }

  /// 人员管理（仅管理员）：改角色 / 改状态；不能改自己，不能改初始管理员。
  /// 返回 null 表示成功，否则返回原因。
  String? setUserRole(CommunityAccount target, String role) {
    if (!isAdmin) return '只有管理员可以管理权限';
    if (target.id == current?.id) return '不能修改自己的权限';
    if (target.id == adminBootstrapId) return '不能修改初始管理员';
    target.role = role;
    notifyListeners();
    return null;
  }

  String? setUserStatus(CommunityAccount target, String status) {
    if (!isAdmin) return '只有管理员可以管理权限';
    if (target.id == current?.id) return '不能修改自己的权限';
    if (target.id == adminBootstrapId) return '不能修改初始管理员';
    target.status = status;
    notifyListeners();
    return null;
  }

  /// 取消举报（管理员/版主）。
  void clearReport(CommunityPost post) {
    post.reported = false;
    notifyListeners();
  }

  /// 板块开关（仅管理员）。
  void setBoardDisabled(String board, bool disabled) {
    if (disabled) {
      disabledBoards.add(board);
    } else {
      disabledBoards.remove(board);
    }
    notifyListeners();
  }

  /// 发布公告（仅管理员）：全站系统通知。
  void publishAnnouncement(String title, String body) {
    notifications.insert(
      0,
      CommunityNotification(
        id: _nextId(),
        targetAccountId: '',
        kind: 'system',
        title: title,
        body: body,
        time: DateTime.now(),
      ),
    );
    notifyListeners();
  }

  /// 删除公告（仅管理员）。
  void deleteAnnouncement(CommunityNotification n) {
    notifications.remove(n);
    notifyListeners();
  }

  void toggleFollow(String targetId) {
    final me = current;
    if (me == null || targetId == me.id) return;
    if (me.followingIds.contains(targetId)) {
      me.followingIds.remove(targetId);
    } else {
      me.followingIds.add(targetId);
      _notify(
        targetAccountId: targetId,
        kind: 'interaction',
        title: '有人关注了你',
        body: '${me.nickname} 关注了你',
      );
    }
    notifyListeners();
  }

  void sendDm(String toId, String content) {
    final me = current;
    if (me == null) return;
    dms.add(DirectMessage(
      id: _nextId(),
      fromId: me.id,
      toId: toId,
      content: content.trim(),
      time: DateTime.now(),
    ));
    _notify(
      targetAccountId: toId,
      kind: 'dm',
      title: '新私信',
      body: '${me.nickname}：${content.trim()}',
    );
    notifyListeners();
  }

  void _notify({
    required String targetAccountId,
    required String kind,
    required String title,
    required String body,
    String? postId,
  }) {
    if (kind == 'system' && !notifySystem) return;
    if (kind == 'interaction' && !notifyInteraction) return;
    if (kind == 'dm' && !notifyDm) return;
    notifications.insert(
      0,
      CommunityNotification(
        id: _nextId(),
        targetAccountId: targetAccountId,
        kind: kind,
        title: title,
        body: body,
        time: DateTime.now(),
        postId: postId,
      ),
    );
  }

  void markNotificationRead(CommunityNotification n) {
    n.read = true;
    notifyListeners();
  }

  void markAllNotificationsRead(String accountId) {
    for (final n in notifications) {
      if (n.targetAccountId == accountId || n.targetAccountId.isEmpty) {
        n.read = true;
      }
    }
    notifyListeners();
  }

  List<CommunityNotification> notificationsFor(String accountId) {
    return notifications
        .where((n) => n.targetAccountId.isEmpty || n.targetAccountId == accountId)
        .toList();
  }

  int unreadCount(String accountId) {
    return notificationsFor(accountId).where((n) => !n.read).length;
  }

  /// 板块热度（纯计算，不改状态）：帖数 × 10 + 各帖热度分之和。
  /// 社区页热聊/排行榜与排行榜页共用。
  int boardHeat(String board) {
    var heat = 0;
    for (final p in posts.where((p) => p.board == board)) {
      heat += 10 + p.hotScore;
    }
    return heat;
  }

  void saveDraft({required String title, required String content, required String board}) {
    if (title.trim().isEmpty && content.trim().isEmpty) {
      draft = null;
    } else {
      draft = PostDraft(title: title, content: content, board: board);
    }
  }

  void clearDraft() {
    draft = null;
    notifyListeners();
  }

  /// 供界面在直接改了账号字段后触发刷新（如编辑资料、通知开关）。
  void refresh() {
    notifyListeners();
  }

  static String formatTime(DateTime t) {
    return '${t.month}月${t.day}日 ${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';
  }
}

/// 头像显示：有上传头像用图片，没有则用颜色圆 + 昵称首字。
Widget communityAvatar({
  required Uint8List? bytes,
  required Color color,
  required String nickname,
  required double radius,
}) {
  if (bytes != null) {
    return CircleAvatar(
      backgroundImage: MemoryImage(bytes),
      radius: radius,
    );
  }
  return CircleAvatar(
    backgroundColor: color,
    foregroundColor: Colors.white,
    radius: radius,
    child: Text(
      nickname.isEmpty ? '枪' : nickname.characters.first,
      style: TextStyle(fontSize: radius * 0.75),
    ),
  );
}

/// 全局单例：本机版状态，App 内各社区页共用。
final communityStore = CommunityStore();
