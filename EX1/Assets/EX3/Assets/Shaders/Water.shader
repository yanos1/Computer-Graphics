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
                float4 vertex : POSITION;
                float3 normal : NORMAL;
                float4 tangent : TANGENT;
                float2 uv : TEXCOORD0;
            };

            struct v2f
            {
                float4 pos : SV_POSITION;
                float2 uv : TEXCOORD0;
                float3 worldPos : TEXCOORD1;
                float3 normal : NORMAL;
                float3 tangent : TANGENT;
            };

            // Returns the value of a noise function simulating water, at coordinates uv and time t
            float waterNoise(float2 uv, float t)
            {
                // Perlin3D(0.5u, 0.5v, 0.5t) + 0.5 * Perlin3D(u, v, t) + 0.2 * Perlin3D(2u, 2v, 3t)
                return perlin3d(float3(0.5 * uv.x, 0.5 * uv.y, 0.5 * t))
                    + 0.5 * perlin3d(float3(uv.x, uv.y, t))
                    + 0.2 * perlin3d(float3(2.0 * uv.x, 2.0 * uv.y, 3.0 * t));
            }

            // Returns the world-space bump-mapped normal for the given bumpMapData and time t
            float3 getWaterBumpMappedNormal(bumpMapData i, float t)
            {
                float2 uv = i.uv;

                float hC = waterNoise(uv, t);
                float hU = waterNoise(uv + float2(i.du, 0.0), t);
                float hV = waterNoise(uv + float2(0.0, i.dv), t);

                float dHdU = (hU - hC) / i.du;
                float dHdV = (hV - hC) / i.dv;

                float3 nTangent = normalize(float3(
                    -dHdU * i.bumpScale,
                    1.0,
                    -dHdV * i.bumpScale
                ));

                float3 T = normalize(i.tangent);
                float3 N = normalize(i.normal);
                float3 B = normalize(cross(N, T));

                float3 nWorld = normalize(
                    nTangent.x * T +
                    nTangent.y * N +
                    nTangent.z * B
                );

                return nWorld;
            }


            v2f vert(appdata input)
            {
                v2f output;
                output.uv = input.uv;
                output.normal = normalize(UnityObjectToWorldNormal(input.normal));
                output.tangent = normalize(UnityObjectToWorldDir(input.tangent.xyz));

                float2 uv = _NoiseScale * input.uv;
                float c = waterNoise(uv, _Time.y * _TimeScale);

                float3 displaced = input.vertex.xyz;
                displaced.y += c * _BumpScale;

                float4 worldPos = mul(unity_ObjectToWorld, float4(displaced, 1.0));
                output.worldPos = worldPos.xyz;

                output.pos = UnityObjectToClipPos(float4(displaced, 1.0));
                return output;
            }

            fixed4 frag(v2f input) : SV_Target
            {
                bumpMapData bumpData;
                bumpData.normal = normalize(input.normal);
                bumpData.tangent = normalize(input.tangent);
                bumpData.uv = _NoiseScale * input.uv;
                bumpData.du = DELTA;
                bumpData.dv = DELTA;
                bumpData.bumpScale = _BumpScale;

                float3 n = getWaterBumpMappedNormal(bumpData, _Time.y * _TimeScale);

                float3 v = normalize(_WorldSpaceCameraPos - input.worldPos);

                float3 I = -v;
                float3 r = reflect(I, n);

                float4 reflectedColor = texCUBE(_CubeMap, r);

                float ndotv = max(0.0, dot(n, v));
                float factor = (1.0 - ndotv + 0.2);

                float3 color = factor * reflectedColor.rgb;
                return fixed4(color, 1.0);
            }
            ENDCG
        }
    }
}