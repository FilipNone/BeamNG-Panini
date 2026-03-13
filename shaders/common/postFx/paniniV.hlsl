//-----------------------------------------------------------------------------
// paniniP.hlsl — Panini Projection post-process pixel shader
//
// Math ported from Unity URP's PaniniProjection.hlsl (MIT License),
// originally by Lasse / Stockholm demo team.
// Adapted for Torque3D / BeamNG.drive by removing all Unity macros and
// wiring to BeamNG's backBuffer sampler convention.
//
// Uniforms:
//   d    — projection distance / strength (0 = off, 1 = full panini)
//   s    — vertical compression factor   (0 = none, 1 = full)
//   crop — 1 = crop to fill screen, 0 = show black corners
//
// Cross-platform SM 3.0 HLSL — no DX-specific intrinsics.
// Vulkan-safe: transpiles cleanly to SPIR-V via Torque3D's backend.
//-----------------------------------------------------------------------------

uniform sampler2D backBuffer  : register(s0);

// Uniforms set by paniniPostFx.cs
uniform float d;     // panini strength
uniform float s;     // vertical compression
uniform float crop;  // crop mode

//-----------------------------------------------------------------------------
// Panini_Generic
//
// Parameterized panini projection using line-circle intersection.
// view_pos : NDC-space position ([-aspect, aspect] x [-1, 1])
// d        : projection parameter (0 = rectilinear, 1 = full panini)
//
// Geometry (ASCII from Unity source):
//
//    S----------- E--X-------
//    |    `  ~.  /,´
//    |-- ---    Q
//    |        ,/    `
//  1 |      ,´/       `
//    |    ,´ /         ´
//    |  ,´  /           ´
//    |,`   /             ,
//    O    /
//    |   /               ,
//  d |  /
//    | /                ,
//    |/                .
//    P
//    |              ´
//    |         , ´
//    +-    ´
//-----------------------------------------------------------------------------
float2 Panini_Generic(float2 view_pos, float d_param)
{
    float view_dist    = 1.0 + d_param;
    float view_hyp_sq  = view_pos.x * view_pos.x + view_dist * view_dist;

    float isect_D      = view_pos.x * d_param;
    float isect_discrim = view_hyp_sq - isect_D * isect_D;

    float cyl_dist_minus_d = (-isect_D * view_pos.x + view_dist * sqrt(isect_discrim)) / view_hyp_sq;
    float cyl_dist         = cyl_dist_minus_d + d_param;

    float2 cyl_pos = view_pos * (cyl_dist / view_dist);
    return cyl_pos / (cyl_dist - d_param);
}

//-----------------------------------------------------------------------------
// Panini_UnitDistance
//
// Fixed-d optimised version (d=1) using tangent-secant theorem.
// Cheaper than the generic version; use when d is always 1.
//-----------------------------------------------------------------------------
float2 Panini_UnitDistance(float2 view_pos)
{
    const float view_dist    = 2.0;
    const float view_dist_sq = 4.0;

    float view_hyp = sqrt(view_pos.x * view_pos.x + view_dist_sq);

    float cyl_hyp      = view_hyp - (view_pos.x * view_pos.x) / view_hyp;
    float cyl_hyp_frac = cyl_hyp / view_hyp;
    float cyl_dist     = view_dist * cyl_hyp_frac;

    float2 cyl_pos = view_pos * cyl_hyp_frac;
    return cyl_pos / (cyl_dist - 1.0);
}

//-----------------------------------------------------------------------------
// Main pixel shader
//-----------------------------------------------------------------------------
float4 main(float2 uv : TEXCOORD0) : COLOR0
{
    // Early-out when effect is disabled (d == 0) — avoids any warp at all
    if (d <= 0.0001)
        return tex2D(backBuffer, uv);

    // UV -> NDC: map [0,1] to [-1,+1]
    float2 ndc = uv * 2.0 - 1.0;

    // Apply panini warp in NDC space
    float2 proj = Panini_Generic(ndc, d);

    // Apply vertical compression (s):
    //   s=0 -> vertical lines stay straight (classic panini)
    //   s=1 -> compress verticals to match horizontal squeeze
    proj.y = lerp(ndc.y, proj.y, s);

    // Crop: scale projected coords so the image fills the screen edge-to-edge.
    // Without this, high d values produce black corners.
    // crop=1 fills the frame; crop=0 shows the full (distorted) field.
    float scale = lerp(1.0, 1.0 / (1.0 + d * 0.5), crop);
    proj *= scale;

    // NDC -> UV: map [-1,+1] back to [0,1]
    float2 final_uv = proj * 0.5 + 0.5;

    // Clamp to avoid wrapping artifacts at extreme d values
    final_uv = clamp(final_uv, 0.0, 1.0);

    return tex2D(backBuffer, final_uv);
}