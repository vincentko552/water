using System;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Rendering;
using UnityEngine.UI;
// ReSharper disable Unity.PreferAddressByIdToGraphicsParams

public class Preprocess : MonoBehaviour
{
    [SerializeField] 
    private ComputeShader preprocessFtShader;
    [SerializeField] 
    private Showcase showcase;

    public RenderTexture ftTexture;

    public Texture2D gaussianNoise;
    public uint noiseSeed = 1;
    public bool useCompute = true;
    public float localAccel = 9.8f;
    public Vector4 baseColor = new Color(0.4018867f, 0.5270109f, 0.5999999f, 1);
    // N = x axis, M = z axis
    public float lx = 0;
    public float lz = 0;
    public int n = 0;
    public int m = 0;
    public Vector4 windInformation = new Vector4(1, 0, 30, 0.0005f);
    public Vector3 lightDirection = new Vector3(0, -1, 0);
    public float l = 0.001f;
    public float timeRepeat = 100.0f;
    public float slowdown = 1.0f;
    
    private Mesh _mesh;
    private Material _material;

    public bool update = false;
    public float epsilon = 0.0001f;

    void Start()
    {
        UpdateShader();
    }

    private void Update()
    {
        if (update)
        {
            UpdateShader();
            update = false;
        }
        preprocessFtShader.SetFloat("_Time", Time.time / slowdown);
        preprocessFtShader.Dispatch(0, n / 8, 1, m / 8);
        _material.SetVector("_CameraPosition", Camera.main.transform.position);
        _material.SetTexture("_FtResult", ftTexture);
    }

    private void UpdateShader()
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
        m = uniqueZs.Count - 1;

        RegenerateNoise();

        lx = _mesh.bounds.max.x - _mesh.bounds.min.x;
        lz = _mesh.bounds.max.z - _mesh.bounds.min.z;

        _material.SetFloat("_Lx", lx);
        _material.SetFloat("_Lz", lz);
        _material.SetFloat("_N", n);
        _material.SetFloat("_M", m);
        
        ftTexture = new RenderTexture(n, m, 0, RenderTextureFormat.ARGBFloat);
        ftTexture.useMipMap = false;
        ftTexture.autoGenerateMips = false;
        ftTexture.enableRandomWrite = true;
        ftTexture.Create();
        
        OnValidate();
    }

    public void OnValidate()
    {
        if (preprocessFtShader == null || n <= 0)
            return;
        
        RegenerateNoise();
        
        preprocessFtShader.SetTexture(0, "_Noise", gaussianNoise);
        preprocessFtShader.SetFloat("_LocalAccel", localAccel);
        preprocessFtShader.SetVector("_BaseColor", baseColor);
        preprocessFtShader.SetFloat("_Lx", lx);
        preprocessFtShader.SetFloat("_Lz", lz);
        preprocessFtShader.SetFloat("_N", n);
        preprocessFtShader.SetFloat("_M", m);
        preprocessFtShader.SetVector("_WindInformation", windInformation);
        preprocessFtShader.SetVector("_LightDirection", lightDirection);
        preprocessFtShader.SetFloat("_l", l);
        preprocessFtShader.SetFloat("_TimeRepeat", timeRepeat);
        preprocessFtShader.SetTexture(0, "Result", ftTexture);
        
        _material.SetInt("_UseCompute", useCompute ? 1 : 0);
    }

    public bool AlmostEqual(float first, float second)
    {
        return Math.Abs(first - second) <= epsilon;
    }

    private void RegenerateNoise()
    {
        gaussianNoise = GenerateNoise.GenerateGaussianNoise(noiseSeed, n);
        showcase.ChangeShowcase(0, "Noise", gaussianNoise);
    }
}
