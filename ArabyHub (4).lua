--[[
    ╔═══════════════════════════════════════════════════════════╗
    ║               ARABY HUB  —  FULL UI v3.0                  ║
    ║                                                           ║
    ║  Splash  |  Circle Toggle Button  |  Main Window           ║
    ║  Draggable  |  Mobile-ready  |  Custom BG support          ║
    ╚═══════════════════════════════════════════════════════════╝

    Usage:
        local Hub = loadstring(game:HttpGet("YOUR_LINK"))()
        Hub:Init({
            buttonImage = "rbxassetid://YOUR_ASSET_ID",   -- or "https://..."
            windowBg    = "rbxassetid://BG_ASSET_ID",     -- or "https://..." or nil
        })
--]]

local ArabyHub = {}
ArabyHub.__index = ArabyHub

-- ═══════════════════════════════════════
--  Services
-- ═══════════════════════════════════════
local TweenService   = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local RunService     = game:GetService("RunService")

-- ═══════════════════════════════════════
--  Color Palette
-- ═══════════════════════════════════════
local C = {
    White       = Color3.fromRGB(255, 255, 255),
    LightGray   = Color3.fromRGB(180, 180, 180),
    MidGray     = Color3.fromRGB(100, 100, 100),
    DarkGray    = Color3.fromRGB(55, 55, 55),
    PanelGray   = Color3.fromRGB(30, 30, 30),
    VeryDark    = Color3.fromRGB(18, 18, 18),
    Accent      = Color3.fromRGB(160, 160, 160),
}

-- ═══════════════════════════════════════
--  Tween Helper
-- ═══════════════════════════════════════
local function tw(obj, props, dur, style, dir, delayTime)
    local info = TweenInfo.new(
        dur or 0.5,
        style or Enum.EasingStyle.Quart,
        dir or Enum.EasingDirection.Out,
        delayTime or 0
    )
    return TweenService:Create(obj, info, props)
end

-- ═══════════════════════════════════════
--  UICorner Helper
-- ═══════════════════════════════════════
local function corner(parent, radius)
    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, radius or 12)
    c.Parent = parent
    return c
end

-- ═══════════════════════════════════════
--  Universal Drag Module
--  Uses UserInputService directly so it works
--  even on invisible/transparent frames + ImageButton
--  Returns: { isDragging function }
-- ═══════════════════════════════════════
local function makeDraggable(frame, dragHandle)
    dragHandle = dragHandle or frame
    local dragThreshold = 6  -- pixels before it counts as drag not click

    local dragging = false
    local dragStartPos = Vector3.zero
    local frameStartPos = UDim2.new()
    local inputObj = nil
    local didDrag = false  -- true if user actually moved enough to be a drag

    local function startDrag(input)
        if dragging then return end
        inputObj = input
        dragging = true
        didDrag = false
        dragStartPos = input.Position
        frameStartPos = frame.Position
    end

    local function updateDrag(input)
        if not dragging or input ~= inputObj then return end
        local delta = input.Position - dragStartPos

        -- Check if past threshold
        if not didDrag and (math.abs(delta.X) > dragThreshold or math.abs(delta.Y) > dragThreshold) then
            didDrag = true
        end

        if didDrag then
            frame.Position = UDim2.new(
                frameStartPos.X.Scale,
                frameStartPos.X.Offset + delta.X,
                frameStartPos.Y.Scale,
                frameStartPos.Y.Offset + delta.Y
            )
        end
    end

    local function endDrag(input)
        if not dragging then return end
        if input ~= inputObj then return end
        dragging = false
        inputObj = nil
    end

    -- Connect to the GUI object directly
    dragHandle.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch then
            startDrag(input)
        end
    end)

    dragHandle.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement
        or input.UserInputType == Enum.UserInputType.Touch then
            updateDrag(input)
        end
    end)

    dragHandle.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch then
            endDrag(input)
        end
    end)

    -- Fallback: global input ended (safety net)
    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch then
            dragging = false
            inputObj = nil
        end
    end)

    return {
        isDragging = function() return didDrag end,
    }
end

-- ═══════════════════════════════════════
--  Viewport Helper (mobile responsive)
-- ═══════════════════════════════════════
local function getViewSize()
    local vp = workspace.CurrentCamera.ViewportSize
    return vp.X, vp.Y
end

local function isMobile()
    local w, h = getViewSize()
    return w < 700 or UserInputService.TouchEnabled
end


-- ╔══════════════════════════════════════════════════════════════╗
-- ║                      SPLASH SCREEN                           ║
-- ╚══════════════════════════════════════════════════════════════╝

local SplashConfig = {
    TitleText       = "ARABY HUB",
    TitleFont       = Enum.Font.GothamBlack,
    TitleSize       = 82,
    LetterSpacing   = 12,
    WaveSpeed       = 0.35,
    ColorCycleTime  = 1.8,
    FloatAmplitude  = 6,
    FloatSpeed      = 2.5,
    EntranceDelay   = 0.06,
    EntranceTime    = 0.5,
    SplashDuration  = 5.0,
    FadeOutTime     = 0.6,
}

local function lerpColor(a, b, t)
    return Color3.new(a.R + (b.R - a.R) * t, a.G + (b.G - a.G) * t, a.B + (b.B - a.B) * t)
end

local function pingPong(t, period)
    local phase = (t % period) / period
    return phase < 0.5 and phase * 2 or 2 - phase * 2
end

local function buildLetters(parent)
    local text = SplashConfig.TitleText
    local labels = {}
    local totalWidth = 0

    for i = 1, #text do
        local char = text:sub(i, i)
        if char == " " then
            local spacer = Instance.new("Frame")
            spacer.Name = "Space_" .. i
            spacer.Size = UDim2.new(0, SplashConfig.LetterSpacing * 2, 0, 1)
            spacer.BackgroundTransparency = 1
            spacer.Parent = parent
            table.insert(labels, { type = "space", instance = spacer })
            totalWidth = totalWidth + SplashConfig.LetterSpacing * 2
        else
            local lbl = Instance.new("TextLabel")
            lbl.Name = "Letter_" .. i
            lbl.BackgroundTransparency = 1
            lbl.Text = char
            lbl.Font = SplashConfig.TitleFont
            lbl.TextSize = SplashConfig.TitleSize
            lbl.TextColor3 = C.White
            lbl.TextTransparency = 1
            lbl.TextXAlignment = Enum.TextXAlignment.Center
            lbl.TextYAlignment = Enum.TextYAlignment.Center
            lbl.Size = UDim2.new(0, 60, 0, 90)
            lbl.Parent = parent
            local width = lbl.TextBounds.X
            totalWidth = totalWidth + width + SplashConfig.LetterSpacing
            table.insert(labels, { type = "letter", instance = lbl, char = char, width = width, index = i })
        end
    end

    local xOffset = -(totalWidth / 2)
    for _, item in ipairs(labels) do
        if item.type == "space" then
            item.instance.Position = UDim2.new(0.5, xOffset, 0.5, 0)
            item.instance.AnchorPoint = Vector2.new(0, 0.5)
            xOffset = xOffset + item.instance.Size.X.Offset
        else
            item.instance.Size = UDim2.new(0, item.width, 0, 90)
            item.instance.Position = UDim2.new(0.5, xOffset, 0.5, 0)
            item.instance.AnchorPoint = Vector2.new(0, 0.5)
            xOffset = xOffset + item.width + SplashConfig.LetterSpacing
        end
    end

    return labels, totalWidth
end

local function playEntrance(labels, callback)
    local letterIndex = 0
    for _, item in ipairs(labels) do
        if item.type == "letter" then
            letterIndex = letterIndex + 1
            local lbl = item.instance
            local idx = letterIndex
            lbl.Size = UDim2.new(0, item.width, 0, 0)
            lbl.Position = UDim2.new(lbl.Position.X.Scale, lbl.Position.X.Offset, 0.5, 40)

            task.delay((idx - 1) * SplashConfig.EntranceDelay, function()
                tw(lbl, { Size = UDim2.new(0, item.width, 0, 90) }, SplashConfig.EntranceTime, Enum.EasingStyle.Back, Enum.EasingDirection.Out):Play()
                tw(lbl, { Position = UDim2.new(lbl.Position.X.Scale, lbl.Position.X.Offset, 0.5, 0) }, SplashConfig.EntranceTime, Enum.EasingStyle.Back, Enum.EasingDirection.Out):Play()
                tw(lbl, { TextTransparency = 0 }, SplashConfig.EntranceTime * 0.7):Play()
            end)
        end
    end
    task.delay((letterIndex - 1) * SplashConfig.EntranceDelay + SplashConfig.EntranceTime + 0.1, function()
        if callback then callback() end
    end)
end

local function startColorWave(labels)
    local startTime = tick()
    return RunService.Heartbeat:Connect(function()
        local elapsed = tick() - startTime
        local letterIdx = 0
        for _, item in ipairs(labels) do
            if item.type == "letter" then
                letterIdx = letterIdx + 1
                local phase = (elapsed - letterIdx * SplashConfig.WaveSpeed) / SplashConfig.ColorCycleTime
                local t = pingPong(phase, 1)
                item.instance.TextColor3 = lerpColor(C.DarkGray, C.White, t)
                item.instance.TextTransparency = 0.05 + 0.15 * math.sin(phase * math.pi * 2)
            end
        end
    end)
end

local function startFloating(labels)
    local startTime = tick()
    return RunService.Heartbeat:Connect(function()
        local elapsed = tick() - startTime
        local letterIdx = 0
        for _, item in ipairs(labels) do
            if item.type == "letter" then
                letterIdx = letterIdx + 1
                local offset = math.sin((elapsed / SplashConfig.FloatSpeed) * math.pi * 2 + letterIdx * 0.4) * SplashConfig.FloatAmplitude
                item.instance.Position = UDim2.new(item.instance.Position.X.Scale, item.instance.Position.X.Offset, 0.5, offset)
            end
        end
    end)
end

local function animateGlow(glow)
    local startTime = tick()
    return RunService.Heartbeat:Connect(function()
        local t = tick() - startTime
        glow.ImageTransparency = 0.55 + 0.2 * math.sin(t * 1.2)
        local r = 100 + 60 * math.sin(t * 0.8)
        local g = 100 + 60 * math.sin(t * 0.8 + 0.5)
        local b = 100 + 60 * math.sin(t * 0.8 + 1.0)
        glow.ImageColor3 = Color3.new(r / 255, g / 255, b / 255)
    end)
end

function ArabyHub:ShowSplash(onComplete)
    local player = game:GetService("Players").LocalPlayer
    local playerGui = player:WaitForChild("PlayerGui")

    local gui = Instance.new("ScreenGui")
    gui.Name = "ArabyHub_Splash"
    gui.ResetOnSpawn = false
    gui.IgnoreGuiInset = true
    gui.DisplayOrder = 9999
    gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    gui.Parent = playerGui

    local bg = Instance.new("Frame")
    bg.Name = "Bg"
    bg.Size = UDim2.new(1, 0, 1, 0)
    bg.BackgroundColor3 = C.VeryDark
    bg.BackgroundTransparency = 1
    bg.BorderSizePixel = 0
    bg.Parent = gui
    tw(bg, { BackgroundTransparency = 0.02 }, 0.4):Play()

    local container = Instance.new("Frame")
    container.Name = "TitleContainer"
    container.Size = UDim2.new(1, 0, 0, 100)
    container.Position = UDim2.new(0.5, 0, 0.5, 0)
    container.AnchorPoint = Vector2.new(0.5, 0.5)
    container.BackgroundTransparency = 1
    container.Parent = gui

    local glow = Instance.new("ImageLabel")
    glow.Name = "TextGlow"
    glow.Size = UDim2.new(0, 700, 0, 140)
    glow.Position = UDim2.new(0.5, 0, 0.5, 0)
    glow.AnchorPoint = Vector2.new(0.5, 0.5)
    glow.BackgroundTransparency = 1
    glow.Image = "rbxassetid://7669168585"
    glow.ImageColor3 = C.MidGray
    glow.ImageTransparency = 1
    glow.ScaleType = Enum.ScaleType.Stretch
    glow.Parent = gui

    local labels = buildLetters(container)
    local connections = {}

    playEntrance(labels, function()
        table.insert(connections, startColorWave(labels))
        table.insert(connections, startFloating(labels))
        tw(glow, { ImageTransparency = 0.6 }, 0.8, Enum.EasingStyle.Sine, Enum.EasingDirection.Out):Play()
        table.insert(connections, animateGlow(glow))
    end)

    task.delay(SplashConfig.SplashDuration, function()
        for _, conn in ipairs(connections) do
            if conn and conn.Connected then conn:Disconnect() end
        end
        for _, item in ipairs(labels) do
            if item.type == "letter" then
                tw(item.instance, { TextColor3 = C.White, TextTransparency = 0, Position = UDim2.new(item.instance.Position.X.Scale, item.instance.Position.X.Offset, 0.5, 0) }, 0.2):Play()
            end
        end
        tw(glow, { ImageTransparency = 1 }, SplashConfig.FadeOutTime):Play()
        tw(bg, { BackgroundTransparency = 1 }, SplashConfig.FadeOutTime):Play()
        for _, item in ipairs(labels) do
            if item.type == "letter" then tw(item.instance, { TextTransparency = 1 }, SplashConfig.FadeOutTime):Play() end
        end
        task.delay(SplashConfig.FadeOutTime + 0.15, function()
            if gui and gui.Parent then gui:Destroy() end
            if onComplete then onComplete() end
        end)
    end)

    return gui
end


-- ╔══════════════════════════════════════════════════════════════╗
-- ║               CIRCLE TOGGLE BUTTON                          ║
-- ║                                                              ║
-- ║  - Circular ImageButton                                     ║
-- ║  - Custom image via asset ID or external URL                ║
-- ║  - Draggable (mouse + touch)                                ║
-- ║  - Rotating ring animation around it                        ║
-- ║  - Glow pulse                                               ║
-- ║  - Opens/closes the main window on click                    ║
-- ╚══════════════════════════════════════════════════════════════╝

function ArabyHub:CreateToggleButton(options)
    options = options or {}
    local imageId = options.buttonImage  -- "rbxassetid://..." or "https://..."
    local mobile = isMobile()
    local btnSize = mobile and 56 or 50

    -- ═══ Frame Hierarchy ═══
    -- ToggleRoot (draggable, invisible)
    --   ├── GlowRing (ImageLabel, rotating/pulsing)
    --   ├── OuterRing (Frame, border ring)
    --   └── Button (ImageButton, main clickable)

    local root = Instance.new("Frame")
    root.Name = "ToggleRoot"
    root.Size = UDim2.new(0, btnSize + 20, 0, btnSize + 20)
    root.Position = UDim2.new(0, 30, 0.5, 0)
    root.AnchorPoint = Vector2.new(0, 0.5)
    root.BackgroundTransparency = 1
    root.ZIndex = 100

    -- Glow ring (subtle pulse behind button)
    local glowRing = Instance.new("ImageLabel")
    glowRing.Name = "GlowRing"
    glowRing.Size = UDim2.new(0, btnSize + 40, 0, btnSize + 40)
    glowRing.Position = UDim2.new(0.5, 0, 0.5, 0)
    glowRing.AnchorPoint = Vector2.new(0.5, 0.5)
    glowRing.BackgroundTransparency = 1
    glowRing.Image = "rbxassetid://7669168585"
    glowRing.ImageColor3 = C.MidGray
    glowRing.ImageTransparency = 0.9
    glowRing.ScaleType = Enum.ScaleType.Stretch
    glowRing.ZIndex = 99
    glowRing.Parent = root

    -- Outer ring (thin border circle)
    local outerRing = Instance.new("Frame")
    outerRing.Name = "OuterRing"
    outerRing.Size = UDim2.new(0, btnSize + 10, 0, btnSize + 10)
    outerRing.Position = UDim2.new(0.5, 0, 0.5, 0)
    outerRing.AnchorPoint = Vector2.new(0.5, 0.5)
    outerRing.BackgroundColor3 = C.DarkGray
    outerRing.BackgroundTransparency = 0.3
    outerRing.BorderSizePixel = 0
    outerRing.ZIndex = 100
    corner(outerRing, 50)
    outerRing.Parent = root

    -- Spinning accent ring (partial circle effect via stroke)
    local spinRing = Instance.new("Frame")
    spinRing.Name = "SpinRing"
    spinRing.Size = UDim2.new(0, btnSize + 16, 0, btnSize + 16)
    spinRing.Position = UDim2.new(0.5, 0, 0.5, 0)
    spinRing.AnchorPoint = Vector2.new(0.5, 0.5)
    spinRing.BackgroundTransparency = 1
    spinRing.BorderSizePixel = 2
    spinRing.BorderColor3 = C.Accent
    spinRing.ZIndex = 101
    corner(spinRing, 50)
    spinRing.Parent = root

    -- Main button
    local btn = Instance.new("ImageButton")
    btn.Name = "CircleButton"
    btn.Size = UDim2.new(0, btnSize, 0, btnSize)
    btn.Position = UDim2.new(0.5, 0, 0.5, 0)
    btn.AnchorPoint = Vector2.new(0.5, 0.5)
    btn.BackgroundColor3 = C.PanelGray
    btn.BorderSizePixel = 0
    btn.AutoButtonColor = true
    btn.ZIndex = 102
    corner(btn, btnSize / 2)
    btn.Parent = root

    -- Button image (if provided)
    if imageId then
        local img = Instance.new("ImageLabel")
        img.Name = "ButtonImage"
        img.Size = UDim2.new(0.6, 0, 0.6, 0)
        img.Position = UDim2.new(0.5, 0, 0.5, 0)
        img.AnchorPoint = Vector2.new(0.5, 0.5)
        img.BackgroundTransparency = 1
        img.Image = imageId
        img.ImageColor3 = C.White
        img.ImageTransparency = 0
        img.ScaleType = Enum.ScaleType.Fit
        img.ZIndex = 103
        img.Parent = btn

        -- If external URL, set properly
        if imageId:find("^https?://") then
            img.Image = imageId
        end
    end

    -- ═══ Animations ═══

    -- Spin ring rotation (continuous)
    task.spawn(function()
        local startTime = tick()
        local conn
        conn = RunService.Heartbeat:Connect(function()
            if not root or not root.Parent then
                conn:Disconnect()
                return
            end
            local elapsed = tick() - startTime
            local angle = elapsed * 60 -- degrees per second
            spinRing.Rotation = angle

            -- Pulse glow
            local glowAlpha = 0.7 + 0.25 * math.sin(elapsed * 2)
            glowRing.ImageTransparency = glowAlpha
            local glowScale = 1 + 0.08 * math.sin(elapsed * 1.5)
            glowRing.Size = UDim2.new(0, (btnSize + 40) * glowScale, 0, (btnSize + 40) * glowScale)
        end)
    end)

    -- Hover effect
    btn.MouseEnter:Connect(function()
        tw(btn, { BackgroundColor3 = C.DarkGray }, 0.2):Play()
        tw(outerRing, { BackgroundTransparency = 0.1 }, 0.2):Play()
    end)
    btn.MouseLeave:Connect(function()
        tw(btn, { BackgroundColor3 = C.PanelGray }, 0.2):Play()
        tw(outerRing, { BackgroundTransparency = 0.3 }, 0.2):Play()
    end)

    -- Make the whole thing draggable (on the button itself)
    local dragState = makeDraggable(root, btn)

    -- Click scale bounce (only if user didn't drag)
    btn.MouseButton1Click:Connect(function()
        -- Ignore click if user was dragging
        if dragState.isDragging() then return end

        tw(root, { Size = UDim2.new(0, btnSize + 14, 0, btnSize + 14) }, 0.1, Enum.EasingStyle.Back, Enum.EasingDirection.Out):Play()
        task.delay(0.1, function()
            tw(root, { Size = UDim2.new(0, btnSize + 20, 0, btnSize + 20) }, 0.25, Enum.EasingStyle.Elastic, Enum.EasingDirection.Out):Play()
        end)
    end)

    return root, btn, dragState
end


-- ╔══════════════════════════════════════════════════════════════╗
-- ║                    MAIN WINDOW                               ║
-- ║                                                              ║
-- ║  - Opens from center as a circle → expands to rectangle     ║
-- ║  - Custom background image support                          ║
-- ║  - Draggable by title bar (mouse + touch)                   ║
-- ║  - Mobile-responsive sizing                                 ║
-- ║  - Gray & white theme                                       ║
-- ╚══════════════════════════════════════════════════════════════╝

function ArabyHub:CreateMainWindow(options)
    options = options or {}
    local bgImage = options.windowBg    -- "rbxassetid://..." or "https://..." or nil
    local mobile = isMobile()

    -- Responsive sizing
    local vpW, vpH = getViewSize()
    local winW = math.min(mobile and (vpW * 0.92) or 420, 500)
    local winH = math.min(mobile and (vpH * 0.75) or 320, 380)
    local titleH = mobile and 44 or 40

    -- ═══ Window Structure ═══
    -- MainFrame
    --   ├── Background (Frame, dark panel)
    --   ├── BGImage (ImageLabel, optional custom bg)
    --   ├── BGOverlay (Frame, darkens bg image)
    --   ├── TitleBar (Frame, draggable header)
    --   │   ├── TitleText "ARABY HUB"
    --   │   ├── CloseBtn
    --   │   └── MinimizeBtn
    --   └── Content (ScrollingFrame, your content goes here)

    local mainFrame = Instance.new("Frame")
    mainFrame.Name = "ArabyHubWindow"
    mainFrame.Size = UDim2.new(0, 0, 0, 0)         -- start tiny (circle)
    mainFrame.Position = UDim2.new(0.5, 0, 0.5, 0)  -- center
    mainFrame.AnchorPoint = Vector2.new(0.5, 0.5)
    mainFrame.BackgroundColor3 = C.PanelGray
    mainFrame.BackgroundTransparency = 0
    mainFrame.BorderSizePixel = 0
    mainFrame.ClipsDescendants = true                 -- clip the circle shape
    mainFrame.Visible = false
    mainFrame.ZIndex = 50

    -- Corner radius: start as circle (0.5), end as rounded rect (14)
    local mainCorner = corner(mainFrame, 14)
    mainCorner.CornerRadius = UDim.new(0.5, 0) -- circle initially

    -- Optional background image
    if bgImage then
        local bgImg = Instance.new("ImageLabel")
        bgImg.Name = "BackgroundImage"
        bgImg.Size = UDim2.new(1, 0, 1, 0)
        bgImg.Position = UDim2.new(0, 0, 0, 0)
        bgImg.BackgroundTransparency = 1
        bgImg.Image = bgImage
        bgImg.ImageTransparency = 0.35
        bgImg.ScaleType = Enum.ScaleType.Stretch
        bgImg.ZIndex = 0
        bgImg.Parent = mainFrame
    end

    -- Dark overlay (on top of bg image to keep text readable)
    local overlay = Instance.new("Frame")
    overlay.Name = "Overlay"
    overlay.Size = UDim2.new(1, 0, 1, 0)
    overlay.BackgroundColor3 = C.VeryDark
    overlay.BackgroundTransparency = 0.35
    overlay.BorderSizePixel = 0
    overlay.ZIndex = 1
    overlay.Parent = mainFrame

    -- ─── Title Bar ───
    local titleBar = Instance.new("Frame")
    titleBar.Name = "TitleBar"
    titleBar.Size = UDim2.new(1, 0, 0, titleH)
    titleBar.Position = UDim2.new(0, 0, 0, 0)
    titleBar.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
    titleBar.BackgroundTransparency = 0.2
    titleBar.BorderSizePixel = 0
    titleBar.ZIndex = 10
    titleBar.Parent = mainFrame

    -- Thin bottom line on title bar
    local titleLine = Instance.new("Frame")
    titleLine.Name = "BottomLine"
    titleLine.Size = UDim2.new(1, 0, 0, 1)
    titleLine.Position = UDim2.new(0, 0, 1, 0)
    titleLine.AnchorPoint = Vector2.new(0, 1)
    titleLine.BackgroundColor3 = C.DarkGray
    titleLine.BackgroundTransparency = 0.3
    titleLine.BorderSizePixel = 0
    titleLine.ZIndex = 11
    titleLine.Parent = titleBar

    -- Title text
    local titleText = Instance.new("TextLabel")
    titleText.Name = "Title"
    titleText.Size = UDim2.new(1, -80, 1, 0)
    titleText.Position = UDim2.new(0, 16, 0, 0)
    titleText.BackgroundTransparency = 1
    titleText.Text = "ARABY HUB"
    titleText.Font = Enum.Font.GothamBold
    titleText.TextSize = mobile and 15 or 16
    titleText.TextColor3 = C.White
    titleText.TextXAlignment = Enum.TextXAlignment.Left
    titleText.ZIndex = 12
    titleText.Parent = titleBar

    -- Close button (X)
    local closeBtn = Instance.new("TextButton")
    closeBtn.Name = "CloseBtn"
    closeBtn.Size = UDim2.new(0, titleH - 8, 0, titleH - 8)
    closeBtn.Position = UDim2.new(1, -(titleH - 4), 0.5, 0)
    closeBtn.AnchorPoint = Vector2.new(0, 0.5)
    closeBtn.BackgroundColor3 = Color3.fromRGB(180, 50, 50)
    closeBtn.BackgroundTransparency = 0.7
    closeBtn.BorderSizePixel = 0
    closeBtn.Text = "X"
    closeBtn.Font = Enum.Font.GothamBold
    closeBtn.TextSize = 14
    closeBtn.TextColor3 = C.White
    closeBtn.AutoButtonColor = true
    closeBtn.ZIndex = 13
    corner(closeBtn, (titleH - 8) / 2)
    closeBtn.Parent = titleBar

    -- Close hover
    closeBtn.MouseEnter:Connect(function()
        tw(closeBtn, { BackgroundTransparency = 0.3 }, 0.15):Play()
    end)
    closeBtn.MouseLeave:Connect(function()
        tw(closeBtn, { BackgroundTransparency = 0.7 }, 0.15):Play()
    end)

    -- Minimize button (—)
    local minBtn = Instance.new("TextButton")
    minBtn.Name = "MinimizeBtn"
    minBtn.Size = UDim2.new(0, titleH - 8, 0, titleH - 8)
    minBtn.Position = UDim2.new(1, -((titleH - 8) * 2 + 8), 0.5, 0)
    minBtn.AnchorPoint = Vector2.new(0, 0.5)
    minBtn.BackgroundColor3 = C.DarkGray
    minBtn.BackgroundTransparency = 0.5
    minBtn.BorderSizePixel = 0
    minBtn.Text = "—"
    minBtn.Font = Enum.Font.GothamBold
    minBtn.TextSize = 16
    minBtn.TextColor3 = C.White
    minBtn.AutoButtonColor = true
    minBtn.ZIndex = 13
    corner(minBtn, (titleH - 8) / 2)
    minBtn.Parent = titleBar

    -- Minimize hover
    minBtn.MouseEnter:Connect(function()
        tw(minBtn, { BackgroundTransparency = 0.2 }, 0.15):Play()
    end)
    minBtn.MouseLeave:Connect(function()
        tw(minBtn, { BackgroundTransparency = 0.5 }, 0.15):Play()
    end)

    -- ─── Content Area ───
    local content = Instance.new("ScrollingFrame")
    content.Name = "Content"
    content.Size = UDim2.new(1, -20, 1, -(titleH + 20))
    content.Position = UDim2.new(0, 10, 0, titleH + 10)
    content.BackgroundTransparency = 1
    content.BorderSizePixel = 0
    content.ScrollBarThickness = mobile and 3 or 4
    content.ScrollBarImageColor3 = C.MidGray
    content.CanvasSize = UDim2.new(0, 0, 0, 0)
    content.AutomaticCanvasSize = Enum.AutomaticSize.Y
    content.ZIndex = 5
    content.Parent = mainFrame

    local listLayout = Instance.new("UIListLayout")
    listLayout.SortOrder = Enum.SortOrder.LayoutOrder
    listLayout.Padding = UDim.new(0, 8)
    listLayout.Parent = content

    local listPadding = Instance.new("UIPadding")
    listPadding.PaddingLeft = UDim.new(0, 4)
    listPadding.PaddingRight = UDim.new(0, 4)
    listPadding.PaddingTop = UDim.new(0, 4)
    listPadding.PaddingBottom = UDim.new(0, 4)
    listPadding.Parent = content

    -- Make window draggable from title bar
    makeDraggable(mainFrame, titleBar)

    -- ═══════════════════════════════════
    --  OPEN animation: circle → rectangle
    -- ═══════════════════════════════════
    local function open()
        if mainFrame.Visible then return end

        -- Reset to circle state
        mainFrame.Visible = true
        mainFrame.Size = UDim2.new(0, 0, 0, 0)
        mainFrame.BackgroundTransparency = 0.3
        mainCorner.CornerRadius = UDim.new(0.5, 0)
        overlay.BackgroundTransparency = 1
        titleBar.BackgroundTransparency = 1
        titleText.TextTransparency = 1
        closeBtn.TextTransparency = 1
        minBtn.TextTransparency = 1
        titleLine.BackgroundTransparency = 1

        -- Animate to full rectangle
        tw(mainFrame, {
            Size = UDim2.new(0, winW, 0, winH),
            BackgroundTransparency = 0,
        }, 0.6, Enum.EasingStyle.Back, Enum.EasingDirection.Out):Play()

        tw(mainCorner, {
            CornerRadius = UDim.new(0, 14),
        }, 0.5, Enum.EasingStyle.Quart, Enum.EasingDirection.Out):Play()

        -- Fade in inner elements slightly delayed
        tw(overlay, { BackgroundTransparency = 0.35 }, 0.4, nil, nil, 0.15):Play()
        tw(titleBar, { BackgroundTransparency = 0.2 }, 0.3, nil, nil, 0.2):Play()
        tw(titleText, { TextTransparency = 0 }, 0.3, nil, nil, 0.25):Play()
        tw(closeBtn, { TextTransparency = 0 }, 0.3, nil, nil, 0.3):Play()
        tw(minBtn, { TextTransparency = 0 }, 0.3, nil, nil, 0.3):Play()
        tw(titleLine, { BackgroundTransparency = 0.3 }, 0.3, nil, nil, 0.25):Play()
    end

    -- ═══════════════════════════════════
    --  CLOSE animation: rectangle → circle
    -- ═══════════════════════════════════
    local function close()
        if not mainFrame.Visible then return end

        -- Shrink back to circle
        tw(mainFrame, {
            Size = UDim2.new(0, 0, 0, 0),
            BackgroundTransparency = 0.4,
        }, 0.4, Enum.EasingStyle.Quart, Enum.EasingDirection.In):Play()

        tw(mainCorner, {
            CornerRadius = UDim.new(0.5, 0),
        }, 0.35, Enum.EasingStyle.Quart, Enum.EasingDirection.In):Play()

        -- Fade out inner elements
        tw(overlay, { BackgroundTransparency = 1 }, 0.2):Play()
        tw(titleBar, { BackgroundTransparency = 1 }, 0.2):Play()
        tw(titleText, { TextTransparency = 1 }, 0.2):Play()
        tw(closeBtn, { TextTransparency = 1 }, 0.15):Play()
        tw(minBtn, { TextTransparency = 1 }, 0.15):Play()
        tw(titleLine, { BackgroundTransparency = 1 }, 0.2):Play()

        task.delay(0.45, function()
            mainFrame.Visible = false
        end)
    end

    -- Wire buttons
    closeBtn.MouseButton1Click:Connect(close)
    minBtn.MouseButton1Click:Connect(close)

    return mainFrame, content, { open = open, close = close }
end


-- ╔══════════════════════════════════════════════════════════════╗
-- ║                    INIT — Wire Everything                    ║
-- ╚══════════════════════════════════════════════════════════════╝

function ArabyHub:Init(options)
    options = options or {}

    -- Step 1: Show splash, then show toggle button
    self:ShowSplash(function()
        print("[ArabyHub] Splash complete.")

        local player = game:GetService("Players").LocalPlayer
        local playerGui = player:WaitForChild("PlayerGui")

        -- Persistent ScreenGui for button + window
        local gui = Instance.new("ScreenGui")
        gui.Name = "ArabyHub_UI"
        gui.ResetOnSpawn = false
        gui.IgnoreGuiInset = true
        gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
        gui.DisplayOrder = 100
        gui.Parent = playerGui

        -- Create toggle button
        local toggleRoot, toggleBtn, dragState = self:CreateToggleButton(options)
        toggleRoot.Parent = gui

        -- Create main window
        local mainFrame, content, windowCtrl = self:CreateMainWindow(options)
        mainFrame.Parent = gui

        -- Toggle open/close on button click (only if user didn't drag)
        local isOpen = false
        toggleBtn.MouseButton1Click:Connect(function()
            -- Don't toggle if user was dragging the button
            if dragState.isDragging() then return end

            isOpen = not isOpen
            if isOpen then
                -- Reset position to center before opening
                mainFrame.Position = UDim2.new(0.5, 0, 0.5, 0)
                windowCtrl.open()
            else
                windowCtrl.close()
            end
        end)

        -- Expose for external use
        self._gui = gui
        self._toggleRoot = toggleRoot
        self._toggleBtn = toggleBtn
        self._mainFrame = mainFrame
        self._content = content
        self._windowCtrl = windowCtrl
        self._isOpen = false

        -- Method to toggle from outside
        self.Toggle = function()
            isOpen = not isOpen
            if isOpen then
                mainFrame.Position = UDim2.new(0.5, 0, 0.5, 0)
                windowCtrl.open()
            else
                windowCtrl.close()
            end
            self._isOpen = isOpen
        end

        -- Method to add content to the window
        function self:AddContent(element)
            if content and content.Parent then
                element.Parent = content
            end
        end

        print("[ArabyHub] UI ready. Click the circle button to open.")
    end)
end

return ArabyHub