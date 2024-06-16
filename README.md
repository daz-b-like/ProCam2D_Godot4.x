![procam wallpaper.png](https://i.ibb.co/FnsPZxb/procam-wallpaper.png)


# ProCam2D Plugin

## Overview

Introducing the ProCam2D plugin! ProCam2D is the ultimate camera for all your 2D needs. Its designed to give you precise control over 2D camera behavior, whether you want to add smooth camera movement, dynamic zoom, or exciting screen shake effects. Our ProCam2D plugin, coupled with the TrackPoint node and a convenient Autoload script, can follow the action in your game with style and precision.

## Features

- Target-based camera tracking with dynamic target switching.
- Smooth transition and offset adjustments
- Various screen shake effects
- Flexible drag and rotation controls
- Zoom and boundary limits
- Multi-object tracking with target radius adjustment
- Controlled by a singleton named `ProCam` for efficiency. 

## Enums

### Process Type

- **PHYSICS_PROCESS**: Updates the camera during the physics process, ensuring it is in sync with physics-based movements and calculations.
- **IDLE_PROCESS**: Updates the camera during the idle process, which is suitable for non-physics related movements and effects.

### Screen Shakes

- **SCREEN_SHAKE_HORIZONTAL**: Applies a horizontal shake effect to the camera, simulating side-to-side movement.
- **SCREEN_SHAKE_VERTICAL**: Applies a vertical shake effect to the camera, simulating up-and-down movement.
- **SCREEN_SHAKE_PERLIN**: Uses Perlin noise to create a smooth, natural-looking shake effect.
- **SCREEN_SHAKE_RANDOM**: Applies a random shake effect, causing erratic camera movement for chaotic effects.
- **SCREEN_SHAKE_ZOOM**: Adds a shaking effect by rapidly zooming in and out, creating a pulsating effect.
- **SCREEN_SHAKE_ROTATE**: Applies a rotational shake effect, causing the camera to rotate back and forth.
- **SCREEN_SHAKE_CIRCULAR**: Creates a circular shaking motion, simulating a whirlpool or spinning effect.

### Drag Types

- **DRAG_TYPE_PRED**: Predictive drag that anticipates the target's movement and adjusts the camera smoothly to follow.
- **DRAG_TYPE_SPRING_DAMP**: Uses a spring-damping system to create a smooth follow effect, like a spring pulling the camera towards the target.
- **DRAG_TYPE_ADAPTIVE**: Adaptive drag that adjusts its speed based on the target's movement, providing a responsive camera behavior.
- **DRAG_TYPE_SMOOTH_DAMP**: Smooth damp drag that gradually smooths out the camera movement over time, ensuring fluid transitions.

## Properties

### Camera Position and Rotation

- `current_position`: `Vector2` - The current position of the camera.
- `current_rotation`: `float` - The current rotation of the camera.

### Target and Tracking

- `target`: `Object` - The target node the camera will follow.
- `track_multiple_objects`: `bool` - Enables tracking multiple objects using the PCTrackPoint node.
- `target_radius`: `float` - Controls the space the target takes on screen when tracking multiple objects.

### Offset and Process Type

- `offset`: `Vector2` - Offset from the target position. Useful for looking around.
- `process_type`: `int` - Determines if the camera updates in `PHYSICS_PROCESS` or `IDLE_PROCESS` mode.
- `offset_smoothly`: `bool` - Smooth transition for offset changes.
- `offset_speed`: `float` - Speed of the offset transition.

### Drag and Rotation

- `drag_smoothly`: `bool` - Smooth transition for dragging.
- `drag_speed`: `Vector2` - Speed of the drag.
- `drag_type`: `int` - Type of drag (Predictive, spring damp, smooth damp or adaptive)
- `rotate`: `bool` - Enables or disables camera rotation.
- `rotation_speed`: `float` - Speed of the camera rotation.
- `rotate_smoothly`: `bool` - Smooth transition for rotation.

### Zoom and Limits

- `zoom_level`: `float` - Zoom level of the camera.
- `zoom_smoothly`: `bool` - Smooth transition for zoom changes.
- `zoom_speed`: `float` - Speed of the zoom transition.
- `limit_smoothly`: `bool` - Smooth transition for camera limits.
- `left_limit`, `right_limit`, `top_limit`, `bottom_limit`: `float` - Boundary limits for the camera movement.

### Margins and Center

- `enable_v_margins`: `bool` - Enables vertical margins.
- `enable_h_margins`: `bool` - Enables horizontal margins.
- `drag_margin_left`, `drag_margin_right`, `drag_margin_top`, `drag_margin_bottom`: `float` - Margins for dragging.
- `screen_center`: `Vector2` - Center of the screen (read-only).

## Methods

### Start Screen Shake

Initiates a screen shake effect.

```gdscript
var types: = [SCREEN_SHAKE_HORIZONTAL, SCREEN_SHAKE_VERTICAL]
var duration: = 0.3
var magnitude: = 3.5
var speed: = 20.0
ProCam.start_shake(types, duration, magnitude, speed)
```

#### Parameters

- `types`: `Array` - Types of screen shakes to be combined separated by a comma(e.g., `[SCREEN_SHAKE_HORIZONTAL`, `SCREEN_SHAKE_VERTICAL]`).
- `duration`: `float` - Duration of the shake.
- `magnitude`: `float` - Magnitude of the shake.
- `speed`: `float` - Speed of the shake.

## Signals

- `target_changed(new_target, old_target)` - Emitted when the camera target changes.
- `zoom_level_changed(new_level, old_level)` - Emitted when the zoom level changes.
- `rotation_enabled()` - Emitted when rotation is enabled.
- `rotation_disabled()` - Emitted when rotation is disabled.
- `offset_changed(new_offset, old_offset)` - Emitted when the offset changes.
- `screen_shake_started(type)` - Emitted when screen shake starts.
- `screen_shake_finished(type)` - Emitted when screen shake finishes.
- `process_mode_changed(new_mode)` - Emitted when the process mode changes.

## PCTrackPoint Node

The PCTrackPoint node is used for defining specific points in the scene that the camera can track. This node needs to be added to the scene and `enabled` & `ProCam.track_multiple_objects` set to `true` in order for multi-object tracking to work. The camera will always keep these points and the target on the screen, automatically adjusting the zoom level if needed.

### Properties

- **radius**: `float` - Radius of the tracking point.
- **enabled**: `bool` - Enables or disables the tracking point.
- **debug_draw**: `bool` - Enables or disables debug drawing of the tracking point.

## Example Usage

```gdscript
extends Node2D

func _ready():
    ProCam.target = $Player
    ProCam.zoom_level = 1.5
    #start following the target's rotation.
    ProCam.rotate = true
    #start screen shake that never ends
    ProCam.start_shake([ProCam.SCREEN_SHAKE_CIRCULAR], INF, 5.0, 15.0)
    #start another shake that ends after 1 second
    ProCam.start_shake([ProCam.SCREEN_SHAKE_CIRCULAR], 1.0, 5.0, 15.0)
```

```gdscript
func on_player_died():
    #zoom out slowly
    ProCam.zoom_smoothly = true
    ProCam.zoom_speed = 0.5
    ProCam.zoom_level = 2.0
```

```gdscript
func _ready() -> void:
    #add a never ending natural camera movement
    ProCam.start_shake([ProCam.SCREEN_SHAKE_PERLIN],INF,30,.3)
```

```gdscript
func on_player_approached_sign():
    #smoothly focus on the sign
    ProCam.drag_smoothly = true
    ProCam.target = $sign
```

```gdscript
func on_explosion():
    # Apply a random screen shake and zoom shake effect with specified parameters
    var types = [SCREEN_SHAKE_RANDOM,SCREEN_SHAKE_ZOOM]
    var duration = 0.5
    var magnitude = 4.0
    var speed = 25.0
    ProCam.start_shake(types, duration, magnitude, speed)
```

```gdscript
func on_earthquake():
    # Apply a horizontal screen shake effect with specified parameters
    var types = [SCREEN_SHAKE_HORIZONTAL]
    var duration = 1.0
    var magnitude = 2.5
    var speed = 15.0
    ProCam.start_shake(types, duration, magnitude, speed)
```

```gdscript
func on_boss_fight_start():
    # Zoom in quickly to focus on the boss and add a circular shake effect
    ProCam.zoom_smoothly = true
    ProCam.zoom_speed = 1.0
    ProCam.zoom_level = 0.75
    
    var types = [SCREEN_SHAKE_CIRCULAR]
    var duration = 1.0
    var magnitude = 3.0
    var speed = 20.0
    ProCam.start_shake(types, duration, magnitude, speed)
```

```gdscript
func on_treasure_found():
    # Smoothly focus on the treasure chest and apply a gentle horizontal shake
    ProCam.drag_smoothly = true
    ProCam.target = $treasure_chest
    ProCam.smooth_drag_time = 0.5
    
    var types = [SCREEN_SHAKE_HORIZONTAL]
    var duration = 0.4
    var magnitude = 1.2
    var speed = 10.0
    ProCam.start_shake(types, duration, magnitude, speed)
```

## Installation

1. Download or clone this repository into your Godot project.
2. Enable the plugin in Godot: Go to `Project` -> `Project Settings` -> `Plugins` and enable `ProCam2D`.

## Contributing

Contributions are welcome! For detailed instructions on how to contribute, please see our [Contributing Guide](CONTRIBUTING.md).

## Reporting Bugs or Requesting Features

To report a bug or request a feature, please use the [Issues](https://github.com/dazlike/ProCam2D/issues) section of this repository. Make sure to follow the templates provided for better clarity and organization.

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Conclusion

The `ProCam2D` plugin offers a versatile and powerful 2D camera in your Godot projects. By adjusting its properties and methods, you can achieve smooth and dynamic camera behaviors tailored to your game's needs.
