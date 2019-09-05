#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Common.hlsl"

#include "Packages/com.unity.render-pipelines.high-definition/Runtime/ShaderLibrary/ShaderVariables.hlsl"
#include "Packages/com.unity.render-pipelines.high-definition/Runtime/Material/Material.hlsl"

#include "Packages/com.unity.render-pipelines.high-definition/Runtime/Debug/DebugDisplay.hlsl"
#include "Packages/com.unity.render-pipelines.high-definition/Runtime/Material/Lit/Lit.hlsl"

uniform float4x4 _projMat;
float4 _fogColor;
float4 _mapTint;
float _mapScale;
float _mapPositionX;
float _mapPositionY;
float _mapScale;
int _iterations;

TEXTURE2D_X(_InputTexture);
TEXTURE2D_X(_map);

struct Attributes
{
    uint vertexID : SV_VertexID;
    UNITY_VERTEX_INPUT_INSTANCE_ID
};

struct Varyings
{
    float4 positionCS : SV_POSITION;
    float2 texcoord : TEXCOORD0;
    float3 worldDirection: TEXCOORD2;
    UNITY_VERTEX_OUTPUT_STEREO
};

Varyings Vert(Attributes input)
{
    Varyings output;
    UNITY_SETUP_INSTANCE_ID(input);
    UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(output);
    output.positionCS = GetFullScreenTriangleVertexPosition(input.vertexID);
    output.texcoord = GetFullScreenTriangleTexCoord(input.vertexID);
    float4 clip = float4(output.texcoord.xy * 2 - 1, 0.0, 1.0);
    output.worldDirection = mul(_projMat, clip) - _WorldSpaceCameraPos;
    return output;
}

float3 Frag(Varyings input) : SV_Target
{
    float depth = LoadCameraDepth(input.positionCS.xy/* + float2(sin(_offset) * 200, 0)*/);

    PositionInputs posInput = GetPositionInput(input.positionCS.xy, _ScreenSize.zw, depth, UNITY_MATRIX_I_VP, UNITY_MATRIX_V);

    BSDFData bsdfData;
    BuiltinData builtinData;
    DECODE_FROM_GBUFFER(posInput.positionSS, UINT_MAX, bsdfData, builtinData);

    NormalData normalData;
    float4 normalBuffer = LOAD_TEXTURE2D_X(_NormalBufferTexture, posInput.positionSS/* + float2(sin(_offset) * 200, 0)*/);
    DecodeFromNormalBuffer(normalBuffer, posInput.positionSS, normalData);

    //
    // available data
    //

    // normals VS
    float3 normalsVS = TransformWorldToViewDir(bsdfData.normalWS) * 0.5 + 0.5;

    // normals WS
    float3 normalsWS = bsdfData.normalWS;

    // linear eye depth
    float linearEyeDepth = LinearEyeDepth(depth, _ZBufferParams);

    // World position
    float3 position = (input.worldDirection * linearEyeDepth + _WorldSpaceCameraPos);

    // bakeDiffuseLighting
    GBufferType0 inGBuffer3 = LOAD_TEXTURE2D_X(_GBufferTexture3, posInput.positionSS);

    //result = bsdfData.normalWS;

    //result = builtinData.bakeDiffuseLighting;
    //result *= exp2(_DebugExposure);
    //result = bsdfData.ambientOcclusion;
    float3 outColor = LOAD_TEXTURE2D_X(_InputTexture, posInput.positionSS).xyz;
    return outColor * 0.1;

    //return normalsWS;
}
