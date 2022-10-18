// MML Emulator Auto Splitter
// Made by apel
// Special thanks to Bo Steed for providing save states

state("duckstation-qt-x64-ReleaseLTCG") 
{
}

startup
{
    settings.Add("timer_settings", true, "Timer Settings");
    settings.SetToolTip("timer_settings", "Settings related to the timer");

    settings.Add("split_settings", true, "Split Settings");
    settings.SetToolTip("split_settings", "Settings related to auto splitting");

    settings.CurrentDefaultParent = "timer_settings";

    settings.Add("igt_timer_start", true, "Start timer when IGT starts");
    settings.SetToolTip("igt_timer_start", "If disabled, it starts the timer when the RTA timer normally would start");

    settings.Add("ignore_igt", false, "Ignore IGT");
    settings.SetToolTip("ignore_igt", "If enabled, Livesplit will ignore the in-game timer, but it will still stop the timer when the game is loading (useful for testing strats)");

    settings.Add("area_change_start", false, "Start timer when the area changes");
    settings.SetToolTip("area_change_start", "If enabled, it starts the timer when the area changes");

    settings.CurrentDefaultParent = "split_settings";

    settings.Add("area_split", false, "Split whenever the area changes");
    settings.SetToolTip("area_split", "Split whenever you go to a different area, even if it doesn't stop IGT. The settings below will be ignored in case this is checked. (WARNING: not recommended for full game runs)");

    settings.Add("intro", true, "Intro");
    settings.SetToolTip("intro", "Split when you complete the intro");

    settings.Add("snake_pit", true, "Snake Pit");
    settings.SetToolTip("snake_pit", "Split when you leave the ruins after the snake pit");

    settings.Add("mine_skip", false, "Mine Skip");
    settings.SetToolTip("mine_skip", "Split when you leave the ruins by doing mine skip");

    settings.Add("ferdinand", true, "Ferdinand");
    settings.SetToolTip("ferdinand", "Split when you defeat Ferdinand");

    settings.Add("city_hall", true, "City Hall");
    settings.SetToolTip("city_hall", "Split when you defeat Bon Bonne in City Hall");

    settings.Add("marlwolf", true, "Marlwolf");
    settings.SetToolTip("marlwolf", "Split when you defeat Marlwolf");

    settings.Add("cardon_ruins", true, "Cardon Ruins");
    settings.SetToolTip("cardon_ruins", "Split when you clear Cardon Ruins");

    settings.Add("balkon_gerat", true, "Balkon Gerat");
    settings.SetToolTip("balkon_gerat", "Split when you defeat Balkon Gerat");

    settings.Add("jyun_ruins", true, "Jyun Ruins");
    settings.SetToolTip("jyun_ruins", "Split when you clear Jyun Ruins");

    settings.Add("clozer_ruins", true, "Clozer Ruins");
    settings.SetToolTip("clozer_ruins", "Split when you clear Clozer Ruins");

    settings.Add("focke_wulf", true, "Focke-Wulf");
    settings.SetToolTip("focke_wulf", "Split when you defeat Focke-Wulf");

    settings.Add("theodore_bruno", true, "Theodore Bruno");
    settings.SetToolTip("theodore_bruno", "Split when you defeat Theodore Bruno");

    settings.Add("uptown_subcity", true, "Uptown Subcity");
    settings.SetToolTip("uptown_subcity", "Split when you clear Uptown Subcity");

    settings.Add("downtown_subcity", true, "Downtown Subcity");
    settings.SetToolTip("downtown_subcity", "Split when you clear Downtown Subcity");

    settings.Add("old_town_subcity", true, "Old Town Subcity");
    settings.SetToolTip("old_town_subcity", "Split when you clear Old Town Subcity");

    settings.Add("end", true, "End");
    settings.SetToolTip("end", "Split when you talk to Roll after beating Juno");

    settings.CurrentDefaultParent = null;

    vars.IGTStarted = false;
    vars.IGTWhenTimerStarted = 0;

    vars.OnReset = (LiveSplit.Model.Input.EventHandlerT<TimerPhase>)((sender, e) => 
    {
        vars.IGTStarted = false;
        vars.IGTWhenTimerStarted = 0;
    });
    timer.OnReset += vars.OnReset;

    vars.OnStart = (EventHandler)((sender, e) => {
        vars.IGTStarted = vars.Memory["IGT"].Current > vars.Memory["IGT"].Old && vars.Memory["IGT"].Current > 1;
        vars.IGTWhenTimerStarted = vars.Memory["IGT"].Current;
    });
    timer.OnStart += vars.OnStart;
}

shutdown
{
    timer.OnStart -= vars.OnStart;
    timer.OnReset -= vars.OnReset;
}

init
{
    version = "DuckStation " + modules.First().FileVersionInfo.FileVersion;
    vars.BaseAddress = IntPtr.Zero;
    vars.GameIdWatcher = null;
    vars.Memory = null;
}

exit
{
    vars.IGTStarted = false;
    vars.IGTWhenTimerStarted = 0;
    vars.Memory = null;
    vars.BaseAddress = IntPtr.Zero;
    vars.GameIdWatcher = null;
}

update
{
    if (string.IsNullOrEmpty(version)) 
    {
        return false;
    }

    if (vars.BaseAddress == IntPtr.Zero) 
    {
        foreach (var page in game.MemoryPages(true)) 
        {
            if ((page.RegionSize == (UIntPtr)0x200000) && (page.Type == MemPageType.MEM_MAPPED))
            {
                vars.BaseAddress = page.BaseAddress;
                break;
            }
        }

        if (vars.BaseAddress != IntPtr.Zero)
        {
            vars.GameIdWatcher = new StringWatcher(new IntPtr((long)vars.BaseAddress + 0x925C), 11);
        }
    }


    if (vars.GameIdWatcher != null)
    {
        vars.GameIdWatcher.Update(game);

        if (vars.GameIdWatcher.Current != vars.GameIdWatcher.Old) 
        {
            if (vars.GameIdWatcher.Current == "SLUS_006.03")
            {
                print("SLUS_006.03");
                print("Base Address: " + ((long)vars.BaseAddress).ToString("X"));

                vars.Memory = new MemoryWatcherList();
                vars.Memory.Add(new MemoryWatcher<short>(new IntPtr((long)vars.BaseAddress + 0xC1B60)) { Name = "Area" });
                vars.Memory.Add(new MemoryWatcher<int>(new IntPtr((long)vars.BaseAddress + 0xC1B1C)) { Name = "IGT" });
                vars.Memory.Add(new MemoryWatcher<int>(new IntPtr((long)vars.BaseAddress + 0xC1B28)) { Name = "Clear Count" });
                vars.Memory.Add(new MemoryWatcher<byte>(new IntPtr((long)vars.BaseAddress + 0xBE37A)) { Name = "Story Flag 1" });
                vars.Memory.Add(new MemoryWatcher<byte>(new IntPtr((long)vars.BaseAddress + 0xBE382)) { Name = "Story Flag 2" });

                vars.Memory.UpdateAll(game);
            }
            else if (vars.GameIdWatcher.Current == "SLPS_011.41")
            {
                print("SLPS_011.41");
                print("Base Address: " + ((long)vars.BaseAddress).ToString("X"));

                vars.Memory = new MemoryWatcherList();
                vars.Memory.Add(new MemoryWatcher<short>(new IntPtr((long)vars.BaseAddress + 0xC1EB0)) { Name = "Area" });
                vars.Memory.Add(new MemoryWatcher<int>(new IntPtr((long)vars.BaseAddress + 0xC1E6C)) { Name = "IGT" });
                vars.Memory.Add(new MemoryWatcher<int>(new IntPtr((long)vars.BaseAddress + 0xC1E78)) { Name = "Clear Count" });
                vars.Memory.Add(new MemoryWatcher<byte>(new IntPtr((long)vars.BaseAddress + 0xBE6CA)) { Name = "Story Flag 1" });
                vars.Memory.Add(new MemoryWatcher<byte>(new IntPtr((long)vars.BaseAddress + 0xBE6D2)) { Name = "Story Flag 2" });
                
                vars.Memory.UpdateAll(game);
            }
            else
            {
                vars.Memory = null;
                vars.GameIdWatcher = null;
                vars.BaseAddress = IntPtr.Zero;
            }
        }
    }

    if (vars.Memory == null) 
    {
        return false;
    }

    vars.Memory.UpdateAll(game);

    if (!vars.IGTStarted)
    {
        vars.IGTStarted = vars.Memory["IGT"].Current > vars.Memory["IGT"].Old && vars.Memory["IGT"].Current > 1;
    }

    return true;
}

isLoading
{
    return true;
}

gameTime
{
    if (settings["ignore_igt"])
    {
        return TimeSpan.FromSeconds((vars.Memory["IGT"].Current - vars.IGTWhenTimerStarted) / 30.0D);
    }

    if (!vars.IGTStarted)
    {
        return TimeSpan.FromSeconds(0);
    }

    return TimeSpan.FromSeconds(vars.Memory["IGT"].Current / 30.0D);
}

start
{
    if (settings["area_change_start"])
    {
        return vars.Memory["Area"].Old != vars.Memory["Area"].Current;
    }

    if (settings["igt_timer_start"])
    {
        return vars.Memory["Area"].Current == 0x0000 && vars.Memory["IGT"].Current > vars.Memory["IGT"].Old && vars.Memory["IGT"].Old == 1;
    }
    
    return vars.Memory["Area"].Current == 0x0000 && vars.Memory["IGT"].Current == 1;
}


split
{
    if (settings["area_split"])
    {
        return vars.Memory["Area"].Old != vars.Memory["Area"].Current;
    }

    if (settings["intro"] && vars.Memory["Area"].Old == 0x0300 && vars.Memory["Area"].Current == 0x0400) // complete intro
    {
        return true;
    }

    if (settings["snake_pit"] && vars.Memory["Area"].Old == 0x0009 && vars.Memory["Area"].Current == 0x0203) // leave the snake pit
    {
        return true;
    }

    if (settings["mine_skip"] && vars.Memory["Area"].Old == 0x0209 && vars.Memory["Area"].Current == 0x0005) // do mine skip
    {
        return true;
    }

    if (settings["ferdinand"] && vars.Memory["Area"].Old == 0x0105 && vars.Memory["Area"].Current == 0x0206) // beat ferdinand
    {
        return true;
    }

    if (settings["city_hall"] && vars.Memory["Area"].Old == 0x0206 && vars.Memory["Area"].Current == 0x0506) // beat bon bonne in city hall
    {
        return true;
    }

    if (settings["marlwolf"] && vars.Memory["Area"].Current == 0x000A && vars.Memory["Story Flag 1"].Old == 0x01 && vars.Memory["Story Flag 1"].Current == 0x81) // beat marlwolf
    {
        return true;
    }

    if (settings["cardon_ruins"] && vars.Memory["Area"].Old == 0x000E && vars.Memory["Area"].Current == 0x000C) // finish cardon ruins
    {
        return true;
    }

    if (settings["balkon_gerat"] && vars.Memory["Area"].Old == 0x030B && vars.Memory["Area"].Current == 0x040B) // beat balkon gerat
    {
        return true;
    }

    if (settings["jyun_ruins"] && vars.Memory["Area"].Old == 0x0014 && vars.Memory["Area"].Current == 0x020B) // finish jyun ruins
    {
        return true;
    }

    if (settings["clozer_ruins"] && vars.Memory["Area"].Old == 0x0013 && vars.Memory["Area"].Current == 0x0C13) // finish jyun ruins
    {
        return true;
    }

    if (settings["focke_wulf"] && vars.Memory["Area"].Old == 0x0317 && vars.Memory["Area"].Current == 0x081B) // beat focke-wulf
    {
        return true;
    }

    if (settings["theodore_bruno"] && vars.Memory["Area"].Current == 0x0019 && vars.Memory["Story Flag 2"].Old == 0x5E && vars.Memory["Story Flag 2"].Current == 0x7E) // beat marlwolf
    {
        return true;
    }

    if (settings["uptown_subcity"] && vars.Memory["Area"].Old == 0x021D && vars.Memory["Area"].Current == 0x0008) // finish uptown subcity
    {
        return true;
    }

    if (settings["downtown_subcity"] && vars.Memory["Area"].Old == 0x011D && vars.Memory["Area"].Current == 0x0005) // finish downtown subcity
    {
        return true;
    }

    if (settings["old_town_subcity"] && vars.Memory["Area"].Old == 0x001D && vars.Memory["Area"].Current == 0x0319) // finish old town subcity
    {
        return true;
    }

    if (settings["end"] && vars.Memory["Clear Count"].Old + 1 == vars.Memory["Clear Count"].Current) // complete the game
    {
        return true;
    }

    return false;
}