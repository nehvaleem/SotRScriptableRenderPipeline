#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Common.hlsl"

#include "Packages/com.unity.render-pipelines.high-definition/Runtime/ShaderLibrary/ShaderVariables.hlsl"
#include "Packages/com.unity.render-pipelines.high-definition/Runtime/Material/Material.hlsl"

#include "Packages/com.unity.render-pipelines.high-definition/Runtime/Debug/DebugDisplay.hlsl"
#include "Packages/com.unity.render-pipelines.high-definition/Runtime/Material/Lit/Lit.hlsl"

float4 _outlineColor;

struct Attributes
{
    uint vertexID : SV_VertexID;
    UNITY_VERTEX_INPUT_INSTANCE_ID
};

struct Varyings
{
    float4 positionCS : SV_POSITION;
    float2 texcoord : TEXCOORD0;
    UNITY_VERTEX_OUTPUT_STEREO
};

Varyings Vert(Attributes input)
{
    Varyings output;
    UNITY_SETUP_INSTANCE_ID(input);
    UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(output);
    output.positionCS = GetFullScreenTriangleVertexPosition(input.vertexID);
    output.texcoord = GetFullScreenTriangleTexCoord(input.vertexID);
    return output;
}

float3 Frag(Varyings input) : SV_Target
{
    float depth = LoadCameraDepth(input.positionCS.xy);
    PositionInputs posInput = GetPositionInput(input.positionCS.xy, _ScreenSize.zw, depth, UNITY_MATRIX_I_VP, UNITY_MATRIX_V);

    BSDFData bsdfData;
    BuiltinData builtinData;
    DECODE_FROM_GBUFFER(posInput.positionSS, UINT_MAX, bsdfData, builtinData);

    int bufferIndex = int(_DebugViewMaterialArray[0]) >= 1 ? int(_DebugViewMaterialArray[1]) : 0;

    float linearDepth = frac(posInput.linearDepth * 0.1);
    float3 result = linearDepth.xxx;

    //result = bsdfData.normalWS;

    //result = builtinData.bakeDiffuseLighting;
    //result *= exp2(_DebugExposure);
    //result = bsdfData.ambientOcclusion;
    return result;



    //float3 color = _outlineColor * depth;

    //return color;
}
