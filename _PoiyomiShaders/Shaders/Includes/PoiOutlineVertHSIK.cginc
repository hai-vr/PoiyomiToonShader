#ifndef OutlineVert
    #define OutlineVert

    float _EnableFakeArm;
    float _BoneLength;
    float _ExtraForearmLength;
    float _ExtraGrabRatio;
    float _ShaderIKTargetLightIntensity;
    float _VertexScale;
    int _IsLeftArm;

    #include "../../../HaiHandholdingShaderIK/HaiHandholdingShaderIK.cginc"
    
    #include "CGI_PoiV2F.cginc"
    
    uint _OutlineMode;
    float4 _OutlinePersonaDirection;
    float4 _OutlineDropShadowOffset;
    float _OutlineUseVertexColors;
    float _OutlineFixedSize;

    sampler2D _OutlineMask; float4 _OutlineMask_ST;
    v2f vert(appdata v)
    {
        UNITY_SETUP_INSTANCE_ID(v);
        v2f o;
        UNITY_INITIALIZE_OUTPUT(v2f, o);
        UNITY_TRANSFER_INSTANCE_ID(v, o);
        UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(o);

        if (_EnableFakeArm > 0.5)
        {
            v.vertex = transformArm(
                float4(v.vertex.xyz * _VertexScale, 1),
                v.color,
                _ShaderIKTargetLightIntensity,
                true,
                float4(0.001, (isLeftArm ? -1 : 1) * -0.002, -0.003, 1) + float4(
                    sin(_Time.y * 0.3) * 0.00002,
                    sin(_Time.y * 0.43) * 0.000035,
                    sin(_Time.y * 1.24) * 0.00015, 0),
                _BoneLength / 1000000,
                (_BoneLength + _ExtraForearmLength) / 1000000,
                (_BoneLength * _ExtraGrabRatio + _ExtraForearmLength) / 1000000,
                isLeftArm
            );
        }
        else
        {
            v.vertex = float4(0, 0, 0, 0);
        }
        
        #ifdef POI_MIRROR
            applyMirrorRenderVert(v.vertex);
        #endif
        
        o.uv0.xy = v.uv0 + _OutlineGlobalPan.xy * _Time.y;
        float outlineMask = 1;
        #ifndef SIMPLE
            outlineMask = poiMax(tex2Dlod(_OutlineMask, float4(TRANSFORM_TEX(o.uv0.xy, _OutlineMask) + _Time.x * _OutlineTexturePan.zw, 0, 0)).rgb);
        #endif
        UNITY_BRANCH
        if (_OutlineUseVertexColors == 0)
        {
            o.normal = UnityObjectToWorldNormal(v.normal);
        }
        else
        {
            o.normal = UnityObjectToWorldNormal(v.color);
        }
        half offsetMultiplier = 1;
        half distanceOffset = 1;
        UNITY_BRANCH
        if(_OutlineFixedSize)
        {
            distanceOffset *= distance(_WorldSpaceCameraPos,mul(unity_ObjectToWorld, v.vertex).xyz);
        }
        
        float3 offset = o.normal * (_LineWidth / 100) * outlineMask * distanceOffset;
        
        UNITY_BRANCH
        if(_OutlineMode == 2)
        {
            float3 lightDirection = poiLight.direction = normalize(_WorldSpaceLightPos0 + unity_SHAr.xyz + unity_SHAg.xyz + unity_SHAb.xyz);
            offsetMultiplier = saturate(dot(lightDirection, o.normal));
            offset *= offsetMultiplier;
            offset *= distanceOffset;
        }
        else if(_OutlineMode == 3)
        {
            half3 viewNormal = mul((float3x3)UNITY_MATRIX_V, o.normal);
            offsetMultiplier = saturate(dot(viewNormal.xy, normalize(_OutlinePersonaDirection.xy)));
            
            offset *= offsetMultiplier;
            offset *= distanceOffset;
        }
        else if(_OutlineMode == 4)
        {
            offset = mul((float3x3)transpose(UNITY_MATRIX_V), _OutlineDropShadowOffset);
            offset *= distanceOffset;
        }
        
        o.worldPos = mul(unity_ObjectToWorld, v.vertex) + float4(offset, 0);
        o.modelPos = mul(unity_ObjectToWorld, float4(0, 0, 0, 1));
        o.pos = UnityWorldToClipPos(o.worldPos);
        
        o.angleAlpha = 1;
        #ifdef POI_RANDOM
            o.angleAlpha = ApplyAngleBasedRendering(o.modelPos, o.worldPos);
        #endif
        
        UNITY_TRANSFER_SHADOW(o, o.uv0);
        UNITY_TRANSFER_FOG(o, o.pos);
        return o;
    }
    
#endif