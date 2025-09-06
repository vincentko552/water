using System;
using System.Collections.Generic;
using UnityEngine;

public class MeshInfo : MonoBehaviour
{
    private Mesh _mesh;
    private Material _material;

    public bool update = false;
    public float epsilon = 0.0001f;

    // N = x axis, M = z axis
    private int N;
    private int M;
    private float Lx;
    private float Lz;

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

        N = uniqueZs.Count;
        M = uniqueXs.Count;

        Lx = _mesh.bounds.max.x - _mesh.bounds.min.x;
        Lz = _mesh.bounds.max.z - _mesh.bounds.min.z;
        // Lx *= transform.localScale.x;
        // Lz *= transform.localScale.z;

        _material.SetFloat("_Lx", Lx);
        _material.SetFloat("_Lz", Lz);
        _material.SetFloat("_N", N);
        _material.SetFloat("_M", M);
    }


    public bool AlmostEqual(float first, float second)
    {
        return Math.Abs(first - second) <= epsilon;
    }
}
