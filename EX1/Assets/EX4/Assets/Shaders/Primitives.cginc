static const float EPSILON = 1e-6;

// Checks for an intersection between a ray and a sphere
// The sphere center is given by sphere.xyz and its radius is sphere.w
void intersectSphere(Ray ray, inout RayHit bestHit, Material material, float4 sphere)
{
    float3 oc = ray.origin - sphere.xyz;

    float a = dot(ray.direction, ray.direction);
    float b = 2.0 * dot(oc, ray.direction);
    float c = dot(oc, oc) - sphere.w * sphere.w;

    float disc = b * b - 4 * a * c;
    if (disc < 0) return;

    float s = sqrt(disc);
    float t1 = (-b - s) / (2 * a);
    float t2 = (-b + s) / (2 * a);

    float t = t1;
    if (t < EPSILON) t = t2;
    if (t < EPSILON || t >= bestHit.distance) return;

    bestHit.distance = t;
    bestHit.position = ray.origin + t * ray.direction;
    bestHit.normal = normalize(bestHit.position - sphere.xyz);
    bestHit.material = material;
}


// Checks for an intersection between a ray and a plane
// The plane passes through point c and has a surface normal n
void intersectPlane(Ray ray, inout RayHit bestHit, Material material, float3 c, float3 n)
{
    float dn = dot(ray.direction, n);
    if (abs(dn) < EPSILON) return;
    float t = dot(-(ray.origin - c), n) / dn;
    if (t < EPSILON || t >= bestHit.distance) return;

    bestHit.distance = t;
    bestHit.position = ray.origin + t * ray.direction;
    bestHit.normal = normalize(n);
    bestHit.material = material;
}

// Checks for an intersection between a ray and a plane
// The plane passes through point c and has a surface normal n
// The material returned is either m1 or m2 in a way that creates a checkerboard pattern 
void intersectPlaneCheckered(Ray ray, inout RayHit bestHit, Material m1, Material m2, float3 c, float3 n)
{
    float dn = dot(ray.direction, n);
    if (abs(dn) < EPSILON) return;
    float t = dot(-(ray.origin - c), n) / dn;
    if (t < EPSILON || t >= bestHit.distance) return;

    float3 p = ray.origin + t * ray.direction;
    float3 localPos = p - c;

    int checkX = floor(localPos.x);
    int checkZ = floor(localPos.z);
    bool isEven = (checkX + checkZ) % 2 == 0;
    Material material;
    if (isEven)
    {
        material = m1;
    }
    else
    {
        material = m2;
    }

    bestHit.distance = t;
    bestHit.position = p;
    bestHit.normal = normalize(n);
    bestHit.material = material;
}


// Checks for an intersection between a ray and a triangle
// The triangle is defined by points a, b, c
void intersectTriangle(Ray ray, inout RayHit bestHit, Material material, float3 a, float3 b, float3 c,
                       bool drawBackface = false)
{
    // Triangle normal
    float3 n = normalize(cross(b - a, c - a));

    // Ray–plane intersection
    float denom = dot(n, ray.direction);

    if (!drawBackface && denom >= 0) return;
    if (abs(denom) < EPS) return;

    float t = dot(a - ray.origin, n) / denom;
    if (t < EPS || t >= bestHit.distance) return;

    // Intersection point
    float3 p = ray.origin + t * ray.direction;

    // Edge tests
    if (dot(cross(b - a, p - a), n) < 0) return;
    if (dot(cross(c - b, p - b), n) < 0) return;
    if (dot(cross(a - c, p - c), n) < 0) return;

    // Valid hit
    bestHit.distance = t;
    bestHit.position = p;
    bestHit.normal = n;
    bestHit.material = material;
}

// Checks for an intersection between a ray and a 2D circle
// The circle center is given by circle.xyz, its radius is circle.w and its orientation vector is n 
void intersectCircle(Ray ray, inout RayHit bestHit, Material material, float4 circle, float3 n,
                     bool drawBackface = false)
{
    // Ray–plane intersection
    float denom = dot(n, ray.direction);

    if (!drawBackface && denom >= 0) return;
    if (abs(denom) < EPS) return;

    float t = dot(circle.xyz - ray.origin, n) / denom;
    if (t < EPS || t >= bestHit.distance) return;

    // Intersection point
    float3 p = ray.origin + t * ray.direction;

    // Check if the point is inside the circle
    float dist2 = dot(p - circle.xyz, p - circle.xyz);
    if (dist2 > circle.w * circle.w) return;

    // Valid hit
    bestHit.distance = t;
    bestHit.position = p;
    bestHit.normal = normalize(n);
    bestHit.material = material;
}


// Checks for an intersection between a ray and a cylinder aligned with the Y axis
// The cylinder center is given by cylinder.xyz, its radius is cylinder.w and its height is h
void intersectCylinderY(Ray ray, inout RayHit bestHit, Material material, float4 cylinder, float h)
{
    float3 rayDir = ray.direction;
    float3 rayOriginLocal = ray.origin - cylinder.xyz;

    float quadA = rayDir.x * rayDir.x + rayDir.z * rayDir.z;

    if (abs(quadA) > EPSILON)
    {
        float quadB = 2.0 * (rayOriginLocal.x * rayDir.x + rayOriginLocal.z * rayDir.z);
        float quadC = rayOriginLocal.x * rayOriginLocal.x
            + rayOriginLocal.z * rayOriginLocal.z
            - cylinder.w * cylinder.w;

        float discriminant = quadB * quadB - 4.0 * quadA * quadC;

        if (discriminant >= 0.0)
        {
            float sqrtDiscriminant = sqrt(discriminant);

            float tNear = (-quadB - sqrtDiscriminant) / (2.0 * quadA);
            float tFar = (-quadB + sqrtDiscriminant) / (2.0 * quadA);

            float bestSideT = 1.#INF;

            if (tNear > EPSILON && tNear < bestHit.distance)
            {
                float yAtNear = (ray.origin.y + tNear * rayDir.y) - cylinder.y;
                if (yAtNear >= 0.0 && yAtNear <= h)
                    bestSideT = tNear;
            }

            if (tFar > EPSILON && tFar < bestHit.distance && tFar < bestSideT)
            {
                float yAtFar = (ray.origin.y + tFar * rayDir.y) - cylinder.y;
                if (yAtFar >= 0.0 && yAtFar <= h)
                    bestSideT = tFar;
            }

            if (!isinf(bestSideT))
            {
                float3 hitPos = ray.origin + bestSideT * rayDir;

                bestHit.distance = bestSideT;
                bestHit.position = hitPos;

                float3 surfaceNormal = normalize(float3(
                    hitPos.x - cylinder.x,
                    0.0,
                    hitPos.z - cylinder.z
                ));

                if (dot(surfaceNormal, ray.direction) > 0.0)
                    surfaceNormal = -surfaceNormal;

                bestHit.normal = surfaceNormal;
                bestHit.material = material;
            }
        }
    }

    float4 bottomCap = float4(cylinder.xyz, cylinder.w);
    float4 topCap = float4(cylinder.xyz + float3(0.0, h, 0.0), cylinder.w);

    intersectCircle(ray, bestHit, material, bottomCap, float3(0, -1, 0), true);
    intersectCircle(ray, bestHit, material, topCap, float3(0, 1, 0), true);
}
