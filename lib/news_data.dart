/// 枪械资讯：公开报道快照（2026-10-25 整理）。
/// 每条都来自公开报道原文链接，点开跳转原文；本页不做实时更新，
/// 标题与摘要只转述报道要点，不编造未证实的价格与上市时间。

class NewsItem {
  /// 厂商 / 机构名。
  final String publisher;

  /// 标题（中文转述）。
  final String title;

  /// 一句话摘要。
  final String summary;

  /// 报道时间（年月精度）。
  final String date;

  /// 'firearm' 枪械厂商 / 'ammo' 弹药商。
  final String category;

  /// 原文链接。
  final String url;

  const NewsItem({
    required this.publisher,
    required this.title,
    required this.summary,
    required this.date,
    required this.category,
    required this.url,
  });
}

const List<NewsItem> newsItems = [
  NewsItem(
    publisher: 'SIG Sauer',
    title: 'SIG Sauer 发布 P385 模块化 9mm 手枪家族',
    summary: 'SIG NEXT 2026 上发布，MACH3D、COMP、FULL、CARRY、COMPACT 五款，沿用 P320 弹匣。',
    date: '2026-09',
    category: 'firearm',
    url:
        'https://particle.news/story/sig-sauer-unveils-p385-a-new-modular-9mm-pistol-family',
  ),
  NewsItem(
    publisher: 'SIG Sauer',
    title: '美军 12 月起列装 SIG M8 步枪，取代 M7',
    summary: 'M8 比 M7 轻约 1 磅、枪管短 3.5 英寸，首批在布拉格堡交付；M250 机枪同用 6.8×51mm 弹。',
    date: '2026-12',
    category: 'firearm',
    url:
        'https://industrialbasealpha.com/article/sig-sauer-m8-rifle-begins-army-fielding-in-december-replacing-m7',
  ),
  NewsItem(
    publisher: 'SIG Sauer',
    title: 'SIG NEXT 2026 新品汇总：HYP 6.8×51 半自动步枪',
    summary: '首款发射 6.8×51mm（.277 Fury）的 AR-10 平台，16 英寸冷锻枪管，另有 MCX-LTAW 一体消音短步枪。',
    date: '2026-09',
    category: 'firearm',
    url:
        'https://gunsweek.com/en/gun-industry/articles/sig-next-2026-sig-sauer-flagship-event',
  ),
  NewsItem(
    publisher: '格洛克',
    title: '格洛克 Gen6 手枪上市：G17 / G19 / G45',
    summary: '全新握把轮廓、平面扳机与新光学瞄具安装系统，2026 年 1 月 20 日上架，MSRP 749 美元。',
    date: '2026-01',
    category: 'firearm',
    url:
        'https://www.ssusa.org/content/glock-s-new-gen6-handgun-lineup-redefines-familiar-territory/',
  ),
  NewsItem(
    publisher: 'Hornady',
    title: 'Hornady 2026 新弹：American Whitetail Tipped 与 .22 Creedmoor',
    summary: '带聚合物弹尖的 SST / FTX 猎鹿弹，覆盖 .243 至 .450 Bushmaster；.22 Creedmoor 新增四款。',
    date: '2026',
    category: 'ammo',
    url:
        'https://www.shootingillustrated.com/content/first-look-new-ammunition-from-hornady/',
  ),
  NewsItem(
    publisher: 'SAAMI / Hornady',
    title: 'SAAMI 通过 5.56 Commercial（5.56 COMM）标准',
    summary: 'Hornady 提交的商用标准，55 格令弹头、初速 3400 fps、最大平均膛压 62000 psi；不等于军用规格。',
    date: '2026-10',
    category: 'ammo',
    url:
        'https://www.thefirearmblog.com/blog/standardizes-the-5-56-commercial-5-56-comm-cartridge-44830963',
  ),
  NewsItem(
    publisher: 'Federal',
    title: 'Federal 2026 新弹：全新 Subsonic 系列等 50 余款',
    summary: '亚音速系列首批含 .30-30、.45-70、.308 与 .300 Blackout；Terminal Ascent 新增 6.5 PRC 等口径。',
    date: '2026-01',
    category: 'ammo',
    url:
        'https://www.thefirearmblog.com/blog/shot-2026-new-federal-rifle-handgun-and-shotgun-ammunition-44825491',
  ),
  NewsItem(
    publisher: 'Winchester',
    title: 'SHOT Show 2026 新弹：Winchester Supreme Long Range',
    summary: '厚壁被甲 + BC Max 弹头的新长程弹，另有 USA 250 周年纪念弹系列；同场还有 CCI 猎用底缘发火弹。',
    date: '2026-01',
    category: 'ammo',
    url: 'https://www.outdoorlife.com/guns/new-ammo-shot-show-2026/',
  ),
];
