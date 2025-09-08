using System;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Rendering;
using UnityEngine.UI;
// ReSharper disable Unity.PreferAddressByIdToGraphicsParams

public class Preprocess : MonoBehaviour
{
    [SerializeField] 
    private ComputeShader calculateDftBasisShader;
    [SerializeField] 
    private ComputeShader calculateDftShader;
    [SerializeField] 
    private Showcase showcase;

    private RenderTexture _basisTexture;
    private RenderTexture _ftTexture;

    private Texture2D _gaussianNoise;
    
    public uint noiseSeed = 1;
    public bool useCompute = true;
    public float g = 9.8f;
    public Vector4 baseColor = new Color(0.4018867f, 0.5270109f, 0.5999999f, 1);
    // N = x axis, M = z axis
    public float lx = 0;
    public int n = 0;
    public Vector4 windInformation = new Vector4(1, 0, 30, 0.0005f);
    public Vector3 lightDirection = new Vector3(0, -1, 0);
    public float l = 0.001f;
    public float T = 100.0f;
    public float slowdown = 20.0f;
    
    private Mesh _mesh;
    private Material _material;

    public bool update = false;
    public float epsilon = 0.0001f;

    void Start()
    {
        Process();
    }

    private void Update()
    {
        if (update)
        {
            Process();
            update = false;
        }
        calculateDftShader.SetFloat("time", Time.time / slowdown);
        calculateDftShader.Dispatch(0, n / 8, 1, n / 8);
        _material.SetVector("_CameraPosition", Camera.main.transform.position);
        _material.SetTexture("_FtResult", _ftTexture);
        
        if (showcase.gameObject.activeSelf)
            showcase.ChangeShowcase(2, "DFT Result", MakePreview(ConvertRenderTexToTex2D(_ftTexture), 256.0f));
    }
    
    Texture2D ConvertRenderTexToTex2D(RenderTexture rTex)
    {
        Texture2D tex = new Texture2D(n, n, TextureFormat.RGBAFloat, false);
        RenderTexture.active = rTex;
        tex.ReadPixels(new Rect(0, 0, rTex.width, rTex.height), 0, 0);
        tex.Apply();
        return tex;
    }
    
    Texture2D MakePreview(Texture2D data, float scale = 1.0f, float offset = 0.0f)
    {
        int w = data.width; int h = data.height;
        Color[] px = data.GetPixels();
        for (int i = 0; i < px.Length; i++)
        {
            float r = offset + scale * px[i].r;
            float g = offset + scale * px[i].g;
            float b = offset + scale * px[i].b;
            px[i] = new Color(r, g, b, 1f);
        }
        Texture2D preview = new Texture2D(w, h, TextureFormat.RGBA32, false, true);
        preview.SetPixels(px);
        preview.Apply(false, false);
        return preview;
    }
    
    private void Process()
    {
        _material = GetComponent<Renderer>().material;
        _mesh = GetComponent<MeshFilter>().mesh;

        HashSet<float> uniqueZs = new HashSet<float>();
        HashSet<float> uniqueXs = new HashSet<float>();

        foreach (Vector3 vertex in _mesh.vertices)
        {
            bool foundZ = false, foundX = false;
            foreach (float z in uniqueZs)
                if (AlmostEqual(z, vertex.z))
                {
                    foundZ = true;
                    break;
                }
            
            foreach (float x in uniqueXs)
                if (AlmostEqual(x, vertex.x))
                {
                    foundX = true;
                    break;
                }

            if (!foundZ) uniqueZs.Add(vertex.z);
            if (!foundX) uniqueXs.Add(vertex.x);
        }

        n = uniqueXs.Count - 1;

        GenerateNoise();

        lx = _mesh.bounds.max.x - _mesh.bounds.min.x;

        _material.SetFloat("_Lx", lx);
        _material.SetFloat("_Lz", lx);
        _material.SetFloat("_N", n);
        _material.SetFloat("_M", n);

        _ftTexture = CreateRenderTexture(n, n);
        _basisTexture = CreateRenderTexture(n, n);
        
        OnValidate();
    }
    
    private RenderTexture CreateRenderTexture(int width, int height)
    {
        RenderTexture rt = new RenderTexture(width, height, 0, RenderTextureFormat.ARGBFloat);
        rt.useMipMap = false;
        rt.autoGenerateMips = false;
        rt.enableRandomWrite = true;
        rt.Create();
        return rt;
    }

    public void OnValidate()
    {
        if (calculateDftShader == null || n <= 0)
            return;
        
        GenerateNoise();
        ConnectShaderParameters();
        
        // Recalculate base spectrum
        calculateDftBasisShader.Dispatch(0, n / 8, 1, n / 8);
        showcase.ChangeShowcase(1, "Basis FT", MakePreview(ConvertRenderTexToTex2D(_basisTexture), 256.0f));
    }

    private void ConnectShaderParameters()
    {
        // Basis Shader
        calculateDftBasisShader.SetTexture(0, "noise", _gaussianNoise);
        calculateDftBasisShader.SetTexture(0, "result", _basisTexture);
        calculateDftBasisShader.SetFloat("g", g);
        calculateDftBasisShader.SetFloat("lx", lx);
        calculateDftBasisShader.SetInt("n", n);
        calculateDftBasisShader.SetVector("wind_information", windInformation);
        calculateDftBasisShader.SetFloat("l", l);
        
        // FT Shader
        calculateDftShader.SetTexture(0, "basis", _basisTexture);
        calculateDftShader.SetTexture(0, "result", _ftTexture);
        calculateDftShader.SetFloat("time", Time.time / slowdown);
        calculateDftShader.SetFloat("g", g);
        calculateDftShader.SetFloat("lx", lx);
        calculateDftShader.SetInt("n", n);
        calculateDftShader.SetVector("wind_information", windInformation);
        calculateDftShader.SetFloat("l", l);
        calculateDftShader.SetFloat("T", T);
    }

    public bool AlmostEqual(float first, float second)
    {
        return Math.Abs(first - second) <= epsilon;
    }

    private void GenerateNoise()
    {
        _gaussianNoise = global::GenerateNoise.GenerateGaussianNoise(noiseSeed, n);
        showcase.ChangeShowcase(0, "Noise", _gaussianNoise);
    }
}
