Shader "Custom/Water"
{
    Properties
    {
        // Graphic Attributes
        [MainColor] _BaseColor("Base Color", Color) = (1, 1, 1, 1)
        [MainColor] _Ambient("Ambient", Color) = (1, 1, 1, 1)
        [MainColor] _Diffuse("Diffuse", Color) = (1, 1, 1, 1)
        [MainColor] _Specular("Specular", Color) = (1, 1, 1, 1)
        _LightDirection("Light Direction", Vector) = (0, -1, 0)
        _LightPosition("Light Position", Vector) = (0, 50, 0)
        _UseCompute("Use Compute?", int) = 0
        
        // FFT Attributes
        [MainTexture] _RealMap("Real Map", 2D) = "white"
        [MainTexture] _ImaginaryMap("Imaginary Map", 2D) = "white"
        _FtResult("FT Result", 2D) = "white"
        _LocalAccel("Local Acceleration", Float) = 9.8
        _PI("Pi", float) = 3.14159265
        _Lx("Lx", float) = 0
        _Lz("Lz", float) = 0
        _N("N", int) = 0
        _M("M", int) = 0
        _l("l", float) = 0
        _TimeRepeat("Time Repeat", float) = 100.0
        _PhaseMult("Phase Multiplier", float) = 100.0
        
        // Modifying Attributes
        _YScale("Y Scale", float) = 1.0
        
        // First 2 are wind directions w_hat, 3rd is wind speed V and 4th is numeric constant A
        _WindInformation("Wind Information", vector) = (1, 0, 30, 0.0005)
    }

    SubShader
    {
        Tags { "RenderType" = "Opaque" "RenderPipeline" = "UniversalPipeline" }

        Pass
        {
            HLSLPROGRAM

            #pragma vertex vert
            #pragma fragment frag

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

            struct Attributes
            {
                float4 positionOS : POSITION;
                float2 uv : TEXCOORD0;
            };

            struct Varyings
            {
                float4 positionHCS : SV_POSITION;
                float2 uv : TEXCOORD0;
                float3 normal : NORMAL;
                float height : TEXCOORD1;
            };

            struct DFT_Result
            {
                float2 h;
                float2 D;
                float2 n;
            };
            
            TEXTURE2D(_RealMap);
            TEXTURE2D(_ImaginaryMap);
            TEXTURE2D(_FtResult);
            SAMPLER(sampler_RealMap);
            SAMPLER(sampler_ImaginaryMap);
            SAMPLER(sampler_FtResult);
            
            CBUFFER_START(UnityPerMaterial)
                int _UseCompute;
                float _LocalAccel;
                half4 _BaseColor;
                float4 _BaseMap_ST;
                float _PI;
                float _Lx;
                float _Lz;
                int _N;
                int _M;
                vector _WindInformation;
                float _YScale;
                vector _LightDirection;
                float _l;
                float _TimeRepeat;
                float _PhaseMult;
            CBUFFER_END

            float2 complex_add(float2 c1, float2 c2)
            {
                return c1 + c2;
            }

            float2 complex_conjugate(float2 c)
            {
                return float2(c.x, -c.y);
            }

            float2 complex_mult(float2 c1, float2 c2)
            {
                return float2(c1.x * c2.x - c1.y * c2.y, c1.x * c2.y + c1.y * c2.x);
            }

            float2 complex_exp(float theta)
            {
                return float2(cos(theta), sin(theta));
            }
            
            float calculate_k(int coord, int size, float length)
            {
                return (2 * _PI * coord - _PI * size) / length;
            }

            float2 get_uv(int n, int m)
            {
                return float2(n, m) / float2(_N, _M);
            }

            Varyings vert(Attributes IN)
            {
                Varyings OUT;
                float y_offset = 0;
                float2 gradient = float2(0.0f, 0.0f);
                for (int n_prime = 0; n_prime < _N; n_prime++)
                {
                   for (int m_prime = 0; m_prime < _M; m_prime++)
                   {
                       float2 h_tilde_prime = SAMPLE_TEXTURE2D_LOD(_FtResult, sampler_FtResult, get_uv(n_prime, m_prime), 0).rg;
                       float2 k = float2(calculate_k(n_prime, _N, _Lx), calculate_k(m_prime, _M, _Lz));
                       float c1 = IN.positionOS.x * k.x;
                       float c2 = IN.positionOS.z * k.y;
                       float2 exp = complex_exp(c1 + c2);
                       float2 result = complex_mult(h_tilde_prime, exp);
                       y_offset += result.x;
                       gradient += k * result;
                   }
                }
                gradient = float2(gradient.y, -gradient.x);
                OUT.positionHCS = TransformObjectToHClip(IN.positionOS.xyz + float3(0, y_offset * _YScale, 0));
                OUT.uv = TRANSFORM_TEX(IN.uv, _BaseMap);
                OUT.normal = float3(-gradient.x, 1, -gradient.y);
                OUT.height = y_offset;
                return OUT;
            }

            half4 frag(Varyings IN) : SV_Target
            {
                half4 color = IN.height * _BaseColor;
                return color;
            }
            ENDHLSL
        }
    }
}
