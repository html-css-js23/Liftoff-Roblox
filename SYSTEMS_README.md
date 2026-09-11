# Liftoff Roblox Game Systems

## Overview
This game includes a complete economy system with:
- **Leaderboard System**: Roblox native leaderboard showing Cash and Rebirths
- **Money System**: Player cash tracking with persistence
- **Rebirth System**: Players can rebirth to gain progression
- **UI System**: Modern, animated interface displaying player stats

## File Structure

### Server Scripts (`src/server/`)
- **Leaderboard.luau**: Core system that manages player data, leaderboard creation, and DataStore persistence
- **MoneyRewards.luau**: Handles rewarding players with cash for various actions

### Client Scripts (`src/client/`)
- **init.client.luau**: Original game mechanics (scream system, plot system)
- **GameUI.client.luau**: Modern UI displaying stats and rebirth button

### Shared Modules (`src/shared/`)
- **Config.luau**: Centralized configuration for all game settings

## Game Mechanics

### Leaderboard
The game automatically creates a Roblox native leaderboard for each player with:
- **Cash**: Current money amount
- **Rebirths**: Total rebirth count

The leaderboard is visible to all players and persisted via DataStore.

### Money System
- Players start with **$100**
- Cash is earned through gameplay actions (examples in MoneyRewards system)
- Cash is multiplied by rebirth level (1.1x per rebirth)
- Cash persists across sessions via DataStore

### Rebirth System
- Cost: **$1000 cash**
- Effect: 
  - Cash resets to $100
  - Rebirths counter increments by 1
  - All future earnings get 1.1x multiplier per rebirth level
- Button shows in UI when player has enough cash

### UI System
Located in the top-right corner with:
- **Cash Display**: Shows current cash with $ prefix
- **Rebirths Display**: Shows total rebirth count
- **Rebirth Button**: Interactive button to perform rebirth
  - Disabled when cash < $1000
  - Smooth hover animations
  - Feedback on click

## Configuration

Edit `src/shared/Config.luau` to modify:
- Initial cash and rebirths
- Rebirth cost and bonus
- UI colors and dimensions
- Reward multipliers
- Action rewards

## Usage Examples

### Rewarding a Player for an Action
```luau
local Players = game:GetService("Players")
local RewardSystem = require(game.ServerScriptService:WaitForChild("MoneyRewards"))

local player = Players:FindFirstChildOfClass("Player")
if player then
    RewardSystem.RewardPlayer(player, 100, "Completed Task")
    -- or use predefined actions:
    RewardSystem.RewardAction(player, "KillEnemy")
end
```

### Accessing Player Stats
```luau
local player = Players.LocalPlayer
local cash = player.leaderstats.Cash.Value
local rebirths = player.leaderstats.Rebirths.Value
```

### Adding New Reward Actions
Edit `Config.luau` in the `Rewards.Actions` table:
```luau
Config.Rewards.Actions = {
    KillEnemy = 50,
    CompleteTask = 100,
    Milestone = 500,
    NewAction = 250, -- Add your custom action
}
```

## Features

✅ Full Roblox native leaderboard integration
✅ DataStore persistence (auto-saves every 30 seconds)
✅ Modern animated UI
✅ Rebirth progression system
✅ Rebirth-based multiplier for earnings
✅ Smooth animations and hover effects
✅ Configurable economy settings
✅ Extensible reward system

## Data Persistence

Player data is automatically saved:
- On player removal
- Every 30 seconds (auto-save)
- Via DataStore: `PlayerData:Player_{UserId}`

Data stored:
- Cash amount
- Rebirth count

## Extension Points

You can easily extend this system by:

1. **Adding new rewards**: Edit Config.Rewards.Actions
2. **Changing UI colors**: Edit Config.UI colors
3. **Adding new stat types**: Duplicate Cash/Rebirths value creation in Leaderboard.luau
4. **Custom economy logic**: Modify multiplier calculations in MoneyRewards.luau
5. **New UI panels**: Add frames to GameUI.client.luau following the same pattern

## Troubleshooting

**Leaderboard not showing**: Ensure Leaderboard.luau is in ServerScriptService
**UI not appearing**: Check that GameUI.client.luau is in StarterPlayer/StarterCharacterScripts or StarterPlayer/StarterGui
**Data not saving**: Check DataStore permissions in game settings
**Rebirth button disabled**: Need $1000 cash to rebirth

## Notes

- All cash values are integers (no decimal places)
- DataStore access requires game to be published
- UI respawns with player but persists data correctly
- Rebirth multiplier is 1.1x per rebirth level (compounding)
