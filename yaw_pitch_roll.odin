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

    rl.SetTargetFPS(60)

    for !rl.WindowShouldClose() {
        dt := rl.GetFrameTime()
        if dt > MAX_FRAME_TIME {
            dt = MAX_FRAME_TIME
        }

        if rl.IsKeyDown(.DOWN) {
            pitch += PITCH_STICK_DEG_PER_SEC * dt
        } else if rl.IsKeyDown(.UP) {
            pitch -= PITCH_STICK_DEG_PER_SEC * dt
        } else {
            step := PITCH_RETURN_DEG_PER_SEC * dt
            if pitch > PITCH_DEADBAND_DEG {
                pitch = math.max(PITCH_DEADBAND_DEG, pitch - step)
            } else if pitch < -PITCH_DEADBAND_DEG {
                pitch = math.min(-PITCH_DEADBAND_DEG, pitch + step)
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

        if rl.IsKeyDown(.LEFT) {
            roll -= YAW_ROLL_STICK_DEG_PER_SEC * dt
        } else if rl.IsKeyDown(.RIGHT) {
            roll += YAW_ROLL_STICK_DEG_PER_SEC * dt
        } else {
            step := YAW_ROLL_RETURN_DEG_PER_SEC * dt
            if roll > 0.0 {
                roll = math.max(0.0, roll - step)
            } else if roll < 0.0 {
                roll = math.min(0.0, roll + step)
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

            endText :: "Press [Esc] to End."
            pitchText :: "Pitch controlled with UP and DOWN arrows"
            rollText :: "Roll controlled with LEFT and RIGHT arrows"
            yawText :: "Yaw controlled with A and S keys"

            FONT_SIZE :: 20
            TXT_BOX_TOP :: SCREEN_HEIGHT - FONT_SIZE * 6
            rl.DrawRectangle(30, TXT_BOX_TOP, FONT_SIZE * 26, FONT_SIZE * 5, rl.Fade(rl.GREEN, 0.5))
            rl.DrawRectangleLines(30, TXT_BOX_TOP, FONT_SIZE * 26, FONT_SIZE * 5, rl.Fade(rl.DARKGREEN, 0.5))
            rl.DrawText(pitchText, 40, TXT_BOX_TOP + FONT_SIZE, FONT_SIZE, rl.DARKGRAY)
            rl.DrawText(rollText, 40, TXT_BOX_TOP + FONT_SIZE * 2, FONT_SIZE, rl.DARKGRAY)
            rl.DrawText(yawText, 40, TXT_BOX_TOP + FONT_SIZE * 3, FONT_SIZE, rl.DARKGRAY)

            rl.DrawText("(c) WWI Plane Model created by GiaHanLam", 
                SCREEN_WIDTH - FONT_SIZE * 24, SCREEN_HEIGHT - FONT_SIZE * 2, FONT_SIZE, rl.DARKGRAY);

        rl.EndDrawing()

        
    }

}