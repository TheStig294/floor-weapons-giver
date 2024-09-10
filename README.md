# Auto-Floor Weapons Spawner
Automatically spawns guns/ammo on the ground of maps that don't have enough, automatically arms any Gmod map to make it playable with TTT!\
Also gives guns to anyone who doesn't have any when a round properly begins.\
\
Forget about manually adding guns to maps ever again, with this mod, you can now add maps without having to worry if they're properly armed!

## Settings
Put the words in *italics* in your listenserver.cfg if hosting a game from the main menu,\
(Usually located at:\
C:\Program Files (x86)\Steam\steamapps\common\GarrysMod\garrysmod\cfg)\
\
or your server's server.cfg if hosting from a dedicated server.


### Misc Settings
*ttt_floor_weapons_giver [0 or 1]*\
Default: 1, whether this mod is on or off\
\
*ttt_floor_weapons_replace_default_guns [0 or 1]*\
Default: 1, whether any default TTT guns already on the ground of a map, such as the H.U.G.E. or Glock, are automatically replaced by random guns of the same ammo type


### Weapon Giving Settings
*ttt_floor_weapons_giver_active [0 or 1]*\
Default: 1, whether to give weapons to players at the start of a round\
\
*ttt_floor_weapons_giver_delay [number]*\
Default: 0.2, seconds after a round starts until floor weapons are given to players that don't have one\
\
*ttt_floor_weapons_giver_ammo [number]*\
Default: 2, when weapons are directly given to players, how many boxes of ammo are given alongside


### Floor Weapon Spawning Settings
*ttt_floor_weapons_spawner_active [0 or 1]*\
Default: 1, if a map has few or no guns, whether floor weapons are automatically spawned on the ground\
\
*ttt_floor_weapons_spawner_delay [number]*\
Default: 0.2, delay in seconds after everyone respawns for the next round, until weapons are spawned on the ground\
\
*ttt_floor_weapons_spawner_ammo [number]*\
Default: 2, how many boxes of ammo are spawned with a gun on the ground\
\
*ttt_floor_weapons_spawner_guns [number]*\
Default: 6, how many guns are spawned on the ground around the map per alive player, if the limit below is never reached\
\
*ttt_floor_weapons_spawner_limit [number]*\
Default: 350, how many weapons and ammo boxes can be on the map before guns and ammo stop being spawned,\
this includes existing guns and ammo already on the map, or ones added from a weapon script\
\
*ttt_floor_weapons_spawner_near [number]*\
Default: 4, number of guns to spawn near players that don't have a gun near them when everyone respawns for the next round, if the limit above is never reached

## Steam Workshop Link
https://steamcommunity.com/sharedfiles/filedetails/?id=2592321966
