#ifndef CG_UTILS_INCLUDED
#define CG_UTILS_INCLUDED

#define PI 3.141592653

// A struct containing all the data needed for bump-mapping
struct bumpMapData
{
    float3 normal; // Mesh surface normal at the point
    float3 tangent; // Mesh surface tangent at the point
    float2 uv; // UV coordinates of the point
    sampler2D heightMap; // Heightmap texture to use for bump mapping
    float du; // Increment size for u partial derivative approximation
    float dv; // Increment size for v partial derivative approximation
    float bumpScale; // Bump scaling factor
};


// Receives pos in 3D cartesian coordinates (x, y, z)
// Returns UV coordinates corresponding to pos using spherical texture mapping
float2 getSphericalUV(float3 pos)
{
    float radius = length(pos);

    if (radius == 0) return float2(0, 0);

    float theta = atan2(pos.z, pos.x);
    float phi = acos(pos.y / radius);

    float u = (theta + 0.5) / (2 * PI);
    float v = 1 - (phi / PI);

    return float2(u, v);
}

// Implements an adjusted version of the Blinn-Phong lighting model
fixed3 blinnPhong(float3 n, float3 v, float3 l, float shininess, fixed4 albedo, fixed4 specularity,
                  float ambientIntensity)
{
    // Your implementation
    fixed4 finalAmbient = albedo * ambientIntensity;
    float3 finalDiffuse = max(dot(n, l), 0) * albedo;
    float3 finalSpecular = pow(max(dot(n, v), 0), shininess) * specularity;
    return finalAmbient + finalDiffuse + finalSpecular;
}

// Returns the world-space bump-mapped normal for the given bumpMapData
// Returns the world-space bump-mapped normal for the given bumpMapData
float3 getBumpMappedNormal(bumpMapData i)
{
    float h = tex2D(i.heightMap, i.uv).r;
    float hU = tex2D(i.heightMap, i.uv + float2(i.du, 0)).r;
    float hV = tex2D(i.heightMap, i.uv + float2(0, i.dv)).r;

    // Compute height derivatives
    float dHdu = (hU - h) * i.bumpScale;
    float dHdv = (hV - h) * i.bumpScale;

    // Tangent-space displacement vectors
    float3 tangent = normalize(i.tangent);
    float3 bitangent = normalize(cross(i.normal, tangent));

    // Perturb normal in tangent space
    float3 bumpedNormal = normalize(i.normal - dHdu * tangent - dHdv * bitangent);

    return bumpedNormal;
}


#endif // CG_UTILS_INCLUDED
