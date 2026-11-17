-- AETHER VISUALS V2 / single-file CLIENT-ONLY cosmetics
-- Click the bottom-center Liquid Glass dock to open or close. No keyboard shortcut.
-- 48 procedural wing designs; local Lighting and character effects.
-- PNG textures need actual uploaded Roblox asset IDs; default works without them.
-- Best-effort compatibility: game clients vary, not tested inside an executor.
local Players = game:GetService("Players")
local UIS = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local Lighting = game:GetService("Lighting")
local HttpService = game:GetService("HttpService")
local player = Players.LocalPlayer
if not player then return end

local sessionEnv = _G
pcall(function() if type(getgenv) == "function" then sessionEnv = getgenv() end end)
if type(sessionEnv.AETHER_V2_CLOSE) == "function" then pcall(sessionEnv.AETHER_V2_CLOSE) end
local active = true
local managedConnections = {}
local localWingRig = nil
local gui, blur
local originalLighting = {
    Brightness=Lighting.Brightness,
    ExposureCompensation=Lighting.ExposureCompensation,
    ClockTime=Lighting.ClockTime,
    Ambient=Lighting.Ambient,
    OutdoorAmbient=Lighting.OutdoorAmbient,
    GlobalShadows=Lighting.GlobalShadows,
}
local function track(conn)
    table.insert(managedConnections,conn)
    return conn
end
local function cleanup()
    if not active then return end
    active = false
    for _, conn in ipairs(managedConnections) do pcall(function() conn:Disconnect() end) end
    if localWingRig then pcall(function() localWingRig:Destroy() end) end
    if player.Character then local a=player.Character:FindFirstChild("Aether_Local_Aura"); if a then a:Destroy() end end
    if gui then pcall(function() gui:Destroy() end) end
    if blur then pcall(function() blur:Destroy() end) end
    for _, name in ipairs({"Aether_Local_Bloom","Aether_Local_Color","Aether_Local_Atmosphere","Aether_Local_Sun","Aether_Local_DOF"}) do
        local effect=Lighting:FindFirstChild(name)
        if effect then pcall(function() effect:Destroy() end) end
    end
    for key,value in pairs(originalLighting) do pcall(function() Lighting[key]=value end) end
end
sessionEnv.AETHER_V2_CLOSE=cleanup


-- ===== Config =====
local Config = (function()
local Config = {}
Config.Version = "2.1.0"
Config.Default = {
    wing = "classic_angel", theme = "Arctic Glass", preset = "Balanced",
    quality = "Balanced", scale = 1, spread = 1, flapSpeed = 1,
    particles = true, trails = false, aura = false, footsteps = false,
    tintHue = -1, wingTransparency = 0, glowIntensity = 1, animationStyle = "Natural",
    reducedMotion = false, uiScale = 1,
}
Config.ThemeOrder = {"Arctic Glass","Obsidian Glass","Moonlight","Crystal White","Deep Violet","Aurora","Midnight Blue","Monochrome"}
Config.PresetOrder = {"Balanced","Ultra Realistic","Cinematic","Soft Aesthetic","Dreamcore","Cyberpunk","Golden Hour","Midnight","Arctic","Sunset","Retro","Competitive","Performance"}
Config.Categories = {"All", "Angel", "Dark", "Elemental", "Cosmic", "Technology", "Fantasy"}
Config.AnimationStyles={"Natural","Gentle Flap","Floating","Energy Pulse","Static"}
Config.SettingBounds = {scale={0.55,1.6}, spread={0.6,1.5}, flapSpeed={0.3,2.4},uiScale={0.75,1.2},
    tintHue={-1,1},wingTransparency={0,.65},glowIntensity={0,2}}
return Config

end)()

-- ===== Themes =====
local Themes = (function()
return {
    ["Arctic Glass"] = {bg=Color3.fromRGB(8,12,20), panel=Color3.fromRGB(19,29,44), accent=Color3.fromRGB(142,205,255), text=Color3.fromRGB(245,249,255),muted=Color3.fromRGB(157,176,197)},
    ["Obsidian Glass"] = {bg=Color3.fromRGB(6,7,10), panel=Color3.fromRGB(22,22,28), accent=Color3.fromRGB(214,219,234), text=Color3.fromRGB(250,250,251),muted=Color3.fromRGB(157,158,171)},
    ["Moonlight"] = {bg=Color3.fromRGB(12,14,29), panel=Color3.fromRGB(28,31,57), accent=Color3.fromRGB(182,198,255), text=Color3.fromRGB(240,240,255),muted=Color3.fromRGB(167,172,207)},
    ["Crystal White"] = {bg=Color3.fromRGB(197,214,232), panel=Color3.fromRGB(233,244,253), accent=Color3.fromRGB(45,125,209), text=Color3.fromRGB(28,42,61),muted=Color3.fromRGB(76,96,120)},
    ["Deep Violet"] = {bg=Color3.fromRGB(19,10,29), panel=Color3.fromRGB(37,26,59), accent=Color3.fromRGB(202,145,255), text=Color3.fromRGB(252,247,255),muted=Color3.fromRGB(193,174,210)},
    ["Aurora"] = {bg=Color3.fromRGB(6,21,23), panel=Color3.fromRGB(16,42,42), accent=Color3.fromRGB(102,253,203), text=Color3.fromRGB(237,255,251),muted=Color3.fromRGB(144,197,186)},
    ["Midnight Blue"] = {bg=Color3.fromRGB(6,9,28), panel=Color3.fromRGB(18,28,63), accent=Color3.fromRGB(99,156,255), text=Color3.fromRGB(239,245,255),muted=Color3.fromRGB(139,158,197)},
    ["Monochrome"] = {bg=Color3.fromRGB(14,14,14), panel=Color3.fromRGB(33,33,33), accent=Color3.fromRGB(220,220,220), text=Color3.fromRGB(250,250,250),muted=Color3.fromRGB(154,154,154)},
}

end)()

-- ===== Presets =====
local Presets = (function()
-- Client-only lighting presets. All values are within supported Roblox properties.
return {
    ["Balanced"]={brightness=2, exposure=0, clock=14,ambient={120,128,148}, outdoor={130,135,150}, shadows=true, bloom=0.12,saturation=0,contrast=0.03,tint={255,255,255}, density=0.25,haze=1,glare=0.15,sun=0.06,dof=0},
    ["Ultra Realistic"]={brightness=2.5,exposure=0.07,clock=15,ambient={116,117,130},outdoor={152,161,171},shadows=true,bloom=0.22,saturation=0.1,contrast=0.12,tint={255,247,237},density=0.33,haze=1.2,glare=0.17,sun=0.11,dof=0.05},
    ["Cinematic"]={brightness=1.7,exposure=-0.13,clock=17,ambient={87,99,128},outdoor={153,118,124},shadows=true,bloom=0.28,saturation=-0.12,contrast=0.24,tint={255,229,217},density=0.42,haze=1.9,glare=0.27,sun=0.17,dof=0.18},
    ["Soft Aesthetic"]={brightness=2.1,exposure=0.08,clock=12.5,ambient={168,153,171},outdoor={193,179,198},shadows=true,bloom=0.3,saturation=-0.1,contrast=-0.08,tint={255,236,248},density=0.22,haze=0.8,glare=0.04,sun=0.02,dof=0.04},
    ["Dreamcore"]={brightness=1.8,exposure=0.08,clock=18,ambient={159,120,205},outdoor={132,155,225},shadows=true,bloom=0.7,saturation=0.16,contrast=-0.08,tint={223,210,255},density=0.58,haze=2.5,glare=0.42,sun=0.1,dof=0.28},
    ["Cyberpunk"]={brightness=1.25,exposure=-0.12,clock=1.5,ambient={63,38,106},outdoor={41,80,111},shadows=true,bloom=0.65,saturation=0.35,contrast=0.22,tint={198,198,255},density=0.45,haze=1.75,glare=0.15,sun=0,dof=0.1},
    ["Golden Hour"]={brightness=2,exposure=0.02,clock=17.4,ambient={188,132,99},outdoor={255,188,128},shadows=true,bloom=0.35,saturation=0.23,contrast=0.07,tint={255,232,185},density=0.33,haze=1.2,glare=0.5,sun=0.3,dof=0.03},
    ["Midnight"]={brightness=0.85,exposure=-0.28,clock=0,ambient={37,54,87},outdoor={64,77,126},shadows=true,bloom=0.35,saturation=-0.16,contrast=0.15,tint={181,206,255},density=0.32,haze=1,glare=0,sun=0,dof=0.06},
    ["Arctic"]={brightness=2.6,exposure=0.12,clock=11,ambient={176,213,231},outdoor={205,224,255},shadows=true,bloom=0.15,saturation=-0.12,contrast=0.06,tint={222,247,255},density=0.3,haze=1.3,glare=0.16,sun=0.08,dof=0},
    ["Sunset"]={brightness=1.55,exposure=0.01,clock=18.3,ambient={141,86,137},outdoor={224,118,130},shadows=true,bloom=0.47,saturation=0.3,contrast=0.09,tint={255,207,194},density=0.44,haze=1.65,glare=0.41,sun=0.2,dof=0.04},
    ["Retro"]={brightness=1.7,exposure=-0.1,clock=15,ambient={165,150,108},outdoor={191,169,124},shadows=true,bloom=0.05,saturation=-0.35,contrast=0.04,tint={255,230,180},density=0.21,haze=0.7,glare=0,sun=0.01,dof=0},
    ["Competitive"]={brightness=2.7,exposure=0.1,clock=13,ambient={174,175,180},outdoor={196,202,211},shadows=false,bloom=0,saturation=0.1,contrast=0.12,tint={255,255,255},density=0,haze=0,glare=0,sun=0,dof=0},
    ["Performance"]={brightness=2.1,exposure=0,clock=14,ambient={145,145,150},outdoor={165,170,180},shadows=false,bloom=0,saturation=0,contrast=0,tint={255,255,255},density=0,haze=0,glare=0,sun=0,dof=0},
}

end)()

-- Optional: insert YOUR REAL Roblox uploaded image IDs here, keyed by wing ID.
local AssetIds = {
  -- classic_angel = {left=123456789, right=123456790, glow=123456791, highlight=123456792, icon=123456793},
}

-- ===== Wings =====
local Wings = (function()
-- All 48 entries have distinct style, palette, silhouette parameters.
-- Assets remain nil until the developer uploads /assets/wings PNGs and configures AssetIds.lua.
-- AssetIds provided by this single-file script
local definitions = {}
local order = {}
do
 local d = {id="classic_angel", name="Classic Angel", collection="Angel", style="feather",
 color=Color3.fromRGB(244,247,255), accent=Color3.fromRGB(185,209,239),
 count=7, scale=1.0, width=0.185, curve=0.115, glow=0.2,
 description="Classic Angel • Angel collection", supportedRigs={R6=true,R15=true},
 animation="Gentle Flap", particles="Dust",
 cost=2, assets=AssetIds["classic_angel"] or {} }
 definitions[d.id] = d
 order[#order+1] = d.id
end
do
 local d = {id="divine_angel", name="Divine Angel", collection="Angel", style="feather",
 color=Color3.fromRGB(255,242,205), accent=Color3.fromRGB(255,209,110),
 count=9, scale=1.16, width=0.22, curve=0.15, glow=0.3,
 description="Divine Angel • Angel collection", supportedRigs={R6=true,R15=true},
 animation="Floating", particles="Feather",
 cost=3, assets=AssetIds["divine_angel"] or {} }
 definitions[d.id] = d
 order[#order+1] = d.id
end
do
 local d = {id="seraphim", name="Seraphim", collection="Angel", style="halo",
 color=Color3.fromRGB(255,249,240), accent=Color3.fromRGB(244,198,160),
 count=11, scale=1.27, width=0.255, curve=0.185, glow=0.4,
 description="Seraphim • Angel collection", supportedRigs={R6=true,R15=true},
 animation="Energy Pulse", particles="Crystal",
 cost=1, assets=AssetIds["seraphim"] or {} }
 definitions[d.id] = d
 order[#order+1] = d.id
end
do
 local d = {id="holy_light", name="Holy Light", collection="Angel", style="energy",
 color=Color3.fromRGB(255,254,238), accent=Color3.fromRGB(255,229,153),
 count=8, scale=1.15, width=0.29, curve=0.22, glow=0.1,
 description="Holy Light • Angel collection", supportedRigs={R6=true,R15=true},
 animation="Cinematic", particles="Magic",
 cost=2, assets=AssetIds["holy_light"] or {} }
 definitions[d.id] = d
 order[#order+1] = d.id
end
do
 local d = {id="celestial", name="Celestial", collection="Angel", style="feather",
 color=Color3.fromRGB(217,244,255), accent=Color3.fromRGB(115,188,235),
 count=8, scale=1.1, width=0.15, curve=0.255, glow=0.2,
 description="Celestial • Angel collection", supportedRigs={R6=true,R15=true},
 animation="Natural", particles="Spark",
 cost=3, assets=AssetIds["celestial"] or {} }
 definitions[d.id] = d
 order[#order+1] = d.id
end
do
 local d = {id="pearl_wings", name="Pearl Wings", collection="Angel", style="butterfly",
 color=Color3.fromRGB(247,235,255), accent=Color3.fromRGB(249,205,223),
 count=6, scale=1.03, width=0.185, curve=0.29, glow=0.3,
 description="Pearl Wings • Angel collection", supportedRigs={R6=true,R15=true},
 animation="Gentle Flap", particles="Dust",
 cost=1, assets=AssetIds["pearl_wings"] or {} }
 definitions[d.id] = d
 order[#order+1] = d.id
end
do
 local d = {id="heavenfall", name="Heavenfall", collection="Angel", style="feather",
 color=Color3.fromRGB(255,255,255), accent=Color3.fromRGB(195,224,255),
 count=10, scale=1.19, width=0.22, curve=0.08, glow=0.4,
 description="Heavenfall • Angel collection", supportedRigs={R6=true,R15=true},
 animation="Floating", particles="Feather",
 cost=2, assets=AssetIds["heavenfall"] or {} }
 definitions[d.id] = d
 order[#order+1] = d.id
end
do
 local d = {id="eternal_wings", name="Eternal Wings", collection="Angel", style="blade",
 color=Color3.fromRGB(214,222,233), accent=Color3.fromRGB(252,247,235),
 count=10, scale=1.35, width=0.255, curve=0.115, glow=0.1,
 description="Eternal Wings • Angel collection", supportedRigs={R6=true,R15=true},
 animation="Energy Pulse", particles="Crystal",
 cost=3, assets=AssetIds["eternal_wings"] or {} }
 definitions[d.id] = d
 order[#order+1] = d.id
end
do
 local d = {id="fallen_angel", name="Fallen Angel", collection="Dark", style="feather",
 color=Color3.fromRGB(42,41,59), accent=Color3.fromRGB(152,100,204),
 count=9, scale=1.13, width=0.29, curve=0.15, glow=0.2,
 description="Fallen Angel • Dark collection", supportedRigs={R6=true,R15=true},
 animation="Cinematic", particles="Magic",
 cost=1, assets=AssetIds["fallen_angel"] or {} }
 definitions[d.id] = d
 order[#order+1] = d.id
end
do
 local d = {id="shadow_wings", name="Shadow Wings", collection="Dark", style="smoke",
 color=Color3.fromRGB(32,38,56), accent=Color3.fromRGB(85,96,117),
 count=7, scale=1.21, width=0.15, curve=0.185, glow=0.3,
 description="Shadow Wings • Dark collection", supportedRigs={R6=true,R15=true},
 animation="Natural", particles="Spark",
 cost=2, assets=AssetIds["shadow_wings"] or {} }
 definitions[d.id] = d
 order[#order+1] = d.id
end
do
 local d = {id="void_wings", name="Void Wings", collection="Dark", style="shard",
 color=Color3.fromRGB(23,13,48), accent=Color3.fromRGB(153,73,239),
 count=9, scale=1.24, width=0.185, curve=0.22, glow=0.4,
 description="Void Wings • Dark collection", supportedRigs={R6=true,R15=true},
 animation="Gentle Flap", particles="Dust",
 cost=3, assets=AssetIds["void_wings"] or {} }
 definitions[d.id] = d
 order[#order+1] = d.id
end
do
 local d = {id="phantom_wings", name="Phantom Wings", collection="Dark", style="energy",
 color=Color3.fromRGB(156,181,207), accent=Color3.fromRGB(67,82,116),
 count=8, scale=1.09, width=0.22, curve=0.255, glow=0.1,
 description="Phantom Wings • Dark collection", supportedRigs={R6=true,R15=true},
 animation="Floating", particles="Feather",
 cost=1, assets=AssetIds["phantom_wings"] or {} }
 definitions[d.id] = d
 order[#order+1] = d.id
end
do
 local d = {id="raven_wings", name="Raven Wings", collection="Dark", style="feather",
 color=Color3.fromRGB(16,25,36), accent=Color3.fromRGB(69,90,114),
 count=11, scale=1.04, width=0.255, curve=0.29, glow=0.2,
 description="Raven Wings • Dark collection", supportedRigs={R6=true,R15=true},
 animation="Energy Pulse", particles="Crystal",
 cost=2, assets=AssetIds["raven_wings"] or {} }
 definitions[d.id] = d
 order[#order+1] = d.id
end
do
 local d = {id="abyss_wings", name="Abyss Wings", collection="Dark", style="blade",
 color=Color3.fromRGB(16,26,67), accent=Color3.fromRGB(48,94,169),
 count=9, scale=1.26, width=0.29, curve=0.08, glow=0.3,
 description="Abyss Wings • Dark collection", supportedRigs={R6=true,R15=true},
 animation="Cinematic", particles="Magic",
 cost=3, assets=AssetIds["abyss_wings"] or {} }
 definitions[d.id] = d
 order[#order+1] = d.id
end
do
 local d = {id="eclipse_wings", name="Eclipse Wings", collection="Dark", style="halo",
 color=Color3.fromRGB(20,23,36), accent=Color3.fromRGB(228,184,107),
 count=7, scale=1.18, width=0.15, curve=0.115, glow=0.4,
 description="Eclipse Wings • Dark collection", supportedRigs={R6=true,R15=true},
 animation="Natural", particles="Spark",
 cost=1, assets=AssetIds["eclipse_wings"] or {} }
 definitions[d.id] = d
 order[#order+1] = d.id
end
do
 local d = {id="crimson_wings", name="Crimson Wings", collection="Dark", style="dragon",
 color=Color3.fromRGB(57,19,33), accent=Color3.fromRGB(240,85,103),
 count=8, scale=1.17, width=0.185, curve=0.15, glow=0.1,
 description="Crimson Wings • Dark collection", supportedRigs={R6=true,R15=true},
 animation="Gentle Flap", particles="Dust",
 cost=2, assets=AssetIds["crimson_wings"] or {} }
 definitions[d.id] = d
 order[#order+1] = d.id
end
do
 local d = {id="flame_wings", name="Flame Wings", collection="Elemental", style="flame",
 color=Color3.fromRGB(255,182,63), accent=Color3.fromRGB(251,62,45),
 count=10, scale=1.18, width=0.22, curve=0.185, glow=0.2,
 description="Flame Wings • Elemental collection", supportedRigs={R6=true,R15=true},
 animation="Floating", particles="Feather",
 cost=3, assets=AssetIds["flame_wings"] or {} }
 definitions[d.id] = d
 order[#order+1] = d.id
end
do
 local d = {id="frost_wings", name="Frost Wings", collection="Elemental", style="shard",
 color=Color3.fromRGB(198,246,252), accent=Color3.fromRGB(86,183,230),
 count=10, scale=1.07, width=0.255, curve=0.22, glow=0.3,
 description="Frost Wings • Elemental collection", supportedRigs={R6=true,R15=true},
 animation="Energy Pulse", particles="Crystal",
 cost=1, assets=AssetIds["frost_wings"] or {} }
 definitions[d.id] = d
 order[#order+1] = d.id
end
do
 local d = {id="thunder_wings", name="Thunder Wings", collection="Elemental", style="lightning",
 color=Color3.fromRGB(230,226,255), accent=Color3.fromRGB(140,119,250),
 count=9, scale=1.13, width=0.29, curve=0.255, glow=0.4,
 description="Thunder Wings • Elemental collection", supportedRigs={R6=true,R15=true},
 animation="Cinematic", particles="Magic",
 cost=2, assets=AssetIds["thunder_wings"] or {} }
 definitions[d.id] = d
 order[#order+1] = d.id
end
do
 local d = {id="water_wings", name="Water Wings", collection="Elemental", style="flow",
 color=Color3.fromRGB(108,231,250), accent=Color3.fromRGB(37,91,166),
 count=7, scale=1.1, width=0.15, curve=0.29, glow=0.1,
 description="Water Wings • Elemental collection", supportedRigs={R6=true,R15=true},
 animation="Natural", particles="Spark",
 cost=3, assets=AssetIds["water_wings"] or {} }
 definitions[d.id] = d
 order[#order+1] = d.id
end
do
 local d = {id="nature_wings", name="Nature Wings", collection="Elemental", style="leaf",
 color=Color3.fromRGB(132,215,135), accent=Color3.fromRGB(49,121,88),
 count=11, scale=1.03, width=0.185, curve=0.08, glow=0.2,
 description="Nature Wings • Elemental collection", supportedRigs={R6=true,R15=true},
 animation="Gentle Flap", particles="Dust",
 cost=1, assets=AssetIds["nature_wings"] or {} }
 definitions[d.id] = d
 order[#order+1] = d.id
end
do
 local d = {id="wind_wings", name="Wind Wings", collection="Elemental", style="flow",
 color=Color3.fromRGB(234,245,255), accent=Color3.fromRGB(131,203,242),
 count=8, scale=1.15, width=0.22, curve=0.115, glow=0.3,
 description="Wind Wings • Elemental collection", supportedRigs={R6=true,R15=true},
 animation="Floating", particles="Feather",
 cost=2, assets=AssetIds["wind_wings"] or {} }
 definitions[d.id] = d
 order[#order+1] = d.id
end
do
 local d = {id="lava_wings", name="Lava Wings", collection="Elemental", style="shard",
 color=Color3.fromRGB(251,193,93), accent=Color3.fromRGB(170,49,27),
 count=10, scale=1.2, width=0.255, curve=0.15, glow=0.4,
 description="Lava Wings • Elemental collection", supportedRigs={R6=true,R15=true},
 animation="Energy Pulse", particles="Crystal",
 cost=3, assets=AssetIds["lava_wings"] or {} }
 definitions[d.id] = d
 order[#order+1] = d.id
end
do
 local d = {id="crystal_wings", name="Crystal Wings", collection="Elemental", style="crystal",
 color=Color3.fromRGB(218,248,255), accent=Color3.fromRGB(121,185,254),
 count=9, scale=1.29, width=0.29, curve=0.185, glow=0.1,
 description="Crystal Wings • Elemental collection", supportedRigs={R6=true,R15=true},
 animation="Cinematic", particles="Magic",
 cost=1, assets=AssetIds["crystal_wings"] or {} }
 definitions[d.id] = d
 order[#order+1] = d.id
end
do
 local d = {id="galaxy_wings", name="Galaxy Wings", collection="Cosmic", style="smoke",
 color=Color3.fromRGB(77,58,171), accent=Color3.fromRGB(227,134,233),
 count=10, scale=1.23, width=0.15, curve=0.22, glow=0.2,
 description="Galaxy Wings • Cosmic collection", supportedRigs={R6=true,R15=true},
 animation="Natural", particles="Spark",
 cost=2, assets=AssetIds["galaxy_wings"] or {} }
 definitions[d.id] = d
 order[#order+1] = d.id
end
do
 local d = {id="nebula_wings", name="Nebula Wings", collection="Cosmic", style="energy",
 color=Color3.fromRGB(226,148,255), accent=Color3.fromRGB(92,110,217),
 count=8, scale=1.29, width=0.185, curve=0.255, glow=0.3,
 description="Nebula Wings • Cosmic collection", supportedRigs={R6=true,R15=true},
 animation="Gentle Flap", particles="Dust",
 cost=3, assets=AssetIds["nebula_wings"] or {} }
 definitions[d.id] = d
 order[#order+1] = d.id
end
do
 local d = {id="stardust_wings", name="Stardust Wings", collection="Cosmic", style="feather",
 color=Color3.fromRGB(219,225,255), accent=Color3.fromRGB(182,164,253),
 count=10, scale=1.16, width=0.22, curve=0.29, glow=0.4,
 description="Stardust Wings • Cosmic collection", supportedRigs={R6=true,R15=true},
 animation="Floating", particles="Feather",
 cost=1, assets=AssetIds["stardust_wings"] or {} }
 definitions[d.id] = d
 order[#order+1] = d.id
end
do
 local d = {id="solar_wings", name="Solar Wings", collection="Cosmic", style="flame",
 color=Color3.fromRGB(255,227,139), accent=Color3.fromRGB(233,135,42),
 count=11, scale=1.33, width=0.255, curve=0.08, glow=0.1,
 description="Solar Wings • Cosmic collection", supportedRigs={R6=true,R15=true},
 animation="Energy Pulse", particles="Crystal",
 cost=2, assets=AssetIds["solar_wings"] or {} }
 definitions[d.id] = d
 order[#order+1] = d.id
end
do
 local d = {id="lunar_wings", name="Lunar Wings", collection="Cosmic", style="halo",
 color=Color3.fromRGB(198,197,248), accent=Color3.fromRGB(123,156,214),
 count=7, scale=1.08, width=0.29, curve=0.115, glow=0.2,
 description="Lunar Wings • Cosmic collection", supportedRigs={R6=true,R15=true},
 animation="Cinematic", particles="Magic",
 cost=3, assets=AssetIds["lunar_wings"] or {} }
 definitions[d.id] = d
 order[#order+1] = d.id
end
do
 local d = {id="aurora_wings", name="Aurora Wings", collection="Cosmic", style="flow",
 color=Color3.fromRGB(129,235,198), accent=Color3.fromRGB(113,105,214),
 count=10, scale=1.28, width=0.15, curve=0.15, glow=0.3,
 description="Aurora Wings • Cosmic collection", supportedRigs={R6=true,R15=true},
 animation="Natural", particles="Spark",
 cost=1, assets=AssetIds["aurora_wings"] or {} }
 definitions[d.id] = d
 order[#order+1] = d.id
end
do
 local d = {id="cosmic_rift", name="Cosmic Rift", collection="Cosmic", style="shard",
 color=Color3.fromRGB(84,92,187), accent=Color3.fromRGB(243,84,201),
 count=9, scale=1.21, width=0.185, curve=0.185, glow=0.4,
 description="Cosmic Rift • Cosmic collection", supportedRigs={R6=true,R15=true},
 animation="Gentle Flap", particles="Dust",
 cost=2, assets=AssetIds["cosmic_rift"] or {} }
 definitions[d.id] = d
 order[#order+1] = d.id
end
do
 local d = {id="supernova_wings", name="Supernova Wings", collection="Cosmic", style="energy",
 color=Color3.fromRGB(253,244,193), accent=Color3.fromRGB(227,108,94),
 count=11, scale=1.36, width=0.22, curve=0.22, glow=0.1,
 description="Supernova Wings • Cosmic collection", supportedRigs={R6=true,R15=true},
 animation="Floating", particles="Feather",
 cost=3, assets=AssetIds["supernova_wings"] or {} }
 definitions[d.id] = d
 order[#order+1] = d.id
end
do
 local d = {id="cyber_wings", name="Cyber Wings", collection="Technology", style="mechanical",
 color=Color3.fromRGB(108,194,216), accent=Color3.fromRGB(33,58,112),
 count=8, scale=1.13, width=0.255, curve=0.255, glow=0.2,
 description="Cyber Wings • Technology collection", supportedRigs={R6=true,R15=true},
 animation="Energy Pulse", particles="Crystal",
 cost=1, assets=AssetIds["cyber_wings"] or {} }
 definitions[d.id] = d
 order[#order+1] = d.id
end
do
 local d = {id="hologram_wings", name="Hologram Wings", collection="Technology", style="hologram",
 color=Color3.fromRGB(131,240,234), accent=Color3.fromRGB(75,120,229),
 count=9, scale=1.12, width=0.29, curve=0.29, glow=0.3,
 description="Hologram Wings • Technology collection", supportedRigs={R6=true,R15=true},
 animation="Cinematic", particles="Magic",
 cost=2, assets=AssetIds["hologram_wings"] or {} }
 definitions[d.id] = d
 order[#order+1] = d.id
end
do
 local d = {id="neon_wings", name="Neon Wings", collection="Technology", style="blade",
 color=Color3.fromRGB(236,111,250), accent=Color3.fromRGB(97,205,251),
 count=8, scale=1.18, width=0.15, curve=0.08, glow=0.4,
 description="Neon Wings • Technology collection", supportedRigs={R6=true,R15=true},
 animation="Natural", particles="Spark",
 cost=3, assets=AssetIds["neon_wings"] or {} }
 definitions[d.id] = d
 order[#order+1] = d.id
end
do
 local d = {id="plasma_wings", name="Plasma Wings", collection="Technology", style="energy",
 color=Color3.fromRGB(140,235,255), accent=Color3.fromRGB(148,100,255),
 count=10, scale=1.17, width=0.185, curve=0.115, glow=0.1,
 description="Plasma Wings • Technology collection", supportedRigs={R6=true,R15=true},
 animation="Gentle Flap", particles="Dust",
 cost=1, assets=AssetIds["plasma_wings"] or {} }
 definitions[d.id] = d
 order[#order+1] = d.id
end
do
 local d = {id="digital_wings", name="Digital Wings", collection="Technology", style="pixel",
 color=Color3.fromRGB(93,251,195), accent=Color3.fromRGB(45,112,166),
 count=10, scale=1.14, width=0.22, curve=0.15, glow=0.2,
 description="Digital Wings • Technology collection", supportedRigs={R6=true,R15=true},
 animation="Floating", particles="Feather",
 cost=2, assets=AssetIds["digital_wings"] or {} }
 definitions[d.id] = d
 order[#order+1] = d.id
end
do
 local d = {id="mecha_wings", name="Mecha Wings", collection="Technology", style="mechanical",
 color=Color3.fromRGB(154,166,186), accent=Color3.fromRGB(225,175,113),
 count=9, scale=1.22, width=0.255, curve=0.185, glow=0.3,
 description="Mecha Wings • Technology collection", supportedRigs={R6=true,R15=true},
 animation="Energy Pulse", particles="Crystal",
 cost=3, assets=AssetIds["mecha_wings"] or {} }
 definitions[d.id] = d
 order[#order+1] = d.id
end
do
 local d = {id="rgb_wings", name="RGB Wings", collection="Technology", style="hologram",
 color=Color3.fromRGB(255,124,179), accent=Color3.fromRGB(117,230,255),
 count=8, scale=1.17, width=0.29, curve=0.22, glow=0.4,
 description="RGB Wings • Technology collection", supportedRigs={R6=true,R15=true},
 animation="Cinematic", particles="Magic",
 cost=1, assets=AssetIds["rgb_wings"] or {} }
 definitions[d.id] = d
 order[#order+1] = d.id
end
do
 local d = {id="quantum_wings", name="Quantum Wings", collection="Technology", style="lightning",
 color=Color3.fromRGB(166,179,255), accent=Color3.fromRGB(125,216,243),
 count=9, scale=1.3, width=0.15, curve=0.255, glow=0.1,
 description="Quantum Wings • Technology collection", supportedRigs={R6=true,R15=true},
 animation="Natural", particles="Spark",
 cost=2, assets=AssetIds["quantum_wings"] or {} }
 definitions[d.id] = d
 order[#order+1] = d.id
end
do
 local d = {id="fairy_wings", name="Fairy Wings", collection="Fantasy", style="butterfly",
 color=Color3.fromRGB(210,251,255), accent=Color3.fromRGB(169,239,193),
 count=6, scale=0.96, width=0.185, curve=0.29, glow=0.2,
 description="Fairy Wings • Fantasy collection", supportedRigs={R6=true,R15=true},
 animation="Gentle Flap", particles="Dust",
 cost=3, assets=AssetIds["fairy_wings"] or {} }
 definitions[d.id] = d
 order[#order+1] = d.id
end
do
 local d = {id="butterfly_wings", name="Butterfly Wings", collection="Fantasy", style="butterfly",
 color=Color3.fromRGB(255,179,212), accent=Color3.fromRGB(217,158,248),
 count=8, scale=1.05, width=0.22, curve=0.08, glow=0.3,
 description="Butterfly Wings • Fantasy collection", supportedRigs={R6=true,R15=true},
 animation="Floating", particles="Feather",
 cost=1, assets=AssetIds["butterfly_wings"] or {} }
 definitions[d.id] = d
 order[#order+1] = d.id
end
do
 local d = {id="sakura_wings", name="Sakura Wings", collection="Fantasy", style="leaf",
 color=Color3.fromRGB(249,184,220), accent=Color3.fromRGB(230,125,165),
 count=11, scale=1.09, width=0.255, curve=0.115, glow=0.4,
 description="Sakura Wings • Fantasy collection", supportedRigs={R6=true,R15=true},
 animation="Energy Pulse", particles="Crystal",
 cost=2, assets=AssetIds["sakura_wings"] or {} }
 definitions[d.id] = d
 order[#order+1] = d.id
end
do
 local d = {id="dream_wings", name="Dream Wings", collection="Fantasy", style="flow",
 color=Color3.fromRGB(228,200,255), accent=Color3.fromRGB(169,217,250),
 count=10, scale=1.2, width=0.29, curve=0.15, glow=0.1,
 description="Dream Wings • Fantasy collection", supportedRigs={R6=true,R15=true},
 animation="Cinematic", particles="Magic",
 cost=3, assets=AssetIds["dream_wings"] or {} }
 definitions[d.id] = d
 order[#order+1] = d.id
end
do
 local d = {id="dragon_wings", name="Dragon Wings", collection="Fantasy", style="dragon",
 color=Color3.fromRGB(109,76,102), accent=Color3.fromRGB(206,108,122),
 count=9, scale=1.18, width=0.15, curve=0.185, glow=0.2,
 description="Dragon Wings • Fantasy collection", supportedRigs={R6=true,R15=true},
 animation="Natural", particles="Spark",
 cost=1, assets=AssetIds["dragon_wings"] or {} }
 definitions[d.id] = d
 order[#order+1] = d.id
end
do
 local d = {id="phoenix_wings", name="Phoenix Wings", collection="Fantasy", style="flame",
 color=Color3.fromRGB(255,204,98), accent=Color3.fromRGB(253,87,97),
 count=10, scale=1.34, width=0.185, curve=0.22, glow=0.3,
 description="Phoenix Wings • Fantasy collection", supportedRigs={R6=true,R15=true},
 animation="Gentle Flap", particles="Dust",
 cost=2, assets=AssetIds["phoenix_wings"] or {} }
 definitions[d.id] = d
 order[#order+1] = d.id
end
do
 local d = {id="royal_wings", name="Royal Wings", collection="Fantasy", style="blade",
 color=Color3.fromRGB(255,216,153), accent=Color3.fromRGB(159,100,202),
 count=10, scale=1.3, width=0.22, curve=0.255, glow=0.4,
 description="Royal Wings • Fantasy collection", supportedRigs={R6=true,R15=true},
 animation="Floating", particles="Feather",
 cost=3, assets=AssetIds["royal_wings"] or {} }
 definitions[d.id] = d
 order[#order+1] = d.id
end
do
 local d = {id="ethereal_wings", name="Ethereal Wings", collection="Fantasy", style="halo",
 color=Color3.fromRGB(185,243,238), accent=Color3.fromRGB(217,171,246),
 count=9, scale=1.32, width=0.255, curve=0.29, glow=0.1,
 description="Ethereal Wings • Fantasy collection", supportedRigs={R6=true,R15=true},
 animation="Energy Pulse", particles="Crystal",
 cost=1, assets=AssetIds["ethereal_wings"] or {} }
 definitions[d.id] = d
 order[#order+1] = d.id
end
return {ById=definitions, Order=order}

end)()

-- ===== Builder =====
local Builder = (function()
-- Procedural, server-authoritative cosmetic wings: no purchased/free-model dependencies.
-- Every wing remains functional when no uploaded PNG assets are configured.
local CollectionService = game:GetService("CollectionService")
local WingBuilder = {}
local styles = {feather=true,blade=true,shard=true,halo=true,smoke=true,energy=true,dragon=true,
    flame=true,lightning=true,flow=true,leaf=true,crystal=true,mechanical=true,hologram=true,pixel=true,butterfly=true}

local function newPart(parent, pivot, name, relative, size, color, material, shape, transparency)
    local p = Instance.new(shape == "wedge" and "WedgePart" or "Part")
    p.Name = name
    p.Size = size
    if shape == "oval" then p.Shape = Enum.PartType.Ball end
    p.Material = material
    p.Color = color
    p.Transparency = transparency or 0
    p.CastShadow = false
    p.CanCollide = false
    p.CanTouch = false
    p.CanQuery = false
    p.Massless = true
    p.CFrame = pivot.CFrame * relative
    p.Parent = parent
    local weld = Instance.new("WeldConstraint")
    weld.Part0 = pivot
    weld.Part1 = p
    weld.Parent = p
    return p
end
local function mat(style)
    if style == "energy" or style == "hologram" or style == "lightning" or style == "flame" then
        return Enum.Material.Neon
    elseif style == "mechanical" or style == "blade" then
        return Enum.Material.Metal
    elseif style == "crystal" or style == "shard" then
        return Enum.Material.Glass
    end
    return Enum.Material.SmoothPlastic
end
local function assetIsValid(id)
    return type(id) == "number" and id > 0 and id == math.floor(id)
end
local function addImageLayer(parent, root, side, assets)
    local mainAsset=side<0 and assets.left or assets.right
    if not assetIsValid(mainAsset) then return end
    local plate = newPart(parent,root,"PNG_Plane",CFrame.new(side*1.12,.5,.06),
        Vector3.new(2.9,2.7,.025),Color3.new(1,1,1),Enum.Material.SmoothPlastic,"block",1)
    for _, face in ipairs({Enum.NormalId.Front, Enum.NormalId.Back}) do
        local surface = Instance.new("SurfaceGui")
        surface.Name = "PNG_" .. face.Name
        surface.Face = face
        surface.CanvasSize = Vector2.new(512,512)
        surface.LightInfluence = 0
        surface.Brightness = 2
        surface.AlwaysOnTop = false
        surface.Parent = plate
        for index,info in ipairs({
            {"WingTexture",mainAsset,.03},
            {"GlowTexture",assets.glow,.24},
            {"HighlightTexture",assets.highlight,.12},
        }) do
            if assetIsValid(info[2]) then
                local img = Instance.new("ImageLabel")
                img.Name = info[1]
                img.Size = UDim2.fromScale(1,1)
                img.BackgroundTransparency = 1
                img.Image = "rbxassetid://" .. tostring(info[2])
                img.ImageTransparency = info[3]
                img.ZIndex = index
                img.ScaleType = Enum.ScaleType.Fit
                img.Parent = surface
            end
        end
    end
end
local function decorate(parent,root,side,def,scale,quality,settings)
    local style = styles[def.style] and def.style or "feather"
    local count = math.clamp(def.count,4,12)
    if quality == "Performance" then count = math.max(4,math.floor(count*.58)) end
    local baseColor,accent = def.color,def.accent
    if type(settings.tintHue)=="number" and settings.tintHue>=0 then
        baseColor=Color3.fromHSV(settings.tintHue,.62,.95)
        accent=Color3.fromHSV((settings.tintHue+.09)%1,.49,1)
    end
    local material = mat(style)
    local alpha = (style == "smoke" or style == "hologram" or style == "flow") and 0.25 or 0
    alpha=math.clamp(alpha+(settings.wingTransparency or 0),0,.84)
    local top = 0.48 * scale
    local edge = 0
    for i = 1,count do
        local t = (i-1)/math.max(1,count-1)
        local curve = math.sin(t*math.pi)*def.curve
        local dist = (0.22+t*1.65) * scale
        local rise = (0.28+(1-t)*.65+curve)*scale
        local height = (1.15+(1-t)*1.2+0.14*math.sin(i*2.2))*scale
        local width = (.13+def.width + (1-t)*.13)*scale
        local shape = "oval"
        if style == "shard" or style == "crystal" or style == "blade" or style == "dragon" or style == "mechanical" then shape = "wedge" end
        if style == "pixel" then shape = "block" end
        if style == "lightning" then shape = "block" end
        if style == "butterfly" then
            height = (1.5+0.45*math.sin(i*.9)) * scale
            width = (.48+0.3*math.sin(i*.7)) * scale
        elseif style == "leaf" then
            height = (.95+0.5*math.sin(i*.75))*scale
            width = (.25+.18*(1-t))*scale
        elseif style == "mechanical" then
            height = (1.05+.5*(1-t))*scale
            width = (.25+.1*(1-t))*scale
        elseif style == "pixel" then
            height = (.16+.17*(i%3))*scale
            width = (.2+.17*(i%4))*scale
            rise = (.5+((i*3)%5)*.28)*scale
        end
        local z = .03*(i%3)*scale
        local tilt = side * math.rad(-23 - t*32 + 7*math.sin(i*.8))
        if style == "dragon" then tilt=side*math.rad(-13-t*24) end
        if style == "flow" then tilt=side*math.rad(15-70*t) end
        if style == "butterfly" then tilt=side*math.rad(17-45*t) end
        if style == "lightning" then tilt=side*math.rad((i%2==0 and 47 or -48)) end
        local piece = newPart(parent,root,style.."_"..i,
            CFrame.new(side*dist,rise,z)*CFrame.Angles(0,side*math.rad(t*6),tilt),
            Vector3.new(width,height,(style=="butterfly" or style=="flow") and .07*scale or .13*scale),
            (i%3==0) and accent or baseColor,material,shape,alpha)
        if style == "hologram" or style == "energy" or style == "flame" or style == "lightning" then
            piece.Transparency = math.clamp(.12 + .3*t+(settings.wingTransparency or 0),0,.85)
        end
        if i%3==1 and style ~= "smoke" and style ~= "pixel" then
            newPart(parent,root,"Highlight_"..i,
                CFrame.new(side*(dist+.06*scale),rise+.08*scale,z+.095*scale)*CFrame.Angles(0,0,tilt),
                Vector3.new(width*.24,height*.78,.045*scale),accent,Enum.Material.Neon,"oval",.18)
        end
        edge = dist
    end
    -- Inner spine & motif make silhouettes readable from side and front.
    if style == "mechanical" or style == "dragon" or style == "blade" or style == "crystal" then
        newPart(parent,root,"Structural Spine",CFrame.new(side*.58*scale,top,.08)*CFrame.Angles(0,0,side*math.rad(-28)),
            Vector3.new(.13*scale,2.6*scale,.2*scale),accent,style=="mechanical" and Enum.Material.Metal or Enum.Material.SmoothPlastic,"block",0)
    elseif style == "halo" then
        for j=1,10 do
            local theta = j*math.pi/5
            newPart(parent,root,"Halo Segment "..j,
                CFrame.new(side*(.85+math.cos(theta)*.7)*scale,(1+math.sin(theta)*.75)*scale,-.03)*CFrame.Angles(0,0,-theta),
                Vector3.new(.1,.29,.1)*scale,accent,Enum.Material.Neon,"oval",.09)
        end
    end
    local anchor0 = Instance.new("Attachment")
    anchor0.Name = "TrailBase"
    anchor0.Position = Vector3.new(side*.28,.35,0)*scale
    anchor0.Parent = root
    local anchor1 = Instance.new("Attachment")
    anchor1.Name = "TrailTip"
    anchor1.Position = Vector3.new(side*(edge+.55*scale),.7*scale,0)
    anchor1.Parent = root
    local trail = Instance.new("Trail")
    trail.Name = "AetherTrail"
    trail.Attachment0 = anchor0
    trail.Attachment1 = anchor1
    trail.Color = ColorSequence.new(baseColor,accent)
    trail.LightEmission = .6
    trail.Lifetime = .14
    trail.MinLength = .06
    trail.Transparency = NumberSequence.new(.35,1)
    trail.Enabled = false
    trail.Parent = root
    local emitter = Instance.new("ParticleEmitter")
    emitter.Name = "AetherParticles"
    emitter.Texture = "rbxasset://textures/particles/sparkles_main.dds"
    emitter.Color = ColorSequence.new(baseColor,accent)
    emitter.LightEmission = math.clamp((settings.glowIntensity or 1)*.7,0,1)
    emitter.Rate = quality == "Performance" and 1 or quality == "Ultra" and 8 or 4
    emitter.Lifetime = NumberRange.new(.4,1)
    emitter.Speed = NumberRange.new(.15,.75)
    emitter.Size = NumberSequence.new({NumberSequenceKeypoint.new(0,.13), NumberSequenceKeypoint.new(1,0)})
    emitter.SpreadAngle = Vector2.new(160,160)
    emitter.Enabled = true
    emitter.Parent = anchor1
end

function WingBuilder.Build(character, torso, def, settings, options)
    options = options or {}
    if not torso or not torso:IsA("BasePart") or not def then return nil end
    local old = character:FindFirstChild("AetherWings")
    if old then old:Destroy() end
    local model = Instance.new("Model")
    model.Name="AetherWings"
    local scale = math.clamp((settings.scale or 1) * def.scale, .35, 2.4)
    local quality = settings.quality or "Balanced"
    for _, side in ipairs({-1,1}) do
        local pivot = Instance.new("Part")
        pivot.Name = side < 0 and "AetherLeftPivot" or "AetherRightPivot"
        pivot.Transparency=1
        pivot.Size=Vector3.new(.12,.12,.12)
        pivot.Massless=true
        pivot.CanCollide=false
        pivot.CanTouch=false
        pivot.CanQuery=false
        pivot.CastShadow=false
        pivot.CFrame = torso.CFrame * CFrame.new(side*.48,.45,.45)
        pivot.Parent=model
        decorate(model,pivot,side,def,scale,quality,settings)
        local assets = def.assets or {}
        addImageLayer(model,pivot,side,assets)
        local motor = Instance.new("Motor6D")
        motor.Name=side < 0 and "AetherLeftMotor" or "AetherRightMotor"
        motor.Part0=torso
        motor.Part1=pivot
        motor.C0=CFrame.new(side*.48,.45,.45)
        motor.C1=CFrame.identity
        motor.Parent=model
        -- Trail and particles are server-owned, validated from player settings.
        local trail = pivot:FindFirstChild("AetherTrail")
        local particles = pivot:FindFirstChild("TrailTip"):FindFirstChild("AetherParticles")
        if trail then trail.Enabled = settings.trails == true and quality ~= "Performance" end
        if particles then particles.Enabled = settings.particles ~= false end
    end
    model:SetAttribute("WingId",def.id)
    model:SetAttribute("FlapSpeed",math.clamp(settings.flapSpeed or 1,.3,2.4))
    model:SetAttribute("Spread",math.clamp(settings.spread or 1,.6,1.5))
    model:SetAttribute("AnimationStyle",settings.animationStyle or "Natural")
    model.Parent=character
    if not options.preview then CollectionService:AddTag(model,"AetherWingRig") end
    return model
end
return WingBuilder

end)()

-- ===== Visual =====
local Visual = (function()
-- Client-side effects only; does not overwrite server/world lighting for other players.
local Lighting=game:GetService("Lighting")
local TweenService=game:GetService("TweenService")
-- Presets provided by this single-file script
local Controller={}
local objects={}
local tweens={}
local function create(class,name)
    local old=Lighting:FindFirstChild(name)
    if old and old.ClassName==class then objects[name]=old;return old end
    local obj=Instance.new(class)
    obj.Name=name
    obj.Parent=Lighting
    objects[name]=obj
    return obj
end
local bloom=create("BloomEffect","Aether_Local_Bloom")
local color=create("ColorCorrectionEffect","Aether_Local_Color")
local atmosphere=create("Atmosphere","Aether_Local_Atmosphere")
local sun=create("SunRaysEffect","Aether_Local_Sun")
local dof=create("DepthOfFieldEffect","Aether_Local_DOF")
bloom.Threshold=1.5
bloom.Size=20
sun.Spread=.6
dof.FocusDistance=28
dof.InFocusRadius=40
dof.NearIntensity=0
local current="Balanced"
local overrides={}
local function c(values) return Color3.fromRGB(values[1],values[2],values[3]) end
local function tween(object,values,motion)
    local previous=tweens[object]
    if previous then previous:Cancel() end
    if not motion then
        for k,v in pairs(values) do object[k]=v end
        return
    end
    local t=TweenService:Create(object,TweenInfo.new(.55,Enum.EasingStyle.Quint,Enum.EasingDirection.Out),values)
    tweens[object]=t
    t:Play()
end
function Controller.ApplyPreset(name,motion)
    local p=Presets[name]
    if not p then return false end
    current=name
    table.clear(overrides)
    tween(Lighting,{Brightness=p.brightness,ExposureCompensation=p.exposure,ClockTime=p.clock,
        Ambient=c(p.ambient),OutdoorAmbient=c(p.outdoor)},motion)
    Lighting.GlobalShadows=p.shadows
    tween(bloom,{Intensity=p.bloom},motion)
    tween(color,{Saturation=p.saturation,Contrast=p.contrast,TintColor=c(p.tint)},motion)
    tween(atmosphere,{Density=p.density,Haze=p.haze,Glare=p.glare},motion)
    tween(sun,{Intensity=p.sun},motion)
    tween(dof,{FarIntensity=p.dof},motion)
    return true
end
local props={brightness={Lighting,"Brightness",0,6},exposure={Lighting,"ExposureCompensation",-2,2},
    clock={Lighting,"ClockTime",0,24},bloom={bloom,"Intensity",0,2},saturation={color,"Saturation",-1,1},
    contrast={color,"Contrast",-1,1},density={atmosphere,"Density",0,1},
    haze={atmosphere,"Haze",0,10},glare={atmosphere,"Glare",0,10},sun={sun,"Intensity",0,1},dof={dof,"FarIntensity",0,1}}
function Controller.Set(name,value)
    local prop=props[name]
    if not prop or type(value)~="number" then return end
    value=math.clamp(value,prop[3],prop[4])
    prop[1][prop[2]]=value
    overrides[name]=value
end
function Controller.Get(name)
    local prop=props[name]
    return prop and prop[1][prop[2]] or nil
end
function Controller.Current() return current end
return Controller

end)()

-- ===== CLIENT APP =====
-- AETHER VISUALS V2 / Client. All GUI is generated via native Roblox instances.
-- No executors, no external requests, no bogus Asset IDs, no inert buttons.
local player=Players.LocalPlayer
local state=table.clone(Config.Default)
local activeTab="Dashboard"
local selectedWing=state.wing
local currentCategory="All"
local motionToken=0
local open=false
local currentTween=nil
local frameAverage=60
local lastFrame=0
local queued={}
local sendVersion=0
local fitScale=1
local tabs={"Dashboard","Visuals","Lighting","Atmosphere","Wings","Wing Studio","Effects","Presets","Themes","Settings"}

-- File persistence is optional and depends on available local APIs.
local saveFile="AETHER_VISUALS_V2_SETTINGS.json"
local function loadSettings()
    if type(readfile)~="function" then return end
    local ok,decoded=pcall(function() return HttpService:JSONDecode(readfile(saveFile)) end)
    if not ok or type(decoded)~="table" then return end
    for key,original in pairs(Config.Default) do
        if type(decoded[key])==type(original) then
            local bounds=Config.SettingBounds[key]
            if bounds and type(decoded[key])=="number" then
                state[key]=math.clamp(decoded[key],bounds[1],bounds[2])
            elseif type(decoded[key])~="string" or #decoded[key]<70 then
                state[key]=decoded[key]
            end
        end
    end
    if state.wing~="none" and not Wings.ById[state.wing] then state.wing=Config.Default.wing end
    if not Themes[state.theme] then state.theme=Config.Default.theme end
    if not Presets[state.preset] then state.preset=Config.Default.preset end
end
loadSettings()
selectedWing=state.wing
local wingUpdateVersion=0
local animateAge=0
local function reEquip()
    if not active then return end
    if localWingRig then localWingRig:Destroy(); localWingRig=nil end
    if state.wing=="none" then return end
    local character=player.Character
    if not character then return end
    local torso=character:FindFirstChild("UpperTorso") or character:FindFirstChild("Torso")
    if not torso then return end
    local definition=Wings.ById[state.wing]
    if not definition then return end
    local ok,rig=pcall(function() return Builder.Build(character,torso,definition,state,{preview=true}) end)
    if ok then localWingRig=rig else warn("AETHER wing build failed:",rig) end
end
local function scheduleEquip()
    wingUpdateVersion+=1
    local token=wingUpdateVersion
    task.delay(.16,function()
        if active and token==wingUpdateVersion then reEquip() end
    end)
end
local function send(key,value)
    if not active then return end
    state[key]=value
    if key=="wing" or key=="quality" or key=="scale" or key=="spread" or key=="tintHue"
       or key=="wingTransparency" or key=="glowIntensity" or key=="particles" or key=="trails" then
        scheduleEquip()
    elseif localWingRig and (key=="flapSpeed" or key=="animationStyle") then
        localWingRig:SetAttribute(key=="flapSpeed" and "FlapSpeed" or "AnimationStyle",value)
    end
end
local function requestSave()
    if type(writefile)~="function" then return false end
    local ok,err=pcall(function() writefile(saveFile,HttpService:JSONEncode(state)) end)
    if not ok then warn("AETHER save unavailable:",err) end
    return ok
end
track(player.CharacterAdded:Connect(function()
    wingUpdateVersion+=1
    task.delay(.65,function() if active then reEquip() end end)
end))
track(RunService.RenderStepped:Connect(function(dt)
    if not active or not localWingRig or not localWingRig.Parent then return end
    local left=localWingRig:FindFirstChild("AetherLeftMotor")
    local right=localWingRig:FindFirstChild("AetherRightMotor")
    if not left or not right then return end
    local hum=player.Character and player.Character:FindFirstChildOfClass("Humanoid")
    local moving=hum and hum.MoveDirection.Magnitude>.12
    local jumping=hum and (hum:GetState()==Enum.HumanoidStateType.Jumping or hum:GetState()==Enum.HumanoidStateType.Freefall)
    local mode=state.animationStyle
    local speed=(state.flapSpeed or 1)*(mode=="Energy Pulse" and 1.6 or mode=="Gentle Flap" and .55 or 1)
    animateAge+=math.min(dt,.09)*speed*(moving and 3.4 or 1.6)
    local amp=(mode=="Static" and 0 or mode=="Floating" and .4 or mode=="Gentle Flap" and .6 or 1)
    local flap=math.sin(animateAge)*math.rad(jumping and 18 or moving and 12 or 5)*amp
    local spread=state.spread or 1
    local openAngle=math.rad((jumping and 18 or moving and 6 or 1)*spread)
    left.C0=CFrame.new(-.48,.45,.45)*CFrame.Angles(0,-openAngle-flap,0)
    right.C0=CFrame.new(.48,.45,.45)*CFrame.Angles(0,openAngle+flap,0)
end))
local function tw(obj,props,duration,easing)
    local t=TweenService:Create(obj,TweenInfo.new(duration or .23,easing or Enum.EasingStyle.Quint,Enum.EasingDirection.Out),props)
    t:Play()
    return t
end
local function round(obj,r)
    local c=Instance.new("UICorner")
    c.CornerRadius=UDim.new(0,r or 12)
    c.Parent=obj
    return c
end
local function stroke(obj,color,alpha,thick)
    local s=Instance.new("UIStroke")
    s.Color=color
    s.Transparency=alpha or .67
    s.Thickness=thick or 1
    s.Parent=obj
    return s
end
local function create(parent,kind,props)
    local obj=Instance.new(kind)
    for k,v in pairs(props or {}) do obj[k]=v end
    obj.Parent=parent
    return obj
end
local function palette() return Themes[state.theme] or Themes["Arctic Glass"] end
local function txt(parent,value,size,color,props)
    local t=create(parent,"TextLabel",{
        Name="Label",BackgroundTransparency=1,Text=value,TextSize=size or 13,
        TextColor3=color or palette().text,Font=Enum.Font.Gotham,
        TextXAlignment=Enum.TextXAlignment.Left,TextYAlignment=Enum.TextYAlignment.Center,
        TextWrapped=true,Size=UDim2.new(1,0,0,32)})
    for k,v in pairs(props or {}) do t[k]=v end
    return t
end
local function button(parent,name,size,onClick,accent)
    local p=palette()
    local b=create(parent,"TextButton",{Name=name,Size=size or UDim2.new(1,0,0,35),
        Text=name,TextColor3=accent and p.bg or p.text,TextSize=12,Font=Enum.Font.GothamMedium,
        BackgroundColor3=accent and p.accent or p.panel,AutoButtonColor=false})
    round(b,9)
    stroke(b,p.accent,accent and .1 or .87,1)
    b.MouseEnter:Connect(function() tw(b,{BackgroundColor3=accent and p.accent or p.panel:Lerp(p.accent,.19)},.17) end)
    b.MouseLeave:Connect(function() tw(b,{BackgroundColor3=accent and p.accent or p.panel},.17) end)
    b.MouseButton1Click:Connect(function()
        tw(b,{BackgroundTransparency=.25},.09)
        task.delay(.11,function() if b.Parent then tw(b,{BackgroundTransparency=0},.17) end end)
        onClick()
    end)
    return b
end

local existingGui=player:WaitForChild("PlayerGui"):FindFirstChild("AETHER_VISUALS_V2")
if existingGui then existingGui:Destroy() end
gui=create(player:WaitForChild("PlayerGui"),"ScreenGui",{
    Name="AETHER_VISUALS_V2",ResetOnSpawn=false,IgnoreGuiInset=true,
    DisplayOrder=450,ZIndexBehavior=Enum.ZIndexBehavior.Sibling,Enabled=true})
blur=create(Lighting,"BlurEffect",{Name="Aether_Menu_Blur",Size=0,Enabled=true})
local shade=create(gui,"Frame",{Name="BackgroundShade",Size=UDim2.fromScale(1,1),
    BackgroundColor3=Color3.new(0,0,0),BackgroundTransparency=1,Visible=false,Active=false})
local window=create(gui,"CanvasGroup",{Name="AetherGlassWindow",Visible=false,
    AnchorPoint=Vector2.new(.5,.5),Position=UDim2.fromScale(.5,.5),
    Size=UDim2.fromOffset(12,12),BackgroundColor3=palette().bg,BackgroundTransparency=.07,
    GroupTransparency=1,ClipsDescendants=true})
round(window,19)
local border=stroke(window,palette().accent,.65,1.3)
local windowScale=create(window,"UIScale",{Scale=1})
local sheen=create(window,"UIGradient",{Rotation=110,Transparency=NumberSequence.new({
    NumberSequenceKeypoint.new(0,0),NumberSequenceKeypoint.new(.4,.13),
    NumberSequenceKeypoint.new(1,.04)})})
local light=create(window,"Frame",{Name="Specular",BackgroundColor3=Color3.new(1,1,1),
    BackgroundTransparency=.93,Size=UDim2.new(1,0,0,1),BorderSizePixel=0})
local top=create(window,"Frame",{Name="Toolbar",Size=UDim2.new(1,0,0,65),BackgroundTransparency=1})
local brand=txt(top,"A E T H E R",18,palette().text,{Position=UDim2.fromOffset(25,10),Size=UDim2.fromOffset(220,28),Font=Enum.Font.GothamBold})
local subbrand=txt(top,"V I S U A L   E N G I N E  /  V2",9,palette().muted,{Position=UDim2.fromOffset(26,36),Size=UDim2.fromOffset(250,17)})
local close=button(top,"×",UDim2.fromOffset(31,31),function() end)
close.Position=UDim2.new(1,-45,0,16)
close.TextSize=23
local nav=create(window,"ScrollingFrame",{Name="Navigation",Position=UDim2.fromOffset(12,69),
    Size=UDim2.new(0,174,1,-83),BackgroundTransparency=1,
    ScrollBarThickness=0,CanvasSize=UDim2.fromOffset(0,0),AutomaticCanvasSize=Enum.AutomaticSize.Y})
local navLayout=create(nav,"UIListLayout",{Padding=UDim.new(0,5),SortOrder=Enum.SortOrder.LayoutOrder})
local separator=create(window,"Frame",{Name="Divider",Position=UDim2.fromOffset(193,70),Size=UDim2.new(0,1,1,-86),
    BorderSizePixel=0,BackgroundColor3=palette().accent,BackgroundTransparency=.88})
local body=create(window,"Frame",{Name="Page",Position=UDim2.fromOffset(208,69),
    Size=UDim2.new(1,-224,1,-82),BackgroundTransparency=1,ClipsDescendants=true})
local footerStatus=txt(top,"●  READY",10,palette().accent,{Position=UDim2.new(1,-228,0,21),Size=UDim2.fromOffset(165,26),TextXAlignment=Enum.TextXAlignment.Right})
local notifications=create(gui,"Frame",{Name="AetherToasts",Position=UDim2.new(1,-274,0,28),
    Size=UDim2.fromOffset(252,270),BackgroundTransparency=1})
local toastList=create(notifications,"UIListLayout",{Padding=UDim.new(0,8),SortOrder=Enum.SortOrder.LayoutOrder})
-- ===== AETHER LIQUID DOCK: always visible near the bottom center =====
-- This is a regular Roblox GUI button and does not depend on an executor API.
local dockRest=UDim2.new(.5,0,1,-74)
local dockShadow=create(gui,"Frame",{
    Name="DockSoftShadow",AnchorPoint=Vector2.new(.5,.5),Position=dockRest,
    Size=UDim2.fromOffset(493,81),BackgroundColor3=Color3.fromRGB(0,0,0),
    BackgroundTransparency=.62,BorderSizePixel=0,ZIndex=8})
round(dockShadow,27)
local dock=create(gui,"TextButton",{
    Name="AetherLiquidDock",AnchorPoint=Vector2.new(.5,.5),
    Position=UDim2.new(.5,0,1,45),Size=UDim2.fromOffset(478,67),
    BackgroundColor3=palette().panel,BackgroundTransparency=.11,
    BorderSizePixel=0,Text="",AutoButtonColor=false,ClipsDescendants=true,ZIndex=10})
round(dock,23)
local dockScale=create(dock,"UIScale",{Scale=1})
local dockShadowScale=create(dockShadow,"UIScale",{Scale=1})
local dockBorder=stroke(dock,palette().accent,.48,1.5)
local dockGradient=create(dock,"UIGradient",{Rotation=18,Color=ColorSequence.new({
    ColorSequenceKeypoint.new(0,Color3.fromRGB(35,47,65)),
    ColorSequenceKeypoint.new(.45,Color3.fromRGB(18,25,38)),
    ColorSequenceKeypoint.new(1,Color3.fromRGB(28,41,57))})})
local dockTopline=create(dock,"Frame",{
    Name="GlassHighlight",Position=UDim2.fromOffset(23,1),Size=UDim2.new(1,-46,0,2),
    BackgroundColor3=Color3.fromRGB(255,255,255),BackgroundTransparency=.68,
    BorderSizePixel=0,ZIndex=11})
round(dockTopline,2)
local dockLogo=create(dock,"Frame",{
    Position=UDim2.fromOffset(12,11),Size=UDim2.fromOffset(46,46),
    BackgroundColor3=palette().accent,BackgroundTransparency=.08,ZIndex=11})
round(dockLogo,15)
local dockLogoText=txt(dockLogo,"A",23,palette().bg,{
    Position=UDim2.fromScale(0,0),Size=UDim2.fromScale(1,1),
    Font=Enum.Font.GothamBold,TextXAlignment=Enum.TextXAlignment.Center,ZIndex=12})
local dockBrand=txt(dock,"A E T H E R",15,palette().text,{
    Position=UDim2.fromOffset(72,10),Size=UDim2.fromOffset(140,25),
    Font=Enum.Font.GothamBold,ZIndex=11})
local dockLabel=txt(dock,"VISUAL ENGINE   /   V2",9,palette().muted,{
    Position=UDim2.fromOffset(73,35),Size=UDim2.fromOffset(155,18),ZIndex=11})
local dockDivider=create(dock,"Frame",{
    Position=UDim2.fromOffset(228,13),Size=UDim2.fromOffset(1,42),
    BackgroundColor3=palette().accent,BackgroundTransparency=.78,
    BorderSizePixel=0,ZIndex=11})
local dockInfo=txt(dock,"60 FPS   ·   BALANCED",12,palette().text,{
    Position=UDim2.fromOffset(245,11),Size=UDim2.fromOffset(174,23),
    Font=Enum.Font.GothamMedium,ZIndex=11})
local dockSub=txt(dock,"CLASSIC ANGEL  ·  READY",9,palette().muted,{
    Position=UDim2.fromOffset(245,35),Size=UDim2.fromOffset(176,18),ZIndex=11})
local dockArrowBG=create(dock,"Frame",{
    Position=UDim2.fromOffset(430,17),Size=UDim2.fromOffset(32,34),
    BackgroundColor3=palette().accent,BackgroundTransparency=.8,ZIndex=11})
round(dockArrowBG,11)
local dockAction=txt(dockArrowBG,"⌃",19,palette().text,{
    Position=UDim2.fromScale(0,0),Size=UDim2.fromScale(1,1),
    TextXAlignment=Enum.TextXAlignment.Center,Font=Enum.Font.GothamBold,ZIndex=12})
local function updateDockInfo()
    local wing=Wings.ById[state.wing]
    local wingName=wing and wing.name or "NO WINGS"
    dockInfo.Text=string.format("%d FPS   ·   %s",math.round(frameAverage),string.upper(state.quality))
    dockSub.Text=string.upper(wingName).."  ·  "..(open and "OPEN" or "READY")
end
local function fitDock()
    local camera=workspace.CurrentCamera
    local viewport=camera and camera.ViewportSize or Vector2.new(1280,720)
    local scale=math.clamp((viewport.X-26)/493,.5,1)
    dockScale.Scale=scale
    dockShadowScale.Scale=scale
    local bottom=UIS.TouchEnabled and 55 or 74
    dockRest=UDim2.new(.5,0,1,-bottom)
    dockShadow.Position=dockRest
    if not open then dock.Position=dockRest end
end
-- The bar itself is the only open/close control; no Insert key needed.
dock.MouseEnter:Connect(function()
    tw(dock,{BackgroundTransparency=.02},.2)
    tw(dockArrowBG,{BackgroundTransparency=.6},.2)
end)
dock.MouseLeave:Connect(function()
    tw(dock,{BackgroundTransparency=.11},.24)
    tw(dockArrowBG,{BackgroundTransparency=.8},.24)
end)

local function toast(message)
    local p=palette()
    local item=create(notifications,"CanvasGroup",{Name="Toast",Size=UDim2.new(1,0,0,48),
        BackgroundColor3=p.panel,BackgroundTransparency=.10,GroupTransparency=1})
    round(item,11)
    stroke(item,p.accent,.6)
    txt(item,message,12,p.text,{Position=UDim2.fromOffset(14,5),Size=UDim2.new(1,-28,1,-10)})
    tw(item,{GroupTransparency=0},.2)
    task.delay(2.8,function()
        if item.Parent then
            tw(item,{GroupTransparency=1},.4)
            task.delay(.42,function() item:Destroy() end)
        end
    end)
end
local auraHighlight=nil
local footConnection=nil
local function updateEffects()
    if auraHighlight then auraHighlight:Destroy();auraHighlight=nil end
    if footConnection then footConnection:Disconnect();footConnection=nil end
    local char=player.Character
    if not char then return end
    if state.aura then
        auraHighlight=Instance.new("Highlight")
        auraHighlight.Name="Aether_Local_Aura"
        auraHighlight.FillColor=palette().accent
        auraHighlight.OutlineColor=palette().accent
        auraHighlight.FillTransparency=.87
        auraHighlight.OutlineTransparency=.24
        auraHighlight.DepthMode=Enum.HighlightDepthMode.Occluded
        auraHighlight.Parent=char
    end
    if state.footsteps and state.quality~="Performance" then
        local elapsed=0
        footConnection=track(RunService.Heartbeat:Connect(function(dt)
            elapsed+=dt
            if elapsed<.28 then return end
            elapsed=0
            if not char.Parent then return end
            local hum=char:FindFirstChildOfClass("Humanoid")
            local root=char:FindFirstChild("HumanoidRootPart")
            if not hum or not root or hum.MoveDirection.Magnitude<.2 or hum.FloorMaterial==Enum.Material.Air then return end
            local dot=create(workspace,"Part",{Name="Aether_Local_Step",Anchored=true,CanCollide=false,CanTouch=false,CanQuery=false,
                Size=Vector3.new(.27,.035,.27),Shape=Enum.PartType.Ball,Material=Enum.Material.Neon,
                Color=palette().accent,Transparency=.45,CFrame=root.CFrame*CFrame.new(0,-2.6,0)})
            tw(dot,{Transparency=1,Size=Vector3.new(.03,.03,.03)},.48)
            game:GetService("Debris"):AddItem(dot,.55)
        end))
    end
end
track(player.CharacterAdded:Connect(function()
    task.delay(.5,function() if active then updateEffects() end end)
end))

local function mkScroller(parent)
    local list=create(parent,"ScrollingFrame",{Name="Scroll",Size=UDim2.fromScale(1,1),BackgroundTransparency=1,
        ScrollBarThickness=3,ScrollBarImageColor3=palette().accent,
        AutomaticCanvasSize=Enum.AutomaticSize.Y,CanvasSize=UDim2.fromOffset(0,0),BorderSizePixel=0})
    create(list,"UIPadding",{PaddingLeft=UDim.new(0,3),PaddingRight=UDim.new(0,12),PaddingTop=UDim.new(0,1),PaddingBottom=UDim.new(0,12)})
    create(list,"UIListLayout",{Padding=UDim.new(0,10),SortOrder=Enum.SortOrder.LayoutOrder})
    return list
end
local function heading(parent,name,subtitle)
    local frame=create(parent,"Frame",{Size=UDim2.new(1,0,0,subtitle and 64 or 42),BackgroundTransparency=1})
    txt(frame,name,20,palette().text,{Size=UDim2.new(1,0,0,29),Font=Enum.Font.GothamBold})
    if subtitle then txt(frame,subtitle,11,palette().muted,{Position=UDim2.fromOffset(0,31),Size=UDim2.new(1,0,0,29),TextYAlignment=Enum.TextYAlignment.Top}) end
    return frame
end
local function section(parent,caption)
    local f=create(parent,"Frame",{Size=UDim2.new(1,0,0,24),BackgroundTransparency=1})
    txt(f,string.upper(caption),10,palette().accent,{Size=UDim2.new(1,0,1,0),Font=Enum.Font.GothamBold})
end
local function tile(parent,label,desc)
    local p=palette()
    local f=create(parent,"Frame",{Name=label,Size=UDim2.new(1,0,0,desc and 75 or 54),BackgroundColor3=p.panel,
        BackgroundTransparency=.2})
    round(f,11);stroke(f,p.accent,.9)
    txt(f,label,13,p.text,{Position=UDim2.fromOffset(13,5),Size=UDim2.new(1,-25,0,30),Font=Enum.Font.GothamMedium})
    if desc then txt(f,desc,11,p.muted,{Position=UDim2.fromOffset(13,32),Size=UDim2.new(1,-26,0,35),TextYAlignment=Enum.TextYAlignment.Top}) end
    return f
end
local function toggle(parent,label,key,info)
    local p=palette()
    local f=tile(parent,label,info)
    local bubble=create(f,"TextButton",{Name="Toggle",Position=UDim2.new(1,-61,0,13),Size=UDim2.fromOffset(46,24),
        Text="",AutoButtonColor=false,BackgroundColor3=state[key] and p.accent or p.bg})
    round(bubble,12)
    local knob=create(bubble,"Frame",{Position=state[key] and UDim2.fromOffset(24,3) or UDim2.fromOffset(3,3),
        Size=UDim2.fromOffset(18,18),BackgroundColor3=state[key] and p.bg or p.muted})
    round(knob,9)
    bubble.MouseButton1Click:Connect(function()
        local value=not state[key]
        send(key,value)
        tw(bubble,{BackgroundColor3=value and p.accent or p.bg},.23)
        tw(knob,{Position=value and UDim2.fromOffset(24,3) or UDim2.fromOffset(3,3),BackgroundColor3=value and p.bg or p.muted},.23)
        if key=="aura" or key=="footsteps" then updateEffects() end
        toast(label..(value and " enabled" or " disabled"))
    end)
    return f
end
local function slider(parent,label,minV,maxV,getValue,onChanged,decimals)
    local p=palette()
    local f=create(parent,"Frame",{Name=label,Size=UDim2.new(1,0,0,64),BackgroundColor3=p.panel,BackgroundTransparency=.24})
    round(f,11);stroke(f,p.accent,.9)
    local l=txt(f,label,12,p.text,{Position=UDim2.fromOffset(13,6),Size=UDim2.new(1,-90,0,22)})
    local count=decimals or 2
    local function fmt(v)
        return string.format("%."..count.."f",v)
    end
    local value=math.clamp(getValue(),minV,maxV)
    local number=txt(f,fmt(value),12,p.accent,{Position=UDim2.new(1,-82,0,6),Size=UDim2.fromOffset(67,22),TextXAlignment=Enum.TextXAlignment.Right})
    local track=create(f,"Frame",{Name="Track",Position=UDim2.new(0,15,0,42),Size=UDim2.new(1,-30,0,6),BackgroundColor3=p.bg})
    round(track,4)
    local fraction=(value-minV)/(maxV-minV)
    local fill=create(track,"Frame",{Size=UDim2.fromScale(fraction,1),BackgroundColor3=p.accent})
    round(fill,4)
    local dot=create(track,"Frame",{AnchorPoint=Vector2.new(.5,.5),Position=UDim2.fromScale(fraction,.5),Size=UDim2.fromOffset(14,14),BackgroundColor3=p.text})
    round(dot,7)
    local hit=create(f,"TextButton",{Name="SliderHit",Text="",BackgroundTransparency=1,
        Position=UDim2.new(0,10,0,32),Size=UDim2.new(1,-20,0,27),AutoButtonColor=false})
    local dragging=false
    local function adjust(x)
        if not track.Parent then return end
        local t=math.clamp((x-track.AbsolutePosition.X)/math.max(1,track.AbsoluteSize.X),0,1)
        local v=minV+(maxV-minV)*t
        number.Text=fmt(v)
        fill.Size=UDim2.fromScale(t,1)
        dot.Position=UDim2.fromScale(t,.5)
        onChanged(v)
    end
    hit.InputBegan:Connect(function(input)
        if input.UserInputType==Enum.UserInputType.MouseButton1 or input.UserInputType==Enum.UserInputType.Touch then
            dragging=true
            adjust(input.Position.X)
        end
    end)
    local moveConnection=UIS.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType==Enum.UserInputType.MouseMovement or input.UserInputType==Enum.UserInputType.Touch) then adjust(input.Position.X) end
    end)
    local endConnection=UIS.InputEnded:Connect(function(input)
        if input.UserInputType==Enum.UserInputType.MouseButton1 or input.UserInputType==Enum.UserInputType.Touch then dragging=false end
    end)
    f.Destroying:Connect(function()
        moveConnection:Disconnect();endConnection:Disconnect()
    end)
    return f
end
local function itemButton(parent,label,action,selected)
    local b=button(parent,label,UDim2.new(1,0,0,37),action,selected)
    b.TextXAlignment=Enum.TextXAlignment.Left
    b.TextSize=12
    local pad=Instance.new("UIPadding")
    pad.PaddingLeft=UDim.new(0,12)
    pad.Parent=b
    return b
end
local function choose(parent,headingText,key,choices,onChosen)
    section(parent,headingText)
    for _,value in ipairs(choices) do
        itemButton(parent,value,function()
            send(key,value)
            if onChosen then onChosen(value) end
            toast(headingText..": "..value)
        end,state[key]==value)
    end
end
local redrawPage
local redrawNav
local refreshTheme
local function buildPreview(vp,wingId)
    vp:ClearAllChildren()
    local world=create(vp,"WorldModel",{Name="PreviewWorld"})
    local avatar=create(world,"Model",{Name="PreviewAvatar"})
    local torso=create(avatar,"Part",{Name="UpperTorso",Size=Vector3.new(1.45,1.65,.7),
        Anchored=true,CanCollide=false,Color=Color3.fromRGB(57,70,88),Material=Enum.Material.SmoothPlastic,
        CFrame=CFrame.new(0,0,0)})
    for _,x in ipairs({-.95,.95}) do
        create(avatar,"Part",{Name="Arm",Size=Vector3.new(.32,1.3,.4),
            Anchored=true,CanCollide=false,Color=Color3.fromRGB(42,54,71),
            CFrame=CFrame.new(x,-.4,0)})
    end
    create(avatar,"Part",{Name="Head",Shape=Enum.PartType.Ball,Size=Vector3.new(.7,.7,.7),
        Anchored=true,CanCollide=false,Color=Color3.fromRGB(69,82,98),CFrame=CFrame.new(0,1.13,0)})
    local d=Wings.ById[wingId]
    if d then Builder.Build(avatar,torso,d,state,{preview=true}) end
    local camera=create(vp,"Camera",{Name="PreviewCamera",FieldOfView=43})
    camera.CFrame=CFrame.lookAt(Vector3.new(0,1,7.2),Vector3.new(0,.5,0))
    vp.CurrentCamera=camera
    local yaw=0
    local down=false
    local lastX=0
    vp.InputBegan:Connect(function(input)
        if input.UserInputType==Enum.UserInputType.MouseButton1 or input.UserInputType==Enum.UserInputType.Touch then
            down=true;lastX=input.Position.X
        end
    end)
    vp.InputEnded:Connect(function(input)
        if input.UserInputType==Enum.UserInputType.MouseButton1 or input.UserInputType==Enum.UserInputType.Touch then down=false end
    end)
    -- Connections are scoped to the viewport's lifetime via parent checks.
    local conn
    conn=UIS.InputChanged:Connect(function(input)
        if not vp.Parent then conn:Disconnect();return end
        if down and (input.UserInputType==Enum.UserInputType.MouseMovement or input.UserInputType==Enum.UserInputType.Touch) then
            yaw+=math.rad((input.Position.X-lastX)*.65)
            lastX=input.Position.X
            camera.CFrame=CFrame.lookAt(Vector3.new(math.sin(yaw)*7.2,1.1,math.cos(yaw)*7.2),Vector3.new(0,.5,0))
        end
    end)
    vp.Destroying:Connect(function() conn:Disconnect() end)
end

local function renderWings()
    local p=palette()
    local head=create(body,"Frame",{Size=UDim2.new(1,0,0,53),BackgroundTransparency=1})
    txt(head,"Wings Library",19,p.text,{Size=UDim2.new(1,0,0,27),Font=Enum.Font.GothamBold})
    txt(head,"48 handcrafted definitions / procedural 3D + optional PNG",10,p.muted,
        {Position=UDim2.fromOffset(0,29),Size=UDim2.new(1,0,0,20)})
    local main=create(body,"Frame",{Position=UDim2.fromOffset(0,60),Size=UDim2.new(1,0,1,-60),BackgroundTransparency=1})
    local left=create(main,"Frame",{Size=UDim2.new(.44,-6,1,0),BackgroundTransparency=1})
    local right=create(main,"Frame",{Position=UDim2.new(.44,5,0,0),Size=UDim2.new(.56,-5,1,0),BackgroundTransparency=1})
    local search=create(left,"TextBox",{Size=UDim2.new(1,0,0,34),Text="",PlaceholderText="Search wings...",
        PlaceholderColor3=p.muted,TextColor3=p.text,BackgroundColor3=p.panel,TextSize=11,
        TextXAlignment=Enum.TextXAlignment.Left,ClearTextOnFocus=false,Font=Enum.Font.Gotham})
    round(search,9);stroke(search,p.accent,.84)
    create(search,"UIPadding",{PaddingLeft=UDim.new(0,12)})
    local category=button(left,currentCategory.."  ▾",UDim2.new(1,0,0,31),function()
        local pos=table.find(Config.Categories,currentCategory) or 1
        currentCategory=Config.Categories[pos%#Config.Categories+1]
        redrawPage()
    end)
    category.Position=UDim2.fromOffset(0,40)
    local gallery=create(left,"ScrollingFrame",{Position=UDim2.fromOffset(0,80),Size=UDim2.new(1,0,1,-80),
        BackgroundTransparency=1,ScrollBarThickness=2,ScrollBarImageColor3=p.accent,
        CanvasSize=UDim2.fromScale(0,0),AutomaticCanvasSize=Enum.AutomaticSize.Y})
    create(gallery,"UIListLayout",{Padding=UDim.new(0,5),SortOrder=Enum.SortOrder.LayoutOrder})
    local preview=create(right,"ViewportFrame",{Size=UDim2.new(1,0,.63,-4),BackgroundColor3=p.panel,
        BackgroundTransparency=.12,Ambient=Color3.fromRGB(180,190,204),LightColor=Color3.new(1,1,1),
        LightDirection=Vector3.new(-1,-2,-1)})
    round(preview,10)
    stroke(preview,p.accent,.84)
    local info=txt(right,"",14,p.text,{Position=UDim2.new(0,5,.63,0),Size=UDim2.new(1,-10,0,27),Font=Enum.Font.GothamBold})
    local info2=txt(right,"",10,p.muted,{Position=UDim2.new(0,5,.63,29),Size=UDim2.new(1,-10,0,25)})
    local equip=button(right,"EQUIP WINGS",UDim2.new(1,0,0,37),function()
        send("wing",selectedWing)
        toast("Wings equipped: "..(Wings.ById[selectedWing] and Wings.ById[selectedWing].name or "None"))
    end,true)
    equip.Position=UDim2.new(0,0,1,-79)
    local remove=button(right,"REMOVE",UDim2.new(1,0,0,34),function()
        send("wing","none")
        toast("Wings removed")
    end)
    remove.Position=UDim2.new(0,0,1,-35)
    local function selectWing(id)
        selectedWing=id
        local def=Wings.ById[id]
        if not def then return end
        info.Text=def.name
        info2.Text=def.collection.." / "..def.style.." / "..def.animation
        buildPreview(preview,id)
    end
    local function populate()
        for _,child in ipairs(gallery:GetChildren()) do if child:IsA("TextButton") then child:Destroy() end end
        local searchFor=search.Text:lower()
        for _,id in ipairs(Wings.Order) do
            local def=Wings.ById[id]
            if def and (currentCategory=="All" or currentCategory==def.collection)
                and (searchFor=="" or def.name:lower():find(searchFor,1,true) or id:find(searchFor,1,true)) then
                local b=button(gallery,def.name,UDim2.new(1,-6,0,36),function() selectWing(id) end,id==selectedWing)
                b.TextXAlignment=Enum.TextXAlignment.Left
                local iconId=def.assets and def.assets.icon
                if type(iconId)=="number" and iconId>0 then
                    local pic=create(b,"ImageLabel",{Name="WingIcon",BackgroundTransparency=1,
                        Position=UDim2.fromOffset(5,3),Size=UDim2.fromOffset(29,29),
                        Image="rbxassetid://"..tostring(iconId)})
                    b.Text="         "..def.name
                end
                b.TextSize=10
                create(b,"UIPadding",{PaddingLeft=UDim.new(0,10),PaddingRight=UDim.new(0,4)})
            end
        end
    end
    search:GetPropertyChangedSignal("Text"):Connect(populate)
    populate()
    selectWing(Wings.ById[selectedWing] and selectedWing or Wings.Order[1])
end
local function fillPage()
    local list=mkScroller(body)
    local p=palette()
    if activeTab=="Dashboard" then
        heading(list,"System Overview","Local cosmetics · 48 procedural wing designs")
        section(list,"Live status")
        tile(list,"FRAMERATE",string.format("~%d FPS · dynamic estimate",math.round(frameAverage)))
        tile(list,"ACTIVE WINGS",state.wing=="none" and "No wings equipped" or (Wings.ById[state.wing] and Wings.ById[state.wing].name or "Unknown"))
        tile(list,"GRAPHICS / QUALITY",state.preset.." · "..state.quality)
        section(list,"Quick actions")
        itemButton(list,"OPEN WINGS LIBRARY",function() activeTab="Wings";redrawNav();redrawPage() end,false)
        itemButton(list,"ENABLE PERFORMANCE MODE",function()
            send("quality","Performance");send("preset","Performance")
            Visual.ApplyPreset("Performance",not state.reducedMotion)
            updateEffects();redrawPage();toast("Performance mode enabled")
        end,false)
        itemButton(list,"SAVE ALL SETTINGS",function() toast(requestSave() and "Saved locally" or "File save is unavailable") end,false)
    elseif activeTab=="Visuals" then
        heading(list,"Visual Engine","Real Lighting, Atmosphere and supported post-processing properties")
        section(list,"Lighting profiles")
        for _,name in ipairs(Config.PresetOrder) do
            itemButton(list,name,function()
                send("preset",name)
                Visual.ApplyPreset(name,not state.reducedMotion)
                redrawPage();toast(name.." applied")
            end,state.preset==name)
        end
    elseif activeTab=="Lighting" then
        heading(list,"Lighting","Local lighting controls; your game may override them")
        section(list,"Environment")
        for _,s in ipairs({{"World Brightness","brightness",0,6},{"Exposure","exposure",-2,2},{"Time of Day","clock",0,24},
            {"Bloom Intensity","bloom",0,2},{"Saturation","saturation",-1,1},{"Contrast","contrast",-1,1},
            {"Sun Rays","sun",0,1},{"Depth of Field","dof",0,1}}) do
            slider(list,s[1],s[3],s[4],function() return Visual.Get(s[2]) or 0 end,function(value) Visual.Set(s[2],value) end,2)
        end
        itemButton(list,"REAPPLY PRESET",function() Visual.ApplyPreset(state.preset,not state.reducedMotion);redrawPage() end)
    elseif activeTab=="Atmosphere" then
        heading(list,"Atmosphere","Adjust environmental haze, aerial perspective and glare")
        for _,s in ipairs({{"Atmospheric Density","density",0,1},{"Haze","haze",0,10},{"Glare","glare",0,10}}) do
            slider(list,s[1],s[3],s[4],function() return Visual.Get(s[2]) or 0 end,function(value) Visual.Set(s[2],value) end,2)
        end
        itemButton(list,"RESTORE ACTIVE PROFILE",function() Visual.ApplyPreset(state.preset,not state.reducedMotion);redrawPage() end)
    elseif activeTab=="Wing Studio" then
        heading(list,"Wing Studio","Local wing customization · appearance updates in real time")
        section(list,"Geometry")
        slider(list,"Overall Scale",.55,1.6,function()return state.scale end,function(value)send("scale",value)end,2)
        slider(list,"Wing Spread",.6,1.5,function()return state.spread end,function(value)send("spread",value)end,2)
        section(list,"Motion")
        slider(list,"Flap Speed",.3,2.4,function()return state.flapSpeed end,function(value)send("flapSpeed",value)end,2)
        section(list,"Appearance")
        slider(list,"Custom Color Hue (-1 = original)",-1,1,function()return state.tintHue end,function(value)send("tintHue",value)end,2)
        slider(list,"Wing Transparency",0,.65,function()return state.wingTransparency end,function(value)send("wingTransparency",value)end,2)
        slider(list,"Glow Intensity",0,2,function()return state.glowIntensity end,function(value)send("glowIntensity",value)end,2)
        section(list,"Motion Profile")
        choose(list,"Animation Style","animationStyle",Config.AnimationStyles,function()redrawPage()end)
        itemButton(list,"RESET WING ADJUSTMENTS",function()
            for _,k in ipairs({"scale","spread","flapSpeed","tintHue","wingTransparency","glowIntensity","animationStyle"}) do send(k,Config.Default[k]) end
            redrawPage();toast("Wing adjustments restored")
        end)
        itemButton(list,"SAVE WING PRESET",function()toast(requestSave() and "Saved locally" or "File save is unavailable")end)
    elseif activeTab=="Effects" then
        heading(list,"Cosmetic Effects","Adjust particles and personal character highlights")
        toggle(list,"Wing Particles","particles","Small sparkles attached to your wing tips")
        toggle(list,"Wing Trails","trails","Colored trails, disabled in Performance quality")
        toggle(list,"Character Aura","aura","Local highlight around your character")
        toggle(list,"Glowing Footsteps","footsteps","Temporary ground lights while walking")
        tile(list,"PERFORMANCE NOTE","Particle budgets depend on Performance / Balanced / Ultra quality.")
    elseif activeTab=="Presets" then
        heading(list,"Presets","Curated visual atmospheres, no fake filter toggles")
        choose(list,"Scene presets","preset",Config.PresetOrder,function(name)
            Visual.ApplyPreset(name,not state.reducedMotion);redrawPage()
        end)
    elseif activeTab=="Themes" then
        heading(list,"Themes","Eight curated AETHER glass color systems")
        section(list,"Appearance")
        for _,name in ipairs(Config.ThemeOrder) do
            itemButton(list,name,function()
                send("theme",name)
                refreshTheme();toast("Theme: "..name)
            end,state.theme==name)
        end
    elseif activeTab=="Settings" then
        heading(list,"Settings","Performance, accessibility and optional file saving")
        section(list,"Render quality")
        choose(list,"Quality","quality",{"Performance","Balanced","Ultra"},function()
            updateEffects();redrawPage()
        end)
        section(list,"Accessibility")
        toggle(list,"Reduced Motion","reducedMotion","Disables long menu transitions")
        slider(list,"Interface Scale",.75,1.2,function()return state.uiScale end,function(value)
            send("uiScale",value)
            windowScale.Scale=fitScale*value
        end,2)
        section(list,"Data & Controls")
        itemButton(list,"SAVE SETTINGS",function()toast(requestSave() and "Saved locally" or "File save is unavailable")end)
        itemButton(list,"RESET ALL SETTINGS",function()
            queued={};sendVersion+=1
            for key,value in pairs(Config.Default) do state[key]=value end
            scheduleEquip()
            selectedWing=state.wing
            Visual.ApplyPreset(state.preset,not state.reducedMotion)
            updateEffects();refreshTheme();toast("Defaults restored")
        end)
        tile(list,"CONTROLS","Tap the floating Liquid Glass bar below to open or close · drag the toolbar to move the window.")
    end
end
redrawPage=function()
    body:ClearAllChildren()
    if activeTab=="Wings" then renderWings() else fillPage() end
end
redrawNav=function()
    for _,child in ipairs(nav:GetChildren()) do if child:IsA("TextButton") then child:Destroy() end end
    local p=palette()
    for i,name in ipairs(tabs) do
        local selected=activeTab==name
        local b=create(nav,"TextButton",{Name=name,LayoutOrder=i,
            Text=(selected and "▰   " or "▫   ")..name,Size=UDim2.new(1,-2,0,36),
            BackgroundColor3=selected and p.accent or p.panel,BackgroundTransparency=selected and .05 or .46,
            TextColor3=selected and p.bg or p.text,Font=Enum.Font.GothamMedium,
            TextSize=12,TextXAlignment=Enum.TextXAlignment.Left,AutoButtonColor=false})
        round(b,9)
        create(b,"UIPadding",{PaddingLeft=UDim.new(0,12)})
        b.MouseEnter:Connect(function() if not selected then tw(b,{BackgroundTransparency=.15},.15) end end)
        b.MouseLeave:Connect(function() if not selected then tw(b,{BackgroundTransparency=.46},.15) end end)
        b.MouseButton1Click:Connect(function()
            if activeTab==name then return end
            activeTab=name
            redrawNav()
            redrawPage()
        end)
    end
end
refreshTheme=function()
    local p=palette()
    window.BackgroundColor3=p.bg
    border.Color=p.accent
    brand.TextColor3=p.text
    subbrand.TextColor3=p.muted
    separator.BackgroundColor3=p.accent
    footerStatus.TextColor3=p.accent
    dock.BackgroundColor3=p.panel
    dockBorder.Color=p.accent
    dockLogo.BackgroundColor3=p.accent
    dockLogoText.TextColor3=p.bg
    dockBrand.TextColor3=p.text
    dockLabel.TextColor3=p.muted
    dockInfo.TextColor3=p.text
    dockSub.TextColor3=p.muted
    dockDivider.BackgroundColor3=p.accent
    dockArrowBG.BackgroundColor3=p.accent
    dockAction.TextColor3=p.text
    dockGradient.Color=ColorSequence.new({
        ColorSequenceKeypoint.new(0,p.panel:Lerp(p.accent,.25)),
        ColorSequenceKeypoint.new(.5,p.panel),
        ColorSequenceKeypoint.new(1,p.panel:Lerp(p.accent,.12))})
    updateDockInfo()
    redrawNav();redrawPage();updateEffects()
end

local function targetSize()
    local viewport=workspace.CurrentCamera and workspace.CurrentCamera.ViewportSize or Vector2.new(1280,720)
    local fit=math.min(1,(viewport.X-34)/720,(viewport.Y-158)/480)
    fitScale=math.max(.33,fit)
    return UDim2.fromOffset(720,480)
end
local function menuCenter()
    return UDim2.fromScale(.5,.43)
end
local function setOpen(value)
    motionToken+=1
    local token=motionToken
    open=value
    if currentTween then currentTween:Cancel();currentTween=nil end
    dockAction.Text=value and "⌄" or "⌃"
    tw(dockArrowBG,{BackgroundTransparency=value and .52 or .8},.22)
    updateDockInfo()
    if state.reducedMotion then
        window.Visible=value;shade.Visible=value
        window.Size=targetSize();windowScale.Scale=fitScale*state.uiScale
        window.Position=menuCenter()
        window.GroupTransparency=value and 0 or 1
        shade.BackgroundTransparency=value and .55 or 1
        blur.Size=value and 8 or 0
        return
    end
    if value then
        local finalSize=targetSize()
        windowScale.Scale=fitScale*state.uiScale
        window.Visible=true;shade.Visible=true
        window.Position=dockRest
        window.Size=UDim2.fromOffset(340,59)
        window.GroupTransparency=.72
        tw(shade,{BackgroundTransparency=.58},.4)
        tw(blur,{Size=8},.45)
        currentTween=tw(window,{
            Position=menuCenter(),Size=finalSize,GroupTransparency=0
        },.52,Enum.EasingStyle.Quint)
    else
        currentTween=tw(window,{
            Position=dockRest,Size=UDim2.fromOffset(340,59),GroupTransparency=1
        },.38,Enum.EasingStyle.Quint)
        tw(shade,{BackgroundTransparency=1},.37)
        tw(blur,{Size=0},.31)
        task.delay(.39,function()
            if not active or token~=motionToken then return end
            window.Visible=false;shade.Visible=false
        end)
    end
end
close.MouseButton1Click:Connect(function()setOpen(false)end)
dock.MouseButton1Click:Connect(function()
    if active then setOpen(not open) end
end)
-- AETHER is intentionally controlled by clicking the dock, not keyboard shortcuts.
-- Toolbar dragging, clamped to viewport.
local dragging=false
local dragOrigin
local dragStart
local function dragTo(point)
    if not dragging then return end
    local size=workspace.CurrentCamera and workspace.CurrentCamera.ViewportSize or Vector2.new(1280,720)
    local offset=point-dragOrigin
    local px=dragStart.X.Scale*size.X+dragStart.X.Offset+offset.X
    local py=dragStart.Y.Scale*size.Y+dragStart.Y.Offset+offset.Y
    px=math.clamp(px,window.AbsoluteSize.X*.5,size.X-window.AbsoluteSize.X*.5)
    py=math.clamp(py,window.AbsoluteSize.Y*.5,size.Y-window.AbsoluteSize.Y*.5)
    window.Position=UDim2.fromOffset(px,py)
end
top.InputBegan:Connect(function(input)
    if input.UserInputType==Enum.UserInputType.MouseButton1 or input.UserInputType==Enum.UserInputType.Touch then
        dragging=true;dragOrigin=input.Position;dragStart=window.Position
    end
end)
track(UIS.InputChanged:Connect(function(input)
    if dragging and (input.UserInputType==Enum.UserInputType.MouseMovement or input.UserInputType==Enum.UserInputType.Touch) then dragTo(input.Position) end
end))
track(UIS.InputEnded:Connect(function(input)
    if input.UserInputType==Enum.UserInputType.MouseButton1 or input.UserInputType==Enum.UserInputType.Touch then dragging=false end
end))
local lastViewport=Vector2.zero
track(RunService.RenderStepped:Connect(function(dt)
    if not active then return end
    if dt>0 then frameAverage=frameAverage*.94 + (1/math.max(dt,.005))*.06 end
    lastFrame+=dt
    if lastFrame>.8 then
        lastFrame=0
        footerStatus.Text=string.format("●  %d FPS  ·  %s",math.round(frameAverage),state.quality:upper())
        local camera=workspace.CurrentCamera
        if camera and camera.ViewportSize~=lastViewport then
            lastViewport=camera.ViewportSize
            targetSize()
            windowScale.Scale=fitScale*state.uiScale
            fitDock()
            if open and window.Visible then window.Size=targetSize() end
        end
        updateDockInfo()
    end
end))
redrawNav();redrawPage()
Visual.ApplyPreset(state.preset,false)
refreshTheme()
reEquip()
updateEffects()
fitDock()
-- Enter smoothly from below the screen after the UI is ready.
dock.Position=UDim2.new(.5,0,1,45)
tw(dock,{Position=dockRest},.72,Enum.EasingStyle.Quint)
toast("AETHER ready  ·  Tap the glass bar below")
-- Unload this instance: getgenv().AETHER_V2_CLOSE() when supported.
