Shader "PBR/PBRBuilding"
{
    Properties
    {
        [Header(Main)]
        _MainTex ("MainTexture", 2D) = "white" {}
        _MainColor ("MainColor", Color) = (1,1,1,1)
        _ShadowColor ("ShadowColor", Color) = (0.53,0.56,1,1)
        _LightColorScale ("LightColorScale",Range(0 , 5)) = 1.0

        [Header(Normal)]
        [NoScaleOffset]_BumpMap ("Normal Map", 2D) = "bump" {}
        _BumpScale ("Bump Scale",Range(0 , 8)) = 1.0

        [Header(MRA)]
        _RoughnessOffset ("RoughnessOffset", Range(0 ,1)) = 1
        [NoScaleOffset]_MRAMap ("MRAMap", 2D) = "white" {}
        _SpecularColor ("SpecularColor", Color) = (0.25,0.25,0.25,1)
        [Gamma] _Metallic("Metallic", Range(0, 1)) = 0 //金属度要经过伽马校正
		_Smoothness("Smoothness", Range(0, 1)) = 0.5
        _MetallicLerp("MetallicLerp", Range(0, 1)) = 1
        _SmoothnessLerp("SmoothnessLerp", Range(0, 1)) = 1
        _AOColor ("AOColor", Color) = (0,0,0,1)
        _AOLerp("AOLerp", Range(0, 1)) = 1
        
        [Header(Animation)]
        [NoScaleOffset]_MaskTex("MaskTexture", 2D) = "black"{}
        _Anim("Anim", Range(0, 1.1)) = 0
        
        [Header(Emission)]
        _EmissionTex("EmissionTex", 2D) = "black"{}
		[HDR]_EmissionColor("EmissionColor", color) = (0.0, 0.0, 0.0, 0.0)
        
        /*
        [Header(BackLightSSS)]
        _InteriorColor ("Interior Color", Color) = (1,1,1,1)
        _BackSubsurfaceDistortion ("Back Subsurface Distortion", Range(0,1)) = 0.5
        _LitIncr ("Light Increment",Vector) = (0.3,-2.83,0.41,0)
        */
       

    }
    SubShader
    {
        Tags { "RenderType"="TransparentCutout" "Queue"="AlphaTest"}
        Pass // 前向渲染 Base Pass
        {
            Tags {  "LightMode"="ForwardBase" }
            
            CGPROGRAM
            
            #pragma multi_compile_fwdbase
            #pragma vertex vert
            #pragma fragment frag

            #include "UnityCG.cginc"
            #include "Lighting.cginc"
            #include "AutoLight.cginc"


            UNITY_INSTANCING_BUFFER_START(InstanceAnim)
            // put more per-instance properties here
			UNITY_DEFINE_INSTANCED_PROP(fixed, _Anim)
			#define _Anim_arr InstanceAnim
			UNITY_INSTANCING_BUFFER_END(InstanceAnim)

            sampler2D _MainTex, _BumpMap ,_MRAMap , _SmoothnessMap ,  _MaskTex , _EmissionTex;
            fixed4 _MainTex_ST, _BumpMap_ST;
            fixed4 _MainColor, _ShadowColor , _EmissionColor , _AOColor;

            fixed  _LightColorScale , _BumpScale, _Gloss ,_Metallic ,_Smoothness;
            fixed _RoughnessOffset , _MetallicLerp ,  _SmoothnessLerp , _AOLerp;
            fixed _BackSubsurfaceDistortion;
            fixed4 _LitIncr;

            fixed4 _SpecularColor , _InteriorColor;

            struct appdata
            {
                fixed4 vertex : POSITION;
                fixed2 uv : TEXCOORD0;
                fixed4 tangent : TANGENT;
                fixed3 normal : NORMAL;
            };

            struct v2f
            {
                fixed4 pos : SV_POSITION;
                fixed2 uv : TEXCOORD0;
                fixed4 t2w_0 : TEXCOORD1;
                fixed4 t2w_1 : TEXCOORD2;
                fixed4 t2w_2 : TEXCOORD3;
                //使用Unity内置宏 声明一个用于对阴影纹理采样的坐标_ShadowCoord，宏后边的(4) 表示可用的插值寄存器的索引值,即 TEXCOORD4
                SHADOW_COORDS(4)  // Unity内部定义为 unityShadowCoord4 _ShadowCoord : TEXCOORD##idx1;
                fixed3 normalDir : TEXCOORD5;
                
            };

            v2f vert (appdata v)
            {
                v2f o;
                //顶点从模型空间到裁剪空间
                o.pos = UnityObjectToClipPos(v.vertex);
                //计算UV变换
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);

                o.normalDir = normalize(UnityObjectToWorldNormal(v.vertex)); // sphere normal

                //顶点从模型空间到世界空间
                fixed3 worldVertex = mul(unity_ObjectToWorld, v.vertex);
                //法线从模型空间到世界空间
                fixed3 worldNormal = UnityObjectToWorldNormal(v.normal);
                //切线从模型空间到切线空间
                fixed3 worldTangent = UnityObjectToWorldDir(v.tangent);
                //根据 世界空间法线、世界空间切线、切线方向 计算世界空间副切线 
                fixed3 worldBiTangent = cross(worldNormal,worldTangent) * v.tangent.w;

                //将 切线空间到世界空间的转换矩阵写入插值器，为了尽可能的利用插值器，把三个插值器的w分量存储世界空间顶点
                o.t2w_0 = fixed4(worldTangent.x,worldBiTangent.x,worldNormal.x, worldVertex.x);
                o.t2w_1 = fixed4(worldTangent.y,worldBiTangent.y,worldNormal.y, worldVertex.y);
                o.t2w_2 = fixed4(worldTangent.z,worldBiTangent.z,worldNormal.z, worldVertex.z);

                //使用Unity内置宏，传递阴影坐标到像素着色器
                /*
                 *由于内置宏 TRANSFER_SHADOW 中会使用上下文变量来进行相关计算
                 *此处 顶点着色器（vert）的输入结构体 appdata 必须命名为v，且输入结构体 appdata 内的顶点坐标必须命名为 vertex
                 *输出结构体 v2f 的顶点坐标必须命名为 pos 
                 */
                TRANSFER_SHADOW(o);
                
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                
                //_MainTex 贴图采样，并于颜色参数混合

                fixed4 albedo = tex2D(_MainTex, i.uv);// * _Color;
                fixed4 _MaskTex_var = tex2D(_MaskTex,i.uv);
                fixed4 _Emission_var = tex2D(_EmissionTex,i.uv);
                //clip(albedo.a - 0.5 );
                clip(albedo.a - 0.5 -1 +step(UNITY_ACCESS_INSTANCED_PROP(_Anim_arr, _Anim), _MaskTex_var.r));
                //计算环境光和模型颜色的混合
                fixed3 ambient = UNITY_LIGHTMODEL_AMBIENT.rgb * albedo.rgb;

                //世界空间顶点
                fixed3 worldVector = fixed3(i.t2w_0.w, i.t2w_1.w, i.t2w_2.w);
                //计算世界空间光照方向
                fixed3 worldLightDir = normalize(UnityWorldSpaceLightDir(worldVector));

                /*-----------------------------------法线计算---------------------------------*/
                //获取  切线空间到世界空间的转换矩阵
                fixed3x3 tangentToWorld = fixed3x3(i.t2w_0.xyz, i.t2w_1.xyz, i.t2w_2.xyz);
                //采样切线空间法线贴图
                fixed4 bump = tex2D(_BumpMap, i.uv);
                //获取切线空间法线
                fixed3 tangentSpeaceNormal = UnpackNormalWithScale(bump,_BumpScale);
                //切线空间法线 转换到 世界空间
                fixed3 worldNormal = normalize(mul(tangentToWorld, tangentSpeaceNormal)); 

                /*-----------------------------------漫反射计算---------------------------------*/
                /*Lambert模型*/
                //fixed3 diffuse = albedo.rgb * _LightColor0.rgb * (dot(worldNormal, worldLightDir));
                
                /*Half-Lambert模型*/
                fixed3 diffuse = albedo.rgb * _LightColor0.rgb * saturate(dot(worldNormal, worldLightDir)* 0.5 + 0.5);

                /*-----------------------------------高光反射计算---------------------------------*/
                //世界空间视角方向
                fixed3 worldViewDir = normalize(UnityWorldSpaceViewDir(worldVector));

                /*
			    //BackLight  SSS
                fixed3 backLitDir =  i.normalDir * _BackSubsurfaceDistortion + _LitIncr.xyz;
                fixed backSSS = saturate(dot(worldViewDir, -backLitDir));
                backSSS = saturate(pow(backSSS, 5)) * _InteriorColor.rgb;

                //return backSSS;// * albedo ;
                */
                
                // /*Phong模型*/
                // //计算反射光照方向
                // fixed3 reflectLightDir = normalize(reflect(-worldLightDir, worldNormal));
                // //计算高光反射
                // fixed3 specular = _Specular.rgb * _LightColor0.rgb * pow(saturate(dot(reflectLightDir, worldViewDir)), _Gloss);
                
                /*Blinn-Phong模型*/
                // 归一化 世界空间光照方向和视角方向之和
                fixed3 hDir = normalize(worldLightDir + worldViewDir);
                //计算光照反射
                //fixed3 specular = _SpecularColor.rgb * _LightColor0.rgb * pow(saturate(dot(hDir,worldNormal)), _Gloss);
                fixed3 finalspecluarcolor = _SpecularColor.rgb * _LightColor0.rgb* (dot(worldNormal, worldLightDir)* 0.5 + 0.5);// * _LightColor0.rgb ;

                /*-----------------------------------金属度粗糙度计算(PBR)---------------------------------*/
                //贴图采样
                fixed4 mra = tex2D(_MRAMap, i.uv);

                //粗糙度
                fixed perceptualRoughness = 1 - lerp(_Smoothness ,mra.g * _Smoothness,_SmoothnessLerp);
                fixed roughness = perceptualRoughness * perceptualRoughness;
				fixed squareRoughness = roughness * roughness;
                //镜面反射部分
				//D是镜面分布函数，从统计学上估算微平面的取向
				fixed lerpSquareRoughness = pow(lerp(0.002, 1, roughness), 2);//Unity把roughness lerp到了0.002
                fixed nh = saturate(dot(worldNormal, hDir));
				fixed D = lerpSquareRoughness / (pow((pow(nh, 2) * (lerpSquareRoughness - 1) + 1), 2) );
                //菲涅尔F
				//unity_ColorSpaceDielectricSpec.rgb这玩意大概是fixed3(0.04, 0.04, 0.04)，就是个经验值
				fixed3 F0 = lerp(unity_ColorSpaceDielectricSpec.rgb, albedo, lerp(_Metallic ,_Metallic * mra.r,_MetallicLerp));
                fixed vh = saturate(dot(worldViewDir, hDir));
                fixed3 F = F0 + (1 - F0) * exp2((-5.55473 * vh - 6.98316) * vh);
               
                //几何遮蔽G 说白了就是高光
				fixed kInDirectLight = pow(squareRoughness + _RoughnessOffset, 2) ;//pow(squareRoughness + 1, 2) ;
				fixed kInIBL = pow(squareRoughness, 2) / 8;
                fixed nl = saturate(dot(worldNormal, worldLightDir));
				fixed nv = saturate(dot(worldNormal, worldViewDir));
				fixed GLeft = nl / lerp(nl, 1, kInDirectLight);
				fixed GRight = nv / lerp(nv, 1, kInDirectLight);
				fixed G = GLeft  * GRight;

                 //镜面反射结果
                fixed3 SpecularResult = saturate((D *G * F * 0.25)/(nv * nl));

                //计算光照衰减和阴影(包含了阴影衰减，故无需再单独使用 SHADOW_ATTENUATION 内置宏来计算阴影)
                UNITY_LIGHT_ATTENUATION(atten, i, worldVector);
                //fixed shadow = SHADOW_ATTENUATION(i);
                half4 shadowcol = lerp(_ShadowColor,_MainColor,atten );  
                fixed ao = lerp(1 ,mra.b , _AOLerp);
                half4 aocolor = lerp(_AOColor, 1, ao);
                //fixed4 col = fixed4(ambient* shadowcol+ (diffuse + specular)  , 1.0);   
                fixed4 col = fixed4(ambient* shadowcol  +  diffuse  * _LightColorScale * aocolor+  SpecularResult * finalspecluarcolor + _EmissionColor.rgb * _Emission_var ,1);//+  SpecularResult * finalspecluarcolor , 1.0);   
                //return lerp(col,shadowcol,0.8); 
                //return lerp(_Color,1,atten);    
                //return fixed4(UNITY_PI * SpecularResult , 1);    
                //return (1- mra.g) * _SpecularColor * mra.b;   
                //return fixed4(ambient* shadowcol,1);  
                //return mra.b;
                return col;
            }
            ENDCG
        }
        
        // 此ShadowCaster Pass是用来更新阴影映射纹理, 使其它物体可以接受到他的阴影
        // 即 此Pass将对象渲染为阴影投射器
        Pass
        {
            Tags{ "LightMode"="ShadowCaster"}

            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #pragma multi_compile_shadowcaster
            #include "UnityCG.cginc"

            struct v2f
            {
                V2F_SHADOW_CASTER;
            };

            v2f vert(appdata_base v)
            {
                v2f o;
                TRANSFER_SHADOW_CASTER_NORMALOFFSET(o)
                return o;
            }

            fixed4 frag(v2f i) : SV_Target
            {
                SHADOW_CASTER_FRAGMENT(i)
            }
            
            ENDCG
        }
    }
    //FallBack "Specular"
}