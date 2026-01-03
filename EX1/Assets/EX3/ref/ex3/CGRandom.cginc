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
    r.z = frac(512.0*j);
    j *= .125;
    r.x = frac(512.0*j);
    j *= .125;
    r.y = frac(512.0*j);
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
    float2 u = t * t * t * (t * (t * 6.0 - 15.0) + 10.0);
    // Interpolate in the x direction
    float x1 = lerp(v[0], v[1], u.x);
    float x2 = lerp(v[2], v[3], u.x);

    // Interpolate in the y direction and return
    return lerp(x1, x2, u.y);
}

// Interpolates a given array v of 8 float values using triquintic interpolation
// at the given ratio t (a float3 with components between 0 and 1)
float triquinticInterpolation(float v[8], float3 t)
{
    float3 u = t * t * t * (t * (t * 6.0 - 15.0) + 10.0);

    float v1[4] = {v[0], v[1], v[2], v[3]};
    float v2[4] = {v[4], v[5], v[6], v[7]};
    
    float y1 = biquinticInterpolation(v1, t.xy);
    float y2 = biquinticInterpolation(v2, t.xy);

    return lerp(y1, y2, u.z);
}

// Returns the value of a 2D value noise function at the given coordinates c
float value2d(float2 c)
{
    float2 grid = floor(c);
    float2 fraction = frac(c);
    
    float2 p1 = grid + float2(0,0);
    float2 p2 = grid + float2(1,0);
    float2 p3 = grid + float2(0,1);
    float2 p4 = grid + float2(1,1);
    float2 p1Color = random2(p1);
    float2 p2Color = random2(p2);
    float2 p3Color = random2(p3);
    float2 p4Color = random2(p4);
    float v[4] = {p1Color.x, p2Color.x, p3Color.x, p4Color.x};
    return bicubicInterpolation(v, fraction);
}

// Returns the value of a 2D Perlin noise function at the given coordinates c
float perlin2d(float2 c)
{
    float2 grid = floor(c);
    float2 fraction = frac(c);
    
    float2 p1 = grid + float2(0,0);
    float2 p2 = grid + float2(1,0);
    float2 p3 = grid + float2(0,1);
    float2 p4 = grid + float2(1,1);
    float2 d1 = c - p1;
    float2 d2 = c - p2;
    float2 d3 = c - p3;
    float2 d4 = c - p4;
    float2 c1 = random2(p1);
    float2 c2 = random2(p2);
    float2 c3 = random2(p3);
    float2 c4 = random2(p4);
    float v[4] = {dot(c1, d1), dot(c2, d2), dot(c3, d3), dot(c4, d4)};
    return biquinticInterpolation(v, fraction);
}

// Returns the value of a 3D Perlin noise function at the given coordinates c
float perlin3d(float3 c)
{                    
    float3 grid = floor(c);
    float3 fraction = frac(c);

    float3 p1 = grid + float3(0,0,0);
    float3 p2 = grid + float3(1,0,0);
    float3 p3 = grid + float3(0,1,0);
    float3 p4 = grid + float3(1,1,0);
    float3 p5 = grid + float3(0,0,1);
    float3 p6 = grid + float3(1,0,1);
    float3 p7 = grid + float3(0,1,1);
    float3 p8 = grid + float3(1,1,1);
    
    float3 d1 = c - p1;
    float3 d2 = c - p2;
    float3 d3 = c - p3;
    float3 d4 = c - p4;
    float3 d5 = c - p5;
    float3 d6 = c - p6;
    float3 d7 = c - p7;
    float3 d8 = c - p8;
    
    float3 c1 = random3(p1);
    float3 c2 = random3(p2);
    float3 c3 = random3(p3);
    float3 c4 = random3(p4);
    float3 c5 = random3(p5);
    float3 c6 = random3(p6);
    float3 c7 = random3(p7);
    float3 c8 = random3(p8);
    
    float v[8] = {dot(c1, d1), dot(c2, d2), dot(c3, d3), dot(c4, d4),
                  dot(c5, d5), dot(c6, d6), dot(c7, d7), dot(c8, d8)};

    return triquinticInterpolation(v,fraction);
}


#endif // CG_RANDOM_INCLUDED
