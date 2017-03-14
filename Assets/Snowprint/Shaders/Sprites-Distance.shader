Shader "Sprites/Distance"
{
	Properties
	{
		[PerRendererData] _MainTex ("Sprite Texture", 2D) = "white" {}
		//_Color ("Tint", Color) = (1,1,1,1)
		//[MaterialToggle] PixelSnap ("Pixel snap", Float) = 0
	}

	SubShader
	{
		Tags
		{ 
			"Queue"="Transparent" 
			"IgnoreProjector"="True" 
			"RenderType"="Transparent" 
			"PreviewType"="Plane"
			"CanUseSpriteAtlas"="True"
		}

		Cull Off
		Lighting Off
		ZWrite On //open ZWreite
		ZTest LEqual
		//Blend OneOne
		Blend One Zero

		Pass
		{
		CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			//#pragma shader_feature ETC1_EXTERNAL_ALPHA
			#include "UnityCG.cginc"
			
			struct appdata_t
			{
				float4 vertex   : POSITION;
				float4 color    : COLOR;
				float2 texcoord : TEXCOORD0;
			};

			struct v2f
			{
				float4 vertex   : SV_POSITION;
				fixed4 color    : COLOR;
				float2 texcoord  : TEXCOORD0;
			};

			struct fout
			{
				fixed4 color : SV_Target;
				float depth : SV_Depth;  
			};
			


			v2f vert(appdata_t IN)
			{
				v2f OUT;
				OUT.vertex = mul(UNITY_MATRIX_MVP, IN.vertex);
				OUT.texcoord = IN.texcoord;
				OUT.color = IN.color;
				return OUT;
			}


			fout frag(v2f IN)
			{
				fout OUT;
				

				OUT.color.rgb = IN.color.rgb;////r,g is the relative center position b is angle

				float dist = distance(IN.texcoord, float2(.5f, .5f))*2.0f;
				OUT.color.a = IN.color.a;
				OUT.depth = 1.0f-dist;
				
				return OUT;
			}
		ENDCG
		}
	}
}
