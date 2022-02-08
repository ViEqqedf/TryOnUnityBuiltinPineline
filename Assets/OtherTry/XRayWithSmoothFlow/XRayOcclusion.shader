Shader "Custom/XRayOcclusion"
{

Properties
	{
		[PerRendererData] _MainTex ("Sprite Texture", 2D) = "white" {}
		_Color ("Tint", Color) = (1,1,1,1)
		[Toggle] UseXRayTex ("Use XRayTex", Float) = 0
		_XRayTexAlphaClipOffset("Alpha Clip Offset",float)=0.1
		_XRayTex("X Ray Texture",2D)="white"{}
		_XRayColor("X Ray Color",Color)=(1,1,1,1)
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
		ZWrite Off
		Blend One OneMinusSrcAlpha

		CGINCLUDE
		#include "UnityCG.cginc"

		struct appdata_t
		{
			float4 vertex   : POSITION;
			float4 color    : COLOR;
			float2 texcoord : TEXCOORD0;
		};

		struct v2f
		{
			float4 pos : SV_POSITION;
			fixed4 color : COLOR;
			float2 texcoord : TEXCOORD0;
			float2 worldUV : TEXCOORD1;
		};

		fixed4 _Color;

		v2f vert(appdata_t i)
		{
			v2f o;
			o.pos = UnityObjectToClipPos(i.vertex);
			o.texcoord = i.texcoord;
			o.color = i.color * _Color;
			o.worldUV = mul(unity_ObjectToWorld, i.vertex).xy;

			return o;
		}

		sampler2D _MainTex;
		sampler2D _AlphaTex;
		float _AlphaSplitEnabled;

		fixed4 SampleSpriteTexture (float2 uv)
		{
			fixed4 color = tex2D (_MainTex, uv);

#if UNITY_TEXTURE_ALPHASPLIT_ALLOWED
			if (_AlphaSplitEnabled)
				color.a = tex2D (_AlphaTex, uv).r;
#endif //UNITY_TEXTURE_ALPHASPLIT_ALLOWED

			return color;
		}

		ENDCG


		Pass
		{
		stencil {
			Ref 99
			Comp Greater
		}
		CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			fixed4 frag(v2f i) : SV_Target
			{
				fixed4 c = SampleSpriteTexture (i.texcoord) * i.color;
				c.rgb *= c.a;
				return c;
			}
		ENDCG
		}

		Pass
		{
			stencil {
				Ref 100
				Comp Equal
				Pass IncrSat
			}
			blend SrcAlpha OneMinusSrcAlpha

			CGPROGRAM
				#pragma vertex vert
				#pragma fragment frag
				//宏必须大写
				#pragma shader_feature _ USEXRAYTEX_ON

				fixed4 _XRayColor;
				sampler2D _XRayTex;
				float4 _XRayTex_ST;
				float _XRayTexAlphaClipOffset;

				fixed4 frag(v2f i) : SV_Target
				{
					fixed4 spriteTex = SampleSpriteTexture (i.texcoord);
					clip(spriteTex.a - _XRayTexAlphaClipOffset);
					#if USEXRAYTEX_ON
						float2 uv = TRANSFORM_TEX(i.worldUV, _XRayTex);
						fixed4 color = tex2D(_XRayTex, uv) * _XRayColor;
						return color;
					#else
						fixed4 color = spriteTex * i.color * _XRayColor;
						return color;
					#endif
				}

			ENDCG
		}
	}
}