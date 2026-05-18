# Tower Defense

A 2D tower defense game built with **Godot 4.6** and GDScript. Features grid-based tower placement, wave-based enemy spawning, and procedural polygon art — no sprite assets required.

## Features

### Towers
| Tower | Cost | Damage | Fire Rate | Range | Special |
|-------|------|--------|-----------|-------|---------|
| **Basic** | 25g | 10 | 1.0/s | 150px | — |
| **Sniper** | 50g | 40 | 0.5/s | 250px | Long range |
| **Cannon** | 40g | 20 | 0.6/s | 120px | 80px splash AoE |
| **Frost** | 35g | 5 | 1.5/s | 130px | 40% slow for 2s |

### Enemies
| Type | Description |
|------|-------------|
| **Grunt** | Standard orc, balanced stats |
| **Runner** | Smaller and faster, low health |
| **Brute** | Large and tanky with armor, slow |
| **Shaman** | Purple skin, glowing green eyes, magic staff |
| **Warlord** | Boss unit — massive health, gold armor, bright tusks |

### Levels
1. **Grasslands** — Introductory S-curve path (5 waves)
2. **Serpent River** — Wide S-curves with water crossings (6 waves)
3. **The Gauntlet** — Tight full-width zigzag (7 waves)
4. **Frozen Marsh** — Winding path through heavy water/mud terrain (6 waves)
5. **Warlord's Keep** — Spiral path inward, longest and hardest (8 waves)

### Gameplay
- **Build phase** between waves — place towers on the grid while a 15-second countdown ticks
- **Send early** by clicking Next Wave to skip the countdown
- **Terrain effects** — mud and water tiles slow enemies passing through
- **Difficulty settings** — Easy, Normal, Hard (affects enemy health, speed, and gold rewards)
- **Fullscreen toggle** available in-game and from the options menu

## How to Run

1. Download and install [Godot 4.6](https://godotengine.org/download)
2. Clone the repository:
   ```bash
   git clone https://github.com/trqarg/towerdefense.git
   ```
3. Open Godot and import the project folder
4. Press **F5** or click the Play button

## Project Structure

```
towerdefense/
├── project.godot
├── scenes/
│   ├── main.tscn              # Game scene (map + HUD + spawner)
│   ├── main_menu.tscn         # Title screen
│   ├── level_select.tscn      # Level picker
│   ├── options.tscn            # Settings screen
│   ├── enemies/
│   │   └── enemy.tscn         # Orc enemy (Polygon2D body parts)
│   ├── towers/
│   │   ├── tower.tscn         # Basic tower
│   │   ├── sniper_tower.tscn
│   │   ├── cannon_tower.tscn
│   │   └── frost_tower.tscn
│   ├── projectiles/
│   │   └── projectile.tscn
│   └── ui/
│       └── hud.tscn
├── scripts/
│   ├── game_state.gd          # Autoload singleton (levels, difficulty, settings)
│   ├── game_map.gd            # Grid rendering, tower placement, terrain
│   ├── main.gd                # Game loop, gold/lives, wave flow
│   ├── wave_spawner.gd        # Wave queue, mixed-type spawning
│   ├── enemy.gd               # Enemy types, walking animation, slow effects
│   ├── tower.gd               # Targeting, firing, range detection
│   ├── projectile.gd          # Homing projectiles, splash, slow-on-hit
│   ├── hud.gd                 # Tower buttons, labels, options panel
│   ├── banner.gd              # Phase/countdown banner messages
│   ├── main_menu.gd
│   ├── level_select.gd
│   └── options.gd
└── icon.svg
```

## Controls

- **Click** a tower button, then **click** a grid cell to place it
- **Next Wave** button (or wait for the 15s auto-countdown)
- **Esc / Options** to open the pause menu with fullscreen and difficulty toggles

## License

MIT
