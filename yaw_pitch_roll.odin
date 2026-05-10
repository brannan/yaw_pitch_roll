package main

import rl "vendor:raylib"

SCREEN_WIDTH :: 1600
SCREEN_HEIGHT :: 900
WINDOW_TITLE :: "yaw, pitch, roll"

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

        if rl.IsKeyDown(.DOWN) {
            pitch += 0.6
        } else if rl.IsKeyDown(.UP) {
            pitch -= 0.6
        } else {
            if (pitch > 0.3) { pitch -= 0.3 }
            else if (pitch < -0.3) { pitch += 0.3 }
        }

        if rl.IsKeyDown(.S) {
            yaw -= 1.0
        } else if rl.IsKeyDown(.A) {
            yaw += 1.0
        } else {
            if (yaw > 0.0) { yaw -= 0.5 }
            else if (yaw < 0.0) { yaw += 0.5 }
        }

        if rl.IsKeyDown(.LEFT) {
            roll -= 1.0
        } else if rl.IsKeyDown(.RIGHT) {
            roll += 1.0
        } else {
            if (roll > 0.0) { roll -= 0.5 }
            else if (roll < 0.0) { roll += 0.5 }
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