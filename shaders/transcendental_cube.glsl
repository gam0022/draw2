#version 460 core

#pragma include "shaders/_common.glsl"

#define tri(x) (1. - 4. * abs(fract(x) - .5))
#define phase(x) (floor(x) + .5 + .5 * cos(TAU * .5 * exp(-5. * fract(x))))

// hemisphere hash function based on a hash by Slerpy
vec3 hashHs(vec3 n, vec3 seed) {
    vec2 h = hash23(seed);
    float a = h.x * 2. - 1.;
    float b = TAU * h.y * 2. - 1.;
    float c = sqrt(1. - a * a);
    vec3 r = vec3(c * cos(b), a, c * sin(b));
    return r;
}

// global vars
vec3 ro, target;
float fov;
vec3 scol;
vec3 boxPos;

// Mode
int mode = 0;
#define NORMAL 0
#define OPENING 1
#define WALL 2
#define WALL_SHADER 3
#define WALL_WARNING 4

// Timeline
float prevEndTime = 0., t = 0.;
#define TL(end) if (t = beat - prevEndTime, beat < (prevEndTime = end))

// Material Types
#define VOL 0.
#define SOL 1.

void opUnion(inout vec4 m, float d, float type, float roughness_or_emissive, float hue) {
    if (d < m.x) m = vec4(d, type, roughness_or_emissive, hue);
}

vec3 pal(vec4 m) {
    // Integer part: Blend ratio with white (0-10)
    // Decimal part: Hue (0-1)
    vec3 col = vec3(.5) + .5 * cos(TAU * (vec3(0., .33, .67) + m.w));
    return mix(col, vec3(.5), .1 * floor(m.w));
}

// Hexagons - distance by iq
// https://www.shadertoy.com/view/Xd2GR3
// return: { 2d cell id (vec2), distance to border, distnace to center }
#define INV_SQRT3 0.5773503
vec4 hexagon(inout vec2 p) {
    vec2 q = vec2(p.x * 2. * INV_SQRT3, p.y + p.x * INV_SQRT3);

    vec2 pi = floor(q);
    vec2 pf = fract(q);

    float v = mod(pi.x + pi.y, 3.);

    float ca = step(1., v);
    float cb = step(2., v);
    vec2 ma = step(pf.xy, pf.yx);

    // distance to borders
    float e = dot(ma, 1. - pf.yx + ca * (pf.x + pf.y - 1.) + cb * (pf.yx - 2. * pf.xy));

    // distance to center
    p = vec2(q.x + floor(.5 + p.y / 1.5), 4. * p.y / 3.) * .5 + .5;
    p = (fract(p) - .5) * vec2(1., .85);
    float f = length(p);

    return vec4(pi + ca - cb * ma, e, f);
}

float warning(vec2 p) {
    vec4 h = hexagon(p);

    float f = fract(hash12(h.xy) + beatPhase);
    f = mix(f, saturate(sin(h.x - h.y + 4. * beatPhase)), .5 + .5 * sin(beatTau / 16.));
    float hex = smoothstep(.1, .11, h.z) * f;

    float mark = 1.;
    float dice = fract(hash12(h.xy) + beatPhase / 4.);

    if (dice < .25) {
        float d = sdBox(p, vec2(.4, dice));
        float ph = phase(beat / 2. + f);
        float ss = smoothstep(1., 1.05, mod(p.x * 10. + 10. * p.y + 8. * ph, 2.));
        mark = saturate(step(0., d) + ss);
    } else {
        vec4[] param_array =
            vec4[](vec4(140., 72., 0., 0.), vec4(0., 184., 482, 0.), vec4(0., 0., 753., 0.),
                   vec4(541., 156., 453., 0.), vec4(112., 0., 301., 0.),             // 0-3
                   vec4(311., 172., 50., 0.), vec4(249., 40., 492., 0.), vec4(0.));  // 4-7

        vec4 param = param_array[int(mod(dice * 33.01, 8.))] / vec2(1200., 675.).xyxy;
        // param = PU;
        vec2 p1 = p - param.xy;
        for (int i = 0; i < 3; i++) {
            p1 = abs(p1 + param.xy) - param.xy;
            rot(p1, TAU * param.z);
        }

        float d = sdBox(p1, vec2(.2, .05));
        mark = saturate(smoothstep(0., .01, d));
    }

    return saturate(hex * mark);
}

vec4 map(vec3 pos, bool isFull) {
    vec4 m = vec4(2, VOL, 0, 0);
    // x: Distance
    // y: MaterialType (VOL or SOL)
    // z: Roughness in (0-1), Emissive when z>1
    // w: ColorPalette

    float roughness = 0.05;
    float a = .1;
    float W = 16.;
    float H = 8.;
    float D = 30.;

    vec3 p1 = pos;

    float boxEmi;

    if (mod(beat, 8.) > 2. + step(56., beat) * 2.) {
        boxEmi = 2.2 * saturate(sin(beatTau * 4.));
    } else {
        boxEmi = 2.2 * abs(cos((beatTau - p1.y) / 4.));
    }

    vec4 _IFS_Rot = vec4(0.34 + beatPhase / 2.3, -0.28, 0.03, 0.);
    vec4 _IFS_Offset = vec4(1.36, 0.06, 0.69, 1.);
    float _IFS_Iteration = phase(tri(beat / 16.) + 3. + (sliders[13] * 3.));
    vec4 _IFS_BoxBase = vec4(1, 1, 1, 0);
    vec4 _IFS_BoxEmissive = vec4(0.05, 1.05, 1.05, 0);

    float hue = 0.5;
    // hue = fract(.12 * beatPhase);
    // hue = fract(beatPhase * .1 + pos.z) + 1.;

    // スライダー
    _IFS_Offset = vec4(2. * slider_tscube_pram_x, 2. * slider_tscube_pram_y, 0.69, 1.);

    bool emi2 = false;
    // emi2 = true;

    // Warning

    if (mode == WALL_WARNING) {
        hue = 0.0;
        _IFS_Iteration = 3 + phase(tri((beat - 4) / 16.));
        emi2 = true;
        _IFS_Rot = vec4(.3 + .1 * sin(beatPhase * TAU / 8.), .9 + .1 * sin(beatPhase * TAU / 8.), .4, 0.);
        _IFS_Offset = vec4(1.4, 0.66, 1.2, 1.);
    }

    if (boxPos.y < 0.) {
        _IFS_Rot *= 0.;
        _IFS_Offset *= 0.;
        _IFS_Iteration = 1.;
    }

    // 減衰
    float atten = 1 - slider_tscube_silence;
    _IFS_Offset *= atten;
    _IFS_Iteration = mix(1, _IFS_Iteration, atten);

    if (mode == OPENING) {
        TL(40.) {
            _IFS_Rot *= 0.;
            _IFS_Offset *= 0.;
            _IFS_Iteration = 1.;
        }
        else TL(56.) {
            float fade = saturate(phase((beat - 56.) / 4.));
            _IFS_Iteration = 1. + fade;
            _IFS_Offset = vec4(1.36, 0.06, 0.69, 1.) * fade;
        }
    }

    // p1 = mod(p1, 8) - 4;

    p1 -= (boxPos + _IFS_Offset.xyz);

    vec3 pp1 = p1;

    for (int i = 0; i < int(_IFS_Iteration); i++) {
        pp1 = p1 + _IFS_Offset.xyz;
        p1 = abs(p1 + _IFS_Offset.xyz) - _IFS_Offset.xyz;
        rot(p1.xz, TAU * _IFS_Rot.x);
        rot(p1.zy, TAU * _IFS_Rot.y);
        rot(p1.xy, TAU * _IFS_Rot.z);
    }

    vec4 mp = m;
    opUnion(m, sdBox(p1, _IFS_BoxBase.xyz), SOL, roughness, 0.5);
    opUnion(m, sdBox(p1, _IFS_BoxEmissive.xyz), SOL, roughness + boxEmi, hue);
    if (emi2) opUnion(m, sdBox(p1, _IFS_BoxEmissive.yzx), SOL, roughness + boxEmi, hue + 0.5);
    opUnion(mp, sdBox(pp1, _IFS_BoxBase.xyz), SOL, roughness, 0.5);
    opUnion(mp, sdBox(pp1, _IFS_BoxEmissive.xyz), SOL, roughness + boxEmi, hue);
    if (emi2) opUnion(mp, sdBox(pp1, _IFS_BoxEmissive.yzx), SOL, roughness + boxEmi, hue + 0.5);

    m = mix(mp, m, fract(_IFS_Iteration));

    float emi = 0;
    hue = 10.;

    vec2 uv;

    // room
    vec3 p2 = abs(pos);
    float hole = sdBox(pos - vec3(0., -H - 0.5, 0.), vec3(1.1) * smoothstep(18., 24., beat));

    // floor and ceil
    uv = (pos.xz) / (H * 2) + 0.5;
    // uv.x /= resolution.x / resolution.y;
    // emi = atten * texture(scene2d, uv).r * 2.;
    // hue = fract(beatPhase * 0.1);
    opUnion(m, max(sdBox(p2 - vec3(0, H + 4., 0), vec3(W, 4., D)), -hole), SOL, roughness + emi * 2., hue);

    // door
    emi = step(p2.x, 2.) * step(p2.y, 2.);
    // if (mod(beat, 2.) < 1.) emi = 1. - emi;
    uv = (pos.xy) / (H * 2) + 0.5;
    uv.x /= resolution.x / resolution.y;
    // emi = atten * texture(scene3d, uv).r;
    opUnion(m, sdBox(p2 - vec3(0, 0, D + a), vec3(W, H, a)), SOL, roughness + emi * 2., hue);

    // wall
    if (isFull) {
        float id = floor((pos.z + D) / 4.);
        hue = 10.;

        emi = step(1., mod(id, 2.)) * step(id, mod(beat * 4., 16.));

        if (mode == OPENING) {
            TL(18.) {}
            else TL(32.) {
                emi = step(1., mod(id, 2.));
            }
        } else if (mode == WALL) {
            int wall_id = int(button_tscube_wall.w) % 5;

            if (wall_id == 0) {
            } else if (wall_id == 1) {
                emi = mix(emi, step(.5, hash12(floor(pos.yz) + 123.23 * floor(beat * 2.))),
                          saturate(beat - pos.y));
            } else if (wall_id == 2) {
                emi = mix(0, pow(hash12(floor(pos.yz) + 123.23 * floor(beat * 2.)), 4.),
                          smoothstep(0, 2, beat));
                hue = 3.65;
            } else if (wall_id == 3) {
                emi = pow(hash12(floor(pos.yz) + 123.23 * floor(beat * 2.)), 4.);
                hue = mix(3.65, hash12(floor(pos.yz) + 123.23 * floor(beat * 8.)),
                          smoothstep(0, 4, beat));
            } else if (wall_id == 4) {
                float fade1 = smoothstep(0., 2., beat);
                float fade2 = smoothstep(2., 4., beat);

                emi = pow(hash12(floor(pos.yz * mix(1., 16., fade1)) + 123.23 * floor(beat * 2.)),
                          4.);
                emi = mix(emi, step(.0, emi) * step(3., mod(floor((pos.z + D) / 2.), 4.)), fade1);
                emi = mix(emi,
                          step(3., mod(floor((pos.z + D) / 2.), 4.)) *
                              step(1., mod(floor(pos.y - pos.z - 4. * beatPhase), 2.)),
                          fade2);

                hue = hash12(floor(pos.yz * mix(1., 16., fade1)) + 123.23 * floor(beat * 8.));
                hue = mix(hue, 10., fade2);
            }
        } else if (mode == WALL_SHADER) {
            uv = (pos.zy) / (H * 2) + 0.5;
            uv.x /= resolution.x / resolution.y;
            vec4 tex = texture(scene2d, fract(uv));
            emi = atten * dot(vec3(0.5), tex.rgb) * smoothstep(1, 3, beat);
            hue = hash13(tex.rgb) * 0.6;
        } else if (mode == WALL_WARNING) {
            hue = 0.;
            float fade1 = smoothstep(0., 4., beat);
            // float fade2 = smoothstep(200., 202., beat);
            float pw = mix(10., 0.6, fade1);
            // pw = mix(pw, 20., fade2);
            emi = pow(warning(pos.zy / 2.), pw) * mix(1., step(0., sin(t * 15. * TAU)), fade1);
            emi = step(0.5, emi) * emi * 1.05;
        }
    }

    opUnion(m, sdBox(p2 - vec3(W + a, 0, 0), vec3(a, H, D)), SOL, roughness + atten * emi * 2., hue);

    return m;
}

vec3 normal(vec3 p) {
    vec2 e = vec2(0, .05);
    return normalize(map(p, false).x - vec3(map(p - e.yxx, false).x, map(p - e.xyx, false).x,
                                            map(p - e.xxy, false).x));
}

// Based on EOT - Grid scene by Virgill
// https://www.shadertoy.com/view/Xt3cWS
void madtracer(vec3 ro1, vec3 rd1, float seed) {
    scol = vec3(0);
    vec2 rand = hash23(vec3(seed, time, time)) * .5;
    float t = rand.x, t2 = rand.y;
    vec4 m1, m2;
    vec3 rd2, ro2, nor2;
    for (int i = 0; i < 130; i++) {
        m1 = map(ro1 + rd1 * t, true);
        // t += m1.y == VOL ? 0.25 * abs(m1.x) + 0.0008 : 0.25 * m1.x;
        t += 0.25 * mix(abs(m1.x) + 0.0032, m1.x, m1.y);
        ro2 = ro1 + rd1 * t;
        nor2 = normal(ro2);
        rd2 = mix(reflect(rd1, nor2), hashHs(nor2, vec3(seed, i, time)), saturate(m1.z));
        m2 = map(ro2 + rd2 * t2, true);
        // t2 += m2.y == VOL ? 0.15 * abs(m2.x) : 0.15 * m2.x;
        t2 += 0.15 * mix(abs(m2.x), m2.x, m2.y);
        scol += .015 * (pal(m2) * max(0., m2.z - 1.) + pal(m1) * max(0., m1.z - 1.));

        // force disable unroll for WebGL 1.0
        if (t < -1.) break;
    }
}

void raymarching(vec3 ro1, vec3 rd1) {
    scol = vec3(0);
    float t = 0.;
    vec4 m;
    for (int i = 0; i < 160; i++) {
        vec3 p = ro1 + rd1 * t;
        m = map(p, true);
        t += m.x;

        if (m.x < 0.01) {
            vec3 light = normalize(vec3(1, 1, -1));
            vec3 albedo = vec3(0.3);
            if (m.z > 1.) albedo = pal(m);
            scol = albedo * (0.5 + 0.5 * saturate(dot(normal(p), light)));
            break;
        }
    }
}

void main() {
    initBeat();

    // シーン全体をスキップ
    if (int(button_tscube_scene.w) % 2 == 0) {
        outColor = vec4(0, 0, 0, 1);
        return;
    }

    // シーン全体
    float time_scene = button_tscube_scene.y;
    float time_ = time_scene;
    if (int(button_tscube_scene.w) == 1) mode = OPENING;

    // 標準壁
    float time_wall = button_tscube_wall.y;
    if (time_wall < time_) {
        time_ = time_wall;
        mode = WALL;
    }

    // 壁シェーダー
    float time_wall_shader = button_tscube_wall_shader.y;
    if (time_wall_shader < time_) {
        time_ = time_wall_shader;
        mode = WALL_SHADER;
    }

    // WALL_WARNING
    float time_wall_warning = button_tscube_wall_warning.y;
    if (time_wall_warning < time_) {
        time_ = time_wall_warning;
        mode = WALL_WARNING;
    }

    // beat関連
    beat = time_ * bpm / 60.0;
    beatTau = beat * TAU;
    beatPhase = phase(beat);

    vec2 uv = gl_FragCoord.xy / resolution.xy;

    boxPos = vec3(0);

    if (mode == OPENING) boxPos.y = mix(-12., 0., smoothstep(20., 48., beat));
    // boxPos.y = mix(boxPos.y, -12., smoothstep(304., 320., beat));

    // Camera
    vec2 noise = hash23(vec3(time, gl_FragCoord)) - .5;  // AA
    vec2 uv2 = (2. * (gl_FragCoord.xy + noise) - resolution.xy) / resolution.x;

    target = boxPos;
    fov = 120;

    // 通常時カメラ
    float dice = hash11(floor(beat / 8. + 2.) * 123.);
    if (dice < .8) {
        float r = 8;
        ro = vec3(r * cos(beatTau / 128.), mix(-6., 6., dice), r * sin(beatTau / 128.));
    } else {
        ro = vec3(9.5 - dice * 20., 1., -12.3);
    }

    // 激しいカメラワーク
    if (int(button_tscube_camera.w) % 2 == 1) {
        dice = hash11(floor(beat / 2) * 123.);
        float rot = phase(beat) * TAU / 3 * sign(dice - 0.5);
        ro = vec3(8. * cos(rot), mix(-6., 6., dice), 8. * sin(rot));
    }

    if (mode == OPENING) {
        TL(8.) {
            ro = vec3(0, -1.36, -12.3 + t * .3);
            target = vec3(0., -2.2, 0.);
            fov = 100.;
        }
        else TL(16.) {
            ro = vec3(9.5, -1.36, -12.3 + t * .3);
            target = vec3(0., -2.2, 0.);
            fov = 100.;
        }
        else TL(20.) {
            ro = vec3(5.5, -5, -1.2);
            target = vec3(0., -8., -0.);
            fov = 100.0 + t;
        }
        else TL(32.) {
            ro = vec3(5.5, -5, -1.2);
            target = vec3(0., -8., -0.);
            fov = 60.0 + t;
        }
        else TL(40.) {
            ro = vec3(10.8, -4.2, -7.2 + t * .1);
            fov = 93.;
        }
        else TL(64.) {
            ro = vec3(0., 1., -12.3);
            target = vec3(0);
            fov = 100. - t;
        }
    } else if (mode == WALL || mode == WALL_SHADER || mode == WALL_WARNING) {
        if (beat < 4) {
            ro = vec3(-5., 1., 18.);
            target = vec3(5.0, -1., 16.);
            fov = 100. - time_;
        }
    }

    vec3 up = vec3(0, 1, 0);
    vec3 fwd = normalize(target - ro);
    vec3 right = normalize(cross(up, fwd));
    up = normalize(cross(fwd, right));
    vec3 rd = normalize(right * uv2.x + up * uv2.y + fwd / tan(fov * TAU / 720.));

// #define DEBUG_SCENE
#ifdef DEBUG_SCENE
    raymarching(ro, rd);
    outColor = vec4(scol, 1.);
#else
    madtracer(ro, rd, hash12(uv2));
    vec3 bufa = texture(transcendental_cube, uv).xyz;
    outColor = saturate(vec4(0.7 * scol + 0.7 * bufa, 1.));

    // outColor.rgb = mix(outColor.rgb, vec3(1, 1, 1), PrintValue(gl_FragCoord.xy, grid(29, 1), fontSize, beat, 1.0, 3.0));
    // outColor.rgb = mix(outColor.rgb, vec3(1, 1, 1), PrintValue(gl_FragCoord.xy, grid(14, 1), fontSize, buttons[24].w, 1.0, 1.0));
#endif
}