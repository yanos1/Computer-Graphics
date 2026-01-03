Shader "CG/Water"
{
    Properties
    {
        _CubeMap("Reflection Cube Map", Cube) = "" {}
        _NoiseScale("Texture Scale", Range(1, 100)) = 10 
        _TimeScale("Time Scale", Range(0.1, 5)) = 3 
        _BumpScale("Bump Scale", Range(0, 0.5)) = 0.05
    }
    SubShader
    {
        Pass
        {
            CGPROGRAM

                #pragma vertex vert
                #pragma fragment frag
                #include "UnityCG.cginc"
                #include "CGUtils.cginc"
                #include "CGRandom.cginc"

                #define DELTA 0.01

                // Declare used properties
                uniform samplerCUBE _CubeMap;
                uniform float _NoiseScale;
                uniform float _TimeScale;
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
                    float3 worldNormal  : TEXCOORD1;
                    float3 worldPos     : TEXCOORD2;
                    float3 worldTangent : TEXCOORD3;
                };

                // Returns the value of a noise function simulating water, at coordinates uv and time t
                float waterNoise(float2 uv, float t)
                {
                    // Perlin3D(0.5u, 0.5v, 0.5t) + 0.5 * Perlin3D(u, v, t) + 0.2 * Perlin3D(2u, 2v, 3t)
                    return perlin3d(float3(0.5 * uv.x, 0.5 * uv.y, 0.5 * t * _TimeScale))
                         + 0.5 * perlin3d(float3(uv.x, uv.y, t * _TimeScale)) 
                         + 0.2 * perlin3d(float3(2.0 * uv.x, 2.0 * uv.y, 3.0 * t * _TimeScale));
                }

                // Returns the world-space bump-mapped normal for the given bumpMapData and time t
                float3 getWaterBumpMappedNormal(bumpMapData i, float t)
                {
                    float p  = waterNoise(i.uv, t);
                    float pU = waterNoise(float2(i.uv.x + i.du, i.uv.y), t);
                    float pV = waterNoise(float2(i.uv.x, i.uv.y + i.dv), t);
                    float dU = (pU - p) / i.du;
                    float dV = (pV - p) / i.dv;
                    
                    float3 nh     = normalize(float3(-i.bumpScale * dU, -i.bumpScale * dV, 1.0));
                    float3 b      = normalize(cross(i.tangent, i.normal));
                    float3 nWorld = normalize(i.tangent * nh.x + i.normal * nh.z + b*nh.y);
                    return nWorld;
                }


                v2f vert (appdata input)
                {
                    v2f output;
                    float c = _BumpScale * waterNoise(input.uv * _NoiseScale, _Time.y);
                    output.uv  = input.uv;
                    output.pos = UnityObjectToClipPos(float3(0,c,0) + input.vertex);
                    output.worldNormal  = normalize(UnityObjectToWorldNormal(input.normal));
                    output.worldPos     = mul(unity_ObjectToWorld, input.vertex).xyz;
                    output.worldTangent = normalize(UnityObjectToWorldDir(input.tangent.xyz));

                    return output;
                }

                fixed4 frag (v2f input) : SV_Target
                {
                    // float c  = waterNoise(input.uv * _NoiseScale, 0);
                    // c = c * 0.5 + 0.5;
                    float3 v = normalize(_WorldSpaceCameraPos - input.worldPos);
                    
                    bumpMapData bm;
                    bm.normal    = input.worldNormal;
                    bm.tangent   = input.worldTangent;
                    bm.uv        = input.uv * _NoiseScale;
                    bm.du        = DELTA;
                    bm.dv        = DELTA;
                    bm.bumpScale = _BumpScale;

                    float3 bumpNormal = getWaterBumpMappedNormal(bm, _Time.y);
                    float3 r = 2 * dot(v,bumpNormal) * bumpNormal - v;
                    fixed4 finalColor = (1 - max(0, dot(bumpNormal,v)) + 0.2) * texCUBE(_CubeMap, r);
                    
                    return finalColor ;
                }

            ENDCG
        }
    }
}
