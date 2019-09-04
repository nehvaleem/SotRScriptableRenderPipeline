using System;

namespace UnityEngine.Rendering.HighDefinition
{
    [Serializable, VolumeComponentMenu("Post-processing/Shadow of the Road/Fog of War")]
    public sealed class FogOfWar : VolumeComponent, IPostProcessComponent
    {
        [Tooltip("To be replaced")]
        public ColorParameter placeholderParameter = new ColorParameter(new Color(0,0,0,0), false, true, true);

        public bool IsActive()
        {
            return placeholderParameter.value.a > 0f;
        }
    }
}
