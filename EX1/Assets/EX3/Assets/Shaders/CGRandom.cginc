#ifndef CG_RANDOM_INCLUDED
// Upgrade NOTE: excluded shader from DX11 because it uses wrong array syntax (type[size] name)
#pragma exclude_renderers d3d11
#define CG_RANDOM_INCLUDED

// Returns a psuedo-random float between -1 and 1 for a given float c
float random(float c)
{
    return -1.0 + 2.0 * frac(43758.5453123 * sin(c));
}

// Returns a psuedo-random float2 with componenets between -1 and 1 for a given float2 c 
float2 random2(float2 c)
{
    c = float2(dot(c, float2(127.1, 311.7)), dot(c, float2(269.5, 183.3)));

    float2 v = -1.0 + 2.0 * frac(43758.5453123 * sin(c));
    return v;
}

// Returns a psuedo-random float3 with componenets between -1 and 1 for a given float3 c 
float3 random3(float3 c)
{
    float j = 4096.0 * sin(dot(c, float3(17.0, 59.4, 15.0)));
    float3 r;
    r.z = frac(512.0 * j);
    j *= .125;
    r.x = frac(512.0 * j);
    j *= .125;
    r.y = frac(512.0 * j);
    r = -1.0 + 2.0 * r;
    return r.yzx;
}

// Interpolates a given array v of 4 float values using bicubic interpolation
// at the given ratio t (a float2 with components between 0 and 1)
//
// [0]=====o==[1]
//         |
//         t
//         |
// [2]=====o==[3]
//
float bicubicInterpolation(float v[4], float2 t)
{
    float2 u = t * t * (3.0 - 2.0 * t); // Cubic interpolation

    // Interpolate in the x direction
    float x1 = lerp(v[0], v[1], u.x);
    float x2 = lerp(v[2], v[3], u.x);

    // Interpolate in the y direction and return
    return lerp(x1, x2, u.y);
}

// Interpolates a given array v of 4 float values using biquintic interpolation
// at the given ratio t (a float2 with components between 0 and 1)
float biquinticInterpolation(float v[4], float2 t)
{
    float2 u = t * t * t * (10.0 - 15.0 * t + 6.0 * t * t); // Quintic interpolation

    float x1 = lerp(v[0], v[1], u.x);
    float x2 = lerp(v[2], v[3], u.x);

    return lerp(x1, x2, u.y);
}

// Interpolates a given array v of 8 float values using triquintic interpolation
// at the given ratio t (a float3 with components between 0 and 1)
float triquinticInterpolation(float v[8], float3 t)
{
    // Quintic fade: 6t^5 - 15t^4 + 10t^3
    float3 u = t * t * t * (10.0 - 15.0 * t + 6.0 * t * t);

    float v00 = lerp(v[0], v[1], u.x);
    float v10 = lerp(v[2], v[3], u.x);
    float v01 = lerp(v[4], v[5], u.x);
    float v11 = lerp(v[6], v[7], u.x);

    float v0 = lerp(v00, v10, u.y); // z = 0 slice
    float v1 = lerp(v01, v11, u.y); // z = 1 slice

    return lerp(v0, v1, u.z);
}

float value2d(float2 c)
{
    float2 i = floor(c);
    float2 f = frac(c);

    float v[4];
    v[0] = random2(i + float2(0, 0)).x;
    v[1] = random2(i + float2(1, 0)).x;
    v[2] = random2(i + float2(0, 1)).x;
    v[3] = random2(i + float2(1, 1)).x;

    return bicubicInterpolation(v, f);
}


// Returns the value of a 2D Perlin noise function at the given coordinates c
float perlin2d(float2 c)
{
    float2 i = floor(c);
    float2 f = frac(c);

    float2 g[4];
    g[0] = normalize(random2(i + float2(0, 0)));
    g[1] = normalize(random2(i + float2(1, 0)));
    g[2] = normalize(random2(i + float2(0, 1)));
    g[3] = normalize(random2(i + float2(1, 1)));

    float d[4];
    d[0] = dot(g[0], f - float2(0, 0));
    d[1] = dot(g[1], f - float2(1, 0));
    d[2] = dot(g[2], f - float2(0, 1));
    d[3] = dot(g[3], f - float2(1, 1));

    return 0.5 + 0.5 * biquinticInterpolation(d, f);
}

// Returns the value of a 3D Perlin noise function at the given coordinates c
float perlin3d(float3 c)
{
    float3 i = floor(c);
    float3 f = frac(c);

    float3 g[8];
    g[0] = normalize(random3(i + float3(0, 0, 0))); // (0,0,0)
    g[1] = normalize(random3(i + float3(1, 0, 0))); // (1,0,0)
    g[2] = normalize(random3(i + float3(0, 1, 0))); // (0,1,0)
    g[3] = normalize(random3(i + float3(1, 1, 0))); // (1,1,0)
    g[4] = normalize(random3(i + float3(0, 0, 1))); // (0,0,1)
    g[5] = normalize(random3(i + float3(1, 0, 1))); // (1,0,1)
    g[6] = normalize(random3(i + float3(0, 1, 1))); // (0,1,1)
    g[7] = normalize(random3(i + float3(1, 1, 1))); // (1,1,1)

    float d[8];
    d[0] = dot(g[0], f - float3(0, 0, 0));
    d[1] = dot(g[1], f - float3(1, 0, 0));
    d[2] = dot(g[2], f - float3(0, 1, 0));
    d[3] = dot(g[3], f - float3(1, 1, 0));
    d[4] = dot(g[4], f - float3(0, 0, 1));
    d[5] = dot(g[5], f - float3(1, 0, 1));
    d[6] = dot(g[6], f - float3(0, 1, 1));
    d[7] = dot(g[7], f - float3(1, 1, 1));

    return 0.5 + 0.5 * triquinticInterpolation(d, f);
}


#endif // CG_RANDOM_INCLUDED
