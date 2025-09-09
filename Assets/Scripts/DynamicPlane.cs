using System;
using UnityEngine;

[RequireComponent(typeof(MeshFilter), typeof(MeshRenderer))]
public class DynamicPlane : MonoBehaviour
{
    public int resolution = 256;
    public float size = 10f;

    private Mesh mesh;

    void Start()
    {
        GeneratePlane();
    }

    void GeneratePlane()
    {
        mesh = new Mesh();
        GetComponent<MeshFilter>().mesh = mesh;

        Vector3[] vertices = new Vector3[(resolution + 1) * (resolution + 1)];
        Vector2[] uv = new Vector2[vertices.Length];
        int[] triangles = new int[resolution * resolution * 6];

        // Vertices + UVs
        for (int z = 0, i = 0; z <= resolution; z++)
        {
            for (int x = 0; x <= resolution; x++, i++)
            {
                float xf = (float)x / resolution;
                float zf = (float)z / resolution;
                vertices[i] = new Vector3(xf * size - size * 0.5f, 0, zf * size - size * 0.5f);
                uv[i] = new Vector2(xf, zf);
            }
        }

        // Triangles
        for (int z = 0, ti = 0, vi = 0; z < resolution; z++, vi++)
        {
            for (int x = 0; x < resolution; x++, ti += 6, vi++)
            {
                triangles[ti] = vi;
                triangles[ti + 1] = vi + resolution + 1;
                triangles[ti + 2] = vi + 1;
                triangles[ti + 3] = vi + 1;
                triangles[ti + 4] = vi + resolution + 1;
                triangles[ti + 5] = vi + resolution + 2;
            }
        }

        mesh.vertices = vertices;
        mesh.uv = uv;
        mesh.triangles = triangles;
        mesh.RecalculateNormals();
    }

    private void OnValidate()
    {
        GeneratePlane();
    }
}