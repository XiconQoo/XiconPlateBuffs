# XiconPlateBuffs TBC Addon

v1.2-Beta

XiconPlateBuffs's goal is to accurately show CC in Arena/BG on any nameplate, without the need to hover/target/interact with the nameplate or the nameplate even beeing visible when CC was applied.

This is inferior to PlateBuffer in PvE. PvE is not the main aim for this addon.

## Screenshot

![Screenshot](../readme-media/sample.png)

### Changes

v1.3-Beta
- fix register UNIT_DIED event to clear icons

v1.2-Beta
- add support with updated Icicle (https://github.com/XiconQoo/Icicle)
- fix icons reappearing
- cleaner script hooks for OnHide

v1.1-Beta
- add SoHighPlates support
- fix icons not rearranging
- add interface configuration in blizz addons menu (type /xpb or /xpbconfig in chat)
    - size
    - fontsize
    - alpha
    - positioning (x-y offsets)
    - responsiveness toggle
    - sorting
    - test mode
    - default options button


v1.0-Beta

- first dummy working showing CC on nameplates

### TODO

- edit debuff list in config
- add categories
- add icon sizing by debuff/category
- add non cc debuffs
- add important buffs like bubble, innervate etc
- reuse icon frames on nameplates for less memory usage