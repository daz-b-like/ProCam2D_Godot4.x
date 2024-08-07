# ProCam2D - A Custom 2D Camera Node for Godot

![procam icon](https://i.ibb.co/dkT2tPQ/procam-icon.png)

[![ko-fi](https://ko-fi.com/img/githubbutton_sm.svg)](https://ko-fi.com/dazlike)

## Overview

![ProCam2D Icon](https://i.ibb.co/s2Ht4RK/pcam.png) **ProCam2D** is a powerful and feature-rich custom 2D camera node designed for the Godot Engine. It aims to provide developers with a AAA-quality camera system suitable for all types of 2D games. ProCam2D is a standalone camera solution that surpasses the built-in Camera2D node, offering extensive customization and control.

## Key Features

- **Standalone 2D Camera**: Works independently, providing advanced features out of the box.
- **Extensible with Addons**: Comes with three addons for mouse follow, shake, and grid movement. Developers can write their own addons to extend functionality.
- **Autoload Control**: The camera is controlled by an autoload called `procam`, making it easy to access all properties and methods from any script.
- **Multiple Camera Behaviors**: Includes 6 additional nodes to control various behaviors such as cinematics, magnet attraction or repulsion, zoom control, room constraints, path constraints, and target following.

## Installation

1. Download or clone the ProCam2D repository.
2. Copy the `ProCam2D` folder into your Godot project’s `addons` directory.
3. Enable the ProCam2D plugin in your project settings.
4. Save and Reload your project from the `project` menu to ensure the plugin is properly loaded.

## Usage

### Basic Setup

1. Press `CTRL` + `A` or the "+" icon on the scene tab to add a new node.
2. Type "pcam" in the search box to filter the nodes and show all 7 ProCam2D nodes.
   
   ![Adding ProCam nodes](https://i.ibb.co/jhzqrWC/image.png)
   
3. Add a `ProCam2D` node to your scene.
4. Add one or more `PCamTarget` nodes as children of the objects you want the camera to follow.
5. Configure the camera properties and target properties via the inspector.

### Example: Basic Camera Setup

```gdscript
extends Node2D

func _ready():
    procam.set_follow_mode(ProCam2D.FollowMode.SINGLE_TARGET)
```

### Example: Adding Addons

Addons can be easily added to the `ProCam2D` node by following these steps:
1. Click on the `Addons` property on the inspector and increase its `Array` size:

   ![Adding addons](https://i.ibb.co/bmqMV8j/image.png)

2. Click on any [empty] fields and choose your addon from the list of resources:

   ![Adding addons](https://i.ibb.co/3kBgXgw/image.png)

3. Configure the addons properties:

   ![Adding addons](https://i.ibb.co/vsWh0fG/image.png)
   
If you added an addon through the inspector, you can access it like this:
```gdscript
func _ready():
    var shake_addon = procam.get_addons()[index] # Replace index with the index of the addon on the inspector. 
    shake_addon.shake() #Use this method to start any shake addon
    shake_addon.stop() #Use this method to stop any shake addon
```

   ![addon index](https://i.ibb.co/b7Tc6Vf/image.png)

To add an addon through code, use this method:
```gdscript
func _ready():
    var shake_addon = PCamShake.new()
    shake_addon.apply_preset(shake_addon.Preset.GUNSHOT) # This is a method available to the screenshake addon
    procam.add_addon(shake_addon)
    shake_addon.shake() # This is a method available to the screenshake addon see below for all available addons
```
## Available addons
Addons are processed in order of their priority. from lowest to highest.

### PCamShake

This addon is used to add exciting screenshakes to your game.

   ![shake](https://i.ibb.co/vsWh0fG/image.png)

### Enums
- **ShakeType**
  - `VERTICAL`: Shakes the screen vertically, moving up and down.
  - `HORIZONTAL`: Shakes the screen horizontally, moving left and right.
  - `RANDOM`: Generates random shakes in all directions, creating an unpredictable effect.
  - `PERLIN`: Uses Perlin noise to generate smooth, natural-looking random shakes.
  - `ROTATE`: Rotates the screen around its center point, simulating a rotational shake.
  - `CIRCULAR`: Shakes the screen in a circular motion, combining horizontal and vertical movement.
  - `ZOOM`: Simulates a zooming effect, shaking the screen by scaling in and out.

- **Preset**
  - `GUNSHOT`: A quick and sudden shake, simulating the recoil of a gunshot.
  - `EARTHQUAKE`: A continuous and intense shaking, mimicking the effect of an earthquake.
  - `HANDHELD`: Mimics the natural, unsteady movement of a handheld camera.
  - `EXPLOSION`: A strong and rapid shake, representing the shockwave of an explosion.
  - `IMPACT`: A brief, intense shake, simulating the effect of a sudden impact.
  - `RUMBLE`: A low-frequency, continuous shaking effect, like a deep vibration.
  - `VIBRATION`: A rapid, high-frequency shake, similar to a vibrating effect.
  - `WOBBLY`: A smooth and gentle shaking, creating a wobbly, unsteady motion.
  - 
### Methods
- `set_preset(preset: Preset)`: Sets the current shake effect to a predefined preset. E.g : `set_preset(PCamShake.Preset.GUNSHOT)`
- `stop()`: Stops the current screen shake effect immediately.
- `is_shaking() -> bool`: Returns a boolean indicating whether a screen shake effect is currently active.
- `shake()`: Initiates a custom screen shake effect based on the current settings.

### PCamGrids

This addon is used to make the camera snap to grid. The snapping will be smooth or instant depending on the camera's `smooth_drag` property.

   ![grids](https://i.ibb.co/3c649s5/image.png)

### PCamMouseFollow

This addon adds pointer influence to the camera. Can be used for side scrollers that use the mouse for aiming or looking around.

![mouse folllow](https://i.ibb.co/27w1gJw/image.png)

## ProCam2D Properties

### Enums

- **FollowMode**
  - `SINGLE_TARGET`: The camera follows a single target with the highest priority, ideal for focusing on one main character or object.
  - `MULTI_TARGET`: The camera can follow multiple targets, useful for multiplayer games or scenes with multiple points of interest.

- **DragType**
  - `SMOOTH_DAMP`: Smoothly follows the target with a damping effect, providing a natural and gradual motion.
  - `LOOK_AHEAD`: Allows the camera to look ahead of the target's movement, enhancing anticipation in fast-paced games.
  - `AUTO_SPEED`: Automatically adjusts the camera speed based on the target's speed.
  - `SPRING_DAMP`: Uses a spring-damping effect for following the target, creating a bouncy and responsive feel.

### Camera Properties

- `process_mode`: Controls the processing mode of the camera.
- `follow_mode: int`: Sets the follow mode (SINGLE_TARGET or MULTI_TARGET).
- `drag_type: int`: Sets the drag type (SMOOTH_DAMP, LOOK_AHEAD, AUTO_SPEED, SPRING_DAMP).
- `smooth_drag: bool`: Enables or disables smooth dragging.
- `smooth_drag_speed: Vector2`: Sets the speed of smooth dragging.
- `prediction_time: Vector2`: Defines the prediction time for look-ahead functionality.
- `offset: Vector2`: Sets the offset of the camera from the target.
- `smooth_offset: bool`: Enables or disables smooth offset.
- `smooth_offset_speed: float`: Sets the speed of smooth offset.
- `allow_rotation: bool`: Enables or disables camera rotation.
- `smooth_rotation: bool`: Enables or disables smooth rotation.
- `smooth_rotation_speed: float`: Sets the speed of smooth rotation.
- `zoom: float`: Sets the camera's zoom level.
- `smooth_zoom: bool`: Enables or disables smooth zooming.
- `smooth_zoom_speed: float`: Sets the speed of smooth zooming.
- `auto_zoom: bool`: Enables or disables automatic zoom adjustment to fit multiple targets.
- `min_zoom: float`: Sets the minimum zoom level for automatic zoom.
- `max_zoom: float`: Sets the maximum zoom level automatic zoom.
- `zoom_margin: float`: Defines the margin around targets when adjustmenting zoom automatically.
- `smooth_limit: bool`: Enables or disables smooth limiting of the camera's bounds.
- `left_limit: int`: Sets the left boundary of the camera.
- `right_limit: int`: Sets the right boundary of the camera.
- `top_limit: int`: Sets the top boundary of the camera.
- `bottom_limit: int`: Sets the bottom boundary of the camera.
- `use_h_margins: bool`: Enables or disables horizontal margins.
- `use_v_margins: bool`: Enables or disables vertical margins.
- `left_margin: float`: Sets the left margin.
- `right_margin: float`: Sets the right margin.
- `top_margin: float`: Sets the top margin.
- `bottom_margin: float`: Sets the bottom margin.

### Public Methods

- `start_cinematic(id)`: Starts a cinematic sequence with the given ID.
- `stop_cinematic()`: Stops the current cinematic sequence.
- `get_camera_bounds()`: Returns the current camera bounds as a `Rect2`.
- `reset_camera()`: Resets the camera to its target position, rotation and zoom.
- `add_addon(addon: PCamAddon)`: Adds an addon to the camera.
- `get_addons() -> Array`: Returns an array of all attached addons.
- `remove_addon(addon: PCamAddon)`: Removes an addon from the camera.
- `set_position(new_position: Vector2)`: Sets the camera's position.
- `set_rotation(new_rotation: float)`: Sets the camera's rotation.
- `set_zoom(new_zoom: float)`: Sets the camera's zoom level.

### Signals

- `cinematic_started(cinematic_id)`: Emitted when a cinematic sequence starts.
- `cinematic_stopped(cinematic_id)`: Emitted when a cinematic sequence stops.
- `addon_message(message)`: Emitted when an addon sends a message.


## Additional Nodes

### ![PCamTarget Icon](https://i.ibb.co/GT64yr8/pcam-target.png) PCamTarget

A node that the camera follows. It can be placed as a child of a player. Multiple targets can be placed.

   ![PCamTarget](https://i.ibb.co/JdyymHT/image.png)

#### Properties

- `priority: int`: Determines the active target when follow mode is set to SINGLE_TARGET. Higher priority targets are followed.
- `radius: float`: Defines the target area for auto-zoom functionality.
- `offset: Vector2`: Sets the positional offset of the target.
- `influence: Vector2`: Determines how much the target influences the camera movement. Values range from 0 (no influence) to 1+ (full influence).
- `rotation_influence: float`: Determines how much the target's rotation influences the camera. Values range from 0 (no influence) to 1+ (full influence).
- `disable_outside_limits: bool`: The camera stops following this node once it goes beyond it's limits.

### ![PCamCinematic Icon](https://i.ibb.co/QjHd0RT/pcam-cinematic.png) PCamCinematic

Defines a point in a cinematic sequence. PCamCinematic nodes with the same id form a cinematic sequence which can be played with `procam.start_cinematic(id)`

   ![PCamCinematic](https://i.ibb.co/FqkG4YD/image.png)

#### Properties

- `cinematic_id: string`: Identifier for the cinematic sequence, used to start and stop specific cinematic events. Can be an integer or string.
- `hold_time: float`: Duration in seconds for which the camera holds the cinematic state before transitioning.
- `target_zoom: float`: Desired zoom level during the cinematic sequence.
- `drag_speed: Vector2`: Speed at which the camera follows the target during the cinematic, affecting how quickly it drags to the new position.
- `rotation_speed: float`: Speed of camera rotation during the cinematic, controlling how quickly the camera rotates to match the `PCamCinematic`'s rotation.
- `zoom_speed: float`: Speed at which the camera zooms in or out during the cinematic.

### ![PCamMagnet Icon](https://i.ibb.co/6yPtVfB/pcam-magnet.png)  PCamMagnet

Attracts or repels the camera like a magnet.

   ![PCamMagnet](https://i.ibb.co/z7TwFwf/image.png)

#### Properties

- `magnet_shape: MagnetShape`: Defines the shape of the magnetic influence area. Options include `CIRCLE` or `RECTANGLE`.
- `attract_repel: AttractRepel`: Determines whether the magnet attracts or repels the camera. Options include `ATTRACT` or `REPEL`.
- `radius: float`: Radius of the influence area when `magnet_shape` is set to `CIRCLE`.
- `rectangle_size: Vector2`: Size of the influence area when `magnet_shape` is set to `RECTANGLE`.
- `use_full_force: bool`: Enables or disables full force application within the influence area.
- `force: Vector2`: Defines the strength of the force applied to the camera when within the influence area, if `use_full_force` is disabled.
- `falloff_curve: Curve`: A curve defining how the force diminishes with distance from the center of the influence area, if `use_full_force` is disabled.

#### Signals

- `magnet_entered()`: Emitted when the camera enters the magnet's area of influence
- `magnet_exits()`: Emitted when the camera exits the magnet's area of influence

### ![PCamZoom Icon](https://i.ibb.co/VJbnTwD/pcam-zoom.png) PCamZoom

Changes the zoom of the camera within its area of influence.

   ![PCamZoom](https://i.ibb.co/NY8sLGP/image.png)

#### Properties

- `zoom_shape: ZoomShape`: Defines the shape of the zoom influence area. Options include `CIRCLE` or `RECTANGLE`.
- `radius: float`: Radius of the influence area when `zoom_shape` is set to `CIRCLE`.
- `rectangle_size: Vector2`: Size of the influence area when `zoom_shape` is set to `RECTANGLE`.
- `zoom_factor: float`: Factor by which the camera zooms in or out when within the influence area.
- `gradual_zoom: bool`: Enables or disables gradual zooming when entering or exiting the influence area.

#### Signals

- `zoom_area_entered()`: Emitted when the camera enters the zoom's area of influence.
- `zoom_area_exited()`: Emitted when the camera exits the zoom's area of influence.
- `zoom_level_changed()`: Emitted when the zoom's zoom level changes.

### ![PCamRoom Icon](https://i.ibb.co/GVVLdYZ/pcam-room.png) PCamRoom

Constrains the camera to an area it covers.

   ![PCamRoom](https://i.ibb.co/C6XjM16/image.png)

#### Properties

- `room_size: Vector2`: Defines the dimensions of the room or constrained area that the camera is limited to.
- `zoom: float`: Sets the zoom level within the constrained room area.
- `open_sides: BitMask`: Specifies which sides of the room are open (left, right, top, bottom). Checkboxes for each side allow for customizable room constraints.

#### Signals
- `room_entered(room)`: Emitted when the camera enters the room.
- `room_exited(room)`: Emitted when the camera exits the room.

### ![PCamPath Icon](https://i.ibb.co/B2spgmh/pcam-path.png) PCamPath

Constrains the camera to a path on a specified axis.

  ![PCamPath](https://i.ibb.co/QHV9Xtq/image.png)

#### Properties
- `constraint_axis: AxisConstraint`: Defines which axis (X or Y) the camera is constrained to follow along the path. Options include `X` and `Y`.

## Addons

ProCam2D is designed to be extensible. You can create your own addons to add custom functionality to the camera.

### Writing Your Own Addon

Creating an addon for the camera system involves extending the `PCamAddon` class. This class provides a standardized way to modify camera behavior in different stages: `pre_process`, `post_smoothing`, and `final_adjust`. Each stage allows you to adjust the camera's properties at different points in the update cycle.

#### Addon Structure

An addon inherits from the `PCamAddon` class and should implement the following methods:

1. **`setup(camera)`**: Called when the addon is initialized. Use this method to set the initial state or configurations, such as defining the stage in which the addon operates.
2. **`exit(camera)`**: Called when the addon is disabled or removed. Use this to clean up or reset any changes made by the addon.

In addition to these lifecycle methods, an addon should override one of the following methods to define its behavior during a specific stage:

- **`pre_process(camera, delta)`**: This method is used for modifications to the camera's target properties before any smoothing is applied. It’s ideal for setting `_target_zoom`, `_target_rotation`, and `_target_position` of the passed in camera.

- **`post_smoothing(camera, delta)`**: This method is used for adjustments after the camera’s target properties have been smoothed but before final adjustments. It’s ideal for setting `_current_zoom`, `_current_rotation`, and `_current_position` of the passed in camera.

- **`final_adjust(camera, delta)`**: This method allows for final modifications to the camera's properties after all other processing. It is often used for post-processing effects or final tweaks.

#### Properties

- **Target Properties**: These are properties adjusted during the `pre_process` stage. They include `_target_zoom`, `_target_rotation`, and `_target_position`.
- **Current Properties**: These are properties adjusted during the `post_smoothing` or `final_adjust` stages. They include setting `_current_zoom`, `_current_rotation`, and `_current_position` of the passed in camera.

### Sample Addon: Grids

This addon aligns the camera's target position to a grid, ensuring that movement snaps to predefined intervals.

```gdscript
tool
extends PCamAddon
class_name PCamGrids

export var grid_size := Vector2(64, 64)
export var grid_offset := Vector2.ZERO

func setup(camera):
	stage = "pre_process"

func pre_process(camera, delta):
	# Snap the target position to the grid and apply an offset if needed
	var snapped_target = camera._target_position.snapped(grid_size) + grid_offset
	camera._target_position = snapped_target
```

The addon will now show up on the list of resources. You can then add it to the camera through the inspector or like so:

```gdscript
var grid_addon = PCamGrids.new()
func _ready() -> void:
    procam.add_addon(grid_addon)
```

### Implementing a New Addon

To create your own addon:

1. **Define the Addon**: Extend `PCamAddon` and set up any necessary properties or export variables.
2. **Set Up Stages**: Use the `setup` method to specify the stage in which the addon should operate. Implement the corresponding method (`pre_process`, `post_smoothing`, or `final_adjust`) to define the addon's behavior.
3. **Enable the Addon**: Ensure your addon is enabled by setting the `enabled` property to `true`.

This framework provides a flexible way to modify camera behavior by compartmentalizing changes into different processing stages.

## Support

If you find ProCam2D useful and would like to support its development, consider buying me a coffee:

[![ko-fi](https://ko-fi.com/img/githubbutton_sm.svg)](https://ko-fi.com/dazlike)

## Contributing

Contributions are welcome! For detailed instructions on how to contribute, please see our [Contributing Guide](CONTRIBUTING.md).

## Reporting Bugs or Requesting Features

To report a bug or request a feature, please use the [Issues](https://github.com/daz-b-like/ProCam2D_Godot4.x/issues) section of this repository. Make sure to follow the templates provided for better clarity and organization.

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

Thank you for using ProCam2D! If you have any questions or need further assistance, feel free to reach out.

