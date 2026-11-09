// Lola Retro by Zoki, MIT; see lola_retro/SOURCES.txt and preset LICENSE.
#include "defaults.inc"
sampler2D tex0 : register(s0);
float2 texture_size, video_size;
float chain_active;
float4 main_fragment(default_v2f input) : COLOR {
    float2 uv=input.texcoord;
    if(chain_active>0.5) uv*=texture_size/video_size;
    return tex2D(tex0,uv);
}
technique t { pass p0 {
    VertexShader = compile vs_3_0 default_vertex();
    PixelShader = compile ps_3_0 main_fragment();
    MinFilter[0]=POINT; MagFilter[0]=POINT; MipFilter[0]=NONE;
    AddressU[0]=CLAMP; AddressV[0]=CLAMP;
} }
