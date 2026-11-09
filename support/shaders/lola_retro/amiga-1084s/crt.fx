// Lola Retro by Zoki (zoran123456), MIT; see LICENSE.
// Pinned upstream 6383ff7357be32c95baf6d31b4a1b1d3cd5c7069
// Isolated Infinite D3D9 prototype; preset amiga-1084s, explicit arcade timing 8.
row_major float4x4 global_MVP;
static const float global_LR_HDR_SRC = 0.0;
static const float global_LR_CONSOLE = 8;
static const float global_LR_NORM = 0;
static const float global_LR_HDR_SIG = 0.0;
static const float global_LR_CABLE = 3;
static const float global_LR_COMB = 0;
static const float global_LR_YTRAP = 0.75;
static const float global_LR_DBLEND = 0.0;
static const float global_LR_SHARP = 0.1;
static const float global_LR_SAT = 1.12;
static const float global_LR_TINT = 0;
static const float global_LR_DEMOD = 0;
static const float global_LR_BRIGHT = 0;
static const float global_LR_CONTRAST = 1.05;
static const float global_LR_NOISE = 0;
static const float global_LR_STEADY = 1;
static const float global_LR_HDR_BEAM = 0.0;
static const float global_LR_SIG_LO = 0.2;
static const float global_LR_SIG_HI = 0.42;
static const float global_LR_HFOCUS = 0.45;
static const float global_LR_GAMMA = 2.4;
static const float global_LR_PERSIST = 0.05;
static const float global_LR_CONV = 0.25;
static const float global_LR_HDR_MASK = 0.0;
static const float global_LR_MASK_TYPE = 2;
static const float global_LR_MASK_STR = 0.5;
static const float global_LR_MASK_TRIADS = 470;
static const float global_LR_WHITE = 6500;
static const float global_LR_PHOS = 3;
static const float global_LR_HDR_GLASS = 0.0;
static const float global_LR_CURV_X = 0;
static const float global_LR_CURV_Y = 0;
static const float global_LR_CORNER = 0;
static const float global_LR_GLOW = 0.06;
static const float global_LR_GLOW_SIZE = 0.5;
static const float global_LR_VIGNETTE = 0.25;
static const float global_LR_OVERSCAN = -0.015;
static const float global_LR_AMBIENT = 0.002;
static const float global_LR_HDR_MON = 0.0;
static const float global_LR_MON_MM = 1;
static const float global_LR_MON_SIZE = 14;
static const float global_LR_MON_PITCH = 0.42;
static const float global_LR_MON_SPOT_LO = 0.28;
static const float global_LR_MON_SPOT_HI = 0.65;
static const float global_LR_MON_CORNER = 1.5;
float4 params_SourceSize;
float4 params_OriginalSize;
float4 params_OutputSize;
uint params_FrameCount;
texture Image2; sampler2D LIBRA_SAMPLER2D_2 : register(s0) = sampler_state { Texture = <Image2>; };
texture Image3; sampler2D LIBRA_SAMPLER2D_3 : register(s1) = sampler_state { Texture = <Image3>; };
texture Image4; sampler2D LIBRA_SAMPLER2D_4 : register(s2) = sampler_state { Texture = <Image4>; };
float4 LIBRA_SAMPLER2D_2_size;
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

static const float vs__940[5] = { 1.0f, 0.726149022579193115234375f, 0.278037011623382568359375f, 0.056134998798370361328125f, 0.005975999869406223297119140625f };





uniform float4 vs_gl_HalfPixel;

static float4 vs_gl_Position;
static float4 vs_Position;
static float2 vs_vTexCoord;
static float2 vs_TexCoord;
static float3 vs_vWhite;
static float4 vs_vTiming;
static float vs_vPhos;
static float vs_vShare;

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
float4 packed2 : TEXCOORD2;
float4 packed3 : TEXCOORD3;
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

// Returns the determinant of a 2x2 matrix.
float vs_spvDet2x2(float a1, float a2, float b1, float b2)
{
    return a1 * b2 - b1 * a2;
}

// Returns the inverse of a matrix, by using the algorithm of calculating the classical
// adjoint and dividing by the determinant. The contents of the matrix are changed.
float3x3 vs_spvInverse(float3x3 m)
{
    float3x3 adj;	// The adjoint matrix (inverse after dividing by determinant)

    // Create the transpose of the cofactors, as the classical adjoint of the matrix.
    adj[0][0] =  vs_spvDet2x2(m[1][1], m[1][2], m[2][1], m[2][2]);
    adj[0][1] = -vs_spvDet2x2(m[0][1], m[0][2], m[2][1], m[2][2]);
    adj[0][2] =  vs_spvDet2x2(m[0][1], m[0][2], m[1][1], m[1][2]);

    adj[1][0] = -vs_spvDet2x2(m[1][0], m[1][2], m[2][0], m[2][2]);
    adj[1][1] =  vs_spvDet2x2(m[0][0], m[0][2], m[2][0], m[2][2]);
    adj[1][2] = -vs_spvDet2x2(m[0][0], m[0][2], m[1][0], m[1][2]);

    adj[2][0] =  vs_spvDet2x2(m[1][0], m[1][1], m[2][0], m[2][1]);
    adj[2][1] = -vs_spvDet2x2(m[0][0], m[0][1], m[2][0], m[2][1]);
    adj[2][2] =  vs_spvDet2x2(m[0][0], m[0][1], m[1][0], m[1][1]);

    // Calculate the determinant as a combination of the cofactors of the first row.
    float det = (adj[0][0] * m[0][0]) + (adj[0][1] * m[1][0]) + (adj[0][2] * m[2][0]);

    // Divide the classical adjoint matrix by the determinant.
    // If determinant is zero, matrix is not invertable, so leave it unchanged.
    return (det != 0.0f) ? (adj * (1.0f / det)) : m;
}

float3 vs_kelvinRGB(float T)
{
    float t = T / 100.0f;
    float _775;
    if (t <= 66.0f)
    {
        _775 = 255.0f;
    }
    else
    {
        _775 = 329.69873046875f * pow(t - 60.0f, -0.133204758167266845703125f);
    }
    float r = _775;
    float _791;
    if (t <= 66.0f)
    {
        _791 = (99.47080230712890625f * log(t)) - 161.11956787109375f;
    }
    else
    {
        _791 = 288.122161865234375f * pow(t - 60.0f, -0.075514845550060272216796875f);
    }
    float g = _791;
    float _811;
    if (t >= 66.0f)
    {
        _811 = 255.0f;
    }
    else
    {
        float _818;
        if (t <= 19.0f)
        {
            _818 = 0.0f;
        }
        else
        {
            _818 = (138.517730712890625f * log(t - 10.0f)) - 305.0447998046875f;
        }
        _811 = _818;
    }
    float b = _811;
    return clamp(float3(r, g, b), 1.0f.xxx, 255.0f.xxx) / 255.0f.xxx;
}

float vs_upscaleOf(float2 orig)
{
    float id = global_LR_CONSOLE;
    bool _305 = id < 5.5f;
    bool _314;
    if (!_305)
    {
        _314 = (id > 7.5f) && (id < 8.5f);
    }
    else
    {
        _314 = _305;
    }
    bool tv = _314;
    float base = ((id > 4.5f) && (id < 5.5f)) ? 480.0f : 240.0f;
    bool _327;
    if (id < 0.5f)
    {
        _327 = orig.y > 576.0f;
    }
    else
    {
        bool _343;
        if (tv)
        {
            _343 = orig.y > (base * 1.5f);
        }
        else
        {
            _343 = tv;
        }
        _327 = _343;
    }
    bool scaled = _327;
    if (!scaled)
    {
        return 1.0f;
    }
    for (float k = 2.0f; k <= 16.0f; k += 1.0f)
    {
        float lines = orig.y / k;
        bool _366 = lines == floor(lines);
        bool _374;
        if (_366)
        {
            _374 = lines >= (base * 0.829999983310699462890625f);
        }
        else
        {
            _374 = _366;
        }
        bool _382;
        if (_374)
        {
            _382 = lines <= (base * 1.21000003814697265625f);
        }
        else
        {
            _382 = _374;
        }
        if (_382)
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
    bool _77 = !mon15;
    bool _104;
    if (_77)
    {
        bool _86 = (w == 320.0f) && (h == 200.0f);
        bool _103;
        if (!_86)
        {
            bool _92 = w == 640.0f;
            bool _102;
            if (_92)
            {
                _102 = (h == 350.0f) || (h == 400.0f);
            }
            else
            {
                _102 = _92;
            }
            _103 = _102;
        }
        else
        {
            _103 = _86;
        }
        _104 = _103;
    }
    else
    {
        _104 = _77;
    }
    if (_104)
    {
        return 7.0f;
    }
    bool _115 = (h == 256.0f) || (h == 512.0f);
    bool _124;
    if (!_115)
    {
        _124 = (w == 640.0f) && (h == 200.0f);
    }
    else
    {
        _124 = _115;
    }
    if (_124)
    {
        return 6.0f;
    }
    bool _137;
    if (mon15)
    {
        _137 = (h == 200.0f) || (h == 400.0f);
    }
    else
    {
        _137 = mon15;
    }
    bool _145;
    if (_137)
    {
        _145 = (w == 320.0f) || (w == 640.0f);
    }
    else
    {
        _145 = _137;
    }
    if (_145)
    {
        return 6.0f;
    }
    bool _159 = ((w == 360.0f) || (w == 720.0f)) || (w == 1440.0f);
    bool _177;
    if (_159)
    {
        _177 = (((h == 287.0f) || (h == 574.0f)) || (h == 242.0f)) || (h == 484.0f);
    }
    else
    {
        _177 = _159;
    }
    if (_177)
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
    float _414;
    if (global_LR_CONSOLE < 0.5f)
    {
        float2 param_1 = nat;
        _414 = vs_autoConsole(param_1);
    }
    else
    {
        _414 = global_LR_CONSOLE;
    }
    float id = _414;
    float param_2 = id;
    float4 param_3;
    float4 param_4;
    float param_5;
    vs_consoleTable(param_2, param_3, param_4, param_5);
    float4 a = param_3;
    float4 b = param_4;
    float c = param_5;
    t.id = id;
    bool _443 = (id > 4.5f) && (id < 5.5f);
    bool _450;
    if (_443)
    {
        _450 = nat.x > 700.0f;
    }
    else
    {
        _450 = _443;
    }
    if (_450)
    {
        a.z = 720.0f;
    }
    t.scan = a.w;
    bool _463 = t.scan < 0.5f;
    bool _469;
    if (_463)
    {
        _469 = nat.y > 300.0f;
    }
    else
    {
        _469 = _463;
    }
    t.interlace = float(_469);
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
            float _498;
            if (t.interlace > 0.5f)
            {
                _498 = nat.y * 0.5f;
            }
            else
            {
                _498 = nat.y;
            }
            float lines = _498;
            bool _510 = t.scan < 0.5f;
            bool _519;
            if (_510)
            {
                _519 = lines > (amiga ? 249.5f : 240.5f);
            }
            else
            {
                _519 = _510;
            }
            t.pal = float(_519);
        }
    }
    float base = lerp(a.x, a.y, t.pal);
    t.pclk = (base * orig.x) / a.z;
    float _543;
    if (orig.x < 480.0f)
    {
        _543 = 1.0f;
    }
    else
    {
        _543 = (orig.x < 960.0f) ? 2.0f : 4.0f;
    }
    float cls = _543;
    if (amiga)
    {
        t.pclk = (base * (320.0f * cls)) / a.z;
    }
    bool _566 = t.scan > 0.5f;
    bool _572;
    if (_566)
    {
        _572 = t.scan < 1.5f;
    }
    else
    {
        _572 = _566;
    }
    bool _578;
    if (_572)
    {
        _578 = orig.x > 720.0f;
    }
    else
    {
        _578 = _572;
    }
    if (_578)
    {
        t.pclk = ((78.75f * orig.x) * orig.y) / 786432.0f;
    }
    float _593;
    if (amiga)
    {
        _593 = cls;
    }
    else
    {
        _593 = orig.x / a.z;
    }
    t.hres = _593;
    t.fsc = (t.pal > 0.5f) ? 4.433619022369384765625f : 3.57954502105712890625f;
    t.lineFrac = lerp(b.x, b.y, t.pal);
    t.fieldStep = lerp(b.z, b.w, t.pal);
    float _634;
    if (global_LR_STEADY > 0.5f)
    {
        _634 = 0.0f;
    }
    else
    {
        _634 = float(frameCount % 24u);
    }
    float fc = _634;
    t.framePhase = frac(fc * t.fieldStep);
    t.vsw = vs_mod(fc * c, 2.0f);
    return t;
}

float vs_phosphorSet(vs_Timing t)
{
    if (global_LR_PHOS > 0.5f)
    {
        return global_LR_PHOS;
    }
    bool _698 = t.scan > 0.5f;
    bool _704;
    if (_698)
    {
        _704 = t.scan < 1.5f;
    }
    else
    {
        _704 = _698;
    }
    if (_704)
    {
        return 1.0f;
    }
    if (t.id > 7.5f)
    {
        return 4.0f;
    }
    return (t.pal > 0.5f) ? 3.0f : 2.0f;
}

float vs_activeShare(vs_Timing t, float2 orig)
{
    bool _661 = t.scan < 0.5f;
    bool _667;
    if (_661)
    {
        _667 = global_LR_MON_MM > 0.5f;
    }
    else
    {
        _667 = _661;
    }
    if (!_667)
    {
        return 1.0f;
    }
    return min((orig.x / t.pclk) / ((t.pal > 0.5f) ? 52.0f : 52.59999847412109375f), 1.0f);
}

float3x3 vs_phosphorMatrix(float p)
{
    if (p < 2.5f)
    {
        return float3x3(float3(0.939541995525360107421875f, 0.0177720002830028533935546875f, -0.00162200001068413257598876953125f), float3(0.0501810014247894287109375f, 0.96579301357269287109375f, -0.0043700002133846282958984375f), float3(0.010277000255882740020751953125f, 0.01643499918282032012939453125f, 1.0059909820556640625f));
    }
    if (p < 3.5f)
    {
        return float3x3(float3(1.04404294490814208984375f, 0.0f, 0.0f), float3(-0.0440430007874965667724609375f, 1.0f, 0.011792999692261219024658203125f), float3(0.0f, 0.0f, 0.98820698261260986328125f));
    }
    return float3x3(float3(1.08194196224212646484375f, 0.0380319990217685699462890625f, -0.0074809999205172061920166015625f), float3(-0.088426999747753143310546875f, 0.959990978240966796875f, 0.015169999562203884124755859375f), float3(0.0064849997870624065399169921875f, 0.0019769999198615550994873046875f, 0.992311000823974609375f));
}

void vs_vert_main()
{
    vs_gl_Position = mul(vs_Position, global_MVP);
    vs_vTexCoord = vs_TexCoord;
    float param = global_LR_WHITE;
    float param_1 = 6500.0f;
    float3 c = pow(vs_kelvinRGB(param) / vs_kelvinRGB(param_1), 2.2000000476837158203125f.xxx);
    vs_vWhite = c / dot(c, float3(0.2125999927520751953125f, 0.715200006961822509765625f, 0.072200000286102294921875f)).xxx;
    float2 param_2 = params_OriginalSize.xy;
    uint param_3 = params_FrameCount;
    vs_Timing T = vs_getTiming(param_2, param_3);
    vs_vTiming = float4(T.scan, T.pal, T.interlace, T.scale);
    vs_Timing param_4 = T;
    vs_vPhos = vs_phosphorSet(param_4);
    vs_Timing param_5 = T;
    float2 param_6 = params_OriginalSize.xy;
    vs_vShare = vs_activeShare(param_5, param_6);
    if (vs_vPhos > 1.5f)
    {
        float param_7 = vs_vPhos;
        vs_vWhite = mul(vs_vWhite, vs_spvInverse(vs_phosphorMatrix(param_7)));
    }
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
    stage_output.packed1.xyz = vs_vWhite;
    stage_output.packed2.xyzw = vs_vTiming;
    stage_output.packed3.x = vs_vPhos;
    stage_output.packed3.y = vs_vShare;
    return stage_output;
}

float4 ps_sample_lod0(sampler2D s, float2 uv) { return tex2Dlod(s, float4(uv,0,0)); }
static const float ps__1131[5] = { 1.0f, 0.726149022579193115234375f, 0.278037011623382568359375f, 0.056134998798370361328125f, 0.005975999869406223297119140625f };









static float4 ps_vTiming;
static float2 ps_vTexCoord;
static float ps_vShare;
static float3 ps_vWhite;
static float ps_vPhos;
static float4 ps_FragColor;

struct ps_SPIRV_Cross_Input
{
float4 packed0 : TEXCOORD0;
float4 packed1 : TEXCOORD1;
float4 packed2 : TEXCOORD2;
float4 packed3 : TEXCOORD3;
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



bool ps_isPC(float scan)
{
    return (scan > 0.5f) && (scan < 1.5f);
}

bool ps_inMM(float scan)
{
    float param = scan;
    bool _79 = ps_isPC(param);
    bool _98;
    if (!_79)
    {
        bool _84 = scan < 0.5f;
        bool _97;
        if (_84)
        {
            _97 = global_LR_MON_MM > 0.5f;
        }
        else
        {
            _97 = _84;
        }
        _98 = _97;
    }
    else
    {
        _98 = _79;
    }
    return _98;
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

float4 ps_beamAt(float i, float x, float lines)
{
    if ((i < 0.0f) || (i >= lines))
    {
        return 0.0f.xxxx;
    }
    uint _207_dummy_parameter;
    float2 bs = float2(int2(float2(LIBRA_SAMPLER2D_2_size.xy)));
    return tex2Dlod(LIBRA_SAMPLER2D_2, float4(float2(x + (0.5f / bs.x), (i + 0.5f) / bs.y), 0.0, 0.0f));
}

float ps_lenticular(float x)
{
    float f = frac(x);
    return smoothstep(0.0f, 0.180000007152557373046875f, f) * smoothstep(1.0f, 0.819999992847442626953125f, f);
}

float3 ps_shadowDots(float2 mp)
{
    float s = mp.x * 3.0f;
    float ci = floor(s);
    float fx = frac(s);
    float fy = frac((mp.y * 1.73199999332427978515625f) + (ps_mod(ci, 2.0f) * 0.5f));
    float dt = smoothstep(0.519999980926513671875f, 0.300000011920928955078125f, length(float2(fx - 0.5f, fy - 0.5f)));
    float chn = ps_mod(ci, 3.0f);
    return float3((chn < 0.5f) ? dt : 0.0f, ((chn > 0.5f) && (chn < 1.5f)) ? dt : 0.0f, (chn > 1.5f) ? dt : 0.0f);
}

float3 ps_stripes(float x)
{
    float s = x * 3.0f;
    float3 m;
    for (int ch = 0; ch < 3; ch++)
    {
        float d = abs(frac(((s - (float(ch) + 0.5f)) / 3.0f) + 0.5f) - 0.5f) * 3.0f;
        m[ch] = smoothstep(0.75f, 0.3499999940395355224609375f, d);
    }
    return m;
}

float ps_slotGate(float x, float y)
{
    float yy = frac((y * 0.5f) + (ps_mod(floor(x), 2.0f) * 0.5f));
    return smoothstep(0.0f, 0.119999997317790985107421875f, yy) * smoothstep(1.0f, 0.87999999523162841796875f, yy);
}

float3 ps_maskAvg(float2 a, float2 b, float mt)
{
    if (mt > 3.5f)
    {
        float param = a.x;
        float param_1 = b.x;
        return (0.5f * (ps_lenticular(param) + ps_lenticular(param_1))).xxx;
    }
    if (mt > 2.5f)
    {
        float2 param_2 = a;
        float2 param_3 = float2(b.x, a.y);
        float2 param_4 = float2(a.x, b.y);
        float2 param_5 = b;
        return (((ps_shadowDots(param_2) + ps_shadowDots(param_3)) + ps_shadowDots(param_4)) + ps_shadowDots(param_5)) * 0.25f;
    }
    float param_6 = a.x;
    float3 ma = ps_stripes(param_6);
    float param_7 = b.x;
    float3 mb = ps_stripes(param_7);
    if (mt > 1.5f)
    {
        float param_8 = a.x;
        float param_9 = a.y;
        float param_10 = a.x;
        float param_11 = b.y;
        float param_12 = b.x;
        float param_13 = a.y;
        float param_14 = b.x;
        float param_15 = b.y;
        return ((ma * (ps_slotGate(param_8, param_9) + ps_slotGate(param_10, param_11))) + (mb * (ps_slotGate(param_12, param_13) + ps_slotGate(param_14, param_15)))) * 0.25f;
    }
    return (ma + mb) * 0.5f;
}

float3x3 ps_phosphorMatrix(float p)
{
    if (p < 2.5f)
    {
        return float3x3(float3(0.939541995525360107421875f, 0.0177720002830028533935546875f, -0.00162200001068413257598876953125f), float3(0.0501810014247894287109375f, 0.96579301357269287109375f, -0.0043700002133846282958984375f), float3(0.010277000255882740020751953125f, 0.01643499918282032012939453125f, 1.0059909820556640625f));
    }
    if (p < 3.5f)
    {
        return float3x3(float3(1.04404294490814208984375f, 0.0f, 0.0f), float3(-0.0440430007874965667724609375f, 1.0f, 0.011792999692261219024658203125f), float3(0.0f, 0.0f, 0.98820698261260986328125f));
    }
    return float3x3(float3(1.08194196224212646484375f, 0.0380319990217685699462890625f, -0.0074809999205172061920166015625f), float3(-0.088426999747753143310546875f, 0.959990978240966796875f, 0.015169999562203884124755859375f), float3(0.0064849997870624065399169921875f, 0.0019769999198615550994873046875f, 0.992311000823974609375f));
}

float3 ps_shoulder(float3 x)
{
    float3 e = max(x - 0.800000011920928955078125f.xxx, 0.0f.xxx);
    return min(x, 0.800000011920928955078125f.xxx) + ((1.0f.xxx - exp((-e) / 0.20000000298023223876953125f.xxx)) * 0.20000000298023223876953125f);
}

void ps_frag_main()
{
    float scan = ps_vTiming.x;
    float pal = ps_vTiming.y;
    float interlace = ps_vTiming.z;
    float2 tc = ps_vTexCoord;
    float2 tubePx = params_OutputSize.xy;
    float px = 2.0f * params_OutputSize.z;
    float2 c = (tc * 2.0f) - 1.0f.xx;
    c *= (1.0f.xx + (float2(global_LR_CURV_X, global_LR_CURV_Y) * (c.yx * c.yx)));
    float corner = global_LR_CORNER;
    float2 qq = (abs(c) - 1.0f.xx) + corner.xx;
    float dist = (length(max(qq, 0.0f.xx)) + min(max(qq.x, qq.y), 0.0f)) - corner;
    float inside = 1.0f - smoothstep(-px, px, dist);
    float3 col = 0.0f.xxx;
    if (inside > 0.0f)
    {
        float2 ut = (c * 0.5f) + 0.5f.xx;
        float2 ua = ((ut - 0.5f.xx) * (1.0f - global_LR_OVERSCAN)) + 0.5f.xx;
        float srcH = params_OriginalSize.y / ps_vTiming.w;
        float rpl = 1.0f;
        float ph = 0.0f;
        bool vga = (scan > 0.5f) && (scan < 1.5f);
        float param = scan;
        bool mm = ps_inMM(param);
        float xs = ((ua.x - 0.5f) / ps_vShare) + 0.5f;
        float dbl = (vga && (srcH <= 300.0f)) ? 2.0f : 1.0f;
        float BH = srcH * dbl;
        float _621;
        if (scan > 0.5f)
        {
            _621 = BH;
        }
        else
        {
            _621 = ((pal > 0.5f) ? 288.0f : 240.0f) * ((interlace > 0.5f) ? 2.0f : 1.0f);
        }
        float visLines = _621;
        bool _638 = interlace > 0.5f;
        bool _645;
        if (_638)
        {
            _645 = global_LR_STEADY < 0.5f;
        }
        else
        {
            _645 = _638;
        }
        bool il = _645;
        float stepL = il ? 2.0f : 1.0f;
        float _651;
        if (il)
        {
            _651 = float(params_FrameCount % 2u);
        }
        else
        {
            _651 = 0.0f;
        }
        float offL = _651;
        bool _663 = interlace > 0.5f;
        bool _669;
        if (_663)
        {
            _669 = global_LR_STEADY > 0.5f;
        }
        else
        {
            _669 = _663;
        }
        float sgk = _669 ? 2.0f : 1.0f;
        float Lf = (ua.y * visLines) - ((visLines - BH) * 0.5f);
        float u = ((Lf - offL) - 0.5f) / stepL;
        float j0 = floor(u);
        float convV = (global_LR_CONV * 0.5f) * (0.300000011920928955078125f + ((0.699999988079071044921875f * c.y) * abs(c.y)));
        float2 sig = float2(global_LR_SIG_LO, max(global_LR_SIG_LO, global_LR_SIG_HI)) * sgk;
        if (mm)
        {
            float2 param_1 = c;
            sig = float2(global_LR_MON_SPOT_LO, max(global_LR_MON_SPOT_LO, global_LR_MON_SPOT_HI)) * (((0.4246608912944793701171875f * ps_monCornerGrowth(param_1)) * visLines) / ps_monScanMM().y);
        }
        int kn = int(clamp(ceil((3.5f * sig.y) - 1.0f), 1.0f, 6.0f));
        int _754 = -kn;
        float3 _810;
        for (int k = _754; k <= (kn + 1); k++)
        {
            float j = j0 + float(k);
            float i = (j * stepL) + offL;
            float param_2 = (floor(i / dbl) * rpl) + ph;
            float param_3 = xs;
            float param_4 = (srcH * rpl) + ph;
            float4 bb = ps_beamAt(param_2, param_3, param_4);
            float3 b = bb.xyz;
            float3 lc = b * b;
            if (mm)
            {
                _810 = bb.w.xxx;
            }
            else
            {
                _810 = b;
            }
            float3 isg = 1.0f.xxx / lerp(sig.x.xxx, sig.y.xxx, _810);
            float3 d = (u - j).xxx + float3(convV, 0.0f, -convV);
            col += (((lc * exp((((d * (-0.5f)) * d) * isg) * isg)) * isg) * 0.398942291736602783203125f);
        }
        col *= (smoothstep(-0.00200000009499490261077880859375f, 0.00200000009499490261077880859375f, xs) * smoothstep(1.00199997425079345703125f, 0.99800002574920654296875f, xs));
        float mt = global_LR_MASK_TYPE;
        float triads = global_LR_MASK_TRIADS;
        if (mm)
        {
            triads = ps_monTubeMM().y / (global_LR_MON_PITCH * (((mt > 2.5f) && (mt < 3.5f)) ? 0.865999996662139892578125f : 1.0f));
        }
        float pitchPx = tubePx.y / triads;
        float str = global_LR_MASK_STR * smoothstep(1.60000002384185791015625f, 2.599999904632568359375f, pitchPx);
        if ((mt > 0.5f) && (str > 0.0f))
        {
            float2 mp = (ut * tubePx) / pitchPx.xx;
            float dp = 0.25f / pitchPx;
            float2 param_5 = mp - dp.xx;
            float2 param_6 = mp + dp.xx;
            float param_7 = mt;
            float3 m = ps_maskAvg(param_5, param_6, param_7);
            float _936;
            if (mt < 1.5f)
            {
                _936 = 0.3670000135898590087890625f;
            }
            else
            {
                float _943;
                if (mt < 2.5f)
                {
                    _943 = 0.310000002384185791015625f;
                }
                else
                {
                    _943 = (mt < 3.5f) ? 0.189999997615814208984375f : 0.839999973773956298828125f;
                }
                _936 = _943;
            }
            float avg = _936;
            col *= (lerp((1.0f - str).xxx, 1.0f.xxx, m) / lerp(1.0f - str, 1.0f, avg).xxx);
        }
        if ((mt > 0.5f) && (mt < 1.5f))
        {
            float hp = tubePx.y;
            float sw = max(0.449999988079071044921875f, hp / 4000.0f);
            float d1 = (ut.y - 0.3333333432674407958984375f) * hp;
            float d2 = (ut.y - 0.666666686534881591796875f) * hp;
            col *= (1.0f - (0.20000000298023223876953125f * (exp((((-0.5f) * d1) * d1) / (sw * sw)) + exp((((-0.5f) * d2) * d2) / (sw * sw)))));
        }
        col *= ps_vWhite;
        float gy = Lf / BH;
        float gin = ((smoothstep(-0.02999999932944774627685546875f, 0.02999999932944774627685546875f, gy) * smoothstep(1.0299999713897705078125f, 0.9700000286102294921875f, gy)) * smoothstep(-0.02999999932944774627685546875f, 0.02999999932944774627685546875f, xs)) * smoothstep(1.0299999713897705078125f, 0.9700000286102294921875f, xs);
        col = lerp(col, tex2Dlod(LIBRA_SAMPLER2D_3, float4(float2(xs, gy), 0.0, 0.0f)).xyz * ps_vWhite, (global_LR_GLOW * gin).xxx);
        if (ps_vPhos > 1.5f)
        {
            float param_8 = ps_vPhos;
            col = mul(col, ps_phosphorMatrix(param_8));
        }
        float3 param_9 = col;
        col = ps_shoulder(param_9);
        float r2 = clamp(dot(c, c) * 0.5f, 0.0f, 1.0f);
        col *= (1.0f - (global_LR_VIGNETTE * pow(r2, 1.60000002384185791015625f)));
        col += (float3(0.800000011920928955078125f, 0.920000016689300537109375f, 0.87000000476837158203125f) * global_LR_AMBIENT);
        col *= inside;
    }
    float3 prev = tex2Dlod(LIBRA_SAMPLER2D_4, float4(ps_vTexCoord, 0.0, 0.0f)).xyz;
    col = max(col, prev * global_LR_PERSIST);
    ps_FragColor = float4(col, 1.0f);
}

ps_SPIRV_Cross_Output ps_main(ps_SPIRV_Cross_Input stage_input)
{
    ps_vTiming = stage_input.packed2.xyzw;
    ps_vTexCoord = stage_input.packed0.xy;
    ps_vShare = stage_input.packed3.y;
    ps_vWhite = stage_input.packed1.xyz;
    ps_vPhos = stage_input.packed3.x;
    ps_frag_main();
    ps_SPIRV_Cross_Output stage_output;
    stage_output.ps_FragColor = float4(ps_FragColor);
    return stage_output;
}

technique t { pass p { VertexShader = compile vs_3_0 vs_main(); PixelShader = compile ps_3_0 ps_main(); } }
