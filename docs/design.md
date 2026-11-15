# VATS: design

The Visual Assisted Targeting System: body part targeting during combat. The research, with every spike's results, is on REDnode's [VATS page](https://edgemodders.github.io/REDnode/vats.html) (source `docs/vats.md` in the REDnode repo). This page keeps the design as the owner has set it, and what is decided.

## How it plays

| Step | What happens |
|---|---|
| Scanning | The game's scanner works as it does today |
| Enter VATS | While scanning, the right trigger (or the VATS key): the view frames the enemy so their whole body is large and centred, from V's own line of sight. Time slows far more than the scanner's own slow motion |
| In VATS | The player picks a body part with the crosshair; the part is outlined. Any enemy looked at during the same scan can be picked. The game's own quickhack wheel shows only VATS quickhacks, and the smart gun works too |
| Body part quickhacks | A VATS quickhack goes to one of six parts; each part can take one separately. They start only in VATS; an upload goes on after VATS ends and lands on its part |
| Cuts | For VATS quickhacks and VATS perks the cut comes **before** any damage: VATS decides it, not the game's damage-based dismember chance (the owner, 2026-11-14). VATS then sets off the game's own reactions: the `Dismembered<zone>` status effect, the crippled bark, hostility and V as the threat (spike V16); the pain hit reaction is still to find. Bullets can also cut through the game's own hit with V's `CanForceDismbember` stat (V14b) |
| Who decides a cut | VATS, always, from its quickhack code and perks (for example a power weapon shot on the left arm at 100 %, with a perk like "Dismember Shot" recalculating the cut to 100 %; the owner, 2026-11-14). **Shots:** VATS wraps the game's `HitReactionComponent.DismembermentConditions()`, the one check that decides whether a hit dismembers: for a VATS shot on its target and part it answers VATS's roll, and the game then carries out the hit as it always does (damage, the cut and its wound, the status effect, the bark, the pain reaction, combat). Every other hit gets the game's own answer. **Quickhacks** have no hit: VATS cuts and then sets off the game's reactions itself (spike V16). Spike V17 for the wrap |
| Leave VATS | Let go of the trigger, or of the scanner. VATS also has a timed duration |

V's own time is never changed: leaving V out of the slow motion would be a free Sandevistan.

## What shows

| Piece | Decided |
|---|---|
| The part under the crosshair | Outlined by the game itself (the meshes worn on that part, named by their prefix: head `h0_`, `heb_`, `hh_`, `h1_`; torso `t1_`, `t2_`; arms `g1_`, `a0_` by side; legs `l1_`, `s1_`), in a colour that stands out from the scanner's red; green is wanted |
| The lit part | Its name and hit chance as a line of the game's own UI under the scanned enemy's name above the crosshair (the quickhack list's `scanner_target_name`), in VATS's green (`scripts/VATS/PartLine.reds`, fed by `VATSPanelSystem.SetCurrentPart`). It replaces the floating overlay label, which the owner could not see in game; it shows while the quickhack list does |
| Hit chances | In a **VATS tab** in the scanner's panel: the six parts with their chances. Replaces the earlier idea of callouts beside the body. It is the third tab (Data, Hacking, VATS): the game's tab animations find the headers by place, so VATS cannot simply move its header after Data (V13's first run) |
| Sounds | `assets/sounds/vats-zoom.mp3` as the VATS zoom starts, `assets/sounds/vats-select.mp3` each time a body part lights (the owner's, 2026-11-14). REDnode's own audio plays them in real time, in the game's sound effects volume, so the slow motion does not slow them |
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

The panel (`scannerDetailsGameController`) shows Data, then either Hacking or TwinTone (the vehicle paint tab, never for an NPC). For an NPC, `scripts/VATS/Panel.reds` takes TwinTone's slot: the third header says VATS (Data, Hacking, VATS), and its body lists the parts with their chances from `VATS.VATSPanelSystem`, which VATS's Node mod sets through REDnode's `api`:

```js
const systems = await api.GameInstance.GetScriptableSystemsContainer(game.instance);
const panel = await systems.Get('VATS.VATSPanelSystem');
await panel.SetPart('Head', 80); // 0 to 100, or -1 for not known
```

Checked with redscript-cli against game 2.5's scripts, alone and beside Codeware (0 errors in VATS's file).

First run, 2026-11-14 (the owner's screenshots): the VATS tab showed, with the parts and their chances fed from the spike app. With its header moved after Data, the Hacking body opened under the VATS header and VATS's list under the Hacking header, and the bottom lines were off: the game's tab animations (`tab_hack_open`, `tab_twintone_open`) find the headers by place. The list also touched the panel's edges. Fixed the same day: the headers stay in the game's order, VATS last; the list has a margin and the chances in their own column. With the VATS tab open, the quickhack list and the cyberdeck's RAM disappeared (the owner, 2026-11-14): the game's `QuickhacksListGameController.IsPanelBlocked()` hides them whenever the open tab is TwinTone, the car paint tab. VATS now wraps it to answer no while the third tab is VATS's.

To put VATS second after all, the bodies would have to swap instead (VATS's list in the Hacking slot, the quickhack description moved into the third), which touches the game's quickhack panel (not tried).
