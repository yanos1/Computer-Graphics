Shader "CG/Earth"
{
    Properties
    {
        [NoScaleOffset] _AlbedoMap ("Albedo Map", 2D) = "defaulttexture" {}
        _Ambient ("Ambient", Range(0, 1)) = 0.15
        [NoScaleOffset] _SpecularMap ("Specular Map", 2D) = "defaulttexture" {}
        _Shininess ("Shininess", Range(0.1, 100)) = 50
        [NoScaleOffset] _HeightMap ("Height Map", 2D) = "defaulttexture" {}
        _BumpScale ("Bump Scale", Range(1, 100)) = 30
        [NoScaleOffset] _CloudMap ("Cloud Map", 2D) = "black" {}
        _AtmosphereColor ("Atmosphere Color", Color) = (0.8, 0.85, 1, 1)
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
            #include "CGUtils.cginc"

            // Declare used properties
            uniform sampler2D _AlbedoMap;
            uniform float _Ambient;
            uniform sampler2D _SpecularMap;
            uniform float _Shininess;
            uniform sampler2D _HeightMap;
            uniform float4 _HeightMap_TexelSize;
            uniform float _BumpScale;
            uniform sampler2D _CloudMap;
            uniform fixed4 _AtmosphereColor;

            struct appdata
            {
                float4 vertex : POSITION;
            };

            struct v2f
            {
                float4 pos : SV_POSITION;
                float3 worldPos : TEXCOORD0;
            };

            v2f vert(appdata v)
            {
                v2f o;
                o.pos = UnityObjectToClipPos(v.vertex);
                o.worldPos = mul(unity_ObjectToWorld, v.vertex).xyz;
                return o;
            }

            fixed4 frag(v2f i) : SV_Target
            {
                // Sphere normal
                float3 sphereCenter = mul(unity_ObjectToWorld, float4(0, 0, 0, 1)).xyz;
                float3 worldNormal = normalize(i.worldPos - sphereCenter);

                // Spherical UV
                float2 uv = getSphericalUV(i.worldPos);

                // Tangent
                float3 tangent = cross(worldNormal, float3(0, 1, 0));

                // Bump map data
                bumpMapData bumpData;
                bumpData.normal = worldNormal;
                bumpData.tangent = tangent;
                bumpData.uv = uv;
                bumpData.heightMap = _HeightMap;
                bumpData.du = _HeightMap_TexelSize.x;
                bumpData.dv = _HeightMap_TexelSize.y;
                bumpData.bumpScale = _BumpScale / 10;

                // Bumped normal
                float3 bumpedNormal = getBumpMappedNormal(bumpData);
                float3 finalNormal = (1 - tex2D(_SpecularMap, uv).r) * bumpedNormal + tex2D(_SpecularMap, uv).r *
                    worldNormal;

                // Billphong
                float3 lightDir = normalize(_WorldSpaceLightPos0.xyz);
                float3 viewDir = normalize(_WorldSpaceCameraPos - i.worldPos);
                float3 halfDir = normalize(lightDir + viewDir);

                float4 albedo = tex2D(_AlbedoMap, uv);
                float4 specular = tex2D(_SpecularMap, uv);

                float3 litColor = blinnPhong(finalNormal, halfDir, lightDir, _Shininess, albedo, specular, _Ambient);

      
                float Lambert = max(dot(finalNormal, lightDir), 0);

                // Atmosphere 
                float3 atmosphere = (1 - max(0, dot(finalNormal, viewDir))) * sqrt(Lambert) * _AtmosphereColor.rgb;

                // Clouds
                float3 cloudTex = tex2D(_CloudMap, uv).rgb;
                float3 clouds = cloudTex * (sqrt(Lambert) + _Ambient);

                // Combine all
                float3 finalColor = litColor + atmosphere + clouds;

                return float4(finalColor, 1);
            }
            ENDCG
        }
    }
}