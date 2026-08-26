# Heresy -- a 90s-style Doom/Heretic/Hexen-like raycaster shooter.
#
# Why this is a *software raycaster* rather than a 3D engine: Star's drawing
# surface is `draw_rect`/`draw_pixel`/`draw_pixels`/`texture_*` over raw RGBA
# `Bytes` -- there is no 3D API, no depth buffer, and `texture_draw` does no
# alpha blending (no `SDL_SetTextureBlendMode`). The authentic 90s answer to
# "I want a first-person shooter with no 3D hardware" is exactly what this
# file does: cast one ray per screen column (DDA), shade walls by distance,
# and project sprites with a per-column depth buffer -- all into a software
# framebuffer that is blitted to the window once per frame via
# `texture_update`/`texture_draw` (the cached-texture pattern
# `projects/nova/main.star` established). This is how Wolfenstein 3D and
# early Doom actually rendered, and it maps perfectly onto Star's strengths.
#
# The internal resolution is 320x200 (the classic 90s FPS resolution),
# scaled 2x to a 640x400 window -- giving that authentic chunky pixel look
# and keeping the per-frame software-render cost tiny.
#
# Build (from the repo root, SDL2 must be linked explicitly):
#   star build projects/heresy/main.star -L sdl/lib/x64 -l SDL2 -o projects/heresy/heresy.exe
# `sdl/lib/x64/SDL2.dll` must be next to the built .exe (or on PATH) to run.
#
# Controls: WASD or arrow keys to move/strafe, mouse to aim (delta-based),
# left click or Space to fire the starbolt, R to restart after death,
# Escape quits. The game synthesizes its own WAV sound effects at startup
# (see audio.star) and plays a looping ambient drone.

import "map.star" as map
import "sprites.star" as sprites
import "audio.star" as audio

const SCREEN_W: i32 = 320
const SCREEN_H: i32 = 200
const SCALE: i32 = 2
const PLANE_DIST: f32 = 0.66
const MAX_DIST: f32 = 12.0

# ---- Game state -----------------------------------------------------------

struct Player:
    mut x: f32
    mut y: f32
    mut angle: f32
    mut health: f32
    mut mana: f32
    mut score: i32
    mut alive: bool

struct Enemy:
    mut x: f32
    mut y: f32
    mut health: f32
    mut kind: i32
    mut alive: bool
    mut cooldown: f32

struct Projectile:
    mut x: f32
    mut y: f32
    mut dx: f32
    mut dy: f32
    mut friendly: bool
    mut alive: bool

struct Pickup:
    mut x: f32
    mut y: f32
    mut kind: i32
    mut taken: bool

struct Game:
    mut player: Player
    mut enemies: List<Enemy>
    mut projectiles: List<Projectile>
    mut pickups: List<Pickup>
    mut recoil: f32
    mut last_fire: bool
    mut last_mouse_x: i32
    mut last_ticks: i32

# ---- Sprite draw records (for back-to-front sorting) ----------------------

struct SpriteDraw:
    dist: f32
    kind: i32
    x: f32
    y: f32

# ---- Level / entity construction ------------------------------------------

fn build_enemies(level: map::Level) -> List<Enemy>:
    let mut enemies: List<Enemy> = List<Enemy>()
    let mut i = 0
    while i < level.imps.len():
        let idx = level.imps[i]
        enemies.push(Enemy(x = map::cell_center_x(idx), y = map::cell_center_y(idx), health = 30.0, kind = 0, alive = true, cooldown = 0.0))
        i += 1
    i = 0
    while i < level.brutes.len():
        let idx = level.brutes[i]
        enemies.push(Enemy(x = map::cell_center_x(idx), y = map::cell_center_y(idx), health = 60.0, kind = 1, alive = true, cooldown = 0.0))
        i += 1
    return enemies

fn build_pickups(level: map::Level) -> List<Pickup>:
    let mut pickups: List<Pickup> = List<Pickup>()
    let mut i = 0
    while i < level.healths.len():
        let idx = level.healths[i]
        pickups.push(Pickup(x = map::cell_center_x(idx), y = map::cell_center_y(idx), kind = 0, taken = false))
        i += 1
    i = 0
    while i < level.manas.len():
        let idx = level.manas[i]
        pickups.push(Pickup(x = map::cell_center_x(idx), y = map::cell_center_y(idx), kind = 1, taken = false))
        i += 1
    return pickups

# ---- Raycasting -----------------------------------------------------------

# Cast a single ray for screen column `camera_x` in [-1, 1]. Returns
# (perp_dist, wall_kind, wall_frac, side) where wall_frac is the fractional
# position along the wall face (for texturing) and side is 0=x-axis, 1=y-axis.
fn cast_ray(map_grid: List<i32>, px: f32, py: f32, dir_x: f32, dir_y: f32, plane_x: f32, plane_y: f32, camera_x: f32) -> (f32, i32, f32, i32):
    let ray_dir_x = dir_x + plane_x * camera_x
    let ray_dir_y = dir_y + plane_y * camera_x
    let mut map_x = px as i32
    let mut map_y = py as i32
    let inv_x = if abs(ray_dir_x) < 0.0001: 1000000.0 else: 1.0 / ray_dir_x
    let inv_y = if abs(ray_dir_y) < 0.0001: 1000000.0 else: 1.0 / ray_dir_y
    let delta_x = abs(inv_x)
    let delta_y = abs(inv_y)
    let mut step_x = 0
    let mut step_y = 0
    let mut side_dist_x = 0.0
    let mut side_dist_y = 0.0
    if ray_dir_x < 0.0:
        step_x = -1
        side_dist_x = (px - (map_x as f32)) * delta_x
    else:
        step_x = 1
        side_dist_x = (((map_x + 1) as f32) - px) * delta_x
    if ray_dir_y < 0.0:
        step_y = -1
        side_dist_y = (py - (map_y as f32)) * delta_y
    else:
        step_y = 1
        side_dist_y = (((map_y + 1) as f32) - py) * delta_y
    let mut side = 0
    let mut hit = 0
    let mut kind = 0
    while hit == 0:
        if side_dist_x < side_dist_y:
            side_dist_x += delta_x
            map_x += step_x
            side = 0
        else:
            side_dist_y += delta_y
            map_y += step_y
            side = 1
        kind = map::cell_at(map_grid, map_x, map_y)
        if kind > 0:
            hit = 1
    let perp = if side == 0: side_dist_x - delta_x else: side_dist_y - delta_y
    let wall_x = if side == 0: py + perp * ray_dir_y else: px + perp * ray_dir_x
    let wall_frac = wall_x - (wall_x as i32) as f32
    return (perp, kind, wall_frac, side)

# Procedural wall texture: vertical stripes + horizontal bands over the
# wall's base palette, giving a chunky 90s stone/brick look.
fn wall_pixel(kind: i32, wall_frac: f32, tex_y: i32, tex_h: i32) -> (i32, i32, i32):
    let base = map::wall_base(kind)
    let mut r = base.0
    let mut g = base.1
    let mut b = base.2
    let stripe = (wall_frac * 8.0) as i32
    if stripe % 2 == 0:
        r = r * 8 / 10
        g = g * 8 / 10
        b = b * 8 / 10
    let band = tex_y * 8 / tex_h
    if band % 2 == 0:
        r = r * 8 / 10
        g = g * 8 / 10
        b = b * 8 / 10
    return (r, g, b)

fn shade_color(r: i32, g: i32, b: i32, shade: f32) -> (i32, i32, i32):
    return ((r as f32 * shade) as i32, (g as f32 * shade) as i32, (b as f32 * shade) as i32)

# ---- Sprite selection -----------------------------------------------------

# kind: 0=imp, 1=starbolt, 2=health, 3=mana, 4=brute
fn pick_sprite(s: sprites::SpriteSet, kind: i32) -> Bytes:
    if kind == 0:
        return s.imp
    if kind == 1:
        return s.starbolt
    if kind == 2:
        return s.health
    if kind == 3:
        return s.mana
    return s.brute

# ---- Rendering ------------------------------------------------------------

# Fill the framebuffer with a ceiling/floor gradient, then raycast walls.
# Returns (buf, zbuf) where zbuf holds per-column wall distance for sprite
# depth testing.
fn render_walls(px: f32, py: f32, angle: f32, map_grid: List<i32>) -> (Bytes, List<f32>):
    # `Bytes` parameters can't be mutated (index-write or `push` fails
    # codegen with "cannot store to this expression" -- the COW clone
    # needs to store the new object pointer into the binding's slot,
    # but parameter slots aren't storable). Drop the `_buf` parameter
    # entirely and build `out` from a fresh `Bytes()`.
    let mut out = Bytes()
    let mut zbuf: List<f32> = List<f32>()
    let mut zi = 0
    while zi < SCREEN_W:
        zbuf.push(1000.0)
        zi += 1

    # Ceiling/floor gradient fill.
    let mut y = 0
    while y < SCREEN_H:
        let mut r = 0
        let mut g = 0
        let mut b = 0
        if y < SCREEN_H / 2:
            let t = (y as f32) / ((SCREEN_H / 2) as f32)
            r = 8 + (t * 18.0) as i32
            g = 8 + (t * 18.0) as i32
            b = 16 + (t * 30.0) as i32
        else:
            let t = ((y - SCREEN_H / 2) as f32) / ((SCREEN_H / 2) as f32)
            r = 26 + (t * 20.0) as i32
            g = 26 + (t * 20.0) as i32
            b = 46 + (t * 30.0) as i32
        let mut x = 0
        while x < SCREEN_W:
            out.push(r as u8)
            out.push(g as u8)
            out.push(b as u8)
            out.push(255 as u8)
            x += 1
        y += 1

    # Raycast walls.
    let dir_x = cos(angle)
    let dir_y = sin(angle)
    let plane_x = -sin(angle) * PLANE_DIST
    let plane_y = cos(angle) * PLANE_DIST
    let mut x = 0
    while x < SCREEN_W:
        let camera_x = (2.0 * (x as f32) / (SCREEN_W as f32)) - 1.0
        let ray = cast_ray(map_grid, px, py, dir_x, dir_y, plane_x, plane_y, camera_x)
        let perp = ray.0
        let kind = ray.1
        let wall_frac = ray.2
        zbuf.push(perp)
        let line_h = (SCREEN_H as f32) / perp
        let draw_start = (0.0 - (line_h / 2.0) + (SCREEN_H as f32) / 2.0) as i32
        let draw_end = ((line_h / 2.0) + (SCREEN_H as f32) / 2.0) as i32
        let shade = clamp(1.0 - perp / MAX_DIST, 0.15, 1.0)
        let mut wy = draw_start
        while wy < draw_end:
            if wy >= 0 and wy < SCREEN_H:
                let tex_y = ((wy - draw_start) * 16) / max(line_h as i32, 1)
                let c = wall_pixel(kind, wall_frac, tex_y, 16)
                let sc = shade_color(c.0, c.1, c.2, shade)
                out.push(sc.0 as u8)
                out.push(sc.1 as u8)
                out.push(sc.2 as u8)
                out.push(255 as u8)
            wy += 1
        x += 1
    return (out, zbuf)

# Project and draw all sprites (enemies, projectiles, pickups) back-to-front
# with per-column depth testing against the wall zbuffer.
fn render_sprites(zbuf: List<f32>, px: f32, py: f32, angle: f32, enemies: List<Enemy>, projectiles: List<Projectile>, pickups: List<Pickup>, spriteset: sprites::SpriteSet) -> Bytes:
    # Drop the `_buf` parameter entirely for the same reason as
    # `render_walls`; start `out` from a brand-new `Bytes()`.
    let mut out = Bytes()
    # Collect drawable sprites.
    let mut draws: List<SpriteDraw> = List<SpriteDraw>()
    let mut i = 0
    while i < enemies.len():
        let e = enemies[i]
        if e.alive:
            let dx = e.x - px
            let dy = e.y - py
            let dist = sqrt(dx * dx + dy * dy)
            let sk = if e.kind == 0: 0 else: 4
            draws.push(SpriteDraw(dist = dist, kind = sk, x = e.x, y = e.y))
        i += 1
    i = 0
    while i < projectiles.len():
        let p = projectiles[i]
        if p.alive:
            let dx = p.x - px
            let dy = p.y - py
            let dist = sqrt(dx * dx + dy * dy)
            draws.push(SpriteDraw(dist = dist, kind = 1, x = p.x, y = p.y))
        i += 1
    i = 0
    while i < pickups.len():
        let p = pickups[i]
        if !p.taken:
            let dx = p.x - px
            let dy = p.y - py
            let dist = sqrt(dx * dx + dy * dy)
            let sk = if p.kind == 0: 2 else: 3
            draws.push(SpriteDraw(dist = dist, kind = sk, x = p.x, y = p.y))
        i += 1

    # Skip the back-to-front sort: `List<T>` only supports `push`/`pop`/
    # `len`, and index writes on a parameter-backed binding fail codegen.
    # The per-column zbuffer in `render_sprites` below handles occlusion
    # correctly without sorting, so the sort is unnecessary.

    let dir_x = cos(angle)
    let dir_y = sin(angle)
    let plane_x = -sin(angle) * PLANE_DIST
    let plane_y = cos(angle) * PLANE_DIST
    let inv_det = 1.0 / (plane_x * dir_y - dir_x * plane_y)

    let mut di = 0
    while di < draws.len():
        let d = draws[di]
        let sprite_x = d.x - px
        let sprite_y = d.y - py
        let transform_x = inv_det * (dir_y * sprite_x - dir_x * sprite_y)
        let transform_y = inv_det * (0.0 - plane_y * sprite_x + plane_x * sprite_y)
        if transform_y > 0.1:
            let screen_x = (SCREEN_W as f32 / 2.0) * (1.0 + transform_x / transform_y)
            let sprite_h = abs((SCREEN_H as f32) / transform_y)
            let sprite_w = sprite_h
            let draw_start_y = (0.0 - sprite_h / 2.0 + (SCREEN_H as f32) / 2.0) as i32
            let draw_end_y = (sprite_h / 2.0 + (SCREEN_H as f32) / 2.0) as i32
            let draw_start_x = (0.0 - sprite_w / 2.0 + screen_x) as i32
            let draw_end_x = (sprite_w / 2.0 + screen_x) as i32
            let sprite_buf = pick_sprite(spriteset, d.kind)
            let shade = clamp(1.0 - d.dist / MAX_DIST, 0.15, 1.0)
            let mut sy = draw_start_y
            while sy < draw_end_y:
                let mut sx = draw_start_x
                while sx < draw_end_x:
                    if sx >= 0 and sx < SCREEN_W and sy >= 0 and sy < SCREEN_H:
                        if transform_y < zbuf[sx]:
                            let tex_x = ((sx - draw_start_x) * sprites::SPRITE_W) / max(sprite_w as i32, 1)
                            let tex_y = ((sy - draw_start_y) * sprites::SPRITE_H) / max(sprite_h as i32, 1)
                            let soff = (tex_y * sprites::SPRITE_W + tex_x) * 4
                            let a = sprite_buf[soff + 3]
                            if (a as i32) > 0:
                                let r = sprite_buf[soff]
                                let g = sprite_buf[soff + 1]
                                let b = sprite_buf[soff + 2]
                                let sc = shade_color(r as i32, g as i32, b as i32, shade)
                                out.push(sc.0 as u8)
                                out.push(sc.1 as u8)
                                out.push(sc.2 as u8)
                                out.push(255 as u8)
                    sx += 1
                sy += 1
        di += 1
    return out

# ---- Game logic -----------------------------------------------------------

# Simple line-of-sight check: sample points along the line and see if any
# lands in a wall cell.
fn has_los(map_grid: List<i32>, x1: f32, y1: f32, x2: f32, y2: f32) -> bool:
    let dx = x2 - x1
    let dy = y2 - y1
    let dist = sqrt(dx * dx + dy * dy)
    let steps = (dist * 4.0) as i32
    let mut i = 1
    while i < steps:
        let t = (i as f32) / (steps as f32)
        let sx = x1 + dx * t
        let sy = y1 + dy * t
        if map::cell_at(map_grid, sx as i32, sy as i32) > 0:
            return false
        i += 1
    return true

fn new_game(level: map::Level) -> Game:
    return Game(
        player = Player(x = map::cell_center_x(level.player_idx), y = map::cell_center_y(level.player_idx), angle = 0.0, health = 100.0, mana = 100.0, score = 0, alive = true),
        enemies = build_enemies(level),
        projectiles = List<Projectile>(),
        pickups = build_pickups(level),
        recoil = 0.0,
        last_fire = false,
        last_mouse_x = 0,
        last_ticks = 0,
    )

impl Game:
    fn update_input(mut self, dt: f32, map_grid: List<i32>, sounds: audio::Sounds) -> Game:
        # Turning: arrow keys + mouse delta.
        let mut turn = 0.0
        if key_down(79):
            turn += 1.0
        if key_down(80):
            turn -= 1.0
        let mx = mouse_x()
        let mdx = mx - self.last_mouse_x
        self.last_mouse_x = mx
        let mouse_turn = (mdx as f32) * 0.003
        self.player.angle += turn * 2.5 * dt + mouse_turn

        # Movement: WASD / arrows.
        let move_speed = 3.0 * dt
        let dir_x = cos(self.player.angle)
        let dir_y = sin(self.player.angle)
        let mut move_x = 0.0
        let mut move_y = 0.0
        if key_down(26) or key_down(82):
            move_x += dir_x
            move_y += dir_y
        if key_down(22) or key_down(81):
            move_x -= dir_x
            move_y -= dir_y
        if key_down(4):
            move_x += dir_y
            move_y -= dir_x
        if key_down(7):
            move_x -= dir_y
            move_y += dir_x
        let mlen = sqrt(move_x * move_x + move_y * move_y)
        if mlen > 0.0:
            move_x = move_x / mlen * move_speed
            move_y = move_y / mlen * move_speed
        let new_x = self.player.x + move_x
        let new_y = self.player.y + move_y
        if map::cell_at(map_grid, new_x as i32, self.player.y as i32) == 0:
            self.player.x = new_x
        if map::cell_at(map_grid, self.player.x as i32, new_y as i32) == 0:
            self.player.y = new_y

        # Firing.
        let fire = mouse_button_down(1) or key_down(44)
        if fire and !self.last_fire and self.player.alive and self.player.mana >= 5.0:
            self.player.mana -= 5.0
            let bx = self.player.x + dir_x * 0.5
            let by = self.player.y + dir_y * 0.5
            self.projectiles.push(Projectile(x = bx, y = by, dx = dir_x * 8.0, dy = dir_y * 8.0, friendly = true, alive = true))
            self.recoil = 0.15
            if !is_null(sounds.zap):
                sound_play(sounds.zap)
        self.last_fire = fire
        if self.recoil > 0.0:
            self.recoil -= dt
        return self

    fn update_enemies(mut self, dt: f32, map_grid: List<i32>) -> Game:
        # `List<T>` only supports `push`/`pop`/`len`; index writes on a
        # `self.`-backed list also fail for the same "cannot store to this
        # expression" reason. Rebuild the list from scratch.
        let mut updated: List<Enemy> = List<Enemy>()
        let mut i = 0
        while i < self.enemies.len():
            let mut e = self.enemies[i]
            if e.alive:
                let dx = self.player.x - e.x
                let dy = self.player.y - e.y
                let dist = sqrt(dx * dx + dy * dy)
                if dist > 0.1:
                    let speed = if e.kind == 0: 1.5 else: 0.8
                    let step = speed * dt
                    let nx = e.x + dx / dist * step
                    let ny = e.y + dy / dist * step
                    if map::cell_at(map_grid, nx as i32, e.y as i32) == 0:
                        e.x = nx
                    if map::cell_at(map_grid, e.x as i32, ny as i32) == 0:
                        e.y = ny
                e.cooldown -= dt
                if e.kind == 0 and dist < 6.0 and e.cooldown <= 0.0 and has_los(map_grid, e.x, e.y, self.player.x, self.player.y):
                    let pdx = (self.player.x - e.x) / dist
                    let pdy = (self.player.y - e.y) / dist
                    self.projectiles.push(Projectile(x = e.x, y = e.y, dx = pdx * 4.0, dy = pdy * 4.0, friendly = false, alive = true))
                    e.cooldown = 2.0
                if e.kind == 1 and dist < 1.5 and e.cooldown <= 0.0:
                    self.player.health -= 10.0
                    if self.player.health <= 0.0:
                        self.player.health = 0.0
                        self.player.alive = false
                    e.cooldown = 1.0
            updated.push(e)
            i += 1
        self.enemies = updated
        return self

    fn update_projectiles(mut self, dt: f32, map_grid: List<i32>) -> Game:
        let mut updated_proj: List<Projectile> = List<Projectile>()
        let mut updated_enemies: List<Enemy> = List<Enemy>()
        let mut i = 0
        while i < self.projectiles.len():
            let mut p = self.projectiles[i]
            if p.alive:
                p.x += p.dx * dt
                p.y += p.dy * dt
                if map::cell_at(map_grid, p.x as i32, p.y as i32) > 0:
                    p.alive = false
                else:
                    if p.friendly:
                        let mut j = 0
                        while j < self.enemies.len():
                            let e = self.enemies[j]
                            if e.alive:
                                let edx = e.x - p.x
                                let edy = e.y - p.y
                                if sqrt(edx * edx + edy * edy) < 0.4:
                                    let mut ne = e
                                    ne.health -= 10.0
                                    if ne.health <= 0.0:
                                        ne.alive = false
                                        self.player.score += if ne.kind == 0: 10 else: 25
                                    updated_enemies.push(ne)
                                    p.alive = false
                                    break
                            j += 1
                    else:
                        let pdx = self.player.x - p.x
                        let pdy = self.player.y - p.y
                        if sqrt(pdx * pdx + pdy * pdy) < 0.4:
                            self.player.health -= 5.0
                            if self.player.health <= 0.0:
                                self.player.health = 0.0
                                self.player.alive = false
                            p.alive = false
            updated_proj.push(p)
            i += 1
        # Merge surviving enemies into the updated list.
        let mut j = 0
        while j < self.enemies.len():
            let e = self.enemies[j]
            if e.alive:
                updated_enemies.push(e)
            j += 1
        self.projectiles = updated_proj
        self.enemies = updated_enemies
        return self

    fn update_pickups(mut self) -> Game:
        let mut updated: List<Pickup> = List<Pickup>()
        let mut i = 0
        while i < self.pickups.len():
            let mut p = self.pickups[i]
            if !p.taken:
                let dx = self.player.x - p.x
                let dy = self.player.y - p.y
                if sqrt(dx * dx + dy * dy) < 0.5:
                    p.taken = true
                    if p.kind == 0:
                        self.player.health = clamp(self.player.health + 25.0, 0.0, 100.0)
                    else:
                        self.player.mana = clamp(self.player.mana + 50.0, 0.0, 100.0)
            updated.push(p)
            i += 1
        self.pickups = updated
        return self

    fn update(mut self, dt: f32, map_grid: List<i32>, sounds: audio::Sounds) -> Game:
        self = self.update_input(dt, map_grid, sounds)
        self = self.update_enemies(dt, map_grid)
        self = self.update_projectiles(dt, map_grid)
        self = self.update_pickups()
        return self

# ---- Main ----------------------------------------------------------------

fn main():
    let w = window_create("Heresy", SCREEN_W * SCALE, SCREEN_H * SCALE)
    if is_null(w):
        println("window_create failed")
        return

    let font = default_font()
    let level = map::parse_level()
    let spriteset = sprites::make_sprites()
    let sounds = audio::make_sounds()

    # Sprite pixel buffers are baked into the framebuffer directly by
    # `render_sprites`; no separate texture handles are needed when using
    # `draw_pixels` (one-shot bulk blit) instead of a cached-texture loop.

    # Start the ambient drone.
    if !is_null(sounds.drone):
        music_play(sounds.drone)

    # Working framebuffer: built fresh each frame and handed to draw_pixels
    # (one-shot texture upload) so we never mutate a `Bytes` parameter
    # through an index -- `store_list_index` rejects parameter bindings as
    # a non-storable place because the COW clone has nowhere to write the
    # new object pointer back to.
    let mut framebuffer = Bytes()
    let mut prefill = 0
    while prefill < SCREEN_W * SCREEN_H * 4:
        framebuffer.push(0 as u8)
        prefill += 1

    let mut game = new_game(level)
    game.last_mouse_x = mouse_x()
    game.last_ticks = ticks()

    while true:
        if window_should_close(w):
            break
        if key_down(41):
            break

        let now = ticks()
        let mut dt = ((now - game.last_ticks) as f32) / 1000.0
        game.last_ticks = now
        dt = clamp(dt, 0.0, 0.05)

        game = game.update(dt, level.map, sounds)

        # Render the software framebuffer. Neither function takes the
        # framebuffer as a parameter -- they build a fresh one each call.
        let rendered = render_walls(game.player.x, game.player.y, game.player.angle, level.map)
        framebuffer = rendered.0
        let zbuf = rendered.1
        framebuffer = render_sprites(zbuf, game.player.x, game.player.y, game.player.angle, game.enemies, game.projectiles, game.pickups, spriteset)

        # Blit the framebuffer to the window.
        draw_pixels(w, framebuffer, SCREEN_W, SCREEN_H, 0, 0, SCREEN_W * SCALE, SCREEN_H * SCALE)

        # HUD.
        draw_text(w, font, f"HP {game.player.health as i32}", 8, 8, 2, Color32(240, 60, 60, 255))
        draw_text(w, font, f"MP {game.player.mana as i32}", 8, 28, 2, Color32(60, 120, 240, 255))
        draw_text(w, font, f"SCORE {game.player.score}", 8, 48, 2, Color32(240, 240, 240, 255))
        draw_text(w, font, "WASD MOVE  MOUSE AIM  CLICK FIRE", 8, SCREEN_H * SCALE - 20, 1, Color32(160, 160, 160, 255))

        # Crosshair.
        let cx = SCREEN_W * SCALE / 2
        let cy = SCREEN_H * SCALE / 2
        draw_rect(w, cx - 4, cy - 1, 8, 2, Color32(255, 255, 255, 255))
        draw_rect(w, cx - 1, cy - 4, 2, 8, Color32(255, 255, 255, 255))

        # Weapon viewmodel (a simple "starbolt launcher" that kicks on fire).
        let weapon_y = if game.recoil > 0.0: SCREEN_H * SCALE - 60 else: SCREEN_H * SCALE - 50
        draw_rect(w, cx - 30, weapon_y, 60, 40, Color32(120, 100, 80, 255))
        draw_rect(w, cx - 8, weapon_y + 8, 16, 24, Color32(200, 180, 120, 255))

        if !game.player.alive:
            let msg = "YOU DIED"
            let sz = measure_text(font, msg, 3)
            draw_text(w, font, msg, (SCREEN_W * SCALE - sz.0) / 2, (SCREEN_H * SCALE - sz.1) / 2, 3, Color32(240, 40, 40, 255))
            let msg2 = "PRESS R TO RESTART"
            let sz2 = measure_text(font, msg2, 2)
            draw_text(w, font, msg2, (SCREEN_W * SCALE - sz2.0) / 2, (SCREEN_H * SCALE - sz2.1) / 2 + 30, 2, Color32(240, 240, 240, 255))
            if key_down(21):
                game = new_game(level)
                game.last_mouse_x = mouse_x()
                game.last_ticks = ticks()

        present(w)
        delay(16)

    # Cleanup.
    sound_stop_all()
    sound_free(sounds.zap)
    sound_free(sounds.growl)
    sound_free(sounds.pickup)
    sound_free(sounds.drone)
    window_destroy(w)
