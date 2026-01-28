InsertionSkyStuckWatchdog()
{
    self endon("disconnect");
    self endon("death");
    level endon("game_ended");
    self endon("bo_brain_restart");

    t0 = gettime();

    if (!isDefined(self.origin))
        return;

    lastZ = self.origin[2];
    lastZTime = gettime();
    descendMs = 0;
    staleMs = 0;

    for (;;)
    {
        if (!isDefined(self.bo_insertion_active) || !self.bo_insertion_active)
            return;

        if (!isAlive(self) || !isDefined(self.origin))
        {
            wait 0.20;
            continue;
        }

        if (IsLandedStable() && !IsHighAltitudeInsertion())
            return;

        zNow = self.origin[2];
        dt = gettime() - lastZTime;

        if (zNow < lastZ - 6)
        {
            descendMs += dt;
            staleMs = 0;
        }
        else
        {
            staleMs += dt;
        }

        lastZ = zNow;
        lastZTime = gettime();

        dz = GetDzToGroundSafe(self);

        stuckHigh = (dz > 2600);
        longTime = (gettime() - t0 > 16000);
        notFalling = (staleMs > 4500);

        if (dz >= 9000000)
            stuckHigh = true;

        if (stuckHigh && (notFalling || longTime))
        {

            self InsertionDisarmCombat();
            self TryForceJumpOut();
            self bottapbutton(7);
            wait 0.25;
            continue;
        }

        wait 0.25;
    }
}

WaitForLanding_Simple(timeoutMs)
{
    self endon("disconnect");
    self endon("death");
    level endon("game_ended");

    if (!isDefined(timeoutMs))
        timeoutMs = 30000;

    startTime = gettime();

    for (;;)
    {
        if (!isAlive(self))
            return false;

        if (!isDefined(self.origin))
        {
            if (gettime() - startTime > timeoutMs)
                return false;

            wait 0.10;
            continue;
        }

        if (self isinvehicle())
        {
            if (gettime() - startTime > timeoutMs)
                return false;

            wait 0.10;
            continue;
        }

        if (IsLandedStable())
            return true;

        if (gettime() - startTime > timeoutMs)
            return false;

        wait 0.10;
    }
}

GetDzToGroundSafe(ent)
{
    if (!isDefined(ent))
        ent = self;

    if (!isDefined(ent.origin))
        return 9999999;

    start = (ent.origin[0], ent.origin[1], ent.origin[2] + 60);
    end   = (ent.origin[0], ent.origin[1], ent.origin[2] - 20000);

    tr = bullettrace(start, end, 0, ent);

    if (!isDefined(tr) || !isDefined(tr["position"]))
        return 9999999;

    return abs(ent.origin[2] - tr["position"][2]);
}

WaitForLanding_Safe()
{
    self endon("disconnect");
    self endon("death");
    level endon("game_ended");

    wait 0.35;

    nearCount = 0;
    startTime = gettime();

    for (;;)
    {
        if (!isAlive(self) || !isDefined(self.origin))
        {
            wait 0.10;
            continue;
        }

        start = (self.origin[0], self.origin[1], self.origin[2] + 60);
        end = (self.origin[0], self.origin[1], self.origin[2] - 20000);

        tr = bullettrace(start, end, 0, self);

        if (isDefined(tr) && isDefined(tr["position"]))
        {
            hit = tr["position"];
            dz = abs(self.origin[2] - hit[2]);

            if (dz < 90)
                nearCount++;
            else
                nearCount = 0;

            if (nearCount >= 6)
                return;
        }
        else
        {
            nearCount++;
            if (nearCount >= 10)
                return;
        }

        if (gettime() - startTime > 45000)
            return;

        wait 0.10;
    }
}

IsHighAltitudeInsertion()
{
    if (!isDefined(self.origin))
        return false;

    if (self.origin[2] > 12000)
        return true;

    return false;
}

IsLandedStable()
{
    if (!isAlive(self) || !isDefined(self.origin))
        return false;

    start = (self.origin[0], self.origin[1], self.origin[2] + 60);
    end = (self.origin[0], self.origin[1], self.origin[2] - 20000);

    tr = bullettrace(start, end, 0, self);
    if (!isDefined(tr) || !isDefined(tr["position"]))
        return false;

    hit = tr["position"];
    dz = abs(self.origin[2] - hit[2]);

    if (dz < 90)
        return true;

    return false;
}

AutoRespawnLoop()
{
    self endon("disconnect");
    level endon("game_ended");

    if (isDefined(self.bo_auto_respawn))
        return;
    self.bo_auto_respawn = true;

    if (!isDefined(self.bo_last_alive_time))
        self.bo_last_alive_time = gettime();

    for (;;)
    {
        wait 0.20;

        if (!isDefined(self) || !isPlayer(self))
            continue;

        if (isAlive(self))
            self.bo_last_alive_time = gettime();

        badState =
            (!isAlive(self)) || IsDownedLike(self) ||
            (isDefined(self.sessionstate) && self.sessionstate != "playing");

        if (badState)
        {
            wait 0.25;

            t0 = gettime();
            while (((!isAlive(self)) || IsDownedLike(self) || (isDefined(self.sessionstate) && self.sessionstate != "playing")) && gettime() - t0 < 14000)
            {
                self bottapbutton(3);
                wait 0.10;
                self bottapbutton(3);
                wait 0.10;

                if (randomint(100) < 35) self bottapbutton(4);
                if (randomint(100) < 20) self bottapbutton(10);

                wait 0.10;
            }

            if (isAlive(self))
            {
                self thread ForceJumpOutAfterRespawn();
                wait 0.25;
            }

            continue;
        }

        if (self isinvehicle() || (isDefined(self.bo_insertion_active) && self.bo_insertion_active))
        {
            self disableweapons();
            self InsertionDisarmCombat();

            self TryForceJumpOut();

            wait 0.20;
            continue;
        }

        if (IsLandedStable())
            self enableweapons();
    }
}

ForceJumpOutAfterRespawn()
{
    self endon("disconnect");
    self endon("death");
    level endon("game_ended");

    wait 0.25;
    if (IsEscapeMap() && HasDeathCircle()) self ForceRecommitPOI("redeploy");

    t0 = gettime();
    while (gettime() - t0 < 14000)
    {
        if (self isonground() && !IsHighAltitudeInsertion())
            break;

        self InsertionDisarmCombat();

        self TryForceJumpOut();

        self bottapbutton(4);
        self bottapbutton(7);
        self bottapbutton(7);

        wait 0.10;
    }
}

InsertionStuckRescueLoop()
{
    self endon("disconnect");
    self endon("death");
    level endon("game_ended");

    t0 = gettime();

    lastZ = isDefined(self.origin) ? self.origin[2] : 0;
    lastZTime = gettime();
    staleZMs = 0;

    for (;;)
    {
        if (!isAlive(self) || !isDefined(self.origin))
        {
            wait 0.25;
            continue;
        }

        if (IsLandedStable() && !IsHighAltitudeInsertion())
            return;

        start = (self.origin[0], self.origin[1], self.origin[2] + 60);
        end = (self.origin[0], self.origin[1], self.origin[2] - 20000);

        tr = bullettrace(start, end, 0, self);

        if (!isDefined(tr) || !isDefined(tr["position"]))
        {
            wait 0.25;
            continue;
        }

        hit = tr["position"];
        dzToGround = abs(self.origin[2] - hit[2]);

        zNow = self.origin[2];

        if (abs(zNow - lastZ) < 18)
            staleZMs += (gettime() - lastZTime);
        else
            staleZMs = 0;

        lastZ = zNow;
        lastZTime = gettime();

        stuckHigh = (dzToGround > 2200);
        tooLong = (gettime() - t0 > 18000);
        notMovingDown = (staleZMs > 3500);

        if (stuckHigh && (tooLong || notMovingDown))
        {
            fallback = undefined;

            if (HasDeathCircle())
                fallback = NavSnap(level.deathcircle.origin);

            if (!isDefined(fallback))
                fallback = PickPOIInsideCircle();

            fallback = FixBadSpawnLocation(fallback);

            if (isDefined(fallback))
            {
                self setorigin(fallback);

                self.bo_search_goal = PickGoalNear(fallback, 900);
                self.bo_next_goal_time = gettime() + randomintRange(2500, 4500);
                self.bo_goal_last_dist = 999999999;
                self.bo_goal_last_progress_time = gettime();

                self.bo_gas_enter_time = undefined;

                wait 0.10;
                self EnsureArmedImmediate();
            }

            return;
        }

        wait 0.25;
    }
}

InsertionJumpOutRescueLoop()
{
    self endon("disconnect");
    self endon("death");
    level endon("game_ended");

    t0 = gettime();
    wasInVehicle = false;
    lastInVeh = false;

    for (;;)
    {
        if (!isAlive(self) || !isDefined(self.origin))
        {
            wait 0.25;
            continue;
        }

        if (IsLandedStable() && !IsHighAltitudeInsertion())
            return;

        inVeh = (self isinvehicle() || (isDefined(self.bo_insertion_active) && self.bo_insertion_active) || IsHighAltitudeInsertion());
        if (inVeh)
            wasInVehicle = true;

        dzToGround = 0;
        start = (self.origin[0], self.origin[1], self.origin[2] + 60);
        end = (self.origin[0], self.origin[1], self.origin[2] - 20000);
        tr = bullettrace(start, end, 0, self);
        if (isDefined(tr) && isDefined(tr["position"]))
            dzToGround = abs(self.origin[2] - tr["position"][2]);

        stuckHigh = (dzToGround > 1600);

        if (inVeh)
        {
            self InsertionDisarmCombat();

            if (stuckHigh)
            {
                self TryForceJumpOut();
                self TryForceJumpOut();
                wait 0.10;
                self TryForceJumpOut();
            }
            else
            {
                if (gettime() - t0 > 1500)
                    self TryForceJumpOut();
            }
        }

        if (wasInVehicle && !inVeh && lastInVeh)
        {
            wait 0.35;
            self EnsureArmedImmediate();
            return;
        }

        lastInVeh = inVeh;

        if (gettime() - t0 > 14000)
        {
            return;
        }

        wait 0.20;
    }
}

IsAirborneOrInsertion()
{
    if (!isAlive(self) || !isDefined(self.origin))
        return true;

    if (self isinvehicle())
        return true;

    if (isDefined(self.bo_insertion_active) && self.bo_insertion_active)
        return true;

    dz = GetDzToGroundSafe(self);

    if (dz >= 9000000)
        return false;

    if (dz > 1200)
        return true;

    if (!IsLandedStable())
        return true;

    return false;
}

