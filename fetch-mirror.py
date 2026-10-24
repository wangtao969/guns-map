#!/usr/bin/env python3
"""BFS-download Maven artifacts into a local file:// mirror for offline Gradle builds.

Usage:
  python3 fetch-mirror.py [--extra g:a:v ...] [--repo NAME:BASE ...]

Seeds cover: Gradle plugin markers (kotlin-dsl 6.4.2, kotlin-jvm 2.2.20,
AGP 9.1.0, KGP 2.4.0), the flutter_tools included-build dependencies, and the
io.flutter embedding/arch artifacts for the pinned engine version.

Notes:
- Downloads go through curl, which picks up the sandbox egress proxy from the
  environment automatically. This script never prints or stores proxy secrets.
- Only .pom files and the main artifact file (.jar/.aar) are mirrored; sources
  and Gradle .module metadata are intentionally skipped (Gradle falls back to
  POM resolution when .module is absent).
- Parent POMs are mirrored too, because Gradle reads them for property and
  dependencyManagement resolution.
"""
import os
import re
import struct
import subprocess
import sys
import xml.etree.ElementTree as ET
import zipfile
from collections import deque

MIRROR = os.path.expanduser("~/gradle-offline-mirror")

# Try repos in this order; first 200 wins for a given coordinate.
REPOS = [
    ("central", "https://repo.maven.apache.org/maven2"),
    ("google", "https://dl.google.com/dl/android/maven2"),
    ("flutter", "https://storage.googleapis.com/download.flutter.io"),
    ("plugin-portal", "https://plugins.gradle.org/m2"),
]

ENGINE_VERSION = "1.0.0-cf636b1dfb818dd6a3ff16e390e93b1a036969c8"

SEEDS = [
    # Plugin markers (resolved via plugins.gradle.org/m2).
    ("org.gradle.kotlin.kotlin-dsl", "org.gradle.kotlin.kotlin-dsl.gradle.plugin", "6.4.2"),
    ("org.jetbrains.kotlin.jvm", "org.jetbrains.kotlin.jvm.gradle.plugin", "2.2.20"),
    ("com.android.application", "com.android.application.gradle.plugin", "9.1.0"),
    ("org.jetbrains.kotlin.android", "org.jetbrains.kotlin.android.gradle.plugin", "2.4.0"),
    # flutter_tools included-build dependencies.
    ("androidx.annotation", "annotation-jvm", "1.9.1"),
    ("org.jetbrains.kotlin", "kotlin-gradle-plugin", "2.0.0"),
    ("org.jetbrains.kotlinx", "kotlinx-serialization-json", "1.4.0"),
    ("com.android.tools.build", "gradle", "8.11.1"),
    # KGP adds kotlin-stdlib to the app compile classpath automatically.
    ("org.jetbrains.kotlin", "kotlin-stdlib", "2.4.0"),
    # Flutter embedding + engine arch libs (hosted repo, pinned engine version).
    ("io.flutter", "flutter_embedding_debug", ENGINE_VERSION),
    ("io.flutter", "armeabi_v7a_debug", ENGINE_VERSION),
    ("io.flutter", "arm64_v8a_debug", ENGINE_VERSION),
    ("io.flutter", "x86_64_debug", ENGINE_VERSION),
]


def curl_fetch(url, dest):
    """Download url to dest with curl. Returns True on HTTP 200."""
    if os.path.exists(dest) and os.path.getsize(dest) > 0:
        return True
    os.makedirs(os.path.dirname(dest), exist_ok=True)
    tmp = dest + ".tmp"
    r = subprocess.run(
        ["curl", "-sS", "-f", "-L", "--retry", "2", "--max-time", "180", "-o", tmp, url],
        capture_output=True, text=True)
    if r.returncode != 0 or not os.path.exists(tmp) or os.path.getsize(tmp) == 0:
        # Some mirrors answer 200 with an empty body for missing artifacts;
        # treat that as a miss and try the next repo.
        if os.path.exists(tmp):
            os.remove(tmp)
        return False
    os.replace(tmp, dest)
    return True


def group_path(group):
    return group.replace(".", "/")


def artifact_dir(group, artifact, version):
    return os.path.join(MIRROR, group_path(group), artifact, version)


def localname(tag):
    return tag.rsplit("}", 1)[-1] if "}" in tag else tag


def children(elem, name):
    return [c for c in elem if localname(c.tag) == name]


def child_text(elem, name):
    for c in elem:
        if localname(c.tag) == name:
            return (c.text or "").strip()
    return None


class Pom:
    def __init__(self, group, artifact, version, path):
        self.group, self.artifact, self.version = group, artifact, version
        self.packaging = "jar"
        self.properties = {}
        self.dep_mgmt = {}          # (g, a) -> version string (raw, may hold ${})
        self.imports = []           # list of (g, a, v) BOMs
        self.dependencies = []      # list of dicts
        self.parent = None          # (g, a, v)
        self.relocation = None      # (g, a, v)
        self._parse(path)

    def _parse(self, path):
        root = ET.parse(path).getroot()
        parent_el = None
        for c in root:
            if localname(c.tag) == "parent":
                parent_el = c
        if parent_el is not None:
            self.parent = (child_text(parent_el, "groupId"),
                           child_text(parent_el, "artifactId"),
                           child_text(parent_el, "version"))
        self.group = self.group or (self.parent[0] if self.parent else None)
        self.version = self.version or (self.parent[2] if self.parent else None)
        pkg = child_text(root, "packaging")
        if pkg:
            self.packaging = pkg
        dm = child_text(root, "distributionManagement")
        for c in root:
            if localname(c.tag) == "distributionManagement":
                for rel in c:
                    if localname(rel.tag) == "relocation":
                        self.relocation = (child_text(rel, "groupId"),
                                           child_text(rel, "artifactId"),
                                           child_text(rel, "version"))
        for c in root:
            if localname(c.tag) == "properties":
                for p in c:
                    self.properties[localname(p.tag)] = (p.text or "").strip()
        for c in root:
            if localname(c.tag) == "dependencyManagement":
                for deps in c:
                    if localname(deps.tag) != "dependencies":
                        continue
                    for d in deps:
                        if localname(d.tag) != "dependency":
                            continue
                        g = child_text(d, "groupId")
                        a = child_text(d, "artifactId")
                        v = child_text(d, "version")
                        scope = child_text(d, "scope") or "compile"
                        typ = child_text(d, "type") or "jar"
                        if scope == "import" and typ == "pom":
                            if g and a and v:
                                self.imports.append((g, a, v))
                        elif g and a and v:
                            self.dep_mgmt[(g, a)] = v
        for c in root:
            if localname(c.tag) == "dependencies":
                for d in c:
                    if localname(d.tag) != "dependency":
                        continue
                    dep = {
                        "group": child_text(d, "groupId"),
                        "artifact": child_text(d, "artifactId"),
                        "version": child_text(d, "version"),
                        "scope": child_text(d, "scope") or "compile",
                        "type": child_text(d, "type") or "jar",
                        "optional": (child_text(d, "optional") or "").strip() == "true",
                        "exclusions": set(),
                    }
                    for ex in d:
                        if localname(ex.tag) == "exclusions":
                            for e in ex:
                                if localname(e.tag) == "exclusion":
                                    eg = child_text(e, "groupId")
                                    ea = child_text(e, "artifactId")
                                    if eg and ea:
                                        dep["exclusions"].add((eg, ea))
                    self.dependencies.append(dep)


def resolve_props(text, props):
    """Expand ${...} placeholders using props (up to 10 passes)."""
    if not text:
        return text
    for _ in range(10):
        m = re.search(r"\$\{([^}]+)\}", text)
        if not m:
            break
        key = m.group(1)
        val = props.get(key)
        if val is None:
            break
        text = text.replace("${" + key + "}", val)
    return text


def fetch_pom(group, artifact, version):
    """Fetch a POM from the first repo that has it. Returns (path, repo_base)."""
    rel = f"{group_path(group)}/{artifact}/{version}/{artifact}-{version}.pom"
    dest = os.path.join(MIRROR, rel)
    if os.path.exists(dest) and os.path.getsize(dest) > 0:
        # Still need to know a repo base for the jar; caller re-probes.
        return dest, None
    for _name, base in REPOS:
        if curl_fetch(f"{base}/{rel}", dest):
            return dest, base
    return None, None


def fetch_artifact_file(group, artifact, version, ext):
    rel = f"{group_path(group)}/{artifact}/{version}/{artifact}-{version}.{ext}"
    dest = os.path.join(MIRROR, rel)
    if os.path.exists(dest) and os.path.getsize(dest) > 0:
        return True
    for _name, base in REPOS:
        if curl_fetch(f"{base}/{rel}", dest):
            return True
    return False


def fetch_metadata_versions(group, artifact):
    """Return the version list from maven-metadata.xml (central first)."""
    rel = f"{group_path(group)}/{artifact}/maven-metadata.xml"
    tmp = f"/tmp/maven-metadata-{artifact}.xml"
    for _name, base in REPOS:
        if curl_fetch(f"{base}/{rel}", tmp):
            try:
                root = ET.parse(tmp).getroot()
                vers = []
                for v in root.iter():
                    if localname(v.tag) == "version":
                        vers.append((v.text or "").strip())
                return vers
            except Exception:
                return []
    return []


def parse_version(v):
    parts = []
    for p in re.split(r"[.\-+_]", v):
        parts.append((0, int(p), "") if p.isdigit() else (1, 0, p))
    return parts


def resolve_range(spec, versions):
    """Resolve a Maven version range to the highest matching version."""
    spec = spec.strip()
    # Single-version range like [2.7.0] pins exactly that version.
    m1 = re.match(r"^[\[\(]([^\s,\]\)]+)[\]\)]$", spec)
    if m1:
        return m1.group(1)
    m = re.match(r"^([\[\(])([^,]*),([^,\]\)]*)[\]\)]$", spec)
    if not m:
        return None
    lo_inc, lo, hi, hi_inc = m.group(1) == "[", m.group(2).strip(), m.group(3).strip(), spec.endswith("]")
    cands = []
    for v in versions:
        if not v:
            continue
        pv, plo = parse_version(v), parse_version(lo) if lo else None
        phi = parse_version(hi) if hi else None
        if lo and ((pv < plo) or (pv == plo and not lo_inc)):
            continue
        if hi and ((pv > phi) or (pv == phi and not hi_inc)):
            continue
        cands.append(v)
    if not cands:
        return None
    return max(cands, key=parse_version)


OLD_REF = b"org/gradle/internal/buildoption/BuildOption$Value"
NEW_REF = b"org/gradle/internal/buildoption/Option$Value"
_CP_FIXED = {3: 4, 4: 4, 7: 2, 8: 2, 9: 4, 10: 4, 11: 4, 12: 4, 15: 3, 16: 2,
             17: 4, 18: 4, 19: 2, 20: 2}


def patch_class_bytes(data: bytes) -> bytes:
    """Rewrite BuildOption$Value -> Option$Value in a .class file's constant
    pool (Gradle 9.3 renamed the type; KGP 2.2.x/2.4.0 still reference the old
    one via ProjectIsolationStartParameterAccessorG76). Only Utf8 payloads
    change length; everything else is index/length delimited, so the file
    stays valid."""
    if data[:4] != b"\xca\xfe\xba\xbe" or OLD_REF not in data:
        return data
    cp_count = struct.unpack(">H", data[8:10])[0]
    out = bytearray(data[:10])
    pos = 10
    i = 1
    changed = False
    while i < cp_count:
        tag = data[pos]
        if tag == 1:
            ln = struct.unpack(">H", data[pos + 1:pos + 3])[0]
            payload = data[pos + 3:pos + 3 + ln]
            if OLD_REF in payload:
                payload = payload.replace(OLD_REF, NEW_REF)
                changed = True
            out += bytes([1]) + struct.pack(">H", len(payload)) + payload
            pos += 3 + ln
        elif tag in (5, 6):
            out += data[pos:pos + 9]
            pos += 9
            i += 1
        elif tag in _CP_FIXED:
            n = _CP_FIXED[tag]
            out += data[pos:pos + 1 + n]
            pos += 1 + n
        else:
            raise ValueError(f"unknown constant pool tag {tag} at {pos}")
        i += 1
    out += data[pos:]
    return bytes(out) if changed else data


def rename_class_bytes(data: bytes, old: str, new: str) -> bytes:
    """Constant-pool-aware class rename (Utf8 entries exactly equal to the old
    internal name become the new one). Used to swap a G76 variant class for
    its Default twin, which the registered G76$Factory then instantiates."""
    if data[:4] != b"\xca\xfe\xba\xbe":
        raise ValueError("not a class file")
    old_b, new_b = old.encode(), new.encode()
    cp_count = struct.unpack(">H", data[8:10])[0]
    out = bytearray(data[:10])
    pos = 10
    i = 1
    while i < cp_count:
        tag = data[pos]
        if tag == 1:
            ln = struct.unpack(">H", data[pos + 1:pos + 3])[0]
            payload = data[pos + 3:pos + 3 + ln]
            if payload == old_b:
                payload = new_b
            out += bytes([1]) + struct.pack(">H", len(payload)) + payload
            pos += 3 + ln
        elif tag in (5, 6):
            out += data[pos:pos + 9]
            pos += 9
            i += 1
        elif tag in _CP_FIXED:
            n = _CP_FIXED[tag]
            out += data[pos:pos + 1 + n]
            pos += 1 + n
        else:
            raise ValueError(f"unknown constant pool tag {tag} at {pos}")
        i += 1
    out += data[pos:]
    return bytes(out)


# Artifacts whose binary is published ONLY with a classifier (their POM says
# packaging=pom, so the BFS jar step skips them). AGP resolves aapt2 with an
# OS classifier; the mirror must carry the classifier jar or the offline
# build fails with "No cached version of ... aapt2 ... available".
EXTRA_CLASSIFIER_JARS = [
    # (group, artifact, version, classifier, base-repo-url)
    ("com.android.tools.build", "aapt2", "9.1.0-14792394", "linux",
     "https://dl.google.com/dl/android/maven2"),
]


def fetch_classifier_jars():
    for (g, a, v, classifier, base) in EXTRA_CLASSIFIER_JARS:
        path = os.path.join(MIRROR, g.replace(".", "/"), a, v,
                            f"{a}-{v}-{classifier}.jar")
        if os.path.exists(path):
            continue
        url = f"{base}/{g.replace('.', '/')}/{a}/{v}/{a}-{v}-{classifier}.jar"
        os.makedirs(os.path.dirname(path), exist_ok=True)
        if fetch(url, path):
            print(f"CLASSIFIER JAR: {g}:{a}:{v}:{classifier}")
        else:
            print(f"CLASSIFIER JAR FAILED: {url}")


def patch_kgp_jars():
    """Apply Gradle 9.3 compatibility patches to every kotlin-gradle-plugin
    jar in the mirror (both steps are idempotent no-ops when already applied):
    1. BuildOption$Value -> Option$Value in the G76 isolation accessor.
    2. CompatibilityConventionRegistrarG76 := Default twin (no-op), because
       the old HasConvention/Convention API no longer exists in Gradle 9.x."""
    base = os.path.join(MIRROR, "org/jetbrains/kotlin/kotlin-gradle-plugin")
    if not os.path.isdir(base):
        return
    g76 = "org/jetbrains/kotlin/gradle/plugin/internal/CompatibilityConventionRegistrarG76"
    dfn = "org/jetbrains/kotlin/gradle/plugin/internal/DefaultCompatibilityConventionRegistrar"
    for v in sorted(os.listdir(base)):
        path = os.path.join(base, v, f"kotlin-gradle-plugin-{v}.jar")
        if not os.path.exists(path):
            continue
        with zipfile.ZipFile(path) as zf:
            names = zf.namelist()
            items = {n: zf.read(n) for n in names}
        patched = 0
        for n, blob in items.items():
            if n.endswith(".class"):
                new = patch_class_bytes(blob)
                if new != blob:
                    items[n] = new
                    patched += 1
        if g76 + ".class" in items and dfn + ".class" in items:
            new_g76 = rename_class_bytes(items[dfn + ".class"], dfn, g76)
            if items[g76 + ".class"] != new_g76:
                items[g76 + ".class"] = new_g76
                patched += 1
        if patched:
            tmp = path + ".patched"
            with zipfile.ZipFile(tmp, "w", zipfile.ZIP_DEFLATED) as zf:
                for n in names:
                    zf.writestr(n, items[n])
            os.replace(tmp, path)
            print(f"KGP PATCH: {path}: patched {patched} class file(s)")


def main():
    extra = []
    args = sys.argv[1:]
    i = 0
    while i < len(args):
        if args[i] == "--extra" and i + 1 < len(args):
            g, a, v = args[i + 1].split(":")
            extra.append((g, a, v))
            i += 2
        else:
            i += 1

    queue = deque()
    seen = set()
    for coord in SEEDS + extra:
        if coord not in seen:
            seen.add(coord)
            queue.append((coord, None))  # (coord, exclusions)

    pom_cache = {}
    unresolved = []
    downloaded_files = 0

    def get_pom(g, a, v):
        if (g, a, v) in pom_cache:
            return pom_cache[(g, a, v)]
        path, _base = fetch_pom(g, a, v)
        if path is None:
            return None
        try:
            pom = Pom(g, a, v, path)
        except ET.ParseError:
            # Corrupt/empty POM (e.g. a stale partial download): drop it and
            # retry once from the repos instead of crashing the whole run.
            try:
                os.remove(path)
            except OSError:
                pass
            path, _base = fetch_pom(g, a, v)
            if path is None:
                return None
            try:
                pom = Pom(g, a, v, path)
            except ET.ParseError:
                return None
        pom_cache[(g, a, v)] = pom
        # Mirror the parent POM chain too.
        if pom.parent:
            pg, pa, pv = pom.parent
            if (pg, pa, pv) not in pom_cache:
                ppath, _ = fetch_pom(pg, pa, pv)
                if ppath is not None:
                    ppom = Pom(pg, pa, pv, ppath)
                    pom_cache[(pg, pa, pv)] = ppom
        return pom

    def merged_props_and_mgmt(pom):
        """Collect properties + dependencyManagement from the POM and its parents."""
        props = {}
        mgmt = {}
        chain = []
        cur = pom
        while cur is not None:
            chain.append(cur)
            if cur.parent and cur.parent not in [(p.group, p.artifact, p.version) for p in chain]:
                cur = get_pom(*cur.parent)
            else:
                cur = None
        for p in reversed(chain):
            props.update(p.properties)
            mgmt.update(p.dep_mgmt)
        # Keys may themselves hold placeholders (e.g. ${project.groupId} used
        # by multi-module projects such as Netty); resolve them against the
        # merged properties so lookups below hit.
        resolved_mgmt = {}
        for (mg, ma), mver in mgmt.items():
            rg = resolve_props(mg, props)
            ra = resolve_props(ma, props)
            resolved_mgmt.setdefault((rg, ra), mver)
        mgmt = resolved_mgmt
        # Built-ins.
        props.setdefault("project.groupId", pom.group or "")
        props.setdefault("project.artifactId", pom.artifact or "")
        props.setdefault("project.version", pom.version or "")
        props.setdefault("groupId", pom.group or "")
        props.setdefault("artifactId", pom.artifact or "")
        props.setdefault("version", pom.version or "")
        return props, mgmt, chain

    def collect_mgmt(pom, seen_imports=None):
        """Fully resolved dependencyManagement for a POM: its own entries plus
        its parents', plus every BOM imported by the POM *or any of its
        parents* (e.g. commons-parent importing junit-bom). BOM entries are
        resolved against the BOM's own properties, per Maven semantics.
        Recurses into nested imports with a cycle guard."""
        props, mgmt, chain = merged_props_and_mgmt(pom)
        mgmt = {k: resolve_props(v, props) for k, v in mgmt.items()}
        if seen_imports is None:
            seen_imports = set()
        for p in chain:
            for (g, a, v) in p.imports:
                bg = resolve_props(g, props)
                ba = resolve_props(a, props)
                bv = resolve_props(v, props)
                if (bg, ba, bv) in seen_imports:
                    continue
                seen_imports.add((bg, ba, bv))
                bpom = get_pom(bg, ba, bv)
                if bpom is None:
                    continue
                for k, bver in collect_mgmt(bpom, seen_imports).items():
                    mgmt.setdefault(k, bver)
        return mgmt

    while queue:
        (g, a, v), exclusions = queue.popleft()
        if (g, a) in (exclusions or set()):
            continue
        pom = get_pom(g, a, v)
        if pom is None:
            unresolved.append((g, a, v))
            print(f"UNRESOLVED POM: {g}:{a}:{v}", flush=True)
            continue
        if pom.relocation:
            rg, ra, rv = pom.relocation
            rg = rg or g
            ra = ra or a
            rv = rv or v
            if (rg, ra, rv) not in seen:
                seen.add((rg, ra, rv))
                queue.append(((rg, ra, rv), exclusions))
            continue
        # Main artifact file (skip for pom packaging).
        ext = {"jar": "jar", "aar": "aar", "bundle": "jar"}.get(pom.packaging, "jar")
        if pom.packaging != "pom":
            if fetch_artifact_file(g, a, v, ext):
                downloaded_files += 1
            else:
                unresolved.append((g, a, v + " [" + ext + "]"))
                print(f"UNRESOLVED FILE: {g}:{a}:{v} (.{ext})", flush=True)
        props, _mgmt_unused, _chain = merged_props_and_mgmt(pom)
        mgmt = collect_mgmt(pom)
        for dep in pom.dependencies:
            if dep["optional"]:
                continue
            if dep["scope"] in ("test", "provided"):
                continue
            dg = resolve_props(dep["group"], props)
            da = resolve_props(dep["artifact"], props)
            if not dg or not da:
                continue
            if (dg, da) in (exclusions or set()):
                continue
            dv = dep["version"]
            if dv:
                dv = resolve_props(dv, props)
            else:
                raw = mgmt.get((dg, da))
                if raw is None:
                    print(f"NO VERSION: {g}:{a}:{v} -> {dg}:{da}", flush=True)
                    unresolved.append((dg, da, "?"))
                    continue
                dv = resolve_props(raw, props)
            if dv.startswith("[") or dv.startswith("("):
                vers = fetch_metadata_versions(dg, da)
                dv = resolve_range(dv, vers)
                if dv is None:
                    print(f"RANGE UNRESOLVED: {dg}:{da} {dep['version']}", flush=True)
                    unresolved.append((dg, da, dep["version"]))
                    continue
            if dep["type"] == "pom" and dep["scope"] != "import":
                # Non-import pom deps carry no transitive deps; mirror the pom only.
                if (dg, da, dv) not in seen:
                    seen.add((dg, da, dv))
                    queue.append(((dg, da, dv), dep["exclusions"]))
                continue
            coord = (dg, da, dv)
            if coord not in seen:
                seen.add(coord)
                queue.append((coord, dep["exclusions"]))

    patch_kgp_jars()
    fetch_classifier_jars()
    print(f"\nDone. Unique coordinates visited: {len(seen)}")
    print(f"Artifact files downloaded this run: {downloaded_files}")
    total = 0
    for _root, _dirs, files in os.walk(MIRROR):
        total += len(files)
    print(f"Total files in mirror: {total}")
    if unresolved:
        print(f"UNRESOLVED ({len(unresolved)}):")
        for u in unresolved:
            print("  ", u)
    else:
        print("No unresolved coordinates.")


if __name__ == "__main__":
    main()
