# Grouflon 3rd Strike Training Mode + Late Cancel Trainer

**Full-featured SF3 training mode with integrated Chun-Li cr.MK late cancel timing analysis**

This is a fork of [Grouflon's 3rd Strike Training Mode](https://github.com/Grouflon/3rd_training_lua) with an added late cancel timing trainer for practicing Chun-Li's cr.MK late cancel into Super Art.

---

## Features

### All Original Grouflon Features ✅
- **Hitbox Display** - View attack/hurt/throw boxes
- **Frame Data** - Real-time frame advantage display
- **Recording/Playback** - Record and replay dummy actions
- **Counter-Attack Training** - Practice punishes and reactions
- **Parry Training** - Visual parry timing feedback
- **Charge Training** - Charge move practice
- **Hyakuretsu Kyaku Training** - Chun-Li's lightning legs
- **Input History** - See your inputs on-screen
- **Customizable Dummy** - Control dummy behavior
- **And much more!**

### NEW: Late Cancel Timing Trainer ⭐
- **Frame-Perfect Analysis** - Tracks timing for frames 23-24 late cancel window
- **Motion Detection** - QCF/QCB with SF3-accurate shortcuts
- **Piano Support** - Tracks multiple kick presses
- **Negative Edge** - Detects button releases
- **Input Buffering** - Hold down while pressing MK
- **Statistics** - Session tracking with success rate
- **Real-Time Feedback** - On-screen timing results

---

## Installation

1. **Download this folder** (`3rd_training_lua-master`) to your FightCade directory
2. **Load in FightCade**:
   - Open FightCade 2
   - Load **Street Fighter III: 3rd Strike (Japan 990512)**
   - Start a match
   - Go to `Game → Lua Scripting → New Lua Script Window`
   - Browse to `3rd_training_lua-master/3rd_training.lua`
   - Click **Run**

---

## Usage

### Grouflon Training Mode

Press **Start** during a match to open the training menu. From here you can:
- Configure dummy behavior
- Enable hitbox display
- Set up recordings
- Adjust training settings
- And much more!

See the [original Grouflon README](https://github.com/Grouflon/3rd_training_lua) for full documentation.

### Late Cancel Trainer

The late cancel trainer can be toggled on/off directly from the training menu:

1. **Open the training menu** - Press **Start** during a match
2. **Navigate to Display menu**
3. **Enable "Late Cancel Trainer (Chun-Li)"** - Check the box
4. **Close the menu** - Press **Start** again
5. **Press P1 MK** to start a trial (simulates cr.MK)
6. **Perform QCF, QCF + Kick**: ↓↘→, ↓↘→ + Kick
7. **View feedback** on-screen:
   - ✓✓ PERFECT! = Frames 23-24 ✅
   - ✗ EARLY = Before frame 23
   - ✗ LATE = After frame 24

**Display Location:** Bottom-left corner (below Grouflon's UI)

**Statistics:** Tracks attempts, perfect, early, late, and failed hits with success rate

---

## Configuration

### Late Cancel Trainer Settings

**Toggle On/Off:** Use the in-game menu (Start → Display → Late Cancel Trainer)

**Advanced Configuration:** Edit `src/late_cancel_trainer.lua` to customize timing windows:

```lua
config = {
    LATE_CANCEL_START_FRAME = 22,  -- Start of late cancel window
    LATE_CANCEL_END_FRAME = 24,    -- End of late cancel window
    MOTION_INPUT_WINDOW = 60,      -- Frames to complete double motion
    DIRECTION_BUFFER_SIZE = 30,    -- Direction history size
},
```

---

## Tips for Practice

1. **Start slow** - Focus on clean motion inputs first
2. **Use the shortcut** - ↓↘→, ↓↘
4. **Piano for consistency** 
5. **Watch frame numbers** - Adjust timing based on feedback
6. **Use Grouflon's features** - Set dummy to random block after you get comforable with the timing

---

## File Structure

```
3rd_training_lua-master/
├── 3rd_training.lua              (Main script - load this!)
├── README.md                     (This file)
├── src/
│   ├── late_cancel_trainer.lua   (Late cancel module - NEW!)
│   ├── gamestate.lua
│   ├── display.lua
│   ├── framedata.lua
│   └── ... (other Grouflon modules)
├── data/
│   └── sfiii3nr1/                (Frame data for all characters)
├── images/
│   └── ... (UI assets)
└── saved/
    └── recordings/               (Your saved recordings)
```

---

## Credits

- **Original Grouflon Training Mode**: [https://github.com/Grouflon/3rd_training_lua](https://github.com/Grouflon/3rd_training_lua)
  - Created by Grouflon
  - Contributors: esn3s, dammit, furitiem, crystal_cube99, speedmccool25, ProfessorAnon, sammygutierrez
- **Late Cancel Trainer**: Added by request
- **Integration**: Seamlessly integrated into Grouflon's architecture

---

## License

Based on Grouflon's work - free to use and modify for personal practice.

---

## Support

For issues with:
- **Grouflon features**: See [original repository](https://github.com/Grouflon/3rd_training_lua)
- **Late cancel trainer**: Check `src/late_cancel_trainer.lua` configuration

---

**Enjoy your training! 🥋**
