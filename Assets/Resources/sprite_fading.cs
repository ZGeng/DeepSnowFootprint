using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class sprite_fading : MonoBehaviour {


    SpriteRenderer spriteRenderer;
    public float lifeSpan = 30.0f;
    public float alpha = 1.0f;
    public float life;

    // Use this for initialization
    void Start () {
      spriteRenderer = GetComponent<SpriteRenderer>();
        life = lifeSpan;
      
    }
	
	// Update is called once per frame
	void Update () {
        life -= Time.deltaTime;
        if (life <= 0.0f)
        {
            Destroy(gameObject);
        }
        else
        {
            alpha = life / lifeSpan;
            spriteRenderer.color = new Color(spriteRenderer.color.r, spriteRenderer.color.g, spriteRenderer.color.b, alpha);
        }
    }
}
