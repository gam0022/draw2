#version 460 core

#pragma include "shaders/_common.glsl"

mat3 getOrthogonalBasis(vec3 direction) {
    direction = normalize(direction);
    vec3 right = normalize(cross(vec3(0, 1, 0), direction));
    vec3 up = normalize(cross(direction, right));
    return mat3(right, up, direction);
}

// https://www.shadertoy.com/view/3tcyD7
float cyclicNoise(vec3 p) {
    float noise = 0.;

    // These are the variables. I renamed them from the original by nimitz
    // So they are more similar to the terms used be other types of noise
    float amp = 1.;
    const float gain = 0.6;
    const float lacunarity = 1.5;
    const int octaves = 8;

    const float warp = 0.3;
    float warpTrk = 1.2;
    const float warpTrkGain = 1.5;

    // Step 1: Get a simple arbitrary rotation, defined by the direction.
    vec3 seed = vec3(-1, -2., 0.5);
    mat3 rotMatrix = getOrthogonalBasis(seed);

    for (int i = 0; i < octaves; i++) {
        // Step 2: Do some domain warping, Similar to fbm. Optional.

        p += sin(p.zxy * warpTrk - 2. * warpTrk) * warp;

        // Step 3: Calculate a noise value.
        // This works in a way vaguely similar to Perlin/Simplex noise,
        // but instead of in a square/triangle lattice, it is done in a sine wave.

        noise += sin(dot(cos(p), sin(p.zxy))) * amp;

        // Step 4: Rotate and scale.

        p *= rotMatrix;
        p *= lacunarity;

        warpTrk *= warpTrkGain;
        amp *= gain;
    }

    return (noise * 0.25 + 0.5);
}

void main() {
    vec2 uv = gl_FragCoord.xy / resolution.xy;

    initBeat();

    int sampleCount = 50;
    float blur = 0.3;
    float falloff = 3.0;

    float noise = cyclicNoise(vec3(uv * 3., beat)) - 0.5;

    vec2 direction = vec2(cos(noise * TAU), sin(noise * TAU)) * noise * fract(beatPhase);
    vec2 velocity = direction * blur;
    float inverseSampleCount = 1.0 / float(sampleCount);

    mat3x2 increments = mat3x2(
        velocity * 1.0 * inverseSampleCount,
        velocity * 2.0 * inverseSampleCount,
        velocity * 4.0 * inverseSampleCount);

    vec3 acc = vec3(0);
    mat3x2 offsets = mat3x2(0);

    for (int i = 0; i < sampleCount; i++) {
        acc.r += texture(post_final, uv + offsets[0]).r;
        acc.g += texture(post_final, uv + offsets[1]).g;
        acc.b += texture(post_final, uv + offsets[2]).b;

        offsets -= increments;
    }

    outColor = vec4(acc * inverseSampleCount, 1);
}