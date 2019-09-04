using System;

namespace UnityEngine.Rendering.HighDefinition
{
    [Serializable, VolumeComponentMenu("Post-processing/Shadow of the Road/Outline")]
    public sealed class Outline : VolumeComponent, IPostProcessComponent
    {
        [Tooltip("Specifies color of the outline")]
        public ColorParameter outlineColor = new ColorParameter(new Color(0,0,0,0), false, true, true);

        public bool IsActive()
        {
            return outlineColor.value.a > 0f;
        }
    }
}
