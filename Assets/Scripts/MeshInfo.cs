using UnityEngine;

public class MeshInfo : MonoBehaviour
{
    private Mesh mesh;
    private Material material;

    // N = x axis, M = z axis
    public int N;
    public int M;
    public float Lx;
    public float Lz;

    void Start()
    {
        material = GetComponent<Renderer>().material;
        mesh = GetComponent<MeshFilter>().mesh;
        float currentColumnPosZ = mesh.vertices[0].z;
        M = 1;
        N = 1;
        foreach (Vector3 vertex in mesh.vertices[1..mesh.vertices.Length])
        {
            // New Line
            if (currentColumnPosZ != vertex.z)
            {
                N++;
                currentColumnPosZ = vertex.z;
            }
            // Only track width on first line
            else if (N == 1)
                M++;
        }

        Lx = mesh.bounds.min.x - mesh.bounds.max.x;
        Lz = mesh.bounds.min.z - mesh.bounds.max.z;

        // TODO
        // material.SetFloat("name", 0);
    }
}
