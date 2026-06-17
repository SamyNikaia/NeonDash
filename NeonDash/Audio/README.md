# Audio assets

Drop your files here. Accepted extensions: `.mp3`, `.m4a`, `.wav`, `.aac`.
Missing files are no-ops — the game stays silent for that slot.

## Music

| Filename            | Purpose                                              |
| ------------------- | ---------------------------------------------------- |
| `bgm_main_01`       | Main loop track 1 (random pick per run)              |
| `bgm_main_02`       | Main loop track 2                                    |
| `bgm_main_03`       | Main loop track 3                                    |
| `bgm_main_04`       | Main loop track 4                                    |
| `bgm_main_05`       | Main loop track 5                                    |
| `bgm_fire`          | On-Fire mode, crossfades in when combo ≥ 10          |

## SFX

| Filename            | Purpose                                              |
| ------------------- | ---------------------------------------------------- |
| `sfx_switch`        | Rail switch click                                    |
| `sfx_coin`          | Coin pickup chime                                    |
| `sfx_crash`         | Game over hit                                        |

After dropping files in this folder, regenerate the Xcode project so they
get added as bundle resources:

```sh
xcodegen generate
```
