#version 440

#pragma include "shaders/_common.glsl"

float gaussian(float x) {
    const float sigma = 4.0;
    return exp(-(x * x) / (2.0 * sigma * sigma));
}

vec3 getBloom(vec2 uv) {
    vec3 col = vec3(0);
    float total = 0.0;
    const int MAX_BLUR_SIZE = 8;
    float rangefactor = 1;
    for (int x = -MAX_BLUR_SIZE; x < MAX_BLUR_SIZE; x++) {
        for (int y = -MAX_BLUR_SIZE; y < MAX_BLUR_SIZE; y++) {
            vec2 offset = vec2(x, y);
            offset *= rangefactor;
            float weight = gaussian(length(offset));
            vec3 samp = texture(post_layer2_bloom_prefilter, uv + offset / resolution.xy).rgb;
            col += samp * weight;
            total += weight;
        }
    }
    return saturate(col / total);
}

void main() {
    vec2 uv = gl_FragCoord.xy / resolution.xy;

    vec3 col = getBloom(uv);

    outColor = vec4(col, 1);
}