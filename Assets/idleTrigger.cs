using UnityEngine;
using System.Collections;

public class idleTrigger : MonoBehaviour {

    float previousForward;
    float ESP = 0.4f;
   // bool idle;
    Animator animControl;
	// Use this for initialization
	void Start () {
        animControl = GetComponent<Animator>();
        previousForward = 0.0f;
	}
	
	// Update is called once per frame
	void Update () {
        float forward = animControl.GetFloat("Forward");
        //Debug.Log(forward.ToString());
        if (previousForward>ESP && forward<=ESP)
        {
            Debug.Log("idle");
        }
        previousForward = forward;
        
	}
}
