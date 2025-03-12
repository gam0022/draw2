#version 460 core

#pragma include "./shaders/common.glsl"

float DigitBin(const in int x) {
    return x == 0   ? 480599.0
           : x == 1 ? 139810.0
           : x == 2 ? 476951.0
           : x == 3 ? 476999.0
           : x == 4 ? 350020.0
           : x == 5 ? 464711.0
           : x == 6 ? 464727.0
           : x == 7 ? 476228.0
           : x == 8 ? 481111.0
           : x == 9 ? 481095.0
                    : 0.0;
}

float PrintValue(vec2 fragCoord, vec2 pixelCoord, vec2 fontSize, float value, float digits, float decimals) {
    vec2 charCoord = (fragCoord - pixelCoord) / fontSize;
    if (charCoord.y < 0.0 || charCoord.y >= 1.0) return 0.0;
    float bits = 0.0;
    float digitIndex1 = digits - floor(charCoord.x) + 1.0;
    if (-digitIndex1 <= decimals) {
        float pow1 = pow(10.0, digitIndex1);
        float absValue = abs(value);
        float pivot = max(absValue, 1.5) * 10.0;
        if (pivot < pow1) {
            if (value < 0.0 && pivot >= pow1 * 0.1) bits = 1792.0;
        } else if (digitIndex1 == 0.0) {
            if (decimals > 0.0) bits = 2.0;
        } else {
            value = digitIndex1 < 0.0 ? fract(absValue) : absValue * 10.0;
            bits = DigitBin(int(mod(value / pow1, 10.0)));
        }
    }
    return floor(mod(bits / pow(2.0, floor(fract(charCoord.x) * 4.0) + floor(charCoord.y * 5.0) * 4.0), 2.0));
}

vec2 fontSize = vec2(4, 5) * vec2(5, 3);

vec2 grid(int x, int y) { return fontSize.xx * vec2(1, ceil(fontSize.y / fontSize.x)) * vec2(x, y) + vec2(2); }

// https://www.shadertoy.com/view/lsf3WH
// Noise - value - 2D by iq
float noise(vec2 p) {
    vec2 i = floor(p);
    vec2 f = fract(p);
    vec2 u = f * f * (3.0 - 2.0 * f);
    return mix(mix(hash12(i + vec2(0.0, 0.0)), hash12(i + vec2(1.0, 0.0)), u.x), mix(hash12(i + vec2(0.0, 1.0)), hash12(i + vec2(1.0, 1.0)), u.x), u.y);
}

float fbm(vec2 uv) {
    float f = 0.0;
    mat2 m = mat2(1.6, 1.2, -1.2, 1.6);
    f = 0.5000 * noise(uv);
    uv = m * uv;
    f += 0.2500 * noise(uv);
    uv = m * uv;
    f += 0.1250 * noise(uv);
    uv = m * uv;
    f += 0.0625 * noise(uv);
    uv = m * uv;
    return f;
}


#define gChromaticAberrationIntensity 0.0
#define gChromaticAberrationDistance 1.

#define gVignetteIntensity 1.
#define gVignetteSmoothness 1.6
#define gVignetteRoundness 1.

#define gTonemapExposure 1
#define gFlash 0
#define gFlashSpeed 60

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
    col.r = texture(composite, uv + shift).r;
    col.g = texture(composite, uv).g;
    col.b = texture(composite, uv - shift).b;
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

void main() {
    vec2 uv = gl_FragCoord.xy / resolution.xy;

    initBeat();

    // vec3 col = texture(composite, uv).rgb;
    vec3 col = chromaticAberration(uv);
    col = mix(col, vec3(1, 1, 1), PrintValue(gl_FragCoord.xy, grid(24, 3), fontSize, bpm, 1.0, 3.0));

    col = PBRNeutralToneMapping(col * gTonemapExposure);
    col *= vignette(uv);
    col = invert(col, uv);
    col = flash(col);
    // col = blend(col);

    outColor = vec4(col, 1);
}