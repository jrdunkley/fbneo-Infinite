// Derived from crt/shaders/guest/advanced/gaussian_vertical.slang; see SOURCES and original shader notices.
row_major float4x4 global_MVP;
float4 params_SourceSize;
float4 params_OriginalSize;
float4 params_OutputSize;
uint params_FrameCount;
static const float params_SIZEV = 6.0;
static const float params_SIGMA_V = 1.20;
static const float params_FINE_GLOW = 1.0;
texture Image2; sampler2D LIBRA_SAMPLER2D_2 : register(s0) = sampler_state { Texture = <Image2>; };
float4 vs_sample_lod0(sampler2D s, float2 uv) { return tex2Dlod(s, float4(uv,0,0)); }




uniform float4 vs_gl_HalfPixel;

static float4 vs_gl_Position;
static float4 vs_Position;
static float2 vs_vTexCoord;
static float2 vs_TexCoord;

struct vs_SPIRV_Cross_Input
{
    float4 vs_Position : TEXCOORD0;
    float2 vs_TexCoord : TEXCOORD1;
};

struct vs_SPIRV_Cross_Output
{
    float4 vs_gl_Position : POSITION;
float4 packed0 : TEXCOORD0;
};

static float vs_FINE_GLOW;

void vs_vert_main()
{
    float _23;
    if (params_FINE_GLOW > 0.5f)
    {
        _23 = params_FINE_GLOW;
    }
    else
    {
        _23 = lerp(0.75f, 0.5f, -params_FINE_GLOW);
    }
    vs_FINE_GLOW = _23;
    vs_gl_Position = mul(vs_Position, global_MVP);
    vs_vTexCoord = vs_TexCoord;
    vs_gl_Position.x = vs_gl_Position.x - vs_gl_HalfPixel.x * vs_gl_Position.w;
    vs_gl_Position.y = vs_gl_Position.y + vs_gl_HalfPixel.y * vs_gl_Position.w;
}

vs_SPIRV_Cross_Output vs_main(vs_SPIRV_Cross_Input stage_input)
{
    vs_Position = stage_input.vs_Position;
    vs_TexCoord = stage_input.vs_TexCoord;
    vs_vert_main();
    vs_SPIRV_Cross_Output stage_output = (vs_SPIRV_Cross_Output)0;
    stage_output.vs_gl_Position = vs_gl_Position;
    stage_output.packed0.xy = vs_vTexCoord;
    return stage_output;
}

float4 ps_sample_lod0(sampler2D s, float2 uv) { return tex2Dlod(s, float4(uv,0,0)); }






static float2 ps_vTexCoord;
static float4 ps_FragColor;

struct ps_SPIRV_Cross_Input
{
float4 packed0 : TEXCOORD0;
};

struct ps_SPIRV_Cross_Output
{
    float4 ps_FragColor : COLOR0;
};

static float ps_FINE_GLOW;
static float ps_invsqrsigma;

float ps_gaussian(float x)
{
    return exp(((-x) * x) * ps_invsqrsigma);
}

void ps_frag_main()
{
    float _27;
    if (params_FINE_GLOW > 0.5f)
    {
        _27 = params_FINE_GLOW;
    }
    else
    {
        _27 = lerp(0.75f, 0.5f, -params_FINE_GLOW);
    }
    ps_FINE_GLOW = _27;
    ps_invsqrsigma = 1.0f / ((2.0f * params_SIGMA_V) * params_SIGMA_V);
    float4 SourceSize1 = float4(params_SourceSize.x, params_OriginalSize.y, params_SourceSize.z, params_OriginalSize.w) * float4(ps_FINE_GLOW, ps_FINE_GLOW, 1.0f / ps_FINE_GLOW, 1.0f / ps_FINE_GLOW);
    float f = frac(SourceSize1.y * ps_vTexCoord.y);
    f = 0.5f - f;
    float2 tex = (floor(SourceSize1.xy * ps_vTexCoord) * SourceSize1.zw) + (SourceSize1.zw * 0.5f);
    float3 color = 0.0f.xxx;
    float2 dy = float2(0.0f, SourceSize1.w);
    float wsum = 0.0f;
    float _124 = -params_SIZEV;
    float n = _124;
    do
    {
        float3 pixel = ps_sample_lod0(LIBRA_SAMPLER2D_2, tex + (dy * n)).xyz;
        float param = n + f;
        float w = ps_gaussian(param);
        color += (pixel * w);
        wsum += w;
        n += 1.0f;
    } while (n <= params_SIZEV);
    color /= wsum.xxx;
    ps_FragColor = float4(color, 1.0f);
}

ps_SPIRV_Cross_Output ps_main(ps_SPIRV_Cross_Input stage_input)
{
    ps_vTexCoord = stage_input.packed0.xy;
    ps_frag_main();
    ps_SPIRV_Cross_Output stage_output;
    stage_output.ps_FragColor = float4(ps_FragColor);
    return stage_output;
}

technique t { pass p { VertexShader = compile vs_3_0 vs_main(); PixelShader = compile ps_3_0 ps_main(); } }
