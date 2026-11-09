// Lola Retro by Zoki (zoran123456), MIT; see LICENSE.
// Pinned upstream 6383ff7357be32c95baf6d31b4a1b1d3cd5c7069
// Isolated Infinite D3D9 prototype; preset studio-monitor-rgb, explicit arcade timing 8.
row_major float4x4 global_MVP;
static const float global_LR_HDR_SRC = 0.0;
static const float global_LR_CONSOLE = 8;
static const float global_LR_NORM = 0;
static const float global_LR_HDR_SIG = 0.0;
static const float global_LR_CABLE = 3;
static const float global_LR_COMB = 0;
static const float global_LR_YTRAP = 0.75;
static const float global_LR_DBLEND = 0.0;
static const float global_LR_SHARP = 0;
static const float global_LR_SAT = 1;
static const float global_LR_TINT = 0;
static const float global_LR_DEMOD = 1;
static const float global_LR_BRIGHT = 0;
static const float global_LR_CONTRAST = 1;
static const float global_LR_NOISE = 0;
static const float global_LR_STEADY = 1;
static const float global_LR_HDR_BEAM = 0.0;
static const float global_LR_SIG_LO = 0.14;
static const float global_LR_SIG_HI = 0.32;
static const float global_LR_HFOCUS = 0.3;
static const float global_LR_GAMMA = 2.4;
static const float global_LR_PERSIST = 0.04;
static const float global_LR_CONV = 0.05;
static const float global_LR_HDR_MASK = 0.0;
static const float global_LR_MASK_TYPE = 1;
static const float global_LR_MASK_STR = 0.6;
static const float global_LR_MASK_TRIADS = 450;
static const float global_LR_WHITE = 6500;
static const float global_LR_PHOS = 3;
static const float global_LR_HDR_GLASS = 0.0;
static const float global_LR_CURV_X = 0;
static const float global_LR_CURV_Y = 0;
static const float global_LR_CORNER = 0;
static const float global_LR_GLOW = 0.03;
static const float global_LR_GLOW_SIZE = 0.5;
static const float global_LR_VIGNETTE = 0.15;
static const float global_LR_OVERSCAN = 0.03;
static const float global_LR_AMBIENT = 0;
static const float global_LR_HDR_MON = 0.0;
static const float global_LR_MON_MM = 0;
static const float global_LR_MON_SIZE = 15;
static const float global_LR_MON_PITCH = 0.28;
static const float global_LR_MON_SPOT_LO = 0.3;
static const float global_LR_MON_SPOT_HI = 0.45;
static const float global_LR_MON_CORNER = 1.4;
float4 params_SourceSize;
float4 params_OriginalSize;
float4 params_OutputSize;
uint params_FrameCount;
texture Image3; sampler2D LIBRA_SAMPLER2D_3 : register(s1) = sampler_state { Texture = <Image3>; };
float4 vs_sample_lod0(sampler2D s, float2 uv) { return tex2Dlod(s, float4(uv,0,0)); }
struct vs_Timing
{
    float pclk;
    float fsc;
    float lineFrac;
    float fieldStep;
    float framePhase;
    float vsw;
    float pal;
    float scan;
    float interlace;
    float scale;
    float id;
    float hres;
};

static const float vs__785[5] = { 1.0f, 0.726149022579193115234375f, 0.278037011623382568359375f, 0.056134998798370361328125f, 0.005975999869406223297119140625f };





uniform float4 vs_gl_HalfPixel;

static float4 vs_gl_Position;
static float4 vs_Position;
static float2 vs_vTexCoord;
static float2 vs_TexCoord;
static float vs_vScale;
static float vs_vScan;
static float2 vs_vShare;
static float vs_vConvW;

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

float vs_mod(float x, float y)
{
    return x - y * floor(x / y);
}

float2 vs_mod(float2 x, float2 y)
{
    return x - y * floor(x / y);
}

float3 vs_mod(float3 x, float3 y)
{
    return x - y * floor(x / y);
}

float4 vs_mod(float4 x, float4 y)
{
    return x - y * floor(x / y);
}

float vs_upscaleOf(float2 orig)
{
    float id = global_LR_CONSOLE;
    bool _295 = id < 5.5f;
    bool _304;
    if (!_295)
    {
        _304 = (id > 7.5f) && (id < 8.5f);
    }
    else
    {
        _304 = _295;
    }
    bool tv = _304;
    float base = ((id > 4.5f) && (id < 5.5f)) ? 480.0f : 240.0f;
    bool _317;
    if (id < 0.5f)
    {
        _317 = orig.y > 576.0f;
    }
    else
    {
        bool _333;
        if (tv)
        {
            _333 = orig.y > (base * 1.5f);
        }
        else
        {
            _333 = tv;
        }
        _317 = _333;
    }
    bool scaled = _317;
    if (!scaled)
    {
        return 1.0f;
    }
    for (float k = 2.0f; k <= 16.0f; k += 1.0f)
    {
        float lines = orig.y / k;
        bool _356 = lines == floor(lines);
        bool _364;
        if (_356)
        {
            _364 = lines >= (base * 0.829999983310699462890625f);
        }
        else
        {
            _364 = _356;
        }
        bool _372;
        if (_364)
        {
            _372 = lines <= (base * 1.21000003814697265625f);
        }
        else
        {
            _372 = _364;
        }
        if (_372)
        {
            return k;
        }
    }
    return max(1.0f, floor((orig.y / base) + 0.5f));
}

float vs_autoConsole(float2 s)
{
    float w = s.x;
    float h = s.y;
    bool mon15 = global_LR_MON_MM > 0.5f;
    bool _67 = !mon15;
    bool _94;
    if (_67)
    {
        bool _76 = (w == 320.0f) && (h == 200.0f);
        bool _93;
        if (!_76)
        {
            bool _82 = w == 640.0f;
            bool _92;
            if (_82)
            {
                _92 = (h == 350.0f) || (h == 400.0f);
            }
            else
            {
                _92 = _82;
            }
            _93 = _92;
        }
        else
        {
            _93 = _76;
        }
        _94 = _93;
    }
    else
    {
        _94 = _67;
    }
    if (_94)
    {
        return 7.0f;
    }
    bool _105 = (h == 256.0f) || (h == 512.0f);
    bool _114;
    if (!_105)
    {
        _114 = (w == 640.0f) && (h == 200.0f);
    }
    else
    {
        _114 = _105;
    }
    if (_114)
    {
        return 6.0f;
    }
    bool _127;
    if (mon15)
    {
        _127 = (h == 200.0f) || (h == 400.0f);
    }
    else
    {
        _127 = mon15;
    }
    bool _135;
    if (_127)
    {
        _135 = (w == 320.0f) || (w == 640.0f);
    }
    else
    {
        _135 = _127;
    }
    if (_135)
    {
        return 6.0f;
    }
    bool _149 = ((w == 360.0f) || (w == 720.0f)) || (w == 1440.0f);
    bool _167;
    if (_149)
    {
        _167 = (((h == 287.0f) || (h == 574.0f)) || (h == 242.0f)) || (h == 484.0f);
    }
    else
    {
        _167 = _149;
    }
    if (_167)
    {
        return 6.0f;
    }
    if (((h >= 336.0f) && (h <= 400.0f)) && (w >= 400.0f))
    {
        return 9.0f;
    }
    if (h > 300.0f)
    {
        return 5.0f;
    }
    if (w > 420.0f)
    {
        return 4.0f;
    }
    if (w <= 300.0f)
    {
        return 1.0f;
    }
    if (h >= 232.0f)
    {
        return 4.0f;
    }
    return 2.0f;
}

void vs_consoleTable(float id, out float4 a, out float4 b, out float c)
{
    if (id < 1.5f)
    {
        a = float4(5.3693180084228515625f, 5.32034206390380859375f, 256.0f, 0.0f);
        b = float4(0.3333333432674407958984375f, 0.16666667163372039794921875f, 0.3333333432674407958984375f, 0.0f);
        c = 0.0f;
    }
    else
    {
        if (id < 2.5f)
        {
            a = float4(6.71164703369140625f, 6.65042781829833984375f, 320.0f, 0.0f);
            b = 0.0f.xxxx;
            c = 1.0f;
        }
        else
        {
            if (id < 3.5f)
            {
                a = float4(5.3693180084228515625f, 5.32034206390380859375f, 256.0f, 0.0f);
                b = 0.0f.xxxx;
                c = 1.0f;
            }
            else
            {
                if (id < 4.5f)
                {
                    a = float4(6.71164703369140625f, 6.652800083160400390625f, 320.0f, 0.0f);
                    b = float4(0.5f, 0.75f, 0.5f, 0.5f);
                    c = 0.0f;
                }
                else
                {
                    if (id < 5.5f)
                    {
                        a = float4(13.5f, 13.5f, 640.0f, 0.0f);
                        b = float4(0.5f, 0.75f, 0.75f, 0.875f);
                        c = 0.0f;
                    }
                    else
                    {
                        if (id < 6.5f)
                        {
                            a = float4(7.1590900421142578125f, 7.0937900543212890625f, 320.0f, 0.0f);
                            b = float4(0.5f, 0.75f, 0.75f, 0.875f);
                            c = 0.0f;
                        }
                        else
                        {
                            if (id < 7.5f)
                            {
                                a = float4(12.5874996185302734375f, 12.5874996185302734375f, 320.0f, 1.0f);
                                b = float4(0.5f, 0.75f, 0.75f, 0.875f);
                                c = 0.0f;
                            }
                            else
                            {
                                if (id < 8.5f)
                                {
                                    a = float4(6.71164703369140625f, 6.71164703369140625f, 320.0f, 0.0f);
                                    b = float4(0.5f, 0.75f, 0.5f, 0.5f);
                                    c = 0.0f;
                                }
                                else
                                {
                                    a = float4(16.0f, 16.0f, 496.0f, 2.0f);
                                    b = float4(0.5f, 0.75f, 0.75f, 0.875f);
                                    c = 0.0f;
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}

vs_Timing vs_getTiming(float2 orig, uint frameCount)
{
    float2 param = orig;
    vs_Timing t;
    t.scale = vs_upscaleOf(param);
    float2 nat = orig / t.scale.xx;
    float _416;
    if (global_LR_CONSOLE < 0.5f)
    {
        float2 param_1 = nat;
        _416 = vs_autoConsole(param_1);
    }
    else
    {
        _416 = global_LR_CONSOLE;
    }
    float id = _416;
    float param_2 = id;
    float4 param_3;
    float4 param_4;
    float param_5;
    vs_consoleTable(param_2, param_3, param_4, param_5);
    float4 a = param_3;
    float4 b = param_4;
    float c = param_5;
    t.id = id;
    bool _444 = (id > 4.5f) && (id < 5.5f);
    bool _451;
    if (_444)
    {
        _451 = nat.x > 700.0f;
    }
    else
    {
        _451 = _444;
    }
    if (_451)
    {
        a.z = 720.0f;
    }
    t.scan = a.w;
    bool _464 = t.scan < 0.5f;
    bool _470;
    if (_464)
    {
        _470 = nat.y > 300.0f;
    }
    else
    {
        _470 = _464;
    }
    t.interlace = float(_470);
    bool amiga = (id > 5.5f) && (id < 6.5f);
    if (global_LR_NORM > 1.5f)
    {
        t.pal = 1.0f;
    }
    else
    {
        if (global_LR_NORM > 0.5f)
        {
            t.pal = 0.0f;
        }
        else
        {
            float _499;
            if (t.interlace > 0.5f)
            {
                _499 = nat.y * 0.5f;
            }
            else
            {
                _499 = nat.y;
            }
            float lines = _499;
            bool _511 = t.scan < 0.5f;
            bool _520;
            if (_511)
            {
                _520 = lines > (amiga ? 249.5f : 240.5f);
            }
            else
            {
                _520 = _511;
            }
            t.pal = float(_520);
        }
    }
    float base = lerp(a.x, a.y, t.pal);
    t.pclk = (base * orig.x) / a.z;
    float _544;
    if (orig.x < 480.0f)
    {
        _544 = 1.0f;
    }
    else
    {
        _544 = (orig.x < 960.0f) ? 2.0f : 4.0f;
    }
    float cls = _544;
    if (amiga)
    {
        t.pclk = (base * (320.0f * cls)) / a.z;
    }
    bool _567 = t.scan > 0.5f;
    bool _573;
    if (_567)
    {
        _573 = t.scan < 1.5f;
    }
    else
    {
        _573 = _567;
    }
    bool _579;
    if (_573)
    {
        _579 = orig.x > 720.0f;
    }
    else
    {
        _579 = _573;
    }
    if (_579)
    {
        t.pclk = ((78.75f * orig.x) * orig.y) / 786432.0f;
    }
    float _594;
    if (amiga)
    {
        _594 = cls;
    }
    else
    {
        _594 = orig.x / a.z;
    }
    t.hres = _594;
    t.fsc = (t.pal > 0.5f) ? 4.433619022369384765625f : 3.57954502105712890625f;
    t.lineFrac = lerp(b.x, b.y, t.pal);
    t.fieldStep = lerp(b.z, b.w, t.pal);
    float _635;
    if (global_LR_STEADY > 0.5f)
    {
        _635 = 0.0f;
    }
    else
    {
        _635 = float(frameCount % 24u);
    }
    float fc = _635;
    t.framePhase = frac(fc * t.fieldStep);
    t.vsw = vs_mod(fc * c, 2.0f);
    return t;
}

float vs_activeShare(vs_Timing t, float2 orig)
{
    bool _662 = t.scan < 0.5f;
    bool _668;
    if (_662)
    {
        _668 = global_LR_MON_MM > 0.5f;
    }
    else
    {
        _668 = _662;
    }
    if (!_668)
    {
        return 1.0f;
    }
    return min((orig.x / t.pclk) / ((t.pal > 0.5f) ? 52.0f : 52.59999847412109375f), 1.0f);
}

bool vs_isAmiga(vs_Timing t)
{
    bool _391 = t.id > 5.5f;
    bool _397;
    if (_391)
    {
        _397 = t.id < 6.5f;
    }
    else
    {
        _397 = _391;
    }
    return _397;
}

void vs_vert_main()
{
    vs_gl_Position = mul(vs_Position, global_MVP);
    vs_vTexCoord = vs_TexCoord;
    float2 param = params_OriginalSize.xy;
    uint param_1 = params_FrameCount;
    vs_Timing T = vs_getTiming(param, param_1);
    vs_vScale = T.scale;
    vs_vScan = T.scan;
    float vis = ((T.pal > 0.5f) ? 288.0f : 240.0f) * ((T.interlace > 0.5f) ? 2.0f : 1.0f);
    vs_Timing param_2 = T;
    float2 param_3 = params_OriginalSize.xy;
    float _749;
    if (T.scan < 0.5f)
    {
        _749 = min((params_OriginalSize.y / T.scale) / vis, 1.0f);
    }
    else
    {
        _749 = 1.0f;
    }
    vs_vShare = float2(vs_activeShare(param_2, param_3), _749);
    vs_Timing param_4 = T;
    float _768;
    if (vs_isAmiga(param_4))
    {
        _768 = 320.0f * T.hres;
    }
    else
    {
        _768 = params_OriginalSize.x;
    }
    vs_vConvW = _768;
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
    stage_output.packed0.z = vs_vScale;
    stage_output.packed0.w = vs_vScan;
    stage_output.packed1.xy = vs_vShare;
    stage_output.packed1.z = vs_vConvW;
    return stage_output;
}

float4 ps_sample_lod0(sampler2D s, float2 uv) { return tex2Dlod(s, float4(uv,0,0)); }
static const float ps__756[5] = { 1.0f, 0.726149022579193115234375f, 0.278037011623382568359375f, 0.056134998798370361328125f, 0.005975999869406223297119140625f };







static float2 ps_vTexCoord;
static float ps_vScale;
static float4 ps_FragColor;
static float ps_vScan;
static float2 ps_vShare;
static float ps_vConvW;

struct ps_SPIRV_Cross_Input
{
float4 packed0 : TEXCOORD0;
float4 packed1 : TEXCOORD1;
};

struct ps_SPIRV_Cross_Output
{
    float4 ps_FragColor : COLOR0;
};

float ps_hash13(inout float3 p3)
{
    p3 = frac(p3 * 0.103100001811981201171875f);
    p3 += dot(p3, p3.zyx + 31.31999969482421875f.xxx).xxx;
    return frac((p3.x + p3.y) * p3.z);
}

bool ps_isPC(float scan)
{
    return (scan > 0.5f) && (scan < 1.5f);
}

bool ps_inMM(float scan)
{
    float param = scan;
    bool _80 = ps_isPC(param);
    bool _100;
    if (!_80)
    {
        bool _85 = scan < 0.5f;
        bool _99;
        if (_85)
        {
            _99 = global_LR_MON_MM > 0.5f;
        }
        else
        {
            _99 = _85;
        }
        _100 = _99;
    }
    else
    {
        _100 = _80;
    }
    return _100;
}

float ps_monCornerGrowth(float2 c)
{
    return 1.0f + (((global_LR_MON_CORNER - 1.0f) * 0.5f) * dot(c, c));
}

float2 ps_monTubeMM()
{
    float d = (global_LR_MON_SIZE - 1.0f) * 25.3999996185302734375f;
    return float2(0.800000011920928955078125f * d, 0.60000002384185791015625f * d);
}

float2 ps_monScanMM()
{
    return ps_monTubeMM() / (1.0f - global_LR_OVERSCAN).xx;
}

float3 ps_gaussCdf(float3 z)
{
    float3 x = abs(z) * 0.707106769084930419921875f;
    float3 t = 1.0f.xxx / (1.0f.xxx + (x * 0.3275910913944244384765625f));
    float3 p = ((((((((t * 1.0614054203033447265625f) - 1.45315206050872802734375f.xxx) * t) + 1.42141377925872802734375f.xxx) * t) - 0.284496724605560302734375f.xxx) * t) + 0.254829585552215576171875f.xxx) * t;
    return 0.5f.xxx + ((sign(z) * 0.5f) * (1.0f.xxx - (p * exp((-x) * x))));
}

float3 ps_gaussPdf(float3 z)
{
    return exp((z * (-0.5f)) * z) * 0.398942291736602783203125f;
}

void ps_frag_main()
{
    float i = floor(ps_vTexCoord.y * params_OutputSize.y);
    if (i >= (params_OriginalSize.y / ps_vScale))
    {
        ps_FragColor = 0.0f.xxxx;
        return;
    }
    float x = ps_vTexCoord.x - (0.5f * params_OutputSize.z);
    float _247;
    if (global_LR_CABLE < 0.5f)
    {
        _247 = 0.5f + (global_LR_NOISE * 4.0f);
    }
    else
    {
        _247 = 0.0f;
    }
    float jitter = _247;
    float seed = float(params_FrameCount % 997u);
    float _269;
    if (jitter > 0.0f)
    {
        float3 param = float3(i, seed, 5.0f);
        float _277 = ps_hash13(param);
        _269 = ((_277 - 0.5f) * jitter) * params_OriginalSize.z;
    }
    else
    {
        _269 = 0.0f;
    }
    float jit = _269;
    float2 tc = float2(x + jit, ((i * ps_vScale) + 0.5f) * params_OriginalSize.w);
    float param_1 = ps_vScan;
    bool pc = ps_isPC(param_1);
    float param_2 = ps_vScan;
    bool mm = ps_inMM(param_2);
    float cx = (((x - 0.5f) * 2.0f) * ps_vShare.x) / (1.0f - global_LR_OVERSCAN);
    float cy = ((((((i + 0.5f) * ps_vScale) * params_OriginalSize.w) - 0.5f) * 2.0f) * ps_vShare.y) / (1.0f - global_LR_OVERSCAN);
    float2 param_3 = float2(cx, cy);
    float mmUnit = (0.4246608912944793701171875f * ps_monCornerGrowth(param_3)) / (ps_monScanMM().x * ps_vShare.x);
    float3 acc = 0.0f.xxx;
    float3 dacc = 0.0f.xxx;
    float3 inv = 0.0f.xxx;
    float spot = 1.0f;
    float sLo;
    float sHi;
    if (pc)
    {
        float W = params_OriginalSize.x;
        sLo = (global_LR_MON_SPOT_LO * mmUnit) * W;
        sHi = (max(global_LR_MON_SPOT_LO, global_LR_MON_SPOT_HI) * mmUnit) * W;
        float px = tc.x * W;
        int j0 = int(floor(px - (3.0f * sHi)));
        int j1 = int(floor(px + (3.0f * sHi)));
        for (int k = 0; k < 24; k++)
        {
            int j = j0 + k;
            if (j > j1)
            {
                break;
            }
            float fj = float(j);
            float3 b = pow(clamp(tex2Dlod(LIBRA_SAMPLER2D_3, float4(float2((fj + 0.5f) / W, tc.y), 0.0, 0.0f)).xyz, 0.0f.xxx, 1.0f.xxx), (0.5f * global_LR_GAMMA).xxx);
            float3 sg = lerp(sLo.xxx, sHi.xxx, b);
            float3 zl = (fj - px).xxx / sg;
            float3 zr = ((fj + 1.0f) - px).xxx / sg;
            float3 param_4 = zr;
            float3 param_5 = zl;
            float3 l = (b * b) * (ps_gaussCdf(param_4) - ps_gaussCdf(param_5));
            acc += l;
            inv += (l / sg);
            float3 param_6 = zl;
            float3 param_7 = zr;
            dacc += (((b * b) * (ps_gaussPdf(param_6) - ps_gaussPdf(param_7))) / sg);
        }
        dacc *= W;
    }
    else
    {
        float f = (2.0f * max(global_LR_HFOCUS, 0.0500000007450580596923828125f)) / 320.0f;
        float _524;
        if (mm)
        {
            _524 = global_LR_MON_SPOT_LO * mmUnit;
        }
        else
        {
            _524 = global_LR_SIG_LO * f;
        }
        sLo = _524;
        float _539;
        if (mm)
        {
            _539 = max(global_LR_MON_SPOT_LO, global_LR_MON_SPOT_HI) * mmUnit;
        }
        else
        {
            _539 = max(global_LR_SIG_LO, global_LR_SIG_HI) * f;
        }
        sHi = _539;
        float dt = sLo;
        int nt = int(min(ceil((3.0f * sHi) / dt), 16.0f));
        int _572 = -nt;
        for (int k_1 = _572; k_1 <= nt; k_1++)
        {
            float o = float(k_1) * dt;
            float3 b_1 = pow(clamp(tex2Dlod(LIBRA_SAMPLER2D_3, float4(tc + float2(o, 0.0f), 0.0, 0.0f)).xyz, 0.0f.xxx, 1.0f.xxx), (0.5f * global_LR_GAMMA).xxx);
            float3 is = 1.0f.xxx / lerp(sLo.xxx, sHi.xxx, b_1);
            float3 g = (exp((is * (((-0.5f) * o) * o)) * is) * is) * (0.398942291736602783203125f * dt);
            acc += ((b_1 * b_1) * g);
            inv += (((b_1 * b_1) * g) * is);
            dacc += (((((b_1 * b_1) * g) * o) * is) * is);
        }
    }
    if (mm)
    {
        float lsum = (acc.x + acc.y) + acc.z;
        float isum = (inv.x + inv.y) + inv.z;
        float _685;
        if ((isum > 9.999999717180685365747194737196e-10f) && (sHi > sLo))
        {
            _685 = clamp(((lsum / isum) - sLo) / (sHi - sLo), 0.0f, 1.0f);
        }
        else
        {
            _685 = 0.0f;
        }
        spot = _685;
    }
    float conv = clamp(((global_LR_CONV * (0.3499999940395355224609375f + ((0.64999997615814208984375f * cx) * abs(cx)))) * ps_vConvW) / 320.0f, -1.0f, 1.0f);
    float sh = conv * params_OriginalSize.z;
    acc.x -= (dacc.x * sh);
    acc.z += (dacc.z * sh);
    ps_FragColor = float4(sqrt(max(acc, 0.0f.xxx)), spot);
}

ps_SPIRV_Cross_Output ps_main(ps_SPIRV_Cross_Input stage_input)
{
    ps_vTexCoord = stage_input.packed0.xy;
    ps_vScale = stage_input.packed0.z;
    ps_vScan = stage_input.packed0.w;
    ps_vShare = stage_input.packed1.xy;
    ps_vConvW = stage_input.packed1.z;
    ps_frag_main();
    ps_SPIRV_Cross_Output stage_output;
    stage_output.ps_FragColor = float4(ps_FragColor);
    return stage_output;
}

technique t { pass p { VertexShader = compile vs_3_0 vs_main(); PixelShader = compile ps_3_0 ps_main(); } }
