Shader "Custom/Water"
{
    Properties
    {
        // Graphic Attributes
        [MainColor] _BaseColor("Base Color", Color) = (1, 1, 1, 1)
        [MainColor] _Ambient("Ambient", Color) = (1, 1, 1, 1)
        [MainColor] _Diffuse("Diffuse", Color) = (1, 1, 1, 1)
        [MainColor] _Specular("Specular", Color) = (1, 1, 1, 1)
        
        // FFT Attributes
        [MainTexture] _RealMap("Real Map", 2D) = "white"
        [MainTexture] _ImaginaryMap("Imaginary Map", 2D) = "white"
        _LocalAccel("Local Acceleration", Float) = 9.8
        _PI("Pi", float) = 3.14159265
        _Lx("Lx", float) = 0
        _Lz("Lz", float) = 0
        _N("N", float) = 0
        _M("M", float) = 0
        
        // Modifying Attributes
        _YScale("Y Scale", float) = 100
        
        // First 2 are wind directions w_hat, 3rd is wind speed V and 4th is numeric constant A
        _WindInformation("Wind Information", vector) = (1, 1, 1, 1)
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
            };
            
            TEXTURE2D(_RealMap);
            TEXTURE2D(_ImaginaryMap);
            SAMPLER(sampler_RealMap);
            SAMPLER(sampler_ImaginaryMap);
            
            CBUFFER_START(UnityPerMaterial)
                float _LocalAccel;
                half4 _BaseColor;
                float4 _BaseMap_ST;
                float _PI;
                float _Lx;
                float _Lz;
                float _N;
                float _M;
                vector _WindInformation;
                float _YScale;
            CBUFFER_END

            float2 complex_add(float2 c1, float2 c2)
            {
                return c1 + c2;
            }

            float2 complex_sub(float2 c1, float2 c2)
            {
                return complex_add(c1, -c2);
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
            
            float omega(int n_prime, int m_prime) 
            {
                float k_x = calculate_k(n_prime, _N, _Lx);
                float k_z = calculate_k(m_prime, _M, _Lz);
                float k_x_sq = k_x * k_x;
                float k_z_sq = k_z * k_z;
                return sqrt(_LocalAccel * sqrt(k_x_sq + k_z_sq));
            }

            float phillips(int n_prime, int m_prime)
            {
                float2 w_hat = normalize(_WindInformation.xy);
                float2 k_hat = float2(calculate_k(n_prime, _N, _Lx), calculate_k(m_prime, _M, _Lz));
                float V = _WindInformation.z;
                float A = _WindInformation.w;
                float L = (V * V) / _LocalAccel;
                float numerator = exp(-1 / pow((length(k_hat) * L), 2));
                float cos_factor = pow(dot(k_hat, w_hat), 2);
                return A * (numerator / pow(length(k_hat), 4)) * cos_factor;
            }
            
            float2 basis_dft(int n_prime, int m_prime, float2 uv)
            {
                float real_sample = SAMPLE_TEXTURE2D_LOD(_RealMap, sampler_RealMap, uv, 0);
                float imaginary_sample = SAMPLE_TEXTURE2D_LOD(_ImaginaryMap, sampler_ImaginaryMap, uv, 0);
                return (1 / sqrt(2)) * float2(real_sample, imaginary_sample) * sqrt(phillips(n_prime, m_prime));
            }

            float2 dft(int n_prime, int m_prime, float2 uv)
            {
                float2 basis = basis_dft(n_prime, m_prime, uv);
                float2 basis_conjugate = complex_conjugate(basis_dft(-n_prime, -m_prime, uv));
                float2 exp1 = complex_exp(omega(n_prime, m_prime) * _Time);
                float2 exp2 = complex_conjugate(exp1);
                return basis * exp1 + basis_conjugate * exp2;
            }

            Varyings vert(Attributes IN)
            {
                Varyings OUT;
                float y_offset = 0;
                for (int n_prime = 0; n_prime < _N; n_prime++)
                {
                   for (int m_prime = 0; m_prime < _M; m_prime++)
                   {
                       float2 h_tilde_prime = dft(n_prime, m_prime, IN.uv);
                       float2 c1 = float2(IN.positionOS.x * calculate_k(n_prime, _N, _Lx), 0);
                       float2 c2 = float2(IN.positionOS.x * calculate_k(m_prime, _M, _Lz), 0);
                       float2 exp = complex_exp(complex_add(c1, c2));
                       y_offset += h_tilde_prime * exp;
                   }
                }
                OUT.positionHCS = TransformObjectToHClip(IN.positionOS.xyz + float3(0, y_offset, 0));
                OUT.uv = TRANSFORM_TEX(IN.uv, _BaseMap);
                return OUT;
            }

            half4 frag(Varyings IN) : SV_Target
            {
                half4 color = SAMPLE_TEXTURE2D(_RealMap, sampler_RealMap, IN.uv) * _BaseColor;
                return color;
            }
            ENDHLSL
        }
    }
}
