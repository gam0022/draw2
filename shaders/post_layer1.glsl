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

void main() {
    vec2 uv = gl_FragCoord.xy / resolution.xy;

    initBeat();

    vec3 col = texture(composite, uv).rgb;

    if (int(button_post_laplacian.w) % 2 == 1) {
        vec2 offsets = 1.0 / resolution.xy;
        col = filterLaplacian(composite, uv, offsets);
    }

    outColor = vec4(col, 1);
}