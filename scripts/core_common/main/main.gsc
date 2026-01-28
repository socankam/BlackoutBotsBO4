#include scripts\core_common\struct;
#include scripts\core_common\ai_shared;
#include scripts\core_common\callbacks_shared;
#include scripts\core_common\clientfield_shared;
#include scripts\core_common\math_shared;
#include scripts\core_common\system_shared;
#include scripts\core_common\util_shared;
#include scripts\core_common\hud_util_shared;
#include scripts\core_common\hud_message_shared;
#include scripts\core_common\hud_shared;
#include scripts\core_common\array_shared;
#include scripts\core_common\flag_shared;
#include scripts\core_common\bots\bot;
#include scripts\core_common\player\player_role;
#include scripts\core_common\player\player_stats;
#include scripts\core_common\values_shared;
#include scripts\core_common\spawner_shared;
#include scripts\core_common\flagsys_shared;
#include scripts\core_common\exploder_shared;
#include scripts\core_common\vehicle_shared.gsc;
#include scripts\core_common\rank_shared.gsc;

#using scripts\mp_common\armor;
#using scripts\core_common\aat_shared;
#using scripts\core_common\bots\bot_action;
#using scripts\core_common\bots\bot_stance;
#using scripts\core_common\animation_shared;
#using scripts\core_common\player\player_stats;
#using scripts\core_common\visionset_mgr_shared.gsc;
#using scripts\core_common\ai\systems\ai_interface.gsc;

#namespace blackoutbots;

// @SoCanKam on Discord
// Updates to come


autoexec __init__system__()
{
    system::register("blackoutbots", &__init__, undefined);

    /*
    ================
    Bot Difficulty
    1 = Regular
    2 = Hardened
    3 = Veteran
    ================
    */
    self.difficulty = 3;

    setGametypeSetting(#"wzrandomcamo", 1);

    setGametypeSetting(#"playernumlives", 5);
    setGametypeSetting(#"waverespawndelay", 5);
    setGametypeSetting(#"wzenablewaverespawn", 1);
    setGametypeSetting(#"wzwaterballoonsenabled", 1);
    setGametypeSetting(#"wzenableblackjackstash", 1);
    setGametypeSetting(#"wzenablecontrabandstash", 1);

    // Alcatraz zombie spawn fix
    map = util::get_map_name(); 
    if (map == "wz_escape"){
        setGametypeSetting(#"wzzombies", 1);
        setGametypeSetting(#"hash_44c7473eab6e5459", 1);
        setGametypeSetting(#"hash_4d6cfd0b3ee4cc7d", 1);
        setGametypeSetting(#"hash_76fb3219916a09f2", 1);
        if(self.difficulty == 2 || self.difficulty == 3) setGametypeSetting(#"hash_3624143624604b4c", 1);
    }
}

__init__()
{
    callback::on_connect(&onPlayerConnect);
    callback::on_spawned(&onPlayerSpawned);
}

onPlayerConnect()
{
}

onPlayerSpawned()
{
    self endon("disconnect");
    level endon("game_ended");
    
    self setclientuivisibilityflag("g_compassShowEnemies", 1); // Infinite sensor dart
    
    map = util::get_map_name(); 

    if (map == "wz_open_skyscrapers") bots = 39; // 11 if you're not using the Shield client
    else if (map == "wz_escape" || map == "wz_escape_alt") bots = 39; // same here

    if(Blackout()){
        if ( !self isTestClient() )
        {
            if ( !isDefined(level.bo_bots_spawned) )
            {
                level.bo_bots_spawned = true;
                level thread AddBotsToGame(bots);
            }
            return;
        }

        self InitBotDifficulty();

        self notify("bo_brain_restart");
        self endon("bo_brain_restart");

        self thread Brain();
    }
}

AddBotsToGame(Amount)
{
    if (!isDefined(Amount))
        Amount = 11;

    level.AllBlackoutWeapons = array(
            "ar_accurate_t8","ar_fastfire_t8","ar_an94_t8","ar_peacekeeper_t8","ar_doublebarrel_t8","ar_damage_t8","ar_stealth_t8","ar_modular_t8","ar_standard_t8","ar_galil_t8",
            "smg_vmp_t8","smg_minigun_t8","smg_standard_t8","smg_handling_t8","smg_fastfire_t8","smg_capacity_t8","smg_accurate_t8","smg_fastburst_t8","smg_folding_t8",
            "tr_powersemi_t8","tr_longburst_t8","tr_midburst_t8","tr_flechette_t8","tr_damageburst_t8",
            "lmg_spray_t8","lmg_stealth_t8","lmg_standard_t8","lmg_heavy_t8",
            "shotgun_pump_t8","shotgun_semiauto_t8","shotgun_fullauto_t8","shotgun_precision_t8",
            "sniper_powerbolt_t8","sniper_damagesemi_t8","sniper_locus_t8","sniper_mini14_t8","sniper_quickscope_t8","sniper_fastrechamber_t8","sniper_powersemi_t8",
            "pistol_standard_t8","pistol_fullauto_t8","pistol_burst_t8","pistol_revolver_t8"
    );

    level.bo_bot_characters = array(
        1, 2, 3, 4, 5,
        6, 7, 8, 9, 10,
        11, 12, 13, 14, 15,
        16, 17, 18, 19, 20,
        21, 22, 23, 24, 25,
        26, 27, 28, 29, 30,
        31, 32, 33, 34, 35,
        36, 37, 38, 39, 40,
        41, 42, 43, 44, 45,
        46, 47, 48, 49, 50,
        51, 52, 53, 54, 55,
        56, 57, 58, 59, 60,
        61, 62, 63, 64, 65,
        66, 67, 68, 69, 70,
        71, 72, 73
    );

    BotTeams = array(#"axis", #"allies");

    BotNames = array(
        "xXGhostXx","V1p3r","R0gu3","Reap3r_99","Sh4d0w",
        "H4v0c","Str1k3r","Bulle7","Fr0stBite","V3n0mX",
        "B1aze","Rapt0r_77","Hunt3rX","C0brA","Ph03n1x",
        "DrakeXx","F4lc0n","St0rm99","Tit4n_21","Mav3rickX",
        "Band1t_OG","Kn0x","N0vaX","Ra1der77","EchoX",
        "SkullCr4sh","NightH4wk","ZeroCool","Bl4ck0ut","Sn1perWolf",
        "IronCl4d","GhostUnit","R3dF0x","Cry0tic","VoidRunn3r",
        "D34dSh0t","StormBr1ng3r","H3llR4z0r","ShadowSix","OmegaX",
        "Vortex99","SilentF4ng","DarkR1der","NoMercyX","KillSw1tch",
        "BlitzKr13g","GrimShot","IceV3in","RuinX","Spectr4",
        "Deadlock","Phantomz","R3apX","BlackFang","ZeroSignal",
        "SavageOne","NovaPulse","Skirmish","R0cketMan","HavocUnit",
        "RazorEdge","KillZone","Crossh4ir","Ghosted","WarpDrive",
        "T0xicRain","FrostByteX","ArcWarden","Shad0wByte","TitanRage",
        "V1rtu0so","Cr1msonFox","DuskReaper","Gh0stM4sk","NeonR1ot",
        "S1lentStorm","W1d0wM4ker","AshenWolf","M1dn1ghtOps","R3dC0m3t",
        "NullVector","CipherX","R4venClaw","HyperNova","PulseR1der",
        "SkullV0lt","Gr1mF4ng","N1ghtShift","M0d3rnW4r","D3lt4Viper",
        "ClutchK1ng","QuickSc0pe","Sh0ckWav3","B1ackoutKid","F0xH0und",
        "Z3r0Mercy","SpectralX","VantaRay","R1otM0de","LethalEcho"
    );

    level.BotsInGame = array();

    anchor = undefined;
    players = getplayers();

    foreach (p in players)
    {
        if (isDefined(p) && isPlayer(p) && !p isTestClient())
        {
            if (isDefined(p.origin))
            {
                anchor = p;
                break;
            }
        }
    }

    level.bo_cluster_center = isDefined(anchor) ? anchor.origin : (0, 0, 0);
    level.bo_cluster_count = int(Amount);

    level.bo_pregame_anchor = anchor;
    level.bo_pregame_center = level.bo_cluster_center;

    for (i = 0; i < int(Amount); i++)
    {
        team = BotTeams[randomint(BotTeams.size)];
        name = BotNames[randomint(BotNames.size)];

        botEnt = addtestclient(name);

        if (isDefined(botEnt))
        {
            level.BotsInGame[level.BotsInGame.size] = botEnt;

            botEnt.botteam = team;
            botEnt.bo_bot_index = i;
            botEnt.bo_is_leader = false;

            botEnt thread WaitAndStartBrain();
        }

        wait 0.25;
    }
}

WaitAndStartBrain()
{
    self endon("disconnect");
    level endon("game_ended");

    self waittill("spawned_player");
    self.bo_pregame_lock_until = gettime() + 12000;
    if (isDefined(level.bo_pregame_anchor) && isDefined(level.bo_pregame_anchor.origin))
    {
        pre = PregameSpreadNearAnchor(level.bo_pregame_anchor, isDefined(self.bo_bot_index) ? self.bo_bot_index : 0, isDefined(level.bo_cluster_count) ? level.bo_cluster_count : 12);
        if (isDefined(pre))
            self setorigin(pre);
    }
    self thread AssignRandomCharacter();
    self EnableBotSprint();

    self.bo_follow_enabled_time = undefined;

    from = isDefined(self.origin) ? self.origin : (HasDeathCircle() ? level.deathcircle.origin : (0,0,0));
    self.bo_drop_poi = PickDryPOIInsideStorm(from, isDefined(self.bo_bot_index) ? self.bo_bot_index : randomint(9999));

    self thread AutoRespawnLoop();

    self thread Brain();
}

PregameSpreadNearAnchor(anchor, botIndex, botCount)
{
    if (!isDefined(anchor) || !isDefined(anchor.origin))
        return undefined;

    base = anchor.origin;

    minR = 180;
    maxR = 520;

    step = 360.0 / float(max(1, botCount));
    ang = float(botIndex) * step + randomFloatRange(-18, 18);

    r = randomFloatRange(minR, maxR);
    fwd = anglesToForward((0, ang, 0));

    pos = (base[0] + fwd[0] * r, base[1] + fwd[1] * r, base[2]);

    pos = FixBadSpawnLocation(pos);

    if (!isDefined(pos))
        return undefined;

    return pos;
}

SetBotCharacterByIndex(index)
{
    if (!isDefined(index))
        return;

    if (!isDefined(self) || !isPlayer(self))
        return;

    self setspecialistindex(index);
    self player_role::update_fields();

    self setcharacteroutfit(0);
    self setcharacterwarpaintoutfit(0);

    slots = array("head", "headgear", "arms", "torso", "legs", "palette", "warpaint", "decal");

    for (i = 0; i < slots.size; i++)
        self function_ab96a9b5(slots[i], 0);
}

AssignRandomCharacter()
{
    self endon("disconnect");
    level endon("game_ended");

    if (isDefined(self.bo_character_index))
        return;

    if (!isDefined(level.bo_bot_characters) || level.bo_bot_characters.size <= 0)
        return;

    if (!isAlive(self) || !isDefined(self.origin))
        self waittill("spawned_player");

    wait 0.20;

    if (isDefined(self.bo_character_index))
        return;

    idx = level.bo_bot_characters[randomint(level.bo_bot_characters.size)];
    self.bo_character_index = idx;

    self SetBotCharacterByIndex(idx);
}

GiveArmor()
{
    if (!self isTestClient()) return false;

    tier = 2;
    roll = randomint(100);
    if (roll < 55) tier = 1;
    else if (roll < 90) tier = 2;
    else tier = 3;

    if (tier == 1) item_id = #"armor_item_small";
    else if (tier == 2) item_id = #"armor_item_medium";
    else item_id = #"armor_item_large";

    maxArmor = 50 * tier;
    armorNow = maxArmor;

    self armor::set_armor(armorNow, maxArmor, tier);
    self clientfield::set_player_uimodel("hudItems.armorType", tier);

    #ifdef _SUPPORTS_LAZYLINK
        get_item = &function_4ba8fde;
        get_slotid = @item_inventory<scripts\mp_common\item_inventory.gsc>::function_e66dcff5;
        give_item = @item_world<scripts\mp_common\item_world.gsc>::function_de2018e3;

        if (isDefined(get_item) && isDefined(get_slotid) && isDefined(give_item))
        {
            itemobj = [[get_item]](item_id);
            if (isDefined(itemobj))
            {
                slotid = self [[get_slotid]](itemobj);
                if (isDefined(slotid))
                    self [[give_item]](itemobj, self, slotid);
            }
        }
    #endif

    return true;
}

GiveRandomLoot()
{
    if (!self isTestClient()) return false;

    perks = array(
        #"perk_item_outlander", #"perk_item_medic", #"perk_item_deadsilence",
        #"perk_item_bloody_tracker", #"perk_item_looter", #"perk_item_lightweight",
        #"perk_item_awareness"
    );

    meds = array( #"health_item_small", #"health_item_medium", #"health_item_large" );

    ammo = array(
        #"ammo_type_9mm_item", #"ammo_type_45_item", #"ammo_type_556_item", #"ammo_type_762_item",
        #"ammo_type_338_item", #"ammo_type_50cal_item", #"ammo_type_12ga_item", #"ammo_type_rocket_item"
    );

    equipment = array(
        #"frag_grenade_wz_item", #"cluster_semtex_wz_item", #"molotov_wz_item",
        #"concussion_wz_item", #"smoke_grenade_wz_item", #"emp_grenade_wz_item",
        #"dart_wz_item", #"trophy_system_wz_item", #"sensor_dart_wz_item",
        #"acid_bomb_wz_item", #"wraithfire_wz_item", #"barricade_wz_item",
        #"hawk_wz_item", #"grapple_wz_item", #"laser_sight_wz_item", #"backpack_item", #"tritium_wz_item", #"fastmag_wz_item"
    );

    rare_weapons = array(
        #"pistol_revolver_t8_gold_item",
        #"smg_handling_t8_gold_item",
        #"smg_accurate_t8_gold_item",
        #"smg_standard_t8_gold_item",
        #"smg_capacity_t8_gold_item",
        #"smg_fastburst_t8_gold_item",
        #"smg_folding_t8_gold_item",
        #"ar_accurate_t8_gold_item",
        #"ar_modular_t8_gold_item",
        #"ar_standard_t8_gold_item",
        #"ar_damage_t8_gold_item",
        #"ar_fastfire_t8_gold_item",
        #"ar_stealth_t8_gold_item",
        #"tr_longburst_t8_gold_item",
        #"tr_midburst_t8_gold_item",
        #"tr_powersemi_t8_gold_item",
        #"sniper_mini14_t8_gold_item",
        #"lmg_standard_t8_gold_item",
        #"lmg_spray_t8_gold_item",
        #"lmg_heavy_t8_gold_item",
        #"sniper_quickscope_t8_gold_item",
        #"sniper_powerbolt_t8_gold_item",
        #"sniper_powersemi_t8_gold_item",
        #"sniper_fastrechamber_t8_gold_item",
        #"ar_fastfire_t8_operator_item",
        #"ar_stealth_t8_operator_item",
        #"tr_longburst_t8_operator_item",
        #"tr_midburst_t8_operator_item",
        #"tr_powersemi_t8_operator_item",
        #"sniper_fastrechamber_t8_operator_item",
        #"sniper_quickscope_t8_operator_item",
        #"lmg_spray_t8_operator_item",
        #"lmg_standard_t8_operator_item",
        #"smg_accurate_t8_operator_item",
        #"smg_fastfire_t8_operator_item",
        #"pistol_revolver_t8_operator_item",
        #"sniper_mini14_t8_operator_item"
    );

    extra = array(#"armor_shard_item");
    rolls = randomintRange(3, 7);

    gaveAny = false;

    gaveRareWeapon = false;

    for (i = 0; i < rolls; i++)
    {
        r = randomint(100);

        if (!gaveRareWeapon && r < 3)
        {
            name = rare_weapons[randomint(rare_weapons.size)];
            if (GiveInventoryItem(name, 1))
            {
                gaveAny = true;
                gaveRareWeapon = true;
            }

            wait 0.05;
            continue;
        }

        if (r < 20)
        {
            name = perks[randomint(perks.size)];
            if (GiveInventoryItem(name, 1)) gaveAny = true;
        }
        else if (r < 52)
        {
            name = meds[randomint(meds.size)];
            if (GiveInventoryItem(name, randomintRange(1, 4))) gaveAny = true;
        }
        else if (r < 80)
        {
            name = ammo[randomint(ammo.size)];

            stacks = randomintRange(3, 7);
            perStack = randomintRange(20, 40);

            for (j = 0; j < stacks; j++)
            {
                if (GiveInventoryItem(name, perStack))
                    gaveAny = true;

                wait 0.01;
            }
        }
        else if (r < 96)
        {
            name = equipment[randomint(equipment.size)];
            if (GiveInventoryItem(name, 1)) gaveAny = true;
        }
        else
        {
            name = extra[randomint(extra.size)];
            if (GiveInventoryItem(name, randomintRange(1, 4))) gaveAny = true;
        }

        wait 0.05;
    }

    return gaveAny;
}

GiveInventoryItem(itemName, count)
{
    if (!isDefined(itemName)) return false;
    if (!isDefined(count)) count = 1;

    #ifdef _SUPPORTS_LAZYLINK
        get_item = &function_4ba8fde;
        give_item = @item_inventory<scripts\mp_common\item_inventory.gsc>::give_inventory_item;

        if (!isDefined(get_item) || !isDefined(give_item)) return false;

        item = [[get_item]](itemName);
        if (!isDefined(item)) return false;

        self [[give_item]](item, count, 0, undefined);
        return true;
    #endif
}

Brain()
{
    self endon("disconnect");
    level endon("game_ended");
    self endon("bo_brain_restart");

    if (!isDefined(self.bo_inited))
    {
        self.bo_inited = true;
        self bot::function_c6e29bdf();
        wait 0.10;
    }

    for (;;)
    {
        if (!isAlive(self) || !isDefined(self.origin)) self waittill("spawned_player");

        wait 0.05;
        self thread LifeStartThreads();
        self.bo_loot_given_life = false;
        self.bo_armor_given_life = false;

        wait 0.05;

        self.bo_search_goal = undefined;
        self.bo_next_goal_time = 0;
        self.bo_last_pos = self.origin;
        self.bo_last_pos_time = gettime();
        self.bo_last_seen_pos = undefined;
        self.bo_last_seen_time = undefined;
        self.bo_goal_last_dist = 999999999;
        self.bo_goal_last_progress_time = gettime();
        self.bo_roam_commit_until = 0;
        self.bo_sprint_until = 0;
        self.bo_gas_enter_time = undefined;

        self.bo_target = undefined;
        self.bo_target_next_recheck = 0;
        self.bo_target_lost_time = undefined;

        self.bo_revive_next_time = 0;
        self.bo_revive_cooldown_until = 0;
        self.bo_reviving = false;

        self.bo_target_score_cache_time = 0;

        for (;;)
        {
            if (!HasGun() && randomint(100) < 25)
                self EnsureArmedImmediate();

            if (ShouldSuppressCombatNow())
            {
                self InsertionDisarmCombat();
                self.bo_target = undefined;
                self.bo_target_lost_time = undefined;
                wait 0.10;
                continue;
            }

            if (!isDefined(self.bo_target_next_recheck))
                self.bo_target_next_recheck = 0;

            if (gettime() >= self.bo_target_next_recheck)
            {
                combatFast = isDefined(self.bo_target);
                diff = self GetBotDifficulty();
            if (combatFast)
            {
                if (diff == 3) self.bo_target_next_recheck = gettime() + randomintRange(60, 120);
                else if (diff == 2) self.bo_target_next_recheck = gettime() + randomintRange(70, 140);
                else self.bo_target_next_recheck = gettime() + randomintRange(80, 160);
            }
            else
            {
                if (diff == 3) self.bo_target_next_recheck = gettime() + randomintRange(160, 300);
                else if (diff == 2) self.bo_target_next_recheck = gettime() + randomintRange(190, 360);
                else self.bo_target_next_recheck = gettime() + randomintRange(220, 420);
            }

                if (isDefined(self.bo_target) && (!isAlive(self.bo_target) || !isDefined(self.bo_target.origin)))
                {
                    self.bo_target = undefined;
                    self.bo_target_lost_time = undefined;
                }

                best = PickBestThreatNow(7000);

                if (isDefined(best))
                {
                    if (!isDefined(self.bo_target))
                    {
                        self.bo_target = best;
                        self.bo_target_lost_time = undefined;
                    }
                    else
                    {
                        cur = self.bo_target;

                        curVis = CanSeeTarget(cur);
                        bestVis = CanSeeTarget(best);

                        curScore = ThreatScore(cur);
                        bestScore = ThreatScore(best);

                        if (bestVis && !curVis)
                        {
                            self.bo_target = best;
                            self.bo_target_lost_time = undefined;
                        }
                        else
                        {
                            if (bestScore > curScore + 18000)
                            {
                                self.bo_target = best;
                                self.bo_target_lost_time = undefined;
                            }
                        }
                    }
                }

                if (isDefined(self.bo_target))
                {
                    if (CanSeeTarget(self.bo_target))
                    {
                        self.bo_target_lost_time = undefined;
                    }
                    else
                    {
                        if (!isDefined(self.bo_target_lost_time))
                            self.bo_target_lost_time = gettime();

                        if (gettime() - self.bo_target_lost_time > 1800)
                        {
                            self.bo_target = undefined;
                            self.bo_target_lost_time = undefined;
                        }
                    }
                }
            }

            enemy = self.bo_target;
            if (!isDefined(enemy))
                enemy = FindEnemy();

            if (IsInDeathZone())
            {
                if (!isDefined(self.bo_gas_enter_time))
                    self.bo_gas_enter_time = gettime();

                safeGoal = undefined;

                poiGoal = self GetCurrentPOIObjective();
                if (isDefined(poiGoal))
                {
                    safeGoal = PickGoalNear(poiGoal, 900);
                    safeGoal = FixBadSpawnLocation(safeGoal);
                }

                if (!isDefined(safeGoal))
                    safeGoal = GetCircleSafeGoal();

                if (isDefined(safeGoal))
                {
                    self clearentitytarget();

                    self botsetmovepoint(safeGoal);
                    self botsetmovemagnitude(1.0);
                    UnstuckCheck(safeGoal);

                    if (randomint(100) < 22) self ScanLook();

                    wait 0.20;
                    continue;
                }
            }
            else
            {
                self.bo_gas_enter_time = undefined;
            }

            if (isDefined(enemy) && isAlive(enemy) && isDefined(enemy.origin))
            {
                canSee = CanSeeTarget(enemy);

                if (canSee)
                {
                    self.bo_last_seen_pos = enemy.origin;
                    self.bo_last_seen_time = gettime();
                }

                diff = self GetBotDifficulty();
                nearDist = 900;
                if (diff == 2) nearDist = 780;
                else if (diff == 3) nearDist = 650;

                goal = PickGoalNear(enemy.origin, nearDist);
                goal = NavSnap(goal);

                self botsetmovepoint(goal);
                self botsetmovemagnitude(1.0);
                UnstuckCheck(goal);

                if (canSee)
                {
                    self botsetlookpoint(enemy.origin);
                    self setentitytarget(enemy, 1);

                    if (HasGun())
                    {
                        self DifficultyCombatTactics(enemy);
                        self ShootBurst(enemy);
                    }
                }
                else
                {
                    self clearentitytarget();
                    self botsetlookpoint(goal);

                    if (randomint(100) < 25)
                        self ScanLook();
                }

                wait 0.10;
            }
            else
            {
                self clearentitytarget();

                stuck = false;
                if (gettime() - self.bo_last_pos_time > 1000)
                {
                    if (distanceSquared(self.origin, self.bo_last_pos) < (60 * 60)) stuck = true;

                    self.bo_last_pos = self.origin;
                    self.bo_last_pos_time = gettime();
                }

                searchingLastSeen = isDefined(self.bo_last_seen_time) &&
                    (gettime() - self.bo_last_seen_time) < 12000 &&
                    isDefined(self.bo_last_seen_pos);
                needNewGoal = false;

                if (!isDefined(self.bo_search_goal)) needNewGoal = true;

                if (!needNewGoal && distanceSquared(self.origin, self.bo_search_goal) < (450 * 450)) needNewGoal = true;

                if (gettime() >= self.bo_roam_commit_until)
                {
                    if (gettime() > self.bo_next_goal_time) needNewGoal = true;

                    if (stuck) needNewGoal = true;
                }

                if (needNewGoal)
                {
                    if (searchingLastSeen)
                    {
                        self.bo_search_goal = PickSearchSpiralGoal(self.bo_last_seen_pos, 750);
                        self.bo_next_goal_time = gettime() + randomintRange(1600, 2600);
                        self.bo_roam_commit_until = gettime() + randomintRange(1800, 3200);
                    }
                    else if (isDefined(self.bo_drop_poi))
                    {
                        self.bo_search_goal = PickGoalNear(self.bo_drop_poi, 1800);
                        self.bo_next_goal_time = gettime() + randomintRange(5200, 8800);
                        self.bo_roam_commit_until = gettime() + randomintRange(2600, 5200);
                    }
                    else
                    {
                        self.bo_search_goal = PickSearchGoal();
                        self.bo_next_goal_time = gettime() + randomintRange(6500, 10500);
                        self.bo_roam_commit_until = gettime() + randomintRange(2400, 5400);
                    }

                    self.bo_goal_last_dist = 999999999;
                    self.bo_goal_last_progress_time = gettime();
                }

                self.bo_search_goal = NavSnap(self.bo_search_goal);

                if (!isDefined(self.bo_search_goal))
                {
                    fallback = FindNearestDryNavFrom(self.origin);
                    if (!isDefined(fallback))
                        fallback = PickClosestPOIInsideStorm(self.origin);
                    if (!isDefined(fallback) && HasDeathCircle())
                        fallback = NavSnap(level.deathcircle.origin);

                    fallback = NavSnap(fallback);

                    if (!isDefined(fallback))
                    {
                        wait 0.25;
                        continue;
                    }

                    self.bo_search_goal = fallback;
                    self.bo_next_goal_time = gettime() + randomintRange(2500, 4500);
                    self.bo_roam_commit_until = gettime() + randomintRange(1800, 3200);
                }

                self botsetmovepoint(self.bo_search_goal);

                if (!isDefined(self.bo_sprint_until))
                    self.bo_sprint_until = 0;

                if (randomint(100) < 7)
                {
                    self botsetmovemagnitude(0.0);
                    wait randomFloatRange(0.10, 0.22);
                }

                if (gettime() < self.bo_sprint_until)
                    self botsetmovemagnitude(1.0);
                else
                {
                    self botsetmovemagnitude(1.0);
                    if (randomint(100) < 15)
                        self.bo_sprint_until = gettime() + randomintRange(900, 1900);
                }

                UnstuckCheck(self.bo_search_goal);

                if (randomint(100) < 22)
                    self ScanLook();
                else
                    self botsetlookangles((0, self.angles[1], 0));

                wait 0.25;
            }
        }

        wait 0.05;
    }
}

LifeStartThreads()
{
    self endon("disconnect");
    level endon("game_ended");
    self endon("bo_brain_restart");

    if (isDefined(self.sessionstate) && self.sessionstate != "playing")
        return;

    self.bo_landing_loadout_done = false;
    self.bo_landing_gun_done = false;

    self thread LandingLoadoutWatcher();

    self.bo_insertion_active = true;
    self.bo_hardtp_until = gettime() + 8500;

    self thread UpdateDropPOIForThisLife();
    self thread DeathCircleRecommitWatcher();

    self thread InsertionJumpOutRescueLoop();
    self thread InsertionStuckRescueLoop();
    self thread InsertionFreefallToPOI();
    self thread InsertionSkyStuckWatchdog();
    self thread InsertionAirSteerWatchdog();

    if (IsOnRealSurface())
    {
        self.bo_insertion_active = false;
        self EnsureArmedImmediate();
    }

    self SetPOIPriorityWindow(22000, 38000);

    self thread EnsureArmedAfterLanding();
    self thread RearmAfterRedeployLanding();

    self thread SpawnSanityRescueLoop();
    self thread WaterOrOutOfMapRescueLoop();
    self thread WeaponWatchdogLoop();

    if (IsOnRealSurface())
        self thread BO_TeamSpreadSpawn_OnLifeStart();
}

BO_TeamSpreadSpawn_OnLifeStart(a, b, c, d, e, f, g, h, i, j, k, l, m, n, o, p, q, r, s, t, u, v, w, x, y, z)
{
    if (!isAlive(self) || !isDefined(self.origin))
        return;

    if (self isinvehicle())
        return;

    if (!IsLandedStable())
        return;

    center = PickSpawnCenterSmart();
    center = FixBadSpawnLocation(center);

    if (!isDefined(center))
        center = FixBadSpawnLocation(self.origin);

    base = isDefined(center) ? center : self.origin;

    for (i = 0; i < 28; i++)
    {
        ang = randomFloatRange(0, 360);
        r = randomFloatRange(1300, 3200);
        fwd = anglesToForward((0, ang, 0));

        pos = (base[0] + fwd[0] * r, base[1] + fwd[1] * r, base[2]);
        pos = FixBadSpawnLocation(pos);

        if (!isDefined(pos))
            continue;

        if (distanceSquared(pos, base) < (950 * 950))
            continue;

        if (MinDistSqToOtherBots(pos) < (900 * 900))
            continue;

        self setorigin(pos);
        return;
    }

    fb = FixBadSpawnLocation(base);
    if (isDefined(fb))
        self setorigin(fb);
}

InitBotDifficulty()
{
    if (!isDefined(level.bo_bot_difficulty))
        level.bo_bot_difficulty = 1;

    if (!isDefined(self.difficulty))
        self.difficulty = int(level.bo_bot_difficulty);

    self.difficulty = ClampInt(self.difficulty, 1, 3);

    if (!isDefined(self.bo_diff_last_action_time))
        self.bo_diff_last_action_time = 0;
}

GetBotDifficulty()
{
    if (!isDefined(self.difficulty))
        return 1;

    return ClampInt(self.difficulty, 1, 3);
}

Blackout() {
    return sessionmodeiswarzonegame();
}