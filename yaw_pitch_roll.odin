package main

import "core:math"
import rl "vendor:raylib"

SCREEN_WIDTH :: 1600
SCREEN_HEIGHT :: 900
WINDOW_TITLE :: "yaw, pitch, roll"

// Rates are degrees per second (tuned to match the old per-frame feel at ~60 FPS).
PITCH_STICK_DEG_PER_SEC :: 36.0
PITCH_RETURN_DEG_PER_SEC :: 18.0
PITCH_DEADBAND_DEG :: 0.3
YAW_ROLL_STICK_DEG_PER_SEC :: 60.0
YAW_ROLL_RETURN_DEG_PER_SEC :: 30.0
// Cap a single frame’s delta so a long hitch does not apply huge angle steps.
MAX_FRAME_TIME :: 0.1

// Virtual stick HUD: lower right. Zone diameter = window height / 3; black knob stays inside.
STICK_CORNER_MARGIN :: f32(36.0)
STICK_KNOB_RADIUS :: f32(8.0)
// Exponential recenter of the knob when the mouse is released (per second).
STICK_RECENTER_PER_SEC :: f32(14.0)

main :: proc() {
    rl.InitWindow(SCREEN_WIDTH, SCREEN_HEIGHT, WINDOW_TITLE)
    defer rl.CloseWindow()

    camera := rl.Camera3D{
        position = {0.0, 50.0, -120.0},
        target = {0.0, 0.0, 0.0},
        up = {0.0, 1.0, 0.0},
        fovy = 30.0, 
        projection = .PERSPECTIVE,
    }

    model := rl.LoadModel("resources/plane.obj")
    defer rl.UnloadModel(model)
    
    texture := rl.LoadTexture("resources/plane_diffuse.png")
    defer rl.UnloadTexture(texture)

    rl.SetTextureWrap(texture,  rl.TextureWrap.REPEAT)

    model.materials[0].maps[rl.MaterialMapIndex.ALBEDO].texture = texture

    pitch: f32 = 0.0
    roll: f32 = 0.0
    yaw: f32 = 0.0
    stick_grabbing: bool = false
    stick_ox: f32 = 0.0
    stick_oy: f32 = 0.0

    zone_diameter := f32(SCREEN_HEIGHT) / 3.0
    zone_radius := zone_diameter * 0.5
    max_offset := zone_radius - STICK_KNOB_RADIUS
    stick_center := rl.Vector2{
        f32(SCREEN_WIDTH) - STICK_CORNER_MARGIN - zone_radius,
        f32(SCREEN_HEIGHT) - STICK_CORNER_MARGIN - zone_radius,
    }

    rl.SetTargetFPS(60)

    for !rl.WindowShouldClose() {
        dt := rl.GetFrameTime()
        if dt > MAX_FRAME_TIME {
            dt = MAX_FRAME_TIME
        }

        if rl.IsMouseButtonPressed(.LEFT) {
            mp := rl.GetMousePosition()
            if rl.CheckCollisionPointCircle(mp, stick_center, zone_radius) {
                stick_grabbing = true
            }
        }
        if rl.IsMouseButtonReleased(.LEFT) {
            stick_grabbing = false
        }

        if stick_grabbing {
            mp := rl.GetMousePosition()
            ox := mp.x - stick_center.x
            oy := mp.y - stick_center.y
            d: f32 = f32(math.sqrt(f64(ox * ox + oy * oy)))
            if d > max_offset && d > 0.0 {
                s := max_offset / d
                ox *= s
                oy *= s
            }
            stick_ox = ox
            stick_oy = oy
            nx := stick_ox / max_offset
            ny := stick_oy / max_offset
            // Screen Y grows downward: drag up (negative oy) = push forward = nose down; drag down = pull back = nose up.
            pitch += (-ny) * PITCH_STICK_DEG_PER_SEC * dt
            roll += nx * YAW_ROLL_STICK_DEG_PER_SEC * dt
        } else {
            decay := f32(math.exp(-f64(STICK_RECENTER_PER_SEC * dt)))
            stick_ox *= decay
            stick_oy *= decay
            if stick_ox * stick_ox + stick_oy * stick_oy < 0.25 {
                stick_ox = 0.0
                stick_oy = 0.0
            }
            step_pitch := PITCH_RETURN_DEG_PER_SEC * dt
            if pitch > PITCH_DEADBAND_DEG {
                pitch = math.max(PITCH_DEADBAND_DEG, pitch - step_pitch)
            } else if pitch < -PITCH_DEADBAND_DEG {
                pitch = math.min(-PITCH_DEADBAND_DEG, pitch + step_pitch)
            }
            step_roll := YAW_ROLL_RETURN_DEG_PER_SEC * dt
            if roll > 0.0 {
                roll = math.max(0.0, roll - step_roll)
            } else if roll < 0.0 {
                roll = math.min(0.0, roll + step_roll)
            }
        }

        if rl.IsKeyDown(.S) {
            yaw -= YAW_ROLL_STICK_DEG_PER_SEC * dt
        } else if rl.IsKeyDown(.A) {
            yaw += YAW_ROLL_STICK_DEG_PER_SEC * dt
        } else {
            step := YAW_ROLL_RETURN_DEG_PER_SEC * dt
            if yaw > 0.0 {
                yaw = math.max(0.0, yaw - step)
            } else if yaw < 0.0 {
                yaw = math.min(0.0, yaw + step)
            }
        }

        model.transform = rl.MatrixRotateXYZ({
            rl.DEG2RAD * pitch,
            rl.DEG2RAD * yaw,
            rl.DEG2RAD * roll,
        })

        // Start Drawing
        rl.BeginDrawing() 

            rl.ClearBackground(rl.RAYWHITE)
        
            rl.BeginMode3D(camera)
                rl.DrawModel(model, {0.0, -8.0, 0.0}, 1.0, rl.LIGHTGRAY)
            rl.EndMode3D()

            // Virtual stick HUD (lower right; knob stays inside gray zone).
            rl.DrawCircleV(stick_center, zone_radius, rl.GRAY)
            // Small center cross: total span = 1/10 of circle diameter.
            cross_half := zone_radius * 0.1
            rl.DrawLineEx(
                {stick_center.x - cross_half, stick_center.y},
                {stick_center.x + cross_half, stick_center.y},
                1.5,
                rl.BLACK,
            )
            rl.DrawLineEx(
                {stick_center.x, stick_center.y - cross_half},
                {stick_center.x, stick_center.y + cross_half},
                1.5,
                rl.BLACK,
            )
            rl.DrawCircleLinesV(stick_center, zone_radius, rl.DARKGRAY)
            knob := rl.Vector2{stick_center.x + stick_ox, stick_center.y + stick_oy}
            rl.DrawCircleV(knob, STICK_KNOB_RADIUS, rl.BLACK)
            rl.DrawCircleLinesV(knob, STICK_KNOB_RADIUS, rl.DARKGRAY)

            pitchText :: "Pitch & roll: lower-right stick (forward/up = nose down, back/down = nose up, sides = roll)"
            yawText :: "Yaw: A and S keys"

            FONT_SIZE :: 20
            TXT_BOX_TOP :: SCREEN_HEIGHT - FONT_SIZE * 5
            rl.DrawRectangle(30, TXT_BOX_TOP, FONT_SIZE * 34, FONT_SIZE * 4, rl.Fade(rl.GREEN, 0.5))
            rl.DrawRectangleLines(30, TXT_BOX_TOP, FONT_SIZE * 34, FONT_SIZE * 4, rl.Fade(rl.DARKGREEN, 0.5))
            rl.DrawText(pitchText, 40, TXT_BOX_TOP + FONT_SIZE, FONT_SIZE, rl.DARKGRAY)
            rl.DrawText(yawText, 40, TXT_BOX_TOP + FONT_SIZE * 2, FONT_SIZE, rl.DARKGRAY)

            rl.DrawText("(c) WWI Plane Model created by GiaHanLam", 
                SCREEN_WIDTH - FONT_SIZE * 24, SCREEN_HEIGHT - FONT_SIZE * 2, FONT_SIZE, rl.DARKGRAY);

        rl.EndDrawing()

        
    }

}