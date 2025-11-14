# Changelog
This project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [0.9.0]
### Changes
- Replaces the checkerboard image asset in the gallery
- Refactors the state management system (this will reset existing settings)
- Adds a stroke and bolds the error text in the cropped and fullscreen capture mode for better contrasts
- Removes additional dead code

## [0.8.5]
### Changes
- Removed a lot of dead code
- Binding helpers have been revamped / cleaned up
- Multi-image selection tab now has a min size constraint

## [0.8.4]
### Added
- Better feedback added when an error / warn occurs while using the cropped or full viewport mode.

## [0.8.3]
### Fixed
- Inherit ZIndexBehavior from nearest layer collector when capturing UI

## [0.8.2]
### Fixed
- Add support for Roblox's UI styling feature when capturing UI
- Fix an issue where the UI capture subject would sometimes be one pixel too small when capturing

## [0.8.1]
### Fixed
- Fix some UI scaling clipping in the gallery

## [0.8.0]
### Added
- New gallery viewer supports selecting and viewing multiple images
- New upload wizard that supports uploading multiple images
- Add a UI capture delay parameter to the bindings to ensure subjects like viewport frames have time to load

### Changes
- `PhotoboothBindings.execute` now cachelessly loads sub requires

## [0.7.0]
### Added
- Support cropped capture up to 2048 x 2048!!!

## [0.6.5]
### Fixed
- The UI capture process no longer relies on canvas groups which should increase capture quality
- UI captures now yield a render frame before capturing to (hopefully) allow certain elements (e.g. viewport frames) to load
- Captures that are larger than the edit image max are now chunked in the gallery viewer so they once again display in their fully glory!

## [0.6.4]
### Fixed
- Fixes issue where skybox was not properly removed in viewport captures when `Lighting.ExposureCompensation` was not equal to zero. 

## [0.6.3]
### Fixed
- Fixed cropped viewport size retaining when toggling fullscreen through the settings menu

## [0.6.2]
### Added
- Add fullscreen toggle bar on viewport capture action bar UI
- Add lune serve workflow for sending images over network for debug purposes

### Changes
- Retain cropped viewport size in viewport capture UI when toggling between fullscreen mode and when open / closing the app
- No longer saves the fullscreen setting between sessions
- When OS Scale is not (1, 1) hide the viewport capture UI

## [0.6.1]
### Changes
- Settings are now saved between sessions.

## [0.6.0]
### Changes
- Refactor history change service tracking in bindings.
- Removed `PhotoboothBindings.cancellable` in favor of `PhotoboothBindings.reversible`.
  - If an error occurs in the callback block the changes made via code in that block will be reverted.
  - Alternatively, the author can manually cancel / revert an in-progress block.

### Fixed
- Fixes an issue where futures in the parallel module were wasting memory.

## [0.5.4]
### Changed
- Refactor the parallel luau helper module to better support relative paths and typecasting

### Fixed
- Fixes another issue (!) where the edges from the cropped viewport capture mode were being caught in the capture on non `(1, 1)` os scaled devices.
- Fix some typing issues related to the future module

## [0.5.3]
### Changed
- Adds a more generalized React hook for using the selected editable image of an instance

### Fixed
- Fixes a rounding issue when calculating the capture rect in cropped viewport mode with OS scales that aren't `(1, 1)`

## [0.5.2]
### Added
- Add `getVersion` to bindings. This returns the semver of the plugin in string form.

### Fixed
- Fix fullscreen captures when os scale is not `(1, 1)`
  - The resulting dimensions of the capture in this case will be `viewportSize * osScale`

## [0.5.1]
### Changed
- The action bar now scales when using a very tiny viewport window + fullscreen mode.
- The dimensions text label in the gallery now uses a fixed size and moves to the bottom left corner when the image is not wide enough.

### Fixed
- Fix issue where parallel luau compositions wouldn't work for images with height < 32 pixels.

## [0.5.0]
### Added
- Use parallel luau for image composition.
  - The algorithm for removing backgrounds is significantly faster now.

## [0.4.0]
### Changes
- Removed the full screen action and instead added a toggle to the settings menu

## [0.3.1]
### Changes
- Refactor bindings module
- Remove the drop shadow UI template
  - This template felt too complex for a basic example so I removed it. In the future I'd like to create a public repository that the community can contribute templates of all varieties. The drop shadow template would likely make its return there in some form.

### Fixes
- Fix rounding error for display size in full viewport capture mode

## [0.3.0]
### Added
- Add full viewport capture support (say goodbye to the 1024x1024 limit)
- Add ability to change background of an image being viewed in the gallery by right clicking

### Changes
- Alpha bleeding changes:
  - Fix incorrect assumption about bleeding one pixel
  - Add option to disable alpha bleeding
- Icons no longer use local assets and instead all have asset ids
- Uploading an editable image no longer makes a copy before opening the upload wizard
- Attempting to capture with a mismatched OS scale now warns

## [0.2.2]
### Added
- Add support for transparent glass

## [0.2.1]
### Changes
- Check for `CreateAssetAsync` API to show / hide upload button

## [0.2.0]
### Changes
- Add new plugin action (`Photobooth Focus`) which allows user to focus their camera on a selection and fit the capture frame in the viewport

### Fixed
- Alpha bleed fixes
  - Algorithm now only bleeds one pixel which saves a lot of time on images with a lot of transparency
  - Fix algorithm mistake where pixels could sample their neighbors before they should be allowed to

## [0.1.1]
### Added
- Add full color correction support!
- Add version number in the settings

### Changes
- Unify plugin names:
  - "Photo Booth" → "Photobooth"
  - "Viewer" → "Gallery"

### Fixed
- Fix maintain aspect ratio when holding ctrl and dragging viewport corners
- Gallery button properly toggles off when player closes the dock minimized

## [0.1.0]
- Initial release