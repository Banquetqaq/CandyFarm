using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class TPPhotographer : MonoBehaviour
{
    //绕X轴旋转量
    public float Pitch { get; private set; }
    //绕Y轴旋转量
    public float Yaw { get; private set; }
    //鼠标灵敏度
    public float mouseSensitivity = 3;
    //跟随点的Y轴偏移量
    public float Yoffset = 0.5f;
    //曲线摄像机远近
    [SerializeField]
    private Transform follow;

    void Update()
    {
        transform.position = follow.position + Vector3.up * Yoffset;
        UpdateRotation();
    }

    //摄像机视角旋转
    private void UpdateRotation()
    {
        //鼠标
        Yaw += Input.GetAxis("Mouse X") * mouseSensitivity;
        Pitch -= Input.GetAxis("Mouse Y") * mouseSensitivity;
        //手柄
        //Yaw += Input.GetAxis("Gamepad X") * gamepadSensitivity * Time.deltaTime;
        //Pitch += Input.GetAxis("Gamepad Y") * gamepadSensitivity * Time.deltaTime;
        //角度限制
        Pitch = Mathf.Clamp(Pitch, -30, 78);

        transform.rotation = Quaternion.Euler(Pitch, Yaw, 0);
    }
    
}
