# Changelog
This project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

### [1.2.1] - 2025/11/30
- `Reversible.wrap` now warns when a recording is in progress as opposed to failing outright.

### [1.2.0] - 2025/11/24
- Fix "SourceSans" warning showing up in the output
- Add experimental mode (more details in the devforum post)
  - Add `Experimental_NSB_A1` capture type which attempts to capture with atmosphere enabled

### [1.1.2] - 2025/11/21
- Fixed captures not correctly handling color correction effects

### [1.1.1] - 2025/11/20
- Flipped the normals on the quad mesh so they're now facing the right way

### [1.1.0] - 2025/11/20
- The exported mesh parts are now quads (as opposed to empty meshes) this allows the ability to export in glTF format
- Added support for `scale` field in the `Bindings.captureUI` options to achieve parity with `captureViewport` 

### [1.0.2] - 2025/11/19
- Fixes an issue where the camera could be moved during UI captures
- Internally use `:QueryDescendants()` over `:GetDescendants()`

### [1.0.1] - 2025/11/19
- Fix an issue with delaying with a viewport binding capture

### [1.0.0] - 2025/11/19
- Outdated versions of photobooth now notify (in a non-intrusive way) that an update is available in the settings window.
- Breaking changes for the bindings module:
  - The module is now parent under a camera instance. This avoids replicating the bindings in a team create setting.
  - `captureViewport` and `captureUI` now return `nil` upon failure without throwing an unhelpful warn in the output window
  - `captureViewport` and `captureUI` now use an options table which allows for much more granularity over capture results.
  - Optional `alphaBleed` param can be used to override the user's alpha bleed setting.
  - Optional `scale` param can be used to better control how the camera adjusts for a capture when using a non-unit os scale.

### [0.9.0] - 2025/11/13
- Replaces the checkerboard image asset in the gallery
- Refactors the state management system
  - This will reset existing saved settings
- Adds a stroke and bolds the error text in the cropped and fullscreen capture mode for better contrasts
- Removes additional dead code

### [0.8.5] - 2025/10/07
- Removed a lot of unused old code
- Binding helpers have been refactored / cleaned up
- Multi-image selection tab now has a min size constraint

### [0.8.4] - 2025/09/20
- Better feedback added when an error / warn occurs while using the cropped or full viewport mode.

### [0.8.3] - 2025/08/28
- Inherit ZIndexBehavior from nearest layer collector when capturing UI

### [0.8.2] - 2025/08/28
- Add support for Roblox's UI styling feature when capturing UI
- Fix an issue where the UI capture subject would sometimes be one pixel too small when capturing

### [0.8.1] - 2025/08/16
- Fix some UI scaling clipping in the gallery

### [0.8.0] - 2025/08/08
- New gallery viewer supports selecting and viewing multiple images
- New upload wizard that supports uploading multiple images
- Add a UI capture delay parameter to the bindings to ensure subjects like viewport frames have time to load
- `PhotoboothBindings.execute` now cachelessly loads sub requires

### [0.7.0] - 2025/07/31
- Support cropped capture up to 2048 x 2048!!!

### [0.6.5] - 2025/07/31
- The UI capture process no longer relies on canvas groups which should increase capture quality.
- UI captures now yield a render frame before capturing to (hopefully) allow certain elements (e.g. viewport frames) to load.
- Captures that are larger than the edit image max are now chunked in the gallery viewer so they once again display in their fully glory!

### [0.6.4] - 2025/07/04
- Fixes issue where skybox was not properly removed in viewport captures when `Lighting.ExposureCompensation` was not equal to zero.

### [0.6.3] - 2025/05/16
- Fixed cropped viewport size retaining when toggling fullscreen through the settings menu

### [0.6.2] - 2025/05/16
- Add fullscreen toggle bar on viewport capture action bar UI
- Add lune serve workflow for sending images over network for debug purposes
- Retain cropped viewport size in viewport capture UI when toggling between fullscreen mode and when open / closing the app
- No longer saves the fullscreen setting between sessions
- When OS Scale is not `(1, 1)` hide the viewport capture UI

### [0.6.1] - 2025/04/29
- Settings are now saved between sessions.

### [0.6.0] - 2025/04/08
- Fixes an issue where futures in the parallel module were wasting memory.
- Refactor history change service tracking in bindings.
- Removed `PhotoboothBindings.cancellable` in favor of `PhotoboothBindings.reversible`.
  - If an error occurs in the callback block the changes made via code in that block will be reverted.
  - Alternatively, the author can manually cancel / revert an in-progress block.

### [0.5.4] - 2025/03/31
- Fixes another issue (!) where the edges from the cropped viewport capture mode were being caught in the capture on non `(1, 1)` os scaled devices.
- Refactor the parallel luau helper module to better support relative paths and typecasting
- Fix some typing issues related to the future module

### [0.5.3] - 2025/03/27
- Adds a more generalized React hook for using the selected editable image of an instance
- Fixes a rounding issue when calculating the capture rect in cropped viewport mode with OS scales that aren't `(1, 1)`

### [0.5.2] - 2025/03/13
- Add `getVersion` to bindings. This returns the semver of the plugin in string form.
- Fix fullscreen captures when os scale is not `(1, 1)`
  - The resulting dimensions of the capture in this case will be `viewportSize * osScale`

### [0.5.1] - 2025/03/07
- The action bar now scales when using a very tiny viewport window + fullscreen mode.
- Fix issue where parallel luau compositions wouldn't work for images with height < 32 pixels.
- The dimensions text label in the gallery now uses a fixed size and moves to the bottom left corner when the image is not wide enough.

### [0.5.0] - 2025/03/06
- Use parallel luau for image composition.
  - The algorithm for removing backgrounds is significantly faster now.

### [0.4.0] - 2025/03/05
- Removed the full screen action and instead added a toggle to the settings menu

### [0.3.1] - 2025/03/04
- Fix rounding error for display size in full viewport capture mode
- Refactor bindings module
- Remove the drop shadow UI template
  - This template felt too complex for a basic example so I removed it. In the future I'd like to create a public repository that the community can contribute templates of all varieties. The drop shadow template would likely make its return there in some form.

### [0.3.0] - 2025/02/08
- Add full viewport capture support (say goodbye to the 1024x1024 limit)
- Alpha bleeding changes:
  - Fix incorrect assumption about bleeding one pixel
  - Add option to disable alpha bleeding
- Add ability to change background of an image being viewed in the gallery by right clicking
- Icons no longer use local assets and instead all have asset ids
- Uploading an editable image no longer makes a copy before opening the upload wizard
- Attempting to capture with a mismatched OS scale now warns

### [0.2.2] - 2025/01/25
- Add support for transparent glass

### [0.2.1] - 2025/01/24
- Check for `CreateAssetAsync` API to show / hide upload button

### [0.2.0] - 2025/01/23
- Add new plugin action (`Photobooth Focus`) which allows user to focus their camera on a selection and fit the capture frame in the viewport
- Alpha bleed fixes
  - Algorithm now only bleeds one pixel which saves a lot of time on images with a lot of transparency
  - Fix algorithm mistake where pixels could sample their neighbors before they should be allowed to

### [0.1.1] - 2025/01/21
- Add full color correction support!
- Fix maintain aspect ratio when holding ctrl and dragging viewport corners
- Unify plugin names:
  - “Photo Booth” → “Photobooth”
  - “Viewer” → “Gallery”
- Gallery button properly toggles off when player closes the dock minimized
- Add version number in the settings