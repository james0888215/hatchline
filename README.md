# Hatchline

A solo PvE auto-battler. You hatch critters, **strictly triple-merge** them, and place them on a **3×3** meadow. Combat plays itself. One circuit: the Meadow.

Critters on the board, bench, shop, and combat grid are flat capsule tokens from the locked Hatch Art style. Starter, prep, and fight sit on a soft sage meadow wash. Wild mites read dusty mauve, and Driftkin stays powder blue. Meadow Circuit rules are unchanged. There is no full production atlas.

## Art

- [`art/style-lock/`](art/style-lock/) — locked reference: `STYLE_LOCK.md`, the mood board, Leaf / Ember / Puff silhouette sheets, and the combat mock.
- [`art/tokens/`](art/tokens/) — one capsule per family and tier (`leaf_t1.png` … `puff_t3.png`), cut from those sheets. `beast_t1.png` is the plain rose pill from the combat mock, used for meadow enemies that are not Leaf, Ember, or Puff.
- [`art/starters/`](art/starters/) — Sproutling, Sparkpup, and Cottonwisp only (soft-patched starters-v1). The board uses the 64px static sheet; tight lists use 32. Idle is the same 4 frames with a longer hold on the rest poses, then a 5-frame merge one-shot when that line triples. Every other species stays a capsule.
- Title — `art/style-lock/title-menu-v1/`. The logo is `wordmark-hatchline-trio-512.png`. Meadow texture B is the background, blended so the button band stays near cream. Paper texture A is `TITLE_TEXTURE_CHOICE`. Side-icon and type-only wordmarks stay in that folder as archive.

`tools/extract_tokens.py` recuts the tokens if the sheets change. Body, face, and the single family mark stay on the sheet; tier is size plus that one silhouette add.

## Open it

1. Install [Godot 4.x](https://godotengine.org/download) (developed against 4.7).
2. Open this folder as a project (`project.godot`).
3. Press F5.

Headless check, from this folder:

```bash
godot --headless --path . -s res://tests/logic_test.gd
```

`ALL PASS` means merge, buddies, shop, the circuit, a sparring win, a weak-board loss, role strikes, enemy aim, the boss summon, and the on-screen retry path all held.

## How to play

1. The title menu is Play, Hatch-dex, and Options. Play opens the three tier-1 starters; Back returns to the title. The line under them is the whole tutorial: three of a kind evolve, and same-family neighbours help.
2. **Sparring** is the teaching fight. Press Fight and watch the two boards. A melee critter lunges. A ranged critter spits a seed. The target gives a small pop, and the number floats on the cell. A kill still pops. Speed toggles between ×1 and ×2. During the fight the combat log stays folded until you open it. After the fight the full log stays on screen in a scroller. A starter in the right column wins. A ranged critter standing in Front, or a melee critter stuck in Back, can lose.
3. The **Meadow Stall** opens next. Buy, Freeze, Reroll, and sell. A copy of something you already own is in the first slot.
4. Two copies do nothing. They show **2/3**. The third copy evolves on the spot — the cell pops, and a one-line banner names the new tier.
5. Drag critters between the bench and the board. Drag onto the red Sell tag to sell. The board holds at most **7** critters.
6. Put matching families on orthogonal neighbours (not diagonals). A glow links them. The tile still shows the bonus: Leaf armour, Ember damage, Puff regen. The columns face the other board: Back, Mid, Front. Melee hits fully from Front and Mid, and half from Back. Ranged is the reverse. Melee pressures the front column. Ranged pressures the lowest HP. Enemy melee picks off a ranged critter standing in Front. Their melee stands in front. Their spitters stand in back.
7. Clear fights to earn coins. The path is Sparring → Stall → Wild Grass → a fork (shop or elite) → a picnic → Bramble → the last stall → the Meadow Matron.
8. The Matron calls Sprig adds twice. An Ember evolve splashes them.
9. A wipe ends the run. The defeat screen keeps one line for why you lost, then the full combat log in a scroller, then **Retry**. Dex ticks and the new egg-line stay.
10. Run 2 keeps the same three starters. **Budmite** joins the shop, marked NEW. Reserve Park and Season Trail stay greyed out.

Interest is paid when you enter a shop: 1 coin per 5 you are holding, capped. Saving is how you afford the next triple. Selling a pair gives less than it cost.

## Where the numbers live

All economy and buddy tuning is in [`data/economy.json`](data/economy.json):

| Constant | Role |
|---|---|
| `STARTING_COINS` | Coins at the start of a run |
| `BUY_T1` `BUY_T2` `BUY_T3` | Shop prices |
| `SELL_T1` `SELL_T2` `SELL_T3` | Sell refunds (a pair is a real loss) |
| `REROLL_COST` | First reroll in a shop |
| `REROLL_SCALE_EVERY` `REROLL_SCALE_STEP` | Reroll price steps up lightly, and resets each shop |
| `INTEREST_PER` `INTEREST_CAP` | Coins of savings per +1 interest, and the cap |
| `SHOP_SLOTS` `BENCH_SLOTS` | Shop width and bench size |
| `BOARD_W` `BOARD_H` | Grid size (3×3) |
| `BOARD_SOFT_CAP` | Max critters on the board (7) |
| `LEAF_BUDDY_ARMOR` | Armour per orthogonal Leaf neighbour |
| `EMBER_BUDDY_DAMAGE` | Damage per orthogonal Ember neighbour |
| `PUFF_BUDDY_REGEN` | Regen per orthogonal Puff neighbour |
| `EVENT_COIN_GIFT` | Picnic tip-jar payout |
| `COMBAT_MAX_ROUNDS` | Round limit before the clock decides |
| `ENEMY_X_OFFSET` | Gap between the two grids |
| `SPARRING_MELEE_HP` `SPARRING_MELEE_ATK` | Front mite in Sparring |
| `SPARRING_RANGED_HP` `SPARRING_RANGED_ATK` | Back spitter in Sparring |
| `WILD_MELEE_HP` `WILD_MELEE_ATK` | Barklings in Wild Grass |
| `WILD_RANGED_HP` `WILD_RANGED_ATK` | Pollen Wisp behind the bark line |
| `SHOP_ODDS` | Tier weights per shop visit (1 early, 2 mid, 3 pre-boss) |

Other tables:

- [`data/critters.json`](data/critters.json) — 24 critters, Leaf / Ember / Puff, tier 1 → 2 → 3
- [`data/circuit.json`](data/circuit.json) — Meadow node graph and coin rewards
- [`data/encounters.json`](data/encounters.json) — fights, including the Matron's add waves

Meta progress (dex, unlocked egg-line) is saved under Godot's `user://profile.json`.
