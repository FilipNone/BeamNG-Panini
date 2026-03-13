// paniniPostFx.cs
// Registers the shader and wires it into the PostFX chain.
//
// Tuning:
//   paniniEffect.d     — projection strength   (0.0 = off, 1.0 = full panini)
//   paniniEffect.s     — vertical compression  (0.0 = keep verticals, 1.0 = compress)
//   paniniEffect.crop  — 1.0 = crop to fill, 0.0 = letterbox (show black corners)
//
// Toggle at runtime from the console:
//   paniniEffect.isEnabled = true;   paniniEffect.postProcess(false);
//   paniniEffect.isEnabled = false;  paniniEffect.postProcess(false);

singleton ShaderData(PaniniShader)
{
    DXVertexShaderFile = "shaders/common/postFx/paniniV.hlsl";
    DXPixelShaderFile  = "shaders/common/postFx/paniniP.hlsl";
    pixVersion         = 3.0;
};

singleton GFXStateBlockData(PaniniStateBlock : PFX_DefaultStateBlock)
{
    zDefined        = true;
    zEnable         = false;
    zWriteEnable    = false;
    samplersDefined = true;
    samplerStates[0] = SamplerClampLinear;
};

singleton PostEffect(paniniEffect)
{
    isEnabled  = true;
    renderTime = "PFXAfterDiffuse";
    renderBin  = "PostFX";
    shader     = PaniniShader;
    stateBlock = PaniniStateBlock;
    texture[0] = "$backBuffer";

    // Uniforms forwarded to the pixel shader
    // d    : panini strength  — tweak to taste, 0.15–0.5 is a good range
    // s    : vertical compression — 0.0 keeps vertical lines perfectly straight
    // crop : 1.0 crops black corners,  0.0 shows them (letterbox)
    d    = "0.25";
    s    = "0.0";
    crop = "1.0";
};