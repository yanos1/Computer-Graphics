using System;
using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class CharacterAnimator : MonoBehaviour
{
    public TextAsset BVHFile; // The BVH file that defines the animation and skeleton
    public bool animate; // Indicates whether or not the animation should be running
    public bool interpolate; // Indicates whether or not frames should be interpolated
    [Range(0.01f, 2f)] public float animationSpeed = 1; // Controls the speed of the animation playback

    public BVHData data; // BVH data of the BVHFile will be loaded here
    public float t = 0; // Value used to interpolate the animation between frames
    public float[] currFrameData; // BVH channel data corresponding to the current keyframe
    public float[] nextFrameData; // BVH vhannel data corresponding to the next keyframe

    // Constants
    private const int GeneralScale = 2;
    private const int HeadScale = 8;
    private const float CylinderDiameter = 0.6f;


    // Start is called before the first frame update
    void Start()
    {
        BVHParser parser = new BVHParser();
        data = parser.Parse(BVHFile);
        CreateJoint(data.rootJoint, Vector3.zero);
    }

    // Returns a Matrix4x4 representing a rotation aligning the up direction of an object with the given v
    public Matrix4x4 RotateTowardsVector(Vector3 v)
    {
        Vector3 target = v.normalized;
        Vector3 up = Vector3.up;

        if (Vector3.Dot(target, up) > 0.9999f)
        {
            return Matrix4x4.identity;
        }

        if (Vector3.Dot(target, up) < -0.9999f)
        {
            return MatrixUtils.RotateX(180f);
        }


        // Calculate rotation around Y axis
        // Project target onto XZ plane 
        Vector3 targetXZ = new Vector3(target.x, 0, target.z);
        float yawAngle = 0f;
        if (targetXZ.magnitude > 0.001f)
        {
            targetXZ = targetXZ.normalized;
            yawAngle = Mathf.Atan2(targetXZ.x, targetXZ.z) * Mathf.Rad2Deg;
        }

        // Calculate rotation around X axis 
        float pitchAngle = -Mathf.Asin(Mathf.Clamp(target.y, -1f, 1f)) * Mathf.Rad2Deg + 90f;

        Matrix4x4 yawMatrix = MatrixUtils.RotateY(yawAngle);
        Matrix4x4 pitchMatrix = MatrixUtils.RotateX(pitchAngle);

        // Combine in order: Y * X
        return yawMatrix * pitchMatrix;
    }

    // Creates a Cylinder GameObject between two given points in 3D space
    public GameObject CreateCylinderBetweenPoints(Vector3 p1, Vector3 p2, float diameter)
    {
        GameObject cylinder = GameObject.CreatePrimitive(PrimitiveType.Cylinder);
        Vector3 direction = p2 - p1;
        float length = direction.magnitude;
        Vector3 position = (p1 + p2) / 2.0f;

        Matrix4x4 translationMatrix = MatrixUtils.Translate(position);
        Matrix4x4 rotationMatrix = RotateTowardsVector(direction);
        Matrix4x4 scaleMatrix = MatrixUtils.Scale(new Vector3(diameter, length / 2.0f, diameter));
        MatrixUtils.ApplyTransform(cylinder, translationMatrix * rotationMatrix * scaleMatrix);

        return cylinder;
    }

    // Creates a GameObject representing a given BVHJoint and recursively creates GameObjects for it's child joints
    public GameObject CreateJoint(BVHJoint joint, Vector3 parentPosition)
    {
        // create base sphere game object at parentPosition + joint.offset
        GameObject jointObj = new GameObject(joint.name);

        GameObject sphere = GameObject.CreatePrimitive(PrimitiveType.Sphere);
        sphere.transform.parent = jointObj.gameObject.transform;

        Matrix4x4 translationMatrix = MatrixUtils.Translate(parentPosition + joint.offset);
        Matrix4x4 scaleMatrix = MatrixUtils.Scale(GetJointScaleFactor(joint) * Vector3.one);
        MatrixUtils.ApplyTransform(sphere, scaleMatrix);
        MatrixUtils.ApplyTransform(jointObj, translationMatrix);

        foreach (BVHJoint child in joint.children)
        {
            GameObject childJoint = CreateJoint(child, jointObj.transform.position);
            GameObject childCylinder = CreateCylinderBetweenPoints(jointObj.transform.position,
                childJoint.transform.position, CylinderDiameter);
            childCylinder.transform.parent = jointObj.transform;
        }

        joint.gameObject = jointObj;
        return jointObj;
    }

    // Transforms BVHJoint according to the keyframe channel data, and recursively transforms its children
    public void TransformJoint(BVHJoint joint, Matrix4x4 parentTransform)
    {
        // Build local translation matrix
        Matrix4x4 translationMatrix = MatrixUtils.Translate(joint.offset);

        Matrix4x4 rotationMatrix = CreateRotationMatrix(joint);

        Matrix4x4 T_R_local = translationMatrix * rotationMatrix;

        // Compose the global transform
        if (joint == data.rootJoint)
        {
            T_R_local = TranslateJointWithLerp(joint, rotationMatrix);
        }

        Matrix4x4 globalTransform = parentTransform * T_R_local;

        // Apply only translation and rotation to the joint's GameObject;
        // No scale applied, so its initial creation scale stays constant
        MatrixUtils.ApplyTransform(joint.gameObject, globalTransform);

        // Recursively transform child joints
        foreach (BVHJoint child in joint.children) TransformJoint(child, globalTransform);
    }

    private Matrix4x4 TranslateJointWithLerp(BVHJoint joint, Matrix4x4 T_R_local)
    {
        if (interpolate)
        {
            return MatrixUtils.Translate(new Vector3(
                Mathf.Lerp(currFrameData[joint.positionChannels.x], nextFrameData[joint.positionChannels.x], t),
                Mathf.Lerp(currFrameData[joint.positionChannels.y], nextFrameData[joint.positionChannels.y], t),
                Mathf.Lerp(currFrameData[joint.positionChannels.z], nextFrameData[joint.positionChannels.z], t)
            )) * T_R_local;
        }

        return MatrixUtils.Translate(new Vector3(
            currFrameData[joint.positionChannels.x],
            currFrameData[joint.positionChannels.y],
            currFrameData[joint.positionChannels.z])) * T_R_local;
    }

    private Matrix4x4 CreateRotationMatrix(BVHJoint joint)
    {
        if (!interpolate)
        {
            // slerp rotation using quaternions
            Vector3 currEuler = new Vector3(
                currFrameData[joint.rotationChannels.x],
                currFrameData[joint.rotationChannels.y],
                currFrameData[joint.rotationChannels.z]
            );
            Vector3 nextEuler = new Vector3(
                nextFrameData[joint.rotationChannels.x],
                nextFrameData[joint.rotationChannels.y],
                nextFrameData[joint.rotationChannels.z]
            );
            Vector4 currQuat = QuaternionUtils.FromEuler(currEuler, joint.rotationOrder);
            Vector4 nextQuat = QuaternionUtils.FromEuler(nextEuler, joint.rotationOrder);
            Vector4 lerpedQuat = QuaternionUtils.Slerp(currQuat, nextQuat, t);

            return MatrixUtils.RotateFromQuaternion(lerpedQuat);
        }

        Matrix4x4[] matrixList =
        {
            MatrixUtils.RotateX(currFrameData[joint.rotationChannels.x]),
            MatrixUtils.RotateY(currFrameData[joint.rotationChannels.y]),
            MatrixUtils.RotateZ(currFrameData[joint.rotationChannels.z]),
        };

        return matrixList[joint.rotationOrder.x] *
               matrixList[joint.rotationOrder.y] *
               matrixList[joint.rotationOrder.z];
    }


    // assign the entries X=0, Y=1, Z=2 to a list in the order specified by joint.rotationOrder
    private static List<string> Vector3Int2List(BVHJoint joint)
    {
        // initialize list of strings
        string[] axes = { "X", "Y", "Z" };
        List<string> rotationOrder = new List<string>
        {
            axes[joint.rotationOrder.x],
            axes[joint.rotationOrder.y],
            axes[joint.rotationOrder.z]
        };

        return rotationOrder;
    }


    // Returns the frame number of the BVH animation at a given time
    public int GetFrameNumber(float time)
    {
        return (int)(time / data.frameLength) % data.numFrames;
    }

    // Returns the proportion of time elapsed between the last frame and the next one, between 0 and 1
    public float GetFrameIntervalTime(float time)
    {
        return (time % data.frameLength) / data.frameLength;
    }

    // Update is called once per frame
    void Update()
    {
        float time = Time.time * animationSpeed;
        if (animate)
        {
            int currFrame = GetFrameNumber(time);
            t = GetFrameIntervalTime(time);
            currFrameData = data.keyframes[currFrame];
            nextFrameData = data.keyframes[(currFrame + 1) % data.numFrames];
            TransformJoint(data.rootJoint, Matrix4x4.identity);
        }
    }

    private int GetJointScaleFactor(BVHJoint joint)
    {
        return joint.name == "Head" ? HeadScale : GeneralScale;
    }
}