using UnityEngine;
using Unity.Mathematics;

public static class GenerateNoise
{
    public static Texture2D GenerateGaussianNoise(uint seed, int size)
    {
        var rng = new Unity.Mathematics.Random(seed);

        var tex = new Texture2D(size, size, TextureFormat.RGBAFloat, mipChain:false, linear:true);
        tex.wrapMode = TextureWrapMode.Repeat;
        tex.filterMode = FilterMode.Point;

        for (int y = 0; y < size; y++)
        for (int x = 0; x < size; x++)
        {
            // Box–Muller
            float u1 = Mathf.Max(1e-7f, rng.NextFloat());
            float u2 = rng.NextFloat();
            float r  = Mathf.Sqrt(-2f * Mathf.Log(u1));
            float z0 = r * Mathf.Cos(2f * Mathf.PI * u2);
            float z1 = r * Mathf.Sin(2f * Mathf.PI * u2);

            tex.SetPixel(x, y, new Color(z0, z1, 0f, 1f));
        }

        tex.Apply(false, false);
        return tex;
    }
}