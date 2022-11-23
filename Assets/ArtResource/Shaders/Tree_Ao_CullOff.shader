Shader "SyntyStudios/Tree_Ao_CullOff1"
{
    Properties
    {
        _Emission("Emission", 2D) = "white" {}
		_MainTexture("_MainTexture", 2D) = "white" {}
		_ColorTint("_ColorTint", Color) = (0,0,0,0)
		_EmissionColor("EmissionColor", Color) = (0,0,0,0)
		_Tree_NoiseTexture("Tree_NoiseTexture", 2D) = "white" {}
		_Big_Wave("Big_Wave", Range( 0 , 10)) = 0
		_Big_Windspeed("Big_Windspeed", Float) = 0
		_Big_WindAmount("Big_WindAmount", Float) = 1
		_Leaves_NoiseTexture("Leaves_NoiseTexture", 2D) = "white" {}
		_Small_Wave("Small_Wave", Range( 0 , 10)) = 0
		_Small_WindSpeed("Small_WindSpeed", Float) = 0
		_Small_WindAmount("Small_WindAmount", Float) = 1
		_Cutoff( "Mask Clip Value", Float ) = 0.5
		_AOTexture("AOTexture", 2D) = "white" {}
		_AOPower("AOPower", Range( 0.1 , 3)) = 1
		_EdgeLitRate ("Edge Light Rate", range(0,2))= 0.3
		_LightInt("LightInt", float) = 1.0

		// back light sss
        _InteriorColor ("Interior Color", Color) = (1,1,1,1)
		_ShadowColor ("Shadow Color", Color) = (1,1,1,1)
		_ShadowStr("Shadow Strength", Float) = 1
        _BackSubsurfaceDistortion ("Back Subsurface Distortion", Range(0,1)) = 0.5
        _LitIncr ("Light Increment",Vector) = (0,0,0,0)

		//[HideInInspector] _texcoord2( "", 2D ) = "white" {}
		//[HideInInspector] _texcoord( "", 2D ) = "white" {}
		//[HideInInspector] __dirty( "", Int ) = 1
    }
    SubShader
    {
        Tags{ "RenderType" = "Opaque" "Queue" = "AlphaTest+0" "IgnoreProjector" = "True" "DisableBatching" = "True" "IsEmissive" = "true"  }

        Pass
        {
            Cull Off
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            // make fog work
            #pragma multi_compile_fog

            #include "AutoLight.cginc"
            #include "Lighting.cginc"
            #pragma multi_compile_fwdbase_fullshadows
            #include "UnityCG.cginc"

            uniform float _Small_WindAmount;
		    uniform sampler2D _Leaves_NoiseTexture;
		    uniform float _Small_WindSpeed;
		    uniform float _Small_Wave;
		    uniform float _Big_WindAmount;
		    uniform sampler2D _Tree_NoiseTexture;
		    uniform float _Big_Windspeed;
		    uniform float _Big_Wave;
		    uniform sampler2D _MainTexture;
		    uniform float4 _MainTexture_ST;
		    uniform float4 _ColorTint;
		    uniform sampler2D _AOTexture;
		    uniform float4 _AOTexture_ST;
		    uniform float _AOPower;
		    uniform sampler2D _Emission;
		    uniform float4 _Emission_ST;
		    uniform float4 _EmissionColor;
		    uniform float _Cutoff = 0.5;
		    uniform float _LightInt;
		    //uniform float _BackSubsurfaceDistortion;
		    uniform float _EdgeLitRate,_BackSubsurfaceDistortion,_ShadowStr;
		    uniform float4 _LitIncr,_InteriorColor,_ShadowColor;

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
                //float3 normal : NORMAL;
                float3 color : COLOR;
            };

            struct v2f
            {
                float4 vertex : SV_POSITION;
                float2 uv_texcoord : TEXCOORD0;
			    float2 uv2_texcoord2 : TEXCOORD1;
			    float4 posWorld : TEXCOORD2;
			    float3 normalDir : TEXCOORD3;
                float3 lightDir : TEXCOORD4;
                float3 viewDir : TEXCOORD5;
                //float3 vertexColor : TEXCOORD6;
                UNITY_FOG_COORDS(6)
            };

            float4 CalculateContrast( float contrastValue, float4 colorTarget )
		    {
			    float t = 0.5 * ( 1.0 - contrastValue );
			    return mul( float4x4( contrastValue,0,0,t, 0,contrastValue,0,t, 0,0,contrastValue,t, 0,0,0,1 ), colorTarget );
		    }

            v2f vert (appdata v)
            {
                //UNITY_INITIALIZE_OUTPUT( Input, o );
                v2f o;
                //o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv_texcoord = v.uv;
                o.uv2_texcoord2 = v.uv;
			    o.posWorld = mul(unity_ObjectToWorld, v.vertex);
                
                o.viewDir = normalize(_WorldSpaceCameraPos.xyz - o.posWorld.xyz);
                o.lightDir = normalize(_WorldSpaceLightPos0.xyz);

                o.normalDir = normalize(UnityObjectToWorldNormal(v.vertex)); // sphere normal
			    float3 ase_vertex3Pos = v.vertex.xyz;
			    float2 temp_cast_0 = (( ( ase_vertex3Pos.x + ( _Time.y * _Small_WindSpeed ) ) / ( 1.0 - _Small_Wave ) )).xx;
			    float lerpResult143 = lerp( tex2Dlod( _Leaves_NoiseTexture, float4( temp_cast_0, 0, 0.0) ).r , 0.0 , v.color.r);
			    float3 appendResult160 = (float3(lerpResult143 , 0.0 , 0.0));
			    float2 temp_cast_2 = ((( _Time.y * _Big_Windspeed ) / ( 1.0 - _Big_Wave ) )).xx;
			    float lerpResult170 = lerp( ( _Big_WindAmount * tex2Dlod( _Tree_NoiseTexture, float4( temp_cast_2, 0, 0.0) ).r ) , 0.0 , v.color.b);
			    float3 appendResult172 = (float3(lerpResult170 , 0.0 , 0.0));
			    v.vertex.xyz += ( CalculateContrast(_Small_WindAmount,float4( (appendResult160).xz, 0.0 , 0.0 )) + float4( (appendResult172).xz, 0.0 , 0.0 ) ).rgb;
                o.vertex = UnityObjectToClipPos(v.vertex);

                UNITY_TRANSFER_FOG(o,o.vertex);
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                float2 uv_MainTexture = i.uv_texcoord * _MainTexture_ST.xy + _MainTexture_ST.zw;
			    float4 tex2DNode2 = tex2D( _MainTexture, uv_MainTexture );
			    float2 uv2_AOTexture = i.uv2_texcoord2 * _AOTexture_ST.xy + _AOTexture_ST.zw;
			    float2 uv_Emission = i.uv_texcoord * _Emission_ST.xy + _Emission_ST.zw;
			    //o.Albedo = ( tex2DNode2 * _ColorTint * ( tex2D( _AOTexture, uv2_AOTexture ).g * _AOPower ) ).rgb;
			    float3 Emission = (tex2D( _Emission, uv_Emission ) * _EmissionColor * saturate(tex2D(_AOTexture, uv2_AOTexture).g + _AOPower)).rgb;
			    float3 emiss = Emission;
			    float ndotl = dot(i.normalDir,i.lightDir);

			    //Emission *= max(0,(ndotl * 0.5 + 0.5));
			    // back light sss
                float3 backLitDir = i.normalDir * _BackSubsurfaceDistortion + _LitIncr.xyz;
                float backSSS = saturate(dot(i.viewDir, -backLitDir));
                backSSS = saturate(pow(backSSS, 5));

			    // apply light and shadow
                fixed3 edgeCol = backSSS * _EdgeLitRate * _InteriorColor * tex2DNode2.rgb;
                edgeCol += backSSS * _InteriorColor;
                fixed3 lighting = lerp (_ShadowStr * _ShadowColor, fixed4 (1,1,1,1), 1.5 * ndotl).rgb * _LightColor0.xyz * _LightInt;

			    Emission += edgeCol;
			    //o.Emission = emiss * 0.5;
			    Emission = max(emiss * 0.5, Emission * lighting);
			    //o.Emission *= lighting;
			    //o.Albedo += backSSS;
			    //o.Albedo = saturate(o.Albedo);
			
			
			    Emission *=1.6;
			    Emission = saturate(Emission);

                // apply fog
                UNITY_APPLY_FOG(i.fogCoord, Emission);
			    //o.Alpha = 1;
			    clip( tex2DNode2.a - _Cutoff );

                return float4(Emission, 1.0);
            }
            ENDCG
        }

		Pass {
            Name "ShadowCaster"
            Tags {
                "LightMode"="ShadowCaster"
            }
            Offset 1, 1
            Cull Back
            
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            // #define UNITY_PASS_SHADOWCASTER
            #include "UnityCG.cginc"
            #include "Lighting.cginc"
            // #pragma fragmentoption ARB_precision_hint_fastest
            #pragma multi_compile_shadowcaster
            #pragma multi_compile_fog
            // #pragma only_renderers d3d9 d3d11 glcore gles gles3 
            #pragma target 3.0
            uniform sampler2D _MainTexture;
			uniform float _Small_WindAmount;
		    uniform sampler2D _Leaves_NoiseTexture;
		    uniform float _Small_WindSpeed;
		    uniform float _Small_Wave;
		    uniform float _Big_WindAmount;
		    uniform sampler2D _Tree_NoiseTexture;
		    uniform float _Big_Windspeed;
		    uniform float _Big_Wave;
            //uniform float _Anim;
			UNITY_INSTANCING_BUFFER_START(InstanceAnim)
            // put more per-instance properties here
			UNITY_DEFINE_INSTANCED_PROP(float, _Anim)
			#define _Anim_arr InstanceAnim
			UNITY_INSTANCING_BUFFER_END(InstanceAnim)

			float4 CalculateContrast( float contrastValue, float4 colorTarget )
		    {
			    float t = 0.5 * ( 1.0 - contrastValue );
			    return mul( float4x4( contrastValue,0,0,t, 0,contrastValue,0,t, 0,0,contrastValue,t, 0,0,0,1 ), colorTarget );
		    }
			
            struct VertexInput {
                float4 vertex : POSITION;
                float2 texcoord0 : TEXCOORD0;
				float3 color : COLOR;
            };
            struct VertexOutput {
                V2F_SHADOW_CASTER;
                float2 uv0 : TEXCOORD1;
            };
            VertexOutput vert (VertexInput v) {
                VertexOutput o = (VertexOutput)0;
                o.uv0 = v.texcoord0;
				float3 ase_vertex3Pos = v.vertex.xyz;
			    float2 temp_cast_0 = (( ( ase_vertex3Pos.x + ( _Time.y * _Small_WindSpeed ) ) / ( 1.0 - _Small_Wave ) )).xx;
			    float lerpResult143 = lerp( tex2Dlod( _Leaves_NoiseTexture, float4( temp_cast_0, 0, 0.0) ).r , 0.0 , v.color.r);
			    float3 appendResult160 = (float3(lerpResult143 , 0.0 , 0.0));
			    float2 temp_cast_2 = ((( _Time.y * _Big_Windspeed ) / ( 1.0 - _Big_Wave ) )).xx;
			    float lerpResult170 = lerp( ( _Big_WindAmount * tex2Dlod( _Tree_NoiseTexture, float4( temp_cast_2, 0, 0.0) ).r ) , 0.0 , v.color.b);
			    float3 appendResult172 = (float3(lerpResult170 , 0.0 , 0.0));
			    v.vertex.xyz += ( CalculateContrast(_Small_WindAmount,float4( (appendResult160).xz, 0.0 , 0.0 )) + float4( (appendResult172).xz, 0.0 , 0.0 ) ).rgb;
                o.pos = UnityObjectToClipPos( v.vertex );
                TRANSFER_SHADOW_CASTER(o)
                return o;
            }
            float4 frag(VertexOutput i) : COLOR {
                float4 _MainTex_var = tex2D(_MainTexture, i.uv0);
                clip(_MainTex_var.a - 0.5 -1 +step(UNITY_ACCESS_INSTANCED_PROP(_Anim_arr, _Anim), _MainTex_var.r));
                SHADOW_CASTER_FRAGMENT(i)
            }
            ENDCG
        }
    }
    Fallback "VertexLit"
}
