Shader "Unlit/UIPlaneCloudShader2"
{
	Properties
	{
		_MainTex ("Texture", 2D) = "white" {}
        

        [Header(Main Cloud Settings)]
        _BaseNoise("Base Noise", 2D) = "black" {}
        _Distort("Distort", 2D) = "black" {}
        _SecNoise("Secondary Noise", 2D) = "black" {}
        _BaseNoiseScale("Base Noise Scale",  Range(0, 1)) = 0.2
        _DistortScale("Distort Noise Scale",  Range(0, 1)) = 0.06
        _SecNoiseScale("Secondary Noise Scale",  Range(0, 1)) = 0.05
        _Distortion("Extra Distortion",  Range(0, 1)) = 0.1
        _Speed("Movement Speed",  Range(0, 10)) = 1.4
        _CloudCutoff("Cloud Cutoff",  Range(0, 1)) = 0.3
        _Fuzziness("Cloud Fuzziness",  Range(0, 1)) = 0.04
        _FuzzinessUnder("Cloud Fuzziness Under",  Range(0, 1)) = 0.01
        _HorizenHeight("地平线高度",Range(0,3)) = 0
        _YScale("Y方向放缩",Range(0.1,3)) = 1

        [Header(Day Clouds Settings)]
        _CloudColorDayEdge("Clouds Edge Day", Color) = (0,0,0,1)
        _CloudColorDayMain("Clouds Main Day", Color) = (0.8,0.9,0.8,1)
        _CloudColorDayUnder("Clouds Under Day", Color) = (0.6,0.7,0.6,1)
	}
	SubShader
	{
		Tags { "RenderType"="Opaque" }
		LOD 100

		Pass
		{
			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			// make fog work
			//#pragma multi_compile_fog
			
			#include "UnityCG.cginc"

			struct appdata
			{
				float4 vertex : POSITION;
				float2 uv : TEXCOORD0;
			};

			struct v2f
			{
				float2 uv : TEXCOORD0;
				float4 vertex : SV_POSITION;
                float3 worldPos : TEXCOORD1;
                UNITY_FOG_COORDS(1)
			};

			sampler2D _MainTex;
            sampler2D _Stars, _BaseNoise, _Distort, _SecNoise;
            float _BaseNoiseScale, _DistortScale, _SecNoiseScale, _Distortion,_YScale;
            float _Speed, _CloudCutoff, _Fuzziness, _FuzzinessUnder;
            float4 _CloudColorDayEdge, _CloudColorDayMain, _CloudColorDayUnder;
            float _HorizenHeight;
            
			float4 _MainTex_ST;
			
			v2f vert (appdata v)
			{
				v2f o;
				o.vertex = UnityObjectToClipPos(v.vertex);
				o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                o.worldPos = mul(unity_ObjectToWorld, v.vertex);
				UNITY_TRANSFER_FOG(o,o.vertex);
				return o;
			}
			
			fixed4 frag (v2f i) : SV_Target
			{
                float2 skyUV = i.uv.xy ;/// (i.uv.y + _HorizenHeight);
                skyUV.x = 0.5 + (skyUV.x - 0.5)/((skyUV.y + 0.2) *0.5);
                skyUV.y /= _YScale;

                float baseNoise = tex2D(_BaseNoise, (skyUV - _Time.x) * _BaseNoiseScale).x;
                float noise1 = tex2D(_Distort, ((skyUV + baseNoise) - (_Time.x * _Speed)) * _DistortScale);

                float noise2 = tex2D(_SecNoise, ((skyUV + (noise1 * _Distortion)) - (_Time.x * (_Speed * 0.5))) * _SecNoiseScale);
				float finalNoise = saturate(noise1 * noise2) * 3 * saturate(i.uv.y +_HorizenHeight ) ;

                
                float clouds = saturate(smoothstep(_CloudCutoff, _CloudCutoff + _Fuzziness, finalNoise)) * 0.1 + 0.9;
                float cloudsunder = saturate(smoothstep(_CloudCutoff, _CloudCutoff + _Fuzziness + _FuzzinessUnder , noise2) * clouds)*0.8;

                float3 cloudsColored = lerp(_CloudColorDayEdge, lerp(_CloudColorDayUnder, _CloudColorDayMain, cloudsunder), clouds);

                                
				// apply fog
				//UNITY_APPLY_FOG(i.fogCoord, cloudsColored);
                float col = float4(cloudsColored,1);

                
				return float4(cloudsColored,1);
			}
			ENDCG
		}
	}
}
