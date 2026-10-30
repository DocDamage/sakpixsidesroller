WITCHING HOUR - TWELVE STAGES FROM HAUNTED TOWN TO STARFALL

CURRENT FIXTURE / COMBAT PASS (2026-10-30)
Stage 1 climbs use clean 48px ladder rails instead of scaffold icons. House
furnishings sit on their actual floors; interior windows use bare leaded panes.
The hearth excludes the unrelated textile from its extracted source. Animated
campfires use a side-on log bed, and light/glow/smoke follow the flame emitter.
Mounted torches have backing; open streets and balconies use grounded posts.
The village and legacy town also replace outdoor candelabras with lantern posts.
Ferr2D's path/edge/fill approach now informs native Godot terrain: fourteen Stage 1
foundations share their contour between visible fill, collision and shadows.
Enemy damage, swishes and following trails match the weapon sweep cells. Ranged
release follows anticipation; interrupted swings lose their trails. Anticipation
and recovery cannot cause body-contact damage. Twenty-eight derived attack SFX
variations use local kit sources. GitHub contains code/text manifests only.
The district still needs the larger room-design work described in the audit.

LEVEL DESIGN REVIEW (2026-10-30)
The user's Silksong reference has a chronological visual study retained locally.
Read DESIGN_REFERENCE.txt and STAGE1_DESIGN_AUDIT.txt before further layout work.
They document the review method, timestamped examples and concrete shortcomings
in the Stage 1 composition. The court-to-belfry loop now has an initial playable
redesign: offset apothecary stairs, roof crossing, an enclosed switchback tower,
window lighting, and a callable bell cage unlocked at the reward gallery.
The cistern, long return gallery and remaining stages still need design work.

The opening houses and apothecary now use the matching House Inside/Outside kit
from GandalfHardcore Pixel Art Medieval Fantasy Assets, at three world pixels
per source pixel. Roofs, cornices, plaster, foundations, doors and interior floors
form complete buildings. Entering the apothecary fades its facade to reveal the
playable rooms; its structural edges stay visible. The hearth now contains the
fire, and rain shelter follows the actual roof silhouettes. Earlier enlarged
Halloween house icons are retained only in distant scenery in this opening block.

PLAY
Double-click Play.cmd, or open project.godot in the included Godot 4.7.2 and press F5.
Main scene: scenes/halloween_town.tscn. Each completion screen continues to the next
stage; the twelfth stage ends the journey. Play Level 2.cmd through Play Level 12.cmd
open those stages directly for review. The four new launchers are:
  Play Level 9.cmd - Rootbound Catacombs (Dungeon)
  Play Level 10.cmd - The Prism Vault (Dungeon)
  Play Level 11.cmd - Lumenwood Trail (Magic Forest)
  Play Level 12.cmd - Starfall Glade (Magic Forest)

STAGE 1 - HAUNTED DISTRICT REFERENCE BUILD
Play.cmd now opens the redesigned Stage 1. The remaining eleven stages keep their
existing layouts while this first district establishes the campaign direction.
The first-clear target is 10-20 minutes; that target still needs first-time human
playtesting. The optimized input-only route audit takes about four simulated
minutes with other encounters disabled, so it is not a measured first-clear time.

The district spans 19,200 pixels and 26 authored spaces: a town hub, apothecary
loft, bell gantries, graveyard, prison, pump house, drowned gallery, watchhouse,
chimney vault, aqueduct, floodgarden, undercroft, chapel and village approach.
Three objective branches return to the quarter's ritual. Open the prison trapdoor,
restore the ritual, then use the lantern tram for the return trip to the chapel.
The prison jailer is optional: the upper passage bypasses his arena. Defeating him
opens a moon-hook cache. Other caches improve character light and combo finishers.
There are eight sanctuaries, 40 enemies, 55 supporting surfaces and 118 coins.

Climb the first apothecary ladder to the intermediate floor, move right to the
second ladder, then cross the loft and jump onto the eaves. The tower ascent uses
offset stone ledges. Release the winch beside the belfry seal, then return to the
bell cage between the upper galleries. Use its lever to ride down to the street
and return left to the court. The cage can be called from either landing and
stays docked until used. The compact exploration HUD leaves more room to see the
route; the journal, controls and full results screen remain available.

After the Gravekeeper falls, the marked stair just beyond the Moon Key opens.
Hold Down at the arch to descend to the chapel undercroft; follow it left to the
tram station. This physical route works even if the pump and prison switches
were missed: victory releases the return gates and drains the tram channel.
Call the tram, jump aboard, then use its control to depart. Calling a docked
tram from below no longer sends it away without its passenger. The tram returns
to the quarter via the prison trapdoor. The new chapel stair works both ways.
The results journal also has KEEP EXPLORING; Escape / controller B resumes the
same cleared stage. The boss, key, equipment, coins and opened routes stay kept.
Return to the dawn portal when ready to continue; the results are recorded again.

Bell, ossuary, service and chapel climbs now include supported dismount landings.
Structural crop checks ensure that support beams contain visible source pixels;
a displaced cottage was moved clear of the new stair entrance.

Controls: Space / A jumps and dismounts; W/S or stick/D-pad Up/Down climbs and swims.
Jump provides an upward swimming stroke. Jump against a wall performs a wall kick.
Up + Use activates an earned moon hook near a visible anchor. Tab / LB opens the
pausing district map. If LB is rebound, Down + Use opens it away from interactions.
The map tracks visited rooms, lanterns, seals, gates, the ritual and tram route.
Four lifts, moving ferries, sixteen ladders/ropes and five hooks connect the tiers.
The sluice changes the real water level and current; shallow banks support wading,
deep channels support swimming, and submerged pickups reward exploration.

Water now reflects/refracts the scene, animates several wave bands, flow, foam,
caustics and overlapping entry/exit and movement wakes, and clips to the actual bed under shallow
banks. Local source lights and structural shadow occluders illuminate the district
against a dark ambient base; the character carries a small light. Lighting remains
for depth and mood, with subtle source flicker. The source SFX kit adds 64 bounded
variations across 32 events,
including material footsteps, climbing, water, gates, winches, relics, UI and layered
combat and cistern drips. Positional effects pan toward their source; stone occludes
them and submerged listeners hear filtered SFX. Map feedback remains clear and the
Haunted Manor score stays on separate music buses. Armor and clean flesh hits use
distinct contact layers, with a stronger pause on finishing blows. Originals are
intact; assets/audio/district/sources.json records every source.

Current Stage 1 checks: district_checks.gd (22), district_combat_checks.gd (7),
district_polish_checks.gd (10), district_return_checks.gd (normal-damage boss fight
and physical post-clear return; add -- --keyboard for native keyboard input),
district_render_checks.gd (6 GPU), district_journey.gd (full controller route;
add -- --keyboard for native keyboard input), and guardian_balance.gd with
-- --controller --stage=1 (normal damage). Shared rebuild/placement/scenery/weather/
music suites also cover the current district. Positional legacy combat/controller
fixtures use -- --classic-expanded; -- --original-layout retains the compact reference.
The original expanded Stage 1 is available only through the explicit test switch.
Review: artifacts/district-preview.mp4 includes live gameplay audio;
district_visuals.gd captures the authored spaces, drained gallery and map.
artifacts/district-return-preview.mp4 shows a continuous native-input journey from
the cleared chapel through the new stair and undercroft onto the returning tram.
district_revision_visuals.gd captures the return route, supported landings and UI.

SOUNDTRACK
All twelve stages and the ending use only The Haunted Manor - Creepy Horror
Soundtrack Pack. Exploration cues follow the area's mood; the final ending uses
The Morning After. Approaches crossfade into the next stage's exact opening song,
then Continue preserves its playback position. Pausing ducks the music by 5 dB,
mute covers both streams, and small measured per-track gains keep levels consistent.
The original MP3 files are unchanged. tests/music_checks.gd verifies all twelve
stages, all eleven handoffs, looping, pause/mute/unmute and the ending (96 checks).

WEATHER
All twelve expanded stages have local weather profiles with continuous border
transitions: drizzle and mist around the town/village, stronger rain and wind
at the keep/ramparts, damp forest air and a gradual clearing toward Starfall.
Three shader passes add layered wind-slanted rain, slow cloud cover and low mist.
A 2,048-column world map clips precipitation at terrain, ledges and lower-route
ceilings. Catacombs stay dry; the Prism Vault exposes its roof and forest-facing
exit, and the cathedral protects its nave while leaving its open crossings exposed.
Small rain impacts follow the same exposed surfaces. Wet terrain keeps its source
silhouette and gains modest darkening/highlights; water has fine rain/wind ripples.
Foliage responds to shared gusts. Strong storm areas occasionally receive one soft
distant-light pulse, with at least 48 seconds between strikes. Weather clocks,
glints, gusts and storm scheduling freeze with pause. All weather draws below the
HUD and ignores input. Dawn clears the opening/final weather gradually.

tests/weather_checks.gd: 123 default-build shelter, climate, pause and camera checks.
tests/weather_render_checks.gd: 9 GPU checks; omit --headless and use GL Compatibility.
tests/weather_visuals.gd: exposed/sheltered views of all stages and 48 motion frames.
artifacts/weather-review-1-6.png and weather-review-7-12.png show the visual audit;
artifacts/weather-preview.gif shows the moving storm. Source shader files are in
scripts/weather_*.gdshader and wet_terrain.gdshader, controlled by stage_weather.gd.
The supplied Water Kit adaptation adds fine ripples; original pack sources remain intact.

CURRENT BUILD - LONGER, VERTICAL ROUTES AND SWORD ALIGNMENT
Stages 2-12 retain their expanded layouts. Each retains its opening and final
approach, with 6,400 additional pixels of upper/lower traversal before the guardian.
The new crossings climb 640-800 pixels above the original road and descend 640-800 pixels
below it. Rooftops, cisterns, root passages, crypt runs and canopy routes use their
stage pack's terrain, with supported high crossings and enclosed lower passages.
The last objective is on the new route. Two extra lanterns, two healing supplies,
two upright camps and six encounters support the longer journey. Camera framing
moves vertically and reveals the next lower landing before a drop. Above/below
compass cues help locate elevated objectives. Stage progress and checkpoint UI use
the longer width and all five lanterns. The final reward and exit are at x11920
and x12590 respectively.

The Seeker pack's Animation_Guide.txt supplies each animation's feet pivot. These
now anchor Idle, Run, Jump, Hurt, Dash and all sword frames in both directions,
including the very different 90x50 and 200x50 attack canvases. A stationary sword
swing leaves the physics body fixed. Supplied blade contact frames control damage
and the swing sound. The blade checks contact throughout its active window, with
one damage event per enemy per swing. Hitboxes follow forward blade reach and enemy
body height. Recovery can chain the next combo, while the pack's separate FX-only
sheets finish the outgoing slash without leaving a duplicate character behind.
The old procedural arc has been removed because the supplied attack art includes it.

The old top-down campfire-ring sheet is no longer used for world camps. Complete
upright side-view campfires from Medieval Kingdom stay at a fixed scale and ground
contact, with color flicker and rising embers. Crowded village/graveyard fires were
moved away from urns, checkpoint lanterns and crop details.

SCENERY COMPOSITION
Background buildings and trees share a ground plane and continuous earth backing.
The dungeon wall extends above/below the camera; carved reliefs fade with their
supporting masonry. Woodland climbs use rooted trunk sections and branch platforms
instead of the same stone tower used in the town. Other elevated routes have stone
supports, and the opening platforms have posts/columns extending into the ground.
Underground forest fill crops opaque soil, avoiding transparent borders and grassy
tile grids. Loose farm/hand props and unattached hanging props have been removed;
small foreground decoration leaves ground encounters, camps and interactions clear.
Market stalls, buildings, lights and major landmarks remain as the scene's set pieces.
The village, market and castle walkways use filled slabs without transparent side gaps.

CURRENT BUILD VALIDATION
Use the included Godot console with --headless --path . --fixed-fps 60 and --script:
  tests/rebuild_checks.gd                 127 checks
  tests/placement_checks.gd                49 checks
  tests/combat_checks.gd                   26 checks
  tests/controller_checks.gd               44 checks
  tests/awareness_feedback_checks.gd      131 checks
The rebuild and placement suites run against the current default campaign. They
check authored extents, endpoints, sanctuary counts, enemy support, camera framing,
upright fires and hero pivots. The shared positional combat/controller/awareness
fixtures use -- --classic-expanded for their prior Stage 1 coordinates; the district
suites above exercise the new traversal, encounters and controller interactions.
tests/scenery_checks.gd adds 66 checks for background grounding, continuous backing,
supported opening platforms, hidden clutter, opaque soil and attached wall reliefs.

  tests/extended_journey.gd
Use -- --classic-expanded to traverse the previous expanded Stage 1 fixture. This
driver traverses the expanded stages with native controller events, including
both vertical rooms, all objectives, guardians, rewards and exits. Add
-- --keyboard for the keyboard route, or -- --stage=9 for a single-stage review.
Route tests disable contact damage to isolate traversal; no teleports are used.
All twelve normal-damage guardian fights also pass using tests/guardian_balance.gd
with -- --controller --stage=1 through --stage=12.

Rendered review: tests/rebuild_visuals.gd (omit --headless) captures nine views of each
stage, including starts, middles, handoffs, camps, vertical rooms and exits, plus all
23 ground sword frames. The window renderer adds two GPU checks. These captures
and logs are in artifacts/; the current route overview is expanded-review-1-6.png
and expanded-review-7-12.png. The main road compositions are in composition-road-1-6.png
and composition-road-7-12.png. Use -- --stage=3 to render only one stage.
Physical controller mapping/feel/rumble still needs
hands-on hardware testing.

THE JOURNEY
The campaign has 160,000 pixels of authored extent: a 19,200-pixel Stage 1 and
eleven 12,800-pixel stages. Stage 1 has 25 connected spaces; the remaining stages
have 66 regions. There are 828 optional coins and twenty-four mimic relics, plus
three new Stage 1 equipment caches. Stage 1 has eight sanctuaries and 40 enemies;
stages 2-12 retain five sanctuaries and nineteen encounters each. All stages share
the core combat, healing, controller and checkpoint systems.

1. HALLOWEEN TOWN - WITCHING HOUR
Explore the belfry, cistern and floodgarden branches from the Crooked Quarter.
Return the three seals to its ritual circle, unlock the tram shortcut, defeat the
Gravekeeper (16 health), claim the Moon Key at x18260 and leave through x19000.
The redesigned prison, water controls and optional equipment form connected side
routes; see the reference-build section above for traversal and map controls.
Scene: scenes/halloween_town.tscn.

2. THE LANTERN ROAD
Ashen Outskirts -> Pumpkin Fields -> Lantern Road -> Emberwick Approach.
Collect three golden hearth sparks. Defeat the Thorn Marshal (8 health), lift the
village ward at the shrine, then enter Emberwick. The route gradually changes from
haunted soil and bare trees to grass, birches, orchards, farms, cottages and paving.
Broken fences give way to maintained rails and stone boundaries. Chimney smoke,
warmer window panes, clearer shader water, wildlife, villagers, market props and
royal banners introduce the kingdom ahead. Behind the Iron Gates crossfades
into Footsteps Upstairs from Haunted Manor.
The village's exit and the market's entrance share the same medieval gate and
complete pole-banner assets. Familiar cottages continue into the orchard gate.
Scene: scenes/lantern_road.tscn.

3. EMBERWICK MARKET
Orchard Gate -> Market Lanes -> Canal Quarter -> Royal Approach.
A new route uses Medievil Kingdom terrain, shop fronts, stalls, fences, towers,
lanterns, stone ledges and props. Recover three royal market crests, defeat the
Gate Captain (10 health), claim the Gate Writ and enter Crownward Keep.
The Seamstress, Cook and Gate Knight offer controller-accessible advice. Guards,
rats, mushrooms, bats, an eye, spitters and optional mimics populate the route.
Haunted Manor's Footsteps Upstairs accompanies the market, fading into
Whispers Between Pages over the final royal approach. Town roofs
give way to towers, timber rails to iron fences, and stalls to ramparts, supply
wagons and royal banners. The sky cools as the road approaches the keep.
Gold coins replace bat coins in the kingdom stages.
Scene: scenes/emberwick_market.tscn.

4. CROWNWARD KEEP
Outer Bailey -> Banner Wall -> Moon Court -> Crown Sanctum.
A second new route uses the Medievil Kingdom castle architecture, battlements,
columns, royal banners, fortifications, stone platforms, moats and courtyard props.
Recover three sapphire crown sigils, defeat the Hollow Regent (12 health), lift
the Crown Ward and open the Ashen Road. A Knight, Quartermaster and Bishop guide
the final approach. Haunted Manor's Whispers Between Pages supplies the stage
music, fading into The Locked Chamber for the approach to the Ashen Ramparts.
The outer bailey retains town roofs, a small awning shop and the same royal
supply-wagon details seen outside its gate. Deeper courtyards add complete pole
banners, weapon stores and workbenches. Route signs appear nearby;
stone abutments mark the kingdom's water crossings without closing the gaps.
Scene: scenes/crownward_keep.tscn.

5. ASHEN RAMPARTS - DARK FANTASY
Ashen Road -> Broken Battlements -> Cinder Canal -> Black Gate.
Cross ruined towers, barred arches and stone walkways. Recover three ashen runes,
defeat the Ashen Sentinel (10 health), claim the Cinder Writ and enter the cathedral.
Dark Fantasy supplies the ground, platforms, walls, architecture, props, hazards,
coins, objectives and gates. Haunted Manor supplies The Locked Chamber.
Scene: scenes/ashen_ramparts.tscn.

6. HOLLOW CATHEDRAL - DARK FANTASY
West Narthex -> Silent Nave -> Sunken Cloister -> Hollow Sanctum.
Vaulted arches and freestanding columns frame a separate route through the
flooded cloister. Gather three lost souls, defeat the Hollow Prelate (12 health)
and take the Sanctum Sigil. Overgrown ruins, trees and a collapsed woodland shelter
appear beyond the last nave. Beneath the Manor fades into Moonlight Through
Broken Glass near the exit into Briarwood; both are from Haunted Manor.
Scene: scenes/hollow_cathedral.tscn.

7. BRIARWOOD EXPANSE - ABANDONED FOREST
Old Border -> Lost Trail -> Forgotten Camp -> Briar Pass.
Follow overgrown earth, mossy walkways, abandoned cabins, a watchtower and assembled
ancient trees. Collect three map fragments, defeat the Briar Marshal (10 health)
and claim the Ranger's Token. Three animated camps, woodland lamps, trail props
and native NPC sheets mark safe pauses. Music: Moonlight Through Broken Glass
from Haunted Manor, fading into The Forgotten Attic.
Scene: scenes/briarwood_expanse.tscn.

8. ELDERROOT SANCTUARY - ABANDONED FOREST
Rooted Path -> Ancient Grove -> Moss Court -> Elder Sanctuary.
Moss-covered stone, vine-covered temples, rooted arches and branching trees lead
to the ancient stair. Restore three root keys, defeat the Rootbound Sovereign
(14 health), claim the Elderroot Ward and descend into the catacombs. The Forgotten
Attic fades into Behind the Walls as buried dungeon arches emerge among the roots.
Scene: scenes/elderroot_sanctuary.tscn.

9. ROOTBOUND CATACOMBS - DUNGEON
Root Stair -> Moss Galleries -> Flooded Ossuary -> Crypt Watch.
Follow mossy stone floors, roofed masonry galleries, burial arches and underground
waterways. Recover three crypt runes, defeat the Crypt Marshal (10 health), take
the Ossuary Writ and open the iron gate. Dungeon supplies terrain, ledges, crystals,
lamps, barrels, relics and architecture. Music: Haunted Manor's Behind the Walls,
fading into Beneath the Manor. Scene: scenes/rootbound_catacombs.tscn.

10. THE PRISM VAULT - DUNGEON
Iron Vestibule -> Glyph Hall -> Crystal Cistern -> Open Vault.
Rune floors, gold-trimmed ledges, glyph arches and blue crystals frame a distinct
route. Recover three vault keys, defeat the Prism Warden (12 health), claim the
Prism Sigil and open the forest-facing rune arch. Trees and mossy gateways emerge
as the late vault walls thin; dungeon stone blends into enchanted grass. Music:
Beneath the Manor, fading into Moonlight Through Broken Glass from Haunted Manor.
Scene: scenes/prism_vault.tscn.
The entire distant masonry layer recedes across the final region, so parallax
cannot keep a solid wall across the forest-facing exit. Carved glyph panels and
ornate friezes distinguish the vault from the catacombs' mossy reliefs.

11. LUMENWOOD TRAIL - MAGIC FOREST
Vault's Edge -> Lantern Grove -> Fairy Crossing -> Lumen Pass.
The incoming rune arch and distant dungeon ruins give way to enchanted soil,
rooted oaks, fairy homes, mushrooms and woodland lamps. Gather three rune shards,
defeat the Lumen Sentinel (12 health), claim the Grove Token and use the vine gate.
Butterflies and fireflies move gently and pause with the world. Music: Haunted
Manor's Moonlight Through Broken Glass, fading into The Haunted Manor main theme.
Scene: scenes/lumenwood_trail.tscn.
Small crystal clusters support drifting spirit wisps; these also freeze in menus.

12. STARFALL GLADE - MAGIC FOREST
Living Arch -> Mushroom Hamlet -> Standing Stones -> Starfall Heart.
Mossy cobbles, glowing willows, treehouses and mushroom cottages lead toward the
final portal. Restore three world seeds, defeat the Astral Keeper (14 health),
claim the Starfall Ward and awaken the Daybreak Gate. The Haunted Manor main theme
accompanies the route; victory fades into The Morning After. The final controller menu offers
replay or a return to Halloween Town. Scene: scenes/starfall_glade.tscn.

BORDER TRANSITIONS
The first and last 1,536 pixels of each stage blend terrain from the adjoining
asset pack, including the ground below the walkable surface. Both sky palettes
meet at the same border colors. The village gains market paving, royal stone
weathers into the ramparts, cathedral stone gives way to forest soil, and the
Briarwood trail gradually gains Elderroot's mossy cobbles. Elderroot introduces
buried Dungeon arches; the Prism Vault opens toward Magic Forest's trees, rune
gateways and grass. Lumenwood's soil becomes Starfall's moss-covered stone.
Dungeon stages use enclosed masonry silhouettes with no outdoor moon or stars.
Dark Fantasy silhouettes enter the keep's final skyline. Royal towers remain
behind the first rampart arches, cathedral vaults appear in the late ramparts,
and abandoned cathedral arches linger behind Briarwood's first cabins. Bare
woodland branches gradually give way to leafy branches; their wind freezes in
menus. These changes add no dense furniture to interactions or combat arenas.
Intermediate result screens preserve their border lighting; the opening and
final Daybreak celebrations retain dawn. Cathedral and Elderroot music now fade
in before their entrances. When the incoming song matches, Continue carries its
playback position forward, including while muted, instead of restarting it.
Each subsequent stage now begins beside the exact open gateway from the previous
exit: the haunted portal, royal gates, cathedral ironwork or vine-covered arch.
These replace the first architectural set piece where appropriate. Overlapping
entry furniture has been removed; the village's first tree frames the portal
instead of hiding it. A short 0.28-second world fade softens each arrival while
the HUD stays readable. Entrance footprints participate in prop-clearance checks.
Small details from the incoming pack recur on both sides of all eleven borders:
roadside grass and stones, castle rubble, dry grass and bones, woodland ferns,
catacomb rocks and crystals, then enchanted flowers and mushrooms. Details fade
toward the interior and use available floor space rather than filling a fixed
slot. Guardian arenas, arrival gates, exits, NPCs, checkpoints, hazards, healing
supplies and existing furniture remain clear. Ambient mote colors also meet at
the same shade on both sides of each border, then shift into the new stage palette.

CAMPAIGN AND CHECKPOINTS
Completing a stage records its results and unlocks the next stage. Continue,
Replay This Level, and the final Back to Halloween Town option work with a
controller. Journey totals combine the most recently completed result from each
stage. Replay resets only the current stage's local objectives and encounters.
Campaign results are held in memory: closing the game starts a fresh session.
Controller preferences are saved separately between game launches.

Five spirit lantern checkpoints restore all five vitality points. Falling or
losing all vitality returns you to the last lit lantern. Objectives, coins,
defeated enemies, broken urns and recovered relics remain collected for that run.
Surviving enemies reset to full health and hostile projectiles are cleared.
Every ten coins restores one vitality if injured. Nearby coins magnetize toward
you. Strike cracked urns for healing hearts; a heart waits if vitality is full.
Mimics on elevated routes guard two optional relics per stage and drop healing.
The compass points back toward missed objectives, then the guardian, reward and
exit. All twelve stages have their own geometry and elevated objective routes.

KEYBOARD
A/D or Left/Right: move
Space, W or Up: jump; press again in the air to double jump
J or X: attack; time further presses to chain the three-hit combo
J in the air: aerial strike; Down + J in the air: plunge and rebound on hit
J against an incoming spore or eye orb: reflect it toward its caster
Down + Jump: drop through one-way ledges; on solid ground this is a normal jump
Shift or K: dodge / air dash with brief invulnerability and a short cooldown
E: interact, speak, claim the stage reward or use the exit
Escape: pause/resume; F1: controls and controller settings
M: mute/unmute; R: restart the current stage

CONTROLLER - ALL TWELVE STAGES AND MENUS
Left stick or D-pad: move; analog speed scales with stick deflection
A / Cross / Nintendo B (south): jump and double jump
X / Square / Nintendo Y (west): attack, combo and reflect
B / Circle / Nintendo A (east): dodge / air dash
RB / R1 / R or RT / R2 / ZR: alternate dodge with the default layout
Y / Triangle / Nintendo X (north): interact and speak
Down + attack: aerial plunge; Down + jump: drop through a suspended ledge
Menu / Options / Plus: pause/resume
View / Touchpad / Minus: controls and controller settings
South face button confirms menus; east face button goes back; stick/D-pad navigates.
Pause includes Resume, Restart, Controls, audio mute/unmute and Quit Game.
Twelve supplied UI icons in two rows and a stage counter show journey progress.
Escape / Menu opens a parchment field journal with the current task, stage
statistics, activated lantern, journey progress and completion totals. Real
controller buttons support Resume, Continue, Replay, Controls, Mute and Quit.
The Mini Pocket UI pack now supplies the journal, framed buttons, HUD panels,
objective holders, vitality hearts, progress bars and controller settings skin.
Objective icons match each stage's actual collectible. Guardian bars show numeric
health, individual hit divisions and a short damage trail after an impact.
Long dialogue wraps above the footer, and long journal titles fit on one page.
NPC advice changes after collecting all markers, defeating the guardian and
claiming the ward. Lanterns activate only on their own ground-level path;
passing overhead on a ledge cannot activate or heal at a checkpoint.
Pause and completion screens identify the current supplied music track.

The face-button dodge position follows the published Belmont's Curse layout;
the other bindings adapt this game's jump, melee, dash and interaction kit.
Reference: https://blog.playstation.com/2026/07/17/castlevania-belmonts-curse-hands-on-report/

Settings remap jump, attack, dodge, interact and pause. Assigning an occupied
button swaps those actions. D-pad movement, View and Guide are reserved; menu
confirm/back keep their physical positions. View/F1/Escape cancels remapping.
An RB remap removes the alternate RB dodge conflict. Restore Defaults resets
bindings, deadzone, rumble and label preferences.
Adjust stick deadzone from 10-40% (default 24%), rumble strength from 0-100%
(default 75%), and Auto/Xbox/PlayStation/Nintendo labels. Preferences are saved
in Godot's user://controller_settings.cfg. Prompts switch automatically between
keyboard and pad, including NPC/urn badges. Slight stick movement permits slow
walking while retaining facing; a deliberate direction turns immediately.
Downward stick lean does not swallow a jump on solid terrain. Down-jump intent
is retained through hit pause, and a ledge drop leaves one recovery jump.
Saved layouts reject reserved navigation buttons as well as invalid indices.
The right trigger requires a clear release between dodges and ignores mid-travel
jitter. Remapping disables its default shortcut. Disconnecting the active pad
pauses and clears held input; an idle second pad does not take over. Losing
window focus pauses safely and stops vibration. Closing menus consumes held
buttons and restores the prior menu focus, including Continue between stages.
An already-held stick or D-pad direction resumes without first returning to
neutral, and releases normally afterward. Holding the menu-back button cannot
freeze the player in midair or leak a dodge, attack or jump into gameplay.
Attack buffers retain their deliberate direction and aerial-plunge intent
through hit pause, even when the stick/buttons are released before the hit ends.
Dodge buffers also retain their pressed direction (or facing when neutral),
so a later stick reversal during hit pause cannot reverse an already queued dodge.
HUD and settings guidance show the active layout's shoulder/trigger alternatives;
a shoulder assigned to another action is removed from the alternate-dodge hint.
The active controller's D-pad takes priority over its stick, so a conflicting
stick lean cannot slow a digital direction. Opposite D-pad directions are neutral.
A neutral event from an idle second controller cannot erase active stick motion.
Down-jump and aerial plunges require a deliberate downward stick tilt; shallow
diagonal drift preserves normal jumps and aerial attacks. D-pad up overrides a
downward stick lean, and explicit D-pad down remains immediate.
Pausing immediately clears controller motor feedback. Resume restores paused
combat SFX and consumes the menu button without leaking a jump, dodge or attack.
Unused right-stick/left-trigger movement and a partial right-trigger squeeze
from an idle pad do not steal the active controller. A deliberate movement,
button or enabled full trigger still selects that controller. Raw stick samples
remain cached below the deadzone, so lowering or raising the setting immediately
affects a held stick without needing another movement event.

ENEMIES AND COMBAT
Enemies acquire a distant visible target over 0.12 seconds, with immediate
recognition at close range or after being struck. A small suspicion marker and
supplied sparkle/growl cue introduce the approach before the full attack warning.
They remember the last visible position for 0.9 seconds, then suspicion fades.
Ground enemies stay on their authored support and require a target within their
attack height. All enemies respect solid cover, including terrain between their
body and muzzle. Once committed, attack aim and warning duration stay fixed.
Checkpoint recovery clears perception, target memory and hostile projectiles.

Pumpkins: two hits; amber windup before a directional lunge.
Bats: one hit; captured-target dive after a visible warning.
Mosquitoes: one hit; 0.72-second warning before a faster 360-pixel/second dive,
followed by a 1.05-second retreat/recovery. Their two-row sheet uses populated
idle/dive and death frames. They enter the swamp, village road and forest routes.
Mushrooms: two hits; 0.68-second warning before a bounded ground roll.
Flying eyes: two hits; 0.82-second captured-aim warning, then one slow reflectable orb.
Flying witches: three hits; 0.95-second captured-aim warning, then one reflectable
spell at 210 pixels/second. Magic Forest supplies its rotating purple orb; the
eight-frame cast and seven-frame death use the supplied Flying Witch sheet.
Witches enter the market, keep, dark stages, catacombs, vault and final glade.
Spitters, flying eyes and witches require an unobstructed ray from their actual muzzle
to the player's torso before beginning an attack. Solid terrain prevents a
warning; sustained clear sight permits the attack without wasting a cooldown.
Once committed, the warning keeps its captured aim while the player dodges.
Rats: two hits; 0.60-second warning before a fast scurry near the village.
Thorn spitters: three hits; aimed spores can be reflected with a timed melee hit.
Guards: three hits; 0.72-second warning and a readable ground swing. Light attacks
interrupt them. Stage three has two guards and stage four has three.
Mimics: four hits; optional ledge encounters with a long reveal before lunging.
Guardians: 8 / 8 / 10 / 12 / 10 / 12 / 10 / 14 / 10 / 12 / 12 / 14 health. Light attacks damage charge armor without
interrupting it. A combo finisher or aerial plunge deals two damage and breaks
the charge. Half of each guardian's own maximum health triggers two-sided flames.
Jump or dodge through them. Nearby enemies, including guardians, respect attacks
that have already committed, preserving distinct reaction windows.
A guardian crossing half health keeps the duration of its current warning;
the shorter enraged windup begins with its next attack.
Breaking guardian armor opens a 1.15-second recovery instead of the ordinary
0.85-second window, with supplied guard-break VFX/SFX and a controller-aware HUD
cue. Follow-up attacks do not reset that recovery clock indefinitely. Ground
contact from a guard-broken guardian is harmless during that recovery, allowing
close counterattacks. Ordinary guardian contact and lingering projectiles remain
dangerous; the opening ends when recovery finishes. Ground
patrols, charges and knockback use each enemy's actual floor or ledge limits;
the warning chevrons use those same limits rather than pointing beyond a bank.

The third combo hit and plunges deal two damage. Directional dodges can cancel
swings. Jump buffering, coyote time and hit-pause input buffering aid responsiveness.
Windup rings, ground reach chevrons, aim dots and dive markers show incoming attacks.
Damage causes knockback with temporary invulnerability. A CLEAN DODGE through an
incoming hit awards feedback and shortens that dash's recharge by 0.18 seconds,
once per dodge. ARMOR and GUARD BREAK feedback distinguish guardian reactions.
Enemy animation follows the actual populated cells of the supplied sheets; moving
guards, rats and guardians use their walk rows. Reactions keep grounded feet fixed.
Original orc, plant, eye and witch sheets face left. Their sprite orientation now
accounts for that source direction so attacks and movement face the actual target;
the rat's original right-facing sheet keeps its own direction convention.
A brief texture-based impact shader makes hits readable on dark enemy sprites.
Enemy health bars briefly retain the lost portion before draining and fading;
their anchors clear the visible frames of all eleven enemy types. Warning markers
also sit above those silhouettes. Recovery poses compress gently with grounded
feet. Expired projectiles cannot award a reflection during deferred cleanup.
Swept projectile contacts resolve in travel order: the first enemy or player is
hit before stone farther along the path, and intervening stone blocks later
targets. Returned shots choose the nearest target, independent of spawn order.
Successful returns produce a centered cue above the enemy's health bar and a
short controller pulse. Plunges can reflect shots below either side; orphaned
shots always receive a nonzero return direction. Stone impacts and projectile
launches use smaller supplied Seeker effects to keep combat silhouettes clear.
Solid cover also blocks player melee, supply-breaking, reflections, enemy contact
and committed melee damage. One-way ledges preserve their existing attack rules.
Light and heavy impact bursts are smaller, while supplied notice sparkles, cast
swirls, slash arcs, dive trails and defeat particles identify actual combat events.
Controller feedback prioritizes hurt, heavy hits, clean dodges and victory so
landing and ordinary dash pulses cannot truncate stronger feedback.
Breakable supplies use haunted urns in stages one/two, clay pots in the market
and small barrels in the keep. Broken debris is anchored to the floor; each
container still drops exactly one healing heart. The new Dark Fantasy stages
use their own barrels; Abandoned Forest uses woodland crates and debris. Dungeon
barrels become dungeon debris, and Magic Forest urns become grounded pottery shards.

ASSETS AND PRESENTATION
All art, animation and audio come from the folders supplied with this project.
Stages/Medievil Kingdom provides both new stage environments, objectives, gold
coins, royal gates and courtyard/market props. Stages/Village introduces larger
cottages along stage two and at stage three's entrance. Halloween Town, Abandonded
Forest and Dark Fantasy supply haunted landmarks and the gradual countryside mix.
NPC packs supply animated characters and the carriage; Props supplies campfires
and healing items. UI/Super Asset Bundle #5 Mini Pocket Status 2.1 supplies the
journey icons and Brown skin used for the HUD, journal, menus and settings.
Stages/Dark Fantasy supplies the two new shadow stages. Stages/Abandonded Forest
(the folder's original spelling) supplies both new woodland stages. Those stages
use three animated camps each and deliberately sparse, grounded prop clusters.
Stages/Dungeon supplies stages nine and ten, and Stages/Magic Forest supplies
stages eleven and twelve. Each has its own floors, traversal layout, collectible
art, breakables, props and scenery, plus three camps and three animated NPCs.
Dungeon walls use supplied frieze bands and carved reliefs. Subtle crystal halos
and Magic Forest spirit wisps add light without covering combat silhouettes.

Shader water adapts the supplied REEBOO Labs Godot Water Shader Kit 1.0. It uses a
pause-aware clock, restrained pixel refraction, depth color, rays, spring ripples
and splash detection. Source kit files remain intact. Window panes warm toward
the village and gentle wind moves rooted vegetation and banners. Smoke and
butterflies pause with the world. Distant architecture and trees use parallax/haze;
lanterns, objectives, checkpoints and the player have subtle local lighting.
Five market shop fronts carry the village's warm windows into the royal road;
one sheltered shop remains near the keep entrance. Pane lighting preserves the
source roof/wall colors and pauses with the world. Castle torch brackets attach
to measured opaque pixels in the towers, walls and arch pillars.

PROP PLACEMENT
Grounded sprites use their visible pixel bounds, including differently padded
and non-square assets. Dense props leave NPCs, spirit lanterns, breakable supplies,
reward chests, exits, spikes and camps clear. Furniture silhouettes are spaced;
solid prop footprints must fit entirely on a floor span. Foliage may overhang
a bank, but solid objects cannot float over water. Wall torches attach to actual
castle architecture; banners use the complete banner_on_pole asset, not the
similarly named three-pixel mounting rod. The ritual circle lies flat as a decal.
Review full overlapping route captures before adding another layer of props.
Dungeon and Magic Forest crystal clusters participate in the same furniture,
interaction, hazard and floor-support checks as lamps, barrels and benches.

Hero/Seeker_PRO supplies hero animation and primary movement/impact VFX.
VFX/Pack 1, Pack 5 and Pack 6 add reflection, guard break, armor, water splashes,
mushroom rolls, eye charging and clean dodges. assets/effects_manifest.json lists
exact source frame paths. SFX/One_Shots supplies twenty-five selected gameplay cues.
The fourteen additions use bounded mono PCM WAV copies with normalized peaks and
clean fades; assets/audio/additional_sources.json records their source paths.
Original recordings are intact. Eight pooled voices support overlapping effects.
Critical warnings, hurt, reflection and guard-break cues can replace weaker sounds
when the pool fills. Repeated pickup/impact cues within 55 milliseconds coalesce.
Enemy notices, swings, spell release, dives and defeat sounds attenuate with
distance and stay silent beyond 900 pixels. Combat SFX freeze with pause and
resume with gameplay; the music continues at its quieter menu level.
Music ducks gently while paused, mute survives scene changes, and the final stage
crossfades to the supplied ending music after victory.

IMPLEMENTATION
scripts/witching_hour.gd: shared state, objectives, checkpoints and interactions
scripts/chapter_profile.gd, kingdom_profile.gd, expedition_profile.gd, deep_profile.gd: twelve stage profiles
scripts/campaign_state.gd: continuation, unlocking, results and totals
scripts/town_builder.gd and village_builder.gd: first two authored routes
scripts/market_builder.gd and keep_builder.gd: new route geometry and playthrough points
scripts/kingdom_builder.gd: shared Medieval Kingdom terrain, buildings and encounters
scripts/ashen_builder.gd, cathedral_builder.gd: two separate Dark Fantasy routes
scripts/briarwood_builder.gd, elderroot_builder.gd: two separate forest routes
scripts/expedition_builder.gd: new-pack terrain, platforms, water and encounters
scripts/expedition_scenery.gd: new-pack architecture, parallax and assembled trees
scripts/expedition_details.gd: supported props, pack-specific lamps, camps and NPCs
scripts/rootbound_catacombs_builder.gd, prism_vault_builder.gd: two Dungeon routes
scripts/lumenwood_trail_builder.gd, starfall_glade_builder.gd: two Magic Forest routes
scripts/deep_biome.gd, deep_builder.gd: source terrain, platforms, water and encounters
scripts/deep_scenery.gd, deep_details.gd: dungeon/forest architecture, props and wildlife
scripts/kingdom_lighting.gd: measured shop panes and structure-mounted torch fixtures
scripts/world_details.gd, village_details.gd, kingdom_details.gd: props, camps and NPCs
scripts/road_biome.gd and world_motion.gd: returning nature, farms, smoke and village life
scripts/journey_details.gd: shared gate landmarks, route signs and bank details
scripts/border_details.gd: low incoming-pack details with floor/prop/interaction clearance
scripts/seeker.gd: hero movement, combo, plunge, dodge and damage
scripts/hero_motion.gd: documented feet pivots, source-frame timing and active windows
scripts/upright_campfire.gd: side-view fire art, floor anchoring, flicker and rising embers
scripts/stage_expansion.gd: inserted upper/lower routes, remapped final areas and vertical scenery
scripts/haunt.gd and enemy_animation.gd: enemy behavior and measured animation rows
scripts/combat_director.gd: attack resolution, pacing, guardians and rewards
scripts/cursed_bolt.gd: hostile/reflected spores, eye orbs and guardian flames
scripts/breakable_urn.gd and spirit_vial.gd: healing props and pickups
scripts/level_hud.gd and stage_ribbon.gd: HUD state, menus and sourced journey icons
scripts/pocket_ui.gd: cached source textures, pixel frames, control theme and text layout
scripts/pocket_hud_painter.gd: sourced HUD, captions, announcements and guardian bars
scripts/journey_journal.gd: parchment pause/results journal and current-task guidance
scripts/controller_hub.gd, controller_bindings.gd, controller_devices.gd,
controller_trigger.gd and controller_panel.gd: controller input, settings and feedback
scripts/controller_feedback.gd: priority and duration for overlapping rumble events
scripts/enemy_impact.gdshader: texture hit flash with preserved tint and transparency
scripts/level_audio.gd: supplied soundtracks, ending crossfade and pooled effects
scripts/level_effects.gd and asset_effects.gd: movement and supplied VFX clips
scripts/level_assets.gd: texture cache, visible bounds and grounded sprite helpers
scripts/level_backdrop.gd, night_sky.gd, town_atmosphere.gd: camera and region atmosphere
scripts/stage_blend.gd: adjoining-pack terrain strips and continuous sky palettes
scripts/stage_entrance.gd: matching exit/entry gateways and grounded arrival landmarks
scripts/enemy_footing.gd: supported patrol, charge and knockback bounds
scripts/cursed_water.gd and river_surface.gdshader: adapted water and ripples
scripts/hearth_windows.gdshader and foliage_sway.gdshader: window/wind presentation
scripts/world_lighting.gd, seal_marker.gd, background_wash.gdshader: halos and depth
The original town square remains preserved in scenes/town_square_preview.tscn.

ORIGINAL-LAYOUT REGRESSION REFERENCE
The following suites retain the earlier 6,400-pixel coordinate fixtures. Run them
with -- --original-layout; that switch is for regression fixtures only. Normal
Play launchers always use the expanded stages. Use the current-build tests above
for the new routes, counts and vertical geometry.

VERIFICATION - RUN FROM THIS FOLDER IN POWERSHELL
Use the included console executable with --headless --path . --fixed-fps 60
and --script followed by one of these test paths:
  tests/level_checks.gd                    30 checks
  tests/polish_checks.gd                   26 checks
  tests/combat_checks.gd                   26 checks
  tests/refinement_checks.gd               26 checks
  tests/chapter_checks.gd                  29 checks
  tests/controller_checks.gd               44 checks
  tests/living_world_checks.gd             37 checks
  tests/shader_encounter_checks.gd         37 checks
  tests/kingdom_checks.gd                  50 checks
  tests/journey_checks.gd                  42 checks
  tests/placement_checks.gd                49 checks
  tests/input_combat_polish.gd             26 checks
  tests/responsive_checks.gd               67 checks
  tests/expedition_checks.gd              157 checks
  tests/pocket_ui_checks.gd               219 checks
  tests/border_polish_checks.gd           249 checks
  tests/arrival_combat_checks.gd          239 checks
  tests/deep_checks.gd                    47 checks
  tests/sight_recovery_checks.gd           42 checks
  tests/campaign_polish_checks.gd          81 checks
  tests/awareness_feedback_checks.gd      131 checks
1654 original-layout core checks cover movement, combat, all twelve objectives/guardians, checkpoints,
scene cleanup, mute, controller input, remapping, focus, shader water, new enemies,
source animation frames, VFX, SFX, music and result/continuation behavior. Journey
checks cover scenery staying on land, committed guardian warnings, impact resets,
destination crossfades, pause/mute behavior and overlapping feedback priorities.
Placement checks examine actual visible bases, interaction/hazard/camp clearance,
solid footprints on land and spacing between furniture silhouettes. Input/combat
checks cover down-jump buffering, recovery jumps, stage-specific breakables,
grounded debris and reserved-button layout validation.
Responsive checks cover buffered attack direction/plunges, held-stick/D-pad
resume and release, safe midair menu dismissal, all eleven enemy UI silhouettes,
damage trails, expired projectiles and the new pause-aware shop windows.
Placement checks also verify all eight torch brackets against actual masonry
pixels, keeping fixtures out of the transparent arch/gate openings.

Continuous keyboard routes: tests/route_playthrough.gd, tests/village_route.gd,
tests/kingdom_route.gd, tests/expedition_route.gd and tests/deep_route.gd. They use real movement inputs without teleports, disable
contact damage to isolate geometry, and fight each guardian through attack inputs.
tests/controller_journey.gd traverses all twelve stages, defeats all guardians and
uses controller events for continuation, controls-screen focus and the final return.

tests/guardian_balance.gd fights with normal damage and requires no deaths. Add
-- --controller to use native joypad events, and --chapter-two, --chapter-three or
--chapter-four after that separator for the original routes, or --stage=5 through
--stage=12 for later stages. All twelve guardians pass with normal damage and no
deaths. No physical controller was attached: actual hardware
mapping, feel and motor vibration remain a hands-on check. Test preference files
go under artifacts/ and do not overwrite the player's saved controller settings.

Rendered fixtures (omit --headless): tests/controller_visuals.gd,
tests/living_world_visuals.gd, tests/shader_encounter_visuals.gd and
tests/kingdom_visuals.gd, tests/journey_visuals.gd and tests/placement_visuals.gd.
Placement visuals cover stages one through four in six overlapping views (24 native captures).
tests/expedition_visuals.gd adds 24 overlapping route captures and four completion
screens for stages five through eight. tests/deep_visuals.gd adds 24 overlapping route captures plus journals and results
for stages nine through twelve. Combined, the route fixtures cover all twelve stages.
tests/feedback_visuals.gd captures combat feedback on all four routes.
tests/pocket_ui_checks.gd adds 219 checks across all twelve stages: source UI assets,
controller journal navigation and settings sliders, page bounds, completion focus,
wrapped text, changing NPC advice, ground-only checkpoints and guardian damage trails.
tests/pocket_ui_visuals.gd captures all twelve HUDs, journals and results, long
dialogue, guardian impacts, all three controller labels, remapping and the label picker.
tests/border_polish_checks.gd adds 249 checks for all eleven adjoining palettes,
supported terrain/enemy movement, guard-break recovery, buffered dodge direction,
layout-specific guidance, pause-aware branches, completion lighting and music
continuation/mute. tests/border_visuals.gd renders all twenty-four stage edges,
twelve guard-break openings and three controller layouts for visual review.
tests/arrival_combat_checks.gd adds 239 checks for all twelve arrival fades,
matching gateways, D-pad/stick arbitration, deliberate downward intent, idle-pad
isolation, ordered projectile collisions, return feedback and plunge reflections.
tests/arrival_visuals.gd captures all twelve arrival fades, reflected flights,
return impacts and small stone impacts. Placement checks include the arrival gates.
tests/deep_checks.gd adds 47 checks for the four new routes, source-pack assets,
opaque platform tops, wildlife pausing, breakables, healing and the stage-eight handoff.
tests/sight_recovery_checks.gd adds 42 checks for blocked/clear ranged attacks,
captured aim, all twelve guardian contact/recovery windows, gradual vault masonry
and pause-aware spirit wisps. All twelve normal-damage guardian fights and the
controller campaign have also been rerun after these combat refinements.
tests/campaign_polish_checks.gd adds 81 checks for all eleven atmospheric seams,
incoming-pack details and new encounter presence across all twelve stages, idle-pad
axis isolation, live deadzone adjustment, mosquito dive/recovery and witch casting,
source spell art, return damage and reflection through native controller melee.
tests/fauna_visuals.gd captures both new enemies' warnings and attacks.
tests/awareness_feedback_checks.gd adds 131 checks for all twelve acquisition,
memory, reset and controller-pause behaviors, thin solid cover, sound priority,
cue coalescing/attenuation/mute, the five new bounded WAVs and source VFX cleanup.
tests/awareness_visuals.gd captures suspicion, memory, committed warning, swing
release, reduced hit impact and defeat feedback. The twelve normal-damage guardian
fights, full controller journey and every keyboard route pass with these changes.
The complete keyboard routes and twelve-stage controller journey have been rerun
with the new encounters. The route fixtures refresh all 72 overlapping views.
tests/window_render_checks.gd adds two GPU checks: original colors remain intact
outside the pane, and the selected window illuminates. This makes 1656 original-layout checks
including renderer validation. It saves window-render-comparison.png for review.
The render-only fixtures block desktop gameplay input
while capturing so a keystroke cannot activate their menus. Screenshots and logs
are saved under artifacts/. Rendering also checks the shaders on the Compatibility
renderer. The original check suites accept -- --screenshots where documented in
those scripts.

This is a playable twelve-stage source project with authored runtime layouts,
not a packaged executable export. The asset-populated local folder is required;
the GitHub repository contains code and text manifests only. Art, sound, music,
derived media, the engine and research captures are excluded from Git.
