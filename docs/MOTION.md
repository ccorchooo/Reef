# Motion

Reef follows the **M3 Expressive motion scheme**: springs instead of fixed-duration easing, split into **spatial** motion (position, size, shape, corner radius) and **effects** motion (opacity, color, blur, font axes). Each has three speeds.

## Springs

These are M3 Expressive's spring tokens. Spatial springs bounce; effects springs never do (damping 1), so colors and opacity never overshoot.

| Token | Stiffness | Damping | Use in Reef |
| --- | --- | --- | --- |
| `spatial-fast` | 800 | 0.6 | Toggle thumb, pressed-button squash, cay hover grow, wrong-password shake |
| `spatial-default` | 380 | 0.8 | The Island expanding and collapsing, Tide panels sliding in, search popping up from the Navigator cay |
| `spatial-slow` | 200 | 0.8 | Island to Pearl morph (power actions, voice), workspace overview zoom, bar moving to the left in edit mode |
| `spatial-bouncy` | 320 | 0.42 | Reef's own, beyond M3E: playful hops. The Pearl dropping into the lock screen and hopping, password shapes landing |
| `effects-fast` | 3800 | 1 | Icon FILL, label weight on press, hover tint |
| `effects-default` | 1600 | 1 | Fades of panel content, color changes when a toggle turns on |
| `effects-slow` | 800 | 1 | Wallpaper-scheme crossfade, scrim in and out |

Damping here is the M3 damping ratio: 1 means no bounce, lower means more bounce.

### Implementing in Quickshell / QML
QML's built-in `SpringAnimation` uses different parameters, so pick one of two routes:

1. **A small spring helper** (recommended): one `QtObject` per animated value that integrates `x'' = -k(x - target) - c·x'` per frame (`FrameAnimation`), with `c = 2·ζ·√k` (mass 1). This gives the exact M3E feel and handles interruption naturally: a new target keeps the current velocity.
2. **Bezier approximations** with `Easing.BezierSpline`. Fine for simple cases, but they can't carry velocity across interruptions. Starting curves (tune by eye against the springs):

| Token | Duration | Curve |
| --- | --- | --- |
| `spatial-fast` | 350 ms | `0.42, 1.67, 0.21, 0.90` |
| `spatial-default` | 500 ms | `0.38, 1.21, 0.22, 1.00` |
| `spatial-slow` | 650 ms | `0.39, 1.29, 0.35, 0.98` |
| `effects-fast` | 150 ms | `0.31, 0.94, 0.34, 1.00` |
| `effects-default` | 200 ms | `0.34, 0.80, 0.34, 1.00` |
| `effects-slow` | 300 ms | `0.34, 0.88, 0.34, 1.00` |

The values in both tables live in `design/tokens.json` → `motion` (with the stagger step, content-fade delay and reduced-motion fade) and reach code only through the `Motion` singleton, multiplied by the **Animation speed** setting. Reef uses route 1: `components/Spring.qml` for numbers and `components/ColorSpring.qml` for colors; `components/MotionAnimation.qml` wraps the bezier fallback for simple `Behavior`s.

## Choreography rules

- **Shape follows content.** The Island never fades out and in to change mode: it morphs its width, height and corners with `spatial-default` while the old content fades out (`effects-fast`) and the new content fades in with a 50 ms delay.
- **Things come from where they live.** Search grows out of the Navigator cay, Tide panels slide in from their edge, the power menu replaces the Navigator cay's contents in place, and dropped files fly into the Shelf.
- **Stagger lists** by 20 ms per item, capped at 8 items.
- **Interruptible always.** Any animation can be retargeted mid-flight without a jump.
- **One hero per moment.** When the Island morphs into the Pearl, nothing else moves.

## Signature moments

| Moment | Motion |
| --- | --- |
| **Island → Pearl** (lock) | The resting Island drops from the top center, rounding into the Pearl's shape as it grows to `pearl-lock-size` on `spatial-bouncy`: it overshoots and bounces back, stretched along the fall and squashed as it lands (`pearl-squash`). The content inside fades in once it's nearly there. |
| **Pearl alive** | Hops `pearl-hop` on the minute and when its activity changes; swells `pearl-pulse` per typed character; rocks `pearl-wobble` on a wrong password. All `spatial-bouncy` kicks, none with Reduce motion. |
| **Password shapes** | Each new shape pops up from below, spins in from `password-spin` and blooms from a circle into its shape (`spatial-bouncy`); its neighbours hop `password-hop`, less with distance, staggered. |
| **Island hover reveal** (app open) | The Island hides up behind the top edge. A pointer at the top center for 150 ms drops it back down with `spatial-default` over the app, with `shadow-island`. It does not reserve space. |
| **Power menu** (Ctrl+Alt+Delete) | Navigator cay icons scale to 0 with `effects-fast`. The cay re-forms to fit the power actions (`spatial-default`), and the new icons pop in staggered. A `scrim` fades in behind. The Island becomes the Pearl: it leaves the top center as the pill and drops into the Pearl's place on `spatial-bouncy`, rounding into its shape; closing folds it back into the Island (`spatial-default`), which then shows again. |
| **Power → Lock** | Locking (or sleeping) from the power actions hands the Pearl to the lock screen: it carries on from where it is, keeping its shape and content, and lands at the lock screen's center on `spatial-bouncy`. Unlocking folds it into the Island. |
| **Coral speaking** | The Pearl's outline is a shape driven by the audio: amplitude scales a set of radial waves (like a music-video audio orb), and the base shape morphs between cookie shapes on beats. `island-accent` glows at the peaks. When the reply finishes, the Pearl morphs into the chat card (`spatial-default`). |
| **Wrong password** | All typed shapes morph back to circles, then shake horizontally ±8px with `spatial-fast`, and the field tints `error-container` for 600 ms. |
| **Toggle on** | Squircle to pill (`spatial-fast`), fill to `primary-container` (`effects-default`), icon FILL 0→1 (`effects-fast`, as a crossfade from the outlined glyph to the filled one). |
| **Button groups** (press) | The pressed button widens by `press-grow` and the others in its row give up that width between them, all with `spatial-fast` (a small overshoot); its corners squash toward `radius-md`. On release everything springs back and the button morphs to its new on/off shape. Off with Reduce motion. |
| **Status cay → quick menu** | The cay's width, height and corners spring to the menu's card (`spatial-default`) from its bottom edge; the items slide to their new places with the same spring; the menu fades in (`effects-default`) and crossfades when switching. |

## Reduce motion

When **Reduce motion** is on:
- Spatial springs become 150 ms crossfades with no overshoot. Nothing moves across the screen. (`Spring` snaps spatial values; the component crossfades. Effects springs still run.)
- Shape morphs become instant swaps under a crossfade.
- Coral's wave pulse becomes a gentle opacity breathe.
- Loading indicators keep animating (they communicate progress), but slower.
