Shader "CG/BlinnPhongGouraud"
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
                fixed4 color : COLOR;
            };


            v2f vert(appdata input)
            {
                v2f output;
                output.pos = UnityObjectToClipPos(input.vertex);
                
                float3 worldPos = mul(unity_ObjectToWorld, input.vertex).xyz;
                float3 worldNormal = UnityObjectToWorldNormal(input.normal);

                worldNormal = normalize(worldNormal);

                float3 lightDir = normalize(_WorldSpaceLightPos0.xyz);

                float3 viewDir = normalize(_WorldSpaceCameraPos - worldPos);

                float3 halfDir = normalize(lightDir + viewDir);

                float NdotL = max(0.0, dot(worldNormal, lightDir));
                fixed3 diffuse = _DiffuseColor.rgb * _LightColor0.rgb * NdotL;

                float NdotH = max(0.0, dot(worldNormal, halfDir));
                float spec = pow(NdotH, _Shininess);
                fixed3 specular = _SpecularColor.rgb * _LightColor0.rgb * spec;

                fixed3 ambient = _AmbientColor.rgb;

                fixed3 finalColor = ambient + diffuse + specular;
                output.color = fixed4(finalColor, 1.0);
                return output;
            }


            fixed4 frag(v2f input) : SV_Target
            {
                return input.color;
            }
            ENDCG
        }
    }
}