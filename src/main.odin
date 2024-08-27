package main

import "core:fmt"
import "core:math/rand"
import "core:mem"
import "core:path/filepath"
import "core:time"

import rl "vendor:raylib"

Scene :: enum {
	Title,
	Game,
	Game_Over,
}

Gopher :: struct {
	x, y:          f32,
	width, height: i32,
}

Wall :: struct {
	wall_x: i32,
	hole_y: i32,
}

Game :: struct {
	gopher:       Gopher,
	velocity:     f32,
	gravity:      f32,
	frames:       i32,
	old_score:    i32,
	new_score:    i32,
	score_string: cstring,
	walls:        [dynamic]Wall,
	scene:        Scene,
	retry:        bool,
}


SCREEN_WIDTH :: 640
SCREEN_HEIGHT :: 360

textures: map[string]rl.Texture2D


draw_title :: proc(game: ^Game) {
	rl.DrawTexture(textures["sky"], 0, 0, rl.WHITE)
	rl.DrawText("Click!", (SCREEN_WIDTH / 2) - 40, SCREEN_HEIGHT / 2, 20, rl.WHITE)
	rl.DrawTexture(textures["gopher"], i32(game.gopher.x), i32(game.gopher.y), rl.WHITE)
	if rl.IsMouseButtonPressed(rl.MouseButton.LEFT) {
		game.scene = .Game
	}
}


JUMP :: -4.0
INTERVAL :: 120 // 壁の追加間隔
WALL_START_X :: 640 // 壁の初期x座標
HOLE_Y_MAX :: 150 // 穴のy座標の最大値
GOPHER_WIDTH :: 60 // GOPHERの幅
GOPHER_HEIGHT :: 75 // GOPHERの高さ
HOLE_HEIGHT :: 170 // 穴のサイズ（高さ）
WALL_HEIGHT :: 360 // 壁の高さ
WALL_WIDTH :: 20 // 壁の幅


draw_game :: proc(game: ^Game) {
	if rl.IsMouseButtonPressed(rl.MouseButton.LEFT) {
		game.velocity = JUMP
	}
	game.velocity += game.gravity
	game.gopher.y += game.velocity

	game.frames += 1
	if game.frames % INTERVAL == 0 {
		append(
			&game.walls,
			Wall{wall_x = WALL_START_X, hole_y = i32(rand.float32_range(0, HOLE_Y_MAX))},
		)
	}

	// wallを左へ移動
	for &v in game.walls {
		v.wall_x -= 2
	}

	// スコアを計算
	for v, i in game.walls {
		if v.wall_x < i32(game.gopher.x) {
			game.new_score = i32(i + 1)
		}
	}
	// スコアの文字列を生成
	if game.new_score != game.old_score {
		game.score_string = rl.TextFormat("Score: %d", game.new_score)
		game.old_score = game.new_score
	}

	rl.DrawTexture(textures["sky"], 0, 0, rl.WHITE)
	rl.DrawTexture(textures["gopher"], i32(game.gopher.x), i32(game.gopher.y), rl.WHITE)

	for v in game.walls {
		wall_x := v.wall_x
		hole_y := v.hole_y
		x := game.gopher.x
		y := game.gopher.y

		// 上の壁の描画
		rl.DrawTexture(textures["wall"], wall_x, hole_y - WALL_HEIGHT, rl.WHITE)
		// 下の壁の描画
		rl.DrawTexture(textures["wall"], wall_x, hole_y + HOLE_HEIGHT, rl.WHITE)

		// gopherを表す四角形を作る
		g_left := i32(x)
		g_top := i32(y)
		g_right := i32(x) + GOPHER_WIDTH
		g_bottom := i32(y) + GOPHER_HEIGHT

		// 上の壁を表す四角形を作る
		w_left := wall_x
		w_top := hole_y - WALL_HEIGHT
		w_right := wall_x + WALL_WIDTH
		w_bottom := hole_y

		// 上の壁との当たり判定
		if g_left < w_right && w_left < g_right && g_top < w_bottom && w_top < g_bottom {
			// rl.DrawText("Hit! [Wall's Top]", 10, 30, 20, rl.BLACK)
			game.scene = .Game_Over
		}

		// 下の壁を表す四角形を作る
		w_left = wall_x
		w_top = hole_y + HOLE_HEIGHT
		w_right = wall_x + WALL_WIDTH
		w_bottom = hole_y + HOLE_HEIGHT + WALL_HEIGHT

		// 下の壁との当たり判定
		if g_left < w_right && w_left < g_right && g_top < w_bottom && w_top < g_bottom {
			game.scene = .Game_Over
		}
	}

	// スコアを描画
	rl.DrawText(game.score_string, 10, 10, 20, rl.RED)

	// 上の壁との当たり判定
	if game.gopher.y < 0 {
		game.scene = .Game_Over
	}
	// 地面との当たり判定
	if 360 - GOPHER_HEIGHT < game.gopher.y {
		game.scene = .Game_Over
	}
}


draw_game_over :: proc(game: ^Game) {
	rl.DrawTexture(textures["sky"], 0, 0, rl.WHITE)
	rl.DrawTexture(textures["gopher"], i32(game.gopher.x), i32(game.gopher.y), rl.WHITE)

	for v in game.walls {
		wall_x := v.wall_x
		hole_y := v.hole_y
		rl.DrawTexture(textures["wall"], wall_x, hole_y - WALL_HEIGHT, rl.WHITE)
		rl.DrawTexture(textures["wall"], wall_x, hole_y + HOLE_HEIGHT, rl.WHITE)
	}
	rl.DrawText("Game Over", (SCREEN_WIDTH / 2) - 60, (SCREEN_HEIGHT / 2) - 60, 20, rl.WHITE)

	game.score_string = rl.TextFormat("Score: %d", game.new_score)
	rl.DrawText(game.score_string, (SCREEN_WIDTH / 2) - 60, (SCREEN_HEIGHT / 2) - 40, 20, rl.WHITE)

	if rl.IsMouseButtonPressed(rl.MouseButton.LEFT) {
		game.scene = .Title
		delete(game.walls)
		init_game(game)
	}
}


init_game :: proc(game: ^Game) {
	game.gopher = Gopher {
		x      = 200.0,
		y      = 150.0,
		width  = 60,
		height = 75,
	}
	game.velocity = 0.0
	game.gravity = 0.1
	game.frames = 0
	game.old_score = 0
	game.new_score = 0
	game.score_string = "Score: 0"
	game.scene = .Title
	game.walls = make([dynamic]Wall)

}


_main :: proc() {
	rl.InitWindow(SCREEN_WIDTH, SCREEN_HEIGHT, "flappy")
	defer rl.CloseWindow()

	rl.SetTargetFPS(60)

	textures_data := #load_directory("../assets/")
	for td in textures_data {
		name, data := td.name, td.data
		path := filepath.stem(name)
		image := rl.LoadImageFromMemory(".png", raw_data(data), i32(len(data)))
		textures[path] = rl.LoadTextureFromImage(image)
		rl.UnloadImage(image)
	}
	defer delete(textures)

	game: Game
	init_game(&game)

	seed := u64(time.time_to_unix(time.now()))
	r := rand.create(seed)
	context.random_generator = rand.default_random_generator(&r)

	render_texture := rl.LoadRenderTexture(SCREEN_WIDTH, SCREEN_HEIGHT)
	defer rl.UnloadRenderTexture(render_texture)

	for !rl.WindowShouldClose() {

		rl.BeginTextureMode(render_texture)
		{
			switch game.scene {
			case .Title:
				draw_title(&game)
			case .Game:
				draw_game(&game)
			case .Game_Over:
				draw_game_over(&game)
			}
		}
		rl.EndTextureMode()

		rl.BeginDrawing()
		{
			w := f32(render_texture.texture.width)
			h := f32(render_texture.texture.height)
			source := rl.Rectangle{0, 0, w, h}
			dest := source
			source.height = -source.height
			rl.DrawTexturePro(
				texture = render_texture.texture,
				source = source,
				dest = dest,
				origin = {0, 0},
				rotation = 0,
				tint = rl.WHITE,
			)
		}
		rl.EndDrawing()

	}
	delete(game.walls)
}


main :: proc() {

	when ODIN_DEBUG {
		track: mem.Tracking_Allocator
		mem.tracking_allocator_init(&track, context.allocator)
		context.allocator = mem.tracking_allocator(&track)

		defer {
			if len(track.allocation_map) > 0 {
				fmt.eprintf("=== %v allocations not freed: ===\n", len(track.allocation_map))
				for _, entry in track.allocation_map {
					fmt.eprintf("- %v bytes @ %v\n", entry.size, entry.location)
				}
			}
			if len(track.bad_free_array) > 0 {
				fmt.eprintf("=== %v incorrect frees: ===\n", len(track.bad_free_array))
				for entry in track.bad_free_array {
					fmt.eprintf("- %p @ %v\n", entry.memory, entry.location)
				}
			}
			mem.tracking_allocator_destroy(&track)
		}
	}
	_main()
}
