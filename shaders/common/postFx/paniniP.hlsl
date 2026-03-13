//-----------------------------------------------------------------------------
// paniniV.hlsl — standard full-screen-quad vertex shader
// No Unity macros, no DX-specific intrinsics.
// Cross-platform HLSL (SM 3.0) — transpiles cleanly to SPIR-V under Vulkan.
//-----------------------------------------------------------------------------

struct VertIn
{
    float4 pos      : POSITION;
    float2 texCoord : TEXCOORD0;
};

struct VertOut
{
    float4 hpos     : POSITION;
    float2 uv       : TEXCOORD0;
};

VertOut main(VertIn IN)
{
    VertOut OUT;
    OUT.hpos = IN.pos;
    OUT.uv   = IN.texCoord;
    return OUT;
}