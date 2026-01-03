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
            Tags { "LightMode" = "ForwardBase" }

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
                    float4 vertex   : POSITION;
                    float3 normal   : NORMAL;
                    float4 tangent  : TANGENT;
                    float2 uv       : TEXCOORD0;
                };

                struct v2f
                {
                    float4 pos          : SV_POSITION;
                    float2 uv           : TEXCOORD0;
                    float3 worldPos     : TEXCOORD1;
                    float3 worldNormal  : TEXCOORD2;
                    float3 worldTangent : TEXCOORD3;
                };

                v2f vert (appdata input)
                {
                    v2f output;
                    output.pos = UnityObjectToClipPos(input.vertex);
                    output.uv  = input.uv;
                    output.worldPos     = mul(unity_ObjectToWorld, input.vertex).xyz;
                    output.worldNormal  = normalize(UnityObjectToWorldNormal(input.normal));
                    output.worldTangent = normalize(UnityObjectToWorldDir(input.tangent.xyz));
                    return output;
                }

                fixed4 frag (v2f input) : SV_Target
                {
                    half4 color     = tex2D(_AlbedoMap, input.uv);
                    float4 specular = tex2D(_SpecularMap, input.uv);
                    
                    float3 N = input.worldNormal;
                    float3 L = normalize(_WorldSpaceLightPos0.xyz);
                    float3 V = normalize(_WorldSpaceCameraPos - input.worldPos);
                    
                    bumpMapData bm;
                    bm.normal    = N;
                    bm.tangent   = input.worldTangent;
                    bm.uv        = input.uv;
                    bm.heightMap = _HeightMap;
                    bm.du        = _HeightMap_TexelSize.x;
                    bm.dv        = _HeightMap_TexelSize.y;
                    bm.bumpScale = _BumpScale * 0.0001;
                    
                    fixed3 b = blinnPhong(
                        getBumpMappedNormal(bm),
                        V,
                        L,
                        _Shininess,
                        color,
                        specular,
                        _Ambient);
                    return fixed4(b, 1.0);
                }

            ENDCG
        }
    }
}
