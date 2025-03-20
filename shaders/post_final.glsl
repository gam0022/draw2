#version 460 core

#pragma include "shaders/_common.glsl"

// https://www.shadertoy.com/view/lsf3WH
// Noise - value - 2D by iq
float noise2d(vec2 p) {
    vec2 i = floor(p);
    vec2 f = fract(p);
    vec2 u = f * f * (3.0 - 2.0 * f);
    return mix(mix(hash12(i + vec2(0.0, 0.0)), hash12(i + vec2(1.0, 0.0)), u.x), mix(hash12(i + vec2(0.0, 1.0)), hash12(i + vec2(1.0, 1.0)), u.x), u.y);
}

float fbm(vec2 uv) {
    float f = 0.0;
    mat2 m = mat2(1.6, 1.2, -1.2, 1.6);
    f = 0.5000 * noise2d(uv);
    uv = m * uv;
    f += 0.2500 * noise2d(uv);
    uv = m * uv;
    f += 0.1250 * noise2d(uv);
    uv = m * uv;
    f += 0.0625 * noise2d(uv);
    uv = m * uv;
    return f;
}


#define gChromaticAberrationIntensity 0.0
#define gChromaticAberrationDistance 1.

#define gVignetteIntensity 1.
#define gVignetteSmoothness 1.6
#define gVignetteRoundness 1.

#define gTonemapExposure 1
#define gFlash slider_flash
#define gFlashSpeed 30

#define gGlitchIntensity 0
#define gXSfhitGlitch 0
#define gInvertRate 0


float vignette(vec2 uv) {
    vec2 d = abs(uv - 0.5) * gVignetteIntensity;
    float roundness = (1.0 - gVignetteRoundness) * 6.0 + gVignetteRoundness;
    d = pow(d, vec2(roundness));
    return pow(saturate(1.0 - dot(d, d)), gVignetteSmoothness);
}

vec3 invert(vec3 c, vec2 uv) {
    if (hash12(vec2(floor(uv.y * gInvertRate * 32.0), beat)) < gInvertRate) {
        return vec3(1.0) - c;
    } else {
        return c;
    }
}

vec3 flash(vec3 c) {
    c = mix(c, vec3(1.0), gFlash * saturate(cos(time * PI * .5 * gFlashSpeed)));
    return c;
}

vec3 chromaticAberration(vec2 uv) {
    uv.x += gXSfhitGlitch * (fbm(vec2(232.0 * uv.y, beat)) - 0.5);

    vec2 d = abs(uv - 0.5);
    float f = mix(0.5, dot(d, d), gChromaticAberrationDistance);
    f *= f * gChromaticAberrationIntensity;
    vec2 shift = vec2(f);

    float a = 2.0 * hash11(beat) - 1.0;
    vec2 grid = hash23(vec3(floor(vec2(uv.x * (4.0 + 8.0 * a), (uv.y + a) * 32.0)), beat));
    grid = 2.0 * grid - 1.0;
    shift += gGlitchIntensity * grid;

    vec3 col;
    col.r = texture(post_bloom_composite, uv + shift).r;
    col.g = texture(post_bloom_composite, uv).g;
    col.b = texture(post_bloom_composite, uv - shift).b;
    return col;
}

// https://github.com/KhronosGroup/ToneMapping/blob/main/PBR_Neutral/pbrNeutral.glsl
vec3 PBRNeutralToneMapping(vec3 color) {
    const float startCompression = 0.8 - 0.04;
    const float desaturation = 0.15;

    float x = min(color.r, min(color.g, color.b));
    float offset = x < 0.08 ? x - 6.25 * x * x : 0.04;
    color -= offset;

    float peak = max(color.r, max(color.g, color.b));
    if (peak < startCompression) return color;

    const float d = 1. - startCompression;
    float newPeak = 1. - d * d / (peak + d - startCompression);
    color *= newPeak / peak;

    float g = 1. - 1. / (desaturation * (peak - newPeak) + 1.);
    return mix(color, newPeak * vec3(1, 1, 1), g);
}

vec3 invertPattern(vec3 col, vec2 uv) {
    return mix(col, saturate(1 - col), texture(scene2d, uv).r);
}

void main() {
    vec2 uv = gl_FragCoord.xy / resolution.xy;

    initBeat();

    // vec3 col = texture(post_bloom, uv).rgb;
    vec3 col = chromaticAberration(uv);
    // col = mix(col, vec3(1, 1, 1), PrintValue(gl_FragCoord.xy, grid(4, 3), fontSize,bpm, 1.0, 1.0));
    // col = mix(col, vec3(1, 1, 1), PrintValue(gl_FragCoord.xy, grid(38, 3), fontSize, buttons[20].w, 1.0, 1.0));

    // col = PBRNeutralToneMapping(col * gTonemapExposure);
    // col *= vignette(uv);
    col = invert(col, uv);
    col = flash(col);
    // col = blend(col);

    // if (mod(beat, 2) < 1) col = invertPattern(col, uv);

    SetAspect(resolution.xy, 25, true, true);
    SetAlign(Align_Left_Bottom);
    SetFontName(NAME_ORBITRON);
    SetFontStyle(STYLE_NORMAL);
    Stack_Char(C_B);
    Stack_Char(C_P);
    Stack_Char(C_M);
    Stack_Char(C_colon);
    col += Render_Char(uv);
    col += Print_Number(uv, bpm, 1, 3);

    outColor = vec4(col, 1);
}