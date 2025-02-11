Shader "TEST/LISSAO"
{
    Properties
    {
        _RotationsTex ("Rotations", 2D) ="white"{}
    }
    SubShader
    {
        Tags
        {
            "LightMode" = "UniversalForward"
        }
        Cull Off
        ZTest Always
        Blend Zero SrcColor

        Pass
        {
            HLSLPROGRAM
            #pragma vertex Vert
            #pragma fragment frag

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.core/Runtime/Utilities/Blit.hlsl"

            TEXTURE2D_HALF(_RotationsTex);
            TEXTURE2D_FLOAT(_CameraDepthTexture);
            SAMPLER(sampler_CameraDepthTexture);


            //все массивы предрасичтанны в гудини
            // Массив предвычисленных координат (XY)
            static const float2 samplePoints[3] =
            {
                float2(0.2, 0.15),
                float2(0.0, 0.45),
                float2(-0.7, 0.35),
            };

            // глубина сферы в этой точке (точнее длин линии)
            //  2 * sqrt(1 - (r^2)) = 2 * sqrt(1 - (i/16))
            static const float sphereWidths[3] =
            {
                1.93649, 1.78606, 1.24499
            };

            //прерасчитанне обемы диаграммы вороного
            //по сути нормализованная сумма длин линий всех "пикселей" участка диграммы вороного
            static const float sphereWeights[3] =
            {
                0.155911, 0.178883, 0.128937
            };

            ///не оч понятно что это должно быть
            static const float maxDistances[3] =
            {
                0.005,
                0.003,
                0.001
            };


            //radius inner - raddius outer ????
            static const float radii[2] =
            {
                0.007, 0.015
            };

            half4 frag(Varyings IN) : SV_Target
            {
                float2 pixel = IN.texcoord * _ScreenParams.xy;
                float2 uvRotation = pixel * 0.25;
                float2 rotationSinCos = SAMPLE_TEXTURE2D(_RotationsTex, sampler_PointRepeat, uvRotation);

                float2x2 rotationMatrix = {
                    float2(rotationSinCos.y, rotationSinCos.x),
                    float2(-rotationSinCos.x, rotationSinCos.y)
                };

                // Глубина центра
                float centerDepth = SAMPLE_TEXTURE2D(_CameraDepthTexture, sampler_CameraDepthTexture, IN.texcoord).r;
                centerDepth *=  _ZBufferParams.z; // x/far

                float2 occlusion = 0.25;// //0.5*center normalized volume? 0.074
                int sampleCount = 3;

                for (int r = 0; r < 2; r++)
                {
                    float radius = min(radii[r] / centerDepth, 0.07);

                    for (int i = 0; i < sampleCount; i++)
                    {
                        half2 sample = samplePoints[i];
                        sample = mul(rotationMatrix, sample);

                        float3 offset = float3(sample, sphereWidths[i]);
                        offset *= radius;
                        float width = offset.z;


                        float2 uv1 = IN.texcoord + offset.xy;
                        float depth1 = SAMPLE_TEXTURE2D(_CameraDepthTexture, sampler_CameraDepthTexture, uv1).r;
                        float2 uv2 = IN.texcoord - offset.xy;
                        float depth2 = SAMPLE_TEXTURE2D(_CameraDepthTexture, sampler_CameraDepthTexture, uv2).r;

                        float2 depthSample = float2(depth1, depth2) * _ZBufferParams.z;
                        float2 depthDiff = centerDepth.xx - depthSample; //(!)

                        //хз каким оно должно быть пока
                        half2 maxDistance = maxDistances[i]; 
                        half2 aoContribution = saturate((depthDiff / width.xx) + 0.5);

                        half2 distanceModifiers = saturate((maxDistance.xx - depthDiff.xy) / maxDistance.xx);
                        half2 modifiersContributor = float2(lerp
                            (
                                lerp(0.5, 1.0 - aoContribution.yx, distanceModifiers.yx),
                                aoContribution.xy,
                                distanceModifiers.xy));

                        modifiersContributor *= sphereWeights[i]; //(!)

                        occlusion += modifiersContributor;
                    }
                }
                occlusion = saturate((occlusion - 0.5) * 2.0);
                half a = saturate(occlusion.y + occlusion.x);
               
                return half4(a, a, a, 1.0);
            }
            ENDHLSL
        }
    }
}