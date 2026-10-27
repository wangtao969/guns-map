#!/usr/bin/env python3
"""Gun's Map 数据同步脚本（幂等，可反复跑）：
1) 口径图鉴 fitGuns：从枪械的 caliber + ammo 字段自动推导，与已有名单取并集。
2) 空配件枪：按品类从配件目录补真实配件（厂商前缀 + 目录名）。
3) 配件 fitGuns 反向同步：枪上挂了某配件，就把枪名写进该配件的 fitGuns。
注意：必须限定在各列表区域内处理（2026-10-25 串位教训：状态机不得跨区）。
"""
import re
import sys

P = 'lib/data.dart'
s = open(P, encoding='utf-8').read()

# ---------- 1) fitGuns ----------
guns_region = s[s.index('const List<Gun>'):s.index('const List<AccessoryItem>')]
atlas_region = s[s.index('const List<CaliberInfo>'):s.index('const List<ReloadCaliber>')]
atlas_names = set(re.findall(r"    caliber: '([^']+)'", atlas_region))
ALIASES = {
    '.308 Win': '.308 Winchester', '.308': '.308 Winchester',
    '5.56 NATO': '5.56×45mm', '5.56×45mm NATO': '5.56×45mm',
    '.300 Win Mag': '.300 Winchester Magnum', '.300 WM': '.300 Winchester Magnum',
    '.300 Norma': '.300 Norma Magnum', '300 Norma': '.300 Norma Magnum',
    '6.5 CM': '6.5 Creedmoor', '.338 Lapua': '.338 Lapua Magnum',
    '.338 Norma': '.338 Norma Magnum', '7mm Mag': '7mm Remington Magnum',
    '.300 BLK': '.300 AAC Blackout', '7.62×39': '7.62×39mm',
    '7.62×51mm NATO': '7.62×51mm', '7.62×51': '7.62×51mm',
    '.223 Rem': '.223 Remington', '.30-06': '.30-06 Springfield',
    '9mm': '9×19mm', '.45': '.45 ACP',
    '6.5×55': '6.5×55mm Swedish', '.270 Win': '.270 Winchester',
    '.243 Win': '.243 Winchester', '7mm-08': '7mm-08 Remington',
}

def normalize(c):
    c = c.strip()
    if c in ALIASES:
        return ALIASES[c]
    return c if c in atlas_names else None

fit = {}
for b in re.findall(r"  Gun\((?:.|\n)*?  \),", guns_region):
    nm = re.search(r"    name: '([^']+)'", b)
    if not nm:
        continue
    cals = set()
    cm = re.search(r"    caliber: '([^']+)'", b)
    if cm:
        for part in re.split(r"[/、，,]", cm.group(1)):
            part = part.strip()
            paren = re.search(r"（([^）]+)）", part)
            if paren:
                for sub in re.split(r"[、，,]", paren.group(1)):
                    n = normalize(sub.replace('可改', ''))
                    if n:
                        cals.add(n)
                part = part[:paren.start()].strip()
            n = normalize(part)
            if n:
                cals.add(n)
    am = re.search(r"    ammo: \[([^\]]*)\]", b)
    if am:
        for a in re.findall(r"'([^']+)'", am.group(1)):
            n = normalize(a)
            if n:
                cals.add(n)
    for c in cals:
        fit.setdefault(c, []).append(nm.group(1))

def repl_cal(m):
    block = m.group(0)
    cal = re.search(r"    caliber: '([^']+)'", block).group(1)
    fm = re.search(r"    fitGuns: \[([^\]]*)\]", block)
    existing = re.findall(r"'([^']+)'", fm.group(1)) if fm else []
    merged = existing + [g for g in fit.get(cal, []) if g not in existing]
    return block[:fm.start(1)] + ', '.join(f"'{g}'" for g in merged) + block[fm.end(1):]

new_atlas = re.sub(r"  CaliberInfo\((?:.|\n)*?  \),", repl_cal, atlas_region)
s = s[:s.index('const List<CaliberInfo>')] + new_atlas + s[s.index('const List<ReloadCaliber>'):]
print('fitGuns synced for', len(fit), 'calibers')

# ---------- 2) 空配件补齐 ----------
acc_region = s[s.index('const List<AccessoryItem>'):s.index('const List<CaliberInfo>')]
vendor_of = dict(re.findall(r"    name: '([^']+)',\n    vendor: '([^']+)'", acc_region))

def acc(name):
    return f"{vendor_of[name]} {name}" if name in vendor_of else None

CAT_MAP = {
    '手枪': ['RMR 红点瞄具', 'X300U 战术灯'],
    '冲锋枪': ['Micro T-2 红点瞄具', 'PMAG 30 弹匣', 'Wolfman 消音器'],
    '步枪': ['Razor HD Gen III 1-10 瞄准镜', 'MS4 枪带'],
    '狙击步枪': ['ATACR 瞄准镜', 'BRM-S 两脚架', '5700 Elite 弹道计算器'],
    '精确射手步枪': ['ATACR 瞄准镜', 'BRM-S 两脚架', '5700 Elite 弹道计算器'],
    '反器材步枪': ['ATACR 瞄准镜', '5700 Elite 弹道计算器', 'M4-72 制退器'],
    '霰弹枪': ['M600 战术灯', 'SGA 枪托', 'MS1 枪带'],
    '机枪': ['ACOG 瞄准镜', 'MS4 枪带'],
}
guns_start = s.index('const List<Gun>')
guns_end = s.index('const List<AccessoryItem>')
guns = s[guns_start:guns_end]
filled = [0]

def repl_gun(m):
    block = m.group(0)
    am = re.search(r"    accessories: \[([^\]]*)\]", block)
    if am and am.group(1).strip() == '':
        cat = re.search(r"    category: '([^']+)'", block).group(1)
        cal = re.search(r"    caliber: '([^']+)'", block).group(1)
        names = list(CAT_MAP.get(cat, []))
        if cat == '步枪':
            names.append('PMAG 20 LR/SR Gen M3 弹匣' if ('.308' in cal or '7.62×51' in cal) else 'PMAG 30 弹匣')
        items = [a for a in (acc(n) for n in names) if a]
        if items:
            filled[0] += 1
            return block[:am.start(1)] + ', '.join(f"'{x}'" for x in items) + block[am.end(1):]
    return block

guns = re.sub(r"  Gun\((?:.|\n)*?  \),", repl_gun, guns)
s = s[:guns_start] + guns + s[guns_end:]
print('accessories filled for', filled[0], 'guns')

# ---------- 3) 配件 fitGuns 反向同步 ----------
guns_region2 = s[s.index('const List<Gun>'):s.index('const List<AccessoryItem>')]
gun_acc = []
for b in re.findall(r"  Gun\((?:.|\n)*?  \),", guns_region2):
    nm = re.search(r"    name: '([^']+)'", b)
    am = re.search(r"    accessories: \[([^\]]*)\]", b)
    if nm and am:
        gun_acc.append((nm.group(1), re.findall(r"'([^']+)'", am.group(1))))
acc_start = s.index('const List<AccessoryItem>')
acc_end = s.index('const List<CaliberInfo>')
accs = s[acc_start:acc_end]
rev = [0]

def repl_acc(m):
    block = m.group(0)
    nm = re.search(r"    name: '([^']+)'", block).group(1)
    vn = re.search(r"    vendor: '([^']+)'", block).group(1)
    full = f"{vn} {nm}"
    fm = re.search(r"    fitGuns: \[([^\]]*)\]", block)
    existing = re.findall(r"'([^']+)'", fm.group(1)) if fm else []
    add = [g for g, al in gun_acc if full in al and g not in existing]
    if add:
        rev[0] += len(add)
        return block[:fm.start(1)] + ', '.join(f"'{g}'" for g in existing + add) + block[fm.end(1):]
    return block

accs = re.sub(r"  AccessoryItem\((?:.|\n)*?  \),", repl_acc, accs)
s = s[:acc_start] + accs + s[acc_end:]
print('accessory fitGuns links added:', rev[0])
open(P, 'w', encoding='utf-8').write(s)
print('sync done')
