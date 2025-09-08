Shader "Custom/Water"
{
    Properties
    {
        // Graphic Attributes
        [MainColor] _BaseColor("Base Color", Color) = (1, 1, 1, 1)
        [MainColor] _Ambient("Ambient", Color) = (1, 1, 1)
        [MainColor] _Diffuse("Diffuse", Color) = (1, 1, 1)
        [MainColor] _Specular("Specular", Color) = (1, 1, 1)
        _LightPosition("Light Position", Vector) = (0, 50, 0)
        _LightIntensity("Light Intensity", float) = 1.0
        _LightColor("Light Color", Color) = (1, 1, 1)
        _SpecularShininess("Specular Shininess", float) = 1.0
        _UseCompute("Use Compute?", int) = 0
        _CameraPosition("CameraPosition", Vector) = (0, 0, 0)
        
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
                float height : TEXCOORD1;
                float3 N : TEXCOORD2;
                float3 V : TEXCOORD3;
                float3 L : TEXCOORD4;
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
                float _l;
                float _TimeRepeat;
                float _PhaseMult;
            
                float3 _Ambient;
                float3 _Diffuse;
                float3 _Specular;
                float3 _LightPosition;
                float _LightIntensity;
                float3 _LightColor;
                float _SpecularShininess;
                float3 _CameraPosition;
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
                float2 displacement = 0;
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
                       // displacement += (k / length(k)) * result.x;
                       y_offset += result.x;
                       gradient += k * result;
                   }
                }
                displacement = float2(-displacement.y, displacement.x) / 1000;
                gradient = float2(gradient.y, -gradient.x);
                OUT.positionHCS = TransformObjectToHClip(IN.positionOS.xyz + float3(displacement.x, y_offset * _YScale, displacement.y));
                OUT.uv = TRANSFORM_TEX(IN.uv, _BaseMap);
                OUT.N = float3(-gradient.x, 1, -gradient.y);
                OUT.L = _LightPosition - IN.positionOS.xyz;
                OUT.V = _CameraPosition - IN.positionOS.xyz;
                OUT.height = y_offset;
                return OUT;
            }

            half4 frag(Varyings IN) : SV_Target
            {
                half4 color = half4(IN.height * _Ambient, 1.0);
                return color;
                float distance_to_light = length(IN.L);
                IN.N = normalize(IN.N);
                IN.V = normalize(IN.V);
                IN.L = normalize(IN.L);

                float lambert = max(dot(IN.L, IN.N), 0.0);
                float3 H = normalize(IN.L + IN.V);
                float3 light_contribution = _LightColor * _LightIntensity / (distance_to_light * distance_to_light);
                float specular = pow(max(dot(H, IN.N), 0.0), _SpecularShininess);
                
                // float3 color = _Ambient + _Diffuse * lambert * light_contribution + _Specular * specular * light_contribution;
                // return float4(color, 1.0);
            }
            ENDHLSL
        }
    }
}
