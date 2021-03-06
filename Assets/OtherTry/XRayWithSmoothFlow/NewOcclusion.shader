Shader "Custom/NewXRayOcclusion"
{

Properties
	{
		[PerRendererData] _MainTex ("Sprite Texture", 2D) = "white" {}
		_Color ("Tint", Color) = (1,1,1,1)
		_XRayTexAlphaClipOffset("Alpha Clip Offset",float)=0.1
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

			return color;
		}

		ENDCG


		Pass
		{
		stencil {
			Ref 100
			Comp Always
			Pass Replace
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
	}
}