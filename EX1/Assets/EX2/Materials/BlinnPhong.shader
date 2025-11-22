Shader "CG/BlinnPhong"
{
    Properties
    {
        _DiffuseColor ("Diffuse Color", Color) = (0.14, 0.43, 0.84, 1)
        _SpecularColor ("Specular Color", Color) = (0.7, 0.7, 0.7, 1)
        _AmbientColor ("Ambient Color", Color) = (0.05, 0.13, 0.25, 1)
        _Shininess ("Shininess", Range(0.1, 50)) = 10
    }
    SubShader
    {
        Pass
        {
            Tags
            {
                "LightMode" = "ForwardBase"
            }

            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #include "UnityCG.cginc"
            #include "Lighting.cginc"

            // Declare used properties
            uniform fixed4 _DiffuseColor;
            uniform fixed4 _SpecularColor;
            uniform fixed4 _AmbientColor;
            uniform float _Shininess;

            struct appdata
            {
                float4 vertex : POSITION;
                float3 normal : NORMAL;
            };

            struct v2f
            {
                float4 pos : SV_POSITION;
                float3 worldPos : TEXCOORD0;
                float3 worldNormal: TEXCOORD1;
            };

            fixed4 pointLights(v2f input)
            {
                float3 pos = input.worldPos;
                float3 worldNormalNoramalized = normalize(input.worldNormal);

                float4 toLightX = unity_4LightPosX0 - pos.x;
                float4 toLightY = unity_4LightPosY0 - pos.y;
                float4 toLightZ = unity_4LightPosZ0 - pos.z;

                float4 distSq = toLightX * toLightX +
                    toLightY * toLightY +
                    toLightZ * toLightZ;

                float4 invDist = rsqrt(distSq + 1e-6);

                float4 Lx = toLightX * invDist;
                float4 Ly = toLightY * invDist;
                float4 Lz = toLightZ * invDist;

                float4 NdotL = max(0.0,
                   worldNormalNoramalized.x * Lx +
                   worldNormalNoramalized.y * Ly +
                   worldNormalNoramalized.z * Lz);

                float4 atten = 1.0 / (1.0 + distSq * unity_4LightAtten0);

                float4 diff = NdotL * atten;

                fixed3 color = 0;
                color += unity_LightColor[0].rgb * diff.x;
                color += unity_LightColor[1].rgb * diff.y;
                color += unity_LightColor[2].rgb * diff.z;
                color += unity_LightColor[3].rgb * diff.w;

                color *= _DiffuseColor.rgb;

                return fixed4(color, 0.0);
            }

            v2f vert(appdata input)
            {
                v2f output;

                output.pos = UnityObjectToClipPos(input.vertex);

                output.worldPos = mul(unity_ObjectToWorld, input.vertex).xyz;
                output.worldNormal = UnityObjectToWorldNormal(input.normal);

                return output;
            }

            fixed4 frag(v2f input) : SV_Target
            {
                float3 worldNoramlNormalized = normalize(input.worldNormal);

                float3 lightDir = normalize(_WorldSpaceLightPos0.xyz);

                float3 viewDir = normalize(_WorldSpaceCameraPos - input.worldPos);

                float3 halfDir = normalize(lightDir + viewDir);

                fixed3 ambient = _AmbientColor.rgb;

                float NdotL = max(dot(worldNoramlNormalized, lightDir), 0.0);
                fixed3 diffuse = _DiffuseColor.rgb * _LightColor0.rgb * NdotL;

                float NdotH = max(dot(worldNoramlNormalized, halfDir), 0.0);
                float spec = pow(NdotH, _Shininess);
                fixed3 specular = _SpecularColor.rgb * _LightColor0.rgb * spec;

                fixed3 finalColor = ambient + diffuse + specular;

                finalColor += pointLights(input).rgb;

                return fixed4(finalColor, 1.0);
            }
            ENDCG
        }
    }
}