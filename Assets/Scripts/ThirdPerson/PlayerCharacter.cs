
using UnityEngine;


public class PlayerCharacter : MonoBehaviour
{
    [SerializeField]  private TPPhotographer photographer;//摄像机

    [SerializeField] private float gravity = -9.81f;

    [SerializeField] private float jumpForce;
    //最大移速 
    public float MaxWalkSpeed = 3;

    //用于移动的组件
    private CharacterController characterController;

    private Vector3 velocity;
    private Vector3 CurrentInput;
    private void Awake()
    {
        //取得用于移动的组件
        characterController = GetComponent<CharacterController>();
    }

    void Update()
    {
        Quaternion rot = Quaternion.Euler(0, photographer.Yaw, 0);
        CurrentInput = Vector3.Slerp(CurrentInput, rot * Vector3.forward * Input.GetAxis("Vertical") + rot * Vector3.right * Input.GetAxis("Horizontal"), Time.deltaTime * 20);
        if (CurrentInput != Vector3.zero)
        {
            characterController.Move(CurrentInput * MaxWalkSpeed * Time.deltaTime);
            transform.rotation = Quaternion.Slerp(transform.rotation, Quaternion.LookRotation(CurrentInput), Time.deltaTime * 10);
        }

        if (characterController.isGrounded && velocity.y < 0)
        {
            velocity.y = -2f;
        }

        if (Input.GetKey(KeyCode.Space) && characterController.isGrounded)
        {
            velocity.y = Mathf.Sqrt(jumpForce * -2f * gravity);
        }
        velocity.y += gravity * Time.deltaTime;
        characterController.Move(velocity * Time.deltaTime);

    }
}
