# Limitations

There are a few situations that don't render well with the skybox removal algorithm. This file acts as both documentation and explanation for those cases. However, for the most part, I'm of the opinion that these are acceptable limitations and likely will not impact what you're trying to capture in a significant way.

### Grass

Unfortunately, there's no way to capture grass with the background removed as it requires nothing to move for the duration of the capture process. Currently there are no known methods to freeze the motion of Roblox's terrain grass. So it is recommended to turn off `Terrain.Decoration` when using this plugin.

### No Atmosphere / Fog

Atmosphere and fog can make it impossible to have a pure white and black background and as a result are disabled for the duration of a capture.

### Color correction effects

This applies to certain configurations of the effect that impact the ability to get pure white and pure black backgrounds.

This includes:
1. `Contrast < 0`
2. `Brightness > 0`

This effect does not get disabled by the plugin, so it's recommended to disable it manually before taking screenshots.