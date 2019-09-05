using System;

namespace UnityEngine.Rendering.HighDefinition
{
    [Serializable, VolumeComponentMenu("Post-processing/Shadow of the Road/Fog of War")]
    public sealed class FogOfWar : VolumeComponent, IPostProcessComponent
    {
        public ColorParameter fogColor = new ColorParameter(new Color(0,0,0,0), false, true, true);
        public TextureParameter map = new TextureParameter(null);
        public ColorParameter mapTint = new ColorParameter(new Color(0,0,0,0), false, true, true);
        public FloatParameter mapScale = new FloatParameter(1f);
        public Vector2Parameter mapPosition = new Vector2Parameter(new Vector2(0,0));
        public ClampedIntParameter iterations = new ClampedIntParameter(1, 0, 64);

        public bool IsActive()
        {
            return map.value != null || fogColor.value.a > 0;
        }
    }
}
