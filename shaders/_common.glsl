out vec4 outColor;

#pragma include "shaders/_uniforms.glsl"

// sliders
#define slider_motion_blur sliders[0]
#define slider_scene3d sliders[1]
#define slider_flash sliders[2]
#define slider_bpm_scale sliders[3]
#define slider_dark sliders[4]
#define slider_tscube_pram_x sliders[5]
#define slider_tscube_pram_y sliders[6]
#define slider_tscube_silence sliders[7]

#define slider_ca_lens sliders[8]
#define slider_ca_cyclic sliders[9]
#define slider_ca_voronoi sliders[10]
#define slider_ca_glitch sliders[11]
#define slider_ca_xshift sliders[12]
#define slider_ps_invert sliders[13]


// buttons
#define button_post_laplacian buttons[0]

#define button_white_out buttons[8]

#define button_tscube_scene buttons[20]
#define button_tscube_camera buttons[21]

#define button_tscube_wall buttons[24]
#define button_tscube_wall_shader buttons[25]
#define button_tscube_wall_warning buttons[26]

uniform sampler2D scene2d;
uniform sampler2D scene3d;
uniform sampler2D transcendental_cube;
uniform sampler2D composite;
uniform sampler2D post_layer1;
uniform sampler2D post_layer2_bloom_blur;
uniform sampler2D post_layer2_bloom_composite;
uniform sampler2D post_layer3_chromatic_aberration;
uniform sampler2D post_layer4_final;

uniform sampler2D draw_logo;
uniform sampler2D draw_logo_tokyo;
uniform sampler2D gam0022;
uniform sampler2D toufu0301;
uniform sampler2D toufu0301_full;

#define PI acos(-1)
#define TAU (2. * PI)
#define saturate(x) clamp(x, 0, 1)
#define phase(x) (floor(x) + .5 + .5 * cos(TAU * .5 * exp(-5. * fract(x))))
#define remap(x, a, b, c, d) ((((x) - (a)) / ((b) - (a))) * ((d) - (c)) + (c))
#define repeat(i, n) for (int i = 0; i < (n); i++)

float bpm, beat, beatTau, beatPhase;
float kick;

void initBeat() {
    // 7bitずつ分けてBPMを受け取る
    float msb = sliders[24];
    float lsb = sliders[25];

    bpm = 128;
    bpm = (lsb * 127) + (msb * 127) * 128;

    float scale = 1 + floor(slider_bpm_scale * 4);
    bpm *= scale;

    beat = time * bpm / 60.0;
    beatTau = beat * TAU;
    beatPhase = phase(beat);
    kick = saturate(cos(beatTau));
}

float scene;

// Hash without Sine by David Hoskins.
// https://www.shadertoy.com/view/4djSRW
//  1 out, 1 in...
float hash11(float p) {
    p = fract(p * .1031);
    p *= p + 33.33;
    p *= p + p;
    return fract(p);
}

//----------------------------------------------------------------------------------------
//  1 out, 2 in...
float hash12(vec2 p) {
    vec3 p3 = fract(vec3(p.xyx) * .1031);
    p3 += dot(p3, p3.yzx + 33.33);
    return fract((p3.x + p3.y) * p3.z);
}

//----------------------------------------------------------------------------------------
//  1 out, 3 in...
float hash13(vec3 p3) {
    p3 = fract(p3 * .1031);
    p3 += dot(p3, p3.zyx + 31.32);
    return fract((p3.x + p3.y) * p3.z);
}
//----------------------------------------------------------------------------------------
// 1 out 4 in...
float hash14(vec4 p4) {
    p4 = fract(p4 * vec4(.1031, .1030, .0973, .1099));
    p4 += dot(p4, p4.wzxy + 33.33);
    return fract((p4.x + p4.y) * (p4.z + p4.w));
}

//----------------------------------------------------------------------------------------
//  2 out, 1 in...
vec2 hash21(float p) {
    vec3 p3 = fract(vec3(p) * vec3(.1031, .1030, .0973));
    p3 += dot(p3, p3.yzx + 33.33);
    return fract((p3.xx + p3.yz) * p3.zy);
}

//----------------------------------------------------------------------------------------
///  2 out, 2 in...
vec2 hash22(vec2 p) {
    vec3 p3 = fract(vec3(p.xyx) * vec3(.1031, .1030, .0973));
    p3 += dot(p3, p3.yzx + 33.33);
    return fract((p3.xx + p3.yz) * p3.zy);
}

//----------------------------------------------------------------------------------------
///  2 out, 3 in...
vec2 hash23(vec3 p3) {
    p3 = fract(p3 * vec3(.1031, .1030, .0973));
    p3 += dot(p3, p3.yzx + 33.33);
    return fract((p3.xx + p3.yz) * p3.zy);
}

//----------------------------------------------------------------------------------------
//  3 out, 1 in...
vec3 hash31(float p) {
    vec3 p3 = fract(vec3(p) * vec3(.1031, .1030, .0973));
    p3 += dot(p3, p3.yzx + 33.33);
    return fract((p3.xxy + p3.yzz) * p3.zyx);
}

//----------------------------------------------------------------------------------------
///  3 out, 2 in...
vec3 hash32(vec2 p) {
    vec3 p3 = fract(vec3(p.xyx) * vec3(.1031, .1030, .0973));
    p3 += dot(p3, p3.yxz + 33.33);
    return fract((p3.xxy + p3.yzz) * p3.zyx);
}

//----------------------------------------------------------------------------------------
///  3 out, 3 in...
vec3 hash33(vec3 p3) {
    p3 = fract(p3 * vec3(.1031, .1030, .0973));
    p3 += dot(p3, p3.yxz + 33.33);
    return fract((p3.xxy + p3.yxx) * p3.zyx);
}

//----------------------------------------------------------------------------------------
// 4 out, 1 in...
vec4 hash41(float p) {
    vec4 p4 = fract(vec4(p) * vec4(.1031, .1030, .0973, .1099));
    p4 += dot(p4, p4.wzxy + 33.33);
    return fract((p4.xxyz + p4.yzzw) * p4.zywx);
}

//----------------------------------------------------------------------------------------
// 4 out, 2 in...
vec4 hash42(vec2 p) {
    vec4 p4 = fract(vec4(p.xyxy) * vec4(.1031, .1030, .0973, .1099));
    p4 += dot(p4, p4.wzxy + 33.33);
    return fract((p4.xxyz + p4.yzzw) * p4.zywx);
}

//----------------------------------------------------------------------------------------
// 4 out, 3 in...
vec4 hash43(vec3 p) {
    vec4 p4 = fract(vec4(p.xyzx) * vec4(.1031, .1030, .0973, .1099));
    p4 += dot(p4, p4.wzxy + 33.33);
    return fract((p4.xxyz + p4.yzzw) * p4.zywx);
}

//----------------------------------------------------------------------------------------
// 4 out, 4 in...
vec4 hash44(vec4 p4) {
    p4 = fract(p4 * vec4(.1031, .1030, .0973, .1099));
    p4 += dot(p4, p4.wzxy + 33.33);
    return fract((p4.xxyz + p4.yzzw) * p4.zywx);
}

float sdBox(vec3 p, vec3 b) {
    vec3 q = abs(p) - b;
    return length(max(q, 0)) + min(0, max(q.x, max(q.y, q.z)));
}

float sdBox(in vec2 p, in vec2 b) {
    vec2 d = abs(p) - b;
    return length(max(d, 0.0)) + min(max(d.x, d.y), 0.0);
}

void U(inout vec4 m, float d, float a, float b, float c) {
    if (d < m.x) m = vec4(d, a, b, c);
}

void rot(inout vec2 p, float a) { p *= mat2(cos(a), sin(a), -sin(a), cos(a)); }

vec3 pal(float h) {
    vec3 col = vec3(0.5) + 0.5 * cos(TAU * (vec3(0.0, 0.33, 0.67) + h));
    return mix(col, vec3(1), 0.1 * floor(h));
}

void pmod(inout vec2 p, float s) {
    float n = TAU / s;
    float a = PI / s - atan(p.x, p.y);
    a = floor(a / n) * n;
    rot(p, a);
}

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

float PrintValue(vec2 fragCoord, vec2 pixelCoord, vec2 fontSize, float value, float digits,
                 float decimals) {
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
    return floor(mod(
        bits / pow(2.0, floor(fract(charCoord.x) * 4.0) + floor(charCoord.y * 5.0) * 4.0), 2.0));
}

vec2 fontSize = vec2(4, 5) * vec2(5, 3);

vec2 grid(int x, int y) {
    return fontSize.xx * vec2(1, ceil(fontSize.y / fontSize.x)) * vec2(x, y) + vec2(2);
}

#pragma include "shaders/_font.glsl"
