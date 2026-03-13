// paniniP.hlsl — Panini Projection post-process pixel shader
//
// Math ported from Unity URP PaniniProjection.hlsl (MIT License).
// Adapted for Torque3D / BeamNG.drive.
//
// Uniforms (set via PaniniPostFx::setShaderConsts / Lua setShaderConst):
//   $d    — projection distance / strength  (0 = off, 1 = full panini)
//   $s    — vertical compression factor     (0 = none, 1 = full)
//   $crop — 1 = crop to fill, 0 = show corners
//
// NOTE: backBuffer is wired in by the PostEffect declaration, not as
// a sampler2D uniform. Torque3D passes it via texture[0] → register s0.

sampler2D backBuffer : register(s0);

uniform float d;
uniform float s;
uniform float crop;

// ---------------------------------------------------------------------------
// Panini_Generic — line-circle intersection, parameterised by d.
// ---------------------------------------------------------------------------
float2 Panini_Generic(float2 view_pos, float d_param)
{
    float view_dist   = 1.0 + d_param;
    float view_hyp_sq = view_pos.x * view_pos.x + view_dist * view_dist;

    float isect_D       = view_pos.x * d_param;
    float isect_discrim = view_hyp_sq - isect_D * isect_D;

    float cyl_dist_minus_d = (-isect_D * view_pos.x
                              + view_dist * sqrt(isect_discrim)) / view_hyp_sq;
    float cyl_dist = cyl_dist_minus_d + d_param;

    float2 cyl_pos = view_pos * (cyl_dist / view_dist);
    return cyl_pos / (cyl_dist - d_param);
}

// ---------------------------------------------------------------------------
// Main pixel shader
// ---------------------------------------------------------------------------
float4 main(float2 uv : TEXCOORD0) : COLOR0
{
    // Early-out: d == 0 means no warp at all
    if (d <= 0.0001)
        return tex2D(backBuffer, uv);

    // UV [0,1] → NDC [-1,+1]
    float2 ndc = uv * 2.0 - 1.0;

    // Apply panini warp
    float2 proj = Panini_Generic(ndc, d);

    // Vertical compression:
    //   s=0 → straight verticals (classic panini)
    //   s=1 → compress verticals to match horizontal squeeze
    proj.y = lerp(ndc.y, proj.y, s);

    // Crop scale — prevents black corners at high d values
    float scale = lerp(1.0, 1.0 / (1.0 + d * 0.5), crop);
    proj *= scale;

    // NDC [-1,+1] → UV [0,1]
    float2 final_uv = proj * 0.5 + 0.5;

    // Clamp to avoid wrap-around at extreme d values
    final_uv = clamp(final_uv, 0.0, 1.0);

    return tex2D(backBuffer, final_uv);
}