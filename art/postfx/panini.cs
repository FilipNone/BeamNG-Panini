// art/postfx/panini.cs
// Registers the Panini Projection post-effect with the Torque3D engine.
// This file is auto-executed by the engine when the mod loads.

singleton GFXStateBlockData( PaniniStateBlock )
{
    zDefined         = true;
    zEnable          = false;
    zWriteEnable     = false;

    samplersDefined  = true;
    samplerStates[0] = SamplerClampLinear;  // backBuffer sampler
};

singleton ShaderData( PaniniShader )
{
    DXVertexShaderFile = "shaders/common/postFx/paniniV.hlsl";
    DXPixelShaderFile  = "shaders/common/postFx/paniniP.hlsl";
    pixVersion         = 3.0;
};

singleton PostEffect( PaniniPostFx )
{
    // Start disabled; main.lua enables it when ready
    isEnabled       = false;

    // Sample the back-buffer as input
    texture[0]      = "$backBuffer";

    // Write to the back-buffer (no intermediate target needed)
    // target is empty by default = writes to back-buffer

    shader          = PaniniShader;
    stateBlock      = PaniniStateBlock;
    renderTime      = PFXAfterBin;
    renderPriority  = 0.5;
};

// Called by the engine when the PostEffect fires.
// This is where we push uniform values into the shader.
function PaniniPostFx::setShaderConsts( %this )
{
    // These are overridden from Lua via setShaderConst(); 
    // providing defaults here so the effect is safe on first frame.
    %this.setShaderConst( "$d",    "0.5" );   // panini strength
    %this.setShaderConst( "$s",    "0.0" );   // vertical compression
    %this.setShaderConst( "$crop", "1.0" );   // crop mode
}