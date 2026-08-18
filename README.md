# TortoiseGMManager

<p align="center">
  <img src="assets/logo.jpg" alt="TortoiseGMManager logo" width="100%">
</p>

A compact, Vanilla-native GM command manager for **Tortoise WoW 1.18.1 / client build 7272**.

TortoiseGMManager turns the server's dot-prefixed GM commands into a small searchable in-game interface. It is intended for local/private Tortoise WoW server administration and testing: teleporting, player/NPC management, items and spells, quests, gameobjects, lookups, moderation, server commands, and other common GM workflows.

The addon is **client-side only**. It does not connect directly to MariaDB and does not bypass server permissions. Commands are sent through the normal GM chat-command path; the world server remains authoritative for access level, syntax, and database state.

## Features

- Compact `590 x 435` command palette instead of a large admin dashboard.
- Draggable minimap launcher; **Shift-drag** moves it and the position is saved.
- `/tgmm` opens the manager.
- Quick, All, Travel, Player, World, Lookup, Admin, Danger and History categories.
- Search across labels, commands, argument hints and lookup metadata.
- Stock Vanilla WoW icons and textures inside the addon; no Ace or LibDBIcon dependency.
- Exact GM command is visible before execution.
- Current target is shown in the header.
- Detailed descriptions, access levels and argument help live in hover tooltips instead of filling the panel.
- `?` asks the server for `.help <command>`.
- Command history plus window/minimap positions persist in `TortoiseGMManagerDB`.
- Persistent/destructive operations require the exact same command to be RUN twice within five seconds.
- Esc closes addon windows through Vanilla `UISpecialFrames`.

## Database-aware lookup browser

Many GM commands require an ID even when you only know a name. TortoiseGMManager adds **FIND** to those workflows.

Example:

```text
Add item -> type: thunderfury -> FIND
```

The addon sends:

```text
.lookup item thunderfury
```

The server performs the lookup against its own loaded data. Matching `CHAT_MSG_SYSTEM` results are captured into a separate compact **Lookup Results** window with the result name, type and ID.

Clicking a result is deliberately safe: it **loads** the appropriate command into the command bar but does not execute it.

Examples:

```text
item       -> .additem <id>
spell      -> .cast <id>
quest      -> .quest status <id>
creature   -> .go creature id <id>
gameobject -> .go object id <id>
event      -> .event info <id>
itemset    -> .additemset <id>
```

When FIND is launched from a specific action such as **Quest add**, **NPC add**, **Delete item**, **Add item set**, **Cast**, or **Set skill**, the selected result is loaded back into that original action instead.

The parser listens to `CHAT_MSG_SYSTEM`; it does not monkey-patch chat-frame `AddMessage` methods and does not suppress the original server response.

## Command coverage

The catalogue is checked against the command registry in the Shyalya `playerbots-integration-gh` branch built by `TortoiseWoWServer` by default.

Current development coverage is **126 presets** with **21 FIND mappings**, including:

- GM mode, visibility, god mode, GPS, revive, replenish, repair, bank, mailbox and combat utilities.
- Saved teleports, player teleport/summon, coordinate movement, hover, waterwalk and taxi utilities.
- Items, item sets, spells, auras, cooldowns, skills, morph/demorph and level changes.
- NPC and gameobject lookup, spawn, movement, targeting and deletion workflows.
- Quest and event management.
- Item, spell, quest, creature, object, faction, skill, item-set, event and player/account lookups.
- Save/reload/server information and moderation commands.
- Shyalya commands such as `.learn all_myspells`, `.learn all_recipes`, `.learn all_trainer` and `.learn all_items`.

Commands not present in the current Shyalya registry are intentionally not advertised.

## Installation

### Downloading from GitHub

The addon files live at the repository root, so the downloaded folder **is** the addon folder.

1. Open the repository and choose **Code -> Download ZIP**.
2. Extract the downloaded archive.
3. Drag the extracted folder (e.g. `TortoiseGMManager-main`) straight into your client:

```text
<WoW>/Interface/AddOns/
```

WoW loads any folder that contains a `.toc` file, so the folder name does not need to match; you can keep `TortoiseGMManager-main` as-is or rename it to `TortoiseGMManager` if you prefer.

```text
<WoW>/Interface/AddOns/TortoiseGMManager/TortoiseGMManager.toc
```

4. Start or restart the WoW client.
5. On the character-selection screen, open **AddOns** and enable **TortoiseGMManager**.
6. If the client marks it as outdated, enable **Load out of date AddOns**. The manifest targets Vanilla interface `11200`.
7. Log into a GM character.
8. Click the gear icon next to the minimap, or run:

```text
/tgmm
```

### Minimap controls

```text
Click       open / close TortoiseGMManager
Shift-drag  move the minimap icon
```

The icon position and main-window position are saved automatically.

## Basic workflow

1. Select a player, NPC or object when the command is target-oriented.
2. Pick a category or use **All** and search.
3. **Run** executes commands that need no extra arguments.
4. **Use** loads a parameterized command into the command bar.
5. **FIND** resolves human-readable names through server-side lookup when available.
6. Click a lookup result to load its ID into the originating action.
7. Review the exact command and press **RUN**.

For server-specific syntax, hover the action or click `?` to request `.help` directly from the server.

## Safety model

Persistent/destructive operations are not one-click actions. Examples include server restart/shutdown, NPC/gameobject persistence changes, saved teleport changes, broad `learn all_*` operations, moderation actions, quest removal and `.die`.

For a dangerous command:

1. the first RUN arms the exact command;
2. the same command must be RUN again within five seconds;
3. editing the command clears the pending confirmation.

Explicit cancellation commands such as `.server restart cancel` remain immediate.

## Server alignment

The addon is currently aligned against:

- `tortoise-wow-stack/TortoiseWoWServer`
- `Shyalya/tortoise-wow` on `playerbots-integration-gh`
- the `Penqle/tortoise-wow` lineage
- `tortoise-wow-stack/TortoiseWoWKnowledgeBase`

Relevant server command definitions live primarily in:

```text
src/game/Chat/Chat.cpp
src/game/Commands/Commands.cpp
src/game/ObjectMgr.cpp
```

`tests/verify_server_catalog.py` reconstructs the nested server command table and verifies addon presets, FIND routes, and displayed access levels against the configured source.

## Project structure

The addon files live at the repository root:

```text
TortoiseGMManager.toc
Data.lua        command catalogue and danger policy
Core.lua        execution, history, help and confirmation logic
Lookup.lua      lookup lifecycle and CHAT_MSG_SYSTEM parser
UI.lua          compact main palette and minimap launcher
ResultsUI.lua   separate lookup-results browser

tests/
  core_spec.lua
  lookup_spec.lua
  verify_server_catalog.py
```

## Development checks

```bash
npx --yes --package fengari-node-cli fengari tests/core_spec.lua
npx --yes --package fengari-node-cli fengari tests/lookup_spec.lua
python3 tests/verify_server_catalog.py

npx --yes luaparse -q Data.lua
npx --yes luaparse -q Core.lua
npx --yes luaparse -q Lookup.lua
npx --yes luaparse -q UI.lua
npx --yes luaparse -q ResultsUI.lua
```

The addon is statically and behavior tested in development, but still needs its first full visual/integration pass inside the actual Tortoise WoW 1.18.1 client.
