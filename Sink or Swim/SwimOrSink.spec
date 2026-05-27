# Swim or Sink — Project Specification
# Version: 1.0
# Author: Brayden Weismantel
# Created: 17 March 2026

## Overview
Swim or Sink is a Flappy Bird-style side-scrolling iOS game built entirely in
SwiftUI. The player controls a pixel-art mermaid who swims through gaps in coral
obstacles, collecting pearls for points. The game features an 8-bit retro
aesthetic with hand-crafted pixel sprites, organic coral obstacles, and an
underwater ocean environment.

## Platform
- iOS (SwiftUI)
- Swift 6 / Xcode
- No external dependencies
- Single-file architecture (ContentView.swift)

## Game Flow
1. **Main Menu** → Title screen with animated mermaid, floating bubbles, game
   title ("SWIM / OR SINK"), instructions, pearl value legend, and "DIVE IN"
   button
2. **Difficulty Select** → Three difficulty tiers (Easy, Medium, Hard) with
   descriptions and visual indicators
3. **Gameplay** → Side-scrolling gameplay with tap-to-swim controls
4. **Death Screen** → Game over overlay with score/best/pearls stats, "TRY
   AGAIN" (replays same difficulty), and "MAIN MENU" button

State machine: `menu → chooseDifficulty → playing → dead → (playing | menu)`

## Difficulty Tiers

| Parameter      | Easy ("Calm waters") | Medium ("Choppy seas") | Hard ("The deep") |
|----------------|----------------------|------------------------|-------------------|
| Scroll Speed   | 130                  | 155                    | 180               |
| Gap Height     | 280                  | 250                    | 220               |
| Gravity        | 600                  | 700                    | 800               |
| Flap Impulse   | -250                 | -265                   | -280              |
| Spawn Interval | 2.0s                 | 1.7s                   | 1.5s              |

Spawn interval decreases with score (min 65% of base value).

## Pearl System

| Type    | Color          | Spawn Chance    | Points |
|---------|----------------|-----------------|--------|
| Normal  | White/pearl    | ~25% per coral  | +5     |
| Gold    | Yellow/amber   | ~15% of pearls  | +10    |
| Diamond | Icy blue       | ~3% of pearls   | +20    |

- Pearls spawn in the gap of coral obstacles
- Collected on proximity (24pt radius)
- Pearl values are displayed on the main menu as a legend
- Diamond pearls have an animated sparkle cross effect

## Mermaid Character
### In-Game Sprite (PixelMermaidView)
- 22x14 pixel grid, rendered at 3pt per pixel
- Side-view swimming pose facing right
- Blue flowing hair trailing behind
- Purple shell bikini top
- Teal/aqua scaled tail with fin
- 4-frame swim animation cycle
- Positioned at 25% screen width (horizontal)
- Tilt angle based on vertical velocity (-25° to +35°)

### Menu Sprite (MenuMermaidView)
- 21x36 pixel grid, rendered at 2.5pt per pixel
- Upright portrait pose with dark outlines
- Kawaii-style eyes: eyelashes, white sclera, blue iris with shine dots
- Rosy blush cheeks
- Detailed blue hair framing face
- Shell bikini top, visible arms
- Tapered scaled tail with fan fin
- Gentle bounce animation on menu screen

## Collision
- Mermaid hitbox: sprite size inset by 16px on each side (forgiving)
- Obstacle hitbox: coral column ±28px from center
- Death triggers on coral contact or screen boundary (top/bottom)

## Obstacles (Coral)
- Coral-only obstacles with 6 random color schemes:
  Red, Orange, Purple, Pink, Teal, Yellow
- Rendered using Canvas API with organic blobby shapes
- Deterministic pseudo-random (seeded LCG) for consistent shapes per instance
- Features: blobby trunk segments, side branches/fronds, rounded polyp tips
- Dark outline → mid fill → bright highlight layering
- Top coral is flipped, bottom coral grows upward
- 80pt frame width

## Scoring
- +1 point for each coral obstacle passed
- +5 / +10 / +20 for Normal / Gold / Diamond pearls
- Best score persisted in memory (resets on app close)
- Pearl count tracked separately

## Visual Environment

### Ocean Background
- 4-layer vertical gradient (top → floor)
- Sandy bottom with pixel rectangles
- Animated kelp strands (sine wave motion)

### Ambient Effects
- **Bubbles**: Float upward with sine wobble, white ring + highlight dot
- **Particles**: Floating plankton/dust with subtle drift
- **Trail Bubbles**: Spawn behind mermaid on flap, fade over time
- **Menu Bubbles**: Self-contained bubble system for menu/difficulty screens
  (30fps timer, Canvas-rendered)

### HUD
- Top-left: Pearl counter (mini pearl icon + count)
- Top-right: Score display
- 8-bit monospaced font styling throughout
- Pixel shadow effects on text

## Architecture

### File Structure
```
Sink or Swim/
├── SinkOrSwimApp.swift        # App entry point (@main)
├── ContentView.swift          # All game code (~1700 lines)
├── Info.plist
├── Assets.xcassets
├── Item.swift
└── Sink_or_Swim.entitlements
```

### Key Types
- `Palette` — Static color constants for the 8-bit art style
- `Difficulty` — Enum with per-tier game parameters
- `GameConfig` — Shared constants (sprite size, pearl size, pixel size)
- `GameState` — Enum: menu, chooseDifficulty, playing, dead
- `PearlType` — Enum: normal, gold, diamond (with point values)
- `CoralColors` — Struct with bright/mid/dark color triplet, 6 schemes
- `Obstacle` — Identifiable struct (position, color, pearl, scoring state)
- `Bubble`, `Particle`, `TrailBubble` — Ambient effect models
- `GameViewModel` — @Observable class, owns all game state and 60fps timer loop

### Key Views
- `ContentView` — Root view, switches between menu/difficulty/game states
- `MenuView` — Title screen with mermaid, title, instructions, pearl legend
- `DifficultySelectView` — Three-button difficulty picker
- `GameView` — Gameplay layer (obstacles, pearls, mermaid, HUD, death overlay)
- `PixelMermaidView` — In-game side-view mermaid sprite
- `MenuMermaidView` — Upright portrait mermaid for title screen
- `ObstacleView` — Positions top/bottom coral pair
- `CoralObstacle` — Canvas-rendered organic coral shape
- `PearlView` — Animated pearl with type-based coloring
- `PearlLegendItem` — Mini pearl + label for menu legend
- `HUDView` — Score and pearl counter overlay
- `DeathView` — Game over screen with stats and buttons
- `OceanBackground` — Gradient + sand + kelp
- `BubbleLayer` / `ParticleLayer` — Ambient effect renderers
- `MenuBubbles` — Self-contained bubble animation for menu screens

### Rendering Approach
- Pixel sprites: `[[Character]]` grid arrays with character-to-color mapping,
  rendered as SwiftUI Rectangle views
- Coral: SwiftUI Canvas API with ellipse-based blob rendering
- Ambient effects: SwiftUI ForEach with Circle/Rectangle views
- Menu bubbles: Canvas API with independent 30fps timer
- Game loop: 60fps Timer.scheduledTimer driving @Observable state updates

## Controls
- Tap anywhere during gameplay to swim (flap upward)
- Tap "DIVE IN" on menu to proceed to difficulty selection
- Tap difficulty button to start game
- Tap "TRY AGAIN" on death to replay same difficulty
- Tap "MAIN MENU" on death to return to title screen
