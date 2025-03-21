#version 460 core

#pragma include "shaders/_common.glsl"

void diamond(vec2 uv, inout vec3 col) {
    vec2 p = uv;

    p += vec2(0.0, 0.1);

    rot(p, TAU / 8.);

    float a = 8;

    p *= a;
    vec2 grid = floor(p);

    p = mod(p, 1) - 0.5;

    vec2 abs_grid = abs(grid);

    float w = 2;
    if (mod(beat, 4) > 3) w += 1;
    if (mod(beat, 8) > 7) w += 6;

    if (abs_grid.x <= w && abs_grid.y <= w) {
        float a = 1;
        float[5] ary = float[](
            (dot((grid), a * vec2(1, -1))),
            (dot((grid), a * vec2(1, 1))),
            abs(dot((grid), a * vec2(1, -1))),
            abs(dot((grid), a * vec2(1, 1))),
            hash12(grid + 32 * floor(beat)) * 10.);

        float b = mod(beat / 4, 5.);
        float c = ary[int(b)];
        // c = hash12(grid + 32 * floor(beat)) * 10.;
        float d = saturate(cos(beat * TAU - c * TAU / 15));
        col += sdBox(p, vec2(0.45 * d)) < 0.0 ? pal(fract(beat)) * d : vec3(0.0);
    }
}

int TEXT_DRAW2_LEN = 5;

int TEXT_DRAW2[] = int[](
    C_D,
    C_R,
    C_A,
    C_W,
    C_2
);

void text_cell(vec2 uv, inout vec3 col) {
    float a = 4;

    vec2 grid = floor(uv * a);

    if (mod(beat, 2) < 1) {
        uv.y += beatPhase * floor(2 - hash11(grid.x + floor(beat)) * 4);
    } else {
        uv.x += beatPhase * floor(2 - hash11(grid.y + floor(beat)) * 4);
    }

    uv *= a;
    uv = fract(uv);

    SetAspect(vec2(1), 2, true, true);
    SetAlign(Align_Center_Center);
    SetFontName(NAME_RECEIPT);
    // SetFontName(NAME_ORBITRON);
    SetFontStyle(STYLE_NORMAL);
    float rnd = hash12(grid + beatPhase * 0.0001);
    int code = C_0 + int((C_Z - C_0) * rnd);

    // code = TEXT_DRAW2[int(beat + grid.y + 2 + grid.x) % TEXT_DRAW2_LEN];

    Stack_Char(code);
    col += Render_Char(uv);

    for(int i = 0; i < TEXT_DRAW2_LEN; i++) {
        if (code == TEXT_DRAW2[i]) {
            col *= vec3(1, 0, 1);
            break;
        }
    }

    // col *= pal(fract(beatPhase + 10 * (length(grid))));
}

void main() {
    vec2 uv = (2. * gl_FragCoord.xy - resolution.xy) / resolution.x;
    vec2 uv0 = gl_FragCoord.xy / resolution.xy;

    initBeat();

    vec3 col = vec3(0);

    float id = mod(beat / 2, 2);

    if (id <= 1) {
        diamond(uv, col);
    } else {
        text_cell(uv, col);
    }

    text_cell(uv, col);
    diamond(uv, col);

    // col += saturate(cos(beat * TAU));

    outColor = vec4(col, 1);
}