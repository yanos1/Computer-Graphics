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
                uniform sampler2D _CloudMap;
                uniform fixed4 _AtmosphereColor;

                struct appdata
                { 
                    float4 vertex : POSITION;
                };

                struct v2f
                {
                    float4 pos      : SV_POSITION;
                    float3 worldPos : TEXCOORD1;
                };

                v2f vert (appdata input)
                {
                    v2f output;
                    output.pos = UnityObjectToClipPos(input.vertex);
                    output.worldPos = mul(unity_ObjectToWorld, input.vertex).xyz;
                    return output;
                }

                fixed4 frag (v2f input) : SV_Target
                {
                    float2 uv = getSphericalUV(input.worldPos);
                    
                    fixed4 color    = tex2D(_AlbedoMap, uv);
                    float4 specular = tex2D(_SpecularMap, uv);
                    float4 cloudmap = tex2D(_CloudMap, uv);
                    
                    float3 N = normalize(input.worldPos);
                    float3 L = normalize(_WorldSpaceLightPos0.xyz);
                    float3 V = normalize(_WorldSpaceCameraPos - input.worldPos);
                    
                    float3 lambert    = max(0, dot(N, L));
                    float3 atmosphere = (1 - max(0, dot(N,V))) * sqrt(lambert) * _AtmosphereColor;
                    float3 clouds     = cloudmap * (sqrt(lambert) + _Ambient);
                    
                    bumpMapData bm;
                    bm.normal    = N;
                    bm.tangent   = cross(N, float3(0,1,0));
                    bm.uv        = uv;
                    bm.heightMap = _HeightMap;
                    bm.du        = _HeightMap_TexelSize.x;
                    bm.dv        = _HeightMap_TexelSize.y;
                    bm.bumpScale = _BumpScale * 0.0001;

                    float3 finalNormal = (1 - specular.x) * getBumpMappedNormal(bm) + specular.x * N;
                    fixed3 b = blinnPhong(
                        finalNormal,
                        V,
                        L,
                        _Shininess,
                        color,
                        specular,
                        _Ambient);
                    
                    return fixed4(b + atmosphere + clouds, 1.0);
                }

            ENDCG
        }
    }
}
