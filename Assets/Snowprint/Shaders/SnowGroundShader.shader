Shader "Custom/snow_ground"
{
	Properties
	{
		_MainTex("Occulution (RGB)", 2D) = "white" {}
		_NormalMap("Normalmap", 2D) = "bump" {}

		_Color("Color", color) = (1,1,1,0)
		_SpecPow("Metallic", Range(0, 1)) = 0.5
		_GlossPow("Smoothness", Range(0, 1)) = 0.5

		_DistanceFiled("DistanceField",2D) = "black"{}
		_CoverSize("CoverSize",float) = 10.0
		_AnchorPoint("AnchorPoint",Vector) = (0.0,0.0,0.0,1.0)

		_DispTex("Disp Texture", 2D) = "gray" {}
		_DispNormal("Decal Normal", 2D) = "bump" {}
		
		_Displacement("Displacement", Range(0, 5.0)) = 0.3
		_DispOffset("Disp Offset", Range(0, 1)) = 0.5
		_MinEdgeLength("Minimum Edge length", Range(0.01,1)) = 0.1
		_TextureWorldSize("Texture Size in world", Range(0.1,10)) = 0.5

	}

	SubShader
	{
		Tags{ "RenderType" = "Opaque" }
		LOD 300

		Pass
		{
			Name "DEFERRED"
			Tags{ "LightMode" = "Deferred" }

			CGPROGRAM
			// Physically based Standard lighting model, and enable shadows on all light types
			#include "HLSLSupport.cginc"
			#include "UnityCG.cginc"
			#include "UnityShaderVariables.cginc"
			#include "Tessellation.cginc"
			#include "Lighting.cginc"
			#include "UnityPBSLighting.cginc"

			#define EPS  0.045 //define the EPS
			#define DISTANCE_RANGE 0.03//define the tessellation distance range

			#pragma vertex vs 
			#pragma fragment fs
			#pragma hull hs
			#pragma domain ds
			#pragma geometry gs
			#pragma multi_compile_prepassfinal
			#pragma target 5.0



			////HELPER FUNCTIONS


			//sample distancefield map data this function will be called in vs/ds/fs shader in total 3 times
			inline float4 distData(sampler2D distanceField, float3 worldPosition, float4 anchorPoint, float coverSize )
			{ 
				float2 relativePos = (worldPosition.xz - anchorPoint.xz) /coverSize;
				return tex2Dlod(distanceField,float4(relativePos,0.0f,0.0f)); 
			} 

			//helper function to clip the uv into the (0,1)range
			inline float2 clipRect(float2 rect) {
				int sx = step(0, rect.x)*step(rect.x, 1);
				int sy = step(0, rect.y)*step(rect.y, 1);
				int sxy = sx*sy;
				return float2(rect.x * sxy, rect.y * sxy);
			}


			///DATA STRUCTURES
			struct appdata
			{
				float4 vertex : POSITION;
				float4 tangent : TANGENT;
				float3 normal : NORMAL;
				float2 texcoord : TEXCOORD0;
				float2 texcoord1 : TEXCOORD1;
				float2 texcoord2 : TEXCOORD2;

			};

			struct HS_INPUT
			{
				float4 vertex : INTERNALTESSPOS;
				float4 tangent : TANGENT;
				float3 normal : NORMAL;
				float2 texcoord : TEXCOORD0;
				float2 texcoord1 : TEXCOORD1;
				float2 texcoord2 : TEXCOORD2;
				float3 worldPos : TEXCOORD3;
				float distanceData : TEXCOORD4;
			};

			struct HS_PER_PATCH_OUTPUT
			{
				float edges[3]  : SV_TessFactor;
				float inside : SV_InsideTessFactor;
			};

			struct DS_INPUT
			{
				float4 vertex : INTERNALTESSPOS;
				float4 tangent : TANGENT;
				float3 normal : NORMAL;
				float2 texcoord : TEXCOORD0;
				float2 texcoord1 : TEXCOORD1;
				float2 texcoord2 : TEXCOORD2;
				float3 worldPos : TEXCOORD3;
			};

			struct GS_INPUT
			{
				float4 vertex : POSITION;
				float3 worldPos: TEXCOORD0;
				half3 tspace0 : TEXCOORD1;
				half3 tspace1 : TEXCOORD2;
				half3 tspace2 : TEXCOORD3;
				float2 uv : TEXCOORD4;
				float2 detailuv : TEXCOORD5; 
			};

			struct PS_INPUT
			{
				float4 vertex : SV_POSITION;
				float3 worldPos : TEXCOORD0;
				half3 tspace0 : TEXCOORD1;
				half3 tspace1 : TEXCOORD2;
				half3 tspace2 : TEXCOORD3;
				float2 uv : TEXCOORD4;
				float2 detailuv : TEXCOORD5;
				//float uvdiscard : TEXCOORD6;

			};

			struct PS_OUTPUT
			{
				half4 outDiffuse: SV_Target0;
				half4 outSpecular : SV_Target1;
				half4 outNormal : SV_Target2;
				half4 outEmission : SV_Target3;
			};



			
			sampler2D _DistanceFiled;
			float _CoverSize;
			float4 _AnchorPoint;
			///Vertex Shader
			HS_INPUT vs(appdata i)
			{
				HS_INPUT o;

				o.vertex = i.vertex;
				o.tangent = i.tangent;
				o.normal = i.normal;
				o.texcoord = i.texcoord;
				o.texcoord1 = i.texcoord1;
				o.texcoord2 = i.texcoord2;
				o.worldPos = mul(unity_ObjectToWorld,i.vertex).xyz;
				//call distData to get information from texture
				float4 distanceData_full = distData(_DistanceFiled,o.worldPos,_AnchorPoint,_CoverSize);
				float2 relativePos = (o.worldPos.xz - _AnchorPoint.xz) / _CoverSize;
				o.distanceData = distance(distanceData_full.xz, relativePos);
				return o;
			}



			float _MinEdgeLength;
			float _TextureWorldSize;

			// tessellation hull constant shader
			HS_PER_PATCH_OUTPUT hsconst(InputPatch<HS_INPUT,3> v) {
				HS_PER_PATCH_OUTPUT o;
				float3 worldPos0 = mul(unity_ObjectToWorld, v[0].vertex).xyz;
				float3 worldPos1 = mul(unity_ObjectToWorld, v[1].vertex).xyz;
				float3 worldPos2 = mul(unity_ObjectToWorld, v[2].vertex).xyz;
				float factor0 = distance(worldPos1, worldPos2) / _MinEdgeLength;
				float factor1 = distance(worldPos2, worldPos0) / _MinEdgeLength;
				float factor2 = distance(worldPos0, worldPos1) / _MinEdgeLength;
				factor0 *= step(v[0].distanceData, DISTANCE_RANGE);
				factor1 *= step(v[1].distanceData, DISTANCE_RANGE);
				factor2 *= step(v[2].distanceData, DISTANCE_RANGE);
				float factor = max(1.f,(factor0 + factor1 + factor2) / 3.f);
				o.edges[0] = factor;
				o.edges[1] = factor;
				o.edges[2] = factor;
				o.inside = (o.edges[0] + o.edges[1] + o.edges[2]) / 3;
				return o;
			}
			// tessellation hull shader
			[UNITY_domain("tri")]
			[UNITY_partitioning("integer")]
			[UNITY_outputtopology("triangle_cw")]
			[UNITY_patchconstantfunc("hsconst")]
			[UNITY_outputcontrolpoints(3)]



			DS_INPUT hs(InputPatch<HS_INPUT, 3> i, uint pointID : SV_OutputControlPointID, uint PatchID : SV_PrimitiveID)
			{
				DS_INPUT o;
				o.vertex = i[pointID].vertex;
				o.normal = i[pointID].normal;
				o.tangent = i[pointID].tangent;
				o.texcoord = i[pointID].texcoord;
				o.texcoord1 = i[pointID].texcoord1;
				o.texcoord2 = i[pointID].texcoord2;
				o.worldPos =i[pointID].worldPos;
				return o;
			}


			sampler2D _DispTex;
			float _Displacement;
			float _DispOffset;


			[domain("tri")]
			GS_INPUT ds(HS_PER_PATCH_OUTPUT i,const OutputPatch<DS_INPUT, 3> vi, float3 bary : SV_DomainLocation)
			{
				GS_INPUT o;

				o.vertex = vi[0].vertex*bary.x + vi[1].vertex*bary.y + vi[2].vertex*bary.z;
				o.worldPos = vi[0].worldPos*bary.x + vi[1].worldPos*bary.y +vi[2].worldPos*bary.z;
				float3 normal = vi[0].normal*bary.x + vi[1].normal*bary.y + vi[2].normal*bary.z;
				float4 tangent = vi[0].tangent*bary.x +vi[1].tangent*bary.y + vi[2].tangent*bary.z;
				o.uv = vi[0].texcoord*bary.x + vi[1].texcoord*bary.y + vi[2].texcoord*bary.z;
				

				//distance data need to resample 
				float2 relativePos = o.worldPos.xz - _AnchorPoint.xz;
				float4 distanceData = distData(_DistanceFiled,o.worldPos,_AnchorPoint,_CoverSize);
				float displaceAmount = _Displacement*distanceData.a;
				// start to deform the vertex position 
				// get the center position xz// data y is the angle/2pi data
				float2 centerPos = distanceData.xz * _CoverSize;
				float angle = (distanceData.y * 2.0f -1.5f) * 3.1416f;
				
				relativePos -= centerPos;

				float cosine = cos(angle);
				float sine = sin(angle);
				float2 rotatedPos = float2(relativePos.x*cosine - relativePos.y*sine, relativePos.y*cosine + relativePos.x*sine);
				//calculat the uv used to sample the height map
				
				float2 heightUV = clipRect(rotatedPos / _TextureWorldSize + float2(0.5f, 0.5f));
				o.detailuv = heightUV; //ouput the detailed uv
				//sample the height map
				float d = (tex2Dlod(_DispTex, float4(heightUV, 0, 0)).r - 0.5)* displaceAmount + _DispOffset;
				o.vertex.y += d; //displace along the y direction


				//reconstruct the normal and tangent value
				float3 wNormal = UnityObjectToWorldNormal(normal);
				float3 wTangent = UnityObjectToWorldDir(tangent.xyz);
				float tangentSign = tangent.w*unity_WorldTransformParams.w;
				float3 wBitangent = cross(wNormal, wTangent) * tangentSign;

				float3 pointAtBitangent_world = o.worldPos + wBitangent*EPS;
				float3 pointAtTangent_world = o.worldPos + wTangent*EPS;

				float2 pointAtBitangent_relative = pointAtBitangent_world.xz - _AnchorPoint.xz - centerPos;
				float2 pointAtTangent_relative = pointAtTangent_world.xz - _AnchorPoint.xz -centerPos;

				float2 pointAtBitangent_rotated = float2(pointAtBitangent_relative.x*cosine - pointAtBitangent_relative.y*sine, 
					pointAtBitangent_relative.y*cosine + pointAtBitangent_relative.x*sine);
				float2 pointAtTangent_rotated = float2(pointAtTangent_relative.x*cosine - pointAtTangent_relative.y*sine, 
					pointAtTangent_relative.y*cosine + pointAtTangent_relative.x*sine);

				float2 uvAtBitanget = clipRect(pointAtBitangent_rotated / _TextureWorldSize + float2(0.5f, 0.5f));
				float2 uvAtTangent = clipRect(pointAtTangent_rotated / _TextureWorldSize + float2(0.5f, 0.5f));

				float dAtBitangent = (tex2Dlod(_DispTex, float4(uvAtBitanget, 0, 0)).r-0.5) * displaceAmount + _DispOffset;
				float dAtTangent = (tex2Dlod(_DispTex, float4(uvAtTangent, 0, 0)).r -0.5)* displaceAmount + _DispOffset;

				pointAtBitangent_world.y +=dAtBitangent;
				pointAtTangent_world.y += dAtTangent;

				//new tangent direction 
				float3 new_worldPos = mul(unity_ObjectToWorld, o.vertex).xyz;
				float3 new_wTangent = normalize(pointAtTangent_world - new_worldPos);
				float3 new_wBitangent = normalize(pointAtBitangent_world - new_worldPos);
				float3 new_wNormal = tangentSign*cross(new_wTangent, new_wBitangent);

				o.tspace0 = half3(new_wTangent.x, new_wBitangent.x, new_wNormal.x);
				o.tspace1 = half3(new_wTangent.y, new_wBitangent.y, new_wNormal.y);
				o.tspace2 = half3(new_wTangent.z, new_wBitangent.z, new_wNormal.z);
			
				o.worldPos = new_worldPos;
				return o;
			}



			//in the gs, to calculate the uv of the 3 point and discard the value if its difference is huge ( the edge condition)
			[maxvertexcount(3)]
			void gs( triangle GS_INPUT input[3], inout TriangleStream<PS_INPUT> stream)
			{
				PS_INPUT o[3];
				float difference = max(max(distance(input[0].detailuv,input[1].detailuv),distance(input[1].detailuv,input[2].detailuv)),distance(input[0].detailuv,input[2].detailuv));
				float discardFactor = step(difference,0.25); //temprary


				for(int i = 0; i < 3; i++)
				{  
					//apply model view projection 
					o[i].vertex = mul(UNITY_MATRIX_MVP,input[i].vertex);  
					o[i].uv = input[i].uv;
					o[i].detailuv =input[i].detailuv * discardFactor;
					o[i].tspace0 = input[i].tspace0;
					o[i].tspace1 = input[i].tspace1;
					o[i].tspace2 = input[i].tspace2;
					o[i].worldPos = input[i].worldPos;
					stream.Append(o[i]);
				}
			}



			sampler2D _NormalMap;//defind the normalmap
			float4  _NormalMap_ST;
			sampler2D _DispNormal;
			fixed4 _Color;
			half _SpecPow;//metalic
			half _GlossPow;//smoothness
			sampler2D _MainTex;
			float4  _MainTex_ST;


			PS_OUTPUT fs(PS_INPUT i)

			{
				PS_OUTPUT o;

				half3 tnormal = UnpackNormal(tex2D(_NormalMap,i.uv*_NormalMap_ST.xy));
				half3 tnormal_decal = UnpackNormal(tex2D(_DispNormal,i.detailuv));
				half3 tnormal_sum = normalize(tnormal + tnormal_decal); //add two normal together
				half3 worldNormal;

				worldNormal.x = dot(i.tspace0,tnormal_sum);
				worldNormal.y = dot(i.tspace1,tnormal_sum);
				worldNormal.z = dot(i.tspace2,tnormal_sum);

				o.outNormal = half4(worldNormal,0);

				float3 worldPos = i.worldPos;
				//setup the light environment

				#ifndef USING_DIRECTIONAL_LIGHT
				fixed3 lightDir = normalize(UnityWorldSpaceLightDir(worldPos));
				#else
				fixed3 lightDir = _WorldSpaceLightPos0.xyz;
				#endif

				fixed3 worldViewDir = normalize(UnityWorldSpaceViewDir(worldPos));

				SurfaceOutputStandard s; //create a surfaceouput 

				//initialize the output value
				//	fixed3 Albedo;		// base (diffuse or specular) color
				//  fixed3 Normal;		// tangent space normal, if written
				//  half3 Emission;
				//  half Metallic;		// 0=non-metal, 1=metal
				//  half Smoothness;	// 0=rough, 1=smooth
				//  half Occlusion;		// occlusion (default 1)
				//  fixed Alpha;		// alpha for transparencies


				s.Albedo = _Color.rgb;
				s.Normal = o.outNormal;
				s.Emission = 0.0;
				s.Alpha = 1.0;
				s.Metallic = _SpecPow;
				s.Smoothness = _GlossPow;
				//s.Occlusion = tex2D(_MainTex, i.uv*_MainTex_ST.xy).r*_Color.a;
				s.Occlusion = tex2D(_MainTex, i.detailuv).r;


				// Setup lighting environment
				half atten = 1;
				UnityGI gi;
				UNITY_INITIALIZE_OUTPUT(UnityGI, gi);
				gi.indirect.diffuse = 0;
				gi.indirect.specular = 0;
				gi.light.color = 0;
				gi.light.dir = half3(0, 1, 0);
				gi.light.ndotl = LambertTerm(worldNormal, gi.light.dir); //the surface ouput normal 
				// Call GI (lightmaps/SH/reflections) lighting function
				UnityGIInput giInput;
				UNITY_INITIALIZE_OUTPUT(UnityGIInput, giInput);
				giInput.light = gi.light;
				giInput.worldPos = worldPos;
				giInput.worldViewDir = worldViewDir;
				giInput.atten = atten;

				giInput.lightmapUV = 0.0;
				giInput.ambient.rgb = 0.0;

				giInput.probeHDR[0] = unity_SpecCube0_HDR;
				giInput.probeHDR[1] = unity_SpecCube1_HDR;
				#if UNITY_SPECCUBE_BLENDING || UNITY_SPECCUBE_BOX_PROJECTION
				giInput.boxMin[0] = unity_SpecCube0_BoxMin;
				#endif
				#if UNITY_SPECCUBE_BOX_PROJECTION
				giInput.boxMax[0] = unity_SpecCube0_BoxMax;
				giInput.probePosition[0] = unity_SpecCube0_ProbePosition;
				giInput.boxMax[1] = unity_SpecCube1_BoxMax;
				giInput.boxMin[1] = unity_SpecCube1_BoxMin;
				giInput.probePosition[1] = unity_SpecCube1_ProbePosition;
				#endif

				LightingStandard_GI(s, giInput, gi);

				// call lighting function to output g-buffer
				o.outEmission = LightingStandard_Deferred(s, worldViewDir, gi, o.outDiffuse, o.outSpecular, o.outNormal);
				#ifndef UNITY_HDR_ON
				o.outEmission.rgb = exp2(-o.outEmission.rgb);
				#endif
				UNITY_OPAQUE_ALPHA(o.outDiffuse.a);

				return o;
			}


			ENDCG
		}
	}

	FallBack "Diffuse"

}
