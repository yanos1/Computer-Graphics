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


    public void MakeFlatShaded()
    {
        HashSet<Vector3> localVertices = new HashSet<Vector3>();

        for (int triStart = 0; triStart < triangles.Count; triStart += numVerteciesPerTriangle)
        {
            int v0 = triangles[triStart];
            int v1 = triangles[triStart + 1];
            int v2 = triangles[triStart + 2];

            Vector3 vert0 = vertices[v0];
            Vector3 vert1 = vertices[v1];
            Vector3 vert2 = vertices[v2];

            if (!localVertices.Add(vert0))
            {
                vertices.Add(vert0);
                int newIndex = vertices.Count - 1;
                triangles[triStart] = newIndex;
            }

            if (!localVertices.Add(vert1))
            {
                vertices.Add(vert1);
                int newIndex = vertices.Count - 1;
                triangles[triStart + 1] = newIndex;
            }

            if (!localVertices.Add(vert2))
            {
                vertices.Add(vert2);
                int newIndex = vertices.Count - 1;
                triangles[triStart + 2] = newIndex;
            }
        }
    }
}