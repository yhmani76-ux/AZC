--[[
    ╔═══════════════════════════════════════════════════════╗
    ║                  ARABY HUB UI LIBRARY                 ║
    ║                   Splash Screen v1.0                  ║
    ║                                                       ║
    ║  Colors: Gray & White                                 ║
    ║  Animation: Multi-layer moving + glow + fade          ║
    ╚═══════════════════════════════════════════════════════╝
--]]

local ArabyHub = {}
ArabyHub.__index = ArabyHub

-- ═══════════════════════════════════════
--  Configuration
-- ═══════════════════════════════════════
local Config = {
    -- Colors
    PrimaryColor   = Color3.fromRGB(200, 200, 200),  -- Light gray
    SecondaryColor = Color3.fromRGB(80, 80, 80),     -- Dark gray
    AccentWhite    = Color3.fromRGB(255, 255, 255),   -- Pure white
    DarkBg         = Color3.fromRGB(25, 25, 25),      -- Near-black background
    MidGray        = Color3.fromRGB(120, 120, 120),   -- Mid-tone gray

    -- Animation timings (seconds)
    SplashDuration     = 4.5,
    TextSlideInTime    = 0.8,
    TextGlowTime       = 1.2,
    TextScaleTime      = 0.6,
    SubtitleFadeTime   = 0.8,
    ParticleCount      = 30,
    LineExpandTime     = 1.0,
    FadeOutTime        = 0.5,
}

-- ═══════════════════════════════════════
--  Utility: Create Tween
-- ═══════════════════════════════════════
local function makeTween(instance, properties, duration, style, direction)
    local tweenInfo = TweenInfo.new(
        duration,
        style or Enum.EasingStyle.Quart,
        direction or Enum.EasingDirection.Out
    )
    local tween = game:GetService("TweenService"):Create(instance, tweenInfo, properties)
    return tween
end

-- ═══════════════════════════════════════
--  Utility: Rounded Corner helper
-- ═══════════════════════════════════════
local function addCorner(parent, radius)
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, radius or 12)
    corner.Parent = parent
    return corner
end

-- ═══════════════════════════════════════
--  Floating Particles (background ambiance)
-- ═══════════════════════════════════════
local function createParticles(parent)
    local particles = {}

    for i = 1, Config.ParticleCount do
        local particle = Instance.new("Frame")
        particle.Name = "Particle_" .. i
        particle.Size = UDim2.new(0, math.random(2, 6), 0, math.random(2, 6))
        particle.BackgroundColor3 = Config.MidGray
        particle.BackgroundTransparency = math.random(40, 80) / 100
        particle.BorderSizePixel = 0
        addCorner(particle, 50)

        -- Random start position spread across screen
        particle.Position = UDim2.new(
            math.random() * 1,
            0,
            math.random() * 1,
            0
        )
        particle.Parent = parent
        table.insert(particles, particle)

        -- Continuous floating animation
        task.spawn(function()
            while particle and particle.Parent do
                local targetX = math.random() * 1
                local targetY = math.random() * 1
                local dur = math.random(30, 60) / 10

                local tw = makeTween(particle, {
                    Position = UDim2.new(targetX, 0, targetY, 0),
                    BackgroundTransparency = math.random(30, 90) / 100,
                }, dur, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut)
                tw:Play()
                tw.Completed:Wait()
            end
        end)
    end

    return particles
end

-- ═══════════════════════════════════════
--  Decorative moving lines
-- ═══════════════════════════════════════
local function createMovingLines(parent)
    local lines = {}
    local lineData = {
        { startY = 0.3,  height = 1,   dir = 1,  speed = 6 },
        { startY = 0.5,  height = 200, dir = -1, speed = 8 },
        { startY = 0.7,  height = 1,   dir = 1,  speed = 5 },
        { startY = 0.2,  height = 150, dir = -1, speed = 7 },
        { startY = 0.8,  height = 1,   dir = 1,  speed = 9 },
    }

    for i, data in ipairs(lineData) do
        local line = Instance.new("Frame")
        line.Name = "MovingLine_" .. i
        line.Size = UDim2.new(0, 0, 0, data.height)
        line.BackgroundColor3 = Config.MidGray
        line.BackgroundTransparency = 0.6
        line.BorderSizePixel = 0
        line.Position = UDim2.new(0, 0, data.startY, 0)
        addCorner(line, 1)
        line.Parent = parent
        table.insert(lines, { frame = line, data = data })

        -- Animate width expansion then slide
        task.spawn(function()
            -- Phase 1: Expand width
            local expandTween = makeTween(line, {
                Size = UDim2.new(0.35, 0, 0, data.height),
            }, Config.LineExpandTime, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)
            expandTween:Play()
            expandTween.Completed:Wait()

            -- Phase 2: Slide across screen continuously
            while line and line.Parent do
                local fromX = data.dir == 1 and 0 or 0.65
                local toX   = data.dir == 1 and 0.65 or 0

                local slideIn = makeTween(line, {
                    Position = UDim2.new(toX, 0, data.startY + (math.random() * 0.1 - 0.05), 0),
                    BackgroundTransparency = 0.5,
                }, data.speed, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut)
                slideIn:Play()
                slideIn.Completed:Wait()

                local slideBack = makeTween(line, {
                    Position = UDim2.new(fromX, 0, data.startY + (math.random() * 0.1 - 0.05), 0),
                    BackgroundTransparency = 0.7,
                }, data.speed, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut)
                slideBack:Play()
                slideBack.Completed:Wait()
            end
        end)
    end

    return lines
end

-- ═══════════════════════════════════════
--  Main Title "ARABY HUB" with animation
-- ═══════════════════════════════════════
local function createMainTitle(parent)
    -- Outer container for the whole title block
    local titleContainer = Instance.new("Frame")
    titleContainer.Name = "TitleContainer"
    titleContainer.Size = UDim2.new(1, 0, 0, 120)
    titleContainer.Position = UDim2.new(0.5, 0, 0.4, 0)
    titleContainer.AnchorPoint = Vector2.new(0.5, 0.5)
    titleContainer.BackgroundTransparency = 1
    titleContainer.Parent = parent

    -- Glow effect behind text (soft white/gray bloom)
    local glowFrame = Instance.new("ImageLabel")
    glowFrame.Name = "Glow"
    glowFrame.Size = UDim2.new(0, 600, 0, 120)
    glowFrame.Position = UDim2.new(0.5, 0, 0.5, 0)
    glowFrame.AnchorPoint = Vector2.new(0.5, 0.5)
    glowFrame.BackgroundTransparency = 1
    glowFrame.Image = "rbxassetid://7669168585" -- circle blur asset
    glowFrame.ImageColor3 = Config.PrimaryColor
    glowFrame.ImageTransparency = 1 -- start invisible
    glowFrame.ScaleType = Enum.ScaleType.Stretch
    glowFrame.Parent = titleContainer

    -- Main title text "ARABY"
    local textAraby = Instance.new("TextLabel")
    textAraby.Name = "TextAraby"
    textAraby.Size = UDim2.new(1, 0, 0, 70)
    textAraby.Position = UDim2.new(0.5, 0, 0.2, 0)
    textAraby.AnchorPoint = Vector2.new(0.5, 0)
    textAraby.BackgroundTransparency = 1
    textAraby.Text = "ARABY"
    textAraby.Font = Enum.Font.GothamBold
    textAraby.TextSize = 72
    textAraby.TextColor3 = Config.SecondaryColor
    textAraby.TextTransparency = 1
    textAraby.TextXAlignment = Enum.TextXAlignment.Center
    -- Start offset to the left for slide-in
    textAraby.Position = UDim2.new(-0.5, 0, 0.2, 0)
    textAraby.Parent = titleContainer

    -- "HUB" text (white, slightly different style)
    local textHub = Instance.new("TextLabel")
    textHub.Name = "TextHub"
    textHub.Size = UDim2.new(1, 0, 0, 55)
    textHub.Position = UDim2.new(1.5, 0, 0.62, 0) -- start offset to the right
    textHub.AnchorPoint = Vector2.new(0.5, 0)
    textHub.BackgroundTransparency = 1
    textHub.Text = "HUB"
    textHub.Font = Enum.Font.GothamBlack
    textHub.TextSize = 58
    textHub.TextColor3 = Config.AccentWhite
    textHub.TextTransparency = 1
    textHub.TextXAlignment = Enum.TextXAlignment.Center
    textHub.Parent = titleContainer

    -- Thin separator line between ARABY and HUB
    local separator = Instance.new("Frame")
    separator.Name = "Separator"
    separator.Size = UDim2.new(0, 0, 0, 2) -- starts at width 0
    separator.Position = UDim2.new(0.5, 0, 0.56, 0)
    separator.AnchorPoint = Vector2.new(0.5, 0.5)
    separator.BackgroundColor3 = Config.MidGray
    separator.BackgroundTransparency = 1
    separator.BorderSizePixel = 0
    addCorner(separator, 2)
    separator.Parent = titleContainer

    -- ═══════════════════════════════════
    --  ANIMATION SEQUENCE
    -- ═══════════════════════════════════
    task.spawn(function()
        -- Step 1: Slide "ARABY" in from the left + fade in
        local arabySlide = makeTween(textAraby, {
            Position = UDim2.new(0.5, 0, 0.2, 0),
            TextTransparency = 0,
        }, Config.TextSlideInTime, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
        arabySlide:Play()
        arabySlide.Completed:Wait()

        -- Brief pause
        task.wait(0.15)

        -- Step 2: Separator expands from center
        local sepExpand = makeTween(separator, {
            Size = UDim2.new(0, 200, 0, 2),
            BackgroundTransparency = 0.2,
        }, 0.5, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)
        sepExpand:Play()
        sepExpand.Completed:Wait()

        -- Step 3: Slide "HUB" in from the right + fade in
        local hubSlide = makeTween(textHub, {
            Position = UDim2.new(0.5, 0, 0.62, 0),
            TextTransparency = 0,
        }, Config.TextSlideInTime, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
        hubSlide:Play()
        hubSlide.Completed:Wait()

        -- Step 4: Scale pulse on both texts
        for _, txt in ipairs({ textAraby, textHub }) do
            local scaleUp = makeTween(txt, {
                TextScaled = false,
            }, 0.01) -- instant
            -- We'll do a size tween on the container instead
        end

        -- Scale bounce on container
        local scaleUp = makeTween(titleContainer, {
            Size = UDim2.new(1, 0, 0, 135),
        }, Config.TextScaleTime * 0.6, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
        scaleUp:Play()
        scaleUp.Completed:Wait()

        local scaleDown = makeTween(titleContainer, {
            Size = UDim2.new(1, 0, 0, 120),
        }, Config.TextScaleTime * 0.4, Enum.EasingStyle.Quart, Enum.EasingDirection.In)
        scaleDown:Play()
        scaleDown.Completed:Wait()

        -- Step 5: Glow effect pulses in
        local glowIn = makeTween(glowFrame, {
            ImageTransparency = 0.5,
        }, Config.TextGlowTime * 0.5, Enum.EasingStyle.Sine, Enum.EasingDirection.Out)
        glowIn:Play()
        glowIn.Completed:Wait()

        -- Glow pulse (breathe effect)
        task.spawn(function()
            while glowFrame and glowFrame.Parent do
                local pulse = makeTween(glowFrame, {
                    ImageTransparency = 0.7,
                }, 1.5, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut)
                pulse:Play()
                pulse.Completed:Wait()

                local pulse2 = makeTween(glowFrame, {
                    ImageTransparency = 0.4,
                }, 1.5, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut)
                pulse2:Play()
                pulse2.Completed:Wait()
            end
        end)

        -- Step 6: Color shift on "ARABY" text (gray -> lighter gray -> back)
        task.wait(0.5)
        local colorShift = makeTween(textAraby, {
            TextColor3 = Config.PrimaryColor,
        }, 1.0, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut)
        colorShift:Play()
        colorShift.Completed:Wait()

        local colorBack = makeTween(textAraby, {
            TextColor3 = Config.SecondaryColor,
        }, 1.0, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut)
        colorBack:Play()
    end)

    return titleContainer
end

-- ═══════════════════════════════════════
--  Subtitle / Tagline
-- ═══════════════════════════════════════
local function createSubtitle(parent)
    local subtitle = Instance.new("TextLabel")
    subtitle.Name = "Subtitle"
    subtitle.Size = UDim2.new(0, 400, 0, 30)
    subtitle.Position = UDim2.new(0.5, 0, 0.62, 0)
    subtitle.AnchorPoint = Vector2.new(0.5, 0)
    subtitle.BackgroundTransparency = 1
    subtitle.Text = "Premium Roblox Experience"
    subtitle.Font = Enum.Font.GothamMedium
    subtitle.TextSize = 18
    subtitle.TextColor3 = Config.MidGray
    subtitle.TextTransparency = 1
    subtitle.TextXAlignment = Enum.TextXAlignment.Center
    subtitle.Parent = parent

    -- Delayed fade in
    task.delay(Config.TextSlideInTime * 2 + 0.5, function()
        local fade = makeTween(subtitle, {
            TextTransparency = 0.1,
        }, Config.SubtitleFadeTime, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)
        fade:Play()
    end)

    -- Gentle floating animation after appearing
    task.delay(Config.TextSlideInTime * 2 + 1.3, function()
        task.spawn(function()
            while subtitle and subtitle.Parent do
                local floatUp = makeTween(subtitle, {
                    Position = UDim2.new(0.5, 0, 0.615, 0),
                }, 2.0, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut)
                floatUp:Play()
                floatUp.Completed:Wait()

                local floatDown = makeTween(subtitle, {
                    Position = UDim2.new(0.5, 0, 0.625, 0),
                }, 2.0, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut)
                floatDown:Play()
                floatDown.Completed:Wait()
            end
        end)
    end)

    return subtitle
end

-- ═══════════════════════════════════════
--  Version label (bottom corner)
-- ═══════════════════════════════════════
local function createVersionLabel(parent)
    local version = Instance.new("TextLabel")
    version.Name = "Version"
    version.Size = UDim2.new(0, 100, 0, 20)
    version.Position = UDim2.new(1, -15, 1, -25)
    version.AnchorPoint = Vector2.new(1, 1)
    version.BackgroundTransparency = 1
    version.Text = "v1.0.0"
    version.Font = Enum.Font.Gotham
    version.TextSize = 12
    version.TextColor3 = Config.MidGray
    version.TextTransparency = 0.6
    version.TextXAlignment = Enum.TextXAlignment.Right
    version.Parent = parent
    return version
end

-- ═══════════════════════════════════════
--  Border frame (subtle animated border)
-- ═══════════════════════════════════════
local function createBorderFrame(parent)
    local border = Instance.new("Frame")
    border.Name = "AnimatedBorder"
    border.Size = UDim2.new(0, 520, 0, 280)
    border.Position = UDim2.new(0.5, 0, 0.5, 0)
    border.AnchorPoint = Vector2.new(0.5, 0.5)
    border.BackgroundColor3 = Config.DarkBg
    border.BackgroundTransparency = 0.15
    border.BorderSizePixel = 0
    addCorner(border, 16)
    border.Parent = parent

    -- Border outline using a slightly larger frame behind
    local outline = Instance.new("Frame")
    outline.Name = "Outline"
    outline.Size = UDim2.new(1, 4, 1, 4)
    outline.Position = UDim2.new(0.5, 0, 0.5, 0)
    outline.AnchorPoint = Vector2.new(0.5, 0.5)
    outline.BackgroundColor3 = Config.MidGray
    outline.BackgroundTransparency = 1
    outline.BorderSizePixel = 0
    addCorner(outline, 18)
    outline.Parent = parent

    -- Fade in the outline
    task.delay(0.3, function()
        local fadeIn = makeTween(outline, {
            BackgroundTransparency = 0.75,
        }, 1.0, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)
        fadeIn:Play()
    end)

    -- Gentle scale breathing
    task.delay(1.5, function()
        task.spawn(function()
            while border and border.Parent do
                local breathe = makeTween(border, {
                    Size = UDim2.new(0, 530, 0, 290),
                }, 2.5, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut)
                breathe:Play()
                breathe.Completed:Wait()

                local shrink = makeTween(border, {
                    Size = UDim2.new(0, 520, 0, 280),
                }, 2.5, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut)
                shrink:Play()
                shrink.Completed:Wait()
            end
        end)

        -- Same for outline
        task.spawn(function()
            while outline and outline.Parent do
                local breathe = makeTween(outline, {
                    Size = UDim2.new(1, 8, 1, 8),
                }, 2.5, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut)
                breathe:Play()
                breathe.Completed:Wait()

                local shrink = makeTween(outline, {
                    Size = UDim2.new(1, 4, 1, 4),
                }, 2.5, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut)
                shrink:Play()
                shrink.Completed:Wait()
            end
        end)
    end)

    return border, outline
end

-- ═══════════════════════════════════════
--  Background overlay (darkens screen)
-- ═══════════════════════════════════════
local function createBackground(parent)
    local bg = Instance.new("Frame")
    bg.Name = "SplashBackground"
    bg.Size = UDim2.new(1, 0, 1, 0)
    bg.BackgroundColor3 = Config.DarkBg
    bg.BackgroundTransparency = 1
    bg.BorderSizePixel = 0
    bg.ZIndex = 0
    bg.Parent = parent

    -- Fade in background
    local fadeIn = makeTween(bg, {
        BackgroundTransparency = 0.05,
    }, 0.5, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)
    fadeIn:Play()

    return bg
end

-- ═══════════════════════════════════════
--  MAIN: Show Splash Screen
-- ═══════════════════════════════════════
function ArabyHub:ShowSplash(onComplete)
    local player = game:GetService("Players").LocalPlayer
    local playerGui = player:WaitForChild("PlayerGui")

    -- Create ScreenGui
    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "ArabyHub_Splash"
    screenGui.ResetOnSpawn = false
    screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    screenGui.IgnoreGuiInset = true
    screenGui.DisplayOrder = 9999
    screenGui.Parent = playerGui

    -- Build layers (order matters for z-indexing)
    local bg = createBackground(screenGui)
    local particles = createParticles(screenGui)
    local lines = createMovingLines(screenGui)
    local borderFrame, outlineFrame = createBorderFrame(screenGui)
    local title = createMainTitle(screenGui)
    local subtitle = createSubtitle(screenGui)
    local version = createVersionLabel(screenGui)

    -- Auto-dismiss after splash duration
    task.delay(Config.SplashDuration, function()
        -- Fade everything out
        local allFrames = screenGui:GetDescendants()
        local fadeOut = makeTween(bg, {
            BackgroundTransparency = 1,
        }, Config.FadeOutTime, Enum.EasingStyle.Quart, Enum.EasingDirection.In)
        fadeOut:Play()

        for _, descendant in ipairs(allFrames) do
            if descendant:IsA("TextLabel") then
                makeTween(descendant, {
                    TextTransparency = 1,
                }, Config.FadeOutTime, Enum.EasingStyle.Quart, Enum.EasingDirection.In):Play()
            elseif descendant:IsA("Frame") and descendant.BackgroundTransparency < 1 then
                makeTween(descendant, {
                    BackgroundTransparency = 1,
                }, Config.FadeOutTime, Enum.EasingStyle.Quart, Enum.EasingDirection.In):Play()
            elseif descendant:IsA("ImageLabel") then
                makeTween(descendant, {
                    ImageTransparency = 1,
                }, Config.FadeOutTime, Enum.EasingStyle.Quart, Enum.EasingDirection.In):Play()
            end
        end

        -- Destroy after fade completes
        task.delay(Config.FadeOutTime + 0.1, function()
            if screenGui and screenGui.Parent then
                screenGui:Destroy()
            end
            -- Fire completion callback
            if onComplete then
                onComplete()
            end
        end)
    end)

    return screenGui
end

-- ═══════════════════════════════════════
--  Quick-run (executes splash immediately)
-- ═══════════════════════════════════════
function ArabyHub:Init()
    self:ShowSplash(function()
        print("[ArabyHub] Splash screen completed. Ready for main UI.")
        -- Future: self:ShowMainUI() goes here
    end)
end

return ArabyHub