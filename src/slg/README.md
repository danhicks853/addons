# Synastria Loot Guide

A World of Warcraft addon that helps you track, browse, and manage attunable loot in your current zone and beyond. Designed specifically for Synastria, it provides a powerful in-game interface to view loot eligibility, attunement progress, and more.

## Features

- **Zone Loot Browser:** View all attunable items available in your current zone, with filters for attuned, not attuned, eligible, or all items.
- **Zone Browser UI:** Explore loot tables for any zone in the game.
- **Attunement Tracking:** See your attunement progress for each item.
- **Minimap Button:** Quick access to the main window and zone browser.
- **Auto-Open Options:** Automatically show the loot window on login or when entering a new zone.
- **Developer Collector Module:** (Dev feature) Collects loot data from vendors, events, and inventory for advanced tracking and export.
- **Saved Settings:** User preferences are stored in `SLGSettings`.
- **Slash Commands:** `/slg` to toggle the window, `/slg config` for options.

## Installation

1. Download the latest release on the right side of this page.
2. Copy the entire `slg` folder into your WoW `Interface/AddOns` directory.
3. Launch World of Warcraft and enable "Synastria Loot Guide" in the AddOns menu.

## Usage

- Access the main window via the minimap button or by typing `/slg` in chat.
- Browse loot by zone, filter by attunement status, and track your collection progress.
- Use `/slg config` to open the configuration panel.
- Developers can use collector slash commands to export loot data for debugging or development.

## Configuration

- **Auto-open on Login/Zone Change:** Enable or disable automatic window display.
- **Display Modes:** Choose to show attuned, not attuned, all eligible, or all items.
- **Minimap Button:** Toggle visibility.
- **Collector Module:** Enable/disable data collection (dev feature).

## Dependencies

Bundled libraries (in `Libs/`):
- Ace3 suite (AceAddon-3.0, AceConfig-3.0, AceConsole-3.0, AceDB-3.0, AceGUI-3.0, AceHook-3.0, AceLocale-3.0)
- LibDataBroker-1.1
- CallbackHandler-1.0
- SynastriaCoreLib-1.0
- LibStub

No external downloads required.

## File Structure

- `core/` – Initialization, settings, constants.
- `modules/` – Attunement, item, zone, difficulty, and collector logic.
- `ui/` – Main window, minimap button, zone browser, item list, and frame helpers.
- `data/zone_items.lua` – Loot tables by zone.
- `utils/helpers.lua` – Utility functions.
- `debug.lua` – Debug and developer tools.
- `slg.toc` – Addon manifest.

## Credits

- Addon Author: Dromkal
- Based on Ace3 and LibDataBroker frameworks.
- Special thanks to the Synastria community and contributors.

## License

See individual library files for their respective licenses. The main addon code is provided as-is for community use.

---

For questions or contributions, please open an issue or submit a pull request!
