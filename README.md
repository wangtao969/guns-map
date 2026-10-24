# Gun's Map

Gun's Map 是一款安卓枪械图鉴 App，三个底部 Tab：

- **图鉴**：按品类浏览枪械（手枪、步枪、狙击步枪、反器材步枪、冲锋枪、机枪、霰弹枪等），列表呈现名称 / 厂家 / 口径 + 侧视图；详情页有可拖动旋转的立体预览、部件热点、参数表、适配弹药与可选配件装配预览。
- **配件**：知名厂商配件目录（制退器、弹匣、瞄准镜、弹道计算器、红外热成像仪等）。
- **复装**：子弹复装手册，按口径列出弹头 / 弹壳 / 火药 / 底火组件。装药数据以厂商公开手册（Hornady 等）为准，不现编。

技术栈：Flutter（Dart），深色主题。包内部名 `firearms_catalog`，应用显示名 Gun's Map。

## 目录结构

```text
lib/                          Dart 源码
  main.dart                   入口（MaterialApp，标题 Gun's Map）
  models.dart                 数据模型
  data.dart                   品类 / 枪械 / 配件 / 复装组件数据
  screens/                    五个界面：图鉴、枪械列表、枪械详情、配件、复装
pubspec.yaml                  依赖与资源声明
assets/images/                枪械侧视图（8 张 webp，见下方图片说明）
app-icon/                     启动图标全套
  res/                        安卓 res 资源（mipmap / drawable / values）
  optional/                   可选的自适应图标 xml
  master/                     母版大图与预览图
  README-安卓图标使用说明.md   图标使用说明
build-apk.sh                  在线编译脚本（见下方）
build-apk-offline.sh          离线编译脚本（见下方）
fetch-mirror.py               离线镜像抓取脚本（见下方）
```

## 编译方式一：在线编译

```bash
bash build-apk.sh
```

脚本会用 `flutter create` 生成安卓工程骨架，覆盖为本仓库代码，跑 `flutter pub get`、`flutter analyze`，再 `flutter build apk --debug`，成功后把 APK 拷到 `app-debug.apk`。

注意：在线编译要求 Gradle 能直接访问插件仓库与 Maven Central；如果构建环境的出站网络受限，Gradle 会在配置阶段解析插件失败，改走方式二。

## 编译方式二：离线编译（推荐用于受限网络）

适用于 Gradle 出站 TCP 被拦截、但 curl / Dart 仍可联网的环境：

1. 先跑镜像抓取脚本，把 Gradle 依赖闭包下到本地 Maven 镜像仓库（默认 `~/gradle-offline-mirror`）：

   ```bash
   python3 fetch-mirror.py
   ```

   该脚本用 curl 从 Maven Central / Google Maven / plugins.gradle.org / download.flutter.io 抓取，镜像目录只是本地构建缓存，**不要提交进仓库**（已在 `.gitignore` 里排除）。

2. 再跑离线编译脚本：

   ```bash
   bash build-apk-offline.sh
   ```

   脚本同样先 `flutter create` 生成骨架并覆盖代码，然后把本地 file:// 镜像仓库排在插件与依赖解析的最前面，并开 `org.gradle.offline=true`，Gradle 全程不联网；`flutter pub get` 仍走正常网络。成功后 APK 同样落在 `app-debug.apk`。

两种方式都不需要改包名：编译产物为 debug APK，安装到手机时需允许“未知来源”。

## 图片资源说明

`assets/images/` 下 App 实际引用 8 张短名侧视图：`glock17.webp`、`ak47.webp`、`m82a1.webp`、`mp5.webp`、`rem870.webp`、`m249.webp`、`rem700.webp`、`svd.webp`。其余枪械暂无侧视图，App 内显示占位图标。

注意：因本仓库推送通道只支持文本文件，二进制图片（`assets/images/*.webp` 与 `app-icon` 下的 `*.png`）暂未包含在本次推送中；拉取后请将上述图片放入对应目录后再编译，否则资源声明会找不到文件。配置、脚本、图标 xml 与说明文档已随本次推送；Dart 源码（`lib/`）因正在并行改动暂缓推送，待数据结构工作落地后补推，届时拉取最新代码即可。
