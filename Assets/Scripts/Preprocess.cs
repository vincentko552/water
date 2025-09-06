using System;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Rendering;
using UnityEngine.UI;

public class Preprocess : MonoBehaviour
{
    [SerializeField] 
    private ComputeShader preprocessFtShader;

    public RenderTexture ftTexture;

    public Texture2D _RealMap;
    public Texture2D _ImaginaryMap;
    public bool _UseCompute = true;
    public float _LocalAccel = 9.8f;
    public Vector4 _BaseColor = new Color(0.4018867f, 0.5270109f, 0.5999999f, 1);
    // N = x axis, M = z axis
    public float _Lx = 0;
    public float _Lz = 0;
    public int _N = 0;
    public int _M = 0;
    public Vector4 _WindInformation = new Vector4(1, 0, 30, 0.0005f);
    public Vector3 _LightDirection = new Vector3(0, -1, 0);
    public float _l = 0.001f;
    public float _TimeRepeat = 100.0f;
    public float _PhaseMult = 100.0f;
    public float _Slowdown = 1.0f;
    
    private Mesh _mesh;
    private Material _material;

    public bool update = false;
    public float epsilon = 0.0001f;

    void Awake()
    {
        _RealMap = Resources.Load<Texture2D>("real");
        _ImaginaryMap = Resources.Load<Texture2D>("imaginary");
    }
    
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
        preprocessFtShader.SetFloat("_Time", Time.time / _Slowdown);
        preprocessFtShader.Dispatch(0, _N / 8, 1, _M / 8);
        _material.SetTexture("_FtResult", ftTexture);
    }

    public void UpdateShader()
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

        _N = uniqueZs.Count - 1;
        _M = uniqueXs.Count - 1;

        _Lx = _mesh.bounds.max.x - _mesh.bounds.min.x;
        _Lz = _mesh.bounds.max.z - _mesh.bounds.min.z;
        // Lx *= transform.localScale.x;
        // Lz *= transform.localScale.z;

        _material.SetFloat("_Lx", _Lx);
        _material.SetFloat("_Lz", _Lz);
        _material.SetFloat("_N", _N);
        _material.SetFloat("_M", _M);
        
        ftTexture = new RenderTexture(_N, _M, 0, RenderTextureFormat.ARGBFloat);
        ftTexture.useMipMap = false;
        ftTexture.autoGenerateMips = false;
        ftTexture.enableRandomWrite = true;
        ftTexture.Create();
        
        OnValidate();
    }

    public void OnValidate()
    {
        if (preprocessFtShader == null || _RealMap == null || _ImaginaryMap == null)
            return;
        
        preprocessFtShader.SetTexture(0, "_RealMap", _RealMap);
        preprocessFtShader.SetTexture(0, "_ImaginaryMap", _ImaginaryMap);
        preprocessFtShader.SetFloat("_LocalAccel", _LocalAccel);
        preprocessFtShader.SetVector("_BaseColor", _BaseColor);
        preprocessFtShader.SetFloat("_Lx", _Lx);
        preprocessFtShader.SetFloat("_Lz", _Lz);
        preprocessFtShader.SetFloat("_N", _N);
        preprocessFtShader.SetFloat("_M", _M);
        preprocessFtShader.SetVector("_WindInformation", _WindInformation);
        preprocessFtShader.SetVector("_LightDirection", _LightDirection);
        preprocessFtShader.SetFloat("_l", _l);
        preprocessFtShader.SetFloat("_TimeRepeat", _TimeRepeat);
        preprocessFtShader.SetFloat("_PhaseMult", _PhaseMult);
        preprocessFtShader.SetTexture(0, "Result", ftTexture);
        
        _material.SetInt("_UseCompute", _UseCompute ? 1 : 0);
    }

    public bool AlmostEqual(float first, float second)
    {
        return Math.Abs(first - second) <= epsilon;
    }
}
