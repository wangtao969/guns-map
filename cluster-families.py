#!/usr/bin/env python3
"""把 data.dart 的 738 支枪按枪族聚类，供族系识别图排期用。

规则：按枪名（中英别名归一）命中枪族关键字；命中多条时取第一条，
所以顺序重要：先写容易误判的特例（如霰弹枪里的 M4），再写通用规则。
未命中者按“厂商·品类”兜底，便于人工复核。
输出：family-clusters.json（枪名 -> 族系）与统计。
"""
import json
import re
from collections import Counter, defaultdict

SRC = 'lib/data.dart'


def gun_blocks(s):
    blocks, i = [], 0
    while True:
        j = s.find('Gun(', i)
        if j < 0:
            break
        k, depth, in_str, esc = j + 3, 0, False, False
        while k < len(s):
            ch = s[k]
            if in_str:
                if esc:
                    esc = False
                elif ch == '\\':
                    esc = True
                elif ch == "'":
                    in_str = False
            else:
                if ch == "'":
                    in_str = True
                elif ch == '(':
                    depth += 1
                elif ch == ')':
                    depth -= 1
                    if depth == 0:
                        break
            k += 1
        blocks.append(s[j:k + 1])
        i = k + 1
    return blocks


def field(b, name):
    m = re.search(name + r":\s*'((?:[^'\\]|\\.)*)'", b)
    return m.group(1) if m else ''


def norm(name):
    n = name.upper()
    n = n.replace(' ', '').replace('·', '').replace('-', '').replace('_', '').replace('.', '').replace('/', '')
    n = n.replace('（', '(').replace('）', ')')
    n = re.sub(r'\(.*?\)', '', n)  # 去括号备注
    return n


# (匹配正则, 族系名)，按顺序命中。中文别名与英文原名都写上。
RULES = [
    (r'M4SUPER90|M1014|M4霰弹', '贝内利M4系'),
    (r'MRAD', 'MRAD系'),
    (r'M95|M99', '巴雷特M95/M99系'),
    (r'M82|M107', '巴雷特M82系'),
    (r'P320|M17|M18', 'SIG P320系'),
    (r'P365', 'SIG P365系'),
    (r'P226|P229|P220|P210', 'SIG经典P系'),
    (r'MCX', 'SIG MCX系'),
    (r'SG55|SG553|SG551', 'SG550系'),
    (r'APX', '贝雷塔APX系'),
    (r'PX4', '贝雷塔PX4系'),
    (r'92FS|92/M9|M9', '贝雷塔92系'),
    (r'(?<!SIG516)G3(?![0-9])', 'HK G3系'),
    (r'MR556', 'AR系'),
    (r'SL8', 'G36系'),
    (r'HK45', 'HK45系'),
    (r'MODEL70|M70', '温彻斯特70系'),
    (r'MODEL94|M94', '温彻斯特94系'),
    (r'SXP|SX4', '温彻斯特霰弹系'),
    (r'XBOLT', '勃朗宁X-Bolt系'),
    (r'鲁格57|RUGER57', '鲁格57系'),
    (r'鲁格精准|RUGERPRECISION', '鲁格精准系'),
    (r'SFAR', 'AR系'),
    (r'M&P15|MP15', 'AR系'),
    (r'STAG15', 'AR系'),
    (r'DDM4|DD5', 'AR系'),
    (r'POF', 'AR系'),
    (r'ZION|锡安|ARAD|阿拉德|卡梅尔', 'AR系'),
    (r'SAINT|圣徒', 'AR系'),
    (r'MSR10', 'AR系'),
    (r'M1A(?![0-9])', 'M14系'),
    (r'M21|M25', 'M14系'),
    (r'M1903', 'M1903系'),
    (r'AK200|AK201|AK202|AK203|AK204|AK205', 'AK-12系'),
    (r'AK308', 'AK系'),
    (r'M21A', 'AK系'),
    (r'M2447|M48', '毛瑟98系'),
    (r'ZH29', 'ZH-29系'),
    (r'VZ98|VZ24|VZ33', '毛瑟98系'),
    (r'(?<!西格)绍尔|(?<!SIG)SAUER', '绍尔系'),
    (r'萨科|SAKO', '萨科系'),
    (r'萨维奇|SAVAGE', '萨维奇系'),
    (r'贝加拉|BERGARA', '贝加拉系'),
    (r'豪威|HOWA|M1500', '豪威1500系'),
    (r'卡迪克斯|CADEX', '卡迪克斯系'),
    (r'CZ600', 'CZ600系'),
    (r'马林336|马林1895|马林1894|MARLIN336|MARLIN1895|MARLIN1894', '马林杠杆系'),
    (r'亨利经典|亨利金童|亨利长程|HENRY', '亨利杠杆系'),
    (r'卡尼克|CANIK', '卡尼克系'),
    (r'金牛座|TAURUS', '金牛座系'),
    (r'蟒蛇|狂蟒|眼镜王蛇|单动陆军', '柯尔特转轮系'),
    (r'FN509|FNX', 'FN手枪系'),
    (r'FN49', 'FN49系'),
    (r'XCR', 'XCR系'),
    (r'精确国际|ACCURACY', '精密国际AW系'),
    (r'^M4(?![0-9])', 'AR系'),
    (r'^(M16|AR15)', 'AR系'),
    (r'M16|AR15', 'AR系'),
    (r'HK416|M27', 'HK416系'),
    (r'HK417', 'HK417系'),
    (r'G36', 'G36系'),
    (r'AK12|AK15|AK19', 'AK-12系'),
    (r'AK74|AK-74|AK105|AK104|AK103|AK102', 'AK-74系'),
    (r'AKM|AK47|AK-47|56式', 'AK系'),
    (r'81式', '81式系'),
    (r'RPK', 'RPK系'),
    (r'赛加|SAIGA', '赛加系'),
    (r'加利尔|GALIL', '加利尔系'),
    (r'格洛克|GLOCK', '格洛克系'),
    (r'M1911|1911', '1911系'),
    (r'贝雷塔|伯莱塔|BERETTA', '贝雷塔系'),
    (r'P225|P228|P230|P232|P239', 'SIG经典P系'),
    (r'SIG516|SIG716', 'AR系'),
    (r'SIG556', 'SG550系'),
    (r'G28|MR762', 'HK417系'),
    (r'PSG1|HK33', 'G3系'),
    (r'VP9|P30', 'HK手枪系'),
    (r'FN15', 'AR系'),
    (r'F2000', 'F2000系'),
    (r'1873|1886|1892', '温彻斯特杠杆系'),
    (r'REC7', 'AR系'),
    (r'M40(?![0-9])|M24狙击', '雷明顿700系'),
    (r'LWRC', 'AR系'),
    (r'SHADOW', 'CZ75系'),
    (r'P10[CF]', 'CZ手枪系'),
    (r'1022', '鲁格10/22系'),
    (r'MINI14|迷你14', 'Mini-14系'),
    (r'AR556', 'AR系'),
    (r'M&P10|MP10', 'AR系'),
    (r'WZ29', '毛瑟98系'),
    (r'BERYL|贝雷尔', 'AK系'),
    (r'GROT|MSBS', 'Grot系'),
    (r'QBZ97', '95式系'),
    (r'QJB95', '95式系'),
    (r'CZ805', 'CZ805系'),
    (r'CZ527', 'CZ527系'),
    (r'L96|精确射手PM|AEMK|AT执法', '精密国际AW系'),
    (r'AR10', 'AR系'),
    (r'SR15|SR25', 'AR系'),
    (r'MK18', 'AR系'),
    (r'DD4', 'AR系'),
    (r'STAG10', 'AR系'),
    (r'LMT', 'AR系'),
    (r'C7A2|C8A3', 'AR系'),
    (r'AKS74', 'AK-74系'),
    (r'AK107', 'AK系'),
    (r'L85', 'L85系'),
    (r'M134|GAU19', '米尼岗系'),
    (r'89式', '89式系'),
    (r'67式', '67式系'),
    (r'M110A1', 'HK417系'),
    (r'M110', 'AR系'),
    (r'L1A1', 'FAL系'),
    (r'PTR91', 'G3系'),
    (r'DPMS', 'AR系'),
    (r'LAR', 'AR系'),
    (r'M468', 'AR系'),
    (r'AK101', 'AK-74系'),
    (r'SV99', 'SV-98系'),
    (r'DP27', 'DP系'),
    (r'SG43', 'SG43系'),
    (r'FG42|42式伞兵', 'FG42系'),
    (r'M1943|M1938|中正式|M49卡宾', '毛瑟98系'),
    (r'M4E1|M5E1', 'AR系'),
    (r'SIG|西格', 'SIG系'),
    (r'CZ75|CZ-75', 'CZ75系'),
    (r'CZ蝎|SCORPION', '蝎式系'),
    (r'瓦尔特|WALTHER', '瓦尔特系'),
    (r'沙漠之鹰|DESERTEAGLE', '沙漠之鹰系'),
    (r'鲁格|RUGER', '鲁格系'),
    (r'史密斯|SMITHWESSON|S&W', '史密斯威森系'),
    (r'柯尔特|COLT', '柯尔特系'),
    (r'HKUSP|USP', 'HK USP系'),
    (r'MP5', 'MP5系'),
    (r'UMP', 'UMP系'),
    (r'乌兹|UZI', '乌兹系'),
    (r'MP7', 'MP7系'),
    (r'P90', 'P90系'),
    (r'汤姆逊|THOMPSON', '汤姆逊系'),
    (r'VECTOR|维克托', 'Vector系'),
    (r'KRISS', 'Vector系'),
    (r'SVD|德拉贡诺夫|DRAGUNOV', 'SVD系'),
    (r'SV98|SV-98', 'SV-98系'),
    (r'VSS|ASVAL', 'VSS/AS Val系'),
    (r'巴雷特|BARRETT', '巴雷特系'),
    (r'MRAD', 'MRAD系'),
    (r'切塔克|CHEYTAC', '切塔克系'),
    (r'麦克米兰|MCMILLAN', '麦克米兰TAC系'),
    (r'TAC50|TAC338|TAC300|TAC308|TAC416', '麦克米兰TAC系'),
    (r'精密国际|ACCURACYINTERNATIONAL|^AW', '精密国际AW系'),
    (r'TRG', 'TRG系'),
    (r'TIKKA|蒂卡', 'Tikka系'),
    (r'雷明顿700|REMINGTON700', '雷明顿700系'),
    (r'雷明顿870|REMINGTON870', '雷明顿870系'),
    (r'雷明顿|REMINGTON', '雷明顿系'),
    (r'莫斯伯格|MOSSBERG', '莫斯伯格系'),
    (r'温彻斯特|WINCHESTER', '温彻斯特系'),
    (r'毛瑟|MAUSER|KAR98|98K', '毛瑟98系'),
    (r'C96|驳壳', 'C96系'),
    (r'莫辛|MOSIN', '莫辛纳甘系'),
    (r'李恩菲尔德|LEEENFIELD|SMLE', '李恩菲尔德系'),
    (r'加兰德|GARAND', '加兰德系'),
    (r'M1卡宾|M1CARBINE', 'M1卡宾系'),
    (r'M14', 'M14系'),
    (r'SKS', 'SKS系'),
    (r'SVT', 'SVT系'),
    (r'PKM|PKP', 'PKM系'),
    (r'M249|MINIMI', 'M249系'),
    (r'M60', 'M60系'),
    (r'MG42|MG3', 'MG42系'),
    (r'MAG|M240', 'MAG系'),
    (r'FAL', 'FAL系'),
    (r'SCAR', 'SCAR系'),
    (r'ACR', 'ACR系'),
    (r'AUG', 'AUG系'),
    (r'FAMAS', 'FAMAS系'),
    (r'TAVOR|塔沃尔', 'Tavor系'),
    (r'95式|QBZ95', '95式系'),
    (r'03式|QBZ03', '03式系'),
    (r'88式|QBU88', '88式系'),
    (r'SG55|SG553|SG551', 'SG550系'),
    (r'贝内利|BENELLI', '贝内利系'),
    (r'勃朗宁|BROWNING', '勃朗宁系'),
    (r'FN', 'FN系'),
    (r'HK', 'HK系'),
    (r'波波沙|PPSH', '波波沙系'),
    (r'司登|STEN', '司登系'),
    (r'斯特林|STERLING', '斯特林系'),
    (r'布伦|BREN', '布伦系'),
    (r'DP28|DP-28', 'DP系'),
    (r'马克沁|MAXIM', '马克沁系'),
    (r'内盖夫|NEGEV', '内盖夫系'),
    (r'KSG', 'KSG系'),
    (r'FIVESEVEN|57', 'Five-seveN系'),
]


VENDOR_FALLBACK = {
    'Accuracy International': '精密国际AW系',
    'Kimber': '金伯系',
    'KelTec': '凯尔特克系',
    'Christensen Arms': '克里斯滕森系',
    'Victrix': '维克特斯系',
    'Seekins Precision': '希金斯系',
    'Q': 'Q系',
    'GA Precision': 'GA系',
    'Steyr': '斯太尔系',
    'Taurus': '金牛座系',
    'Henry': '亨利系',
    'Mauser': '毛瑟98系',
    'Springfield Armory': '春田系',
    'MasterPiece Arms': 'MPA系',
    'Desert Tech': '沙漠科技系',
    'HS Produkt': 'VHS系',
    'CETME': 'CETME系',
    'KBP 仪器设计局': 'KBP系',
    '捷格加廖夫工厂': '捷格加廖夫系',
    'Marlin': '马林系',
    'Walther': '瓦尔特系',
    'Aero Precision': 'Aero系',
    'KAC': 'KAC系',
    'Colt': '柯尔特系',
    'Ruger': '鲁格系',
    'Haenel': '黑内尔系',
    'PGW': 'PGW系',
    'Daniel Defense': '丹尼尔防务系',
    'IWI': 'IWI系',
}


def cluster(name, vendor, category):
    n = norm(name)
    for pat, fam in RULES:
        if re.search(pat, n):
            return fam
    if vendor in VENDOR_FALLBACK:
        return VENDOR_FALLBACK[vendor]
    return f'其他·{vendor}·{category}'


def main():
    s = open(SRC, encoding='utf-8').read()
    mapping, fams = {}, defaultdict(list)
    for b in gun_blocks(s):
        name, vendor, cat = field(b, 'name'), field(b, 'vendor'), field(b, 'category')
        fam = cluster(name, vendor, cat)
        mapping[name] = fam
        fams[fam].append(name)
    json.dump(mapping, open('family-clusters.json', 'w', encoding='utf-8'),
              ensure_ascii=False, indent=1)
    counts = Counter({f: len(v) for f, v in fams.items()})
    print(f'总枪数: {len(mapping)}  族系数: {len(fams)}')
    print(f'命中规则族系: {sum(1 for f in fams if not f.startswith("其他"))} 个，'
          f'覆盖 {sum(len(v) for f, v in fams.items() if not f.startswith("其他"))} 支')
    print('--- 规模前 30 的族系 ---')
    for fam, c in counts.most_common(30):
        print(f'{c:4d}  {fam}  例：{"、".join(fams[fam][:4])}')
    other = {f: v for f, v in fams.items() if f.startswith('其他')}
    print(f'--- 未命中规则：{sum(len(v) for v in other.values())} 支，分 {len(other)} 组 ---')
    for fam, v in sorted(other.items(), key=lambda kv: -len(kv[1]))[:25]:
        print(f'{len(v):4d}  {fam}  例：{"、".join(v[:4])}')
    singles = [f for f, v in fams.items() if len(v) == 1 and not f.startswith('其他')]
    print(f'--- 单支族系（规则命中但仅 1 支）：{len(singles)} 个 ---')
    print('、'.join(f'{f}（{fams[f][0]}）' for f in singles[:40]))


if __name__ == '__main__':
    main()
