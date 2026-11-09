// Native Arcade RGB presentation. The 18-pass chain is hosted by VidEffect.
#include "defaults.inc"
sampler2D tex0 : register(s0);
texture clean_image;
sampler2D clean_tex : register(s1) = sampler_state { Texture = <clean_image>; };
float2 texture_size, video_size;
float chain_active;
float effect_strength = 0.4;
float4 main_fragment(default_v2f input) : COLOR {
    float2 uv=input.texcoord;
    if(chain_active>0.5) uv*=texture_size/video_size;
    if(chain_active>0.5) {
        if(effect_strength>=1.0) return tex2D(tex0,uv);
        if(effect_strength<=0.0) return tex2D(clean_tex,input.texcoord);
        return lerp(tex2D(clean_tex,input.texcoord),tex2D(tex0,uv),effect_strength);
    }
    return tex2D(tex0,uv);
}
technique t { pass p0 {
    VertexShader = compile vs_3_0 default_vertex();
    PixelShader = compile ps_3_0 main_fragment();
    MinFilter[0]=POINT; MagFilter[0]=POINT; MipFilter[0]=NONE;
    AddressU[0]=CLAMP; AddressV[0]=CLAMP;
    MinFilter[1]=POINT; MagFilter[1]=POINT; MipFilter[1]=NONE;
    AddressU[1]=CLAMP; AddressV[1]=CLAMP;
} }
