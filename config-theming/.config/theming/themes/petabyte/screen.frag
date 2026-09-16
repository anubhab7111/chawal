#version 300 es
// petabyte "boudoir" screen shader for Hyprland (decoration:screen_shader)
// Sensual/tasteful post-process: warm rose bloom + soft vignette + gentle film grain.
// Deliberately subtle and light — safe for daily use on an Intel iGPU.
//
// Intentionally does NOT use the `time` uniform: Hyprland requires
// debug:damage_tracking to be disabled for time-varying shaders, which it
// warns will "massively increase GPU utilization." Static per-pixel grain
// gives the same texture without that tradeoff.
precision highp float;

in vec2 v_texcoord;
uniform sampler2D tex;
out vec4 fragColor;

// cheap hash for animated grain
float hash(vec2 p) {
    p = fract(p * vec2(233.34, 851.73));
    p += dot(p, p + 23.45);
    return fract(p.x * p.y);
}

void main() {
    vec2 uv = v_texcoord;
    vec3 base = texture(tex, uv).rgb;

    // --- warm rose bloom -------------------------------------------------
    // Small thresholded bright-pass, blurred with an 8-tap ring, tinted rose.
    vec2 texel = vec2(1.0) / vec2(textureSize(tex, 0));
    vec3 bloom = vec3(0.0);
    const int TAPS = 8;
    for (int i = 0; i < TAPS; i++) {
        float a = 6.2831853 * (float(i) / float(TAPS));
        vec2 off = vec2(cos(a), sin(a)) * texel * 6.0;
        vec3 s = texture(tex, uv + off).rgb;
        // keep only the brighter parts
        bloom += max(s - 0.55, 0.0);
    }
    bloom /= float(TAPS);
    vec3 roseTint = vec3(1.0, 0.40, 0.55);
    base += bloom * roseTint * 0.6;

    // --- rose vignette ---------------------------------------------------
    vec2 d = uv - 0.5;
    float vig = smoothstep(0.85, 0.35, length(d));      // 1 center -> 0 edges
    // darken toward edges, and bleed a faint rose into the falloff
    vec3 edgeRose = vec3(0.16, 0.02, 0.06);
    base = mix(edgeRose, base, mix(0.72, 1.0, vig));

    // --- film grain (static, no time uniform — see header note) ----------
    float g = hash(uv * vec2(textureSize(tex, 0)));
    base += (g - 0.5) * 0.025;

    fragColor = vec4(base, 1.0);
}
