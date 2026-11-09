// Tunable adaptation; fixed original and notices are in the parent folder.
// Derived from crt/shaders/guest/advanced/avg-lum-ntsc.slang; see SOURCES and original shader notices.
row_major float4x4 global_MVP;
uint params_FrameCount;
float4 params_SourceSize;
static const float params_lsmooth = 0.70;
static const float params_lsdev = 0.0;
texture Image2; sampler2D LIBRA_SAMPLER2D_2 : register(s0) = sampler_state { Texture = <Image2>; };
texture Image3; sampler2D LIBRA_SAMPLER2D_3 : register(s1) = sampler_state { Texture = <Image3>; };
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

void vs_vert_main()
{
    vs_gl_Position = mul(vs_Position, global_MVP);
    vs_vTexCoord = vs_TexCoord * 1.000010013580322265625f;
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

float ps_dist(float3 A, float3 B)
{
    float r = 0.5f * (A.x + B.x);
    float3 d = A - B;
    float3 c = float3(2.0f + r, 4.0f, 3.0f - r);
    return sqrt(dot(c * d, d)) / 3.0f;
}

void ps_frag_main()
{
    float m = max(log2(params_SourceSize.x), log2(params_SourceSize.y));
    m = floor(max(m, 1.0f)) - 1.0f;
    float2 dx = float2(1.0f / params_SourceSize.x, 0.0f);
    float2 dy = float2(0.0f, 1.0f / params_SourceSize.y);
    float2 y2 = dy * 2.0f;
    float2 x2 = dx * 2.0f;
    float ltotal = 0.0f;
    ltotal += length(tex2Dlod(LIBRA_SAMPLER2D_2, float4(0.300000011920928955078125f.xx, 0.0, m)).xyz);
    ltotal += length(tex2Dlod(LIBRA_SAMPLER2D_2, float4(float2(0.300000011920928955078125f, 0.699999988079071044921875f), 0.0, m)).xyz);
    ltotal += length(tex2Dlod(LIBRA_SAMPLER2D_2, float4(float2(0.699999988079071044921875f, 0.300000011920928955078125f), 0.0, m)).xyz);
    ltotal += length(tex2Dlod(LIBRA_SAMPLER2D_2, float4(0.699999988079071044921875f.xx, 0.0, m)).xyz);
    ltotal *= 0.25f;
    ltotal = pow(0.57735025882720947265625f * ltotal, 0.699999988079071044921875f);
    float lhistory = ps_sample_lod0(LIBRA_SAMPLER2D_3, 0.5f.xx).w;
    ltotal = lerp(ltotal, lhistory, min(lerp(params_lsmooth, params_lsmooth + params_lsdev, ltotal), 0.9900000095367431640625f));
    float3 l1 = ps_sample_lod0(LIBRA_SAMPLER2D_2, ps_vTexCoord).xyz;
    float3 r1 = ps_sample_lod0(LIBRA_SAMPLER2D_2, ps_vTexCoord + dx).xyz;
    float3 l2 = ps_sample_lod0(LIBRA_SAMPLER2D_2, ps_vTexCoord - dx).xyz;
    float3 r2 = ps_sample_lod0(LIBRA_SAMPLER2D_2, ps_vTexCoord + x2).xyz;
    float3 param = l2;
    float3 param_1 = l1;
    float c1 = ps_dist(param, param_1);
    float3 param_2 = l1;
    float3 param_3 = r1;
    float c2 = ps_dist(param_2, param_3);
    float3 param_4 = r2;
    float3 param_5 = r1;
    float c3 = ps_dist(param_4, param_5);
    ps_FragColor = float4(c1, c2, c3, ltotal);
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
