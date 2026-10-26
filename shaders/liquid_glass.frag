#version 460 core
#include <flutter/runtime_effect.glsl>

// Engine-provided (do NOT set from Dart):
//   sampler index 0 = backdrop image, floats 0..1 = backdrop size.
uniform vec2 u_size;
uniform sampler2D u_texture;
// Custom uniforms (Dart setFloat indices start at 2, in this order):
uniform float u_radius;      // corner radius, px
uniform float u_refraction;  // refraction displacement, px
uniform float u_chroma;      // chromatic spread factor (0..1)
uniform float u_tint;        // white veil amount (0..1)

out vec4 fragColor;

float sdRoundBox(vec2 p, vec2 b, float r) {
  vec2 q = abs(p) - b + r;
  return length(max(q, 0.0)) + min(max(q.x, q.y), 0.0) - r;
}

void main() {
  vec2 coord = FlutterFragCoord().xy;
  vec2 uv = coord / u_size;
#ifdef IMPELLER_TARGET_OPENGLES
  uv.y = 1.0 - uv.y;
#endif

  // Signed distance to the pill outline, in the bar's own coordinates.
  vec2 p = coord - u_size * 0.5;
  float d = sdRoundBox(p, u_size * 0.5, u_radius);

  // Bevel normal from the SDF gradient (finite differences).
  float e = 1.0;
  float dx = sdRoundBox(p + vec2(e, 0.0), u_size * 0.5, u_radius)
           - sdRoundBox(p - vec2(e, 0.0), u_size * 0.5, u_radius);
  float dy = sdRoundBox(p + vec2(0.0, e), u_size * 0.5, u_radius)
           - sdRoundBox(p - vec2(0.0, e), u_size * 0.5, u_radius);
  vec2 grad = vec2(dx, dy) / (2.0 * e);
  float gl = length(grad);
  vec2 normal = gl > 0.0001 ? grad / gl : vec2(0.0);

  // Refraction lives in a bevel band just inside the rim: full at the edge,
  // fading to nothing ~18px in, so the middle stays readable.
  float bevel = 18.0;
  float edgeFactor = 1.0 - clamp((-d) / bevel, 0.0, 1.0);
  vec2 disp = normal * edgeFactor * u_refraction;

  // Chromatic aberration: red bends a little more, blue a little less.
  vec2 uvR = uv + disp / u_size * (1.0 + u_chroma);
  vec2 uvG = uv + disp / u_size;
  vec2 uvB = uv + disp / u_size * (1.0 - u_chroma);

  // A tiny 5-tap cross softens shimmer without a real blur pass.
  vec2 px = 1.0 / u_size;
  vec3 col;
  col.r = (texture(u_texture, uvR).r
         + texture(u_texture, uvR + vec2(px.x, 0.0)).r
         + texture(u_texture, uvR - vec2(px.x, 0.0)).r
         + texture(u_texture, uvR + vec2(0.0, px.y)).r
         + texture(u_texture, uvR - vec2(0.0, px.y)).r) / 5.0;
  col.g = (texture(u_texture, uvG).g
         + texture(u_texture, uvG + vec2(px.x, 0.0)).g
         + texture(u_texture, uvG - vec2(px.x, 0.0)).g
         + texture(u_texture, uvG + vec2(0.0, px.y)).g
         + texture(u_texture, uvG - vec2(0.0, px.y)).g) / 5.0;
  col.b = (texture(u_texture, uvB).b
         + texture(u_texture, uvB + vec2(px.x, 0.0)).b
         + texture(u_texture, uvB - vec2(px.x, 0.0)).b
         + texture(u_texture, uvB + vec2(0.0, px.y)).b
         + texture(u_texture, uvB - vec2(0.0, px.y)).b) / 5.0;

  // Fresnel-ish rim light: bright glint on the light side, faint on the other.
  vec2 lightDir = normalize(vec2(-0.6, -0.8));
  float facing = dot(normal, lightDir);
  float glint = pow(max(facing, 0.0), 24.0) * 0.9
              + pow(max(facing, 0.0), 4.0) * 0.18
              + pow(max(-facing, 0.0), 8.0) * 0.12;
  col += vec3(1.0) * glint * edgeFactor;

  // Thin bright rim line right at the outline.
  float rim = 1.0 - smoothstep(0.0, 1.5, abs(d));
  col += vec3(1.0) * rim * 0.35;

  // Light white veil, like real glass over bright content.
  col = mix(col, vec3(1.0), u_tint);

  fragColor = vec4(col, 1.0);
}
