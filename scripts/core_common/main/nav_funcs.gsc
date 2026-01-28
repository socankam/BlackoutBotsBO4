IsBadAnchorEnt(ent)
{
    if (!isDefined(ent) || !isAlive(ent) || !isDefined(ent.origin))
        return true;

    if (IsActuallySwimmingOrWater(ent))
        return true;

    if (IsWaterNear(ent.origin, 650))
        return true;

    start = (ent.origin[0], ent.origin[1], ent.origin[2] + 60);
    end = (ent.origin[0], ent.origin[1], ent.origin[2] - 20000);
    tr = bullettrace(start, end, 0, ent);
    if (!isDefined(tr) || !isDefined(tr["position"]))
        return true;

    dz = abs(ent.origin[2] - tr["position"][2]);
    if (dz > 180)
        return true;

    return false;
}

IsBadLandCandidate(pos)
{
    if (!isDefined(pos))
        return true;

    if (IsBadLandingPos(pos))
        return true;

    if (IsWaterNear(pos, 650))
        return true;

    return false;
}

IsActuallySwimmingOrWater(ent)
{
    if (!isDefined(ent)) ent = self;
    if (!isDefined(ent.origin)) return false;

    if (ent isplayerswimming())
        return true;

    if (IsWaterAt(ent.origin) || IsWaterNear(ent.origin, 260))
        return true;

    return false;
}

PickNearestDryLandGoal(fromPos)
{
    if (!isDefined(fromPos))
        return undefined;

    land = FindNearestDryNavFrom(fromPos);
    land = FixBadSpawnLocation(land);

    if (isDefined(land) && !IsBadLandingPos(land) && !IsWaterNear(land, 520))
        return land;

    poi = PickClosestPOIInsideStorm(fromPos);
    poi = FixBadSpawnLocation(poi);

    if (isDefined(poi) && !IsBadLandingPos(poi) && !IsWaterNear(poi, 520))
        return poi;

    if (HasDeathCircle())
    {
        g = GetCircleSafeGoal();
        g = FixBadSpawnLocation(g);
        if (isDefined(g) && !IsBadLandingPos(g) && !IsWaterNear(g, 520))
            return g;

        c = FixBadSpawnLocation(level.deathcircle.origin);
        if (isDefined(c) && !IsBadLandingPos(c) && !IsWaterNear(c, 520))
            return c;
    }

    return undefined;
}

SwimToLand(dest, maxMs)
{
    self endon("disconnect");
    self endon("death");
    level endon("game_ended");

    if (!isDefined(maxMs))
        maxMs = 9000;

    if (!isDefined(dest))
        return false;

    dest = FixBadSpawnLocation(dest);
    if (!isDefined(dest))
        return false;

    t0 = gettime();
    lastUp = 0;
    lastDown = 0;

    for (;;)
    {
        if (!isAlive(self) || !isDefined(self.origin))
            return false;

        if (!IsActuallySwimmingOrWater(self) && IsLandedStable() && !IsWaterNear(self.origin, 220))
            return true;

        if (gettime() - t0 > maxMs)
            return false;

        g = NavSnap(dest);
        if (!isDefined(g))
            g = dest;

        self clearentitytarget();
        self botsetmovepoint(g);
        self botsetmovemagnitude(1.0);

        dir = vectorNormalize(g - self.origin);
        yaw = vectortoangles(dir)[1];

        self botsetmoveangles((0, yaw, 0));
        self botsetlookangles((-25, yaw, 0));

        if (gettime() - lastUp > 120)
        {
            lastUp = gettime();
            self bottapbutton(BO_SWIM_UP());
        }

        if (randomint(100) < 6 && gettime() - lastDown > 900)
        {
            lastDown = gettime();
            self bottapbutton(BO_SWIM_DOWN());
        }

        wait 0.10;
    }

    return false;
}

SafeRandomFloatRange(a, b)
{
    if (!isDefined(a) || !isDefined(b))
        return 0;

    if (b <= a)
        return float(a);

    return randomFloatRange(a, b);
}

IsBlockedAheadWide(dist)
{
    if (!isDefined(dist))
        dist = 110;

    if (!isDefined(self.origin) || !isDefined(self.angles))
        return false;

    fwd = anglesToForward((0, self.angles[1], 0));
    rx = 0.0 - fwd[1];
    ry = fwd[0];

    lane = array((0,0,0), (rx * 22, ry * 22, 0), (rx * -22, ry * -22, 0));

    for (i = 0; i < lane.size; i++)
    {
        o = lane[i];

        start = (self.origin[0] + o[0], self.origin[1] + o[1], self.origin[2] + 56);
        end = (start[0] + fwd[0] * dist, start[1] + fwd[1] * dist, start[2]);

        tr = bullettrace(start, end, 0, self);
        if (isDefined(tr) && isDefined(tr["fraction"]) && tr["fraction"] < 0.82)
            return true;
    }

    start2 = (self.origin[0], self.origin[1], self.origin[2] + 18);
    end2   = (start2[0] + fwd[0] * dist, start2[1] + fwd[1] * dist, start2[2]);

    tr2 = bullettrace(start2, end2, 0, self);
    if (isDefined(tr2) && isDefined(tr2["fraction"]) && tr2["fraction"] < 0.82)
        return true;

    return false;
}

StartGoalProgress(goal, key)
{
    if (!isDefined(key)) key = "bo_prog";

    if (!isDefined(goal) || !isDefined(self.origin))
        return;

    self[key + "_goal"] = goal;
    self[key + "_dist"] = distanceSquared(self.origin, goal);
    self[key + "_time"] = gettime();
    self[key + "_fails"] = 0;

    if (!isDefined(self[key + "_lastPos"]))
        self[key + "_lastPos"] = self.origin;

    self[key + "_lastPosTime"] = gettime();
}

GoalProgressFailing(goal, key, graceMs, minImproveSq)
{
    if (!isDefined(key))
        key = "bo_prog";
    if (!isDefined(graceMs))
        graceMs = 900;
    if (!isDefined(minImproveSq))
        minImproveSq = 160 * 160;

    if (!isDefined(goal) || !isDefined(self.origin))
        return false;

    if (!isDefined(self[key + "_time"]))
        return true;

    g0 = self[key + "_goal"];
    if (!isDefined(g0) || distanceSquared(g0, goal) > (220 * 220))
    {
        self StartGoalProgress(goal, key);
        return false;
    }

    dt = gettime() - self[key + "_time"];
    if (dt < graceMs)
        return false;

    dNow = distanceSquared(self.origin, goal);
    dWas = self[key + "_dist"];

    improved = (dWas - dNow);

    movedSq = 0;
    if (isDefined(self[key + "_lastPos"]))
        movedSq = distanceSquared(self.origin, self[key + "_lastPos"]);

    if (gettime() - self[key + "_lastPosTime"] > 650)
    {
        self[key + "_lastPos"] = self.origin;
        self[key + "_lastPosTime"] = gettime();
    }

    if (improved < minImproveSq || movedSq < (28 * 28))
    {
        self[key + "_fails"]++;
        self[key + "_dist"] = dNow;
        self[key + "_time"] = gettime();
        return true;
    }

    self[key + "_fails"] = 0;
    self[key + "_dist"] = dNow;
    self[key + "_time"] = gettime();
    return false;
}

AllowHardTeleport()
{
    if (!isDefined(self.bo_hardtp_until))
        self.bo_hardtp_until = 0;

    if (gettime() > self.bo_hardtp_until)
        return false;

    return IsEmergencyBrokenPos();
}

IsEmergencyBrokenPos()
{
    if (!isDefined(self.origin))
        return true;

    if (self.origin[2] < -8000)
        return true;

    dz = GetDzToGroundSafe(self);
    if (dz >= 9000000)
        return true;

    return false;
}

ClampInt(val, lo, hi)
{
    if (!isDefined(val)) return int(lo);

    v = int(val);
    if (v < int(lo)) return int(lo);
    if (v > int(hi)) return int(hi);

    return v;
}

NoGroundAt(pos)
{
    if (!isDefined(pos))
        return true;

    start = (pos[0], pos[1], pos[2] + 128);
    end = (pos[0], pos[1], pos[2] - 20000);

    tr = bullettrace(start, end, 0, self);

    if (!isDefined(tr))
        return true;

    if (!isDefined(tr["fraction"]) || tr["fraction"] >= 0.999)
        return true;

    if (!isDefined(tr["position"]))
        return true;

    return false;
}

TryForceJumpOut()
{
    self BotHoldButton(3, 1.35);

    self bottapbutton(3);
    self bottapbutton(3);

    self bottapbutton(4);
    if (randomint(100) < 65) self bottapbutton(10);

    self bottapbutton(7);
    if (randomint(100) < 55) self bottapbutton(7);
}

WaterOrOutOfMapRescueLoop()
{
    self endon("disconnect");
    self endon("death");
    level endon("game_ended");

    self.bo_rescue_next_time = 0;

    if (!isDefined(self.bo_bad_water_since))
        self.bo_bad_water_since = 0;

    if (!isDefined(self.bo_bad_nonav_since))
        self.bo_bad_nonav_since = 0;

    if (!isDefined(self.bo_hardtp_until))
        self.bo_hardtp_until = 0;

    for (;;)
    {
        if (!isAlive(self) || !isDefined(self.origin))
        {
            wait 0.25;
            continue;
        }

        dzToGround = GetDzToGroundSafe(self);
        if (!IsLandedStable() && (self isinvehicle() || dzToGround > 1400))
        {
            wait 0.25;
            continue;
        }

        if (gettime() < self.bo_rescue_next_time)
        {
            wait 0.20;
            continue;
        }

        self.bo_rescue_next_time = gettime() + 450;

        pos = self.origin;

        inWater = IsActuallySwimmingOrWater(self);
        nav = getclosestpointonnavmesh(pos, 256, 16);
        noNav = !isDefined(nav);

        if (inWater)
        {
            if (self.bo_bad_water_since == 0) self.bo_bad_water_since = gettime();
        }
        else self.bo_bad_water_since = 0;

        if (noNav)
        {
            if (self.bo_bad_nonav_since == 0) self.bo_bad_nonav_since = gettime();
        }
        else self.bo_bad_nonav_since = 0;

        if (!inWater && !noNav)
        {
            wait 0.25;
            continue;
        }

        if (inWater)
        {
            dest = PickNearestDryLandGoal(pos);
            if (isDefined(dest))
            {
                self thread SwimToLand(dest, 8500);
                wait 0.25;
                continue;
            }
        }

        land = FindNearestDryNavFrom(pos);
        land = FixBadSpawnLocation(land);

        if (isDefined(land) && !IsBadLandingPos(land) && !IsWaterNear(land, 320))
        {
            self clearentitytarget();
            self botsetmovepoint(land);
            self botsetmovemagnitude(1.0);

            wait 3.25;
        }

        badLong = (self.bo_bad_water_since != 0 && (gettime() - self.bo_bad_water_since) > 9000) || (self.bo_bad_nonav_since != 0 && (gettime() - self.bo_bad_nonav_since) > 9000);

        if (badLong && AllowHardTeleport())
        {
            fallback = PickLocalEmergencyRescuePos(pos);

            if (isDefined(fallback))
            {
                self setorigin(fallback);

                self.bo_search_goal = PickGoalNear(fallback, 900);
                self.bo_next_goal_time = gettime() + randomintRange(2500, 4500);
                self.bo_goal_last_dist = 999999999;
                self.bo_goal_last_progress_time = gettime();

                self.bo_bad_water_since = 0;
                self.bo_bad_nonav_since = 0;

                wait 0.25;
            }
        }

        wait 0.25;
    }
}

IsLandPlayable(pos)
{
    if (!isDefined(pos))
        return false;

    if (pos[2] < -2500)
        return false;

    nav = getclosestpointonnavmesh(pos, 512, 24);
    if (!isDefined(nav))
        return false;

    gs = GroundSnap(nav);
    if (!isDefined(gs))
        return false;

    if (NoGroundAt(gs))
        return false;

    if (IsWaterAt(gs))
        return false;

    if (HasDeathCircle() && !IsPosInsideCircle(gs))
        return false;

    return true;
}

IsBadLandingPos(pos)
{
    if (!isDefined(pos))
        return true;

    if (pos[2] < -2500)
        return true;

    nav = getclosestpointonnavmesh(pos, 384, 24);
    if (!isDefined(nav))
        return true;

    gs = GroundSnap(nav);
    if (!isDefined(gs))
        return true;

    if (NoGroundAt(gs))
        return true;

    if (IsWaterAt(gs))
        return true;

    if (IsWaterNear(gs, 900))
        return true;

    if (HasDeathCircle() && !IsPosInsideCircle(gs))
        return true;

    if (abs(gs[2] - nav[2]) > 900)
        return true;

    return false;
}

FixBadSpawnLocation(desired)
{
    if (!isDefined(desired))
        return undefined;

    if (HasDeathCircle())
    {
        c = IsEscapeMap() ? GetLandBiasedCircleCenter() : level.deathcircle.origin;
        if (!isDefined(c)) c = level.deathcircle.origin; r = level.deathcircle.radius;

        if (!IsPosInsideCircle(desired))
        {
            vx = desired[0] - c[0];
            vy = desired[1] - c[1];

            if (abs(vx) > 1 || abs(vy) > 1)
            {
                dir = vectorNormalize((vx, vy, 0));
                safeR = r - 900;

                if (safeR < 600) safeR = r * 0.60;
                if (safeR < 250) safeR = 250;

                desired = (c[0] + dir[0] * safeR, c[1] + dir[1] * safeR, c[2]);
            }
            else
            {
                desired = c;
            }
        }
    }

    base = NavSnap(desired);
    if (isDefined(base) && !IsBadLandCandidate(base))
        return base;

    for (ring = 0; ring < 9; ring++)
    {
        minR = 250 + (ring * 280);
        maxR = 650 + (ring * 420);
        if (maxR <= minR) maxR = minR + 1;

        for (i = 0; i < 34; i++)
        {
            ang = randomFloatRange(0, 360);
            rr = SafeRandomFloatRange(minR, maxR);
            fwd = anglesToForward((0, ang, 0));

            p = (desired[0] + fwd[0] * rr, desired[1] + fwd[1] * rr, desired[2]);
            p = NavSnap(p);

            if (!isDefined(p))
                continue;

            if (IsBadLandCandidate(p))
                continue;

            if (MinDistSqToOtherBots(p) < (850 * 850))
                continue;

            return p;
        }
    }

    if (HasDeathCircle())
    {
        c = level.deathcircle.origin;
        r = level.deathcircle.radius;

        minCircleR = 650;
        maxCircleR = r - 1100;

        if (maxCircleR > minCircleR)
        {
            for (k = 0; k < 70; k++)
            {
                ang = randomFloatRange(0, 360);
                rr  = SafeRandomFloatRange(minCircleR, maxCircleR);
                fwd = anglesToForward((0, ang, 0));

                cand = (c[0] + fwd[0] * rr, c[1] + fwd[1] * rr, c[2]);
                cand = NavSnap(cand);

                if (!isDefined(cand))
                    continue;

                if (IsBadLandCandidate(cand))
                    continue;

                if (MinDistSqToOtherBots(cand) < (850 * 850))
                    continue;

                return cand;
            }
        }

        center = NavSnap(c);
        if (isDefined(center) && !IsBadLandCandidate(center))
            return center;
    }

    return undefined;
}

SpawnSanityRescueLoop()
{
    self endon("disconnect");
    self endon("death");
    level endon("game_ended");

    endTime = gettime() + 20000;

    if (!isDefined(self.bo_spawn_bad_since))
        self.bo_spawn_bad_since = 0;

    if (!isDefined(self.bo_nonav_since))
        self.bo_nonav_since = 0;

    if (!isDefined(self.bo_hardtp_until))
        self.bo_hardtp_until = 0;

    for (;;)
    {
        if (isDefined(self.bo_insertion_active) && self.bo_insertion_active)
        {
            wait 0.25;
            continue;
        }

        if (gettime() > endTime)
            return;

        if (!isAlive(self) || !isDefined(self.origin))
        {
            wait 0.25;
            continue;
        }

        dzToGround = GetDzToGroundSafe(self);
        if (!IsLandedStable() && (self isinvehicle() || dzToGround > 1800))
        {
            wait 0.25;
            continue;
        }

        nav = getclosestpointonnavmesh(self.origin, 256, 16);
        noNav = !isDefined(nav);

        if (noNav)
        {
            if (self.bo_nonav_since == 0)
                self.bo_nonav_since = gettime();
        }
        else
        {
            self.bo_nonav_since = 0;
        }

        noNavLong = (self.bo_nonav_since != 0 && (gettime() - self.bo_nonav_since) > 6000);

        bad = (self.origin[2] < -5000) || NoGroundAt(self.origin) || IsWaterAt(self.origin) || noNavLong;

        if (!bad)
        {
            self.bo_spawn_bad_since = 0;
            wait 0.50;
            continue;
        }

        if (self.bo_spawn_bad_since == 0)
            self.bo_spawn_bad_since = gettime();

        land = FindNearestDryNavFrom(self.origin);
        if (isDefined(land))
        {
            self clearentitytarget();
            self botsetmovepoint(land);
            self botsetmovemagnitude(1.0);

            wait 1.25;

            nav2 = getclosestpointonnavmesh(self.origin, 256, 16);
            if (isDefined(nav2) && !IsWaterAt(self.origin) && !NoGroundAt(self.origin))
            {
                self.bo_spawn_bad_since = 0;
                self.bo_nonav_since = 0;
                wait 0.25;
                continue;
            }
        }

        if ((gettime() - self.bo_spawn_bad_since) > 6500 && AllowHardTeleport())
        {
            fallback = PickLocalEmergencyRescuePos(self.origin);

            if (isDefined(fallback))
            {
                self setorigin(fallback);

                self.bo_search_goal = PickGoalNear(fallback, 900);
                self.bo_next_goal_time = gettime() + randomintRange(2500, 4500);
                self.bo_goal_last_dist = 999999999;
                self.bo_goal_last_progress_time = gettime();

                self.bo_spawn_bad_since = 0;
                self.bo_nonav_since = 0;
            }
        }

        wait 0.50;
    }
}

PickBestNavGoalNear(center, radius, samples)
{
    best = undefined;

    if (!isDefined(samples))
        samples = 8;

    for (i = 0; i < samples; i++)
    {
        offX = randomFloatRange(0 - radius, radius);
        offY = randomFloatRange(0 - radius, radius);
        candidate = (center[0] + offX, center[1] + offY, center[2]);

        snapped = NavSnap(candidate);
        if (!isDefined(snapped))
            continue;

        if (distanceSquared(snapped, center) < (140 * 140))
            continue;

        if (distanceSquared(snapped, center) > ((radius * 1.35) * (radius * 1.35)))
            continue;

        best = snapped;
        break;
    }

    if (!isDefined(best))
        best = NavSnap(center);

    return best;
}

PickGoalNear(center, radius)
{
    return PickBestNavGoalNear(center, radius, 10);
}

PickSearchSpiralGoal(center, baseRadius)
{
    if (!isDefined(baseRadius)) baseRadius = 650;

    ang = randomFloatRange(0, 360);
    r = randomFloatRange(baseRadius * 0.55, baseRadius * 1.15);
    fwd = anglesToForward((0, ang, 0));

    pos = (center[0] + fwd[0] * r, center[1] + fwd[1] * r, center[2]);
    return NavSnap(pos);
}

GetRandomAliveEntityInsideCircle()
{
    list = array();
    players = getplayers();

    foreach (p in players)
    {
        if (!isDefined(p) || !isAlive(p) || p == self || !isDefined(p.origin))
            continue;

        if (!IsPosInsideCircle(p.origin))
            continue;

        if (IsBadAnchorEnt(p))
            continue;

        list[list.size] = p;
    }

    if (list.size <= 0)
        return undefined;

    return list[randomint(list.size)];
}

IsWaterNear(pos, radius)
{
    if (!isDefined(pos))
        return true;

    if (!isDefined(radius))
        radius = 220;

    negRadius = 0 - radius;
    half = int(radius * 0.5);
    negHalf = 0 - half;

    offs = array((0,0,0),(radius,0,0), (negRadius,0,0), (0,radius,0), (0,negRadius,0),(radius,radius,0), (radius,negRadius,0), (negRadius,radius,0), (negRadius,negRadius,0),(half,0,0), (negHalf,0,0), (0,half,0), (0,negHalf,0), (half,half,0), (half,negHalf,0), (negHalf,half,0), (negHalf,negHalf,0));

    foreach (o in offs)
    {
        p = (pos[0] + o[0], pos[1] + o[1], pos[2]);
        if (IsWaterAt(p))
            return true;
    }

    return false;
}

FindDryRedirectFromHere()
{
    if (!isDefined(self.origin))
        return undefined;

    dry = FindNearestDryNavFrom(self.origin);
    if (isDefined(dry) && !IsWaterNear(dry, 260) && !IsBadLandingPos(dry))
        return dry;

    fromNow = self.origin;
    poi = PickDryPOIInsideStorm(fromNow, isDefined(self.bo_bot_index) ? self.bo_bot_index : randomint(9999));
    if (isDefined(poi) && !IsWaterNear(poi, 320) && !IsBadLandingPos(poi))
        return poi;

    if (HasDeathCircle())
    {
        c = FixBadSpawnLocation(level.deathcircle.origin);
        if (isDefined(c) && !IsWaterNear(c, 320) && !IsBadLandingPos(c))
            return c;
    }

    return undefined;
}

TeleportNearEntity(ent)
{
    if (!isDefined(ent) || !isDefined(ent.origin) || !isAlive(self))
        return;

    minR = 450;
    maxR = 950;

    for (i = 0; i < 16; i++)
    {
        ang = randomFloatRange(0, 360);
        r = randomFloatRange(minR, maxR);

        fwd = anglesToForward((0, ang, 0));
        pos = (ent.origin[0] + fwd[0] * r, ent.origin[1] + fwd[1] * r, ent.origin[2]);

        pos = FixBadSpawnLocation(pos);
        if (!isDefined(pos))
            continue;

        if (distanceSquared(pos, ent.origin) < (280 * 280))
            continue;

        if (HasDeathCircle() && !IsPosInsideCircle(pos))
            continue;

        self setorigin(pos);
        return;
    }

    pos = FixBadSpawnLocation(ent.origin);
    if (isDefined(pos))
        self setorigin(pos);
}

MinDistSqToAnyPlayer(pos)
{
    if (!isDefined(pos))
        return 0;

    best = 999999999;
    players = getplayers();

    foreach (p in players)
    {
        if (!isDefined(p) || !isAlive(p) || !isDefined(p.origin))
            continue;

        d = distanceSquared(pos, p.origin);
        if (d < best)
            best = d;
    }

    return best;
}

FindFarNavPointFromPlayers(samples, minDist)
{
    if (!isDefined(samples))
        samples = 24;

    if (!isDefined(minDist))
        minDist = 2200;

    minDistSq = minDist * minDist;

    center = (isDefined(level.deathcircle) && isDefined(level.deathcircle.origin)) ? level.deathcircle.origin : self.origin;
    safeRad = (isDefined(level.deathcircle) && isDefined(level.deathcircle.radius)) ? level.deathcircle.radius : 12000;

    best = undefined;
    bestScore = -1;

    for (i = 0; i < samples; i++)
    {
        ang = randomFloatRange(0, 360);
        maxR = safeRad - 600;
        if (maxR <= 1200) maxR = 1201;
        r = SafeRandomFloatRange(1200, maxR);

        fwd = anglesToForward((0, ang, 0));
        candidate = (center[0] + fwd[0] * r, center[1] + fwd[1] * r, center[2]);

        candidate = NavSnap(candidate);
        if (!isDefined(candidate))
            continue;

        dSq = MinDistSqToAnyPlayer(candidate);

        if (dSq < minDistSq)
            continue;

        if (dSq > bestScore)
        {
            bestScore = dSq;
            best = candidate;
        }
    }

    return best;
}

IsBlockedAhead(dist)
{
    if (!isDefined(dist))
        dist = 96;

    if (!isDefined(self.origin) || !isDefined(self.angles))
        return false;

    fwd = anglesToForward((0, self.angles[1], 0));

    start1 = (self.origin[0], self.origin[1], self.origin[2] + 56);
    end1   = (start1[0] + fwd[0] * dist, start1[1] + fwd[1] * dist, start1[2]);

    start2 = (self.origin[0], self.origin[1], self.origin[2] + 18);
    end2   = (start2[0] + fwd[0] * dist, start2[1] + fwd[1] * dist, start2[2]);

    tr1 = bullettrace(start1, end1, 0, self);
    tr2 = bullettrace(start2, end2, 0, self);

    if (isDefined(tr1) && isDefined(tr1["fraction"]) && tr1["fraction"] < 0.80)
        return true;

    if (isDefined(tr2) && isDefined(tr2["fraction"]) && tr2["fraction"] < 0.80)
        return true;

    return false;
}

BreakWallContactAndRepath(goal)
{
    if (!isDefined(self.origin))
        return;

    if (!isDefined(self.bo_last_wall_repath_time))
        self.bo_last_wall_repath_time = 0;

    if (gettime() - self.bo_last_wall_repath_time < 1100)
        return;

    self.bo_last_wall_repath_time = gettime();

    fwd = anglesToForward((0, self.angles[1], 0));
    rx = 0.0 - fwd[1];
    ry = fwd[0];

    backDist = randomFloatRange(120, 210);
    back = (self.origin[0] - fwd[0] * backDist, self.origin[1] - fwd[1] * backDist, self.origin[2]);
    back = NavSnap(back);

    if (isDefined(back))
    {
        self botsetmovepoint(back);
        self botsetmovemagnitude(1.0);
    }

    wait 0.10;

    side = (randomint(2) == 0) ? 1 : -1;
    sideDist = randomFloatRange(260, 420) * float(side);

    step = (self.origin[0] + rx * sideDist, self.origin[1] + ry * sideDist, self.origin[2]);
    step = NavSnap(step);

    if (isDefined(step))
    {
        self botsetmovepoint(step);
        self botsetmovemagnitude(1.0);
    }

    if (randomint(100) < 70)
        self bottapbutton(10);

    if (isDefined(goal))
    {
        newGoal = PickGoalNear(goal, 1200);
        if (isDefined(newGoal))
        {
            self.bo_search_goal = newGoal;
            self botsetmovepoint(newGoal);
            self botsetmovemagnitude(1.0);
        }
    }

    self.bo_goal_last_progress_time = gettime();
    self.bo_goal_last_dist = 999999999;
}

UnstuckCheck(goal)
{
    if (!isDefined(goal) || !isDefined(self.origin))
        return;

    if (!isDefined(self.bo_goal_last_dist))
        self.bo_goal_last_dist = 999999999;

    if (!isDefined(self.bo_goal_last_progress_time))
        self.bo_goal_last_progress_time = gettime();

    if (!isDefined(self.bo_wall_stuck_time))
        self.bo_wall_stuck_time = gettime();

    if (!isDefined(self.bo_wall_last_origin))
        self.bo_wall_last_origin = self.origin;

    dSq = distanceSquared(self.origin, goal);

    if (IsBlockedAhead(96))
    {
        BreakWallContactAndRepath(goal);
        self.bo_goal_last_progress_time = gettime();
        self.bo_goal_last_dist = 999999999;
        self.bo_wall_stuck_time = gettime();
        self.bo_wall_last_origin = self.origin;
        return;
    }

    if (dSq + (120 * 120) < self.bo_goal_last_dist)
    {
        self.bo_goal_last_dist = dSq;
        self.bo_goal_last_progress_time = gettime();
        self.bo_wall_stuck_time = gettime();
        self.bo_wall_last_origin = self.origin;
        return;
    }

    movedSq = distanceSquared(self.origin, self.bo_wall_last_origin);

    if (movedSq > (35 * 35))
    {
        if (gettime() - self.bo_wall_stuck_time > 1800)
        {
            BreakWallContactAndRepath(goal);
            self.bo_goal_last_progress_time = gettime();
            self.bo_goal_last_dist = 999999999;
            self.bo_wall_stuck_time = gettime();
            self.bo_wall_last_origin = self.origin;
            return;
        }

        self.bo_wall_last_origin = self.origin;
    }

    if (gettime() - self.bo_goal_last_progress_time > 2250)
    {
        dir = vectorNormalize(goal - self.origin);

        rx = 0.0 - dir[1];
        ry = dir[0];

        side = (randomint(2) == 0) ? 1 : -1;
        dist = 260.0 * float(side);

        nudge = (self.origin[0] + (rx * dist), self.origin[1] + (ry * dist), self.origin[2]);
        nudge = NavSnap(nudge);

        if (isDefined(nudge))
        {
            self botsetmovepoint(nudge);
            self botsetmovemagnitude(1.0);
        }

        self bottapbutton(10);

        self.bo_goal_last_progress_time = gettime();
        self.bo_goal_last_dist = 999999999;
        self.bo_wall_stuck_time = gettime();
        self.bo_wall_last_origin = self.origin;
    }
}

FindNearestDryNavFrom(pos)
{
    if (!isDefined(pos))
        return undefined;

    base = NavSnap(pos);
    if (isDefined(base) && !IsBadLandingPos(base))
        return base;

    for (ring = 0; ring < 7; ring++)
    {
        minR = 250 + (ring * 350);
        maxR = 550 + (ring * 450);

        for (i = 0; i < 18; i++)
        {
            ang = randomFloatRange(0, 360);
            r = randomFloatRange(minR, maxR);
            fwd = anglesToForward((0, ang, 0));

            cand = (pos[0] + fwd[0] * r, pos[1] + fwd[1] * r, pos[2]);
            cand = NavSnap(cand);

            if (!isDefined(cand))
                continue;

            if (IsBadLandingPos(cand))
                continue;

            return cand;
        }
    }

    if (HasDeathCircle())
    {
        c = level.deathcircle.origin;

        for (k = 0; k < 22; k++)
        {
            ang = randomFloatRange(0, 360);
            maxR = level.deathcircle.radius - 700;
            if (maxR <= 600) maxR = 601;
            r = SafeRandomFloatRange(600, maxR);
            fwd = anglesToForward((0, ang, 0));

            cand = (c[0] + fwd[0] * r, c[1] + fwd[1] * r, c[2]);
            cand = NavSnap(cand);

            if (!isDefined(cand))
                continue;

            if (IsBadLandingPos(cand))
                continue;

            return cand;
        }
    }
    return undefined;
}

PickLocalEmergencyRescuePos(fromPos)
{
    if (!isDefined(fromPos))
        return undefined;

    local = FindNearestDryNavFrom(fromPos);
    local = FixBadSpawnLocation(local);

    if (!isDefined(local))
    {
        for (i = 0; i < 26; i++)
        {
            ang = randomFloatRange(0, 360);
            r = randomFloatRange(350, 1600);
            fwd = anglesToForward((0, ang, 0));

            cand = (fromPos[0] + fwd[0] * r, fromPos[1] + fwd[1] * r, fromPos[2]);
            cand = NavSnap(cand);

            if (!isDefined(cand)) continue;
            if (IsBadLandingPos(cand)) continue;
            if (IsWaterNear(cand, 900)) continue;

            local = cand;
            break;
        }
    }

    if (!isDefined(local))
        local = NavSnap(fromPos);

    if (isDefined(local) && IsBadLandingPos(local))
        return undefined;

    return local;
}

NavSnap(pos)
{
    if (!isDefined(pos))
        return undefined;

    nav = getclosestpointonnavmesh(pos, 384, 24);
    if (isDefined(nav))
    {
        snapped = GroundSnap(nav);
        if (isDefined(snapped))
            return snapped;
        return (nav[0], nav[1], nav[2] + 10);
    }

    return GroundSnap(pos);
}

MinDistSqToOtherBots(pos)
{
    if (!isDefined(pos) || !isDefined(level.BotsInGame))
        return 999999999;

    best = 999999999;

    foreach (b in level.BotsInGame)
    {
        if (!isDefined(b) || b == self || !isDefined(b.origin))
            continue;

        d = distanceSquared(pos, b.origin);
        if (d < best)
            best = d;
    }

    return best;
}

IsWaterAt(pos)
{
    if (!isDefined(pos))
        return true;

    for (i = 0; i < 3; i++)
    {
        up = 128 + (i * 192);
        start = (pos[0], pos[1], pos[2] + up);
        end = (pos[0], pos[1], pos[2] - 20000);

        tr = bullettrace(start, end, 0, self);
        if (!isDefined(tr))
            continue;

        if (!isDefined(tr["fraction"]) || tr["fraction"] >= 0.999)
            continue;

        if (isDefined(tr["surfacetype"]))
        {
            st = tr["surfacetype"];

            if (st == #"water" || st == #"water_shallow" || st == #"water_deep" || st == #"slime")
                return true;

            if (st == "water" || st == "water_shallow" || st == "water_deep" || st == "slime")
                return true;
        }
    }

    return false;
}

InsertionAirSteerWatchdog()
{
    self endon("disconnect");
    self endon("death");
    level endon("game_ended");
    self endon("bo_brain_restart");

    lastDist = 999999999;
    badSince = 0;

    for (;;)
    {
        if (!isDefined(self.bo_insertion_active) || !self.bo_insertion_active)
            return;

        if (!isAlive(self) || !isDefined(self.origin))
        {
            wait 0.15;
            continue;
        }

        if (IsLandedStable() && !IsHighAltitudeInsertion())
            return;

        goal = self GetCurrentPOIObjective();
        if (!isDefined(goal))
        {
            self UpdateDropPOIForThisLife();
            wait 0.20;
            continue;
        }

        if (HasDeathCircle())
            goal = ClampPosInsideCircle(goal, 750);

        airGoal = self GetAirSteerGoal(goal);
        if (!isDefined(airGoal))
        {
            wait 0.20;
            continue;
        }

        d = distance2d(self.origin, airGoal);

        if (IsWaterNear(self.origin, 900))
        {
            from2 = HasDeathCircle() ? level.deathcircle.origin : self.origin;
            self.bo_drop_poi = PickDryPOIInsideStorm(from2, isDefined(self.bo_bot_index) ? self.bo_bot_index : randomint(9999));
        }

        if (d > lastDist + 140)
        {
            if (badSince == 0) badSince = gettime();
        }
        else
        {
            badSince = 0;
        }

        lastDist = d;

        if (badSince != 0 && (gettime() - badSince) > 1400)
        {
            self UpdateDropPOIForThisLife();

            self bottapbutton(7);
            if (randomint(100) < 50) self bottapbutton(7);

            if (self isinvehicle())
            {
                self TryForceJumpOut();
                self TryForceJumpOut();
            }

            badSince = 0;
        }

        wait 0.20;
    }
}