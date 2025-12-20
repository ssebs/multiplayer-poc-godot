# Multiplayer Architecture Diagram

## Overview

This is a Godot 4.5 multiplayer proof-of-concept implementing a **client-server authority model** for a top-down 2D shooter game.

---

## High-Level Architecture

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                              NETWORK TOPOLOGY                                │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                              │
│    ┌──────────────┐         ┌──────────────┐         ┌──────────────┐       │
│    │   CLIENT A   │         │    SERVER    │         │   CLIENT B   │       │
│    │   (Peer 2)   │◄───────►│   (Peer 1)   │◄───────►│   (Peer 3)   │       │
│    └──────────────┘  ENet   └──────────────┘  ENet   └──────────────┘       │
│                      UDP          │          UDP                             │
│                                   │                                          │
│                          Port 42069                                          │
│                                                                              │
└─────────────────────────────────────────────────────────────────────────────┘
```

---

## Authority Distribution

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                          AUTHORITY BOUNDARIES                                │
├───────────────────────────────┬─────────────────────────────────────────────┤
│        SERVER AUTHORITY       │            CLIENT AUTHORITY                  │
│           (Peer 1)            │            (Peer 2, 3, ...)                  │
├───────────────────────────────┼─────────────────────────────────────────────┤
│                               │                                              │
│  ┌─────────────────────────┐  │  ┌─────────────────────────┐                │
│  │   PLAYER MOVEMENT       │  │  │   INPUT POLLING         │                │
│  │   • move_and_slide()    │  │  │   • Keyboard/Mouse      │                │
│  │   • Position updates    │  │  │   • input_dir vector    │                │
│  └─────────────────────────┘  │  └─────────────────────────┘                │
│                               │                                              │
│  ┌─────────────────────────┐  │  ┌─────────────────────────┐                │
│  │   ENEMY MANAGEMENT      │  │  │   UI RENDERING          │                │
│  │   • Spawning            │  │  │   • Chat display        │                │
│  │   • AI Pathfinding      │  │  │   • Aim arrow rotation  │                │
│  │   • Position updates    │  │  │   • Lobby display       │                │
│  └─────────────────────────┘  │  └─────────────────────────┘                │
│                               │                                              │
│  ┌─────────────────────────┐  │  ┌─────────────────────────┐                │
│  │   COLLISION DETECTION   │  │  │   VISUAL-ONLY EFFECTS   │                │
│  │   • Enemy-Player hits   │  │  │   • Bullet instantiation│                │
│  │   • Death triggering    │  │  │   • Local animations    │                │
│  └─────────────────────────┘  │  └─────────────────────────┘                │
│                               │                                              │
│  ┌─────────────────────────┐  │                                              │
│  │   GAME LIFECYCLE        │  │                                              │
│  │   • Player spawning     │  │                                              │
│  │   • Player respawning   │  │                                              │
│  │   • Action validation   │  │                                              │
│  └─────────────────────────┘  │                                              │
│                               │                                              │
└───────────────────────────────┴─────────────────────────────────────────────┘
```

---

## Component Architecture

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                              SCENE HIERARCHY                                 │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                              │
│  GameMain (Node) ──────────────── Lifecycle Coordinator                     │
│  │                                                                           │
│  ├── MultiplayerManager (Node) ── Network Setup & Entity Spawning           │
│  │   │                                                                       │
│  │   ├── ENetMultiplayerPeer ──── Server: listen() / Client: connect()      │
│  │   │                                                                       │
│  │   └── Signals ────────────────┐                                          │
│  │       ├── player_connected    │                                          │
│  │       ├── player_disconnected │                                          │
│  │       └── server_disconnected │                                          │
│  │                                                                           │
│  ├── LobbyUI (Control) ────────── Connection Interface                      │
│  │                                                                           │
│  ├── TextChatUI (Control) ─────── Chat System                               │
│  │                                                                           │
│  └── Level (Node2D) ───────────── Game World                                │
│      │                                                                       │
│      ├── Players (Node2D) ─────── Container for NetworkedPlayer instances   │
│      │   └── NetworkedPlayer ──── Player Entity (see detail below)          │
│      │                                                                       │
│      ├── Enemies (Node2D) ─────── Container for Enemy instances             │
│      │   └── Enemy ────────────── Enemy Entity (server-controlled)          │
│      │                                                                       │
│      └── Stuff (Node2D) ───────── Static Level Geometry                     │
│                                                                              │
└─────────────────────────────────────────────────────────────────────────────┘
```

---

## NetworkedPlayer Detail

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                        NetworkedPlayer (CharacterBody2D)                     │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                              │
│  ┌─────────────────────────────────────────────────────────────────────┐    │
│  │  MultiplayerSynchronizer (Position Sync)                             │    │
│  │  ├── Syncs: position                                                 │    │
│  │  ├── Authority: Server (Peer 1)                                      │    │
│  │  └── Mode: Always replicate                                          │    │
│  └─────────────────────────────────────────────────────────────────────┘    │
│                                                                              │
│  ┌─────────────────────────────────────────────────────────────────────┐    │
│  │  InputSynchronizer (Node + MultiplayerSynchronizer)                  │    │
│  │  ├── Syncs: input_dir (Vector2)                                      │    │
│  │  ├── Authority: Owning Client                                        │    │
│  │  ├── Reads: Keyboard input (WASD)                                    │    │
│  │  └── Sends: Shoot/Animate RPCs to server                             │    │
│  └─────────────────────────────────────────────────────────────────────┘    │
│                                                                              │
│  ┌─────────────────────────────────────────────────────────────────────┐    │
│  │  RPCs Defined:                                                        │    │
│  │  ├── die() ─────────────── @rpc("call_local")                        │    │
│  │  ├── shoot_bullet() ────── @rpc("call_local")                        │    │
│  │  └── play_rotate_anim() ── @rpc("call_local")                        │    │
│  └─────────────────────────────────────────────────────────────────────┘    │
│                                                                              │
└─────────────────────────────────────────────────────────────────────────────┘
```

---

## Data Flow: Input to Action

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                         INPUT → MOVEMENT FLOW                                │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                              │
│   CLIENT (Owner)                           SERVER                            │
│   ─────────────                           ──────                             │
│                                                                              │
│   ┌─────────────────┐                                                        │
│   │ Input.get_axis  │                                                        │
│   │ (WASD keys)     │                                                        │
│   └────────┬────────┘                                                        │
│            │                                                                 │
│            ▼                                                                 │
│   ┌─────────────────┐     MultiplayerSync     ┌─────────────────┐           │
│   │ input_dir       │ ───────────────────────►│ input_dir       │           │
│   │ (Vector2)       │     (auto-replicated)   │ (received)      │           │
│   └─────────────────┘                         └────────┬────────┘           │
│                                                        │                     │
│                                                        ▼                     │
│                                               ┌─────────────────┐           │
│                                               │ velocity =      │           │
│                                               │ input_dir*speed │           │
│                                               └────────┬────────┘           │
│                                                        │                     │
│                                                        ▼                     │
│                                               ┌─────────────────┐           │
│                                               │ move_and_slide()│           │
│                                               └────────┬────────┘           │
│                                                        │                     │
│   ┌─────────────────┐     MultiplayerSync              │                     │
│   │ position        │◄────────────────────────────────┘                     │
│   │ (updated)       │     (auto-replicated)                                  │
│   └─────────────────┘                                                        │
│                                                                              │
└─────────────────────────────────────────────────────────────────────────────┘
```

---

## Data Flow: Shooting

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                           SHOOTING FLOW                                      │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                              │
│   CLIENT A                    SERVER                     ALL CLIENTS         │
│   ────────                   ──────                     ───────────          │
│                                                                              │
│   ┌──────────────┐                                                           │
│   │ Mouse click  │                                                           │
│   │ (shoot)      │                                                           │
│   └──────┬───────┘                                                           │
│          │                                                                   │
│          ▼                                                                   │
│   ┌──────────────────────────┐                                               │
│   │ tell_clients_to_shoot    │                                               │
│   │ .rpc_id(1, mouse_pos)    │─────────────────┐                             │
│   └──────────────────────────┘                 │                             │
│                                                │                             │
│                                                ▼                             │
│                              ┌───────────────────────────┐                   │
│                              │ if multiplayer.is_server():│                  │
│                              │   player.shoot_bullet.rpc()│                  │
│                              └───────────────┬───────────┘                   │
│                                              │                               │
│                                              │ broadcast                     │
│                                              ▼                               │
│                                        ┌───────────┐                         │
│                                        │ shoot_    │                         │
│                                        │ bullet()  │──────────────────┐      │
│                                        └───────────┘                  │      │
│                                                                       ▼      │
│   ┌────────────────────────────────────────────────────────────────────┐    │
│   │  ALL CLIENTS: Instantiate bullet locally, add to scene tree        │    │
│   │  (Bullets are NOT synchronized - visual only)                       │    │
│   └────────────────────────────────────────────────────────────────────┘    │
│                                                                              │
└─────────────────────────────────────────────────────────────────────────────┘
```

---

## Data Flow: Death & Respawn

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                        DEATH & RESPAWN FLOW                                  │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                              │
│   SERVER ONLY                                           ALL CLIENTS          │
│   ───────────                                          ───────────           │
│                                                                              │
│   ┌───────────────────────┐                                                  │
│   │ Enemy._physics_process│                                                  │
│   │ (AI navigation)       │                                                  │
│   └───────────┬───────────┘                                                  │
│               │                                                              │
│               ▼                                                              │
│   ┌───────────────────────┐                                                  │
│   │ Collision detected    │                                                  │
│   │ (Enemy hits Player)   │                                                  │
│   └───────────┬───────────┘                                                  │
│               │                                                              │
│               ▼                                                              │
│   ┌───────────────────────┐     broadcast     ┌───────────────────────┐     │
│   │ player.die.rpc()      │ ─────────────────►│ die()                 │     │
│   │                       │                   │ └─► queue_free()      │     │
│   └───────────┬───────────┘                   └───────────────────────┘     │
│               │                                                              │
│               ▼                                                              │
│   ┌───────────────────────┐                                                  │
│   │ Wait 2 seconds        │                                                  │
│   │ (respawn timer)       │                                                  │
│   └───────────┬───────────┘                                                  │
│               │                                                              │
│               ▼                                                              │
│   ┌───────────────────────┐     spawn         ┌───────────────────────┐     │
│   │ _spawn_player(id)     │ ─────────────────►│ New NetworkedPlayer   │     │
│   │ (server spawns)       │   (replicated)    │ appears on all        │     │
│   └───────────────────────┘                   └───────────────────────┘     │
│                                                                              │
└─────────────────────────────────────────────────────────────────────────────┘
```

---

## Synchronization Summary

| Entity | Sync Method | Authority | Direction | Reliability |
|--------|-------------|-----------|-----------|-------------|
| Player Position | MultiplayerSynchronizer | Server | Server → All | Continuous |
| Input Direction | MultiplayerSynchronizer | Client Owner | Client → Server | Continuous |
| Enemy Position | MultiplayerSynchronizer | Server | Server → All | Continuous |
| Shoot Action | RPC | Server validates | Client → Server → All | Reliable |
| Rotate Animation | RPC | Server validates | Client → Server → All | Reliable |
| Player Death | RPC | Server detects | Server → All | Reliable |
| Chat Messages | RPC | Any peer | Peer → All | Reliable |

---

## RPC Patterns Used

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                            RPC ANNOTATIONS                                   │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                              │
│  @rpc("call_local")                                                          │
│  └── Executes on sender + all remotes                                        │
│  └── Used for: die(), shoot_bullet(), start_game()                           │
│                                                                              │
│  @rpc("any_peer", "call_local", "reliable")                                  │
│  └── Any client can send (not just server)                                   │
│  └── Used for: tell_clients_to_shoot_bullet(), chat messages                 │
│                                                                              │
│  @rpc("call_local", "reliable")                                              │
│  └── Guaranteed delivery, executes locally too                               │
│  └── Used for: lobby updates, game state changes                             │
│                                                                              │
└─────────────────────────────────────────────────────────────────────────────┘
```

---

## Key Files Reference

| File | Purpose |
|------|---------|
| [multiplayer_manager.gd](scripts/multiplayer_manager.gd) | Network setup, player/enemy spawning |
| [networked_player.gd](scripts/networked_player.gd) | Player entity with server authority |
| [input_synchronizer.gd](scripts/input_synchronizer.gd) | Input polling and RPC dispatch |
| [enemy.gd](scripts/enemy.gd) | Server-only enemy AI |
| [game_main.gd](scripts/game_main.gd) | Game lifecycle coordinator |
| [bullet.gd](scripts/bullet.gd) | Projectile (client-spawned, not synced) |

---

## Design Notes

**Strengths:**
- Clear server authority prevents cheating
- Clean separation of input (client) vs execution (server)
- Uses Godot's built-in synchronization where possible
- Groups (`players`, `enemies`) for easy entity querying

**Limitations:**
- No network interpolation (may be jittery on high latency)
- No latency compensation for shooting
- Bullets not network-synced (visual-only, may differ between clients)
- Cannot join mid-game (must join before start)
