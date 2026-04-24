```lua
-- Update WIN --
natidcs.ww2LandWinPicture.updateWinPicture(42, {
    zones = { 'Versailles_Palace' },
    airbases = { 'Barville', 'Essay', 'Lonrai' },
    showLander = true,
})

-- When final (all objectives) completed:
natidcs.ww2LandWinPicture.setWin()
```