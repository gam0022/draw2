#version 460 core

#pragma include "shaders/_common.glsl"

vec3 filterLaplacian(sampler2D tex, vec2 uv, vec2 uv_offset) {
    vec3 sum = vec3(0);
    float offsetx = uv_offset.x;
    float offsety = uv_offset.y;
    for (int i = -1; i < 2; i++) {
        for (int j = -1; j < 2; j++) {
            vec2 offsets = vec2(offsetx * j, offsety * i);
            int index = i * 3 + j;
            float weight = (index == 4) ? -8.0 : 1.0;
            sum += texture(tex, uv + offsets).xyz * weight;
        }
    }
    return sum;
}

float Manhattan2D(vec2 p) { return abs(p.x) + abs(p.y); }

void ManhattanVoronoi2D(vec2 p, inout float d1, inout float d2, inout vec2 idx) {
    vec2 cellPos = floor(p);
    vec2 localPos = p - cellPos;
    d1 = 100.0;

    for (int i = -1; i <= 1; i++) {
        for (int j = -1; j <= 1; j++) {
            vec2 cellOffset = vec2(i, j);
            vec2 pointPosition = cellOffset + hash22(cellPos + cellOffset);

            float dist = Manhattan2D(localPos - pointPosition);

            if (dist < d1) {
                d2 = d1;
                d1 = dist;
                idx = cellPos + cellOffset;
            } else if (dist < d2) {
                d2 = dist;
            }
        }
    }
}

void main() {
    vec2 uv = gl_FragCoord.xy / resolution.xy;

    initBeat();

    vec3 col = texture(composite, uv).rgb;

    if (false) {
        // ラプラシアンフィルター
        vec2 offsets = 1.0 / resolution.xy;
        col = filterLaplacian(composite, uv, offsets);
    }

    if (false) {
        float d1, d2;
        vec2 idx;
        ManhattanVoronoi2D(vec2(uv * 5.0 + floor(time) * 10.0), d1, d2, idx);
        vec2 velo = hash22(idx + vec2(100.0)) * 2.0 - 1.0;
        ivec2 velo_int = ivec2(velo * (100.0 + beatPhase));
        vec2 dxy = 1.0 / resolution.xy;
        col = texture(composite, mod(uv + vec2(velo_int * dxy), 1.0)).rgb;
    }

    outColor = vec4(col, 1);
}