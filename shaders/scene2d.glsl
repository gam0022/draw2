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
        col += sdBox(p, vec2(0.45 * d)) < 0.0 ? 2 * pal(fract(beat)) * d : vec3(0.0);
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
    float a = 2;

    vec2 grid = floor(uv * a);

    if (mod(beat, 2) < 1) {
        uv.y += beatPhase * floor(2 - hash11(grid.x + floor(beat)) * 4);
    } else {
        uv.x += beatPhase * floor(2 - hash11(grid.y + floor(beat)) * 4);
    }

    uv *= a;
    vec2 grid2 = floor(uv);
    uv = fract(uv);

    SetAspect(vec2(1), 2, true, true);
    SetAlign(Align_Center_Center);
    SetFontName(NAME_RECEIPT);
    // SetFontName(NAME_ORBITRON);
    SetFontStyle(STYLE_NORMAL);
    float rnd = hash12(grid2 + beatPhase * 0.0001);
    int code = C_0 + int((C_Z - C_0) * rnd);

    // code = TEXT_DRAW2[int(beat + grid2.y + 2 + grid2.x) % TEXT_DRAW2_LEN];

    Stack_Char(code);
    col += Render_Char(uv) * 1.3;

    for(int i = 0; i < TEXT_DRAW2_LEN; i++) {
        if (code == TEXT_DRAW2[i]) {
            col *= vec3(1, 0, 1);
            break;
        }
    }

    // col *= pal(fract(beatPhase + 10 * (length(grid))));
}

void logo(vec2 uv, inout vec3 col) {
    // vec2 p = uv * 0.8 + 0.5;

    float a = 1;

    vec2 grid = floor(uv * a);

    if (mod(beat, 2) < 1) {
        uv.y += beatPhase * floor(2 - hash11(grid.x + floor(beat)) * 4);
    } else {
        uv.x += beatPhase * floor(2 - hash11(grid.y + floor(beat)) * 4);
    }

    uv *= a;

    vec2 grid2 = floor(uv);

    uv = fract(uv);

    float rnd = hash12(grid2);

    if (rnd < 0.5) {
        vec4 col_tofu0301 = texture(toufu0301, uv);
        col += 1 - col_tofu0301.rgb;
    }
    else if (rnd < 1.5) {
        vec4 col_gam0022 = texture(gam0022, uv);
        col += col_gam0022.rgb;
    } else {
        vec4 texDraw = texture(draw_logo, uv);
        col += texDraw.rgb * texDraw.a;
    }

    // if (mod(beat, 2) < 1) col = 1 - col;
}

void main() {
    vec2 uv = (2. * gl_FragCoord.xy - resolution.xy) / resolution.y;
    vec2 uv0 = gl_FragCoord.xy / resolution.xy;

    initBeat();

    vec3 col = vec3(0);

    float id = mod(beat / 1, 2);

    if (id <= 1) {
        // diamond(uv, col);
    } else {
        // text_cell(uv, col);
    }

    // text_cell(uv, col);
    // diamond(uv, col);
    logo(uv, col);

    // col += saturate(cos(beat * TAU));

    outColor = vec4(col, 1);
}