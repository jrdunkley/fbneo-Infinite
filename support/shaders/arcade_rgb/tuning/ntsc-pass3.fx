// Tunable adaptation; fixed original and notices are in the parent folder.
// Derived from crt/shaders/guest/advanced/ntsc/ntsc-pass3.slang; see SOURCES and original shader notices.
row_major float4x4 global_MVP;
float4 params_OutputSize;
float4 params_OriginalSize;
float4 params_SourceSize;
uint params_FrameCount;
static const float params_ntsc_phase = 1.0;
static const float params_auto_res = 0.0;
float params_ntsc_sharp = 0.0;
static const float params_ntsc_fonts = 0.25;
static const float params_ntsc_charp = 10.000000;
static const float params_ntsc_charp3 = 10.000000;
static const float params_ntsc_shape = 0.80;
static const float params_ntsc_gamma = 1.0;
static const float params_ntsc_rainbow1 = 0.0;
static const float params_speedup = 1.0;
static const float params_RFNOISE = 0.30;
static const float params_RFNOISE1 = 0.00;
static const float params_RFNOISE2 = 0.00;
texture Image2; sampler2D LIBRA_SAMPLER2D_2 : register(s0) = sampler_state { Texture = <Image2>; };
texture Image3; sampler2D LIBRA_SAMPLER2D_3 : register(s1) = sampler_state { Texture = <Image3>; };
texture Image4; sampler2D LIBRA_SAMPLER2D_4 : register(s2) = sampler_state { Texture = <Image4>; };
float4 vs_sample_lod0(sampler2D s, float2 uv) { return tex2Dlod(s, float4(uv,0,0)); }




uniform float4 vs_gl_HalfPixel;

static float4 vs_gl_Position;
static float4 vs_Position;
static float2 vs_vTexCoord0;
static float2 vs_TexCoord;
static float2 vs_vTexCoord1;
static float2 vs_vTexCoord;

struct vs_SPIRV_Cross_Input
{
    float4 vs_Position : TEXCOORD0;
    float2 vs_TexCoord : TEXCOORD1;
};

struct vs_SPIRV_Cross_Output
{
    float4 vs_gl_Position : POSITION;
float4 packed0 : TEXCOORD0;
float4 packed1 : TEXCOORD1;
};

static float vs_auto_rez;
static float vs_RFNOISE;

void vs_vert_main()
{
    vs_auto_rez = lerp(1.0f, 0.5f, clamp((params_auto_res * round(params_OriginalSize.x / 300.0f)) - 1.0f, 0.0f, 1.0f));
    vs_RFNOISE = (params_RFNOISE * params_RFNOISE) + 9.9999997473787516355514526367188e-06f;
    vs_gl_Position = mul(vs_Position, global_MVP);
    vs_vTexCoord0 = vs_TexCoord / float2(params_speedup, 1.0f);
    vs_vTexCoord1 = (floor(vs_vTexCoord0 * params_OriginalSize.xy) + 0.5f.xx) * params_OriginalSize.zw;
    vs_vTexCoord = vs_TexCoord + float2((0.5f * (params_OriginalSize.z / vs_auto_rez)) / 4.0f, 0.0f);
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
    stage_output.packed0.zw = vs_vTexCoord0;
    stage_output.packed1.xy = vs_vTexCoord1;
    stage_output.packed0.xy = vs_vTexCoord;
    return stage_output;
}

float4 ps_sample_lod0(sampler2D s, float2 uv) { return tex2Dlod(s, float4(uv,0,0)); }








static float2 ps_vTexCoord0;
static float4 ps_FragColor;
static float2 ps_vTexCoord;
static float2 ps_vTexCoord1;

struct ps_SPIRV_Cross_Input
{
float4 packed0 : TEXCOORD0;
float4 packed1 : TEXCOORD1;
};

struct ps_SPIRV_Cross_Output
{
    float4 ps_FragColor : COLOR0;
};

static float ps_auto_rez;
static float ps_RFNOISE;

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

float3 ps_yiq2rgb(float3 yiq)
{
    return mul(float3x3(float3(1.0f, 0.95599997043609619140625f, 0.620999991893768310546875f), float3(1.0f, -0.272000014781951904296875f, -0.64740002155303955078125f), float3(1.0f, -1.10599994659423828125f, 1.70459997653961181640625f)), yiq);
}

float ps_smothstep(float e0, float e1, float x)
{
    return clamp((x - e0) / (e1 - e0), 0.0f, 1.0f);
}

float3 ps_rgb2yiq(float3 col)
{
    return mul(float3x3(float3(0.29890000820159912109375f, 0.58700001239776611328125f, 0.114000000059604644775390625f), float3(0.595899999141693115234375f, -0.2743999958038330078125f, -0.3215999901294708251953125f), float3(0.21150000393390655517578125f, -0.52289998531341552734375f, 0.311399996280670166015625f)), col);
}

float2 ps_psrnd(float2 TexCoord, float FrameCount)
{
    float3 p = float3(TexCoord * 16758.544921875f, FrameCount);
    float x = frac(sin(dot(p, float3(12.98980045318603515625f, 78.233001708984375f, 3.183000087738037109375f))) * 43758.546875f);
    float y = frac(sin(dot(p, float3(25.9796009063720703125f, 14.11299991607666015625f, 11.270999908447265625f))) * 96321.9140625f);
    return float2(x, y);
}

float3 ps_Noise(inout float2 TexCoord, float FrameCount)
{
    float2 param = TexCoord;
    float param_1 = FrameCount;
    TexCoord = ps_psrnd(param, param_1);
    float3 p = float3(TexCoord * 758.5452880859375f, FrameCount);
    float res1 = frac(sin(dot(p, float3(12.98983478546142578125f, 78.2334136962890625f, 0.16452999413013458251953125f))) * 43758.546875f);
    float res2 = frac(sin(dot(p, float3(39.346790313720703125f, 11.13523006439208984375f, 83.155731201171875f))) * 39459.32421875f);
    float res3 = frac(sin(dot(p, float3(73.15691375732421875f, 52.23503875732421875f, 9.15196990966796875f))) * 60493.84765625f);
    float lns = float(abs(res1 - 0.5f) < (0.20000000298023223876953125f * ps_RFNOISE));
    float cny = float(abs(res2 - 0.5f) < (0.5f * ps_RFNOISE));
    float cnz = float(abs(res3 - 0.5f) < (0.5f * ps_RFNOISE));
    float param_2 = 0.5f - (0.20000000298023223876953125f * ps_RFNOISE);
    float param_3 = 0.5f + (0.20000000298023223876953125f * ps_RFNOISE);
    float param_4 = res1;
    lns = ((lns * ps_smothstep(param_2, param_3, param_4)) * 0.660000026226043701171875f) - (0.3300000131130218505859375f * lns);
    float param_5 = 0.5f - (0.5f * ps_RFNOISE);
    float param_6 = 0.5f + (0.5f * ps_RFNOISE);
    float param_7 = res2;
    cny = (cny * ps_smothstep(param_5, param_6, param_7)) - (0.5f * cny);
    float param_8 = 0.5f - (0.5f * ps_RFNOISE);
    float param_9 = 0.5f + (0.5f * ps_RFNOISE);
    float param_10 = res3;
    cnz = (cnz * ps_smothstep(param_8, param_9, param_10)) - (0.5f * cnz);
    return float3(lns, cny, cnz);
}

void ps_frag_main()
{
    ps_auto_rez = lerp(1.0f, 0.5f, clamp((params_auto_res * round(params_OriginalSize.x / 300.0f)) - 1.0f, 0.0f, 1.0f));
    ps_RFNOISE = (params_RFNOISE * params_RFNOISE) + 9.9999997473787516355514526367188e-06f;
    bool _279 = params_speedup > 1.25f;
    bool _302;
    if (_279)
    {
        bool _286 = params_OriginalSize.y > 500.0f;
        bool _294;
        if (_286)
        {
            _294 = params_SourceSize.y > 820.0f;
        }
        else
        {
            _294 = _286;
        }
        bool _301;
        if (!_294)
        {
            _301 = params_SourceSize.y > 820.0f;
        }
        else
        {
            _301 = _294;
        }
        _302 = _301;
    }
    else
    {
        _302 = _279;
    }
    if (_302)
    {
        float3 signal = ps_sample_lod0(LIBRA_SAMPLER2D_2, ps_vTexCoord0).xyz;
        signal.x = pow(signal.x, 1.0f / params_ntsc_gamma);
        float3 param = signal;
        ps_FragColor = float4(clamp(ps_yiq2rgb(param), 0.0f.xxx, 1.0f.xxx), 1.0f);
    }
    else
    {
        float2 xx = float2(((0.5f * params_OriginalSize.z) / ps_auto_rez) / params_speedup, 0.0f);
        float2 dx = float2(((0.0625f * params_OriginalSize.z) / ps_auto_rez) / params_speedup, 0.0f);
        float2 texcoord0 = (floor(params_OriginalSize.xy * ps_vTexCoord) + 0.5f.xx) * params_OriginalSize.zw;
        float2 texcoord = ps_vTexCoord - (dx * 2.0f);
        float2 vTex = ps_vTexCoord;
        if (params_speedup > 1.25f)
        {
            texcoord0 = ps_vTexCoord1;
            texcoord = ps_vTexCoord0;
            vTex = ps_vTexCoord0;
        }
        float3 l1 = ps_sample_lod0(LIBRA_SAMPLER2D_2, texcoord + xx).xyz;
        float3 l2 = ps_sample_lod0(LIBRA_SAMPLER2D_2, texcoord - xx).xyz;
        float dy = 0.0f;
        float2 yy = float2(0.0f, params_OriginalSize.w);
        xx = float2((params_OriginalSize.z / ps_auto_rez) / params_speedup, 0.0f);
        float _425;
        if (params_ntsc_phase < 1.5f)
        {
            _425 = ((params_OriginalSize.x * ps_auto_rez) > 300.0f) ? 2.0f : 3.0f;
        }
        else
        {
            _425 = (params_ntsc_phase > 2.5f) ? 3.0f : 2.0f;
        }
        float phase = _425;
        if (params_ntsc_phase > 3.5f)
        {
            phase = 3.0f;
        }
        float th = (phase < 2.5f) ? 0.02500000037252902984619140625f : 0.0074999998323619365692138671875f;
        float ca = ps_sample_lod0(LIBRA_SAMPLER2D_3, (texcoord0 - xx) - xx).w;
        float c0 = ps_sample_lod0(LIBRA_SAMPLER2D_3, texcoord0 - xx).w;
        float c1 = ps_sample_lod0(LIBRA_SAMPLER2D_3, texcoord0).w;
        float c2 = ps_sample_lod0(LIBRA_SAMPLER2D_3, texcoord0 + xx).w;
        float cb = ps_sample_lod0(LIBRA_SAMPLER2D_3, (texcoord0 + xx) + xx).w;
        float param_1 = th;
        float param_2 = 0.0f;
        float param_3 = min(abs(c1 - c0), abs(c2 - c1));
        float line0 = ps_smothstep(param_1, param_2, param_3);
        float param_4 = th;
        float param_5 = 0.0f;
        float param_6 = min(abs(ca - c0), abs(c2 - cb));
        float line1 = max(ps_smothstep(param_4, param_5, param_6), line0);
        float param_7 = th;
        float param_8 = 0.0f;
        float param_9 = min(abs(ca - c2), abs(c0 - cb));
        float line2 = max(ps_smothstep(param_7, param_8, param_9), line1);
        float diffboost = 0.0f;
        if (params_ntsc_fonts > 0.25499999523162841796875f)
        {
            float b1 = ps_sample_lod0(LIBRA_SAMPLER2D_3, texcoord0 - yy).w;
            float d1 = ps_sample_lod0(LIBRA_SAMPLER2D_3, texcoord0 + yy).w;
            float d2 = ps_sample_lod0(LIBRA_SAMPLER2D_3, (texcoord0 + xx) + yy).w;
            float maxdif = float((0.5f * (abs(c0 - c1) + abs(c1 - c2))) > (1.0f - params_ntsc_fonts));
            float param_10 = 0.100000001490116119384765625f;
            float param_11 = 0.0f;
            float param_12 = max(abs(c1 - b1), abs(c1 - d1));
            float linecb = ps_smothstep(param_10, param_11, param_12);
            bool _609 = abs(c1 - b1) < 0.0500000007450580596923828125f;
            bool _618;
            if (!_609)
            {
                _618 = abs(c2 - d2) < 0.0500000007450580596923828125f;
            }
            else
            {
                _618 = _609;
            }
            linecb *= float(_618);
            float xdif1 = 0.0f;
            float xdif2 = 0.0f;
            float th_1 = 0.2150000035762786865234375f;
            for (float i = 0.5f; i < 10.5f; i += 1.0f)
            {
                float j = i + 1.0f;
                ca = ps_sample_lod0(LIBRA_SAMPLER2D_2, texcoord - (xx * i)).x;
                c0 = ps_sample_lod0(LIBRA_SAMPLER2D_2, texcoord - (xx * j)).x;
                c2 = ps_sample_lod0(LIBRA_SAMPLER2D_2, texcoord + (xx * i)).x;
                cb = ps_sample_lod0(LIBRA_SAMPLER2D_2, texcoord + (xx * j)).x;
                xdif1 = max(abs(ca - c0) - th_1, xdif1);
                xdif2 = max(abs(cb - c2) - th_1, xdif2);
            }
            float param_13 = 0.0f;
            float param_14 = 0.125f;
            float param_15 = min(xdif1, xdif2);
            float linex = ps_smothstep(param_13, param_14, param_15);
            diffboost = min((linex * linecb) * maxdif, 0.625f);
        }
        float3 ref = ps_sample_lod0(LIBRA_SAMPLER2D_2, texcoord).xyz;
        float2 orig = ref.yz;
        bool _714 = params_ntsc_rainbow1 > 0.5f;
        bool _727;
        if (_714)
        {
            bool _718 = phase < 2.5f;
            bool _726;
            if (!_718)
            {
                _726 = params_ntsc_phase == 5.0f;
            }
            else
            {
                _726 = _718;
            }
            _727 = _726;
        }
        else
        {
            _727 = _714;
        }
        if (_727)
        {
            float ybool = 1.0f;
            if ((params_ntsc_rainbow1 < 1.5f) && (line0 != 0.0f))
            {
                ybool = 0.0f;
            }
            else
            {
                if ((params_ntsc_rainbow1 < 2.5f) && (line2 != 0.0f))
                {
                    ybool = 0.0f;
                }
            }
            float line_no = floor(ps_mod(params_OriginalSize.y * ps_vTexCoord.y, 2.0f));
            float frame_no = floor(ps_mod(float(params_FrameCount), 2.0f));
            float ii = abs(line_no - frame_no);
            dy = (ii * params_OriginalSize.w) * ybool;
            float2 ref1 = ps_sample_lod0(LIBRA_SAMPLER2D_2, texcoord - float2(0.0f, dy)).yz;
            float2 ref2 = ps_sample_lod0(LIBRA_SAMPLER2D_2, texcoord + float2(0.0f, dy)).yz;
            float2 rdf1 = abs(orig - ref1);
            float2 rdf2 = abs(orig - ref2);
            rdf1 /= max(rdf1 + rdf2, 1.0000000116860974230803549289703e-07f.xx);
            float2 _813 = lerp(ref1, ref2, rdf1);
            ref.y = _813.x;
            ref.z = _813.y;
        }
        float lum1 = min(ps_sample_lod0(LIBRA_SAMPLER2D_3, vTex - dx).w, ps_sample_lod0(LIBRA_SAMPLER2D_3, vTex + dx).w);
        float lum2 = ref.x;
        float3 l3 = abs(l1 - l2);
        float dif = max(max(max(l3.x, l3.y), max(l3.z, abs((l1.x * l1.x) - (l2.x * l2.x)))), diffboost);
        float dff = pow(dif, 0.125f);
        float param_16 = 0.20000000298023223876953125f;
        float param_17 = 0.100000001490116119384765625f;
        float param_18 = abs(lum2 - lum1);
        float lc = ps_smothstep(param_16, param_17, param_18) * dff;
        float param_19 = 0.0500000007450580596923828125f - (0.02999999932944774627685546875f * lc);
        float param_20 = 0.425000011920928955078125f - (0.375f * lc);
        float param_21 = dif;
        float tmp = ps_smothstep(param_19, param_20, param_21);
        float tmp1 = pow((tmp + 0.100000001490116119384765625f) / 1.10000002384185791015625f, 0.25f);
        float sweight = lerp(tmp, tmp1, line0);
        float sweighr = lerp(tmp, tmp1, line2);
        float3 signal_1 = ref;
        float ntsc_sharp = abs(params_ntsc_sharp);
        if (ntsc_sharp > 0.25f)
        {
            float mixer = sweight;
            if (params_ntsc_sharp > 0.25f)
            {
                mixer = sweighr;
            }
            mixer *= (0.100000001490116119384765625f * ntsc_sharp);
            float lummix = lerp(lum2, lum1, mixer);
            float lm1 = lerp(lum2 * lum2, lum1 * lum1, mixer);
            lm1 = sqrt(lm1);
            float lm2 = lerp(sqrt(lum2), sqrt(lum1), mixer);
            lm2 *= lm2;
            float k1 = abs(lummix - lm1) + 9.9999997473787516355514526367188e-06f;
            float k2 = abs(lummix - lm2) + 9.9999997473787516355514526367188e-06f;
            signal_1.x = min(((k2 * lm1) + (k1 * lm2)) / (k1 + k2), 1.0f);
            signal_1.x = min(signal_1.x, max(params_ntsc_shape * signal_1.x, lum2));
        }
        if ((params_ntsc_charp + params_ntsc_charp3) > 0.25f)
        {
            dx.x = (0.0625f * params_OriginalSize.z) / ps_auto_rez;
            float texcoordx = (params_OriginalSize.x * (ps_vTexCoord.x + dx.x)) - 0.5f;
            float fpx = frac(texcoordx);
            texcoordx = (floor(texcoordx) + 0.5f) * params_OriginalSize.z;
            float mixer_1 = sweight;
            if (params_ntsc_sharp > 0.25f)
            {
                mixer_1 = sweighr;
            }
            float param_22 = 0.07500000298023223876953125f;
            float param_23 = 0.125f;
            float param_24 = max(l3.y, l3.z);
            float param_25 = 0.014999999664723873138427734375f;
            float param_26 = 0.0274999998509883880615234375f;
            float param_27 = dif;
            mixer_1 = lerp(ps_smothstep(param_22, param_23, param_24), ps_smothstep(param_25, param_26, param_27), line2) * mixer_1;
            float _1062;
            if (phase < 2.5f)
            {
                _1062 = params_ntsc_charp;
            }
            else
            {
                _1062 = params_ntsc_charp3;
            }
            mixer_1 *= (0.100000001490116119384765625f * _1062);
            texcoord = float2(texcoordx, texcoord.y);
            float3 param_28 = lerp(ps_sample_lod0(LIBRA_SAMPLER2D_4, texcoord).xyz, ps_sample_lod0(LIBRA_SAMPLER2D_4, texcoord + (dx * 16.0f)).xyz, clamp((1.5f * fpx) - 0.25f, 0.0f, 1.0f).xxx);
            float3 orig_ch = ps_rgb2yiq(param_28);
            float3 _1100 = signal_1;
            float2 _1106 = lerp(_1100.yz, orig_ch.yz, mixer_1.xx);
            signal_1.y = _1106.x;
            signal_1.z = _1106.y;
        }
        if ((params_RFNOISE1 + params_RFNOISE2) > 0.004999999888241291046142578125f)
        {
            float2 param_29 = ps_vTexCoord;
            float param_30 = float(params_FrameCount);
            float3 _1129 = ps_Noise(param_29, param_30);
            float3 ns = _1129;
            float Y = lerp(0.375f, 1.0f, pow(signal_1.x, 0.20000000298023223876953125f));
            signal_1.x = clamp(signal_1.x + (params_RFNOISE1 * ns.x), 0.0f, 1.0f);
            signal_1.y = clamp(signal_1.y + (((Y * params_RFNOISE2) * (0.324999988079071044921875f + (1.3250000476837158203125f * abs(signal_1.y)))) * ns.y), -0.60000002384185791015625f, 0.60000002384185791015625f);
            signal_1.z = clamp(signal_1.z + (((Y * params_RFNOISE2) * (0.324999988079071044921875f + (1.3250000476837158203125f * abs(signal_1.z)))) * ns.z), -0.5299999713897705078125f, 0.5299999713897705078125f);
        }
        signal_1.x = pow(signal_1.x, 1.0f / params_ntsc_gamma);
        float3 param_31 = signal_1;
        signal_1 = clamp(ps_yiq2rgb(param_31), 0.0f.xxx, 1.0f.xxx);
        bool _1201 = phase == 2.0f;
        bool _1208;
        if (!_1201)
        {
            _1208 = params_ntsc_phase > 3.5f;
        }
        else
        {
            _1208 = _1201;
        }
        sweighr = _1208 ? sweighr : 1.0f;
        ps_FragColor = float4(signal_1, sweighr);
    }
}

ps_SPIRV_Cross_Output ps_main(ps_SPIRV_Cross_Input stage_input)
{
    ps_vTexCoord0 = stage_input.packed0.zw;
    ps_vTexCoord = stage_input.packed0.xy;
    ps_vTexCoord1 = stage_input.packed1.xy;
    ps_frag_main();
    ps_SPIRV_Cross_Output stage_output;
    stage_output.ps_FragColor = float4(ps_FragColor);
    return stage_output;
}

technique t { pass p { VertexShader = compile vs_3_0 vs_main(); PixelShader = compile ps_3_0 ps_main(); } }
