# Slider

`Slider` is a `UIControl` that mimics `UISlider`, but with multiple thumbs. It does not perfectly mirror the API of `UISlider` so is not suitable as a drop-in replacement, although this would be the ideal outcome down the road.

# Appearance

The images included in this project are duplicates of the default `UISlider` images. They are rendered as template images with slicing enabled.

## Known Differences

 - Since the `minimumValueImage` and `maximumValueImage` properties are not implemented they are not taken in to account when sizing. This would need to be done if they were ever added. Since the position and values of the thumbs are calculated using the size of the track it should be possible to simply update `trackRect(forBounds:)` to support these images.
 - The intrinsic content size of a `UISlider` appears to increase the width by `4`. Until I figure out why this is I am hesitant to hardcode this.
 - The tap area of the thumb is the image itself, not the image plus some padding. In a `UISlider` they seem to have a larger `UIImageView` that doesn't have an image, and then place a smaller `UIImageView` inside that has the thumb image in it. I think increasing the hit area via `hitTest` might work as an interim solution, but this something similar to how `UISlider` does it is probably better long-term.
 - A bunch of the API that we would not need are not implemented, e.g. `isContinuous`

# Use of Manual Layout

`Slider` does not use AutoLayout internally, but rather overrides `layoutSubviews()`. This was done because it simplifies a lot of the code around knowing what the value difference should be, and is overall less complex than AutoLayout.

# Roadmap

Eventually I would love for the project to be open-source, but for now I think it's best to keep it closed. Some of code (such as the scaling options I will pull in) were originally implemented in a personal project, but the majority of the work was done while at Thread so it should live under the Thread GitHub account.

A rough roadmap that I would say moves us to a 1.0 would be:

 - [X] Fix slider tracks slicing
 - [X] Snap to step value
 - [X] Support dynamic ranges for values, so lower and upper values can be equal while being visually separated
 - [X] Track sliding of thumbs via `touches*` functions
  - This would allow the movement to be immediate, rather than the slight delay introduced by using gesture recognizers
 - [ ] Fix tracking when using a `step`
  - Sometimes the thumbs will not move close enough to be equal
  - Sometimes moving one slider close to the other will change its value
 - [ ] Fix positioning of coloured track
  - Sometimes the track will start/end in the wrong position. I think it just needs a layout; I'm pretty sure the calculation is correct
 - [ ] Increase tap area of thumbs
 - [ ] Add custom assets for track and thumb
  - Replicating the defaults in iOS 11-13 would be hard. Probably best to just bundle some defaults that are similar to a single iOS version
 - [X] Tests for the scaling options
 - [X] Fix stepped scaling option
 - [X] Move to `github.com/Thread/Slider` or similar
 - [ ] Create as Swift Package
  - With a lack of support for bundling assets this may not be possible, unless the images are created programmatically
 - [ ] Open source

In the future we may add:

 - [X] `OSLog` support
 - [ ] Snapshot tests to compare to the system `UISlider` on various device screen scales
 - [ ] Fix width being different to `UISlider`
 - [ ] Support different images per-state
 - [ ] `IBDesignable` support
 - [ ] API mirroring with `UISlider`. Other than `value` property this should be possible
   - Another option is to make `value` the result of `upperValue` - `lowerValue`
 - [ ] Support a single thumb
   - This will also require the minimum track slicing to be correct
 - [ ] Accessibility support