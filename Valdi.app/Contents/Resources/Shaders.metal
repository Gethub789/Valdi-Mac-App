#include <metal_stdlib>
#include <SwiftUI/SwiftUI_Metal.h>
using namespace metal;

// MARK: - Fisheye Convex Lens Distortion Shader
// Simulates an optical glass hemisphere lens focused directly over the active word,
// magnifying the center text while curving peripheral words backwards along the glass boundary.

[[stitchable]] float2 fisheyeLensDistortion(
    float2 position,
    float2 center,
    float radius,
    float strength
) {
    // Vector from lens focal center to current coordinate
    float2 delta = position - center;
    float dist = length(delta);
    
    // Outside the lens radius, coordinates remain unchanged
    if (dist >= radius || dist <= 0.0001) {
        return position;
    }
    
    // Normalized distance from center (0.0 at center, 1.0 at circumference)
    float normalizedDist = dist / radius;
    
    // Spherical convex distortion formula:
    // Uses smooth Hermite / power curve to bulge center coordinates outward toward the viewer
    float factor = pow(normalizedDist, strength);
    float distortedDist = radius * factor;
    
    // Calculate new sampled coordinate
    float2 direction = delta / dist;
    float2 newPos = center + direction * distortedDist;
    
    return newPos;
}

// MARK: - Ship 3D Spatial Drift Wave Shader
// Warps coordinates with harmonic 3D spatial sine wave currents to create an interstellar drift effect.

[[stitchable]] float2 shipDepthWave(
    float2 position,
    float time,
    float amplitude,
    float frequency
) {
    float offsetX = sin(position.y * frequency + time * 1.5) * amplitude;
    float offsetY = cos(position.x * frequency * 0.7 + time * 1.2) * (amplitude * 0.5);
    
    return position + float2(offsetX, offsetY);
}

// MARK: - Optical Vignette and Chromatic Dispersion Shader
// Applies chromatic aberration and edge falloff for realistic lens dispersion.

[[stitchable]] half4 lensChromaticDispersion(
    float2 position,
    SwiftUI::Layer layer,
    float2 center,
    float radius,
    float aberrationIntensity
) {
    float2 delta = position - center;
    float dist = length(delta);
    
    if (dist >= radius) {
        return layer.sample(position);
    }
    
    float dispersion = (dist / radius) * aberrationIntensity;
    float2 direction = dist > 0.0001 ? delta / dist : float2(0.0);
    
    half4 rSample = layer.sample(position + direction * dispersion);
    half4 gSample = layer.sample(position);
    half4 bSample = layer.sample(position - direction * dispersion);
    
    half4 color = half4(rSample.r, gSample.g, bSample.b, gSample.a);
    
    // Optical edge vignette
    float edgeFactor = smoothstep(radius * 0.65, radius, dist);
    half vignette = half(1.0 - edgeFactor * 0.25);
    color.rgb *= vignette;
    
    return color;
}
