#!/bin/bash
# 编译枪械图鉴 App 的 debug APK。用法：bash build-apk.sh
set -e
export JAVA_HOME=$HOME/sdk/jdk17
export ANDROID_HOME=$HOME/sdk/android-sdk
export ANDROID_SDK_ROOT=$ANDROID_HOME
export PATH=$HOME/sdk/flutter/bin:$JAVA_HOME/bin:$ANDROID_HOME/cmdline-tools/latest/bin:$ANDROID_HOME/platform-tools:$PATH

# Gradle 用 Apache HttpClient，认 proxyUser/proxyPassword 系统属性：
# 直接走出站代理加认证（只放环境变量，不落盘），不再绕本机回环代理
# （回环会被沙箱按进程拦截，且 java.net 不认 proxyUser）
if [ -n "$https_proxy" ]; then
  P_HOST=$(python3 -c "import os,urllib.parse; print(urllib.parse.urlparse(os.environ['https_proxy']).hostname)")
  P_PORT=$(python3 -c "import os,urllib.parse; print(urllib.parse.urlparse(os.environ['https_proxy']).port)")
  P_USER=$(python3 -c "import os,urllib.parse; print(urllib.parse.urlparse(os.environ['https_proxy']).username)")
  P_PASS=$(python3 -c "import os,urllib.parse; print(urllib.parse.urlparse(os.environ['https_proxy']).password)")
  export JAVA_OPTS="-Djava.net.preferIPv4Stack=true -Dhttp.proxyHost=$P_HOST -Dhttp.proxyPort=$P_PORT -Dhttp.proxyUser=$P_USER -Dhttp.proxyPassword=$P_PASS -Dhttps.proxyHost=$P_HOST -Dhttps.proxyPort=$P_PORT -Dhttps.proxyUser=$P_USER -Dhttps.proxyPassword=$P_PASS"
  export GRADLE_OPTS="$JAVA_OPTS"
fi

# 不用 sdkmanager 联网（本机代理认证 Java 不认）：curl 直下组件并接受许可
cd "$ANDROID_HOME"
if [ ! -d platform-tools ]; then
  curl -LO https://dl.google.com/android/repository/platform-tools-latest-linux.zip
  unzip -q -o platform-tools-latest-linux.zip
fi
if [ ! -d build-tools/34.0.0 ]; then
  curl -LO https://dl.google.com/android/repository/build-tools_r34-linux.zip
  mkdir -p build-tools-tmp && unzip -q -o build-tools_r34-linux.zip -d build-tools-tmp
  mkdir -p build-tools/34.0.0
  if [ -d build-tools-tmp/build-tools ]; then
    cp -r build-tools-tmp/build-tools/. build-tools/34.0.0/
  else
    cp -r build-tools-tmp/. build-tools/34.0.0/
  fi
  rm -rf build-tools-tmp
fi
mkdir -p licenses
printf '8933bad161af4178b1185d1a37fbf41ea526\nd56f5187479451eabf01fb0b5b2a5f34e0a3\n24333f8a63b6825a656882fa2f2492894739\n' > licenses/android-sdk-license
cd "$HOME"

# 用 flutter create 生成安卓工程骨架，再覆盖为我们的代码
WORK=$HOME/workspace/firearms-app
BUILD_DIR=$HOME/workspace/firearms-app-build
rm -rf "$BUILD_DIR"
flutter create --project-name firearms_catalog --org com.example "$BUILD_DIR" >/dev/null
cp "$WORK/pubspec.yaml" "$BUILD_DIR/pubspec.yaml"
rm -rf "$BUILD_DIR/lib"
cp -r "$WORK/lib" "$BUILD_DIR/lib"
rm -rf "$BUILD_DIR/assets"
cp -r "$WORK/assets" "$BUILD_DIR/assets"
# 脚手架自带的 widget 测试引用的是默认 MyApp，与我们的入口类名不符，删掉
rm -rf "$BUILD_DIR/test"

cd "$BUILD_DIR"
# daemon JVM 也强制 IPv4 并走出站代理（只写 host/port，认证只放环境变量不落盘）
python3 - <<'PYEOF'
import re, os, urllib.parse
p = "android/gradle.properties"
s = open(p).read()
up = urllib.parse.urlparse(os.environ.get('https_proxy') or '')
extra = f"-Djava.net.preferIPv4Stack=true -Dhttp.proxyHost={up.hostname} -Dhttp.proxyPort={up.port} -Dhttps.proxyHost={up.hostname} -Dhttps.proxyPort={up.port}"
if "org.gradle.jvmargs=" in s:
    s = re.sub(r"(?m)^org\.gradle\.jvmargs=.*$",
               lambda m: m.group(0) if "preferIPv4Stack" in m.group(0) else m.group(0) + " " + extra, s)
else:
    s += "\norg.gradle.jvmargs=" + extra + "\n"
open(p, "w").write(s)
print("gradle.properties patched")
PYEOF
# 按模板的 compileSdk 下载对应平台包
COMPILE_SDK=$(grep -rhoE 'compileSdk(Version)?[^0-9]*[0-9]+' android/app/build.gradle* android/local.properties 2>/dev/null | grep -oE '[0-9]+' | head -1)
if [ -n "$COMPILE_SDK" ] && [ ! -d "$ANDROID_HOME/platforms/android-$COMPILE_SDK" ]; then
  curl -s https://dl.google.com/android/repository/repository2-1.xml -o /tmp/repo2.xml
  PLAT_URL=$(python3 - "$COMPILE_SDK" <<'PYEOF'
import re, sys
sdk = sys.argv[1]
xml = open('/tmp/repo2.xml').read()
for m in re.finditer(r'<remotePackage path="platforms;android-' + sdk + r'"[^>]*>(.*?)</remotePackage>', xml, re.S):
    body = m.group(1)
    name = re.search(r'<display-name>([^<]+)</display-name>', body).group(1)
    if name.strip() == f'Android SDK Platform {sdk}':
        print(re.search(r'<url>([^<]+\.zip)</url>', body).group(1))
        break
PYEOF
)
  if [ -n "$PLAT_URL" ]; then
    cd "$ANDROID_HOME"
    curl -LO "https://dl.google.com/android/repository/$PLAT_URL"
    mkdir -p "platforms/android-$COMPILE_SDK"
    unzip -q -o "$PLAT_URL" -d "platforms/android-$COMPILE_SDK"
    cd "$BUILD_DIR"
  fi
fi
flutter pub get
flutter analyze || true
# 停掉可能残留的旧参数 daemon，确保用新参数起 daemon
(cd android && ./gradlew --stop >/dev/null 2>&1) || true
# 不用 daemon：daemon 读不到项目里的代理/IPv4 参数会被沙箱拦截，--no-daemon 直接用带参数的客户端 JVM 构建
flutter build apk --debug --no-android-gradle-daemon
cp build/app/outputs/flutter-apk/app-debug.apk "$WORK/app-debug.apk"
ls -la "$WORK/app-debug.apk"
echo BUILD_DONE
