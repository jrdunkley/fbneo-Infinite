// Tunable adaptation; fixed original and notices are in the parent folder.
// Derived from crt/shaders/guest/hd/bloom_horizontal.slang; see SOURCES and original shader notices.
row_major float4x4 global_MVP;
float4 params_LinearizePassSize;
float4 params_OriginalSize;
float4 params_OutputSize;
uint params_FrameCount;
static const float params_SIZEHB = 3.0;
static const float params_SIGMA_HB = 0.75;
static const float params_FINE_BLOOM = 1.0;
static const float params_auto_res = 0.0;
float params_GLOW_MAX;
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

static float vs_auto_rez;
static float vs_FINE_BLOOM;

void vs_vert_main()
{
    float _24;
    if (params_OriginalSize.y < 375.0f)
    {
        _24 = lerp(1.0f, 2.0f, clamp((params_auto_res * round(params_OriginalSize.x / 300.0f)) - 1.0f, 0.0f, 1.0f));
    }
    else
    {
        _24 = 1.0f;
    }
    vs_auto_rez = _24;
    float _51;
    if (params_FINE_BLOOM > 0.5f)
    {
        _51 = params_FINE_BLOOM;
    }
    else
    {
        _51 = lerp(0.75f, 0.5f, -params_FINE_BLOOM);
    }
    vs_FINE_BLOOM = _51;
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

static float ps_auto_rez;
static float ps_FINE_BLOOM;
static float ps_invsqrsigma;

float ps_gaussian(float x)
{
    return exp(((-x) * x) * ps_invsqrsigma);
}

void ps_frag_main()
{
    float _28;
    if (params_OriginalSize.y < 375.0f)
    {
        _28 = lerp(1.0f, 2.0f, clamp((params_auto_res * round(params_OriginalSize.x / 300.0f)) - 1.0f, 0.0f, 1.0f));
    }
    else
    {
        _28 = 1.0f;
    }
    ps_auto_rez = _28;
    float _55;
    if (params_FINE_BLOOM > 0.5f)
    {
        _55 = params_FINE_BLOOM;
    }
    else
    {
        _55 = lerp(0.75f, 0.5f, -params_FINE_BLOOM);
    }
    ps_FINE_BLOOM = _55;
    ps_invsqrsigma = 1.0f / ((((2.0f * params_SIGMA_HB) * params_SIGMA_HB) * ps_auto_rez) * ps_auto_rez);
    float4 SourceSize1 = params_OriginalSize * float4(ps_FINE_BLOOM, ps_FINE_BLOOM, 1.0f / ps_FINE_BLOOM, 1.0f / ps_FINE_BLOOM);
    float f = frac(SourceSize1.x * ps_vTexCoord.x);
    f = 0.5f - f;
    float2 tex = (floor(SourceSize1.xy * ps_vTexCoord) * SourceSize1.zw) + (SourceSize1.zw * 0.5f);
    float4 color = 0.0f.xxxx;
    float2 dx = float2(SourceSize1.z, 0.0f);
    float wsum = 0.0f;
    float _142 = (-params_SIZEHB) * ps_auto_rez;
    float n = _142;
    do
    {
        float4 pixel = ps_sample_lod0(LIBRA_SAMPLER2D_2, tex + (dx * n));
        float param = n + f;
        float w = ps_gaussian(param);
        pixel.w = max(max(pixel.x, pixel.y), pixel.z);
        pixel.w *= (pixel.w * pixel.w);
        color += (pixel * w);
        wsum += w;
        n += 1.0f;
    } while (n <= (params_SIZEHB * ps_auto_rez));
    color /= wsum.xxxx;
    ps_FragColor = float4(color.xyz, pow(color.w, 0.3333329856395721435546875f));
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
