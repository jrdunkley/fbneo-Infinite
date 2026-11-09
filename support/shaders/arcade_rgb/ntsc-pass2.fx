// Derived from crt/shaders/guest/advanced/ntsc/ntsc-pass2.slang; see SOURCES and original shader notices.
row_major float4x4 global_MVP;
float4 params_OutputSize;
float4 params_OriginalSize;
float4 params_SourceSize;
static const float params_ntsc_scale = 2.500000;
static const float params_ntsc_phase = 1.0;
static const float params_ntsc_ring = 0.5;
static const float params_ntsc_cscale = 4.000000;
static const float params_ntsc_cscale1 = 2.250000;
static const float params_ntsc_taps = 32.0;
static const float params_auto_res = 0.0;
static const float params_ntsc_charp = 10.000000;
static const float params_ntsc_charp3 = 10.000000;
static const float params_speedup = 1.0;
static const float params_nscale = 1.0;
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

static float vs_auto_rez;

void vs_vert_main()
{
    vs_auto_rez = lerp(1.0f, 0.5f, clamp((params_auto_res * round(params_OriginalSize.x / 300.0f)) - 1.0f, 0.0f, 1.0f));
    vs_gl_Position = mul(vs_Position, global_MVP);
    vs_vTexCoord = vs_TexCoord + float2(((0.5f / params_speedup) * (params_OriginalSize.z / vs_auto_rez)) / 4.0f, 0.0f);
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
static const float ps__171[33] = { 0.0f, 0.0f, 0.0f, 0.0f, 0.0f, 0.0f, 0.0f, 0.0f, -1.2020000212942250072956085205078e-05f, -2.2145999537315219640731811523438e-05f, -1.315499957854626700282096862793e-05f, -1.2020000212942250072956085205078e-05f, -4.9979000323219224810600280761719e-05f, -0.00011393999739084392786026000976562f, -0.0001221499987877905368804931640625f, -5.6120002227544318884611129760742e-06f, 0.00017051599570550024509429931640625f, 0.00023719899763818830251693725585938f, 0.0001696399995125830173492431640625f, 0.00028568800189532339572906494140625f, 0.00098457396961748600006103515625f, 0.00201868289150297641754150390625f, 0.0020022750832140445709228515625f, -0.0059098820202052593231201171875f, -0.01204908080399036407470703125f, -0.01822285912930965423583984375f, -0.022606931626796722412109375f, 0.00246085994876921176910400390625f, 0.0358682237565517425537109375f, 0.084016449749469757080078125f, 0.13556349277496337890625f, 0.17526127398014068603515625f, 0.2201765477657318115234375f };
static const float ps__262[33] = { -0.0001748439972288906574249267578125f, -0.0002058440004475414752960205078125f, -0.0001494530006311833858489990234375f, -5.16930012963712215423583984375e-05f, 0.0f, -6.6171000071335583925247192382812e-05f, -0.00024505800683982670307159423828125f, -0.00043292800546623766422271728515625f, -0.000472643994726240634918212890625f, -0.00025223600096069276332855224609375f, 0.00019892900309059768915176391601562f, 0.0006870580255053937435150146484375f, 0.0009441120200790464878082275390625f, 0.000803467002697288990020751953125f, 0.00036319901118986308574676513671875f, 1.3421999938145745545625686645508e-05f, 0.0002534019877202808856964111328125f, 0.00133946095593273639678955078125f, 0.00293297204189002513885498046875f, 0.0039834850467741489410400390625f, 0.00302668311633169651031494140625f, -0.001102056005038321018218994140625f, -0.0083730258047580718994140625f, -0.016897700726985931396484375f, -0.0229144804179668426513671875f, -0.02164234779775142669677734375f, -0.028863273561000823974609375f, 0.0272719562053680419921875f, 0.0549219213426113128662109375f, 0.09834258258342742919921875f, 0.139044284820556640625f, 0.168055832386016845703125f, 0.1785714328289031982421875f };
static const float ps__499[33] = { 0.0f, 0.0f, 0.0f, 0.0f, 0.0f, 0.0f, 0.0f, 0.0f, -0.00011884699779329821467399597167969f, -0.00027130599482916295528411865234375f, -0.00050264201126992702484130859375f, -0.0009308329899795353412628173828125f, -0.001451013027690351009368896484375f, -0.00206474401056766510009765625f, -0.00270043197087943553924560546875f, -0.0032412759028375148773193359375f, -0.0035249479115009307861328125f, -0.0033502839505672454833984375f, -0.00249172910116612911224365234375f, -0.0007211489719338715076446533203125f, 0.002164659090340137481689453125f, 0.00631363503634929656982421875f, 0.011789103038609027862548828125f, 0.01854565925896167755126953125f, 0.02641439624130725860595703125f, 0.0351007096469402313232421875f, 0.044196568429470062255859375f, 0.05320720374584197998046875f, 0.061590276658535003662109375f, 0.068803600966930389404296875f, 0.074356190860271453857421875f, 0.077856563031673431396484375f, 0.079052396118640899658203125f };








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

float ps_smothstep(float e0, float e1, float x)
{
    return clamp((x - e0) / (e1 - e0), 0.0f, 1.0f);
}

float3 ps_fetch_offset2(float2 dx)
{
    return ps_sample_lod0(LIBRA_SAMPLER2D_2, ps_vTexCoord + dx).xyz + ps_sample_lod0(LIBRA_SAMPLER2D_2, ps_vTexCoord - dx).xyz;
}

float3 ps_fetch_offset3(float3 dx)
{
    return float3(ps_sample_lod0(LIBRA_SAMPLER2D_2, ps_vTexCoord + dx.xz).x + ps_sample_lod0(LIBRA_SAMPLER2D_2, ps_vTexCoord - dx.xz).x, ps_sample_lod0(LIBRA_SAMPLER2D_2, ps_vTexCoord + dx.yz).yz + ps_sample_lod0(LIBRA_SAMPLER2D_2, ps_vTexCoord - dx.yz).yz);
}

float ps_get_luma(float3 c)
{
    return dot(c, float3(0.29890000820159912109375f, 0.58700001239776611328125f, 0.114000000059604644775390625f));
}

void ps_frag_main()
{
    ps_auto_rez = lerp(1.0f, 0.5f, clamp((params_auto_res * round(params_OriginalSize.x / 300.0f)) - 1.0f, 0.0f, 1.0f));
    if ((ps_vTexCoord.x * params_speedup) > 1.00325000286102294921875f)
    {
        discard;
    }
    float luma_filter_3_phase[33] = ps__171;
    float res = (params_ntsc_scale * ps_auto_rez) * params_nscale;
    float OriginalSize = params_OriginalSize.x * ps_auto_rez;
    float2 one_x = ((params_OriginalSize.zz * 0.25f) / res.xx) / params_speedup.xx;
    float3 signal = 0.0f.xxx;
    float _209;
    if (params_ntsc_phase < 1.5f)
    {
        _209 = (OriginalSize > 300.0f) ? 2.0f : 3.0f;
    }
    else
    {
        _209 = (params_ntsc_phase > 2.5f) ? 3.0f : 2.0f;
    }
    float phase = _209;
    if (params_ntsc_phase > 3.5f)
    {
        phase = 3.0f;
        luma_filter_3_phase = ps__262;
    }
    float offset = 0.0f;
    int i = 0;
    float j = 0.0f;
    float3 wsum = 0.0f.xxx;
    float3 sums = wsum;
    float3 tmp = wsum;
    if (phase < 2.5f)
    {
        float iloop = max(params_ntsc_taps, 8.0f);
        if (params_ntsc_charp > 0.25f)
        {
            iloop = min(iloop, 14.0f);
        }
        int loopstart = int(32.0f - iloop);
        float ltap = iloop + 1.0f;
        float cs_sub = iloop - (iloop / params_ntsc_cscale);
        float ctap = 0.0f;
        float param = 16.0f;
        float param_1 = 8.0f;
        float param_2 = iloop;
        float mit = 1.0f + (0.039999999105930328369140625f * pow(ps_smothstep(param, param_1, param_2), 0.5f));
        float2 dx = float2(one_x.x * mit, 0.0f);
        float2 dx1 = dx;
        i = loopstart;
        for (; i < 32; i++)
        {
            offset = float(i - loopstart);
            j = offset + 1.0f;
            dx1 = dx * (offset - iloop);
            float2 param_3 = dx1;
            sums = ps_fetch_offset2(param_3);
            ctap = max(j - cs_sub, 0.0f);
            tmp = float3(ps__262[max(i, 0)], ctap.xx);
            wsum += tmp;
            signal += (sums * tmp);
        }
        ctap = ltap - cs_sub;
        tmp = float3(0.1785714328289031982421875f, ctap.xx);
        wsum = (wsum + wsum) + tmp;
        signal += (ps_sample_lod0(LIBRA_SAMPLER2D_2, ps_vTexCoord).xyz * tmp);
        signal /= wsum;
    }
    else
    {
        one_x.y /= params_ntsc_cscale1;
        float3 dx_1 = float3(one_x.x, one_x.y, 0.0f);
        float mit_1 = 1.0f;
        float iloop_1 = min(params_ntsc_taps, 24.0f);
        if (params_ntsc_phase > 3.5f)
        {
            iloop_1 = max(iloop_1, 8.0f);
            float param_4 = 16.0f;
            float param_5 = 8.0f;
            float param_6 = iloop_1;
            mit_1 = 1.0f + (0.039999999105930328369140625f * pow(ps_smothstep(param_4, param_5, param_6), 0.5f));
        }
        float3 dx1_1 = dx_1;
        dx_1.x *= mit_1;
        int loopstart_1 = int(32.0f - iloop_1);
        i = loopstart_1;
        for (; i < 32; i++)
        {
            offset = float(i - loopstart_1);
            float2 _463 = dx_1.xy * (offset - iloop_1);
            dx1_1.x = _463.x;
            dx1_1.y = _463.y;
            float3 param_7 = dx1_1;
            sums = ps_fetch_offset3(param_7);
            tmp = float3(luma_filter_3_phase[i], ps__499[i].xx);
            wsum += tmp;
            signal += (sums * tmp);
        }
        tmp = float3(luma_filter_3_phase[32], 0.079052396118640899658203125f, 0.079052396118640899658203125f);
        wsum = (wsum + wsum) + tmp;
        signal += (ps_sample_lod0(LIBRA_SAMPLER2D_2, ps_vTexCoord).xyz * tmp);
        signal /= wsum;
    }
    signal.x = clamp(signal.x, 0.0f, 1.0f);
    if (params_ntsc_ring > 0.0500000007450580596923828125f)
    {
        float2 dx_2 = float2((params_OriginalSize.z / min(res, 1.0f)) / params_speedup, 0.0f);
        float a = ps_sample_lod0(LIBRA_SAMPLER2D_2, ps_vTexCoord - (dx_2 * 2.0f)).w;
        float b = ps_sample_lod0(LIBRA_SAMPLER2D_2, ps_vTexCoord - dx_2).w;
        float c = ps_sample_lod0(LIBRA_SAMPLER2D_2, ps_vTexCoord + (dx_2 * 2.0f)).w;
        float d = ps_sample_lod0(LIBRA_SAMPLER2D_2, ps_vTexCoord + dx_2).w;
        float e = ps_sample_lod0(LIBRA_SAMPLER2D_2, ps_vTexCoord).w;
        signal.x = lerp(signal.x, clamp(signal.x, min(min(min(a, b), min(c, d)), e), max(max(max(a, b), max(c, d)), e)), params_ntsc_ring);
    }
    float3 param_8 = ps_sample_lod0(LIBRA_SAMPLER2D_3, ps_vTexCoord * float2(params_speedup, 1.0f)).xyz;
    float orig = ps_get_luma(param_8);
    ps_FragColor = float4(signal, orig);
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
