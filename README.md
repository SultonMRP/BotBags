# BotBags

Standalone WotLK **3.3.5a** bag window for **player bots**. It is **not** UnBot and it does **not** replace a bot controller.

Use this on private servers that run **[mod-playerbots](https://github.com/mod-playerbots/mod-playerbots)** (or a similar playerbot module) **and** already have their own bot-control addon. BotBags only lists a bot’s bags and lets you click items (equip, destroy, sell, use, guild bank, trade).

## What it is / is not

| This addon | Not this addon |
| --- | --- |
| Bag window + `/botbag` | Command bar, strategies, online list, inspect gearing |
| Works next to *your* bot controller | A fork of UnBot |
| Whispers normal playerbot item commands (`c`, `e`, `s`, …) | Server GM commands |

UnBot’s bag UI was the starting point. The code here is a standalone AddOn (`BotBags`). You do not need UnBot installed.

## Install

1. Copy the `BotBags` folder to `Interface\AddOns\BotBags`.
2. Folder name must match the TOC: `BotBags`.
3. Enable **BotBags** at character select.
4. `/reload`.

## Use

- Target a **party/raid player bot** and type `/botbag`.
- Or right-click that bot’s party/raid portrait → **Bot Bag** (hidden on your own portrait).

The window whispers `c` to the bot and fills from whisper item links.

**Modes:** View, Equip, Destroy, Sell, Use, Gbank, Trade.

- Equip / Destroy / Sell / Use / Gbank whisper the usual playerbot prefixes plus the item link (`e`, `destroy`, `s`, `u`, `gb`).
- **Trade** runs the client `/trade` command with that bot, then whispers the item link once the trade window is open. Closing the trade window refreshes the bag.
- **?** queries unknown items. **S** hides soulbound rows on the next refresh.

Sell still expects you to have a merchant targeted.

## Requirements

- Client: WoW 3.3.5a (`## Interface: 30300`)
- Server: playerbots that answer whisper `c` with item links
- Bot must be in your party or raid

Your existing bot controller addon stays as-is. BotBags does not depend on it.
