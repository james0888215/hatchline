# Hatchline — Title Menu Background Shortlist

Quality bar refs (in this folder):
- `ref-stardew-title.png` — logo high, big calm sky + clouds, menu low, cream/wood UI
- `ref-terraria-title.png` — layered hills parallax, world reads as a place, menu in open sky pocket
- `ref-great-hatch-title.png` — cream/peach soft sky, meadow bottom, cosy creature-collector pastel

**Gen-assist: NOT needed.** Packs below clear the bar for a professional title composite.

Rejected (do not use for this cut): muddy watercolor washes (bart OGA meadow), dark night hills (Myaumya Green Hills), dark forest (edermunizz Pixel Art Forest), cold blue pine wilderness (OGA seamless HD landscape), muddy repeating mountain tiles (edermunizz Mountains), heavy brush hillside (heartpunch `hillside_day`), AI Flower Meadow (WineChan), unrelated roof textures (Kalponic). Raw leftovers remain under `_scratch/` only.

---

## Ranked shortlist

| Rank | Folder | Source | Licence | What matched | Center-light OK? | Notes |
| ---: | --- | --- | --- | --- | --- | --- |
| 1 | `01_vista-parallax-najjar320/` | [najjar320 VISTA](https://najjar320.itch.io/vista-parallax-backgrounds) | **CC0** | `downs` sky+clouds+3 hill layers; Terraria/Stardew structure | **YES** | Best layered pixel meadow. Scale 5× NN from 384×216. Pack is generated+curated (still a released CC0 pack). |
| 2 | `02_kenney-background-elements-remastered/` | [Kenney](https://kenney.nl/assets/background-elements-remastered) | **CC0** | Composable clouds/hills/ground + clean grass sample | **YES** | Best *builder kit* for custom composite under wordmark. |
| 3 | `03_craftpix-green-meadow/` | [OGA / CraftPix](https://opengameart.org/content/green-meadow-pixel-art-background) | **OGA-BY 3.0** (attrib) | Stardew-like meadow, clouds, trees, sparse flowers | **YES** | Strong pixel meadow hero; credit CraftPix. |
| 4 | `04_caspardal-grassy-meadow-parallax/` | [caspardal](https://harbingersolution.itch.io/grassy-meadow-parallax-background) | Commercial free; credit optional | 6 warm parallax layers; cream clouds | **MOSTLY** | Slide dark pines aside for button pocket. |
| 5 | `05_edermunizz-simple-pastel-backgrounds/` | [edermunizz](https://edermunizz.itch.io/free-simple-pastel-backgrounds) | Commercial; **MUST credit** | `Sky/skyDay01` cream-cloud sky | **YES** | Use **sky only**. Avoid Mountains tiles. |
| 6 | `06_heartpunch-hand-painted-nature/` | [heartpunch!](https://heartpunchstudio.itch.io/hand-painted-nature-backgrounds-pack) | **CC0** | `flowermeadow_day` cream-peach painted hero | **YES** | Best Great Hatch / cream-paper painted match. Flat (not parallax). |
| 7 | `07_fabinho-clouds-mountains-parallax/` | [OGA FabinhoSC](https://opengameart.org/content/background-clouds-and-mountains-parallax) | **CC0** | Cloud layer pieces | **YES** | Cloud accents; skip cold mountains or recolor. |
| 8 | `08_garzett-pixel-clouds/` | [GarzettDev](https://garzettdev.itch.io/pixel-clouds) | Commercial free | Classic flat-bottom pixel clouds | **YES** | Stardew/NES cloud language. |
| 9 | `09_sbs-seamless-sky-day-subset/` | [Screaming Brain / OGA](https://opengameart.org/content/seamless-sky-backgrounds) | **CC0** | Day blue Simple/Cloudy/Puffy skies | **YES** | Prefer Simple/Cloudy; watch grain on Fuzzy. |
| 10 | `10_untied-grasslands/` | [unTied Games](https://untiedgames.itch.io/free-grasslands-tileset) | Commercial; **attrib required** | Parallax `bg*.png` + wallpaper | **PARTIAL** | Terraria-punchier; recolor toward cream if used. |
| 11 | `11_voxelcorelab-watercolor-terrain/` | [Voxel Core Lab](https://voxelcorelab.itch.io/watercolor-terrain-textures) | **CC0** | Soft grass textures | N/A | Low-opacity near-grass wash only. |
| 12 | `12_cc0-paper-textures/` | [OGA plaggy](https://opengameart.org/content/cc0-pbr-paper-textures) | **CC0** | Paper albedo fiber | **YES** if subtle | Optional cream-paper overlay 8–15% soft-light. |

Each pack folder contains `ATTRIBUTION.md` and/or `LICENCE.txt` with exact URL + usage notes.

---

## Recommended #1 combo for Art (pixel / matches Stardew + Terraria refs)

**Goal:** 1280×800 title — logo high in calm sky; Play / Hatch-dex / Options low in open light pocket over near grass; soft parallax idle.

| Layer (back→front) | Asset | Path |
| --- | --- | --- |
| 0 Sky | Soft day blue | `05_…/use/Sky/skyDay01.png` **or** `01_…/downs/downs_0_sky@3x.png` |
| 1 Clouds | Soft pixel clouds | `08_garzett-pixel-clouds/cloud_pack.png` sprites **and/or** Kenney `02_…/Backgrounds/Elements/cloudLayer1.png` + `cloudLayer2.png` |
| 2 Far hills | Hazy distant hills | `01_…/downs/downs_1_far@3x.png` |
| 3 Mid hills | Sage rolling hills | `01_…/downs/downs_2_mid@3x.png` |
| 4 Near grass | Saturated near hills | `01_…/downs/downs_3_near@3x.png` |
| 5 Optional flowers | Sparse only | CraftPix meadow foreground accents from `03_…/layers/` (keep sparse) |
| 6 Optional paper | Cream fiber | `12_…/extracted/PaperAlbedo.png` @ ~10% soft-light |
| UI | Logo high / buttons low | Cream/wood plates à la Stardew ref — **not** from dark UI packs |

**Scale note:** VISTA base is 384×216 — use `@3x` (1152×648) or 5× nearest-neighbour to 1920×1080, then crop/fit to 1280×800. Point filter, no blur.

**Attrib if this stack ships:**  
- VISTA downs — CC0 (optional credit najjar320)  
- edermunizz sky — **required** credit if that sky is used  
- Garzett / Kenney — optional  
- CraftPix flowers — **OGA-BY** credit if used  
- Paper — CC0  

### Alternate A — single painted hero (Great Hatch cream cousins)
Use `06_heartpunch-hand-painted-nature/recommended/flowermeadow_day.png` full-bleed; logo in upper sky; buttons in light valley with cream plates; optional paper overlay. No parallax unless Art slices sky/hills manually. **CC0.**

### Alternate B — CraftPix meadow primary
Use `03_craftpix-green-meadow/layers/2304x1296.png` (+ layer splits). Strong Stardew pixel meadow. **Must credit CraftPix (OGA-BY 3.0).**

---

## Licence red flags
- **edermunizz** free packs: attribution **mandatory**; no redistributing source.
- **CraftPix via OGA**: treat as **OGA-BY 3.0** (attrib) even though CraftPix freebie page is soft on credit.
- **unTied Games**: attrib required; no asset-store redistribution; no AI training.
- **Do not buy** paid packs this cut (InKing meadows $4.90, CaptainSkolot pastel $2.49, etc.).
- **heartpunch** zip is ~124 MB — recommended day PNGs already extracted under `recommended/`.

## Gen-assist?
**No.** Shortlist supplies sky, layered hills, clouds, sparse flora, and paper fiber at commercial-safe licences. Prefer composing #1 stack over generating.
