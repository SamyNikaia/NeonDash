# Audio assets

Drop your files here. Accepted extensions: `.mp3`, `.m4a`, `.wav`, `.aac`.
Missing files are no-ops — the game stays silent for that slot.

## Music (looped infinitely)

| Filename     | Purpose                                              |
| ------------ | ---------------------------------------------------- |
| `bgm_main`   | Main loop, plays while you're alive                  |
| `bgm_fire`   | On-Fire mode, crossfades in when combo ≥ 10          |

Pick tracks that loop cleanly (or accept the seam — `numberOfLoops = -1`
just replays from the top).

## SFX

| Filename     | Purpose                                              |
| ------------ | ---------------------------------------------------- |
| `sfx_switch` | Rail switch click                                    |
| `sfx_coin`   | Coin / heart pickup chime                            |
| `sfx_crash`  | Hit (both partial damage and death)                  |

After dropping files in this folder, regenerate the Xcode project so
they get added as bundle resources:

```sh
xcodegen generate
```
