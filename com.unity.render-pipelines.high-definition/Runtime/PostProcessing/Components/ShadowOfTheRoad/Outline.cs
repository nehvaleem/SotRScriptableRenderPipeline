using System;

namespace UnityEngine.Rendering.HighDefinition
{
    [Serializable, VolumeComponentMenu("Post-processing/Shadow of the Road/Outline")]
    public sealed class Outline : VolumeComponent, IPostProcessComponent
    {
        public BoolParameter isDebugMode = new BoolParameter(false);
        public BoolParameter useScreen = new BoolParameter(false);
        public ClampedFloatParameter cavityBrightness = new ClampedFloatParameter(0.1f, 0f, 1f);
        public ClampedFloatParameter cavityContrast = new ClampedFloatParameter(0.1f, 0f, 1f);
        public ClampedFloatParameter distanceBrightness = new ClampedFloatParameter(0.1f, 0f, 1f);
        public ClampedFloatParameter distanceContrast = new ClampedFloatParameter(0.1f, 0f, 1f);
        public ColorParameter outlineColor = new ColorParameter(new Color(0,0,0,0), false, true, true);
        public ClampedIntParameter thickness = new ClampedIntParameter(0, 0, 10);

        public bool IsActive()
        {
            return outlineColor.value.a > 0f;
        }
    }
}
