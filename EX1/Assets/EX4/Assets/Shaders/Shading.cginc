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
// Returns the refracted (or reflected if TIR) direction.
// Updates ray.origin and ray.direction. Does NOT change ray.energy.
float3 refractRay(inout Ray ray, RayHit hit)
{
    float3 n = normalize(hit.normal);
    float3 d = normalize(ray.direction);

    // cosi = cos(theta_i) with theta_i measured from the normal
    float cosi = dot(-d, n);

    // We assume one side is always air (ior = 1)
    float ior = hit.material.refractiveIndex;

    // eta = n1 / n2
    float eta;
    if (cosi < 0.0)
    {
        // Ray is inside the object, leaving to air
        // Flip normal to face against incoming direction
        n = -n;
        cosi = -cosi;
        eta = ior; // n1/n2 = ior/1
    }
    else
    {
        // Ray is in air, entering object
        eta = 1.0 / ior; // n1/n2 = 1/ior
    }

    // Compute k to detect total internal reflection
    float k = 1.0 - eta * eta * (1.0 - cosi * cosi);

    float3 newDir;
    if (k < 0.0)
    {
        // Total internal reflection: reflect instead
        newDir = normalize(reflect(d, n));
    }
    else
    {
        // Snell refraction
        newDir = normalize(eta * d + (eta * cosi - sqrt(k)) * n);
    }

    // Move origin slightly to avoid self-intersections.
    // Note: using -n matches your original; either side can work if consistent.
    ray.origin = hit.position - n * EPS;
    ray.direction = newDir;

    return newDir;
}

// Samples the _SkyboxTexture at a given direction vector
float3 sampleSkybox(float3 direction)
{
    float theta = acos(direction.y) / -PI;
    float phi = atan2(direction.x, -direction.z) / -PI * 0.5f;
    return _SkyboxTexture.SampleLevel(sampler_SkyboxTexture, float2(phi, theta), 0).xyz;
}
