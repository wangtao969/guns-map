# 格洛克手枪 + 子弹 · 安卓应用图标资源包（v2）

设计：纯黑底 + 白色圆环；**格洛克样式手枪居中于圆心**，其正下方为 **1 颗横置手枪子弹（弹头朝右，尺寸明显小于手枪）**。纯白扁平剪影，无渐变、无阴影、无文字。

## 一、放进工程的方式

把本包里的 **`res/` 整个目录**合并进 `app/src/main/`（同名目录合并，不要覆盖你已有的其他资源）：

```
app/src/main/res/
├── mipmap-mdpi/        ic_launcher.png(48)   ic_launcher_round.png
├── mipmap-hdpi/        ic_launcher.png(72)   ic_launcher_round.png
├── mipmap-xhdpi/       ic_launcher.png(96)   ic_launcher_round.png
├── mipmap-xxhdpi/      ic_launcher.png(144)  ic_launcher_round.png
├── mipmap-xxxhdpi/     ic_launcher.png(192)  ic_launcher_round.png
├── mipmap-anydpi-v26/  ic_launcher.xml  ic_launcher_round.xml     ← 自适应图标入口
├── drawable-mdpi … xxxhdpi/
│                       ic_launcher_foreground.png(108/162/216/324/432)
│                       ic_launcher_monochrome.png(同上，Android 13 主题图标用)
└── values/             ic_launcher_colors.xml（#FF000000 背景色）
```

## 二、`AndroidManifest.xml` 配置

```xml
<application
    android:icon="@mipmap/ic_launcher"
    android:roundIcon="@mipmap/ic_launcher_round"
    ... >
```

工程里已有旧的 `ic_launcher` 资源时直接替换文件即可；若 `ic_launcher_background` 与已有颜色重名，改名并同步修改 `res/mipmap-anydpi-v26/*.xml`。

## 三、自适应图标（Adaptive Icon）要点

- 画布 108dp，桌面会用圆形/方角/水滴等蒙版裁切，**只有中间 66dp 圆区一定可见**。
- `ic_launcher_foreground.png` 是**透明底**，圆环直径被压到 66dp 安全区内，黑色背景由 `@color/ic_launcher_background` 提供 → 任何蒙版都不会切到手枪、子弹或圆环。
- 桌面效果预览：`master/preview_adaptive_on_black_1024.png`。

## 四、Android 13+ 主题图标（单色层）

需要系统"主题图标"（跟随壁纸取色）时，把 `optional/` 下两个 xml 覆盖到 `res/mipmap-anydpi-v26/`，它们额外声明：

```xml
<monochrome android:drawable="@drawable/ic_launcher_monochrome" />
```

前提 `compileSdk >= 33`。单色层为纯白剪影 + 亮度透明通道，套色后呈现"色底 + 白色手枪圆环"。

## 五、其他交付物

| 文件 | 用途 |
|---|---|
| `master/icon_master_1024.png` | 母图 1024×1024 |
| `master/icon_master_512.png` / `_256.png` | 常用中间尺寸 |
| `master/play_store_icon_512.png` | Google Play 上架图标 512×512 |
| `res/mipmap-*/ic_launcher_round.png` | Android 7.1 圆形桌面图标（圆环撑满画布） |

生成链路：AI 出母图并按需求修改图形 → 代码清除圆环外的生成水印、按圆环几何重新居中裁切 → 按安卓规范导出各密度 + 透明前景层 + 单色层。图形未经手工重绘，与母图完全一致。

## 六、两点提醒

1. **小尺寸识别**：黑白高对比粗剪影，48px 下主体仍可辨认；会糊的是套筒防滑纹、扳机护圈空隙这类细结构。要极致清晰可再出一版去细纹的简化剪影专供 mdpi/hdpi。
2. **上架审核**：枪支弹药题材在 Google Play 及国内主流商店属敏感内容，可能触发审核拦截或要求补充应用资质说明。这是渠道规则，与图标质量无关。
