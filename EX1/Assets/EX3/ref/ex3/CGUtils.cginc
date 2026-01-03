#ifndef CG_UTILS_INCLUDED
#define CG_UTILS_INCLUDED

#define PI 3.141592653

// A struct containing all the data needed for bump-mapping
struct bumpMapData
{ 
    float3 normal;       // Mesh surface normal at the point
    float3 tangent;      // Mesh surface tangent at the point
    float2 uv;           // UV coordinates of the point
    sampler2D heightMap; // Heightmap texture to use for bump mapping
    float du;            // Increment size for u partial derivative approximation
    float dv;            // Increment size for v partial derivative approximation
    float bumpScale;     // Bump scaling factor
};


// Receives pos in 3D cartesian coordinates (x, y, z)
// Returns UV coordinates corresponding to pos using spherical texture mapping
float2 getSphericalUV(float3 pos)
{
    float r = sqrt(pow(pos.x,2) + pow(pos.y,2) + pow(pos.z,2));
    float theta = atan2(pos.z, pos.x);
    float phi = acos(pos.y / r);
    float u = 0.5 + theta / (2.0 * PI);
    float v = 1.0 - phi / PI;
    return float2(u, v);
}

// Implements an adjusted version of the Blinn-Phong lighting model
fixed3 blinnPhong(float3 n, float3 v, float3 l, float shininess, fixed4 albedo, fixed4 specularity, float ambientIntensity)
{
    float3 h = normalize(l + v);
    fixed4 ambient  = ambientIntensity * albedo;
    float4 diffuse  = max(0, dot(n, l)) * albedo;
    float4 specular = pow(max(0, dot(n, h)), shininess) * specularity;
    return ambient + diffuse + specular;
}

// Returns the world-space bump-mapped normal for the given bumpMapData
float3 getBumpMappedNormal(bumpMapData i)
{
    float p  = tex2D(i.heightMap, i.uv).r;
    float pU = tex2D(i.heightMap, float2(i.uv.x + i.du, i.uv.y)).r;
    float pV = tex2D(i.heightMap, float2(i.uv.x, i.uv.y + i.dv)).r;
    float dU = (pU - p) / i.du;
    float dV = (pV - p) / i.dv;
    
    float3 nh     = normalize(float3(-i.bumpScale * dU, -i.bumpScale * dV, 1.0));
    float3 b      = normalize(cross(i.tangent, i.normal));
    float3 nWorld = normalize(i.tangent * nh.x + i.normal * nh.z + b*nh.y);
    return nWorld;
}


#endif // CG_UTILS_INCLUDED
