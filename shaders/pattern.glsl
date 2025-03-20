#version 460 core

#pragma include "./shaders/common.glsl"

void main() {
    vec2 uv0 = gl_FragCoord.xy / resolution.xy;
    vec4 prevColor = texture(pattern, uv0);

    vec2 uv = (2. * gl_FragCoord.xy - resolution.xy) / resolution.x;

    initBeat();

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
        float[5] ary = float[](
            (dot((grid), a * vec2(1, -1))),
            (dot((grid), a * vec2(1, 1))),
            abs(dot((grid), a * vec2(1, -1))),
            abs(dot((grid), a * vec2(1, 1))),
            hash12(grid + 32 * floor(beat)) * 10.
        );

        float b = mod(beat / 2, 5.);
        float c = ary[int(b)];
        // c = hash12(grid + 32 * floor(beat)) * 10.;
        float d = saturate(cos(beat * TAU - c * TAU / 15));
        col += sdBox(p, vec2(0.45 * d)) < 0.0 ? pal(fract(beat)) * d : vec3(0.0);
    }

    col += saturate(cos(beat * TAU));

    outColor = vec4(col, 1);
}