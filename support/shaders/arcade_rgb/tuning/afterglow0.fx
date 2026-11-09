// Tunable adaptation; fixed original and notices are in the parent folder.
// Derived from crt/shaders/guest/advanced/afterglow0.slang; see SOURCES and original shader notices.
row_major float4x4 global_MVP;
float4 params_SourceSize;
float4 params_OriginalSize;
float4 params_OutputSize;
uint params_FrameCount;
static const float params_PR = 0.32;
static const float params_PG = 0.32;
static const float params_PB = 0.32;
static const float params_esrc = 1.0;
static const float params_bth = 4.0;
texture Image3; sampler2D LIBRA_SAMPLER2D_3 : register(s1) = sampler_state { Texture = <Image3>; };
texture Image2; sampler2D LIBRA_SAMPLER2D_2 : register(s0) = sampler_state { Texture = <Image2>; };
texture Image4; sampler2D LIBRA_SAMPLER2D_4 : register(s2) = sampler_state { Texture = <Image4>; };
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

void ps_frag_main()
{
    float2 dx = float2(params_OriginalSize.z, 0.0f);
    float2 dy = float2(0.0f, params_OriginalSize.w);
    float3 color0 = ps_sample_lod0(LIBRA_SAMPLER2D_3, ps_vTexCoord).xyz;
    float3 color1 = ps_sample_lod0(LIBRA_SAMPLER2D_3, ps_vTexCoord - dx).xyz;
    float3 color2 = ps_sample_lod0(LIBRA_SAMPLER2D_3, ps_vTexCoord + dx).xyz;
    float3 color3 = ps_sample_lod0(LIBRA_SAMPLER2D_3, ps_vTexCoord - dy).xyz;
    float3 color4 = ps_sample_lod0(LIBRA_SAMPLER2D_3, ps_vTexCoord + dy).xyz;
    if (params_esrc > 1.5f)
    {
        color0 = ps_sample_lod0(LIBRA_SAMPLER2D_2, ps_vTexCoord).xyz;
        color1 = ps_sample_lod0(LIBRA_SAMPLER2D_2, ps_vTexCoord - dx).xyz;
        color2 = ps_sample_lod0(LIBRA_SAMPLER2D_2, ps_vTexCoord + dx).xyz;
        color3 = ps_sample_lod0(LIBRA_SAMPLER2D_2, ps_vTexCoord - dy).xyz;
        color4 = ps_sample_lod0(LIBRA_SAMPLER2D_2, ps_vTexCoord + dy).xyz;
    }
    float3 color = (((((color0 * 2.5f) + color1) + color2) + color3) + color4) / 6.5f.xxx;
    float3 accumulate = ps_sample_lod0(LIBRA_SAMPLER2D_4, ps_vTexCoord).xyz;
    float w = 1.0f;
    float b = params_bth / 255.0f;
    float c = max(max(color0.x, color0.y), color0.z);
    w = smoothstep(b, 2.0f * b, c);
    float3 result = lerp(max(lerp(color, accumulate, 0.4900000095367431640625f.xxx + float3(params_PR, params_PG, params_PB)) - 0.0049019609577953815460205078125f.xxx, 0.0f.xxx), color, w.xxx);
    ps_FragColor = float4(result, w);
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
