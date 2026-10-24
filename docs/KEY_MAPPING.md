# Key mapping guide for Waydroid Helper

## Overview

The key mapping feature in Waydroid Helper maps physical keyboard keys and mouse buttons to touch events in Waydroid.

## Getting started

### Opening the key mapping interface

1. Launch Waydroid Helper
2. Open the **Home** tab and click the Waydroid status row to open **Instance Details**
3. In the **Key Mapper** section, click **Open**
4. A transparent overlay window opens over your screen

### Understanding the two modes

The key mapping overlay has two modes:

- **Edit mode** (default). Place, resize, and configure control widgets.
- **Mapping mode**. Send mapped keyboard and mouse inputs to the game.

Press `F1` to switch between Edit mode and Mapping mode. In Mapping mode, press `F12` to toggle widget visibility.

## Setting up key mappings

### Adding widgets

<img src="../assets/img/KEY_MAPPING/image-20250802234629279.png" alt="image-20250802234629279" style="zoom:67%;" />

1. Enter Edit mode
2. Right-click an empty area to open the widget menu
3. Select a widget type
4. Drag the widget to the target control in the game
5. Drag the resize handles when the widget is selected to adjust its size

### Configuring key bindings

1. Double-click a widget to enter key capture mode
2. Press the key or mouse button you want to bind
3. The widget displays the assigned key combination

#### Supported key types

- **Keyboard keys.** Letters, numbers, function keys, and modifiers (Ctrl, Alt, Shift).
- **Mouse buttons.** Left, Right, and Middle.
- **Key combinations.** Multiple keys pressed together, such as Ctrl+A or Alt+Tab.

### Widget settings

1. Select a widget in Edit mode
2. Click the gear icon in the widget's bottom-right corner
3. Adjust the widget parameters and click **OK**

## Using key mappings

### Activating mappings for gameplay

1. Press `F1` to switch to Mapping mode
2. Position the game window behind the transparent overlay
3. Use your configured keys to control the game
4. Press `F1` anytime to return to Edit mode

## Available control widgets

### 1. Single click

![image-20250802223254952](../assets/img/KEY_MAPPING/image-20250802223254952.png)

Maps a key or mouse button to a single tap at a screen location. Pressing the key touches down, and releasing the key lifts the touch.

- **Use case.** Menu buttons and basic taps.
- **Configuration.** Position the widget over the target area and bind a key.

### 2. Repeated click

![image-20250802225228249](../assets/img/KEY_MAPPING/image-20250802225228249.png)

Simulates rapid taps at a fixed position.

- **Use case.** Auto-attack and rapid-fire actions.
- **Operating methods.**
  - **Long-press combo.** Taps continuously while the key is held, using **Number of clicks per second**.
  - **Click after button.** Performs a fixed **Number of clicks** after the key is pressed.

### 3. Aim

![image-20250802225148255](../assets/img/KEY_MAPPING/image-20250802225148255.png)

Locks the mouse pointer and converts mouse movement into touch dragging for camera rotation in FPS games. Resize the rectangular box to match the in-game look area.

- **Use case.** Camera rotation and aiming in FPS games.
- **Configuration.** Adjust **Sensitivity** (1 to 100).

### 4. Fire

![image-20250802224603813](../assets/img/KEY_MAPPING/image-20250802224603813.png)

Places a fire button for FPS games that activates while the Aim widget is active.

- **Use case.** Shooting in FPS games when paired with the Aim widget.
- **Configuration.**
  - **Mouse button.** Choose **Left Button** or **Right Button**.
  - **Enable drag shot.** Let Fire take over pointer lock while firing so mouse movement drags the fire touch point.
  - **Horizontal sensitivity** and **Vertical sensitivity.** Adjust drag-shot movement speed on each axis.

### 5. Directional pad

![image-20250802225040921](../assets/img/KEY_MAPPING/image-20250802225040921.png)

Maps four directional keys (default W, A, S, D) to an in-game movement joystick. Drag the dotted border so the blue circle matches the size of the in-game joystick.

- **Use case.** Character movement.
- **Default keys.** W (up), A (left), S (down), D (right).
- **Configuration.**
  - **Slide control.** Slides from the center of the pad toward the target direction.
  - **Click control.** Taps the directional point directly.

### 6. Skill casting

![image-20250802225814744](../assets/img/KEY_MAPPING/image-20250802225814744.png)

Maps a skill button and aims the skill toward the mouse cursor using perspective projection. Resize the dotted frame to match the in-game skill joystick.

- **Use case.** Directional skills in MOBA and action games.
- **Configuration.**
  - **Casting radius.** Set the ground-circle radius in world space.
  - **Camera tilt** and **Vertical FOV.** Match the game camera's tilt angle and field of view for perspective mapping.
  - **Origin X** and **Origin Y.** Set the character's ground origin position on screen (0% to 100%).
  - **Cast timing.** Choose **On Release** (cast when releasing the key), **Immediate** (cast right after moving to the target), or **Manual** (press once to aim, press again to cast).
  - **Enable cancel button.** Create a **Cancel Casting** widget. Drag it over the in-game cancel area and hold its key while aiming to cancel a skill.

### 7. Right click to walk

![image-20250802231156125](../assets/img/KEY_MAPPING/image-20250802231156125.png)

Place this widget over the game's movement wheel. Hold and drag to steer, or click to walk toward the cursor position.

- **Use case.** Movement in MOBA games.
- **Default key.** Right mouse button.

### 8. Macro

After adding a Macro widget, click the gear icon in its bottom-right corner to open the command editor.

- Supports standard editing shortcuts such as Ctrl+A, Ctrl+C, Ctrl+V, Ctrl+X, Ctrl+Z, and Ctrl+Y.
- Write all commands in lowercase.
- Clicking anywhere on the overlay while the settings panel is open inserts the clicked `x,y` coordinates into the editor.

#### Trigger timing command

`release_actions` separates press commands from release commands. Commands before `release_actions` run when the macro key is pressed, and commands after `release_actions` run when the macro key is released.

Example:

```
# Press and hold at coordinate (0,0) when macro key is pressed
# Release at coordinate (0,0) when macro key is released
press 0,0
release_actions
release 0,0
```

#### Single click command

`click x1,y1 x2,y2...` taps one or more coordinates at the same time. You can pass `mouse` to use the current cursor position.

Example:

```
# Click coordinates (0,0), (1,1), and current mouse position
# Wait 100ms, then click (2,2)
click 0,0 1,1 mouse
sleep 100
click 2,2
```

#### Hold, release, and toggle commands

- `press x1,y1 x2,y2...` holds one or more coordinates (`mouse` is supported).
- `release x1,y1 x2,y2...` releases one or more held coordinates.
- `switch x1,y1 x2,y2...` toggles between hold and release states at the given coordinates.
- `key_press key1,key2...` triggers the press action of keys bound to other widgets.
- `key_release key1,key2...` triggers the release action of keys bound to other widgets.
- `key_switch key1,key2...` toggles the pressed and released state of keys bound to other widgets.
- `toggle_group group1 | group2` alternates between two command groups on each trigger (use `;` to separate commands inside a group).
- `release_all` releases all currently pressed keys and active macro commands.

Examples:

```
# Hold (0,0) and (1,1), then release when the macro key is released
press 0,0 1,1
release_actions
release 0,0 1,1

# Toggle touch state at (0,0) on each press
switch 0,0
```

```
# Trigger widget bound to [A] while held, release when macro key is released
key_press a
release_actions
key_release a

# Toggle [A] key state on each press
key_switch a
```

#### Wait command

`sleep duration` pauses macro execution for `duration` milliseconds.

Example:

```
# Click (0,0), wait 1 second, then click (1,1)
click 0,0
sleep 1000
click 1,1
```

#### Aim mode commands

`enter_staring` and `exit_staring` enter or exit Aim pointer-lock mode. For example, holding a key can unlock the cursor and releasing it can re-lock the cursor:

```
exit_staring
release_actions
sleep 50
enter_staring
```

#### Directional pad radius commands

- `swipehold_radius x` scales the directional pad slide radius to `x` times its size, which can switch between walking and running speeds.
- `swipehold_radius_switch x` toggles the directional pad radius between `x` and `1`.

Examples:

```
# Walk when pressed, run when released
swipehold_radius 0.2
release_actions
swipehold_radius 1
```

```
# Toggle between walking and running on each press
swipehold_radius_switch 0.5
```
