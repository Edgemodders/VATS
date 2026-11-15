# VATS: notes for Claude sessions

VATS (Visual Assisted Targeting System) is a drop-in REDnode mod for Cyberpunk 2077, game 2.5: body part targeting while scanning. Read [docs/design.md](docs/design.md) first. The research, spikes V1 to V13 and their in-game results, lives in REDnode's `docs/vats.md` (checked out at `../REDnode`), with the spike app `packages/overlay/apps/vats-spike` there.

## Decided with the owner

- VATS is its own mod. It depends on REDnode (and REDnode's own needs) only. Its quickhacks are made with EDGEhack, the quickhack editor, but nothing in VATS needs EDGEhack to run (2026-11-14).
- V's time is never changed (a free Sandevistan otherwise).
- Hit chances go in a VATS tab in the scanner's panel, after Data, not in callouts (2026-11-14).
- The part's outline should be green (the colour number is still to find; 2, 5 and 3 gave blue, white and red).

## Current status

- Spike V13 (the VATS tab): `scripts/VATS/Panel.reds` written and compile-checked; not yet run in the game.

## Working rules (as in every Edgemodders repo)

- Commit straight to `main` and push, in small logical commits; agree the plan in chat first.
- Git identity per repo: `CyberbuildsAI` with the GitHub no-reply email. Never change the global identity.
- Never commit game files or anything extracted from them, game scripts included: the decompiled game scripts used to write the wraps stay in a scratchpad.
- **redscript:** check every change with redscript-cli before it reaches the game, since one compile error stops every script in the game: `.\tools\check-scripts.ps1` (alone, and beside Codeware's scripts, counting errors in VATS's files only; this CLI version reports 24 errors in Codeware 1.21's own files, which the game's compiler accepts). redscript-cli is at `E:\Modding\Tools\redscript-cli` on the dev PC (REDnode's docs/dev-setup.md).
- Deploying writes into the game folder: ask the owner first, with the game closed (`.\tools\deploy.ps1`).
- Writing style: plain, short sentences; tables for facts; mark anything unverified as unverified.
- Scripts in this shell: write them with the Write tool, not heredocs (they eat backslashes), and never let PowerShell's `Set-Content` write a `.reds` file (its BOM is a syntax error at line 1).
