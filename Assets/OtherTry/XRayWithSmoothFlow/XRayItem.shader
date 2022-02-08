Shader "Custom/XRayItem"
{

Properties
	{
		[PerRendererData] _MainTex ("Sprite Texture", 2D) = "white" {}
		_RepeatX("RepeatX", float) = 1
		_RepeatY("RepeatY", float) = 1
		_ViceTex("Texture", 2D) = "white" {}
		_Color ("Tint", Color) = (1,1,1,1)
		[Toggle] UseXRayTex ("Use XRayTex", Float) = 0
		_AlphaClipOffset("Alpha Clip Offset",float) = 0.1
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
				#pragma multi_compile _ PIXELSNAP_ON
				#pragma shader_feature _ USEXRAYTEX_ON
				#include "UnityCG.cginc"

				struct appdata_t
				{
					float4 vertex   : POSITION;
					float4 color    : COLOR;
					float2 texcoord : TEXCOORD0;
				};

				struct v2f
				{
					float4 modelVertex : TEXCOORD1;
					float4 vertex   : SV_POSITION;
					fixed4 color    : COLOR;
					float2 texcoord  : TEXCOORD0;
				};

				fixed4 _Color;

				v2f vert(appdata_t IN)
				{
					v2f OUT;
					OUT.modelVertex = IN.vertex;
					OUT.vertex = UnityObjectToClipPos(IN.vertex);
					OUT.texcoord = IN.texcoord;
					OUT.color = IN.color * _Color;

					return OUT;
				}

				sampler2D _MainTex;
				sampler2D _ViceTex;
				sampler2D _AlphaTex;
				float _AlphaSplitEnabled;
				float _AlphaClipOffset;
				fixed _RepeatX;
				fixed _RepeatY;

				fixed4 SampleSpriteTexture (v2f IN, float viceArea)
				{
					float2 uv = IN.texcoord;
					uv.x += _Time.y / 3;
					uv.x = (uv.x - (int)(uv.x / (1 / _RepeatX)) * (1 / _RepeatX)) * _RepeatX;
					uv.y = (uv.y - (int)(uv.y / (1 / _RepeatY)) * (1 / _RepeatY)) * _RepeatY;

					fixed4 color;
				#if USEXRAYTEX_ON
					if(IN.modelVertex.x < viceArea)
						color = tex2D(_MainTex, uv);
					else
						color = tex2D(_ViceTex, uv);
				#else
					color = tex2D(_MainTex, uv);
				#endif


	#if UNITY_TEXTURE_ALPHASPLIT_ALLOWED
					if (_AlphaSplitEnabled)
						color.a = tex2D(_AlphaTex, uv).r;
	#endif //UNITY_TEXTURE_ALPHASPLIT_ALLOWED

					return color;
				}

				fixed4 frag(v2f IN) : SV_Target
				{
					fixed4 c = SampleSpriteTexture(IN, 0) * IN.color;
					c.rgb *= c.a;
					clip(c.a - _AlphaClipOffset);
					return c;
				}
			ENDCG
		}
	}
}