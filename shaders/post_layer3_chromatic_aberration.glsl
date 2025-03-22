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

// https://www.shadertoy.com/view/lsf3WH
// Noise - value - 2D by iq
float noise2d(vec2 p) {
    vec2 i = floor(p);
    vec2 f = fract(p);
    vec2 u = f * f * (3.0 - 2.0 * f);
    return mix(mix(hash12(i + vec2(0.0, 0.0)), hash12(i + vec2(1.0, 0.0)), u.x),
               mix(hash12(i + vec2(0.0, 1.0)), hash12(i + vec2(1.0, 1.0)), u.x), u.y);
}

float fbm(vec2 uv) {
    float f = 0.0;
    mat2 m = mat2(1.6, 1.2, -1.2, 1.6);
    f = 0.5000 * noise2d(uv);
    uv = m * uv;
    f += 0.2500 * noise2d(uv);
    uv = m * uv;
    f += 0.1250 * noise2d(uv);
    uv = m * uv;
    f += 0.0625 * noise2d(uv);
    uv = m * uv;
    return f;
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

// https://www.shadertoy.com/view/4tlyD8
vec3 chromaticAberration(sampler2D tex, vec2 uv, vec2 direction) {
    int sampleCount = 20;
    float blur = 0.3;

    vec2 velocity = direction * blur;
    float inverseSampleCount = 1.0 / float(sampleCount);

    mat3x2 increments =
        mat3x2(
            velocity * 1.0 * inverseSampleCount,
            velocity * 2.0 * inverseSampleCount,
            velocity * 4.0 * inverseSampleCount);

    vec3 acc = vec3(0);
    mat3x2 offsets = mat3x2(0);

    for (int i = 0; i < sampleCount; i++) {
        acc.r += texture(tex, saturate(uv + offsets[0])).r;
        acc.g += texture(tex, saturate(uv + offsets[1])).g;
        acc.b += texture(tex, saturate(uv + offsets[2])).b;
        offsets -= increments;
    }

    return acc * inverseSampleCount;
}

void main() {
    vec2 uv = gl_FragCoord.xy / resolution.xy;

    initBeat();
    vec2 direction = vec2(0.0);

    // Lens Distortion
    if (slider_ca_lens > 0.0) {
        vec2 diff = uv - 0.5;
        uv = diff * mix(1.0, 0.8, slider_ca_lens) + 0.5;
        direction += slider_ca_lens * pow(length(diff), 10) * diff * 100;
    }

    // Cyclic Noise
    if (slider_ca_cyclic > 0.0) {
        float cnoise = cyclicNoise(vec3(uv * 3., beat)) - 0.5;
        direction += slider_ca_cyclic * vec2(cos(cnoise * TAU), sin(cnoise * TAU)) * cnoise;
    }

    // Voronoi
    if (slider_ca_voronoi > 0.0) {
        float d1, d2;
        vec2 idx;
        ManhattanVoronoi2D(vec2(uv * 2.0 + beatPhase + hash21(floor(beat))), d1, d2, idx);
        vec2 velo = hash22(idx + vec2(100.0)) - 0.5;
        // rot(uv, velo.x)
        direction += slider_ca_voronoi * velo;
    }

    // Glitch
    // https://www.shadertoy.com/view/M32cRc
    if (slider_ca_glitch > 0.0) {
        vec2 p = uv;
        float amp = 1;
        repeat(i, 5) {
            vec2 cell = floor(p / vec2(0.2, .05) / amp);
            vec3 rnd = hash33(vec3(cell, floor(float(i) * 3 + beatPhase * 10)));
            p += (rnd.xy - 0.5) * step(fract(beat), rnd.z) * amp;
            amp *= 0.75;
        }
        direction += slider_ca_glitch * kick * (p - uv) ;
    }

    // X Shift
    if (slider_ca_xshift > 0.0) {
        direction += slider_ca_xshift * kick * vec2(1, 0) *
            (fbm(vec2(uv.y * 1000, 10 * beatPhase)) - 0.5) *
            step(0.5, hash12(vec2(floor(uv.y / 400), beatPhase)));
    }

    uv += direction;
    vec3 col = chromaticAberration(post_layer2_bloom_final, uv, direction);

    outColor = vec4(col, 1);
}