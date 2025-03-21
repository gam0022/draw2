#version 460 core

#pragma include "shaders/_common.glsl"

vec3 diamond(vec2 uv) {
    vec3 col = vec3(0);

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
        float[4] ary = float[](
            (dot((grid), a * vec2(1, -1))),
            (dot((grid), a * vec2(1, 1))),
            abs(dot((grid), a * vec2(1, -1))),
            // abs(dot((grid), a * vec2(1, 1)))
            hash12(grid + 32 * floor(beat)) * 10.
        );

        float b = mod(beat / 2, 4.);
        float c = ary[int(b)];
        float d = saturate(cos(beat * TAU - c * TAU / 20));
        col += sdBox(p, vec2(0.45 * d)) < 0.0 ? pal(fract(beat)) * d : vec3(0.0);
    }

    return col;
}

int TEXT_DRAW2_LEN = 5;
int TEXT_DRAW2[] = int[](
    C_D,
    C_R,
    C_A,
    C_W,
    C_2
);

int TEXT_GAM0022_LEN = 7;
int TEXT_GAM0022[] = int[](
    C_G,
    C_A,
    C_M,
    C_0,
    C_0,
    C_2,
    C_2
);

int TEXT_TOHU0301_LEN = 8;
int TEXT_TOHU0301[] = int[](
    C_T,
    C_O,
    C_F,
    C_U,
    C_0,
    C_3,
    C_0,
    C_1
);

vec3 text_cell(vec2 uv) {
    vec3 col = vec3(0);

    float a = 2;

    vec2 grid = floor(uv * a);

    if (mod(beat, 1) < 1) {
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
    int code = C_0 + int((C_Z + - C_0) * rnd);

    // code = TEXT_DRAW2[int(beat + grid2.y + 2 + grid2.x) % TEXT_DRAW2_LEN];

    Stack_Char(code);

    vec3 ccol = vec3(1);

    for(int i = 0; i < TEXT_DRAW2_LEN; i++) {
        if (code == TEXT_DRAW2[i]) {
            ccol *= vec3(1, 0, 1);
            break;
        }
    }

    // for(int i = 0; i < TEXT_GAM0022_LEN; i++) {
    //     if (code == TEXT_GAM0022[i]) {
    //         ccol *= vec3(0, 0, 1);
    //         break;
    //     }
    // }

    // for(int i = 0; i < TEXT_TOHU0301_LEN; i++) {
    //     if (code == TEXT_TOHU0301[i]) {
    //         ccol *= vec3(0, 1, 0);
    //         break;
    //     }
    // }

    col += ccol * Render_Char(uv);

    // col *= pal(fract(beatPhase + 10 * (length(grid))));

    return col;
}

vec3 logo(vec2 uv) {
    vec3 col = vec3(0.0);

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
        col += 0.9 * col_tofu0301.rgb;
    }
    else if (rnd < 1.7) {
        vec4 col_gam0022 = texture(gam0022, uv);
        col += 1.2 * col_gam0022.rgb;
    } else {
        vec4 texDraw = texture(draw_logo, uv);
        col += 1.2 * texDraw.rgb * texDraw.a;
    }

    // if (mod(beat, 2) < 1) col = 1 - col;

    return col;
}

vec3 print_text(vec2 uv) {
    vec3 col = vec3(0);

    // uv *= 2;
    // uv.x += beatPhase;
    // rot(uv, beatPhase * .3);
    uv = fract(uv);
    SetAspect(resolution.xy, 4, true, true);
    SetAlign(Align_Center_Center);
    // SetFontName(NAME_RECEIPT);
    SetFontName(NAME_ORBITRON);
    SetFontStyle(STYLE_NORMAL);
    // SetFontStyle(int(beat) % 6);

    for(int i = 0; i < TEXT_DRAW2_LEN; i++) {
        Stack_Char(TEXT_DRAW2[i]);
    }

    col += Render_Char(uv);

    return col;
}

vec3 print_draw_logo(vec2 uv) {
    vec3 col = vec3(0);
    vec4 col_draw = texture(draw_logo, uv * 0.3 + 0.5);
    col += col_draw.rgb * col_draw.a;
    return col;
}

void main() {
    vec2 uv = (2. * gl_FragCoord.xy - resolution.xy) / resolution.y;
    vec2 uv0 = gl_FragCoord.xy / resolution.xy;

    initBeat();

    vec3 col = vec3(0);

    float id = mod(beat / 1, 2);

    col += 1.4 * print_draw_logo(uv);
    // col += 2 * diamond(uv);
    // col += 1.3 * text_cell(uv);
    // col += logo(uv);
    // col += print_text(uv0);
    // col += kick;
    // if (mod(beat, 2) < 1) col = 1 - col;

    outColor = vec4(col, 1);
}