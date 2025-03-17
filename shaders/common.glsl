out vec4 outColor;

#pragma include "./shaders/uniforms.glsl"

uniform sampler2D pattern;
uniform sampler2D raymarching;
uniform sampler2D transcendental_cube;
uniform sampler2D composite;

#define PI acos(-1)
#define TAU (2. * PI)
#define saturate(x) clamp(x, 0, 1)
#define phase(x) (floor(x) + .5 + .5 * cos(TAU * .5 * exp(-5. * fract(x))))

float bpm, beat, beatTau, beatPhase;

void initBeat()
{
    // 7bitずつ分けてBPMを受け取る
    float msb = sliders[24];
    float lsb = sliders[25];

    bpm = (lsb * 127) + (msb * 127) * 128;
    beat = time * bpm / 60.0;
    beatTau = beat * TAU;
    beatPhase = phase(beat);
}

float scene;

// sliders
#define slider_motion_blur sliders[0]
#define slider_raymarching sliders[1]
#define slider_flash sliders[2]

// Hash without Sine by David Hoskins.
// https://www.shadertoy.com/view/4djSRW
float hash11(float p) {
    p = fract(p * .1031);
    p *= p + 33.33;
    p *= p + p;
    return fract(p);
}

float hash12(vec2 p) {
    vec3 p3 = fract(vec3(p.xyx) * .1031);
    p3 += dot(p3, p3.yzx + 33.33);
    return fract((p3.x + p3.y) * p3.z);
}

vec3 hash31(float p) {
    vec3 p3 = fract(vec3(p) * vec3(.1031, .1030, .0973));
    p3 += dot(p3, p3.yzx + 33.33);
    return fract((p3.xxy + p3.yzz) * p3.zyx);
}

vec2 hash22(vec2 p) {
    vec3 p3 = fract(vec3(p.xyx) * vec3(.1031, .1030, .0973));
    p3 += dot(p3, p3.yzx + 33.33);
    return fract((p3.xx + p3.yz) * p3.zy);
}

vec2 hash23(vec3 p3) {
    p3 = fract(p3 * vec3(.1031, .1030, .0973));
    p3 += dot(p3, p3.yzx + 33.33);
    return fract((p3.xx + p3.yz) * p3.zy);
}

float sdBox(vec3 p, vec3 b) {
    vec3 q = abs(p) - b;
    return length(max(q, 0)) + min(0, max(q.x, max(q.y, q.z)));
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