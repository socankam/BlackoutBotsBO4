InitBlackoutPOIs()
{
    map = util::get_map_name();

    if (isDefined(level.bo_pois_inited) && level.bo_pois_inited)
        return;

    level.bo_pois_inited = true;
    level.bo_pois_map = map;
    level.bo_pois = array();

    if (map == "wz_open_skyscrapers")
    {
        level.bo_pois[level.bo_pois.size] = array("asylum", (9904.15, -41700.2, 4013.05));
        level.bo_pois[level.bo_pois.size] = array("buried", (-55217.4, -38466.2, 1996.18));
        level.bo_pois[level.bo_pois.size] = array("dam", (37654.7, -45952.6, 4072.38));
        level.bo_pois[level.bo_pois.size] = array("dock", (-31249, 25237, 1148.13));
        level.bo_pois[level.bo_pois.size] = array("factory", (-40143, -13333, 1366.13));
        level.bo_pois[level.bo_pois.size] = array("firing_range", (12296.2, -2656.55, 1326.5));
        level.bo_pois[level.bo_pois.size] = array("lighthouse", (-45981, 27144, 1240.13));
        level.bo_pois[level.bo_pois.size] = array("nuketown", (-11560, 45393, 1650.82));
        level.bo_pois[level.bo_pois.size] = array("raid", (48010, 5174, 5132.13));
        level.bo_pois[level.bo_pois.size] = array("rivertown", (-2899, -17123, 1308.13));
        level.bo_pois[level.bo_pois.size] = array("array", (4510.68, 17379.9, 4031.51));
        level.bo_pois[level.bo_pois.size] = array("train_station", (26605, -19024, 2015.11));
    }

    if (map == "wz_escape" || map == "wz_escape_alt")
    {
        level.bo_pois[level.bo_pois.size] = array("boat", (-9045, -4126, 117.117));
        level.bo_pois[level.bo_pois.size] = array("docks", (2049, -4510, 144.125));
        level.bo_pois[level.bo_pois.size] = array("island", (-9868, -7088, 199.947));
        level.bo_pois[level.bo_pois.size] = array("main_building", (-70, 419, 1392.13));
        level.bo_pois[level.bo_pois.size] = array("model_industries", (5636, 9464, 1144.13));
        level.bo_pois[level.bo_pois.size] = array("new_industries", (3268, 6574, 527.625));
        level.bo_pois[level.bo_pois.size] = array("submarine", (9503, 5888, 117));
        level.bo_pois[level.bo_pois.size] = array("white_house", (-4057, -4664, 693.125));
    }
}

PickDryPOIInsideStorm(fromPos, botIndex)
{
    InitBlackoutPOIs();

    if (isDefined(level.bo_pois) && level.bo_pois.size > 0)
    {
        startIdx = isDefined(botIndex) ? (int(botIndex) % level.bo_pois.size) : randomint(level.bo_pois.size);
        if (startIdx < 0) startIdx += level.bo_pois.size;

        for (k = 0; k < level.bo_pois.size; k++)
        {
            idx = (startIdx + k) % level.bo_pois.size;

            poi = level.bo_pois[idx];
            if (!isDefined(poi) || poi.size < 2)
                continue;

            pos = poi[1];

            if (HasDeathCircle() && !IsPosInsideCircle(pos)) continue;
            if (HasDeathCircle() && IsEscapeMap() && !IsPOISafeInterior(pos)) continue;

            fixed = FixBadSpawnLocation(pos);

            if (HasDeathCircle() && !IsPosInsideCircle(fixed))
                continue;

            if (!isDefined(fixed))
                continue;

            if (IsBadLandingPos(fixed))
                continue;

            if (IsWaterNear(fixed, 900))
                continue;

            return fixed;
        }
    }

    if (HasDeathCircle())
    {
        c = level.deathcircle.origin;
        r = level.deathcircle.radius;

        for (i = 0; i < 60; i++)
        {
            ang = randomFloatRange(0, 360);
            maxR = r - 900;
            if (maxR <= 350) maxR = 351;
            rr = SafeRandomFloatRange(350, maxR);
            fwd = anglesToForward((0, ang, 0));

            cand = (c[0] + fwd[0] * rr, c[1] + fwd[1] * rr, c[2]);
            cand = FixBadSpawnLocation(cand);

            if (HasDeathCircle() && !IsPosInsideCircle(cand))
                continue;


            if (!isDefined(cand))
                continue;

            if (IsBadLandingPos(cand))
                continue;

            if (IsWaterNear(cand, 900))
                continue;

            return cand;
        }

        c2 = FixBadSpawnLocation(c);
        if (isDefined(c2) && !IsBadLandingPos(c2) && !IsWaterNear(c2, 520))
            return c2;
    }

    return FixBadSpawnLocation(fromPos);
}

HasDeathCircle()
{
    return (isDefined(level.deathcircle) && isDefined(level.deathcircle.origin) && isDefined(level.deathcircle.radius));
}

IsPosInsideCircle(pos)
{
    if (!HasDeathCircle() || !isDefined(pos))
        return false;

    margin = 220;
    d = distance2d(pos, level.deathcircle.origin);

    if (d < (level.deathcircle.radius - margin))
        return true;

    return false;
}

IsInDeathZone()
{
    if (!HasDeathCircle() || !isDefined(self.origin))
        return false;

    d = distance2d(self.origin, level.deathcircle.origin);
    buffer = 520;

    if (d > (level.deathcircle.radius - buffer))
        return true;

    return false;
}

GetAliveAnchorInsideCirclePreferNearby()
{
    if (!isDefined(self.origin))
        return undefined;

    players = getplayers();

    best = undefined;
    bestDSq = 999999999;

    foreach (p in players)
    {
        if (!isDefined(p) || !isAlive(p) || p == self || !isDefined(p.origin))
            continue;

        if (HasDeathCircle() && !IsPosInsideCircle(p.origin))
            continue;

        if (IsBadAnchorEnt(p))
            continue;

        dSq = distanceSquared(self.origin, p.origin);
        if (dSq < bestDSq)
        {
            bestDSq = dSq;
            best = p;
        }
    }

    return best;
}

PickSpawnCenterSmart()
{
    if (randomint(100) < 60)
    {
        a = GetAliveAnchorInsideCirclePreferNearby();
        if (isDefined(a) && isDefined(a.origin))
            return a.origin;
    }

    if (HasDeathCircle() && randomint(100) < 60)
        return level.deathcircle.origin;

    far = FindFarNavPointFromPlayers(34, 2600);
    if (isDefined(far))
        return far;

    e = GetRandomAliveEntityInsideCircle();
    if (isDefined(e) && isDefined(e.origin))
        return e.origin;

    return (isDefined(self.origin) ? self.origin : (0,0,0));
}

GetPOIsInsideCircleList()
{
    InitBlackoutPOIs();

    list = array();

    if (!isDefined(level.bo_pois) || level.bo_pois.size <= 0)
        return list;

    foreach (poi in level.bo_pois)
    {
        if (!isDefined(poi) || poi.size < 2)
            continue;

        pos = poi[1];

        if (HasDeathCircle())
        {
            if (!IsPosInsideCircle(pos))
                continue;

            if (IsEscapeMap() && !IsPOISafeInterior(pos))
                continue;
        }

                if (IsWaterNear(pos, 520) || IsWaterAt(pos))
            continue;

        list[list.size] = pos;
    }

    return list;
}

PickIndexedPOIInsideStorm(botIndex, fromPos)
{
    inside = GetPOIsInsideCircleList();

    if (isDefined(inside) && inside.size > 0)
    {
        start = botIndex % inside.size;
        for (i = 0; i < inside.size; i++)
        {
            idx = (start + i) % inside.size;
            fixed = FixBadSpawnLocation(inside[idx]);

            if (!isDefined(fixed))
                continue;

            if (IsBadLandingPos(fixed))
                continue;

            if (IsWaterNear(fixed, 900) || IsWaterAt(fixed))
                continue;

            return fixed;
        }
    }

    return PickClosestPOIInsideStorm(fromPos);
}

GetCircleSafeGoal()
{
    if (!HasDeathCircle() || !isDefined(self.origin))
        return undefined;

    center = IsEscapeMap() ? GetLandBiasedCircleCenter() : level.deathcircle.origin;
    if (!isDefined(center))
        center = level.deathcircle.origin;

    rad = level.deathcircle.radius;

    margin = 700;
    v = (center[0] - self.origin[0], center[1] - self.origin[1], 0);

    if (abs(v[0]) < 1 && abs(v[1]) < 1)
    {
        g0 = NavSnap(center);
        g0 = FixBadSpawnLocation(g0);
        if (isDefined(g0) && !IsBadLandingPos(g0))
            return g0;
    }

    dir = vectorNormalize(v);
    d = distance2d(self.origin, center);

    desiredD = d - 1800;
    minD = 350;
    maxD = rad - margin;

    if (maxD < minD) maxD = minD + 1;
    if (desiredD < minD) desiredD = minD;
    if (desiredD > maxD) desiredD = maxD;

    raw = (center[0] + dir[0] * desiredD, center[1] + dir[1] * desiredD, center[2]);

    safe = FixBadSpawnLocation(raw);

    if (isDefined(safe) && !IsBadLandingPos(safe) && !IsWaterNear(safe, 320))
        return safe;

    poi = PickClosestPOIInsideStorm(self.origin);
    poi = FixBadSpawnLocation(poi);
    if (isDefined(poi) && !IsBadLandingPos(poi))
        return poi;

    land = FindNearestDryNavFrom(self.origin);
    land = FixBadSpawnLocation(land);
    if (isDefined(land) && !IsBadLandingPos(land))
        return land;

    return undefined;
}

PickPOIInsideCircle()
{
    if (isDefined(self.bo_pregame_lock_until) && gettime() < self.bo_pregame_lock_until)
    {
        if (isDefined(level.bo_pregame_anchor) && isDefined(level.bo_pregame_anchor.origin))
            return FixBadSpawnLocation(level.bo_pregame_anchor.origin);
    }
    if (!isDefined(self.origin))
        return undefined;

    anchor = GetRandomAliveEntityInsideCircle();
    if (!isDefined(anchor))
        anchor = self;

    if (HasDeathCircle())
    {
        c = level.deathcircle.origin;
        useCenter = (randomint(100) < 40);
        base = useCenter ? c : anchor.origin;

        map = util::get_map_name();
        if (map == "wz_open_skyscrapers")
        {
            minR = 650;
            maxR = 1850;
        }
        else if (map == "wz_escape" || map == "wz_escape_alt")
        {
            minR = 900;
            maxR = 2600;
        }
        else
        {
            minR = 1200;
            maxR = 3400;
        }

        for (i = 0; i < 24; i++)
        {
            ang = randomFloatRange(0, 360);
            r = randomFloatRange(minR, maxR);
            fwd = anglesToForward((0, ang, 0));

            cand = (base[0] + fwd[0] * r, base[1] + fwd[1] * r, base[2]);
            cand = FixBadSpawnLocation(cand);

            if (!isDefined(cand))
                continue;

            if (distanceSquared(cand, self.origin) < (380 * 380))
                continue;

            if (IsBadLandingPos(cand))
                continue;

            if (IsWaterNear(cand, 900) || IsWaterAt(cand))
                continue;

            return cand;
        }

        baseFixed = FixBadSpawnLocation(base);
        if (isDefined(baseFixed) && !IsBadLandingPos(baseFixed) && !IsWaterNear(baseFixed, 520) && !IsWaterAt(baseFixed))
            return baseFixed;

        return PickDryPOIInsideStorm(base, isDefined(self.bo_bot_index) ? self.bo_bot_index : randomint(9999));
    }

    fixedAnchor = FixBadSpawnLocation(anchor.origin);
    if (isDefined(fixedAnchor) && !IsBadLandingPos(fixedAnchor) && !IsWaterNear(fixedAnchor, 520) && !IsWaterAt(fixedAnchor))
        return fixedAnchor;

    return PickDryPOIInsideStorm(anchor.origin, isDefined(self.bo_bot_index) ? self.bo_bot_index : randomint(9999));
}

PickSearchGoal()
{
    map = util::get_map_name();

    if (map == "wz_open_skyscrapers" || map == "wz_escape" || map == "wz_escape_alt") return PickPOIInsideCircle();

    center = self.origin;

    minR = 1800;
    maxR = 4200;

    r = randomFloatRange(minR, maxR);
    ang = randomFloatRange(0, 360);
    fwd = anglesToForward((0, ang, 0));

    pos = (center[0] + fwd[0] * r, center[1] + fwd[1] * r, center[2]);
    return FixBadSpawnLocation(pos);
}

ClampPosInsideCircle(pos, margin)
{
    if (!HasDeathCircle() || !isDefined(pos))
        return pos;

    if (!isDefined(margin))
        margin = 650;

    c = level.deathcircle.origin;
    r = level.deathcircle.radius;

    safeR = r - margin;
    if (safeR < r * 0.55)
        safeR = r * 0.55;
    if (safeR < 220)
        safeR = 220;

    if (distance2d(pos, c) <= safeR)
        return pos;

    v = (pos[0] - c[0], pos[1] - c[1], 0);

    if (abs(v[0]) < 1 && abs(v[1]) < 1)
        return (c[0], c[1], c[2]);

    dir = vectorNormalize(v);
    return (c[0] + dir[0] * safeR, c[1] + dir[1] * safeR, c[2]);
}

PickClosestPOIInsideStorm(fromPos)
{
    if (!isDefined(fromPos))
        return undefined;

    InitBlackoutPOIs();

    if (!isDefined(level.bo_pois) || level.bo_pois.size <= 0)
        return undefined;

    best = undefined;
    bestDSq = 999999999;

    foreach (poi in level.bo_pois)
    {
        if (!isDefined(poi) || poi.size < 2)
            continue;

        pos = poi[1];

        if (HasDeathCircle() && !IsPosInsideCircle(pos)) continue;
        if (HasDeathCircle() && IsEscapeMap() && !IsPOISafeInterior(pos)) continue;

        fixed = FixBadSpawnLocation(pos);
        if (!isDefined(fixed))
            continue;

        if (IsBadLandingPos(fixed))
            continue;

        if (IsWaterNear(fixed, 900) || IsWaterAt(fixed))
            continue;

        dSq = distanceSquared(fromPos, fixed);
        if (dSq < bestDSq)
        {
            bestDSq = dSq;
            best = fixed;
        }
    }

    if (isDefined(best))
        return best;

    if (HasDeathCircle())
    {
        c = level.deathcircle.origin;

        best2 = undefined;
        best2DSq = 999999999;

        foreach (poi2 in level.bo_pois)
        {
            if (!isDefined(poi2) || poi2.size < 2)
                continue;

            p2 = poi2[1];

            if (HasDeathCircle() && !IsPosInsideCircle(p2)) continue;
            if (HasDeathCircle() && IsEscapeMap() && !IsPOISafeInterior(p2)) continue;

            fixed2 = FixBadSpawnLocation(p2);
            if (!isDefined(fixed2))
                continue;

            if (IsBadLandingPos(fixed2))
                continue;

            if (IsWaterNear(fixed2, 520) || IsWaterAt(fixed2))
                continue;

            d2 = distanceSquared(c, fixed2);
            if (d2 < best2DSq)
            {
                best2DSq = d2;
                best2 = fixed2;
            }
        }

        if (isDefined(best2))
            return best2;
    }

    return undefined;
}

InsertionFreefallToPOI()
{
    self endon("disconnect");
    self endon("death");
    level endon("game_ended");

    self.bo_insertion_active = true;

    wait 0.25;

    from = isDefined(self.origin) ? self.origin : (HasDeathCircle() ? level.deathcircle.origin : (0,0,0));
    if (!isDefined(self.bo_drop_poi)) self UpdateDropPOIForThisLife();

    poiGoal = isDefined(self.bo_drop_poi) ? self.bo_drop_poi : PickClosestPOIInsideStorm(from);
    if (!isDefined(poiGoal))
    {
        self.bo_insertion_active = false;
        return;
    }

    if (IsBadLandingPos(poiGoal) || IsWaterNear(poiGoal, 650))
    {
        self UpdateDropPOIForThisLife();
        if (isDefined(self.bo_drop_poi))
            poiGoal = self.bo_drop_poi;
    }

    safeMargin = 700;
    lastRecalc = 0;

    t0 = gettime();
    lastHold = 0;
    lastChuteTap = 0;

    for (;;)
    {
        if (!isAlive(self))
        {
            self.bo_insertion_active = false;
            return;
        }

        if (!isDefined(self.origin))
        {
            wait 0.10;
            continue;
        }

        if (IsLandedStable())
        {
            if (IsWaterNear(self.origin, 220))
            {
                redirect2 = FindDryRedirectFromHere();
                if (isDefined(redirect2))
                    self setorigin(redirect2);
            }
            break;
        }

        dzToGround = 0;
        start = (self.origin[0], self.origin[1], self.origin[2] + 60);
        end = (self.origin[0], self.origin[1], self.origin[2] - 20000);
        tr = bullettrace(start, end, 0, self);
        if (isDefined(tr) && isDefined(tr["position"]))
            dzToGround = abs(self.origin[2] - tr["position"][2]);

        if (gettime() - lastRecalc > 450)
        {
            lastRecalc = gettime();

            if (!isDefined(self.bo_drop_poi))
                self UpdateDropPOIForThisLife();
            else if (HasDeathCircle() && !IsPosInsideCircle(self.bo_drop_poi))
                self UpdateDropPOIForThisLife();

            poiGoal = isDefined(self.bo_drop_poi) ? self.bo_drop_poi : poiGoal;

            if (isDefined(poiGoal) && (IsBadLandingPos(poiGoal) || IsWaterNear(poiGoal, 650)))
            {
                self UpdateDropPOIForThisLife();
                if (isDefined(self.bo_drop_poi))
                    poiGoal = self.bo_drop_poi;
            }
            if (dzToGround > 0 && dzToGround < 950)
            {
                if (IsWaterNear(self.origin, 220))
                {
                    redirect = FindDryRedirectFromHere();
                    if (isDefined(redirect))
                        poiGoal = redirect;
                }
            }
        }

        dynGoal = poiGoal;

        if (HasDeathCircle())
        {
            dynGoal = ClampPosInsideCircle(dynGoal, safeMargin);

            d2 = distance2d(self.origin, level.deathcircle.origin);
            if (d2 > (level.deathcircle.radius - 120))
            {
                dynGoal = self GetCurrentPOIObjective();
                if (!isDefined(dynGoal))
                    dynGoal = PickClosestPOIInsideStorm(self.origin);
            }
        }

        dynGoal = self GetAirSteerGoal(dynGoal);
        if (!isDefined(dynGoal))
        {
            wait 0.10;
            continue;
        }

        dir = vectorNormalize(dynGoal - self.origin);
        yaw = vectortoangles(dir)[1];
        self botsetmoveangles((0, yaw, 0));
        self botsetlookangles((0, yaw, 0));

        if (!self isinvehicle())
        {
            self clearentitytarget();
            self botsetmovepoint(dynGoal);
            self botsetmovemagnitude(1.0);
        }

        if (self isinvehicle())
        {
            self InsertionDisarmCombat();

            dxy = distance2d(self.origin, dynGoal);

            if (dxy < 1100)
            {
                risky = false;

                test = FixBadSpawnLocation((dynGoal[0], dynGoal[1], level.deathcircle.origin[2]));
                if (!isDefined(test) || IsWaterNear(test, 650) || IsBadLandingPos(test))
                    risky = true;

                if (risky)
                {
                    self UpdateDropPOIForThisLife();
                    wait 0.10;
                    continue;
                }

                self TryForceJumpOut();
                self TryForceJumpOut();
                self bottapbutton(7);
                if (randomint(100) < 50) self bottapbutton(7);
            }
            else if (gettime() - lastHold > 550)
            {
                lastHold = gettime();
                self TryForceJumpOut();
                if (randomint(100) < 35)
                    self bottapbutton(10);
            }

            if (gettime() - t0 > 9000)
            {
                self TryForceJumpOut();
                self TryForceJumpOut();
                self bottapbutton(7);
            }

            if (gettime() - t0 > 22000)
            {
                self.bo_insertion_active = false;
                return;
            }

            wait 0.10;
            continue;
        }

        if (dzToGround > 250 && dzToGround < 1100)
        {
            if (gettime() - lastChuteTap > 650)
            {
                lastChuteTap = gettime();
                self bottapbutton(7);
            }
        }

        if (gettime() - t0 > 14000 && gettime() - lastChuteTap > 900)
        {
            lastChuteTap = gettime();
            self bottapbutton(7);
        }

        wait 0.10;
    }

    wait 0.35;

    self.bo_insertion_active = false;

    poiGoalFixed = FixBadSpawnLocation(poiGoal);

    if (!isDefined(poiGoalFixed))
    {
        poiGoalFixed = FindNearestDryNavFrom(self.origin);
        if (!isDefined(poiGoalFixed))
            poiGoalFixed = PickClosestPOIInsideStorm(self.origin);
        if (!isDefined(poiGoalFixed) && HasDeathCircle())
            poiGoalFixed = NavSnap(level.deathcircle.origin);

        poiGoalFixed = NavSnap(poiGoalFixed);
        if (!isDefined(poiGoalFixed))
        {
            self.bo_insertion_active = false;
            return;
        }
    }

    self.bo_search_goal = NavSnap(poiGoalFixed);
    if (!isDefined(self.bo_search_goal))
        self.bo_search_goal = poiGoalFixed;

    self.bo_next_goal_time = gettime() + randomintRange(4500, 8000);
    self.bo_roam_commit_until = gettime() + randomintRange(2500, 4500);

    self clearentitytarget();
    self botsetmovepoint(self.bo_search_goal);
    self botsetmovemagnitude(1.0);
}

SetPOIPriorityWindow(minMs, maxMs)
{
    if (!isDefined(minMs)) minMs = 22000;
    if (!isDefined(maxMs)) maxMs = 38000;

    self.bo_poi_priority_until = gettime() + randomintRange(minMs, maxMs);
    self.bo_poi_priority_reached = false;
}

IsPOIPriorityActive()
{
    return isDefined(self.bo_poi_priority_until) && gettime() < self.bo_poi_priority_until;
}

GetCurrentPOIObjective()
{
    if (isDefined(self.bo_drop_poi))
        return self.bo_drop_poi;

    from = isDefined(self.origin) ? self.origin : (HasDeathCircle() ? level.deathcircle.origin : (0,0,0));
    return PickIndexedPOIInsideStorm(isDefined(self.bo_bot_index) ? self.bo_bot_index : randomint(9999), from);
}

GetAirSteerGoal(rawGoal)
{
    if (!isDefined(rawGoal) || !isDefined(self.origin))
        return undefined;

    g = rawGoal;

    margin = 750;
    if (IsEscapeMap())
        margin = 1100;

    if (HasDeathCircle())
        g = ClampPosInsideCircle(g, margin);

    ground = FixBadSpawnLocation(g);

    if (!isDefined(ground) || IsBadLandingPos(ground) || IsWaterNear(ground, IsEscapeMap() ? 380 : 650))
    {
        poi = self GetCurrentPOIObjective();
        if (!isDefined(poi))
            poi = PickClosestPOIInsideStorm(self.origin);

        poiFixed = FixBadSpawnLocation(poi);

        if (isDefined(poiFixed) && !IsBadLandingPos(poiFixed))
            ground = poiFixed;
        else
        {
            land = FindNearestDryNavFrom(self.origin);
            land = FixBadSpawnLocation(land);
            if (isDefined(land) && !IsBadLandingPos(land))
                ground = land;
        }
    }

    if (!isDefined(ground))
        return undefined;

    if (isDefined(self.bo_insertion_active) && self.bo_insertion_active && !IsLandedStable())
    {
        if (IsWaterNear(self.origin, 900))
        {
            dry = FindDryRedirectFromHere();
            if (!isDefined(dry)) dry = FindNearestDryNavFrom(self.origin);
            dry = FixBadSpawnLocation(dry);
            if (isDefined(dry) && !IsBadLandingPos(dry) && !IsWaterNear(dry, 520))
                ground = dry;
        }
        idx = isDefined(self.bo_bot_index) ? self.bo_bot_index : randomint(9999);
        ang0 = (idx * 61) % 360;

        for (j = 0; j < 8; j++)
        {
            ang = (ang0 + (j * 45)) % 360;
            r = 450 + (j * 90);
            fwd = anglesToForward((0, ang, 0));

            cand = (ground[0] + fwd[0] * r, ground[1] + fwd[1] * r, ground[2]);
            cand = FixBadSpawnLocation(cand);

            if (!isDefined(cand)) continue;
            if (IsBadLandingPos(cand)) continue;
            if (IsWaterNear(cand, 900)) continue;

            if (MinDistSqToOtherBots(cand) < (750 * 750)) continue;

            ground = cand;
            break;
        }
    }

    return (ground[0], ground[1], self.origin[2]);
}

PickStormExitDestination()
{
    if (!isDefined(self.origin))
        return undefined;

    a = GetAliveAnchorInsideCirclePreferNearby();
    if (isDefined(a) && isDefined(a.origin))
        return FixBadSpawnLocation(a.origin);

    poi = PickIndexedPOIInsideStorm(isDefined(self.bo_bot_index) ? self.bo_bot_index : randomint(9999), self.origin);
    if (isDefined(poi))
        return FixBadSpawnLocation(poi);

    g = GetCircleSafeGoal();
    if (isDefined(g))
        return FixBadSpawnLocation(g);

    if (HasDeathCircle())
        return FixBadSpawnLocation(level.deathcircle.origin);

    return undefined;
}

StormRunTo(dest)
{
    if (!isDefined(dest))
        return false;

    g = NavSnap(dest);
    if (!isDefined(g))
        g = FixBadSpawnLocation(dest);

    if (!isDefined(g))
        return false;

    self clearentitytarget();
    self botsetmovepoint(g);
    self botsetmovemagnitude(1.0);

    UnstuckCheck(g);

    if (randomint(100) < 25)
        self ScanLook();

    return true;
}

IsEscapeMap()
{
    map = util::get_map_name();
    return (map == "wz_escape" || map == "wz_escape_alt");
}

GetLandBiasedCircleCenter()
{
    if (!HasDeathCircle())
        return undefined;

    c = level.deathcircle.origin;

    if (IsWaterAt(c) || IsWaterNear(c, 420) || NoGroundAt(c))
    {
        land = FindNearestDryNavFrom(c);
        land = FixBadSpawnLocation(land);

        if (isDefined(land) && !IsBadLandingPos(land))
            return land;

        poi = PickClosestPOIInsideStorm(c);
        poi = FixBadSpawnLocation(poi);

        if (isDefined(poi) && !IsBadLandingPos(poi))
            return poi;

        return FixBadSpawnLocation(c);
    }

    return c;
}

UpdateDropPOIForThisLife()
{
    if (!isDefined(self) || !isPlayer(self))
        return;

    from = isDefined(self.origin) ? self.origin : (HasDeathCircle() ? level.deathcircle.origin : (0,0,0));

    if (isDefined(from) && (IsWaterNear(from, 900) || IsWaterAt(from)))
        from = HasDeathCircle() ? level.deathcircle.origin : from;

    if (HasDeathCircle() && IsEscapeMap() && isDefined(self.bo_drop_poi))
    {
        if (!IsPOISafeInterior(self.bo_drop_poi))
            self.bo_drop_poi = undefined;
    }

    self.bo_drop_poi = PickDryPOIInsideStorm(from, isDefined(self.bo_bot_index) ? self.bo_bot_index : randomint(9999));
    self.bo_drop_poi_time = gettime();

    if (!isDefined(self.bo_drop_poi) || IsBadLandingPos(self.bo_drop_poi) || IsWaterNear(self.bo_drop_poi, 900) || IsWaterAt(self.bo_drop_poi) || (HasDeathCircle() && IsEscapeMap() && !IsPOISafeInterior(self.bo_drop_poi)))
    {
        alt = PickClosestPOIInsideStorm(from);
        if (isDefined(alt))
            self.bo_drop_poi = alt;
    }

    if (!isDefined(self.bo_drop_poi) || IsBadLandingPos(self.bo_drop_poi) || IsWaterNear(self.bo_drop_poi, 900) || IsWaterAt(self.bo_drop_poi))
    {
        if (HasDeathCircle())
            self.bo_drop_poi = PickDryPOIInsideStorm(level.deathcircle.origin, isDefined(self.bo_bot_index) ? self.bo_bot_index : randomint(9999));
        else
            self.bo_drop_poi = PickDryPOIInsideStorm(from, isDefined(self.bo_bot_index) ? self.bo_bot_index : randomint(9999));
    }

    fixed = FixBadSpawnLocation(self.bo_drop_poi);

    if (HasDeathCircle() && isDefined(fixed) && !IsPosInsideCircle(fixed))
        fixed = undefined;


    if (!isDefined(fixed))
    {
        fixed = FindNearestDryNavFrom(from);
        if (!isDefined(fixed))
            fixed = PickClosestPOIInsideStorm(from);
    }

    if (isDefined(fixed) && !IsBadLandingPos(fixed) && !IsWaterNear(fixed, 900) && !IsWaterAt(fixed))
        self.bo_drop_poi = fixed;
}

IsPosInsideCircleMargin(pos, margin)
{
    if (!HasDeathCircle() || !isDefined(pos))
        return false;

    if (!isDefined(margin))
        margin = 220;

    d = distance2d(pos, level.deathcircle.origin);
    return (d < (level.deathcircle.radius - margin));
}

GetEscapePOIMargin()
{
    return 1600;
}

IsPOISafeInterior(pos)
{
    if (!HasDeathCircle() || !isDefined(pos)) return true;

    if (!IsEscapeMap()) return true;

    return IsPosInsideCircleMargin(pos, GetEscapePOIMargin());
}

GetCircleSig()
{
    if (!HasDeathCircle())
        return undefined;

    ox = int(level.deathcircle.origin[0] / 64) * 64;
    oy = int(level.deathcircle.origin[1] / 64) * 64;
    r  = int(level.deathcircle.radius / 64) * 64;

    return (ox, oy, r);
}

CircleSigChanged(a, b)
{
    if (!isDefined(a) || !isDefined(b))
        return true;

    if (a[0] != b[0]) return true;
    if (a[1] != b[1]) return true;
    if (a[2] != b[2]) return true;

    return false;
}

ForceRecommitPOI(reason)
{
    if (!isDefined(self) || !isPlayer(self))
        return;

    self.bo_search_goal = undefined;
    self.bo_next_goal_time = 0;
    self.bo_roam_commit_until = 0;

    self UpdateDropPOIForThisLife();

    if (isDefined(self.bo_insertion_active) && self.bo_insertion_active)
    {
        if (self isinvehicle())
        {
            self InsertionDisarmCombat();
            if (randomint(100) < 80) self TryForceJumpOut();
        }
    }
}

DeathCircleRecommitWatcher()
{
    self endon("disconnect");
    self endon("death");
    level endon("game_ended");
    self endon("bo_brain_restart");

    lastSig = GetCircleSig();
    lastBump = 0;

    for (;;)
    {
        wait 0.35;

        if (!HasDeathCircle())
            continue;

        if (!IsEscapeMap())
        {
            lastSig = GetCircleSig();
            continue;
        }

        sig = GetCircleSig();

        if (CircleSigChanged(sig, lastSig))
        {
            if (gettime() - lastBump > 1200)
            {
                lastBump = gettime();
                self ForceRecommitPOI("circle_changed");
            }

            lastSig = sig;
        }
    }
}