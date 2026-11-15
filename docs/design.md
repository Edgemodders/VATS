# VATS: design

The Visual Assisted Targeting System: body part targeting during combat. The research, with every spike's results, is on REDnode's [VATS page](https://edgemodders.github.io/REDnode/vats.html) (source `docs/vats.md` in the REDnode repo). This page keeps the design as the owner has set it, and what is decided.

## How it plays

| Step | What happens |
|---|---|
| Scanning | The game's scanner works as it does today |
| Enter VATS | While scanning, the right trigger (or the VATS key): the view frames the enemy so their whole body is large and centred, from V's own line of sight. Time slows far more than the scanner's own slow motion |
| In VATS | The player picks a body part with the crosshair; the part is outlined. Any enemy looked at during the same scan can be picked. The game's own quickhack wheel shows only VATS quickhacks, and the smart gun works too |
| Body part quickhacks | A VATS quickhack goes to one of six parts; each part can take one separately. They start only in VATS; an upload goes on after VATS ends and lands on its part |
| Leave VATS | Let go of the trigger, or of the scanner. VATS also has a timed duration |

V's own time is never changed: leaving V out of the slow motion would be a free Sandevistan.

## What shows

| Piece | Decided |
|---|---|
| The part under the crosshair | Outlined by the game itself (the meshes worn on that part, named by their prefix: head `h0_`, `heb_`, `hh_`, `h1_`; torso `t1_`, `t2_`; arms `g1_`, `a0_` by side; legs `l1_`, `s1_`), in a colour that stands out from the scanner's red; green is wanted |
| Hit chances | In a **VATS tab** in the scanner's panel, after Data: the six parts with their chances. Replaces the earlier idea of callouts beside the body |
| The upload icon | On the part's slot, not above the head (the game's own bar if it follows the event's `slotName`, else a REDnode pin) |

## The parts

| Part | Hit shapes (`npc_base.hitrepresentation`) |
|---|---|
| Head | Head |
| Torso | Chest, LeftTorso, RightShoulder, Belly |
| Left arm | LeftArm, LeftForeArm |
| Right arm | RightArm, RightForeArm |
| Left leg | LeftUpLeg, LeftLeg, LeftFoot |
| Right leg | RightUpLeg, RightLeg, RightFoot |

## What is known (from the spikes, 2026-11-14)

| Question | Answer |
|---|---|
| Where each part is | The NPC's hit representation slot component: `GetSlotTransform(slot)`, native |
| Which part the crosshair is on | The game says only "the hit representation"; VATS casts a ray along the camera against the 15 shapes |
| Outline one part | `entRenderHighlightEvent` with a `componentName`, one mesh at a time, visible without the scanner |
| Frame the enemy | Turn the first-person camera's local orientation and zoom; it holds, and aim follows. Zoom by the camera's zoom override, eased on real time (`SetFOV` eases on world time and crawls under the scanner) |
| Slow motion | VATS's own dilation reason holds over the scanner's 0.03 |
| One part hit | Switching the other hit shapes off makes only the chosen part take hits |
| The trigger | REDnode 0.65.1 reads the controller: Xbox pads through XInput, Sony pads from their own reports |

## Spike V13: the VATS tab

The panel (`scannerDetailsGameController`) shows Data, then either Hacking or TwinTone (the vehicle paint tab, never for an NPC). For an NPC, `scripts/VATS/Panel.reds` takes TwinTone's slot: the header says VATS and moves after Data (Data, VATS, Hacking), and its body lists the parts with their chances from `VATS.VATSPanelSystem`, which VATS's Node mod sets through REDnode's `api`:

```js
const systems = await api.GameInstance.GetScriptableSystemsContainer(game.instance);
const panel = await systems.Get('VATS.VATSPanelSystem');
await panel.SetPart('Head', 80); // 0 to 100, or -1 for not known
```

Checked with redscript-cli against game 2.5's scripts, alone and beside Codeware (0 errors in VATS's file). Not yet run in the game.
