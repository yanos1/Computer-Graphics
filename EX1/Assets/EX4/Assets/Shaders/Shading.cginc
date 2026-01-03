// Implements an adjusted version of the Blinn-Phong lighting model

float3 blinnPhong(float3 n, float3 v, float3 l, float shininess, float3 albedo)
{
    // Diffuse term
    float NdotL = max(dot(n, l), 0.0);
    float3 diffuse = albedo * NdotL;

    // Halfway vector
    float3 h = normalize(l + v);

    // Specular term (Blinn-Phong)
    float NdotH = max(dot(n, h), 0.0);
    float spec = pow(NdotH, shininess) * 0.4f;

    return diffuse + spec;
}


// Reflects the given ray from the given hit point
void reflectRay(inout Ray ray, RayHit hit)
{
    float3 n = normalize(hit.normal);
    float3 d = normalize(ray.direction); // incoming ray

    ray.direction = normalize(d - 2.0 * dot(d, n) * n);

    ray.origin = hit.position + n * EPS;

    ray.energy *= hit.material.specular;
}


// Refracts the given ray from the given hit point
void refractRay(inout Ray ray, RayHit hit)
{
    // Your implementation
}

// Samples the _SkyboxTexture at a given direction vector
float3 sampleSkybox(float3 direction)
{
    float theta = acos(direction.y) / -PI;
    float phi = atan2(direction.x, -direction.z) / -PI * 0.5f;
    return _SkyboxTexture.SampleLevel(sampler_SkyboxTexture, float2(phi, theta), 0).xyz;
}
