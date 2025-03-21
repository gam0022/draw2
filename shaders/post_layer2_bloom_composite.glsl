#version 440

#pragma include "shaders/_common.glsl"

void main() {
    vec2 uv = gl_FragCoord.xy / resolution.xy;
    vec3 col = texture(post_layer1, uv).rgb;
    vec3 bloom_blur = texture(post_layer2_bloom_blur, uv).rgb;

    float bloom_intensity = 1;

    if (int(button_tscube_scene.w) % 2 == 1) {
        bloom_intensity = 0;
    }

    col = col + bloom_blur * bloom_intensity;

    outColor = vec4(col, 1);
}