Shader "Custom/Water"
{
    Properties
    {
        _BaseMap("Base Map", 2D) = "black" {}
        // Graphic Attributes
        _Ambient("Ambient", Color) = (1, 1, 1, 1)
        _Diffuse("Diffuse", Color) = (1, 1, 1, 1)
        _Specular("Specular", Color) = (1, 1, 1, 1)
        _LightPosition("Light Position", Vector) = (0, 50, 0, 0)
        _LightIntensity("Light Intensity", Float) = 1.0
        _LightColor("Light Color", Color) = (1, 1, 1, 1)
        _SpecularShininess("Specular Shininess", Float) = 1.0
        _CameraPosition("Camera Position", Vector) = (0, 0, 0, 0)
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

            TEXTURE2D(_BaseMap);
            SAMPLER(sampler_BaseMap);
            
            CBUFFER_START(UnityPerMaterial)
                float4 _BaseMap_ST;
                float _PI;
                vector _WindInformation;
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

            Varyings vert(Attributes IN)
            {
                Varyings OUT;
                float y_offset = SAMPLE_TEXTURE2D_LOD(_BaseMap, sampler_BaseMap, IN.uv, 0).r;
                float2 displacement = SAMPLE_TEXTURE2D_LOD(_BaseMap, sampler_BaseMap, IN.uv, 0).gb;
                
                float2 gradient = float2(0.0f, 0.0f);
                gradient = float2(gradient.y, -gradient.x);
                OUT.positionHCS = TransformObjectToHClip(IN.positionOS.xyz + float3(displacement.x, y_offset, displacement.y));
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
