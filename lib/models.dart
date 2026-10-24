class Gun {
  final String name;
  final String vendor;
  final String category;
  final String caliber;
  final String action;
  final String barrel;
  final String length;
  final String weight;
  final String capacity;
  final String origin;
  final String year;
  final String description;
  final String? image;
  final List<String> ammo;
  final List<String> accessories;

  const Gun({
    required this.name,
    required this.vendor,
    required this.category,
    required this.caliber,
    required this.action,
    required this.barrel,
    required this.length,
    required this.weight,
    required this.capacity,
    required this.origin,
    required this.year,
    required this.description,
    this.image,
    required this.ammo,
    required this.accessories,
  });
}

class AccessoryItem {
  final String name;
  final String vendor;
  final String type;
  final String description;
  final List<String> fitGuns;

  const AccessoryItem({
    required this.name,
    required this.vendor,
    required this.type,
    required this.description,
    required this.fitGuns,
  });
}

class CaliberInfo {
  final String caliber;
  final String bulletDiameter;
  final String bulletWeightRange;
  final String use;
  final List<String> fitGuns;

  const CaliberInfo({
    required this.caliber,
    required this.bulletDiameter,
    required this.bulletWeightRange,
    required this.use,
    required this.fitGuns,
  });
}

class ReloadCaliber {
  final String caliber;
  final List<String> bullets;
  final List<String> cases;
  final List<String> powders;
  final List<String> primers;

  const ReloadCaliber({
    required this.caliber,
    required this.bullets,
    required this.cases,
    required this.powders,
    required this.primers,
  });
}

/// 一条装药数据。所有数值字段均须有 Hornady 手册原文出处；
/// 未经核实的字段以“详见手册原文”标示，初速/膛压未引述时为空。
class ReloadLoad {
  final String caliber;
  final String bullet;
  final String powder;
  final String startCharge;
  final String maxCharge;
  final String col;
  final String primer;
  final String brass;
  final String? velocity;
  final String? pressure;
  final String source;

  const ReloadLoad({
    required this.caliber,
    required this.bullet,
    required this.powder,
    required this.startCharge,
    required this.maxCharge,
    required this.col,
    required this.primer,
    required this.brass,
    this.velocity,
    this.pressure,
    required this.source,
  });
}
