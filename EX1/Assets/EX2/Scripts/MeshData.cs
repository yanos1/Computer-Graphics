using System;
using System.Collections;
using System.Collections.Generic;
using UnityEngine;


public class MeshData
{
    public List<Vector3> vertices; // The vertices of the mesh 
    public List<int> triangles; // Indices of vertices that make up the mesh faces
    public Vector3[] normals; // The normals of the mesh, one per vertex

    private int numVerteciesPerTriangle = 3;

    // Class initializer
    public MeshData()
    {
        vertices = new List<Vector3>();
        triangles = new List<int>();
    }

    // Returns a Unity Mesh of this MeshData that can be rendered
    public Mesh ToUnityMesh()
    {
        Mesh mesh = new Mesh
        {
            vertices = vertices.ToArray(),
            triangles = triangles.ToArray(),
            normals = normals
        };

        return mesh;
    }

    // Calculates surface normals for each vertex, according to face orientation
    public void CalculateNormals()
    {
        int vertexCount = vertices.Count;
        int triangleCount = triangles.Count;

        normals = new Vector3[vertexCount];

        for (int triIndex = 0; triIndex < triangleCount; triIndex += 3)
        {
            int vertexA = triangles[triIndex];
            int vertexB = triangles[triIndex + 1];
            int vertexC = triangles[triIndex + 2];

            Vector3 pointA = vertices[vertexA];
            Vector3 pointB = vertices[vertexB];
            Vector3 pointC = vertices[vertexC];

            Vector3 edgeAB = pointB - pointA;
            Vector3 edgeAC = pointC - pointA;

            Vector3 faceNormal = Vector3.Cross(edgeAB, edgeAC);

            normals[vertexA] += faceNormal;
            normals[vertexB] += faceNormal;
            normals[vertexC] += faceNormal;
        }

        for (int v = 0; v < vertexCount; v++)
            normals[v] = normals[v].normalized;
    }


    // can be optimised according to chat gpt
    public void MakeFlatShaded()
    {
        Dictionary<int, List<int>> vertToTriangle = new Dictionary<int, List<int>>();

        for (int triStart = 0; triStart < triangles.Count; triStart += numVerteciesPerTriangle)
        {
            int v0 = triangles[triStart];
            int v1 = triangles[triStart + 1];
            int v2 = triangles[triStart + 2];

            void Add(int vertexIndex)
            {
                if (!vertToTriangle.TryGetValue(vertexIndex, out var triList))
                {
                    triList = new List<int>();
                    vertToTriangle[vertexIndex] = triList;
                }

                triList.Add(triStart); // store triangle's starting index
            }

            Add(v0);
            Add(v1);
            Add(v2);
        }

        foreach ((int vertexIndex, List<int> trianglesAppearace) in vertToTriangle)
        {
            if (trianglesAppearace.Count <= 1) continue;

            var current = vertices[vertexIndex];
            bool isFirst = true;
            foreach (var triangle in trianglesAppearace)
            {
                if (isFirst)
                {
                    isFirst = false;
                    continue;
                }

                vertices.Add(current);

                int t0 = triangles[triangle];
                int t1 = triangles[triangle + 1];
                int t2 = triangles[triangle + 2];

                int newIndex = vertices.Count - 1;

                if (t0 == vertexIndex) triangles[triangle]     = newIndex;
                if (t1 == vertexIndex) triangles[triangle + 1] = newIndex;
                if (t2 == vertexIndex) triangles[triangle + 2] = newIndex;
            }
        }
    }
}