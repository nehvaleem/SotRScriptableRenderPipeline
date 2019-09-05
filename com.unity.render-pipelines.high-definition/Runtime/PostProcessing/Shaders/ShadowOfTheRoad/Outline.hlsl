#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Common.hlsl"

#include "Packages/com.unity.render-pipelines.high-definition/Runtime/ShaderLibrary/ShaderVariables.hlsl"
#include "Packages/com.unity.render-pipelines.high-definition/Runtime/Material/Material.hlsl"

#include "Packages/com.unity.render-pipelines.high-definition/Runtime/Debug/DebugDisplay.hlsl"
#include "Packages/com.unity.render-pipelines.high-definition/Runtime/Material/Lit/Lit.hlsl"

float4 _outlineColor;
uniform float4x4 _projMat;
float _offset;
float _cavityBrightness;
float _cavityContrast;
float _distanceBrightness;
float _distanceContrast;
int _isDebugMode;
TEXTURE2D_X(_InputTexture);

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

float3 GetNormalSample(float2 positionSS)
{

    BSDFData bsdfData;
    BuiltinData builtinData;
    DECODE_FROM_GBUFFER(positionSS, UINT_MAX, bsdfData, builtinData);

    NormalData normalData;
    float4 normalBuffer = LOAD_TEXTURE2D_X(_NormalBufferTexture, positionSS);
    DecodeFromNormalBuffer(normalBuffer, positionSS, normalData);
    float3 normalsVS = TransformWorldToViewDir(bsdfData.normalWS);
    float3 normalsWS = bsdfData.normalWS;
    return normalsVS;
}

float GetCavity(float2 texcoord)
{
    float cavity = 1;
    float3 midNormal = GetNormalSample(texcoord);

    float3 leftNormal = GetNormalSample(texcoord + float2(0, 0));
    float3 rightNormal = GetNormalSample(texcoord + float2(1, 0));
    float LRdot = dot(leftNormal, rightNormal);

    float3 topNormal = GetNormalSample(texcoord + float2(0, 0));
    float3 bottomNormal = GetNormalSample(texcoord + float2(0, 1));
    float TBdot = dot(topNormal, bottomNormal);

    float3 leftTopNormal = GetNormalSample(texcoord + float2(0, 0));
    float3 rightBottomNormal = GetNormalSample(texcoord + float2(1, 1));
    float LTRBdot = dot(leftTopNormal, rightBottomNormal);

    float3 leftBottomNormal = GetNormalSample(texcoord + float2(0, 1));
    float3 rightTopNormal = GetNormalSample(texcoord + float2(1, 0));
    float LBRTdot = dot(leftBottomNormal, rightTopNormal);

    float minDot = min(min(LRdot, TBdot), min(LTRBdot, LBRTdot));
    cavity = minDot;

    return cavity;
}

float GetDistanceSample(float2 positionSS)
{
    float depth = LoadCameraDepth(positionSS);
    float linearEyeDepth = LinearEyeDepth(depth, _ZBufferParams);
    return linearEyeDepth;
}

float GetDistance(float2 texcoord)
{
    float midDistance = GetDistanceSample(texcoord);

    float leftDistance = GetDistanceSample(texcoord + float2(1, 0));
    float leftDot = min(leftDistance, midDistance) / max(leftDistance, midDistance);

    float rightDistance = GetDistanceSample(texcoord + float2(1, 0));
    float rightDot = min(rightDistance, midDistance) / max(rightDistance, midDistance);

    float LRdot = min(leftDistance, rightDistance) / max(leftDistance, rightDistance);

    float topDistance = GetDistanceSample(texcoord + float2(0, 1));
    float topDot = min(topDistance, midDistance) / max(topDistance, midDistance);

    float bottomDistance = GetDistanceSample(texcoord + float2(0, 1));
    float bottomDot = min(bottomDistance, midDistance) / max(bottomDistance, midDistance);

    float TBdot = min(topDistance, bottomDistance) / max(topDistance, bottomDistance);

    float leftTopDistance = GetDistanceSample(texcoord + float2(0, 0));
    float leftTopDot = min(leftTopDistance, midDistance) / max(leftTopDistance, midDistance);

    float rightBottomDistance = GetDistanceSample(texcoord + float2(1, 1));
    float rightBottomDot = min(rightBottomDistance, midDistance) / max(rightBottomDistance, midDistance);

    float LTRBdot = min(leftTopDistance, rightBottomDistance) / max(leftTopDistance, rightBottomDistance);

    float leftBottomDistance = GetDistanceSample(texcoord + float2(0, 1));
    float leftBottomDot = min(leftBottomDistance, midDistance) / max(leftBottomDistance, midDistance);

    float rightTopDistance = GetDistanceSample(texcoord + float2(1, 0));
    float rightTopDot = min(rightTopDistance, midDistance) / max(rightTopDistance, midDistance);

    float LBRTdot = min(leftBottomDistance, rightTopDistance) / max(leftBottomDistance, rightTopDistance);


    float avgDistance = (LRdot + TBdot + LTRBdot + LBRTdot) * 0.25;
    float minDistance = min(min(LRdot, TBdot), min(LTRBdot, LBRTdot));
    float sdDistance = pow((pow(LRdot - avgDistance, 2) + pow(TBdot - avgDistance, 2) + pow(LTRBdot - avgDistance, 2) + pow(LBRTdot - avgDistance, 2)) * 0.25, 0.5);
    float sdMinDistance = pow(pow(minDistance - avgDistance, 2), 0.5);

    float dotSdMinDistance = min(sdDistance, sdMinDistance) / max(sdDistance, sdMinDistance);
    // saturate(min(min(rightDot, rightBottomDot), bottomDot));
    //float avgDistance = (rightDot + rightBottomDot + bottomDot) / 3;
    //float sdDistance = pow(pow(rightDot - avgDistance, 2) + pow(bottomDot - avgDistance, 2) + pow(rightBottomDot - avgDistance, 2), 0.5);

    float distance = minDistance;

    /*
    float midFresnel = dot(GetNormalSample(texcoord), -worldDirection);
    float rightFresnel = dot(GetNormalSample(texcoord + float2(dx, 0)), -worldDirection);
    float bottomFresnel = dot(GetNormalSample(texcoord + float2(0, dy)), -worldDirection);
    float rightBottomFresnel = dot(GetNormalSample(texcoord + float2(dx, dy)), -worldDirection);
    float rightFresnelDot = min(pow(saturate(rightFresnel), 1), pow(saturate(midFresnel), 1)) / max(pow(saturate(rightFresnel), 1), pow(saturate(midFresnel), 1));
    float bottomFresnelDot = min(pow(saturate(bottomFresnel), 1), pow(saturate(midFresnel), 1)) / max(pow(saturate(bottomFresnel), 1), pow(saturate(midFresnel), 1));
    float rightBottomFresnelDot = min(pow(saturate(rightBottomFresnel), 1), pow(saturate(midFresnel), 1)) / max(rightBottomFresnel, pow(saturate(midFresnel), 1));
    */
    return distance;
}

float GetPositioniSample(float2 positionSS, float3 worldDirection)
{
    float depth = LoadCameraDepth(positionSS);
    float linearEyeDepth = LinearEyeDepth(depth, _ZBufferParams);
    float3 position = (worldDirection * linearEyeDepth + _WorldSpaceCameraPos);
    return position;
}

float GetPosition(float2 texcoord, float3 worldDirection)
{
    float3 midPosition = GetPositioniSample(texcoord, worldDirection);

    float3 leftPosition = GetPositioniSample(texcoord + float2(0, 0), worldDirection);
    float3 rightPosition = GetPositioniSample(texcoord + float2(1, 0), worldDirection);
    float LRdot = distance(leftPosition, rightPosition);

    float3 topPosition = GetPositioniSample(texcoord + float2(0, 0), worldDirection);
    float3 bottomPosition = GetPositioniSample(texcoord + float2(0, 1), worldDirection);
    float TBdot = distance(topPosition, bottomPosition);

    float3 leftTopPosition = GetPositioniSample(texcoord + float2(0, 0), worldDirection);
    float3 rightBottomPosition = GetPositioniSample(texcoord + float2(1, 1), worldDirection);
    float LTRBdot = distance(leftTopPosition, rightBottomPosition);

    float3 leftBottomPosition = GetPositioniSample(texcoord + float2(0, 1), worldDirection);
    float3 rightTopPosition = GetPositioniSample(texcoord + float2(1, 0), worldDirection);
    float LBRTdot = distance(leftBottomPosition, rightTopPosition);

    float avg = (LRdot + TBdot + LTRBdot + LBRTdot) * 0.5;
    float sd = 1 - pow((pow(LRdot - avg, 2) + pow(TBdot - avg, 2) + pow(LTRBdot - avg, 2) + pow(LBRTdot - avg, 2)) / 4, 0.5) + saturate(midPosition.y * 0.1);
    return saturate(sd);
}

float3 Frag(Varyings input) : SV_Target
{
    float4 color = 0;
    float depth = LoadCameraDepth(input.positionCS.xy);
    float linearEyeDepth = LinearEyeDepth(depth, _ZBufferParams);
    PositionInputs posInput = GetPositionInput(input.positionCS.xy, _ScreenSize.zw, depth, UNITY_MATRIX_I_VP, UNITY_MATRIX_V);
    BSDFData bsdfData;
    BuiltinData builtinData;
    DECODE_FROM_GBUFFER(posInput.positionSS, UINT_MAX, bsdfData, builtinData);
    NormalData normalData;
    float4 inputTexture = LOAD_TEXTURE2D_X(_InputTexture, posInput.positionSS);
    float4 inGBuffer3 = LOAD_TEXTURE2D_X(_GBufferTexture3, posInput.positionSS);
    color = inputTexture;

    float3 position = GetPosition(posInput.positionSS, input.worldDirection);
    float3 cavity = GetCavity(posInput.positionSS);
    cavity = saturate(cavity + _cavityBrightness);
    cavity = saturate(pow(cavity, _cavityContrast * 100));
    float showAtDistance = 100;
    float d = 1;
    if (linearEyeDepth < showAtDistance)
    {
        cavity = cavity + pow(linearEyeDepth/showAtDistance, 4) + saturate(1 - position.y * 2 - 2);
        cavity = saturate(cavity);
    }
    else
    {
        cavity = 1;
    }

    float distance = GetDistance(posInput.positionSS);
    distance = saturate(distance + _distanceBrightness);
    distance = saturate(pow(distance, _distanceContrast * 100));
    float outline = saturate(distance * cavity);


    float light = max(max(inputTexture.r, inputTexture.g), inputTexture.b);
    light = light * 2;

    outline = lerp(light * 0.5, 1, outline.r);
    outline = lerp(1, outline, _outlineColor.a);
    outline = saturate(outline);
    if (abs(position.x) < 70 && abs(position.z) < 70)
    {
        color.rgb = lerp(_outlineColor, inputTexture, outline.r);
    }
    if (_isDebugMode == 1)
    {
        color.rgb = outline;
    }
    return color;// inputTexture * cavity * distance;
}
