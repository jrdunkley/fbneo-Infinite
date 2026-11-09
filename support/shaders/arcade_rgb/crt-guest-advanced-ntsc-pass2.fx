// Derived from crt/shaders/guest/advanced/crt-guest-advanced-ntsc-pass2.slang; see SOURCES and original shader notices.
row_major float4x4 global_MVP;
float4 global_SourceSize;
float4 global_OriginalSize;
float4 global_OutputSize;
uint global_FrameCount;
static const float global_bloom = 0.0;
static const float global_halation = 0.0;
static const float global_scans = 0.50;
static const float global_gamma_c = 1.0;
static const float global_gamma_c2 = 1.0;
static const float global_gamma_out = 1.95;
static const float global_overscanX = 0.0;
static const float global_overscanY = 0.0;
static const float global_VShift = 0.0;
static const float global_intres = 0.0;
float global_prescalex;
static const float global_c_shape = 0.25;
static const float global_scangamma = 5.000000;
static const float global_sborder = 0.75;
static const float global_scan_falloff = 2.000000;
static const float global_bloom_dist = 0.0;
static const float global_bmask1 = 0.0;
static const float global_hmask1 = 0.35;
static const float global_interm = 2.0;
static const float params_IOS = 0.0;
static const float params_OS = 1.0;
static const float params_BLOOM = 0.0;
static const float params_brightboost = 1.40;
static const float params_brightboost1 = 1.10;
static const float params_gsl = 2.000000;
static const float params_scanline1 = 6.0;
static const float params_scanline2 = 8.0;
static const float params_beam_min = 0.750000;
static const float params_beam_max = 1.274998;
static const float params_beam_size = 0.60;
float params_h_sharp;
float params_s_sharp;
static const float params_warpX = 0.0;
static const float params_warpY = 0.0;
static const float params_glow = 0.08;
#ifndef RC_shadowMask
#define RC_shadowMask 4.000000
#endif
static const float params_shadowMask = RC_shadowMask;
#ifndef RC_masksize
#define RC_masksize 1.0
#endif
static const float params_masksize = RC_masksize;
float params_ring;
static const float params_no_scanlines = 0.0;
static const float params_tds = 1.000000;
static const float params_clips = 0.0;
static const float params_hiscan = 0.0;
static const float params_rolling_scan = 0.0;
texture Image2; sampler2D LIBRA_SAMPLER2D_2 : register(s0) = sampler_state { Texture = <Image2>; };
texture Image3; sampler2D LIBRA_SAMPLER2D_3 : register(s1) = sampler_state { Texture = <Image3>; };
texture Image4; sampler2D LIBRA_SAMPLER2D_4 : register(s2) = sampler_state { Texture = <Image4>; };
float4 LIBRA_SAMPLER2D_2_size;
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

float ps_mod(float x, float y)
{
    return x - y * floor(x / y);
}

float2 ps_mod(float2 x, float2 y)
{
    return x - y * floor(x / y);
}

float3 ps_mod(float3 x, float3 y)
{
    return x - y * floor(x / y);
}

float4 ps_mod(float4 x, float4 y)
{
    return x - y * floor(x / y);
}



float2 ps_Overscan(inout float2 pos, float dx, float dy)
{
    pos = (pos * 2.0f) - 1.0f.xx;
    pos *= float2(dx, dy);
    return (pos * 0.5f) + 0.5f.xx;
}

float2 ps_Warp(inout float2 pos)
{
    pos = (pos * 2.0f) - 1.0f.xx;
    pos = lerp(pos, float2(pos.x * rsqrt(1.0f - ((global_c_shape * pos.y) * pos.y)), pos.y * rsqrt(1.0f - ((global_c_shape * pos.x) * pos.x))), float2(params_warpX, params_warpY) / global_c_shape.xx);
    return (pos * 0.5f) + 0.5f.xx;
}

float ps_st(float x)
{
    return exp2(((-10.0f) * x) * x);
}

float3 ps_sw0(float x, float color, float scanline, float3 c)
{
    float tmp = lerp(params_beam_min, params_beam_max, color);
    float3 sat = lerp(1.0f.xxx + (1.5f * global_scans).xxx, 1.0f.xxx, c);
    float ex = x * tmp;
    float _105;
    if (params_gsl > (-0.5f))
    {
        _105 = ex * ex;
    }
    else
    {
        _105 = lerp(ex * ex, (ex * ex) * ex, 0.4000000059604644775390625f);
    }
    ex = _105;
    return exp2(sat * ((-scanline) * ex));
}

float3 ps_sw1(inout float x, float color, float scanline, float3 c)
{
    x = lerp(x, params_beam_min * x, max(x - (0.4000000059604644775390625f * color), 0.0f));
    float3 sat = lerp(1.0f.xxx + (1.5f * global_scans).xxx, 1.0f.xxx, c);
    float tmp = lerp(1.2000000476837158203125f * params_beam_min, params_beam_max, color);
    float ex = x * tmp;
    return exp2(sat * (((-scanline) * ex) * ex));
}

float3 ps_sw2(float x, float color, float scanline, float3 c)
{
    float tmp = lerp((2.5f - (0.5f * color)) * params_beam_min, params_beam_max, color);
    float3 sat = lerp(1.0f.xxx + (1.5f * global_scans).xxx, 1.0f.xxx, c);
    tmp = lerp(params_beam_max, tmp, pow(x, color + 0.300000011920928955078125f));
    float ex = x * tmp;
    return exp2(sat * (((-scanline) * ex) * ex));
}

float3 ps_plant(float3 tar, float r)
{
    float t = max(max(tar.x, tar.y), tar.z) + 9.9999997473787516355514526367188e-06f;
    return (tar * r) / t.xxx;
}

float3 ps_gc(float3 c)
{
    float mc = max(max(c.x, c.y), c.z);
    float mg = pow(mc, 1.0f / global_gamma_c);
    return (c * mg) / (mc + 9.9999999392252902907785028219223e-09f).xxx;
}

void ps_frag_main()
{
    uint _344_dummy_parameter;
    float prescalex = float(int2(float2(LIBRA_SAMPLER2D_2_size.xy)).x) / (2.0f * global_OriginalSize.x);
    float4 SourceSize = global_OriginalSize * float4(prescalex, 1.0f, 1.0f / prescalex, 1.0f);
    SourceSize *= float4(2.0f, 1.0f, 0.5f, 1.0f);
    float lum = ps_sample_lod0(LIBRA_SAMPLER2D_3, 0.5f.xx).w;
    float gamma_in = 1.0f / ps_sample_lod0(LIBRA_SAMPLER2D_2, 0.25f.xx).w;
    float intera = ps_sample_lod0(LIBRA_SAMPLER2D_2, float2(0.75f, 0.25f)).w;
    bool hscan = params_hiscan > 0.5f;
    bool _394 = intera < 0.3499999940395355224609375f;
    bool _402;
    if (_394)
    {
        _402 = global_interm == 6.0f;
    }
    else
    {
        _402 = _394;
    }
    bool inter6 = _402;
    bool _408 = (intera < 0.3499999940395355224609375f) && (!inter6);
    bool _417;
    if (!_408)
    {
        _417 = params_no_scanlines > 0.02500000037252902984619140625f;
    }
    else
    {
        _417 = _408;
    }
    bool interb = _417 && (!hscan);
    float SourceY = SourceSize.y;
    float sy = 1.0f;
    if (global_intres == 1.0f)
    {
        sy = max(round(SourceY / 224.0f), 1.0f);
    }
    bool _437 = global_intres > 0.25f;
    bool _443;
    if (_437)
    {
        _443 = global_intres != 1.0f;
    }
    else
    {
        _443 = _437;
    }
    if (_443)
    {
        sy = global_intres;
    }
    if (inter6)
    {
        sy *= 2.0f;
    }
    SourceSize *= float4(1.0f, 1.0f / sy, 1.0f, sy);
    float2 texcoord = ps_vTexCoord;
    if ((params_IOS > 0.0f) && (!interb))
    {
        float2 ofactor = global_OutputSize.xy / global_OriginalSize.xy;
        float2 _484;
        if (params_IOS < 2.5f)
        {
            _484 = floor(ofactor);
        }
        else
        {
            _484 = ceil(ofactor);
        }
        float2 intfactor = _484;
        float2 diff = ofactor / intfactor;
        float scan = diff.y;
        float2 param = texcoord;
        float param_1 = scan;
        float param_2 = scan;
        float2 _506 = ps_Overscan(param, param_1, param_2);
        texcoord = _506;
        bool _509 = params_IOS == 1.0f;
        bool _517;
        if (!_509)
        {
            _517 = params_IOS == 3.0f;
        }
        else
        {
            _517 = _509;
        }
        if (_517)
        {
            texcoord = float2(ps_vTexCoord.x, texcoord.y);
        }
    }
    float factor = (1.0f + (((1.0f - (0.5f * params_OS)) * params_BLOOM) / 100.0f)) - ((lum * params_BLOOM) / 100.0f);
    float2 param_3 = texcoord;
    float param_4 = factor;
    float param_5 = factor;
    float2 _550 = ps_Overscan(param_3, param_4, param_5);
    texcoord = _550;
    texcoord.y -= (global_VShift * global_OriginalSize.w);
    float2 param_6 = texcoord;
    float param_7 = (global_OriginalSize.x - global_overscanX) / global_OriginalSize.x;
    float param_8 = (global_OriginalSize.y - global_overscanY) / global_OriginalSize.y;
    float2 _582 = ps_Overscan(param_6, param_7, param_8);
    texcoord = _582;
    float2 param_9 = texcoord;
    float2 _586 = ps_Warp(param_9);
    float2 pos = _586;
    float2 param_10 = ps_vTexCoord;
    float2 _590 = ps_Warp(param_10);
    float2 pos0 = _590;
    float ii = float(inter6) * floor(ps_mod(float(global_FrameCount), 2.0f));
    float2 coffset = float2(0.5f, 0.5f + (0.5f * ii));
    float2 ps = SourceSize.zw;
    float2 OGL2Pos = (pos * SourceSize.xy) - coffset;
    float2 fp = frac(OGL2Pos);
    float2 dx = float2(ps.x, 0.0f);
    float2 dy = float2(0.0f, ps.y);
    float f = fp.y;
    float2 pC4 = (floor(OGL2Pos) * ps) + (ps * 0.5f);
    pC4.y += ((float(inter6) * 0.25f) * dy.y);
    pC4.x = pos.x;
    if ((global_intres == 0.5f) && (prescalex < 1.5f))
    {
        pC4.y = (floor(pC4.y * global_OriginalSize.y) * global_OriginalSize.w) + (0.5f * global_OriginalSize.w);
    }
    bool _680;
    if (interb)
    {
        _680 = params_no_scanlines < 0.02500000037252902984619140625f;
    }
    else
    {
        _680 = interb;
    }
    if (_680 || hscan)
    {
        pC4.y = pos.y;
    }
    else
    {
        if (interb)
        {
            pC4.y += (smoothstep(0.4000000059604644775390625f - (0.5f * params_no_scanlines), 0.60000002384185791015625f + (0.5f * params_no_scanlines), f) * SourceSize.w);
        }
    }
    float3 color1 = ps_sample_lod0(LIBRA_SAMPLER2D_4, pC4).xyz;
    float3 scolor1 = ps_sample_lod0(LIBRA_SAMPLER2D_4, pC4).www;
    if (!interb)
    {
        color1 = pow(color1, (global_scangamma / gamma_in).xxx);
    }
    pC4 += dy;
    if ((global_intres == 0.5f) && (prescalex < 1.5f))
    {
        pC4.y = (floor((pos.y + (0.3300000131130218505859375f * dy.y)) * global_OriginalSize.y) * global_OriginalSize.w) + (0.5f * global_OriginalSize.w);
    }
    float3 color2 = ps_sample_lod0(LIBRA_SAMPLER2D_4, pC4).xyz;
    float3 scolor2 = ps_sample_lod0(LIBRA_SAMPLER2D_4, pC4).www;
    if (!interb)
    {
        color2 = pow(color2, (global_scangamma / gamma_in).xxx);
    }
    float3 ctmp = color1;
    float w3 = 1.0f;
    float3 color = color1;
    float3 one = 1.0f.xxx;
    if (hscan)
    {
        color2 = color1;
        scolor2 = scolor1;
    }
    if ((!interb) || hscan)
    {
        float shape1 = lerp(params_scanline1, params_scanline2, f);
        float shape2 = lerp(params_scanline1, params_scanline2, 1.0f - f);
        float param_11 = f;
        float wt1 = ps_st(param_11);
        float param_12 = 1.0f - f;
        float wt2 = ps_st(param_12);
        float3 color00 = (color1 * wt1) + (color2 * wt2);
        float3 scolor0 = (scolor1 * wt1) + (scolor2 * wt2);
        ctmp = color00 / (wt1 + wt2).xxx;
        float3 sctmp = scolor0 / (wt1 + wt2).xxx;
        if (abs(params_rolling_scan) > 0.004999999888241291046142578125f)
        {
            color1 = ctmp;
            color2 = ctmp;
            scolor1 = sctmp;
            scolor2 = sctmp;
        }
        float3 cref1 = lerp(sctmp, scolor1, params_beam_size.xxx);
        float creff1 = pow(max(max(cref1.x, cref1.y), cref1.z), global_scan_falloff);
        float3 cref2 = lerp(sctmp, scolor2, params_beam_size.xxx);
        float creff2 = pow(max(max(cref2.x, cref2.y), cref2.z), global_scan_falloff);
        if (params_tds > 0.5f)
        {
            shape1 = lerp(params_scanline2, shape1, creff1);
            shape2 = lerp(params_scanline2, shape2, creff2);
        }
        float scanpix = global_OriginalSize.y / global_OutputSize.y;
        float f1 = frac(f - ((params_rolling_scan * float(global_FrameCount)) * scanpix));
        float f2 = 1.0f - f1;
        float mc1 = max(max(color1.x, color1.y), color1.z) + 9.9999999392252902907785028219223e-09f;
        float mc2 = max(max(color2.x, color2.y), color2.z) + 9.9999999392252902907785028219223e-09f;
        cref1 = color1 / mc1.xxx;
        cref2 = color2 / mc2.xxx;
        float3 w1;
        float3 w2;
        if (params_gsl < 0.5f)
        {
            float param_13 = f1;
            float param_14 = creff1;
            float param_15 = shape1;
            float3 param_16 = cref1;
            w1 = ps_sw0(param_13, param_14, param_15, param_16);
            float param_17 = f2;
            float param_18 = creff2;
            float param_19 = shape2;
            float3 param_20 = cref2;
            w2 = ps_sw0(param_17, param_18, param_19, param_20);
        }
        else
        {
            if (params_gsl == 1.0f)
            {
                float param_21 = f1;
                float param_22 = creff1;
                float param_23 = shape1;
                float3 param_24 = cref1;
                float3 _1009 = ps_sw1(param_21, param_22, param_23, param_24);
                w1 = _1009;
                float param_25 = f2;
                float param_26 = creff2;
                float param_27 = shape2;
                float3 param_28 = cref2;
                float3 _1018 = ps_sw1(param_25, param_26, param_27, param_28);
                w2 = _1018;
            }
            else
            {
                float param_29 = f1;
                float param_30 = creff1;
                float param_31 = shape1;
                float3 param_32 = cref1;
                w1 = ps_sw2(param_29, param_30, param_31, param_32);
                float param_33 = f2;
                float param_34 = creff2;
                float param_35 = shape2;
                float3 param_36 = cref2;
                w2 = ps_sw2(param_33, param_34, param_35, param_36);
            }
        }
        float3 w3_1 = w1 + w2;
        float wf1 = max(max(w3_1.x, w3_1.y), w3_1.z);
        if (wf1 > 1.0f)
        {
            wf1 = 1.0f / wf1;
            w1 *= wf1;
            w2 *= wf1;
        }
        if (abs(params_clips) > 0.004999999888241291046142578125f)
        {
            sy = mc1;
            bool3 _1076 = (params_clips > 0.0f).xxx;
            one = float3(_1076.x ? w1.x : 1.0f.xxx.x, _1076.y ? w1.y : 1.0f.xxx.y, _1076.z ? w1.z : 1.0f.xxx.z);
            float sat = 1.00010001659393310546875f - min(min(cref1.x, cref1.y), cref1.z);
            float3 param_37 = pow(color1, 0.699999988079071044921875f.xxx - (0.324999988079071044921875f * sat).xxx);
            float param_38 = sy;
            color1 = lerp(color1, ps_plant(param_37, param_38), (one * pow(sat, 0.33329999446868896484375f)) * abs(params_clips));
            sy = mc2;
            bool3 _1118 = (params_clips > 0.0f).xxx;
            one = float3(_1118.x ? w2.x : 1.0f.xxx.x, _1118.y ? w2.y : 1.0f.xxx.y, _1118.z ? w2.z : 1.0f.xxx.z);
            sat = 1.00010001659393310546875f - min(min(cref2.x, cref2.y), cref2.z);
            float3 param_39 = pow(color2, 0.699999988079071044921875f.xxx - (0.324999988079071044921875f * sat).xxx);
            float param_40 = sy;
            color2 = lerp(color2, ps_plant(param_39, param_40), (one * pow(sat, 0.33329999446868896484375f)) * abs(params_clips));
        }
        float3 param_41 = color1;
        float3 param_42 = color2;
        color = (ps_gc(param_41) * w1) + (ps_gc(param_42) * w2);
        color = min(color, 1.0f.xxx);
    }
    if (interb)
    {
        float3 param_43 = color1;
        color = ps_gc(param_43);
    }
    float colmx = max(max(ctmp.x, ctmp.y), ctmp.z);
    if (!interb)
    {
        color = pow(color, (gamma_in / global_scangamma).xxx);
    }
    ps_FragColor = float4(color, colmx);
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
