CanArmNow()
{
    if (!isAlive(self) || !isDefined(self.origin))
        return false;

    if (self isinvehicle())
        return false;

    if (isDefined(self.bo_insertion_active) && self.bo_insertion_active)
        return false;

    if (!IsLandedStable())
        return false;

    return true;
}

CanArmNowFast()
{
    if (!isAlive(self) || !isDefined(self.origin))
        return false;

    if (self isinvehicle())
        return false;

    if (isDefined(self.bo_insertion_active) && self.bo_insertion_active)
        return false;

    if (self isonground())
        return true;

    return IsLandedStable();
}

GiveRandomPrimary()
{
    if (!isDefined(level.AllBlackoutWeapons))
        return;

    if (level.AllBlackoutWeapons.size <= 0)
        return;

    idx = randomint(level.AllBlackoutWeapons.size);
    wname = level.AllBlackoutWeapons[idx];

    if (!isDefined(wname) || wname == "")
        return;

    self GivePrimarySafe(wname);
}

GivePrimarySafe(weaponName)
{
    if (!isDefined(weaponName))
        return;

    w = getweapon(weaponName);
    if (!isDefined(w))
        return;

    self enableweapons();

    prims = self getweaponslistprimaries();
    if (isDefined(prims))
    {
        foreach (pw in prims)
            self takeweapon(pw);
    }

    self enableweapons();
    self giveweapon(w);
    self givemaxammo(w);
    self switchtoweaponimmediate(w);
    self enableweapons();
}

PickLandingWeaponName()
{
    weapons = array(
        "smg_standard_t8",
        "smg_handling_t8",
        "smg_fastfire_t8",
        "ar_fastfire_t8",
        "ar_accurate_t8",
        "ar_modular_t8",
        "tr_damageburst_t8"
    );

    if (!isDefined(weapons) || weapons.size <= 0)
        return "smg_standard_t8";

    return weapons[randomint(weapons.size)];
}

LandingLoadoutWatcher()
{
    self endon("disconnect");
    self endon("death");
    level endon("game_ended");
    self endon("bo_brain_restart");

    t0 = gettime();

    while (!IsOnRealSurface() && gettime() - t0 < 45000)
        wait 0.20;

    if (!isAlive(self))
        return;

    if (isDefined(self.bo_landing_loadout_done) && self.bo_landing_loadout_done)
        return;

    self.bo_landing_loadout_done = true;

    self GiveArmor();
    self GiveRandomLoot();

    if (!isDefined(self.bo_landing_gun_done) || !self.bo_landing_gun_done)
    {
        self.bo_landing_gun_done = true;
        w = PickLandingWeaponName();
        if (isDefined(w))
            self GivePrimarySafe(w);
    }
}

ForceArmBurst(msTotal)
{
    if (!isDefined(msTotal))
        msTotal = 4500;

    if (!isAlive(self))
        return;

    endT = gettime() + msTotal;

    while (gettime() < endT)
    {
        if (!isAlive(self) || !isDefined(self.origin))
            return;

        if (!CanArmNow())
        {
            self disableweapons();
            wait 0.12;
            continue;
        }

        self enableweapons();

        if (HasGun())
            return;

        prims = self getweaponslistprimaries();
        if (isDefined(prims))
        {
            foreach (pw in prims)
                self takeweapon(pw);
        }

        self enableweapons();
        self GiveRandomPrimary();
        self enableweapons();

        prims2 = self getweaponslistprimaries();
        if (isDefined(prims2) && prims2.size > 0)
            self switchtoweaponimmediate(prims2[0]);

        if (HasGun())
            return;

        wait 0.12;
    }
}

HasGun()
{
    if (!isDefined(self) || !isPlayer(self) || !isAlive(self) || !isDefined(self.origin))
        return false;

    if (self isinvehicle())
        return false;

    if (isDefined(self.bo_insertion_active) && self.bo_insertion_active)
        return false;

    if (isDefined(self.sessionstate) && self.sessionstate != "playing")
        return false;

    prims = self getweaponslistprimaries();
    if (isDefined(prims) && prims.size > 0)
        return true;

    cw = self getcurrentweapon();
    if (isDefined(cw) && cw != "none")
        return true;

    all = self getweaponslist();
    if (isDefined(all) && all.size > 0)
        return true;

    return false;
}

EnsureArmedImmediate()
{
    if (!isAlive(self))
        return;

    if (!CanArmNowFast())
    {
        self disableweapons();
        return;
    }

    self enableweapons();

    if (HasGun())
        return;

    t0 = gettime();
    while (gettime() - t0 < 4500)
    {
        if (!isAlive(self))
            return;

        if (!CanArmNowFast())
        {
            self disableweapons();
            return;
        }

        self enableweapons();

        if (HasGun())
            return;

        prims = self getweaponslistprimaries();
        if (isDefined(prims))
        {
            foreach (pw in prims)
                self takeweapon(pw);
        }

        self enableweapons();
        self GiveRandomPrimary();
        self enableweapons();

        prims = self getweaponslistprimaries();
        if (isDefined(prims) && prims.size > 0)
            self switchtoweaponimmediate(prims[0]);

        if (HasGun())
            return;

        wait 0.18;
    }
}

EnsureArmedAfterLanding()
{
    self endon("disconnect");
    self endon("death");
    level endon("game_ended");

    self WaitForLanding_Safe();

    self ForceArmBurst(5000);

    burstStart = gettime();
    while (gettime() - burstStart < 4500)
    {
        if (!isAlive(self))
            return;

        if (!CanArmNow())
        {
            self disableweapons();
            wait 0.20;
            continue;
        }

        if (HasGun())
        {
            self enableweapons();
            break;
        }

        self enableweapons();
        self GiveRandomPrimary();
        self enableweapons();

        prims = self getweaponslistprimaries();
        if (isDefined(prims) && prims.size > 0)
            self switchtoweaponimmediate(prims[0]);

        if (HasGun())
            break;

        wait 0.20;
    }

    for (;;)
    {
        wait 7.0;

        if (!isAlive(self))
            continue;

        if (!CanArmNow())
        {
            self disableweapons();
            continue;
        }

        if (!HasGun())
        {
            self enableweapons();
            self GiveRandomPrimary();
            continue;
        }

        self GiveRandomPrimary();
    }
}

WeaponWatchdogLoop()
{
    self endon("disconnect");
    self endon("death");
    level endon("game_ended");

    if (!isDefined(self.bo_weapon_watch_next))
        self.bo_weapon_watch_next = 0;

    for (;;)
    {
        if (isDefined(self.bo_insertion_active) && self.bo_insertion_active)
        {
            wait 0.25;
            continue;
        }
        if (!isAlive(self) || !isDefined(self.origin))
        {
            wait 0.25;
            continue;
        }

        if (gettime() < self.bo_weapon_watch_next)
        {
            wait 0.25;
            continue;
        }

        if (!IsLandedStable())
        {
            wait 0.25;
            continue;
        }

        if (!HasGun())
        {
            self.bo_weapon_watch_next = gettime() + 4500;

            wait 0.75;

            t0 = gettime();
            while (gettime() - t0 < 6000)
            {
                if (!isAlive(self))
                    return;

                if (HasGun())
                    break;

                self enableweapons();
                self GiveRandomPrimary();
                self enableweapons();

                prims = self getweaponslistprimaries();
                if (isDefined(prims) && prims.size > 0)
                    self switchtoweaponimmediate(prims[0]);

                if (HasGun())
                    break;

                wait 0.25;
            }
        }
        else
        {
            self.bo_weapon_watch_next = gettime() + 2500;
        }

        wait 0.25;
    }
}

ArmNow_OnSpawn()
{
    self endon("disconnect");
    self endon("death");
    level endon("game_ended");

    self WaitForLanding_Safe();

    wait 0.05;

    self ForceArmBurst(5500);
}

GroundSnap(pos)
{
    if (!isDefined(pos))
        return undefined;

    start = (pos[0], pos[1], pos[2] + 4096);
    end = (pos[0], pos[1], pos[2] - 20000);

    tr = bullettrace(start, end, 0, self);
    if (isDefined(tr) && isDefined(tr["position"]) && isDefined(tr["fraction"]) && tr["fraction"] < 0.999)
    {
        hit = tr["position"];
        return (hit[0], hit[1], hit[2] + 10);
    }

    return (pos[0], pos[1], pos[2] + 10);
}

RearmAfterRedeployLanding()
{
    self endon("disconnect");
    self endon("death");
    level endon("game_ended");

    if (!isDefined(self.bo_land_arm_cooldown_until))
        self.bo_land_arm_cooldown_until = 0;

    landedCount = 0;

    for (;;)
    {
        if (!isAlive(self) || !isDefined(self.origin))
        {
            wait 0.15;
            continue;
        }

        if (HasGun())
        {
            landedCount = 0;
            wait 0.35;
            continue;
        }

        if (IsLandedStable())
            landedCount++;
        else
            landedCount = 0;

        if (landedCount >= 8)
        {
            if (gettime() < self.bo_land_arm_cooldown_until)
            {
                wait 0.25;
                continue;
            }

            self.bo_land_arm_cooldown_until = gettime() + 4000;

            wait 0.90;

            t0 = gettime();
            while (gettime() - t0 < 5000)
            {
                if (!isAlive(self))
                    return;

                if (HasGun())
                    break;

                self enableweapons();
                self GiveRandomPrimary();
                self enableweapons();

                prims = self getweaponslistprimaries();
                if (isDefined(prims) && prims.size > 0)
                    self switchtoweaponimmediate(prims[0]);

                if (HasGun())
                    break;

                wait 0.25;
            }

            landedCount = 0;
        }

        wait 0.25;
    }
}