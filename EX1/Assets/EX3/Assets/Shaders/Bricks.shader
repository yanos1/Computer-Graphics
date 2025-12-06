Shader "CG/Bricks"
{
    Properties
    {
        [NoScaleOffset] _AlbedoMap ("Albedo Map", 2D) = "defaulttexture" {}
        _Ambient ("Ambient", Range(0, 1)) = 0.15
        [NoScaleOffset] _SpecularMap ("Specular Map", 2D) = "defaulttexture" {}
        _Shininess ("Shininess", Range(0.1, 100)) = 50
        [NoScaleOffset] _HeightMap ("Height Map", 2D) = "defaulttexture" {}
        _BumpScale ("Bump Scale", Range(-100, 100)) = 40
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

            struct appdata
            {
                float4 vertex : POSITION;
                float3 normal : NORMAL;
                float4 tangent : TANGENT;
                float2 uv : TEXCOORD0;
            };

            struct v2f
            {
                float4 pos : SV_POSITION;
                float3 normal : NORMAL;
                float2 uv : TEXCOORD0;
                float3 worldPos: TEXCOORD1;
                float3 tangent: TEXCOORD2;
            };

            v2f vert(appdata input)
            {
                v2f output;

                output.pos = UnityObjectToClipPos(input.vertex);
                output.uv = input.uv;

                output.normal = UnityObjectToWorldNormal(input.normal);
                output.tangent = UnityObjectToWorldDir(input.tangent.xyz);
                output.worldPos = mul(unity_ObjectToWorld, input.vertex).xyz;

                return output;
            }


            fixed4 frag(v2f input) : SV_Target
            {
                // Bumpmap
                bumpMapData bumpData;
                bumpData.normal = normalize(input.normal);
                bumpData.tangent = normalize(input.tangent);
                bumpData.uv = input.uv;
                bumpData.heightMap = _HeightMap;
                bumpData.du = _HeightMap_TexelSize.x;
                bumpData.dv = _HeightMap_TexelSize.y;
                bumpData.bumpScale = _BumpScale/10000;

                float3 bumpedNormal = getBumpMappedNormal(bumpData);

                // Billphong
                float3 worldNormal = normalize(bumpedNormal);
                float3 lightDir = normalize(_WorldSpaceLightPos0.xyz);
                float3 viewDir = normalize(_WorldSpaceCameraPos - input.worldPos);
                float3 halfDir = normalize(lightDir + viewDir);

                float4 baseAlbedo = tex2D(_AlbedoMap, input.uv);
                float4 baseSpecular = tex2D(_SpecularMap, input.uv);

                fixed3 litColor = blinnPhong(worldNormal, halfDir, lightDir,
                                             _Shininess, baseAlbedo, baseSpecular, _Ambient);

                return fixed4(litColor, 1);
            }
            ENDCG
        }
    }
}