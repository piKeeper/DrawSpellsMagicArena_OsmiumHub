----------------------------------------------------------------
-- Debug toggle
----------------------------------------------------------------
local DEBUG = true
local function dprint(...)
    if DEBUG then
        print("[OsmiumHub]", ...)
    end
end

----------------------------------------------------------------
-- Fluent UI
----------------------------------------------------------------
local Fluent = loadstring(game:HttpGet(
    "https://github.com/ActualMasterOogway/Fluent-Renewed/releases/latest/download/Fluent.luau"
))()

local SaveManager = loadstring(game:HttpGet(
    "https://raw.githubusercontent.com/dawid-scripts/Fluent/master/Addons/SaveManager.lua"
))()

local InterfaceManager = loadstring(game:HttpGet(
    "https://raw.githubusercontent.com/dawid-scripts/Fluent/master/Addons/InterfaceManager.lua"
))()

----------------------------------------------------------------
-- Loop guards storage
----------------------------------------------------------------
local LoopGuards = {}

----------------------------------------------------------------
-- Window
----------------------------------------------------------------
local Window = Fluent:CreateWindow({
    Title = "Osmium Hub",
    SubTitle = "",
    Size = UDim2.fromOffset(600, 450),
    Acrylic = true,
    Theme = "Darker"
})

local Options = Fluent.Options

----------------------------------------------------------------
-- Tabs
----------------------------------------------------------------
local Tabs = {
    Main = Window:AddTab({ Title = "Control Room", Icon = "circle-power" }),
    Teleports = Window:AddTab({ Title = "Teleports", Icon = "map" }),
    Items = Window:AddTab({ Title = "Items", Icon = "box" }),
    Misc = Window:AddTab({ Title = "Misc", Icon = "settings" }),
}

----------------------------------------------------------------
-- Sections
----------------------------------------------------------------
local Sections = {}
local function GetOrCreateSection(Tab, SectionName)
    if not Sections[SectionName] then
        Sections[SectionName] = Tab:AddSection(SectionName)
    end
    return Sections[SectionName]
end

----------------------------------------------------------------
-- Generic Lever Toggle Creator
----------------------------------------------------------------
local function CreateLeverToggle(folderPath, toggleName, toggleTitle, expectedText, sectionName, textLabelPath, clickDetectorPath)
    LoopGuards[toggleName] = false
    local section = GetOrCreateSection(Tabs.Main, sectionName)

    local toggle = section:AddToggle(toggleName, {
        Title = toggleTitle,
        Default = false
    })

    toggle:OnChanged(function(value)
        dprint(toggleName .. " changed:", value)
        if not value or LoopGuards[toggleName] then return end

        LoopGuards[toggleName] = true
        dprint(toggleName .. " loop started")

        task.spawn(function()
            while Options[toggleName].Value do
                local current = workspace
                for _, part in ipairs(folderPath) do
                    current = current and current:FindFirstChild(part)
                end

                if not current then
                    dprint("Folder not found for toggle:", toggleName)
                else
                    for _, lever in ipairs(current:GetChildren()) do
                        local labelObj = lever
                        for _, step in ipairs(textLabelPath) do
                            labelObj = labelObj and labelObj:FindFirstChild(step)
                        end
                        local label = labelObj

                        local clickObj = lever
                        for _, step in ipairs(clickDetectorPath) do
                            clickObj = clickObj and clickObj:FindFirstChild(step)
                        end
                        local click = clickObj

                        if not label then
                            dprint("Missing TextLabel on lever:", lever.Name)
                        elseif not click then
                            dprint("Missing ClickDetector on lever:", lever.Name)
                        else
                            dprint("Lever", lever.Name, "state:", label.Text)
                            if label.Text ~= expectedText then
                                dprint("Clicking lever to set:", expectedText, "Lever:", lever.Name)
                                fireclickdetector(click)
                            end
                        end
                    end
                end
                task.wait(0.2)
            end
            LoopGuards[toggleName] = false
            dprint(toggleName .. " loop stopped")
        end)
    end)
end

----------------------------------------------------------------
-- Coolant Dropdown Creator (individual)
----------------------------------------------------------------
local CoolantValueMap = {
    ["OFF"] = "0",
    ["25%"] = "25",
    ["50%"] = "50",
    ["75%"] = "75",
    ["100%"] = "100"
}

local function CreateSingleCoolantDropdown(coolantFolder, dropdownName, dropdownTitle, sectionName)
    LoopGuards[dropdownName] = false
    local section = GetOrCreateSection(Tabs.Main, sectionName)

    local Dropdown = section:AddDropdown(dropdownName, {
        Title = dropdownTitle,
        Description = "Select laser output percentage",
        Values = {"OFF", "25%", "50%", "75%", "100%"},
        Multi = false,
        Default = 1
    })

    Dropdown:OnChanged(function(Value)
        dprint(dropdownName .. " changed:", Value)
        if LoopGuards[dropdownName] then return end
        LoopGuards[dropdownName] = true

        task.spawn(function()
            local screen = coolantFolder:FindFirstChild("Screen")
            local surfaceGui = screen and screen:FindFirstChild("SurfaceGui")
            local label = surfaceGui and surfaceGui:FindFirstChild("TextLabel")

            if not label then
                dprint("Missing TextLabel on coolant:", coolantFolder.Name)
            else
                local currentValue = label.Text
                dprint("Coolant", coolantFolder.Name, "state:", currentValue)

                if currentValue ~= Value then
                    local buttons = coolantFolder:FindFirstChild("Buttons")
                    if not buttons then
                        dprint("Missing Buttons folder on coolant:", coolantFolder.Name)
                    else
                        local partName = CoolantValueMap[Value]
                        local button = buttons:FindFirstChild(partName)
                        local click = button and button:FindFirstChildOfClass("ClickDetector")
                        if click then
                            dprint("Clicking coolant", coolantFolder.Name, "button:", partName)
                            fireclickdetector(click)
                        else
                            dprint("Missing ClickDetector for button:", partName, "on coolant:", coolantFolder.Name)
                        end
                    end
                end
            end

            LoopGuards[dropdownName] = false
        end)
    end)
end

----------------------------------------------------------------
-- Create all lever toggles
----------------------------------------------------------------
-- Anti Lasers
CreateLeverToggle(
    { "Facility", "Core", "Buildings", "ControlRoom", "Controls", "Actual", "Anti" },
    "AntiOpenToggle",
    "Anti Auto Open",
    "ENABLED",
    "Anti Lasers",
    { "Screen", "SurfaceGui", "TextLabel" },
    { "Handle", "Union", "ClickDetector" }
)

CreateLeverToggle(
    { "Facility", "Core", "Buildings", "ControlRoom", "Controls", "Actual", "Anti" },
    "AntiCloseToggle",
    "Anti Auto Close",
    "DISABLED",
    "Anti Lasers",
    { "Screen", "SurfaceGui", "TextLabel" },
    { "Handle", "Union", "ClickDetector" }
)

-- Heat Lasers
CreateLeverToggle(
    { "Facility", "Core", "Buildings", "ControlRoom", "Controls", "Actual", "Lights" },
    "HeatOnToggle",
    "Heat Auto ON",
    "ENABLED",
    "Heat Lasers",
    { "Screen", "SurfaceGui", "TextLabel" },
    { "Handle", "Union", "ClickDetector" }
)

CreateLeverToggle(
    { "Facility", "Core", "Buildings", "ControlRoom", "Controls", "Actual", "Lights" },
    "HeatOffToggle",
    "Heat Auto OFF",
    "DISABLED",
    "Heat Lasers",
    { "Screen", "SurfaceGui", "TextLabel" },
    { "Handle", "Union", "ClickDetector" }
)

-- Openings Lasers (OPEN / CLOSED)
CreateLeverToggle(
    { "Facility", "Core", "Buildings", "CR", "Openings" },
    "OpeningsOpenToggle",
    "Openings Auto Open",
    "OPEN",
    "Openings",
    { "Screen", "SurfaceGui", "TextLabel" },
    { "Handle", "Click", "ClickDetector" }
)

CreateLeverToggle(
    { "Facility", "Core", "Buildings", "CR", "Openings" },
    "OpeningsCloseToggle",
    "Openings Auto Close",
    "CLOSED",
    "Openings",
    { "Screen", "SurfaceGui", "TextLabel" },
    { "Handle", "Click", "ClickDetector" }
)

----------------------------------------------------------------
-- Coolant Lasers (Separate Dropdowns)
----------------------------------------------------------------
local coolantFolder = workspace:WaitForChild("Facility")
    :WaitForChild("Core")
    :WaitForChild("Buildings")
    :WaitForChild("CR")
    :WaitForChild("Coolant")

local coolant1 = coolantFolder:FindFirstChild("Coolant1")
local coolant2 = coolantFolder:FindFirstChild("Coolant2")

if coolant1 then
    CreateSingleCoolantDropdown(coolant1, "Coolant1Dropdown", "Coolant1 Output", "Coolant Lasers")
end

if coolant2 then
    CreateSingleCoolantDropdown(coolant2, "Coolant2Dropdown", "Coolant2 Output", "Coolant Lasers")
end

----------------------------------------------------------------
-- Teleports Tab (Three Dropdowns)
----------------------------------------------------------------
local TeleportLocations = {
    Core = {
        ["Control Room"] = Vector3.new(4, 178, 173),
        ["Coolant Pumps"] = Vector3.new(-117, 178, 471),
        ["Maintenance"] = Vector3.new(29, 178, 404),
        ["Emergency Generator"] = Vector3.new(-170, 146, 337),
        ["Generator Switch"] = Vector3.new(-165, 178, 314),
        ["Security Room"] = Vector3.new(-86, 178, 447)
    },
    Extras = {
        ["Lab"] = Vector3.new(-151, 178, 559),
        ["Safeguard Control"] = Vector3.new(-159, 173, 611),
        ["Alien Research"] = Vector3.new(-28, 178, 445),
        ["Launch Silo"] = Vector3.new(0, 178, 492),
        ["Servers"] = Vector3.new(-53, 178, 298)
    },
    Outside = {
        ["Exit"] = Vector3.new(73, 181, 360),
        ["Mines"] = Vector3.new(236, 186, 176),
        ["Bunker"] = Vector3.new(403, 260, 910),
        ["Helicopter"] = Vector3.new(353, 209, 382)
    }
}

for category, locations in pairs(TeleportLocations) do
    local locNames = {}
    for name, _ in pairs(locations) do
        table.insert(locNames, name)
    end

    local dropdown = Tabs.Teleports:AddDropdown(category.."Dropdown", {
        Title = category .. " Locations",
        Description = "Select a location to teleport",
        Values = locNames,
        Multi = false,
        Default = "None"
    })

    dropdown:OnChanged(function(value)
        local pos = locations[value]
        local player = game.Players.LocalPlayer
        local char = player.Character
        if char and char:FindFirstChild("HumanoidRootPart") and pos then
            char.HumanoidRootPart.CFrame = CFrame.new(pos)
            dprint("Teleported to", value)
        else
            dprint("Failed to teleport to", value)
        end
    end)
end

----------------------------------------------------------------
-- Items Tab (Ore Mining, anchor reset on rock switch)
----------------------------------------------------------------
local OrePath = {"Outside", "Cave", "Ores"} -- Workspace path

-- Generic Ore Mining Toggle (cycles through rocks)
local function CreateOreToggle(oreName, toggleName, toggleTitle)
    LoopGuards[toggleName] = false

    local toggle = Tabs.Items:AddToggle(toggleName, {
        Title = toggleTitle,
        Default = false
    })

    toggle:OnChanged(function(value)
        dprint(toggleName .. " changed:", value)
        local player = game.Players.LocalPlayer
        local char = player.Character
        local hrp = char and char:FindFirstChild("HumanoidRootPart")
        if not hrp then
            dprint("HumanoidRootPart not found for player")
            return
        end

        if value then
            if LoopGuards[toggleName] then return end
            LoopGuards[toggleName] = true

            task.spawn(function()
                dprint(toggleName .. " mining loop started")

                while Options[toggleName].Value do
                    local current = workspace
                    for _, part in ipairs(OrePath) do
                        current = current and current:FindFirstChild(part)
                    end

                    if not current then
                        dprint("Ores folder not found")
                        task.wait(1)
                    else
                        -- Get all rocks of the target type
                        local rocks = {}
                        for _, rock in ipairs(current:GetChildren()) do
                            if rock.Name == oreName then
                                table.insert(rocks, rock)
                            end
                        end

                        if #rocks == 0 then
                            dprint("No rocks found for:", oreName)
                            task.wait(1)
                        else
                            for _, rock in ipairs(rocks) do
                                if not Options[toggleName].Value then break end

                                task.wait(0.05)

                                hrp.CFrame = CFrame.new(rock.PrimaryPart.Position + Vector3.new(0, 3, 0))

                                while rock.Parent and Options[toggleName].Value do
                                    -- Fire the mining remote
                                    game.ReplicatedStorage.RemoteEvents.Tools.Mine:FireServer(rock)
                                    dprint("Mining rock:", rock.Name)
                                    task.wait(1)
                                end
                                dprint("Rock destroyed or removed, moving to next:", rock.Name)
                            end
                        end
                    end
                end

                LoopGuards[toggleName] = false
                dprint(toggleName .. " mining loop stopped")
            end)
        else
            LoopGuards[toggleName] = false
            dprint(toggleName .. " manually stopped")
        end
    end)
end

-- Create the toggles
CreateOreToggle("BlueRock", "MineBlueOreToggle", "Mine Blue Ore")
CreateOreToggle("RedRock", "MineRedOreToggle", "Mine Red Ore")

----------------------------------------------------------------
-- Save / Interface
----------------------------------------------------------------
SaveManager:SetLibrary(Fluent)
InterfaceManager:SetLibrary(Fluent)

InterfaceManager:BuildInterfaceSection(Tabs.Misc)
SaveManager:BuildConfigSection(Tabs.Misc)

Window:SelectTab(1)
SaveManager:LoadAutoloadConfig()

dprint("Script loaded successfully")