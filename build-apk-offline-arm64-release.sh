#!/bin/bash
# Gun's Map（枪械图鉴 App）完全离线 release APK 编译（正式版签名）。
# 用法：bash build-apk-offline-arm64-release.sh
# 签名：密钥库在 ~/release-keystore/（本机，不进公开仓库）；密码在构建时
# 从同目录的 keystore.password 文件读取，写入构建目录的 key.properties
#（构建目录不在推送源码范围，且每次构建前 rm -rf 清空）。
#
# 背景：沙箱在 TCP 层拦截 Gradle 的出站连接（Apache HttpClient），即使把
# other_tcp 改成 Ask 也不弹审批卡，此路已死。本脚本因此：
#   1. 用 curl 预先把 Android SDK 组件（平台包、build-tools）下好；
#   2. Gradle 全部走本地 file:// 镜像仓库（~/gradle-offline-mirror，由
#      fetch-mirror.py 用 curl 从 Maven Central / Google Maven /
#      plugins.gradle.org / download.flutter.io 抓取），并开
#      org.gradle.offline=true，Gradle 进程全程不联网；
#   3. flutter pub get 仍走正常网络（pub.dev 在放行列表里，Dart 可通）。
# 注意：不要把 https_proxy 里的认证信息打印或写入任何文件；本脚本不读它。
set -e
export JAVA_HOME=$HOME/sdk/jdk17
export ANDROID_HOME=$HOME/sdk/android-sdk
export ANDROID_SDK_ROOT=$ANDROID_HOME
export PATH=$HOME/sdk/flutter/bin:$JAVA_HOME/bin:$ANDROID_HOME/cmdline-tools/latest/bin:$ANDROID_HOME/platform-tools:$PATH
# 关键：Gradle 客户端与 daemon 经本地回环 TCP 通信；不强制 IPv4 时，Java 会用
# IPv6 映射地址建连，会被沙箱拦截导致 Broken pipe（已实证）。离线不需要代理，
# 但必须强制 IPv4。
export JAVA_OPTS="-Djava.net.preferIPv4Stack=true"
export GRADLE_OPTS="$JAVA_OPTS"

MIRROR=$HOME/gradle-offline-mirror
if [ ! -d "$MIRROR" ]; then
  echo "本地镜像仓库不存在：$MIRROR，请先跑 python3 fetch-mirror.py"
  exit 1
fi

# ---- Android SDK 组件（curl 直下，不走 sdkmanager）----
cd "$ANDROID_HOME"
if [ ! -d platform-tools ]; then
  curl -LO https://dl.google.com/android/repository/platform-tools-latest-linux.zip
  unzip -q -o platform-tools-latest-linux.zip
fi
if [ ! -d build-tools/34.0.0 ]; then
  curl -LO https://dl.google.com/android/repository/build-tools_r34-linux.zip
  mkdir -p build-tools-tmp && unzip -q -o build-tools_r34-linux.zip -d build-tools-tmp
  mkdir -p build-tools/34.0.0
  # 新版 build-tools zip 顶层目录不再是 build-tools/，而是 android-<大版本>/
  #（r34 对应 android-14、r36 对应 android-16）；取唯一顶层目录平铺。
  TOPDIR=$(ls build-tools-tmp)
  if [ "$(ls build-tools-tmp | wc -l)" = "1" ] && [ -d "build-tools-tmp/$TOPDIR" ]; then
    cp -r "build-tools-tmp/$TOPDIR/." build-tools/34.0.0/
  else
    cp -r build-tools-tmp/. build-tools/34.0.0/
  fi
  rm -rf build-tools-tmp
fi
# AGP 9.1.0 默认 build-tools 为 36.0.0，缺失会在配置后报错，先备好。
if [ ! -d build-tools/36.0.0 ]; then
  curl -LO https://dl.google.com/android/repository/build-tools_r36_linux.zip
  mkdir -p build-tools-tmp && unzip -q -o build-tools_r36_linux.zip -d build-tools-tmp
  mkdir -p build-tools/36.0.0
  TOPDIR=$(ls build-tools-tmp)
  if [ "$(ls build-tools-tmp | wc -l)" = "1" ] && [ -d "build-tools-tmp/$TOPDIR" ]; then
    cp -r "build-tools-tmp/$TOPDIR/." build-tools/36.0.0/
  else
    cp -r build-tools-tmp/. build-tools/36.0.0/
  fi
  rm -rf build-tools-tmp
fi
# AGP 要求 ndkVersion = flutter.ndkVersion（28.2.13676358，即 NDK r28c），
# 缺失会在 :app 配置时报 "NDK not configured"，先备好。
if [ ! -d ndk/28.2.13676358 ]; then
  curl -LO https://dl.google.com/android/repository/android-ndk-r28c-linux.zip
  mkdir -p ndk-tmp && unzip -q -o android-ndk-r28c-linux.zip -d ndk-tmp
  mkdir -p ndk/28.2.13676358
  cp -r ndk-tmp/android-ndk-r28c/. ndk/28.2.13676358/
  rm -rf ndk-tmp
fi
mkdir -p licenses
printf '8933bad161af4178b1185d1a37fbf41ea526\nd56f5187479451eabf01fb0b5b2a5f34e0a3\n24333f8a63b6825a656882fa2f2492894739\n' > licenses/android-sdk-license
# Flutter 3.47.8 的 compileSdk 是 36（见 flutter_tools 的 gradle_utils.dart）。
if [ ! -d platforms/android-36 ]; then
  curl -s https://dl.google.com/android/repository/repository2-1.xml -o /tmp/repo2.xml
  PLAT_URL=$(python3 - <<'PYEOF'
import re
xml = open('/tmp/repo2.xml').read()
for m in re.finditer(r'<remotePackage path="platforms;android-36"[^>]*>(.*?)</remotePackage>', xml, re.S):
    body = m.group(1)
    name = re.search(r'<display-name>([^<]+)</display-name>', body).group(1)
    if name.strip() == 'Android SDK Platform 36':
        print(re.search(r'<url>([^<]+\.zip)</url>', body).group(1))
        break
PYEOF
)
  if [ -n "$PLAT_URL" ]; then
    curl -LO "https://dl.google.com/android/repository/$PLAT_URL"
    # 平台 zip 顶层自带 android-36/ 目录，直接解到 platforms/android-36 会嵌套
    # 一层导致 AGP 找不到；先解到临时目录再把内容平铺上来，并校验版本。
    mkdir -p platforms-tmp && unzip -q -o "$PLAT_URL" -d platforms-tmp
    mkdir -p "platforms/android-36"
    if [ -d platforms-tmp/android-36 ]; then
      cp -r platforms-tmp/android-36/. "platforms/android-36/"
    else
      cp -r platforms-tmp/. "platforms/android-36/"
    fi
    rm -rf platforms-tmp
    # 注意：新版平台的 source.properties 里 Platform.Version 是 Android 大版本
    # 号（API 36 对应 Android 16），不能拿它当 API 级别校验；以 build.prop 的
    # ro.build.version.sdk=36 为准。
    grep -q "ro.build.version.sdk=36" "platforms/android-36/build.prop" || {
      echo "platform 36 install verification FAILED" >&2; exit 1; }
  fi
fi
cd "$HOME"

# ---- 生成安卓工程骨架并覆盖为我们的代码 ----
WORK=$HOME/workspace/firearms-app
BUILD_DIR=$HOME/workspace/firearms-app-build
rm -rf "$BUILD_DIR"
flutter create --project-name firearms_catalog --org com.example "$BUILD_DIR" >/dev/null
cp "$WORK/pubspec.yaml" "$BUILD_DIR/pubspec.yaml"
rm -rf "$BUILD_DIR/lib"
cp -r "$WORK/lib" "$BUILD_DIR/lib"
rm -rf "$BUILD_DIR/assets"
cp -r "$WORK/assets" "$BUILD_DIR/assets"
rm -rf "$BUILD_DIR/test"

# ---- 改名：显示名 Gun's Map（内部包名 firearms_catalog 不动）----
# ---- 启动图标：核对 icon / roundIcon（模板缺 roundIcon 时补上）----
python3 - <<'PYEOF'
import re
p = "/home/hatch/workspace/firearms-app-build/android/app/src/main/AndroidManifest.xml"
s = open(p).read()
s = re.sub(r'android:label="[^"]*"', 'android:label="Gun\'s Map"', s, count=1)
s = re.sub(r'android:icon="[^"]*"', 'android:icon="@mipmap/ic_launcher"', s, count=1)
if 'android:roundIcon=' not in s:
    s = s.replace('android:icon="@mipmap/ic_launcher"',
                  'android:icon="@mipmap/ic_launcher"\n        android:roundIcon="@mipmap/ic_launcher_round"', 1)
open(p, "w").write(s)
print("AndroidManifest label/icon/roundIcon patched")
PYEOF

# ---- 启动图标：把 app-icon/res/ 合并进生成工程的 res/ ----
# 同名目录合并：只替换 ic_launcher 相关文件（模板自带的默认图标），其他已有
# 资源（launch_background、styles 等）名字不同，不受影响。
ICON_SRC=$WORK/app-icon/res
if [ -d "$ICON_SRC" ]; then
  cp -r "$ICON_SRC/." "$BUILD_DIR/android/app/src/main/res/"
  if [ -f "$BUILD_DIR/android/app/src/main/res/mipmap-anydpi-v26/ic_launcher.xml" ]; then
    echo "app icon res merged"
  else
    echo "app icon merge FAILED: adaptive icon entry missing" >&2
    exit 1
  fi
else
  echo "app icon source missing: $ICON_SRC (skipping icon merge)" >&2
fi

# ---- 正式版签名：key.properties + release signingConfig ----
# Flutter 模板默认 release 用 debug 签名，这里改成正式密钥库。
STORE_PASS=$(cat "$HOME/release-keystore/keystore.password")
cat > "$BUILD_DIR/android/key.properties" <<KEYEOF
storePassword=$STORE_PASS
keyPassword=$STORE_PASS
keyAlias=gunsmap
storeFile=$HOME/release-keystore/guns-map-release.keystore
KEYEOF
python3 - <<'PYEOF'
p = "/home/hatch/workspace/firearms-app-build/android/app/build.gradle.kts"
s = open(p).read()
loader = '''import java.io.FileInputStream
import java.util.Properties

val keystoreProperties = Properties()
val keystorePropertiesFile = rootProject.file("key.properties")
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
}

'''
assert 'keystoreProperties' not in s
s = s.replace('android {', loader + 'android {', 1)
old = '''    buildTypes {
        release {
            // TODO: Add your own signing config for the release build.
            // Signing with the debug keys for now, so `flutter run --release` works.
            signingConfig = signingConfigs.getByName("debug")
        }
    }'''
new = '''    signingConfigs {
        create("release") {
            keyAlias = keystoreProperties["keyAlias"] as String
            keyPassword = keystoreProperties["keyPassword"] as String
            storeFile = keystoreProperties["storeFile"]?.let { file(it) }
            storePassword = keystoreProperties["storePassword"] as String
        }
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("release")
        }
    }

    // Release 构建默认跑 lintVital；离线镜像里没有 lint-gradle，
    // 且 App 已通过 flutter analyze，这里关掉，不影响 APK 本身。
    lint {
        checkReleaseBuilds = false
    }'''
assert old in s, "release buildTypes block not found in template"
s = s.replace(old, new, 1)
open(p, "w").write(s)
print("release signing config patched")
PYEOF

# ---- 本地镜像仓库接线 ----
# flutter_tools 的 included build 自带 settings（FAIL_ON_PROJECT_REPOS，只认
# google()+mavenCentral()），不能直接改 SDK 里的原文件：拷一份到构建目录，
# 给副本的 settings 加镜像仓库，并让主工程 includeBuild 指向副本。
cp -r "$HOME/sdk/flutter/packages/flutter_tools/gradle" "$BUILD_DIR/flutter-tools-gradle"
python3 - "$BUILD_DIR" "$MIRROR" <<'PYEOF'
import re, sys
build_dir, mirror = sys.argv[1], sys.argv[2]
mirror_uri = "file://" + mirror

# 1) included build 副本的 settings：镜像仓库排最前。
#    注意：included build 用自己的 settings 解析自身 build 脚本的插件，主工程
#    的 pluginManagement 不会透传进来，所以副本必须自带 pluginManagement。
p = build_dir + "/flutter-tools-gradle/settings.gradle.kts"
s = open(p).read()
s = s.replace("    repositories {\n        google()\n        mavenCentral()\n    }",
              "    repositories {\n        maven { url = uri(\"" + mirror_uri + "\") }\n        google()\n        mavenCentral()\n    }")
s = ("pluginManagement {\n"
     "    repositories {\n"
     '        maven { url = uri("' + mirror_uri + '") }\n'
     "        google()\n"
     "        mavenCentral()\n"
     "        gradlePluginPortal()\n"
     "    }\n"
     "}\n\n") + s
open(p, "w").write(s)
print("flutter-tools-gradle settings patched")

# 2) 主工程 settings：includeBuild 指向副本；pluginManagement 仓库镜像最前；
#    再加 dependencyResolutionManagement，让 app 工程的依赖也先走镜像。
p = build_dir + "/android/settings.gradle.kts"
s = open(p).read()
s = s.replace('includeBuild("$flutterSdkPath/packages/flutter_tools/gradle")',
              'includeBuild("' + build_dir + '/flutter-tools-gradle")')
s = s.replace("    repositories {\n        google()\n        mavenCentral()\n        gradlePluginPortal()\n    }",
              "    repositories {\n        maven { url = uri(\"" + mirror_uri + "\") }\n        google()\n        mavenCentral()\n        gradlePluginPortal()\n    }")
block = (
    "\ndependencyResolutionManagement {\n"
    "    repositoriesMode.set(RepositoriesMode.PREFER_SETTINGS)\n"
    "    repositories {\n"
    '        maven { url = uri("' + mirror_uri + '") }\n'
    "        google()\n"
    "        mavenCentral()\n"
    '        maven { url = uri("https://storage.googleapis.com/download.flutter.io") }\n'
    "    }\n"
    "}\n"
)
s += block
open(p, "w").write(s)
print("app settings patched")
PYEOF

cd "$BUILD_DIR"
# 离线模式：Gradle 只用本地镜像与缓存，不发起任何出站连接。
# 同时给 daemon JVM 也强制 IPv4（与客户端一致，避免回环建连被沙箱拦截）。
# 另外关掉 Kotlin 的 FUS（匿名用量统计）收集：KGP 2.2.x 的
# ProjectIsolationStartParameterAccessorG76 会调 Gradle 内部 API
# StartParameterInternal.getIsolatedProjects()，而 Gradle 9.3.1 里该方法的返回
# 类型已从 BuildOption$Value 改成 Option$Value，直接调会 NoSuchMethodError；
# 关掉 FUS 后 KGP 根本不会走到这段代码，对 APK 产物没有任何影响。
python3 - <<'PYEOF'
import re
for p in ("android/gradle.properties", "flutter-tools-gradle/gradle.properties"):
    try:
        s = open(p).read()
    except FileNotFoundError:
        s = ""
    if "org.gradle.offline=" not in s:
        s += "\norg.gradle.offline=true\n"
    if "kotlin.internal.collectFUSMetrics=" not in s:
        s += "kotlin.internal.collectFUSMetrics=false\n"
    if "preferIPv4Stack" not in s:
        if "org.gradle.jvmargs=" in s:
            s = re.sub(r"(?m)^org\.gradle\.jvmargs=.*$",
                       lambda m: m.group(0) + " -Djava.net.preferIPv4Stack=true", s)
        else:
            s += "\norg.gradle.jvmargs=-Djava.net.preferIPv4Stack=true\n"
    open(p, "w").write(s)
    print(p, "patched")
PYEOF

flutter pub get
(cd android && ./gradlew --stop >/dev/null 2>&1) || true
# flutter build 不转发 --offline，且 gradle.properties 里的 org.gradle.offline
# 不是有效属性（实测会被忽略）：用 GRADLE_USER_HOME/init.d 初始化脚本强制离线。
# 构建结束即删（trap 保证），不影响机器上其他 Gradle 构建。
GUH=$(python3 -c "import pwd,os; print(pwd.getpwuid(os.getuid()).pw_dir)")/.gradle
mkdir -p "$GUH/init.d"
printf 'gradle.startParameter.offline = true\n' > "$GUH/init.d/offline.gradle"
trap 'rm -f "$GUH/init.d/offline.gradle"' EXIT
flutter build apk --release --target-platform android-arm64 --no-android-gradle-daemon
cp build/app/outputs/flutter-apk/app-release.apk "$WORK/app-release-arm64.apk"
ls -la "$WORK/app-release-arm64.apk"
echo BUILD_DONE
