Shader "Hidden/SotR/FogOfWar"
{
    SubShader
    {
        Tags{ "RenderPipeline" = "HDRenderPipeline" }

        Pass
        {
            ZWrite On ZTest Always Blend Off Cull Off

            HLSLPROGRAM
                #pragma target 4.5
                #pragma only_renderers d3d11 ps4 xboxone vulkan metal switch


            ENDHLSL
        }
    }
    Fallback Off
}
