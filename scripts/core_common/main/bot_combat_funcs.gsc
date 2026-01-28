InsertionDisarmCombat()
{
    if (!isDefined(self.bo_insertion_active) || !self.bo_insertion_active)
        return;

    self clearentitytarget();

    if (isDefined(self.angles))
        self botsetlookangles((0, self.angles[1], 0));

    self botsetmovemagnitude(0.0);

    self bottapbutton(0);
    self bottapbutton(1);
    self bottapbutton(11);
}

ShouldSuppressCombatNow()
{
    if (!isAlive(self))
        return true;

    if (self isonground())
        return false;

    if (self isinvehicle())
        return true;

    if (isDefined(self.bo_insertion_active) && self.bo_insertion_active)
        return true;

    if (isDefined(self.bo_air_combat_suppress_until) && gettime() < self.bo_air_combat_suppress_until)
        return true;

    return false;
}

BO_SWIM_UP()
{
    return 67;
}

BO_SWIM_DOWN()
{
    return 68;
}

EnableBotSprint()
{
    if (!self isTestClient())
        return;

    ai::createinterfaceforentity(self);

    if (ai::hasaiattribute(self, #"sprint"))
        ai::setaiattribute(self, #"sprint", 1);

    if (isDefined(self.bo_sprint_thread))
        return;

    self.bo_sprint_thread = true;
    self thread SprintWhileMovingLoop();
}

CanEngageCombatNow()
{
    if (!isAlive(self) || !isDefined(self.origin))
        return false;

    if (self isinvehicle())
        return false;

    if (isDefined(self.bo_insertion_active) && self.bo_insertion_active)
        return false;

    if (self isonground())
        return IsLandedStable();

    return IsLandedStable();
}

BotSprintController()
{
    self endon("disconnect");
    self endon("death");
    level endon("game_ended");

    for (;;)
    {
        if (!CanEngageCombatNow())
        {
            wait 0.15;
            continue;
        }

        if (self attackbuttonpressed() || isDefined(self.bo_target))
        {
            wait 0.15;
            continue;
        }

        if (isDefined(self.bo_search_goal))
        {
            dSq = distanceSquared(self.origin, self.bo_search_goal);

            if (dSq > (650 * 650))
            {
                self bottapbutton(10);
            }
        }

        wait 0.15;
    }
}

SprintWhileMovingLoop()
{
    self endon("disconnect");
    self endon("death");
    level endon("game_ended");

    for (;;)
    {
        if (!isAlive(self) || !isDefined(self.origin))
        {
            wait 0.20;
            continue;
        }

        if (self isinvehicle() || (isDefined(self.bo_insertion_active) && self.bo_insertion_active))
        {
            self botreleasebutton(1);
            wait 0.10;
            continue;
        }

        movingFar = isDefined(self.bo_search_goal) && distanceSquared(self.origin, self.bo_search_goal) > (900 * 900);

        fighting = isDefined(self.bo_target) && isAlive(self.bo_target);

        if (movingFar && !fighting && IsLandedStable()){
            self botreleasebutton(9);
            self botreleasebutton(8);
            self botreleasebutton(39);
            self botpressbutton(1);
        }
        else { self botreleasebutton(1); }

        wait 0.10;
    }
}

GetAimPointForDifficulty(enemy)
{
    if (!isDefined(enemy) || !isDefined(enemy.origin))
        return undefined;

    diff = self GetBotDifficulty();

    z = 52;
    j = 8;

    if (diff == 2)
    {
        z = 58;
        j = 6;
    }
    else if (diff == 3)
    {
        z = 64;
        j = 4;
    }

    aim = enemy.origin;
    aim = (aim[0] + randomFloatRange(0.0 - j, j), aim[1] + randomFloatRange(0.0 - j, j), aim[2] + z + randomFloatRange(-2, 2));
    return aim;
}

DoSlideTap()
{
    if (!self isonground())
        return;

    self botreleasebutton(9);
    self botreleasebutton(8);
    self botreleasebutton(39);

    self botpressbutton(1);
    wait 0.05;

    self bottapbutton(39);
    wait 0.05;

    self botreleasebutton(1);
}

DifficultyCombatTactics(enemy)
{
    diff = self GetBotDifficulty();
    if (diff <= 1)
        return;

    if (!isDefined(enemy) || !isAlive(enemy) || !isDefined(enemy.origin))
        return;

    if (self isinvehicle())
        return;

    if (isDefined(self.bo_insertion_active) && self.bo_insertion_active)
        return;

    if (gettime() - self.bo_diff_last_action_time < 350)
        return;

    self.bo_diff_last_action_time = gettime();

    if (!self isonground())
        return;

    if (CanSeeTarget(enemy))
    {
        if (diff == 2) hopChance = 12;
        else hopChance = 22;

        if (randomint(100) < hopChance)
            self bottapbutton(10);
    }

    if (diff == 2)
    {
        slideChance = 8;
        crouchChance = 10;
    }
    else
    {
        slideChance = 16;
        crouchChance = 16;
    }

    r = randomint(100);
    if (r < slideChance)
        self DoSlideTap();
    else if (r < slideChance + crouchChance)
        self bottapbutton(9);
}

ThreatScore(p)
{
    if (!isDefined(p) || !isAlive(p) || !isDefined(p.origin) || !isDefined(self.origin))
        return -999999999;

    if (isDefined(self.team) && isDefined(p.team))
    {
        if (!util::function_fbce7263(p.team, self.team))
            return -999999999;
    }

    if (isDefined(self.botteam) && isDefined(p.botteam) && p.botteam == self.botteam)
        return -999999999;

    dSq = distanceSquared(self.origin, p.origin);
    if (dSq > (7000 * 7000))
        return -999999999;

    fwd = anglesToForward((0, self.angles[1], 0));
    dir = vectorNormalize(p.origin - self.origin);
    frontDot = vectorDot(dir, fwd);

    visible = CanSeeTarget(p);

    score = 0;
    score += visible ? 120000 : 0;
    score += int(52000000 / (dSq + 1));
    score += int(frontDot * 14000);

    if (!visible) score -= 25000;

    diff = self GetBotDifficulty();
    host = util::gethostplayerforbots();
    if (isDefined(host) && p == host)
    {
        if (diff == 2) score += 22000;
        else if (diff == 3) score += 52000;
    }

    return score;
}

PickBestThreatNow(maxDist)
{
    
    if (ShouldSuppressCombatNow())
        return undefined;
    if (!isDefined(maxDist))
        maxDist = 7000;

    if (!isDefined(self.origin) || !isDefined(self.angles))
        return undefined;

    maxSq = maxDist * maxDist;

    players = getplayers();
    best = undefined;
    bestScore = -999999999;

    foreach (p in players)
    {
        if (!isDefined(p) || p == self || !isAlive(p) || !isDefined(p.origin))
            continue;

        dSq = distanceSquared(self.origin, p.origin);
        if (dSq > maxSq)
            continue;

        s = ThreatScore(p);
        if (s > bestScore)
        {
            bestScore = s;
            best = p;
        }
    }

    return best;
}

UpdateTargetSmart()
{
    if (!isDefined(self.bo_target))
        self.bo_target = undefined;

    if (isDefined(self.bo_target) && (!isAlive(self.bo_target) || !isDefined(self.bo_target.origin)))
    {
        self.bo_target = undefined;
        self.bo_target_lost_time = undefined;
    }

    best = PickBestThreatNow(7000);
    if (!isDefined(best))
        return;

    if (!isDefined(self.bo_target))
    {
        self.bo_target = best;
        self.bo_target_lost_time = undefined;
        return;
    }

    curScore = ThreatScore(self.bo_target);
    bestScore = ThreatScore(best);

    curVis = CanSeeTarget(self.bo_target);
    bestVis = CanSeeTarget(best);

    if (bestVis && !curVis)
    {
        self.bo_target = best;
        self.bo_target_lost_time = undefined;
        return;
    }

    if (bestScore > curScore + 18000)
    {
        self.bo_target = best;
        self.bo_target_lost_time = undefined;
        return;
    }
}

DoJuke(goal, strength)
{
    if (!isDefined(strength))
        strength = 1;

    if (!isDefined(self.origin) || !isDefined(self.angles))
        return;

    if (!isDefined(self.bo_last_juke_time))
        self.bo_last_juke_time = 0;

    if (gettime() - self.bo_last_juke_time < 900)
        return;

    self.bo_last_juke_time = gettime();

    fwd = anglesToForward((0, self.angles[1], 0));
    rx = 0.0 - fwd[1];
    ry = fwd[0];

    backDist = randomFloatRange(120, 200) * float(strength);
    back = (self.origin[0] - fwd[0] * backDist, self.origin[1] - fwd[1] * backDist, self.origin[2]);
    back = NavSnap(back);

    if (isDefined(back))
    {
        self botsetmovepoint(back);
        self botsetmovemagnitude(1.0);
        if (randomint(100) < 70) self bottapbutton(10);
        wait 0.08;
    }

    side = (randomint(2) == 0) ? 1 : -1;
    sideDist = randomFloatRange(320, 520) * float(side) * float(strength);

    step = (self.origin[0] + rx * sideDist, self.origin[1] + ry * sideDist, self.origin[2]);
    step = NavSnap(step);

    if (isDefined(step))
    {
        self botsetmovepoint(step);
        self botsetmovemagnitude(1.0);
        if (randomint(100) < 85) self bottapbutton(10);
        wait 0.12;
    }

    if (isDefined(goal))
    {
        newGoal = PickGoalNear(goal, 900 + (250 * strength));
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

SmartMoveTo(goal, isCombat, lookPos)
{
    if (!isDefined(goal))
        return false;

    goal = NavSnap(goal);
    if (!isDefined(goal))
        return false;

    self botsetmovepoint(goal);
    self botsetmovemagnitude(1.0);

    if (!isCombat && isDefined(self.origin))
    {
        dir = vectorNormalize(goal - self.origin);
        yaw = vectortoangles(dir)[1];
        self botsetmoveangles((0, yaw, 0));

        if (!isDefined(lookPos))
            self botsetlookangles((0, yaw, 0));
    }

    if (isDefined(lookPos))
        self botsetlookpoint(lookPos);
    else if (!isCombat && isDefined(self.angles))
        self botsetlookangles((0, self.angles[1], 0));

    if (!isDefined(self.bo_nav_goal_last) || distanceSquared(self.bo_nav_goal_last, goal) > (220 * 220))
    {
        self.bo_nav_goal_last = goal;
        self StartGoalProgress(goal, "bo_nav");
    }

    blocked = IsBlockedAheadWide(110);
    failing = GoalProgressFailing(goal, "bo_nav", isCombat ? 650 : 900, isCombat ? (120 * 120) : (160 * 160));

    if (blocked || failing)
    {
        fails = isDefined(self["bo_nav_fails"]) ? self["bo_nav_fails"] : 0;
        fails++;
        self["bo_nav_fails"] = fails;

        strength = 1;
        if (fails >= 2) strength = 2;
        if (fails >= 4) strength = 3;

        self DoJuke(goal, strength);
        return true;
    }

    self["bo_nav_fails"] = 0;

    return true;
}

GetEyePos(ent)
{
    if (!isDefined(ent) || !isDefined(ent.origin))
        return undefined;

    return (ent.origin[0], ent.origin[1], ent.origin[2] + 56);
}

CanSeeTarget(target)
{
    if (self isinvehicle())
        return false;
    if (isDefined(self.bo_insertion_active) && self.bo_insertion_active)
        return false;
    if (!isDefined(target) || !isAlive(target))
        return false;

    if (!isDefined(self.origin) || !isDefined(target.origin))
        return false;

    start = GetEyePos(self);
    end = GetEyePos(target);

    if (!isDefined(start) || !isDefined(end))
        return false;

    tr = bullettrace(start, end, 0, self);
    if (!isDefined(tr))
        return false;

    if (isDefined(tr["entity"]) && tr["entity"] == target)
        return true;

    if (isDefined(tr["fraction"]) && tr["fraction"] >= 0.98)
        return true;

    return false;
}

PickVisibleThreat()
{
    players = getplayers();

    if (!isDefined(self.origin) || !isDefined(self.angles))
        return undefined;

    fwd = anglesToForward((0, self.angles[1], 0));

    best = undefined;
    bestScore = -999999999;

    foreach (p in players)
    {
        if (!isDefined(p) || !isAlive(p) || p == self || !isDefined(p.origin))
            continue;

        if (isDefined(self.team) && isDefined(p.team))
        {
            if (!util::function_fbce7263(p.team, self.team))
                continue;
        }

        if (isDefined(self.botteam) && isDefined(p.botteam) && p.botteam == self.botteam)
            continue;

        if (!CanSeeTarget(p))
            continue;

        dSq = distanceSquared(self.origin, p.origin);
        if (dSq > (5200 * 5200))
            continue;

        dir = vectorNormalize(p.origin - self.origin);
        inFront = (vectorDot(dir, fwd) > 0.15);

        score = 0;
        score += inFront ? 14000 : 0;
        score += int(38000000 / (dSq + 1));

        if (score > bestScore)
        {
            bestScore = score;
            best = p;
        }
    }

    return best;
}

FindEnemy()
{
    if (self isinvehicle()) return undefined;

    if (isDefined(self.bo_insertion_active) && self.bo_insertion_active)
        return undefined;
    players = getplayers();

    if (!isDefined(self.origin) || !isDefined(self.angles))
        return undefined;

    fwd = anglesToForward((0, self.angles[1], 0));

    best = undefined;
    bestScore = -999999999;

    foreach (p in players)
    {
        if (!isDefined(p) || !isAlive(p) || p == self || !isDefined(p.origin))
            continue;

        if (isDefined(self.team) && isDefined(p.team))
        {
            if (!util::function_fbce7263(p.team, self.team))
                continue;
        }

        if (isDefined(self.botteam) && isDefined(p.botteam) && p.botteam == self.botteam)
            continue;

        dSq = distanceSquared(self.origin, p.origin);
        if (dSq > (7000 * 7000))
            continue;

        dir = vectorNormalize(p.origin - self.origin);
        frontDot = vectorDot(dir, fwd);

        visible = CanSeeTarget(p);

        score = 0;
        score += visible ? 60000 : 0;
        score += int(52000000 / (dSq + 1));
        score += int(frontDot * 12000);

        if (score > bestScore)
        {
            bestScore = score;
            best = p;
        }
    }

    return best;
}

GetRandomAliveEnemyEntity()
{
    list = array();
    players = getplayers();

    foreach (p in players)
    {
        if (!isDefined(p) || !isAlive(p) || p == self || !isDefined(p.origin))
            continue;

        if (isDefined(self.team) && isDefined(p.team))
        {
            if (!util::function_fbce7263(p.team, self.team))
                continue;
        }

        if (isDefined(self.botteam) && isDefined(p.botteam) && p.botteam == self.botteam)
            continue;

        if (HasDeathCircle() && !IsPosInsideCircle(p.origin))
            continue;

        list[list.size] = p;
    }

    if (list.size <= 0)
        return undefined;

    return list[randomint(list.size)];
}

ScanLook()
{
    self endon("disconnect");
    self endon("death");
    level endon("game_ended");

    baseYaw = self.angles[1];

    self botsetlookangles((0, baseYaw + randomFloatRange(-80, 80), 0));
    wait 0.10;

    self botsetlookangles((0, baseYaw + randomFloatRange(-80, 80), 0));
    wait 0.10;

    self botsetlookangles((0, baseYaw, 0));
}

ShootBurst(enemy)
{
    if (IsBlockedAheadWide(84))
    {
        self DoJuke(enemy.origin, 1);
    }

    if (self isinvehicle())
        return;

    if (isDefined(self.bo_insertion_active) && self.bo_insertion_active)
        return;

    if (isDefined(self.sessionstate) && self.sessionstate != "playing")
        return;
    if (!isDefined(enemy) || !isAlive(enemy) || !isDefined(enemy.origin))
        return;

    if (!HasGun())
        return;

    self setentitytarget(enemy, 1);
    aimPt = self GetAimPointForDifficulty(enemy);
    if (isDefined(aimPt))
        self botsetlookpoint(aimPt);
    else
        self botsetlookpoint(enemy.origin);

    if (isDefined(self.origin))
    {
        dSq = distanceSquared(self.origin, enemy.origin);

    diff = self GetBotDifficulty();
    maxShoot = 2200;
    if (diff == 2) maxShoot = 2500;
    else if (diff == 3) maxShoot = 2800;

    if (dSq > (maxShoot * maxShoot))
    {
        self botsetmovemagnitude(1.0);
        return;
    }
    }
    diff = self GetBotDifficulty();

    if (diff >= 2 && self isonground())
    {
        if (diff == 2) dsChance = 10;
        else dsChance = 18;

        if (randomint(100) < dsChance)
            self bottapbutton(8);
    }
    self botsetmovemagnitude(0.35);

    burstMs = 350;
    step = 0.05;

    if (diff == 2)
    {
        burstMs = 420;
        step = 0.045;
    }
    else if (diff == 3)
    {
        burstMs = 520;
        step = 0.040;
    }

    endTime = gettime() + burstMs;
    while (gettime() < endTime)
    {
        self bottapbutton(11);
        self bottapbutton(0);
        wait step;
    }
        self botsetmovemagnitude(1.0);
}

IsDownedLike(ent)
{
    if (!isDefined(ent))
        return false;

    if (!isDefined(ent.origin))
        return false;

    if (!isAlive(ent))
        return false;

    if (isDefined(ent.laststand) && ent.laststand)
        return true;

    if (isDefined(ent.inlaststand) && ent.inlaststand)
        return true;

    if (isDefined(ent.isDown) && ent.isDown)
        return true;

    if (isDefined(ent.bo_is_downed) && ent.bo_is_downed)
        return true;

    if (isDefined(ent.sessionstate) && (ent.sessionstate == "down" || ent.sessionstate == "laststand"))
        return true;

    return false;
}

FindDownedTeammate()
{
    return undefined;
}

DoReviveTeammate(target)
{
    return;
}

BotHoldButton(button, holdTime)
{
    endT = gettime() + int(holdTime * 1000);
    while (gettime() < endT)
    {
        self bottapbutton(button);
        wait 0.05;
    }
}