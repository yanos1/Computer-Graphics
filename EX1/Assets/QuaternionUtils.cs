using System;
using UnityEngine;

public class QuaternionUtils
{
    // The default rotation order of Unity. May be used for testing
    public static readonly Vector3Int UNITY_ROTATION_ORDER = new Vector3Int(1, 2, 0);

    // Returns the product of 2 given quaternions
    public static Vector4 Multiply(Vector4 q1, Vector4 q2)
    {
        return new Vector4(
            q1.w * q2.x + q1.x * q2.w + q1.y * q2.z - q1.z * q2.y,
            q1.w * q2.y + q1.y * q2.w + q1.z * q2.x - q1.x * q2.z,
            q1.w * q2.z + q1.z * q2.w + q1.x * q2.y - q1.y * q2.x,
            q1.w * q2.w - q1.x * q2.x - q1.y * q2.y - q1.z * q2.z
        );
    }

    // Returns the conjugate of the given quaternion q
    public static Vector4 Conjugate(Vector4 q)
    {
        return new Vector4(-q.x, -q.y, -q.z, q.w);
    }

    // Returns the Hamilton product of given quaternions q and v
    public static Vector4 HamiltonProduct(Vector4 q, Vector4 v)
    {
        return Multiply(Multiply(q, v), Conjugate(q));
    }

    // Returns a quaternion representing a rotation of theta degrees around the given axis
    public static Vector4 AxisAngle(Vector3 axis, float theta)
    {
        float halfThetaRad = (theta * Mathf.Deg2Rad) / 2f;
        float sinHalfTheta = Mathf.Sin(halfThetaRad);
        return new Vector4(
            axis.x * sinHalfTheta,
            axis.y * sinHalfTheta,
            axis.z * sinHalfTheta,
            Mathf.Cos(halfThetaRad)
        );
    }

    // Returns a quaternion representing the given Euler angles applied in the given rotation order
    public static Vector4 FromEuler(Vector3 euler, Vector3Int rotationOrder)
    {
        Vector4 qx = AxisAngle(Vector3.right, euler.x);
        Vector4 qy = AxisAngle(Vector3.up, euler.y);
        Vector4 qz = AxisAngle(Vector3.forward, euler.z);

        Vector4[] quaternions = { qx, qy, qz };
        Vector4 result = quaternions[rotationOrder.z];
        result = Multiply(result, quaternions[rotationOrder.y]);
        result = Multiply(result, quaternions[rotationOrder.x]);
        return result;
    }

    // Returns a spherically interpolated quaternion between q1 and q2 at time t in [0,1]
    public static Vector4 Slerp(Vector4 q1, Vector4 q2, float t)
    {
        // Compute the dot product (cosine of angle between quaternions)
        float dot = Vector4.Dot(q1, q2);

        // If the dot product is negative, negate one quaternion to take the shorter path
        if (dot < 0.0f)
        {
            q2 = new Vector4(-q2.x, -q2.y, -q2.z, -q2.w);
            dot = -dot;
        }

        // Clamp dot product to avoid numerical errors with acos
        dot = Math.Clamp(dot, -1.0f, 1.0f);

        // Calculate the angle between the quaternions
        float theta = (float)Math.Acos(dot);
        float sinTheta = (float)Math.Sin(theta);

        // If quaternions are very close, use linear interpolation to avoid division by zero
        if (sinTheta < 0.001f)
        {
            return new Vector4(
                q1.x * (1.0f - t) + q2.x * t,
                q1.y * (1.0f - t) + q2.y * t,
                q1.z * (1.0f - t) + q2.z * t,
                q1.w * (1.0f - t) + q2.w * t
            );
        }

        // Apply the SLERP formula: sin((1-t)θ)/sinθ * p + sin(tθ)/sinθ * q
        float coeff1 = (float)Math.Sin((1.0f - t) * theta) / sinTheta;
        float coeff2 = (float)Math.Sin(t * theta) / sinTheta;

        return new Vector4(
            q1.x * coeff1 + q2.x * coeff2,
            q1.y * coeff1 + q2.y * coeff2,
            q1.z * coeff1 + q2.z * coeff2,
            q1.w * coeff1 + q2.w * coeff2
        );
    }
}