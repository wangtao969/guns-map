import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// 社区本机版数据层：账号、帖子、评论、通知、私信、草稿全部只保存在内存里，
/// 本次打开期间有效，不联网、不落盘。接后端时把这里的方法换成接口调用，
/// 模型字段（角色、板块、标签、置顶/精华、举报、隐私开关）直接沿用。
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
  /// 隐私开关：帖子旁是否显示 ID、收藏是否对外可见。
  bool showIdPublic;
  bool favoritesPublic;
  final Set<String> followingIds;

  CommunityAccount({
    required this.nickname,
    required this.id,
    required this.password,
    required this.avatarColor,
    this.avatarBytes,
    this.bio = '',
    this.role = 'user',
    this.showIdPublic = true,
    this.favoritesPublic = true,
    Set<String>? followingIds,
  }) : followingIds = followingIds ?? <String>{};
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
}

class PostDraft {
  String title;
  String content;
  String board;
  PostDraft({this.title = '', this.content = '', this.board = '综合'});
}

/// 社区全局状态（单例，本机版）。界面用 AnimatedBuilder 监听它。
class CommunityStore extends ChangeNotifier {
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

  int _seq = 0;
  String _nextId() => 'c${DateTime.now().millisecondsSinceEpoch}_${_seq++}';

  CommunityStore() {
    notifications.add(CommunityNotification(
      id: _nextId(),
      targetAccountId: '',
      kind: 'system',
      title: '欢迎来到 Gun’s Map 社区',
      body: '这里是本机版社区：账号、帖子、评论、收藏、私信都只保存在本机当次有效，换设备、重启 App 都会清空；验证码、微信/QQ 登录、推送这些需要后端的功能会在接后端后补上。',
      time: DateTime.now(),
    ));
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
