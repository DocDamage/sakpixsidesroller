"""Rebuild short, normalized enemy cues from the user's local SFX kit."""
from pathlib import Path
import json
import subprocess

ROOT = Path(__file__).resolve().parents[1]
SOURCE = ROOT / "SFX/One_Shots"
DEST = ROOT / "assets/audio/enemies"
# event: source patterns, length, playback pitch baked into the derived cue.
CUES = {
    "guard_swing": (["Weapon/*heavy_sword_swing_1*.wav", "Weapon/*heavy_sword_swing_2*.wav"], .45, 1.0),
    "witch_fire": (["Electricity/*shock_1*.wav", "Electricity/*shock_2*.wav"], .45, .85),
    "eye_fire": (["Fire/*steam_element_1*.wav", "Fire/*steam_element_2*.wav"], .4, .8),
    "mosquito_dive": (["Weapon/*wood_stick_swing_1*.wav", "Weapon/*wood_stick_swing_2*.wav"], .3, 1.25),
    "armor_ready": (["Chains/*metal_tiny_short.wav", "Chains/*metal_smaller_short.wav"], .35, 1.0),
    "beast_ready": (["Creature/*attacker_1_quick*.wav", "Creature/*attacker_2_quick*.wav"], .4, 1.25),
    "warden_swing": (["Weapon/*giant_quick_swing_1*.wav", "Weapon/*giant_quick_swing_2*.wav"], .55, .9),
    "rat_lunge": (["Creature/*cat_noise_1*.wav", "Creature/*cat_noise_2*.wav"], .35, 1.45),
    "bat_dive": (["Creature/*chatter_1_bird*.wav", "Creature/*chatter_2_bird*.wav"], .4, 1.2),
    "mimic_snap": (["Creature/*beast_1_quick*.wav", "Creature/*beast_2_quick*.wav"], .5, 1.0),
    "mushroom_rush": (["Gore/*fight_short_blood_wet.wav", "Gore/*fight_short_blood_wet_02.wav"], .4, .8),
    "spit": (["Fire/*steam_element_1*.wav", "Fire/*steam_element_2*.wav"], .35, 1.3),
    "spell_impact": (["Fire/*short_steam_1*.wav", "Fire/*short_steam_2*.wav"], .4, 1.1),
    "enemy_contact": (["Fight/*fight_hit_enemy_1_hit*.wav", "Gore/*hit_fight_short_hard.wav"], .4, 1.0),
}

def main():
    DEST.mkdir(parents=True, exist_ok=True)
    manifest = {}
    for event, (patterns, duration, pitch) in CUES.items():
        manifest[event] = []
        for index, pattern in enumerate(patterns):
            matches = sorted(SOURCE.glob(pattern))
            assert len(matches) == 1, (pattern, matches)
            source = matches[0]
            output = DEST / f"{event}_{index}.wav"
            filters = (
                "silenceremove=start_periods=1:start_threshold=-48dB:start_duration=0.005,"
                f"aresample=44100,asetrate=44100*{pitch},aresample=44100,"
                f"atrim=duration={duration},loudnorm=I=-20:TP=-2:LRA=7,"
                f"afade=t=out:st={duration-.08}:d=0.08"
            )
            subprocess.run(["ffmpeg", "-v", "error", "-y", "-i", str(source),
                            "-af", filters, "-ac", "1", "-ar", "44100", "-c:a", "pcm_s16le", str(output)], check=True)
            manifest[event].append({"path": "res://" + output.relative_to(ROOT).as_posix(),
                                    "source": source.relative_to(ROOT).as_posix(), "duration": duration})
    (DEST / "sources.json").write_text(json.dumps(manifest, indent=2) + "\n", encoding="utf-8")
    print(f"Built {sum(map(len, manifest.values()))} enemy cues from local SFX sources")

if __name__ == "__main__":
    main()
