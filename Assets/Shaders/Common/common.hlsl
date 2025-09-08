#ifndef COMMON_WATER_INCLUDED
#define COMMON_WATER_INCLUDED

static const float pi = 3.14159265359f;

float2 get_uv(int n, int m, int N, int M)
{
    return float2(n, m) / float2(N, M);
}

int wrap_index(int i, int size)
{
    return (i % size + size) % size;
}

float calculate_k(int n, int N, float Lx)
{
    return (2 * pi * n - pi * N) / Lx;
}

float omega(int n_prime, int m_prime, int size, float length, float g, float time_repeat) 
{
    float w_0 = 2.0f * pi / time_repeat;
    float k_x = calculate_k(n_prime, size, length);
    float k_z = calculate_k(m_prime, size, length);
    return round(sqrt(g * sqrt(k_x * k_x + k_z * k_z)) / w_0) * w_0;
}

float2 wave_vector(uint i, uint j, int N, int M, float Lx, float Lz)
{
    int ix = (i <= N / 2) ? i : i - N;
    int jz = (j <= M / 2) ? j : j - M;
    float kx = 2.0 * pi * ix / max(Lx, 1e-4);
    float kz = 2.0 * pi * jz / max(Lz, 1e-4);
    return float2(kx, kz);
}

float2 complex_add(float2 c1, float2 c2)
{
    return c1 + c2;
}

float2 complex_sub(float2 c1, float2 c2)
{
    return complex_add(c1, -c2);
}

float2 complex_conjugate(float2 c)
{
    return float2(c.x, -c.y);
}

float2 complex_mult(float2 c1, float2 c2)
{
    return float2(c1.x * c2.x - c1.y * c2.y, c1.x * c2.y + c1.y * c2.x);
}

float2 complex_exp(float theta)
{
    return float2(cos(theta), sin(theta));
}

#endif