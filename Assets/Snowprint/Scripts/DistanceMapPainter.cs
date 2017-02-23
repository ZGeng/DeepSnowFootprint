using UnityEngine;
using System.Collections;

public class DistanceMapPainter : MonoBehaviour {

    public int spriteCounter = 0;

    // Use this for initialization

    void OnEnable()
    {
        footCollide.OnFootCollided += DoAction;
    }


    void OnDisable()
    {
        footCollide.OnFootCollided -= DoAction;
    }


    void Start () {
	
	}

    // Update is called once per frame
    void FixedUpdate()
    {
       
    }

    void DoAction(Vector3 position,float angle)
    {
           GameObject spriteObj;
           spriteObj = (GameObject)Instantiate(Resources.Load("default_sprite"));
           spriteObj.transform.parent = this.transform;
           spriteObj.transform.localPosition = new Vector3(position.x-0.5f,position.z-0.5f,0);
           Color positionInfo = new Color(spriteObj.transform.localPosition.x+0.5f, angle, spriteObj.transform.localPosition.y+0.5f, 1.0f);
           spriteObj.GetComponent<SpriteRenderer>().color = positionInfo; //pass the position info color to sprite shader
           spriteCounter++; 
    }
}
