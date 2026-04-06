## Developer Request

This project is AGPL-3.0. If you modify this plugin and use it in a public-facing project, you are obligated to make your modified source code available. While I can't stop you from using modifications privately I strongly encourage you to contribute improvements back. If you've optimized something or added a feature that helps you or your team, please consider a PR so everyone benefits.

This plugin is still being sold for money as a pre-built rbxm on the creator-store and itch.io offering convenience for those unfamiliar with building roblox projects. I strongly request that you do not publicly distribute any builds as this is my primary way of earning money off the project.

While the source is open, building and maintaining this tool takes significant time. The best way to ensure this plugin remains updated and compatible with the latest Roblox engine changes is to purchase the pre-built version on the Creator Store or Itch. Thanks!

# Photobooth Plugin

![](docs/assets/readme/general/header.png)

Photobooth is a plugin that allows you to capture images of the workspace or UI elements entirely in Roblox studio.

Notably, it features the ability to remove skyboxes/backgrounds from images and bindings to allow developers to write their own capture workflows.

Results are output as editable images stored as a mesh part's texture.

[![](docs/assets/readme/badges/roblox-marketplace-badge.svg)](https://create.roblox.com/store/asset/82716202460157) [![](docs/assets/readme/badges/itch-badge.svg)](https://egomoose.itch.io/rbx-photobooth-plugin)

[Devforum post](https://devforum.roblox.com/t/3401720)

<details>
<summary>Examples</summary>

![](docs/assets/readme/examples/RedDress.png)
![](docs/assets/readme/examples/Candle.png)
![](docs/assets/readme/examples/NeoVeg.png)
![](docs/assets/readme/examples/Spaceship.png)
![](docs/assets/readme/examples/Tree.png)
</details>

## Limitations

Photobooth has a couple of limitations that are worth noting. For most users these will likely not be of significant impact, but I'm listing them here so people can see them before getting the plugin.

General:
- The plugin can capture any resolution desired, but there are some stipulations. Please read the "Full Viewport Captures" section for more details.
- Photobooth can only be used during edit mode in studio. It cannot be used to capture anything during a studio play session.
- The built-in upload feature is currently disabled. You can still upload, but you have to write code to do it yourself. Read more about this further down the post.
- Using the emulator + photobooth only works correctly when on "actual resolution"
- The viewport must be visible when capturing. You cannot tab out of studio or switch to the script editor while a capture is in progress.
- `Studio Settings > Rendering > Graphics Mode = OpenGL` is unsupported (this is a Roblox bug).

Skybox removal:
- No atmosphere / fog support.
- Anything that cannot be frozen in place on screen is not supported. For example:
	- Terrain grass.
	- Force-field material.
- Retro color grading is highly recommended for best results, but not mandatory.

**Warning: This plugin will cause the screen to flash when removing skyboxes. Those with photosensitive epilepsy are advised caution when using this plugin.**

## Bindings

This plugin can be used for automation purposes. An example use case might be capturing icons for all the inventory items in your game thereby allowing you to avoid using viewport frames which are more expensive than traditional images.

To use this feature open the viewer and in the settings menu toggle "Bindings" to `true`.

![](docs/assets/readme/general/bindings_enabled.png)

Roblox may prompt you for script injection permissions.

![](docs/assets/readme/general/script_injection.png)

This will create a `ModuleScript` underneath `ServerStorage` which provides a typed interface that can be used to create automated capture workflows. Included are a couple of common template workflows to get you started.

For example:

```luau
local Photobooth = require(game.ServerStorage.Photobooth.Bindings)

local capture = Photobooth.captureViewport({
	rect = Rect.new(0, 0, 300, 300),
	type = "NoSkybox",
})
capture.Name = "Example"
capture.Parent = game.StarterGui
```

Fullscreen captures can be made with bindings by passing a rect that represents the viewport. I.e.

```luau
local viewportSize = workspace.CurrentCamera.ViewportSize
local capture = Photobooth.captureViewport({
	rect = Rect.new(Vector2.zero, viewportSize),
	type = "NoSkybox",
})
```

Captures should be parented as a descendant of StarterGui. This ensures that they can be properly exported as pngs.

### OS scaling

With the advent of high resolution monitors many computers use scaling options built into their operating system to ensure that applications rendered on screen are not too small. Roblox however, always captures in full resolution leading to a number of UX problems.

Photobooth will attempt to resolve this issue automatically, but for the highest quality image when using bindings it is strongly recommended to use your monitor's true resolution.

![](docs/assets/readme/general/scale150.png)

*i.e. use scale 100% and the display resolution that matches your monitor.*

<details>
<summary>Or on Mac</summary>

![](docs/assets/readme/general/scale_mac.png)
</details>

## Full Viewport Captures

In cropped capture mode this plugin has a `2048 x 2048` limit. However, it is possible to circumvent this by capturing the entire viewport window. You can toggle to full viewport capture mode from the action bar or in the settings menu.

To set an arbitrary size you can either resize your viewport (not recommended) or take advantage of custom device resolutions on the emulator.

![](docs/assets/readme/general/emulator.jpg)

It's very important that you use the "Actual Resolution" option when capturing in the emulator. For very large dimensions that don't fit on screen I recommend temporarily switching to "Fit to Window", setting up the scene, and then switching back to "Actual resolution" once you're ready to capture.

> **Note:** Full viewport captures will result in images with their dimensions as `viewportSize * osScale`. It is highly recommened to adjust your display settings such that os scale is `(1, 1)` when using full viewport captures.

## Experimental Mode

As of v1.2.0 Photobooth now supports a new setting called experimental mode. Enabling this requires restarting studio and is not available during team create sessions.

Experimental mode is a way to provide speculative features to the public without making any guarantees that the behavior will remain supported in the future. If you enable this mode you should be aware that any behavior it exposes may be removed and should not be relied on.

<details>
<summary>Experimental Features:</summary>

- `Experimental_NSB_A1` is a viewport capture mode that attempts to allow capturing with atmosphere in lighting

</details>


## Saving Captures as PNGs

If you want to save any of the plugin captures to your computer, you can do so by right clicking the exported mesh part and selecting "Export Selection". This will prompt you to export the mesh in `.obj` format which will include the texture of the mesh in `.png` format. Both the `.obj` and `.mtl` files can be discarded.

If you want to export many images at the same time. First group all the mesh parts together as a model and then export that model.

<img src="docs/assets/readme/general/exportA.png" height=400> <img src="docs/assets/readme/general/exportB.png" height=400>

#### GLTF Exports

Alternatively, you can also export your photobooth selection in the [glTF format](https://devforum.roblox.com/t/gltf-export-beta-available-now/3905928). This may be preferable as many users have reported that sometimes exporting as an obj can crash studio.

In order to extract the pngs from the glTF file you'll need an additional tool. For convenience I've created a website found [here](https://egomoose.github.io/photobooth-plugin-site/) where you can drag and drop the export and get the resulting pngs.

## Uploading

**This feature is currently disabled!**

Uploading will be enabled in the future once Roblox provides the proper security tooling to allow creator store plugins to upload assets on your behalf. More detail from Roblox [here.](https://devforum.roblox.com/t/beta-lua-asset-creation-for-creator-tooling-with-createassetasync/3294134)

For now, developers will have to write their own code to upload editable images.

<details>
<summary>Sample Code</summary>

```luau
local ATTRIBUTE_NAME = "UploadResult"

local AssetService = game:GetService("AssetService")
local SelectionService = game:GetService("Selection")

for _, selected in SelectionService:Get() do
	if selected:IsA("MeshPart") and not selected:GetAttribute(ATTRIBUTE_NAME) then
		local content = selected.TextureContent
		local object = content and content.Object

		if object and object:IsA("EditableImage") then
			local result, value = AssetService:CreateAssetAsync(object, Enum.AssetType.Image, {
				Name = selected.Name,
				Description = "",
				IsPackage = false,
			})

			if result == Enum.CreateAssetResult.Success then
				selected:SetAttribute(ATTRIBUTE_NAME, `rbxassetid://{value}`)
			end
		end
	end
end
```
</details>
<br/>

When this feature is enabled this is what the upload process will look like:

<img src="docs/assets/readme/general/upload.png" width=70%>