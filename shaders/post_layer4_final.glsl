#version 460 core

#pragma include "shaders/_common.glsl"

#define gVignetteIntensity 1
#define gVignetteSmoothness 1.6
#define gVignetteRoundness 1.

#define gTonemapExposure 1

float vignette(vec2 uv) {
    vec2 d = abs(uv - 0.5) * gVignetteIntensity;
    float roundness = (1.0 - gVignetteRoundness) * 6.0 + gVignetteRoundness;
    d = pow(d, vec2(roundness));
    return pow(saturate(1.0 - dot(d, d)), gVignetteSmoothness);
}

vec3 invert(vec3 c, vec2 uv) {
    if (hash12(vec2(floor(uv.y * 3202.0), beat)) < slider_ps_invert) {
        return vec3(1.0) - c;
    } else {
        return c;
    }
}

vec3 flash(vec3 col) {
    col = mix(col, vec3(1.0), slider_flash * saturate(cos(time * PI * .5 * 30)));

    if (slider_flash == 1.0) {
        col = vec3(1.0);
    }

    return col;
}

vec3 whiteOut(vec3 col) {
    float t = button_white_out.z;
    col = mix(col, vec3(1), exp(-0.7 * t));
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

vec3 drawBPM(vec2 uv) {
    vec3 col = vec3(0);

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

    return col;
}

vec3 drawBeat(vec2 uv) {
    vec3 col = vec3(0);

    uv *= 8;

    uv -= vec2(1.5, 0.17);
    uv.x *= resolution.x / resolution.y;

    float a = 0.25;
    float grid = floor(uv.x / a);
    uv.x = mod(uv.x, a) - a * 0.5;

    float b = mod(beat, 4);

    if (grid >= 0 && grid < 4) {
        float d = length(uv) - 0.1;
        if (grid <= b) {
            col += smoothstep(0.01, -0.01, d);
        } else {
            col += smoothstep(0.01, -0.01, d) * smoothstep(-0.02, -0.01, d);
        }
    }

    return col;
}

vec3 drawSpectrum(sampler1D tex, vec2 uv) {
    vec3 col = vec3(0);

    uv *= 8;

    uv -= vec2(2.5, 0.08);
    uv.x *= resolution.x / resolution.y;

    float a = 0.1;
    float grid = floor(uv.x / a);
    uv.x = mod(uv.x, a) - a * 0.5;

    float div = 48;

    if (grid >= 0 && grid < div) {
        float u = float(grid + 1) / div;
        float vol = texture(tex, u).r;
        float d = sdBox(uv - vec2(0, 0.1 * vol), vec2(0.03, 0.1 * vol));
        col += smoothstep(0.01, -0.01, d);
    }

    return col;
}

void main() {
    vec2 uv = gl_FragCoord.xy / resolution.xy;

    initBeat();

    vec3 col = texture(post_layer3_chromatic_aberration, uv).rgb;

    // col = PBRNeutralToneMapping(col * gTonemapExposure);
    col *= vignette(uv);
    col = invert(col, uv);
    col = flash(col);
    col = whiteOut(col);

    col = mix(col, vec3(0), slider_dark);

    // if (mod(beat, 2) < 1) col = invertPattern(col, uv);

    col += drawBPM(uv);
    col += drawBeat(uv);
    col += drawSpectrum(spectrum_smooth, uv);

    // SetAlign(Align_Center_Bottom);
    // col += Print_Number(uv, button_white_out.z, 5, 3);

    outColor = vec4(col, 1);
}