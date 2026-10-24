import 'package:flutter/foundation.dart';

/// 界面语言：简体中文 / 繁体中文 / 英文，设置页切换，仅本次打开期间生效。
/// 注意：枪械、配件、口径、装药等图鉴数据本身仍是中文，翻译的是界面文案。
/// 各页把 Scaffold 包在 ValueListenableBuilder(localeNotifier) 里，切换后即时重译。
const localeHans = 'zh-Hans';
const localeHant = 'zh-Hant';
const localeEn = 'en';

final ValueNotifier<String> localeNotifier = ValueNotifier(localeHans);

const localeNames = <String, String>{
  localeHans: '简体中文',
  localeHant: '繁體中文',
  localeEn: 'English',
};

String tr(String key) {
  final map = _strings[localeNotifier.value] ?? _strings[localeHans]!;
  return map[key] ?? _strings[localeHans]![key] ?? key;
}

/// 8 个固定品类名翻译（数据里的品类字段仍是中文，这里只换显示）。
String trCategory(String category) {
  return _categories[localeNotifier.value]?[category] ?? category;
}

String countText(int n) {
  switch (localeNotifier.value) {
    case localeHant:
      return '$n 款在售';
    case localeEn:
      return '$n models';
    default:
      return '$n 支在售';
  }
}


String fitGunsText(int n) {
  switch (localeNotifier.value) {
    case localeHant:
      return '適用槍械（$n款）';
    case localeEn:
      return 'Fits ($n models)';
    default:
      return '适配枪械（$n款）';
  }
}

String bulletsText(int n) {
  switch (localeNotifier.value) {
    case localeHant:
      return '常見彈頭（$n款）';
    case localeEn:
      return 'Common bullets ($n)';
    default:
      return '常见弹头（$n款）';
  }
}

String atlasCountText(int n) {
  switch (localeNotifier.value) {
    case localeHant:
      return '共 $n 條口徑';
    case localeEn:
      return '$n calibers';
    default:
      return '共 $n 条口径';
  }
}

String suppliersCountText(int n) {
  switch (localeNotifier.value) {
    case localeHant:
      return '彈頭、彈殼、火藥、底火供應商 · 共 $n 條';
    case localeEn:
      return 'Bullet, brass, powder and primer suppliers · $n total';
    default:
      return '弹头、弹壳、火药、底火供应商 · 共 $n 条';
  }
}

String modelsCountText(int n) {
  switch (localeNotifier.value) {
    case localeEn:
      return '$n models';
    default:
      return '$n 款在售';
  }
}

const _categories = <String, Map<String, String>>{
  localeHant: {
    '步枪': '步槍',
    '手枪': '手槍',
    '狙击步枪': '狙擊步槍',
    '精确射手步枪': '精確射手步槍',
    '反器材步枪': '反器材步槍',
    '霰弹枪': '霰彈槍',
    '冲锋枪': '衝鋒槍',
    '机枪': '機槍',
    'search_gun_hint': '搜尋槍械、廠商、口徑…',
    'search_caliber_hint': '搜口徑或彈頭，如 338、XTP、曳光',
    'generic_unbound': '通用配件，未綁定具體槍型',
    'no_guns_for_caliber': '本 App 圖鑑中暫無該口徑槍械',
    'factory_price_note': '美國零售參考價，隨商家批次浮動',
    'atlas_note': '彈頭直徑、彈殼長度與最大全彈長均為 SAAMI/CIP 標準值，點卡片進詳情看彈頭、售價與適用槍械。',
    'sniper_title': '子彈復裝 · 狙擊口徑',
    'sniper_note': '狙擊彈售價高、自己復裝最划算，本板塊只收狙擊步槍常用口徑，按口徑分組。',
    'loads_title': '裝藥表（公開手冊資料）',
    'sop_title': '復裝記錄 · SOP 執行',
    'sop_sub': '按 SOP 步驟打勾，記下每次復裝的實際參數',
    'channel_vendor_suffix': '官網或授權經銷商',
    'no_mail_app': '沒有找到信箱應用，信箱地址已複製',
    'feedback_empty': '請先寫回饋內容',
    'feedback_saved': '回饋已記錄在本機，可點複製發出去',
    'feedback_note': '暫未接後端，回饋只保存在本機當次有效；點複製後可以發到聊天裡或用信箱發到 Toryphoto77@gmail.com。',
    'feedback_mail_sub': 'Toryphoto77@gmail.com · 點此直接跳轉手機信箱應用',
    'feedback_content_label': '回饋內容',
    'feedback_content_hint': '比如：哪個頁面有問題、哪條資料不對、想要什麼功能',
    'feedback_email_label': '聯絡信箱（可選）',
    'feedback_email_hint': '填你的信箱，方便回覆你',
    'feedback_copied': '回饋內容已複製',
    'feedback_email_prefix': '聯絡信箱：',

    'safety_rules': '安全紅線',
    'log_new': '記一則復裝',
    'no_logs': '還沒有記錄',

  },
  localeEn: {
    '步枪': 'Rifle',
    '手枪': 'Handgun',
    '狙击步枪': 'Sniper Rifle',
    '精确射手步枪': 'Designated Marksman Rifle',
    '反器材步枪': 'Anti-Materiel Rifle',
    '霰弹枪': 'Shotgun',
    '冲锋枪': 'Submachine Gun',
    '机枪': 'Machine Gun',
    'search_gun_hint': 'Search guns, makers, calibers…',
    'search_caliber_hint': 'Search calibers or bullets, e.g. 338, XTP, tracer',
    'generic_unbound': 'Universal accessory, not tied to a specific model',
    'no_guns_for_caliber': 'No guns in this caliber in the catalog',
    'factory_price_note': 'US retail reference, varies by seller batch',
    'atlas_note': 'Bullet diameter, case length and max overall length are SAAMI/CIP standard values. Tap a card for bullets, prices and fitting guns.',
    'sniper_title': 'Sniper caliber reloading',
    'sniper_note': 'Sniper ammo is expensive, so handloading pays off most here. This section only covers calibers commonly used in sniper rifles, grouped by caliber.',
    'loads_title': 'Load data (public manuals)',
    'sop_title': 'Reloading log · SOP checklist',
    'sop_sub': 'Check off each SOP step and log the actual parameters of every session',
    'channel_vendor_suffix': ' website or authorized dealers',
    'no_mail_app': 'No mail app found; the email address was copied',
    'feedback_empty': 'Please write your feedback first',
    'feedback_saved': 'Feedback saved locally; tap Copy to send it out',
    'feedback_note': 'No backend yet; feedback stays on this device for this session. After copying, you can paste it into a chat or email it to Toryphoto77@gmail.com.',
    'feedback_mail_sub': 'Toryphoto77@gmail.com · tap to open your mail app',
    'feedback_content_label': 'Feedback',
    'feedback_content_hint': 'E.g. which page has a problem, which entry is wrong, what feature you want',
    'feedback_email_label': 'Contact email (optional)',
    'feedback_email_hint': 'Your email, so we can reply to you',
    'feedback_copied': 'Feedback copied',
    'feedback_email_prefix': 'Contact email: ',

    'safety_rules': 'Safety rules',
    'log_new': 'New log entry',
    'no_logs': 'No entries yet',

  },
};

const _strings = <String, Map<String, String>>{
  localeHans: {
    'tab_catalog': '图鉴',
    'tab_accessories': '配件',
    'tab_reloading': '复装',
    'tab_community': '社区',
    'theme': '主题',
    'theme_system': '跟随系统',
    'theme_system_sub': '白天米白，夜晚黑底白字',
    'theme_light': '浅色',
    'theme_light_sub': '始终使用米白主题',
    'theme_dark': '深色',
    'theme_dark_sub': '始终使用黑底白字主题',
    'theme_note': '主题选择仅在本次打开期间生效，重启后恢复跟随系统。',
    'haptics': '震动反馈',
    'haptics_title': '卡片与导航震动',
    'haptics_sub': '点击卡片、切换底部导航时轻震一下',
    'haptics_note': '震动开关仅在本次打开期间生效，重启后恢复开启。',
    'language': '语言',
    'language_note': '语言选择仅在本次打开期间生效，重启后恢复简体中文。',
    'about': '关于',
    'version_prefix': '安卓枪械图鉴 App · ',
    'version_suffix': ' 正式版（arm64）',
    'check_update': '检查更新',
    'check_update_sub': '联网查询 GitHub 最新 Release，有新版会给出下载链接',
    'feedback': '意见反馈',
    'feedback_sub': '应用内填写反馈，可留联系邮箱',
    'data_note': '数据说明',
    'data_note_body':
        '图鉴与配件数据为公开资料整理；装药数据引自 Hornady、Speer、Nosler、Hodgdon、Vihtavuori、Lyman 等公开手册，各条标注出处；枪械与组件价格为 2026 年 10 月美国零售参考价，随时变动。',
    'id_account': 'GitHub 账号',
    'checking': '正在检查更新…',
    'latest_title': '已是最新版本',
    'latest_body_prefix': '当前版本 v',
    'latest_body_suffix': ' 已是最新。',
    'new_title_prefix': '发现新版本 v',
    'new_empty': '去 Release 页查看更新说明。',
    'close': '关闭',
    'copy_link': '复制下载链接',
    'copied': '下载链接已复制，去浏览器粘贴打开即可',
    'check_failed': '检查失败',
    'check_failed_body': '没能连上 GitHub，请检查网络后重试。',
    'ok': '好的',
    'cancel': '取消',
    'save': '保存',
    'all': '全部',
    'all_categories': '全部品类',
    'all_types': '全部类型',
    'vendor': '厂商',
    'type': '类型',
    'by_category': '按品类',
    'price': '售价',
    'channel': '购买渠道',
    'channel_value': '厂商官网或授权经销商',
    'not_listed': '暂未收录',
    'generic': '通用',
    'intro': '简介',
    'params': '参数',
    'ammo_fit': '适配弹药',
    'accessories_pick': '可选配件',
    'assembled': '已装配',
    'assembled_prefix': '已装配：',
    'preview': '装配预览',
    'auto_rotate': '自动旋转',
    'got_it': '知道了',
    'fit_guns': '适配枪械',
    'factory_price': '工厂弹售价',
    'safety_warn': '安全警告',
    'caliber_atlas': '子弹口径图鉴',
    'more': '更多',
    'suppliers': '组件供应商',
    'source_prefix': '来源：',
    'legends': '停售名枪鉴赏',
    'legend_story': '历史与故事',
    'gun_categories': '枪械品类',
    'prototype_prefix': '原型：',
    'image_credit': '图片来源：Wikimedia Commons，遵循原图许可',
    'community_note': '本地账号与动态仅保存在本机当次有效，暂未联网同步；后续接后端后账号体系直接沿用。',
    'not_logged': '你还没有登录',
    'not_logged_sub': '登录后才能发帖，账号只保存在本机。',
    'login': '登录',
    'register': '注册',
    'logout': '退出',
    'edit_profile': '编辑资料',
    'post_new': '发一条动态',
    'post_title_label': '标题',
    'post_content_label': '内容',
    'publish': '发布',
    'no_posts': '还没有动态',
    'no_posts_sub': '登录后发一条动态，聊聊你的枪械与复装心得',
    'login_required_title': '发帖需要先登录',
    'login_required_body': '登录已有账号，或者注册一个新账号。',
    'register_title': '注册账号',
    'avatar_color': '头像颜色',
    'upload_avatar': '上传头像',
    'use_color_avatar': '用回颜色头像',
    'pick_failed': '未能打开相册或未选图片',
    'nickname_label': '昵称',
    'id_login_hint': 'ID（登录用，不可重复）',
    'id_field': 'ID',
    'password_label': '密码',
    'confirm_password': '确认密码',
    'err_empty': '昵称、ID、密码都不能为空',
    'err_mismatch': '两次密码不一致',
    'err_dup': '这个 ID 已经被注册了',
    'err_login': 'ID 或密码不对',
    'edit_title': '编辑资料',
    'id_fixed_suffix': '（注册后不可改）',
    'post_no_title': '无标题',
    'feedback_type': '反馈类型',
    'feedback_submit': '提交反馈',
    'feedback_mail': '邮箱反馈',
    'feedback_submitted': '已提交的反馈',
    'copy': '复制',
    'feedback_type_feature': '功能建议',
    'feedback_type_content': '内容纠错',
    'feedback_type_crash': '闪退报错',
    'feedback_type_other': '其他',
    'search_gun_hint': '搜索枪械、厂商、口径…',
    'search_caliber_hint': '搜口径或弹头，如 338、XTP、曳光',
    'generic_unbound': '通用配件，未绑定具体枪型',
    'no_guns_for_caliber': '本 App 图鉴中暂无该口径枪械',
    'factory_price_note': '美国零售参考价，随商家批次浮动',
    'atlas_note': '弹头直径、弹壳长度与最大全弹长均为 SAAMI/CIP 标准值，点卡片进详情看弹头、售价与适配枪械。',
    'sniper_title': '子弹复装 · 狙击口径',
    'sniper_note': '狙击弹售价高、自己复装最划算，本板块只收狙击步枪常用口径，按口径分组。',
    'loads_title': '装药表（公开手册数据）',
    'sop_title': '复装记录 · SOP 执行',
    'sop_sub': '按 SOP 步骤打勾，记下每次复装的实际参数',
    'channel_vendor_suffix': '官网或授权经销商',
    'no_mail_app': '没有找到邮箱应用，邮箱地址已复制',
    'feedback_empty': '请先写反馈内容',
    'feedback_saved': '反馈已记录在本机，可点复制发出去',
    'feedback_note': '暂未接后端，反馈只保存在本机当次有效；点复制后可以发到聊天里或用邮箱发到 Toryphoto77@gmail.com。',
    'feedback_mail_sub': 'Toryphoto77@gmail.com · 点此直接跳转手机邮箱应用',
    'feedback_content_label': '反馈内容',
    'feedback_content_hint': '比如：哪个页面有问题、哪条数据不对、想要什么功能',
    'feedback_email_label': '联系邮箱（可选）',
    'feedback_email_hint': '填你的邮箱，方便回复你',
    'feedback_copied': '反馈内容已复制',
    'feedback_email_prefix': '联系邮箱：',

    'safety_rules': '安全红线',
    'log_new': '记一条复装',
    'no_logs': '还没有记录',

  },
  localeHant: {
    'tab_catalog': '圖鑑',
    'tab_accessories': '配件',
    'tab_reloading': '復裝',
    'tab_community': '社區',
    'theme': '主題',
    'theme_system': '跟隨系統',
    'theme_system_sub': '白天米白，夜晚黑底白字',
    'theme_light': '淺色',
    'theme_light_sub': '始終使用米白主題',
    'theme_dark': '深色',
    'theme_dark_sub': '始終使用黑底白字主題',
    'theme_note': '主題選擇僅在本次開啟期間生效，重新啟動後恢復跟隨系統。',
    'haptics': '震動回饋',
    'haptics_title': '卡片與導覽震動',
    'haptics_sub': '點擊卡片、切換底部導覽時輕震一下',
    'haptics_note': '震動開關僅在本次開啟期間生效，重新啟動後恢復開啟。',
    'language': '語言',
    'language_note': '語言選擇僅在本次開啟期間生效，重新啟動後恢復簡體中文。',
    'about': '關於',
    'version_prefix': 'Android 槍械圖鑑 App · ',
    'version_suffix': ' 正式版（arm64）',
    'check_update': '檢查更新',
    'check_update_sub': '連網查詢 GitHub 最新 Release，有新版會給出下載連結',
    'feedback': '意見回饋',
    'feedback_sub': '在應用內填寫回饋，可留聯絡信箱',
    'data_note': '資料說明',
    'data_note_body':
        '圖鑑與配件資料為公開資料整理；裝藥資料引自 Hornady、Speer、Nosler、Hodgdon、Vihtavuori、Lyman 等公開手冊，各條標註出處；槍械與組件價格為 2026 年 10 月美國零售參考價，隨時變動。',
    'id_account': 'GitHub 帳號',
    'checking': '正在檢查更新…',
    'latest_title': '已是最新版本',
    'latest_body_prefix': '目前版本 v',
    'latest_body_suffix': ' 已是最新。',
    'new_title_prefix': '發現新版本 v',
    'new_empty': '前往 Release 頁查看更新說明。',
    'close': '關閉',
    'copy_link': '複製下載連結',
    'copied': '下載連結已複製，前往瀏覽器貼上開啟即可',
    'check_failed': '檢查失敗',
    'check_failed_body': '無法連接 GitHub，請檢查網路後重試。',
    'ok': '好的',
    'cancel': '取消',
    'save': '儲存',
    'all': '全部',
    'all_categories': '全部類別',
    'all_types': '全部類型',
    'vendor': '廠商',
    'type': '類型',
    'by_category': '按類別',
    'price': '售價',
    'channel': '購買管道',
    'channel_value': '廠商官網或授權經銷商',
    'not_listed': '暫未收錄',
    'generic': '通用',
    'intro': '簡介',
    'params': '參數',
    'ammo_fit': '適用彈藥',
    'accessories_pick': '可選配件',
    'assembled': '已裝配',
    'assembled_prefix': '已裝配：',
    'preview': '裝配預覽',
    'auto_rotate': '自動旋轉',
    'got_it': '知道了',
    'fit_guns': '適用槍械',
    'factory_price': '工廠彈售價',
    'safety_warn': '安全警告',
    'caliber_atlas': '子彈口徑圖鑑',
    'more': '更多',
    'suppliers': '組件供應商',
    'source_prefix': '來源：',
    'legends': '停售名槍鑑賞',
    'legend_story': '歷史與故事',
    'gun_categories': '槍械類別',
    'prototype_prefix': '原型：',
    'image_credit': '圖片來源：Wikimedia Commons，遵循原圖授權',
    'community_note': '本地帳號與動態僅保存在本機當次有效，暫未連網同步；後續接後端後帳號體系直接沿用。',
    'not_logged': '你還沒有登入',
    'not_logged_sub': '登入後才能發文，帳號只保存在本機。',
    'login': '登入',
    'register': '註冊',
    'logout': '登出',
    'edit_profile': '編輯資料',
    'post_new': '發一則動態',
    'post_title_label': '標題',
    'post_content_label': '內容',
    'publish': '發布',
    'no_posts': '還沒有動態',
    'no_posts_sub': '登入後發一則動態，聊聊你的槍械與復裝心得',
    'login_required_title': '發文需要先登入',
    'login_required_body': '登入已有帳號，或註冊一個新帳號。',
    'register_title': '註冊帳號',
    'avatar_color': '頭像顏色',
    'upload_avatar': '上傳頭像',
    'use_color_avatar': '改回顏色頭像',
    'pick_failed': '無法開啟相簿或未選擇圖片',
    'nickname_label': '暱稱',
    'id_login_hint': 'ID（登入用，不可重複）',
    'id_field': 'ID',
    'password_label': '密碼',
    'confirm_password': '確認密碼',
    'err_empty': '暱稱、ID、密碼都不能為空',
    'err_mismatch': '兩次密碼不一致',
    'err_dup': '這個 ID 已經被註冊了',
    'err_login': 'ID 或密碼不對',
    'edit_title': '編輯資料',
    'id_fixed_suffix': '（註冊後不可改）',
    'post_no_title': '無標題',
    'feedback_type': '回饋類型',
    'feedback_submit': '提交回饋',
    'feedback_mail': '信箱回饋',
    'feedback_submitted': '已提交的回饋',
    'copy': '複製',
    'feedback_type_feature': '功能建議',
    'feedback_type_content': '內容糾錯',
    'feedback_type_crash': '閃退報錯',
    'feedback_type_other': '其他',
  },
  localeEn: {
    'tab_catalog': 'Catalog',
    'tab_accessories': 'Accessories',
    'tab_reloading': 'Reloading',
    'tab_community': 'Community',
    'theme': 'Theme',
    'theme_system': 'Follow system',
    'theme_system_sub': 'Light paper theme by day, dark theme by night',
    'theme_light': 'Light',
    'theme_light_sub': 'Always use the light theme',
    'theme_dark': 'Dark',
    'theme_dark_sub': 'Always use the dark theme',
    'theme_note':
        'Theme choice applies to this session only and resets to Follow system on restart.',
    'haptics': 'Haptics',
    'haptics_title': 'Card & navigation haptics',
    'haptics_sub': 'Light vibration on card taps and tab switches',
    'haptics_note':
        'Haptics applies to this session only and resets to on on restart.',
    'language': 'Language',
    'language_note':
        'Language applies to this session only and resets to Simplified Chinese on restart.',
    'about': 'About',
    'version_prefix': 'Android firearm catalog app · ',
    'version_suffix': ' release (arm64)',
    'check_update': 'Check for updates',
    'check_update_sub':
        'Check GitHub for the latest release; a download link is provided when an update exists',
    'feedback': 'Feedback',
    'feedback_sub': 'Submit feedback in the app, optionally with a contact email',
    'data_note': 'About the data',
    'data_note_body':
        'Catalog and accessory data is compiled from public sources; load data cites Hornady, Speer, Nosler, Hodgdon, Vihtavuori, Lyman and other public manuals, each entry noting its source; firearm and component prices are US retail references from October 2026 and change over time.',
    'id_account': 'GitHub account',
    'checking': 'Checking for updates…',
    'latest_title': 'Already up to date',
    'latest_body_prefix': 'Version v',
    'latest_body_suffix': ' is already the latest.',
    'new_title_prefix': 'New version v',
    'new_empty': 'See the release page for details.',
    'close': 'Close',
    'copy_link': 'Copy download link',
    'copied': 'Download link copied; paste it in your browser to open it',
    'check_failed': 'Check failed',
    'check_failed_body':
        'Couldn\'t reach GitHub. Please check your connection and try again.',
    'ok': 'OK',
    'cancel': 'Cancel',
    'save': 'Save',
    'all': 'All',
    'all_categories': 'All categories',
    'all_types': 'All types',
    'vendor': 'Maker',
    'type': 'Type',
    'by_category': 'By category',
    'price': 'Price',
    'channel': 'Where to buy',
    'channel_value': 'Maker website or authorized dealers',
    'not_listed': 'Not listed',
    'generic': 'Universal',
    'intro': 'About',
    'params': 'Specs',
    'ammo_fit': 'Compatible ammo',
    'accessories_pick': 'Accessories',
    'assembled': 'Installed',
    'assembled_prefix': 'Installed: ',
    'preview': 'Preview',
    'auto_rotate': 'Auto-rotate',
    'got_it': 'Got it',
    'fit_guns': 'Fits',
    'factory_price': 'Factory ammo price',
    'safety_warn': 'Safety warning',
    'caliber_atlas': 'Caliber atlas',
    'more': 'More',
    'suppliers': 'Component suppliers',
    'source_prefix': 'Source: ',
    'legends': 'Discontinued legends',
    'legend_story': 'History & story',
    'gun_categories': 'Gun categories',
    'prototype_prefix': 'Prototype: ',
    'image_credit': 'Images: Wikimedia Commons, under their original licenses',
    'community_note':
        'Local accounts and posts stay on this device for this session only and are not synced yet; the account system will carry over when a backend is added.',
    'not_logged': 'You\'re not signed in',
    'not_logged_sub': 'Sign in to post. Accounts stay on this device only.',
    'login': 'Sign in',
    'register': 'Register',
    'logout': 'Sign out',
    'edit_profile': 'Edit profile',
    'post_new': 'New post',
    'post_title_label': 'Title',
    'post_content_label': 'Body',
    'publish': 'Publish',
    'no_posts': 'No posts yet',
    'no_posts_sub': 'Sign in and share something about firearms and reloading',
    'login_required_title': 'Sign in to post',
    'login_required_body': 'Sign in to an existing account, or register a new one.',
    'register_title': 'Register',
    'avatar_color': 'Avatar color',
    'upload_avatar': 'Upload avatar',
    'use_color_avatar': 'Use a color avatar',
    'pick_failed': 'Couldn\'t open the gallery, or no image was chosen',
    'nickname_label': 'Nickname',
    'id_login_hint': 'ID (for sign-in, must be unique)',
    'id_field': 'ID',
    'password_label': 'Password',
    'confirm_password': 'Confirm password',
    'err_empty': 'Nickname, ID and password can\'t be empty',
    'err_mismatch': 'Passwords don\'t match',
    'err_dup': 'This ID is already registered',
    'err_login': 'Wrong ID or password',
    'edit_title': 'Edit profile',
    'id_fixed_suffix': ' (can\'t be changed after registration)',
    'post_no_title': 'Untitled',
    'feedback_type': 'Feedback type',
    'feedback_submit': 'Submit feedback',
    'feedback_mail': 'Email feedback',
    'feedback_submitted': 'Submitted feedback',
    'copy': 'Copy',
    'feedback_type_feature': 'Feature suggestion',
    'feedback_type_content': 'Content correction',
    'feedback_type_crash': 'Crash report',
    'feedback_type_other': 'Other',
  },
};
