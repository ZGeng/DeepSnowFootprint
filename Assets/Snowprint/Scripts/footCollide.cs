using UnityEngine;
using System.Collections;

public class footCollide : MonoBehaviour {
    //add event manager to this class
    public delegate void OnFootCollision(Vector3 positon,float angle);
    public static event OnFootCollision OnFootCollided;
    public GameObject controller;
    public Animator animControl;
    float previousForward;
    float currentForward;
    float ESP = 0.35f;
    bool onIdle;

    // Use this for initialization
    void Start () {

        previousForward = 0.0f;
        onIdle = true;
        controller = GameObject.Find("ThirdPersonController");
        if (controller != null)
        {
            animControl = controller.GetComponent<Animator>();
        }
	}
	

    void OnTriggerEnter(Collider other)
    {
        if (other.tag== "foot")
        {
            Vector3 position = other.transform.position/40.0f;//40.0 is the size of the terrain
            //Debug.Log(position.ToString());
            float angle = (other.transform.rotation.eulerAngles.y)/360.0f; //map into range 0-1
                                                                           //Debug.Log(angle.ToString());
            //call the event manager
            OnFootCollided(position, angle);
            //play sound 
            controller.GetComponent<AudioSource>().Play();
        }
    }

    void OnTriggerStay(Collider other)
    {
        if(other.tag == "foot" && onIdle == true)
        {
            Vector3 position = other.transform.position / 40.0f;//20.0 is the size of the terrain
            //Debug.Log(position.ToString());
            float angle = (other.transform.rotation.eulerAngles.y) / 360.0f; //map into range 0-1
                                                                             //Debug.Log(angle.ToString());
                                                                             //call the event manager
            OnFootCollided(position, angle);
        }

    }




	// Update is called once per frame
	void Update () {
        currentForward = animControl.GetFloat("Forward");
        if (previousForward > ESP && currentForward <= ESP)
        {
            onIdle = true;
        }
        else
        {
            onIdle = false;
        }
        previousForward = currentForward;
    }
}
