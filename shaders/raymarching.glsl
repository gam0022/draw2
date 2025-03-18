#version 460 core

#pragma include "./shaders/common.glsl"

#define VOL 0.0
#define SOL 1.0

vec4 map(vec3 p);

vec3 normal(vec3 p) {
    vec2 e = vec2(0, .0005);
    return normalize(map(p).x - vec3(map(p - e.yxx).x, map(p - e.xyx).x, map(p - e.xxy).x));
}

vec3 evalLight(vec3 p, vec3 normal, vec3 view, vec3 light, vec3 baseColor, float metallic, float roughness) {
    vec3 ref = mix(vec3(0.04), baseColor, metallic);
    vec3 h = normalize(light + view);
    vec3 diffuse = mix(1.0 - ref, vec3(0.0), metallic) * baseColor / PI;
    float eps = 6e-8;
    float m = clamp(2.0 * (1.0 / (roughness * roughness)) - 2.0, eps, 1.0 / eps);
    vec3 specular = ref * pow(max(0.0, dot(normal, h)), m) * (m + 2.0) / (8.0 * PI);
    return (diffuse + specular) * max(0.0, dot(light, normal));
}

float sdN(vec3 p, float z) {
    rot(p.xy, -0.07 * TAU);
    if (p.x < 0) p.y = -p.y;
    p.x = abs(p.x);
    float w = 0.13;
    float h = 0.07;
    float s = 4;
    float a = w / h / s * p.y;
    return min(sdBox(p, vec3(0.2, h, z)), sdBox(p - vec3(0.25 - a, h * (s - 1), 0), vec3(w - a, h * s, z)));
}

vec4 map(vec3 pos) {
    vec4 m = vec4(1);

    vec3 p = pos;
    float a = 3;
    vec3 of = vec3(0.9, 0.0, 0.1);
    float s = 1;
    // rot(p.xy, pos.z * 0.2);
    p.y -= cos(pos.z * TAU / 32) * 0.3;
    p = mod(p, a) - 0.5 * a;
    p -= of;
    for (int i = 0; i < 3; i++) {
        p = abs(p + of) - of;
        U(m, sdBox(p, vec3(0.4, 0.1, 0.1)), VOL, saturate(cos(beatTau * 4)), 0.4);
        rot(p.xz, TAU * 0.1 + cos(pos.z / 4));
        if (mod(beat, 2) < 1) rot(p.xy, TAU * 0.4 * beatPhase);
    }

    float scale = 1.04;
    s *= scale;
    p *= scale;

    float e = saturate(cos(beatTau - TAU * pos.z / 64));
    U(m, sdBox(p, vec3(1, 0.5, 0.1)) / s, SOL, 1, 10);
    U(m, sdBox(p, vec3(1.1, 0.51, 0.01)) / s, VOL, 4 * e, floor(mod(beat, 2)) * fract(pos.z) + 0 * fract(pos.z / 8));


    return m;
}

vec3 render(vec3 ro, vec3 rd) {
    vec3 col = vec3(0);
    float t = 0;
    for (int i = 0; i < 100; i++) {
        vec3 p = ro + rd * t;
        vec4 m = map(p);
        float d = m.x;
        if (m.y == SOL) {
            t += d * 0.5;
            if (d < t * 0.001) {
                vec3 n = normal(p);
                // col += saturate(dot(n, normalize(vec3(1, 1, -1))));
                col += evalLight(p, n, -rd, normalize(vec3(1, 1, -1)), vec3(1), 0.7, 0.5) * pal(m.w) * m.z;
                break;
            }
        } else {
            t += abs(d) * 0.5 + 0.01;
            col += saturate(0.001 * pal(m.w) * m.z / abs(d));
        }
    }
    col = mix(vec3(0), col, exp(-0.01 * t));
    return col;
}

void main() {
    vec2 uv0 = gl_FragCoord.xy / resolution.xy;
    vec4 prevColor = texture(raymarching, uv0);

    vec2 uv = (2. * gl_FragCoord.xy - resolution.xy) / resolution.x;

    initBeat();

    float len = 4.;
    scene = floor(mod(beat, len * 4) / len);

    vec3 ro = vec3(0, 0, -1);
    ro = vec3(0, 0, beat * 1.);
    float fl = 1;
    vec3 rd = vec3(uv, fl);
    rd = normalize(rd);
    // rot(rd.xz, beatTau / 8);
    // rot(rd.xy, beatTau / 8);
    vec3 col = render(ro, rd);

    // motion blur
    col = mix(prevColor.rgb, col, slider_motion_blur);

    outColor = vec4(col, 1);
}