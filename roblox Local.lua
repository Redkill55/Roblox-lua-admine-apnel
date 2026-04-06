-- ================================================
-- MENU ADMIN ULTIME v10
-- ✅ Loading Screen long + ultra animé
-- ✅ Grille diagonale animée (haut-droit → bas-gauche)
-- ✅ Auras toutes différentes et uniques
-- ✅ ESP plus grand, visible à distance infinie
-- ✅ Couleurs synchronisées en temps réel
-- ✅ Admin Chat, Titre ADMIN, Scanner, Véhicule
-- INSERT = ouvrir/fermer
-- ================================================

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local Lighting = game:GetService("Lighting")

local localPlayer = Players.LocalPlayer
local mouse = localPlayer:GetMouse()

-- ==================== CONFIG ====================
local CONFIG = {
    BgDark      = Color3.fromRGB(8, 8, 14),
    BgCard      = Color3.fromRGB(18, 18, 30),
    BgSidebar   = Color3.fromRGB(6, 6, 12),
    Accent      = Color3.fromRGB(0, 230, 160),
    AccentDim   = Color3.fromRGB(0, 140, 100),
    Danger      = Color3.fromRGB(255, 60, 60),
    Text        = Color3.fromRGB(220, 220, 235),
    TextMuted   = Color3.fromRGB(110, 110, 135),
    Border      = Color3.fromRGB(30, 30, 50),
    ToggleOn    = Color3.fromRGB(0, 210, 120),
    ToggleOff   = Color3.fromRGB(70, 70, 95),
    GridColor   = Color3.fromRGB(0, 230, 160),
    MainSize    = UDim2.new(0, 840, 0, 580),
    MinSize     = Vector2.new(500, 360),
    MaxSize     = Vector2.new(1400, 900),
    Title       = "ADMIN v10",
    Subtitle    = "MENU ULTIME",
    AccentHue   = 160,
}

-- ==================== VARIABLES ====================
local menuGui, mainFrame, contentFrame, sidebar = nil, nil, nil, nil
local gridCanvas = nil
local minimizedIcon = nil
local currentTab = "Mouvement"
local minimized = false

local espEnabled, flyEnabled, noclipEnabled, godEnabled = false, false, false, false
local infJumpEnabled, fullBrightEnabled, noFogEnabled = false, false, false
local rainEnabled, auraEnabled, colorInvertEnabled = false, false, false
local adminChatEnabled, adminTitleEnabled = false, false

local flySpeed = 100
local walkSpeed = 50
local jumpPower = 100

local highlights, infoBillboards = {}, {}
local adminTitleBb = nil
local flyBodyVelocity, movementConnection, noclipConnection = nil, nil, nil
local infJumpConnection, espUpdateConnection = nil, nil
local gridAnimConn = nil
local auraAttachment = nil
local auraEmitters = {}
local fireOrb = nil
local rainEmitter, invertEffect = nil, nil
local rainbowConn = nil
local currentAuraStyle = "Cosmique"
local adminCharacterMode = nil

local originalLighting = {
    Brightness    = Lighting.Brightness,
    Ambient       = Lighting.Ambient,
    FogEnd        = Lighting.FogEnd,
    ClockTime     = Lighting.ClockTime,
    GlobalShadows = Lighting.GlobalShadows,
}

-- ==================== HELPERS ====================
local function tween(obj, props, time, style, dir)
    TweenService:Create(obj,
        TweenInfo.new(time or 0.3, style or Enum.EasingStyle.Quint, dir or Enum.EasingDirection.Out),
        props
    ):Play()
end

local function makeCorner(p, r)
    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, r or 10)
    c.Parent = p
    return c
end

local function makeStroke(p, col, t)
    local s = Instance.new("UIStroke")
    s.Color = col or CONFIG.Border
    s.Thickness = t or 1
    s.Parent = p
    return s
end

local function makeCard(parent, height)
    local card = Instance.new("Frame")
    card.Size = UDim2.new(1, -24, 0, height or 60)
    card.BackgroundColor3 = CONFIG.BgCard
    card.Parent = parent
    makeCorner(card, 12)
    makeStroke(card, CONFIG.Border, 1)
    return card
end

local function makeSectionLabel(parent, txt)
    local f = Instance.new("Frame")
    f.Size = UDim2.new(1, -24, 0, 28)
    f.BackgroundTransparency = 1
    f.Parent = parent
    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, 0, 1, 0)
    label.BackgroundTransparency = 1
    label.Text = "[ " .. txt .. " ]"
    label.TextColor3 = CONFIG.Accent
    label.Font = Enum.Font.GothamBlack
    label.TextSize = 12
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Parent = f
end

local function makeDivider(parent)
    local d = Instance.new("Frame")
    d.Size = UDim2.new(1, -24, 0, 1)
    d.BackgroundColor3 = CONFIG.Border
    d.Parent = parent
end

-- ==================== GRILLE DIAGONALE ANIMÉE ====================
-- La grille se déplace du coin haut-droit vers le coin bas-gauche
local gridLines = {}
local gridOffset = 0
local GRID_SPACING = 48  -- espacement entre lignes en pixels

local function buildDiagonalGrid(parent)
    if gridCanvas then gridCanvas:Destroy() gridCanvas = nil end
    if gridAnimConn then gridAnimConn:Disconnect() gridAnimConn = nil end
    gridLines = {}

    -- Canvas conteneur (ZIndex bas, vraiment en arrière-plan)
    gridCanvas = Instance.new("Frame")
    gridCanvas.Size = UDim2.new(1, 0, 1, 0)
    gridCanvas.BackgroundTransparency = 1
    gridCanvas.ClipsDescendants = true
    gridCanvas.ZIndex = 1
    gridCanvas.Parent = parent

    -- On crée suffisamment de lignes diagonales pour couvrir toute la zone
    -- Les lignes sont à 45 degrés (diagonale haut-droit → bas-gauche)
    local numLines = 32
    for i = 1, numLines do
        local line = Instance.new("Frame")
        -- Largeur fine, haute de 2px, mais rotée à 45°
        -- On utilise un Frame large et fin roté
        line.Size = UDim2.new(0, 2, 0, 2000)
        line.AnchorPoint = Vector2.new(0.5, 0.5)
        line.BackgroundColor3 = CONFIG.GridColor
        line.BackgroundTransparency = 0.75
        line.BorderSizePixel = 0
        line.ZIndex = 1
        line.Rotation = 45  -- diagonale haut-gauche → bas-droit (perpendiculaire à la direction)
        -- Position initiale distribuée sur l'axe diagonal
        line.Position = UDim2.new(0, (i - 1) * GRID_SPACING - GRID_SPACING, 0.5, 0)
        line.Parent = gridCanvas
        table.insert(gridLines, line)
    end

    -- Lignes perpendiculaires (autre diagonale pour effet grille)
    for i = 1, numLines do
        local line = Instance.new("Frame")
        line.Size = UDim2.new(0, 2, 0, 2000)
        line.AnchorPoint = Vector2.new(0.5, 0.5)
        line.BackgroundColor3 = CONFIG.GridColor
        line.BackgroundTransparency = 0.85
        line.BorderSizePixel = 0
        line.ZIndex = 1
        line.Rotation = -45
        line.Position = UDim2.new(0, (i - 1) * GRID_SPACING - GRID_SPACING, 0.5, 0)
        line.Parent = gridCanvas
        table.insert(gridLines, line)
    end

    local t = 0
    gridOffset = 0

    gridAnimConn = RunService.RenderStepped:Connect(function(dt)
        t = t + dt
        gridOffset = gridOffset + dt * 28  -- vitesse de déplacement diagonal

        -- Recalcul de l'offset cyclique
        if gridOffset > GRID_SPACING then
            gridOffset = gridOffset - GRID_SPACING
        end

        local hue = CONFIG.AccentHue / 360
        -- Variation de teinte légère pour effet vivant
        local hShift = (math.sin(t * 0.4) * 0.06)
        local col = Color3.fromHSV((hue + hShift) % 1, 0.9, 1)
        local col2 = Color3.fromHSV((hue + hShift + 0.05) % 1, 0.8, 0.9)

        -- Pulse global
        local pulse = 0.68 + math.sin(t * 2.2) * 0.14

        local numLines = #gridLines / 2

        -- Lignes 45° : se déplacent vers le bas-gauche
        for i = 1, numLines do
            local line = gridLines[i]
            if line and line.Parent then
                local baseX = (i - 1) * GRID_SPACING - GRID_SPACING
                -- déplacement diagonal : x diminue, y augmente
                local ox = -gridOffset
                local oy = gridOffset
                line.Position = UDim2.new(0, baseX + ox, 0.5, oy)
                line.BackgroundColor3 = col
                line.BackgroundTransparency = pulse

                -- Ligne brillante toutes les N lignes
                if i % 4 == 0 then
                    local bright = 0.45 + math.sin(t * 3 + i * 0.5) * 0.15
                    line.BackgroundTransparency = bright
                    line.Size = UDim2.new(0, 3, 0, 2000)
                else
                    line.Size = UDim2.new(0, 1, 0, 2000)
                    line.BackgroundTransparency = pulse + 0.1
                end
            end
        end

        -- Lignes -45° : se déplacent dans le sens opposé légèrement
        for i = numLines + 1, #gridLines do
            local line = gridLines[i]
            if line and line.Parent then
                local idx = i - numLines
                local baseX = (idx - 1) * GRID_SPACING - GRID_SPACING
                local ox = gridOffset * 0.6
                local oy = gridOffset * 0.6
                line.Position = UDim2.new(0, baseX + ox, 0.5, oy)
                line.BackgroundColor3 = col2
                line.BackgroundTransparency = pulse + 0.08

                if idx % 5 == 0 then
                    local bright = 0.5 + math.sin(t * 2.5 + idx * 0.7) * 0.12
                    line.BackgroundTransparency = bright
                    line.Size = UDim2.new(0, 2, 0, 2000)
                else
                    line.Size = UDim2.new(0, 1, 0, 2000)
                end
            end
        end
    end)
end

local function updateGridColor(hue)
    CONFIG.AccentHue = hue
    CONFIG.Accent = Color3.fromHSV(hue / 360, 0.9, 0.95)
    CONFIG.GridColor = Color3.fromHSV(hue / 360, 1, 1)
end

-- ==================== COMPOSANTS UI ====================
local function createToggle(parent, text, description, default, callback)
    local h = description and 68 or 54
    local card = makeCard(parent, h)

    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(0.7, 0, 0, 22)
    label.Position = UDim2.new(0, 14, 0, description and 9 or 16)
    label.BackgroundTransparency = 1
    label.Text = text
    label.TextColor3 = CONFIG.Text
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Font = Enum.Font.GothamBold
    label.TextSize = 15
    label.Parent = card

    if description then
        local desc = Instance.new("TextLabel")
        desc.Size = UDim2.new(0.7, 0, 0, 16)
        desc.Position = UDim2.new(0, 14, 0, 34)
        desc.BackgroundTransparency = 1
        desc.Text = description
        desc.TextColor3 = CONFIG.TextMuted
        desc.TextXAlignment = Enum.TextXAlignment.Left
        desc.Font = Enum.Font.Gotham
        desc.TextSize = 12
        desc.Parent = card
    end

    local trackW, trackH = 52, 26
    local track = Instance.new("Frame")
    track.Size = UDim2.new(0, trackW, 0, trackH)
    track.Position = UDim2.new(1, -(trackW + 14), 0.5, -trackH / 2)
    track.BackgroundColor3 = default and CONFIG.ToggleOn or CONFIG.ToggleOff
    track.Parent = card
    makeCorner(track, 13)

    local knob = Instance.new("Frame")
    knob.Size = UDim2.new(0, 20, 0, 20)
    knob.Position = default and UDim2.new(0, trackW - 24, 0.5, -10) or UDim2.new(0, 4, 0.5, -10)
    knob.BackgroundColor3 = Color3.new(1, 1, 1)
    knob.Parent = track
    makeCorner(knob, 10)

    local click = Instance.new("TextButton")
    click.Size = UDim2.new(1, 0, 1, 0)
    click.BackgroundTransparency = 1
    click.Text = ""
    click.Parent = card

    local state = default
    click.MouseButton1Click:Connect(function()
        state = not state
        tween(track, {BackgroundColor3 = state and CONFIG.ToggleOn or CONFIG.ToggleOff}, 0.18)
        tween(knob, {Position = state and UDim2.new(0, trackW - 24, 0.5, -10) or UDim2.new(0, 4, 0.5, -10)}, 0.18)
        callback(state)
    end)
    return card
end

local function createSlider(parent, text, minVal, maxVal, defaultVal, callback)
    local card = makeCard(parent, 76)

    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(0.65, 0, 0, 20)
    label.Position = UDim2.new(0, 14, 0, 10)
    label.BackgroundTransparency = 1
    label.Text = text
    label.TextColor3 = CONFIG.Text
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Font = Enum.Font.GothamBold
    label.TextSize = 14
    label.Parent = card

    local valLabel = Instance.new("TextLabel")
    valLabel.Size = UDim2.new(0.3, -14, 0, 20)
    valLabel.Position = UDim2.new(0.7, 0, 0, 10)
    valLabel.BackgroundTransparency = 1
    valLabel.Text = tostring(math.floor(defaultVal))
    valLabel.TextColor3 = CONFIG.Accent
    valLabel.TextXAlignment = Enum.TextXAlignment.Right
    valLabel.Font = Enum.Font.GothamBold
    valLabel.TextSize = 14
    valLabel.Parent = card

    local trackFrame = Instance.new("Frame")
    trackFrame.Size = UDim2.new(1, -28, 0, 8)
    trackFrame.Position = UDim2.new(0, 14, 0, 44)
    trackFrame.BackgroundColor3 = Color3.fromRGB(12, 12, 20)
    trackFrame.Parent = card
    makeCorner(trackFrame, 4)
    makeStroke(trackFrame, CONFIG.Border, 1)

    local fill = Instance.new("Frame")
    fill.Size = UDim2.new(0, 0, 1, 0)
    fill.BackgroundColor3 = CONFIG.Accent
    fill.Parent = trackFrame
    makeCorner(fill, 4)

    local knob = Instance.new("TextButton")
    knob.Size = UDim2.new(0, 18, 0, 18)
    knob.Position = UDim2.new(0, -9, 0.5, -9)
    knob.BackgroundColor3 = Color3.new(1, 1, 1)
    knob.Text = ""
    knob.Parent = trackFrame
    makeCorner(knob, 9)

    local value = defaultVal
    local dragging = false

    local function updateSlider()
        local percent = math.clamp((value - minVal) / (maxVal - minVal), 0, 1)
        fill.Size = UDim2.new(percent, 0, 1, 0)
        knob.Position = UDim2.new(percent, -9, 0.5, -9)
        valLabel.Text = tostring(math.floor(value))
        callback(value)
    end

    knob.MouseButton1Down:Connect(function() dragging = true end)
    UserInputService.InputEnded:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 then dragging = false end
    end)
    RunService.RenderStepped:Connect(function()
        if dragging then
            local relX = mouse.X - trackFrame.AbsolutePosition.X
            local percent = math.clamp(relX / trackFrame.AbsoluteSize.X, 0, 1)
            value = minVal + (maxVal - minVal) * percent
            updateSlider()
        end
    end)
    updateSlider()
    return card
end

local function createButton(parent, text, col, callback)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1, -24, 0, 46)
    btn.BackgroundColor3 = col or CONFIG.BgCard
    btn.Text = text
    btn.TextColor3 = CONFIG.Text
    btn.Font = Enum.Font.GothamBold
    btn.TextSize = 15
    btn.Parent = parent
    makeCorner(btn, 10)
    makeStroke(btn, CONFIG.Border, 1)
    btn.MouseEnter:Connect(function() tween(btn, {BackgroundColor3 = (col or CONFIG.BgCard):lerp(Color3.new(1,1,1), 0.1)}, 0.12) end)
    btn.MouseLeave:Connect(function() tween(btn, {BackgroundColor3 = col or CONFIG.BgCard}, 0.12) end)
    btn.MouseButton1Down:Connect(function() tween(btn, {Size = UDim2.new(1, -26, 0, 44)}, 0.06) end)
    btn.MouseButton1Up:Connect(function()
        tween(btn, {Size = UDim2.new(1, -24, 0, 46)}, 0.1)
        callback()
    end)
    return btn
end

local function createTextInput(parent, placeholder, callback)
    local card = makeCard(parent, 56)
    local input = Instance.new("TextBox")
    input.Size = UDim2.new(1, -80, 0, 36)
    input.Position = UDim2.new(0, 10, 0.5, -18)
    input.BackgroundColor3 = Color3.fromRGB(12, 12, 20)
    input.PlaceholderText = placeholder
    input.PlaceholderColor3 = CONFIG.TextMuted
    input.Text = ""
    input.TextColor3 = CONFIG.Text
    input.Font = Enum.Font.Gotham
    input.TextSize = 14
    input.ClearTextOnFocus = false
    input.Parent = card
    makeCorner(input, 8)
    makeStroke(input, CONFIG.Border, 1)

    local sendBtn = Instance.new("TextButton")
    sendBtn.Size = UDim2.new(0, 60, 0, 36)
    sendBtn.Position = UDim2.new(1, -70, 0.5, -18)
    sendBtn.BackgroundColor3 = CONFIG.Accent
    sendBtn.Text = "SEND"
    sendBtn.TextColor3 = Color3.fromRGB(5, 20, 15)
    sendBtn.Font = Enum.Font.GothamBlack
    sendBtn.TextSize = 12
    sendBtn.Parent = card
    makeCorner(sendBtn, 8)

    sendBtn.MouseButton1Click:Connect(function()
        if input.Text ~= "" then callback(input.Text) input.Text = "" end
    end)
    input.FocusLost:Connect(function(enter)
        if enter and input.Text ~= "" then callback(input.Text) input.Text = "" end
    end)
end

-- ==================== LOADING SCREEN ULTRA STYLÉ ====================
local function showLoadingScreen(onDone)
    local sg = Instance.new("ScreenGui")
    sg.ResetOnSpawn = false
    sg.Parent = localPlayer.PlayerGui

    -- Fond principal
    local bg = Instance.new("Frame")
    bg.Size = UDim2.new(1, 0, 1, 0)
    bg.BackgroundColor3 = Color3.fromRGB(4, 4, 8)
    bg.Parent = sg

    -- ===== GRILLE DIAGONALE EN BACKGROUND DU LOADING =====
    local lgGrid = Instance.new("Frame")
    lgGrid.Size = UDim2.new(1, 0, 1, 0)
    lgGrid.BackgroundTransparency = 1
    lgGrid.ClipsDescendants = true
    lgGrid.Parent = bg

    local loadGridLines = {}
    local numDiag = 28
    for i = 1, numDiag do
        local l = Instance.new("Frame")
        l.Size = UDim2.new(0, 1, 0, 2000)
        l.AnchorPoint = Vector2.new(0.5, 0.5)
        l.Rotation = 45
        l.BackgroundColor3 = Color3.fromRGB(0, 200, 140)
        l.BackgroundTransparency = 0.82
        l.BorderSizePixel = 0
        l.Position = UDim2.new(0, (i - 1) * 52 - 100, 0.5, 0)
        l.Parent = lgGrid
        table.insert(loadGridLines, {frame = l, base = (i - 1) * 52 - 100, type = 1})
    end
    for i = 1, numDiag do
        local l = Instance.new("Frame")
        l.Size = UDim2.new(0, 1, 0, 2000)
        l.AnchorPoint = Vector2.new(0.5, 0.5)
        l.Rotation = -45
        l.BackgroundColor3 = Color3.fromRGB(0, 160, 110)
        l.BackgroundTransparency = 0.88
        l.BorderSizePixel = 0
        l.Position = UDim2.new(0, (i - 1) * 52 - 100, 0.5, 0)
        l.Parent = lgGrid
        table.insert(loadGridLines, {frame = l, base = (i - 1) * 52 - 100, type = 2})
    end

    -- Points lumineux aux intersections (effet décoratif)
    for i = 1, 18 do
        local dot = Instance.new("Frame")
        dot.Size = UDim2.new(0, 4, 0, 4)
        dot.AnchorPoint = Vector2.new(0.5, 0.5)
        dot.Position = UDim2.new(math.random() * 0.9 + 0.05, 0, math.random() * 0.9 + 0.05, 0)
        dot.BackgroundColor3 = Color3.fromRGB(0, 255, 180)
        dot.BackgroundTransparency = 0.2
        dot.BorderSizePixel = 0
        dot.Parent = lgGrid
        makeCorner(dot, 2)
        task.spawn(function()
            while dot.Parent do
                tween(dot, {BackgroundTransparency = 0.9, Size = UDim2.new(0, 2, 0, 2)}, 1.2 + math.random() * 0.8)
                task.wait(1.2 + math.random() * 0.8)
                tween(dot, {BackgroundTransparency = 0.1, Size = UDim2.new(0, 6, 0, 6)}, 0.8)
                task.wait(0.8)
            end
        end)
    end

    -- Animation de la grille loading
    local lgOffset = 0
    local lgConn = RunService.RenderStepped:Connect(function(dt)
        lgOffset = lgOffset + dt * 35
        if lgOffset > 52 then lgOffset = lgOffset - 52 end
        for _, lg in ipairs(loadGridLines) do
            if lg.frame and lg.frame.Parent then
                local ox = lg.type == 1 and -lgOffset or lgOffset * 0.7
                local oy = lg.type == 1 and lgOffset or lgOffset * 0.7
                lg.frame.Position = UDim2.new(0, lg.base + ox, 0.5, oy)
            end
        end
    end)

    -- ===== HEXAGONE CENTRAL ANIMÉ =====
    local centerGroup = Instance.new("Frame")
    centerGroup.Size = UDim2.new(0, 220, 0, 220)
    centerGroup.Position = UDim2.new(0.5, -110, 0.5, -160)
    centerGroup.BackgroundTransparency = 1
    centerGroup.Parent = bg

    -- Anneaux concentriques
    for i = 3, 1, -1 do
        local ring = Instance.new("Frame")
        ring.Size = UDim2.new(0, i * 70, 0, i * 70)
        ring.AnchorPoint = Vector2.new(0.5, 0.5)
        ring.Position = UDim2.new(0.5, 0, 0.5, 0)
        ring.BackgroundTransparency = 1
        ring.Parent = centerGroup
        makeCorner(ring, i * 35)
        local stroke = makeStroke(ring, Color3.fromRGB(0, 230, 160), 2 - (i - 1) * 0.4)
        stroke.Transparency = 0.3 + (i - 1) * 0.2
        local spinDir = i % 2 == 0 and 1 or -1
        local speed = 0.4 + i * 0.15
        task.spawn(function()
            local angle = 0
            while ring.Parent do
                angle = angle + spinDir * speed
                ring.Rotation = angle
                RunService.RenderStepped:Wait()
            end
        end)
    end

    -- Cercle central avec "v10"
    local innerCircle = Instance.new("Frame")
    innerCircle.Size = UDim2.new(0, 90, 0, 90)
    innerCircle.AnchorPoint = Vector2.new(0.5, 0.5)
    innerCircle.Position = UDim2.new(0.5, 0, 0.5, 0)
    innerCircle.BackgroundColor3 = Color3.fromRGB(0, 20, 14)
    innerCircle.Parent = centerGroup
    makeCorner(innerCircle, 45)
    makeStroke(innerCircle, Color3.fromRGB(0, 255, 180), 2)

    local vLbl = Instance.new("TextLabel")
    vLbl.Size = UDim2.new(1, 0, 0.55, 0)
    vLbl.Position = UDim2.new(0, 0, 0.1, 0)
    vLbl.BackgroundTransparency = 1
    vLbl.Text = "v10"
    vLbl.TextColor3 = Color3.fromRGB(0, 255, 180)
    vLbl.Font = Enum.Font.GothamBlack
    vLbl.TextSize = 30
    vLbl.Parent = innerCircle

    local adminLbl = Instance.new("TextLabel")
    adminLbl.Size = UDim2.new(1, 0, 0.35, 0)
    adminLbl.Position = UDim2.new(0, 0, 0.62, 0)
    adminLbl.BackgroundTransparency = 1
    adminLbl.Text = "ADMIN"
    adminLbl.TextColor3 = Color3.fromRGB(100, 200, 160)
    adminLbl.Font = Enum.Font.GothamBold
    adminLbl.TextSize = 11
    adminLbl.Parent = innerCircle

    -- Pulse du cercle central
    task.spawn(function()
        while innerCircle.Parent do
            tween(innerCircle, {BackgroundColor3 = Color3.fromRGB(0, 35, 22)}, 1.1)
            task.wait(1.1)
            tween(innerCircle, {BackgroundColor3 = Color3.fromRGB(0, 15, 10)}, 1.1)
            task.wait(1.1)
        end
    end)

    -- ===== TITRE PRINCIPAL =====
    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(0, 700, 0, 56)
    title.Position = UDim2.new(0.5, -350, 0.5, 72)
    title.BackgroundTransparency = 1
    title.Text = "MENU ADMIN ULTIME"
    title.TextColor3 = Color3.new(1, 1, 1)
    title.Font = Enum.Font.GothamBlack
    title.TextSize = 38
    title.TextTransparency = 1
    title.Parent = bg

    local subtitle = Instance.new("TextLabel")
    subtitle.Size = UDim2.new(0, 700, 0, 28)
    subtitle.Position = UDim2.new(0.5, -350, 0.5, 132)
    subtitle.BackgroundTransparency = 1
    subtitle.Text = "INITIALISATION DU SYSTÈME..."
    subtitle.TextColor3 = Color3.fromRGB(0, 230, 160)
    subtitle.Font = Enum.Font.GothamBold
    subtitle.TextSize = 16
    subtitle.TextTransparency = 1
    subtitle.Parent = bg

    -- ===== LIGNE DE SÉPARATION ANIMÉE =====
    local sepLine = Instance.new("Frame")
    sepLine.Size = UDim2.new(0, 0, 0, 1)
    sepLine.Position = UDim2.new(0.5, -220, 0.5, 170)
    sepLine.BackgroundColor3 = Color3.fromRGB(0, 230, 160)
    sepLine.BackgroundTransparency = 0.3
    sepLine.Parent = bg

    -- ===== BARRE DE PROGRESSION =====
    local barBg = Instance.new("Frame")
    barBg.Size = UDim2.new(0, 460, 0, 6)
    barBg.Position = UDim2.new(0.5, -230, 0.5, 185)
    barBg.BackgroundColor3 = Color3.fromRGB(15, 15, 25)
    barBg.Parent = bg
    makeCorner(barBg, 3)
    makeStroke(barBg, Color3.fromRGB(30, 30, 50), 1)

    local barFill = Instance.new("Frame")
    barFill.Size = UDim2.new(0, 0, 1, 0)
    barFill.BackgroundColor3 = Color3.fromRGB(0, 230, 160)
    barFill.Parent = barBg
    makeCorner(barFill, 3)

    -- Brillance sur la barre
    local barShine = Instance.new("Frame")
    barShine.Size = UDim2.new(0, 20, 1, 0)
    barShine.BackgroundColor3 = Color3.new(1, 1, 1)
    barShine.BackgroundTransparency = 0.7
    barShine.Parent = barFill
    makeCorner(barShine, 3)

    local statusLbl = Instance.new("TextLabel")
    statusLbl.Size = UDim2.new(0, 460, 0, 24)
    statusLbl.Position = UDim2.new(0.5, -230, 0.5, 196)
    statusLbl.BackgroundTransparency = 1
    statusLbl.Text = ""
    statusLbl.TextColor3 = Color3.fromRGB(90, 90, 115)
    statusLbl.Font = Enum.Font.GothamBold
    statusLbl.TextSize = 12
    statusLbl.Parent = bg

    -- ===== COMPTEUR DE POURCENTAGE =====
    local percentLbl = Instance.new("TextLabel")
    percentLbl.Size = UDim2.new(0, 80, 0, 24)
    percentLbl.Position = UDim2.new(0.5, 155, 0.5, 183)
    percentLbl.BackgroundTransparency = 1
    percentLbl.Text = "0%"
    percentLbl.TextColor3 = Color3.fromRGB(0, 230, 160)
    percentLbl.Font = Enum.Font.GothamBlack
    percentLbl.TextSize = 13
    percentLbl.TextXAlignment = Enum.TextXAlignment.Left
    percentLbl.Parent = bg

    -- ===== PARTICULES DÉCORATIVES (coins) =====
    for cx = 0, 1 do for cy = 0, 1 do
        local corner = Instance.new("Frame")
        corner.Size = UDim2.new(0, 40, 0, 40)
        corner.Position = UDim2.new(cx, cx == 0 and 20 or -60, cy, cy == 0 and 20 or -60)
        corner.BackgroundTransparency = 1
        corner.Parent = bg
        -- Lignes de coin
        for _, dir in ipairs({"H", "V"}) do
            local line = Instance.new("Frame")
            line.Size = dir == "H" and UDim2.new(1, 0, 0, 1) or UDim2.new(0, 1, 1, 0)
            line.AnchorPoint = cx == 1 and (dir == "H" and Vector2.new(1, 0) or Vector2.new(1, cy == 1 and 1 or 0)) or Vector2.new(0, 0)
            line.Position = cx == 1 and (dir == "H" and UDim2.new(1, 0, cy == 1 and 1 or 0, 0) or UDim2.new(1, 0, cy == 1 and 1 or 0, 0)) or UDim2.new(0, 0, cy == 1 and 1 or 0, 0)
            line.BackgroundColor3 = Color3.fromRGB(0, 230, 160)
            line.BackgroundTransparency = 0.3
            line.BorderSizePixel = 0
            line.Parent = corner
        end
    end end

    -- ===== TAGS SYSTÈME (style terminal) =====
    local tagLabels = {}
    local tagTexts = {
        "[SYS] > Chargement kernel admin...",
        "[ESP] > Module visuel initialisé",
        "[FLY] > Vecteur de vol prêt",
        "[AURA] > 6 styles disponibles",
        "[CHAT] > Protocole admin actif",
        "[SCAN] > Détection d'items OK",
        "[VEH] > Contrôle véhicule OK",
        "[NET] > Connexion établie ✓",
    }
    for i, txt in ipairs(tagTexts) do
        local tag = Instance.new("TextLabel")
        tag.Size = UDim2.new(0, 340, 0, 18)
        tag.Position = UDim2.new(0, 20, 0, 20 + (i - 1) * 22)
        tag.BackgroundTransparency = 1
        tag.Text = txt
        tag.TextColor3 = Color3.fromRGB(0, 120, 80)
        tag.TextXAlignment = Enum.TextXAlignment.Left
        tag.Font = Enum.Font.Code
        tag.TextSize = 11
        tag.TextTransparency = 1
        tag.Parent = bg
        table.insert(tagLabels, tag)
    end

    -- ===== ÉTAPES DE CHARGEMENT =====
    local steps = {
        {text = "Initialisation du kernel admin...", delay = 0.55},
        {text = "Chargement des modules ESP...", delay = 0.5},
        {text = "Injection des fonctions vol & vitesse...", delay = 0.5},
        {text = "Calibrage du scanner d'items...", delay = 0.48},
        {text = "Connexion des auras (6 styles)...", delay = 0.52},
        {text = "Activation Admin Chat & Titres...", delay = 0.45},
        {text = "Chargement grille diagonale...", delay = 0.4},
        {text = "Calibrage véhicule & monde...", delay = 0.42},
        {text = "Optimisation ESP infini...", delay = 0.38},
        {text = "Finalisation v10...", delay = 0.3},
    }

    task.spawn(function()
        task.wait(0.3)

        -- Apparition titre + subtitle
        tween(title, {TextTransparency = 0}, 0.7)
        task.wait(0.3)
        tween(subtitle, {TextTransparency = 0}, 0.6)
        task.wait(0.3)

        -- Ligne séparatrice qui s'étend
        tween(sepLine, {Size = UDim2.new(0, 440, 0, 1), Position = UDim2.new(0.5, -220, 0.5, 170)}, 0.7)
        task.wait(0.5)

        -- Apparition progressive des tags système (style terminal)
        for i, tag in ipairs(tagLabels) do
            tween(tag, {TextTransparency = 0, TextColor3 = Color3.fromRGB(0, 180, 110)}, 0.25)
            task.wait(0.18)
        end
        task.wait(0.2)

        local totalTime = 0
        for _, s in ipairs(steps) do totalTime = totalTime + s.delay end
        local elapsed = 0
        local progressPct = 0

        for stepIdx, step in ipairs(steps) do
            statusLbl.Text = step.text
            statusLbl.TextColor3 = Color3.fromRGB(0, 200, 130)

            -- Mettre à jour le tag correspondant si dispo
            if tagLabels[stepIdx] then
                tween(tagLabels[stepIdx], {TextColor3 = Color3.fromRGB(0, 255, 170)}, 0.2)
            end

            elapsed = elapsed + step.delay
            local targetPct = math.floor(elapsed / totalTime * 100)

            tween(barFill, {Size = UDim2.new(elapsed / totalTime, 0, 1, 0)}, step.delay * 0.85)

            -- Animer le compteur de %
            local startPct = progressPct
            local endPct = targetPct
            local pctElapsed = 0
            task.spawn(function()
                while pctElapsed < step.delay * 0.85 do
                    pctElapsed = pctElapsed + RunService.RenderStepped:Wait()
                    local p = math.min(pctElapsed / (step.delay * 0.85), 1)
                    percentLbl.Text = math.floor(startPct + (endPct - startPct) * p) .. "%"
                end
                percentLbl.Text = endPct .. "%"
            end)
            progressPct = endPct

            -- Brillance qui glisse sur la barre
            tween(barShine, {Position = UDim2.new(0, -30, 0, 0)}, 0.01)
            tween(barShine, {Position = UDim2.new(1, 10, 0, 0)}, step.delay * 0.85)

            task.wait(step.delay)
        end

        percentLbl.Text = "100%"
        statusLbl.Text = "✓  SYSTÈME PRÊT"
        statusLbl.TextColor3 = Color3.fromRGB(0, 255, 180)
        percentLbl.TextColor3 = Color3.fromRGB(0, 255, 180)

        -- Flash final
        local flash = Instance.new("Frame")
        flash.Size = UDim2.new(1, 0, 1, 0)
        flash.BackgroundColor3 = Color3.fromRGB(0, 255, 180)
        flash.BackgroundTransparency = 0.85
        flash.ZIndex = 10
        flash.Parent = bg
        tween(flash, {BackgroundTransparency = 1}, 0.5)

        task.wait(0.6)

        -- Fermeture animée
        lgConn:Disconnect()
        tween(bg, {BackgroundTransparency = 1}, 0.55)
        for _, tag in ipairs(tagLabels) do tween(tag, {TextTransparency = 1}, 0.3) end
        tween(title, {TextTransparency = 1}, 0.4)
        tween(subtitle, {TextTransparency = 1}, 0.4)
        tween(statusLbl, {TextTransparency = 1}, 0.4)
        tween(percentLbl, {TextTransparency = 1}, 0.4)
        task.wait(0.65)
        sg:Destroy()
        onDone()
    end)
end

-- ==================== AURAS UNIQUES ====================
local auraStyles = {
    -- 1. COSMIQUE : particules violettes/bleues orbitantes + orbe lumineux
    Cosmique = {
        build = function(attachment, root)
            -- Traînée cosmique principale
            local pe1 = Instance.new("ParticleEmitter", attachment)
            pe1.Texture = "rbxassetid://297658536"
            pe1.Color = ColorSequence.new{
                ColorSequenceKeypoint.new(0, Color3.fromRGB(120, 60, 255)),
                ColorSequenceKeypoint.new(0.5, Color3.fromRGB(60, 120, 255)),
                ColorSequenceKeypoint.new(1, Color3.fromRGB(0, 200, 255)),
            }
            pe1.LightEmission = 0.9
            pe1.Size = NumberSequence.new{NumberSequenceKeypoint.new(0, 8), NumberSequenceKeypoint.new(0.6, 4), NumberSequenceKeypoint.new(1, 0)}
            pe1.Lifetime = NumberRange.new(1.8, 2.5)
            pe1.Rate = 120
            pe1.Speed = NumberRange.new(0, 2)
            pe1.SpreadAngle = Vector2.new(360, 360)
            pe1.RotSpeed = NumberRange.new(-45, 45)
            -- Étoiles scintillantes
            local pe2 = Instance.new("ParticleEmitter", attachment)
            pe2.Texture = "rbxassetid://243098098"
            pe2.Color = ColorSequence.new(Color3.fromRGB(200, 180, 255))
            pe2.LightEmission = 1
            pe2.Size = NumberSequence.new{NumberSequenceKeypoint.new(0, 0.3), NumberSequenceKeypoint.new(0.5, 0.6), NumberSequenceKeypoint.new(1, 0)}
            pe2.Lifetime = NumberRange.new(0.8, 1.4)
            pe2.Rate = 200
            pe2.Speed = NumberRange.new(14, 22)
            pe2.SpreadAngle = Vector2.new(360, 360)
            -- Orbe orbitant cosmique
            local orb = Instance.new("Part")
            orb.Size = Vector3.new(2.5, 2.5, 2.5)
            orb.Shape = Enum.PartType.Ball
            orb.Color = Color3.fromRGB(80, 40, 200)
            orb.Material = Enum.Material.Neon
            orb.Anchored = true
            orb.CanCollide = false
            orb.Parent = workspace
            local orbPe = Instance.new("ParticleEmitter", orb)
            orbPe.Color = ColorSequence.new(Color3.fromRGB(120, 80, 255))
            orbPe.LightEmission = 1
            orbPe.Size = NumberSequence.new(1)
            orbPe.Rate = 80
            orbPe.Lifetime = NumberRange.new(0.5)
            orbPe.Speed = NumberRange.new(5)
            local ang = 0
            task.spawn(function()
                while orb.Parent and auraEnabled do
                    ang = ang + 0.05
                    orb.CFrame = root.CFrame * CFrame.new(math.cos(ang) * 7, math.sin(ang * 0.7) * 3, math.sin(ang) * 7)
                    RunService.RenderStepped:Wait()
                end
                if orb.Parent then orb:Destroy() end
            end)
            return {pe1, pe2, orb}
        end,
    },

    -- 2. FEU INFERNAL : flammes orange/rouge + braises + orbe de feu
    FeuInfernal = {
        build = function(attachment, root)
            local pe1 = Instance.new("ParticleEmitter", attachment)
            pe1.Texture = "rbxassetid://297658536"
            pe1.Color = ColorSequence.new{
                ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 200, 0)),
                ColorSequenceKeypoint.new(0.4, Color3.fromRGB(255, 80, 0)),
                ColorSequenceKeypoint.new(1, Color3.fromRGB(100, 10, 0)),
            }
            pe1.LightEmission = 1
            pe1.Size = NumberSequence.new{NumberSequenceKeypoint.new(0, 10), NumberSequenceKeypoint.new(0.5, 6), NumberSequenceKeypoint.new(1, 0)}
            pe1.Lifetime = NumberRange.new(1.0, 1.6)
            pe1.Rate = 200
            pe1.Speed = NumberRange.new(3, 8)
            pe1.SpreadAngle = Vector2.new(360, 360)
            pe1.Acceleration = Vector3.new(0, 12, 0)
            -- Braises
            local pe2 = Instance.new("ParticleEmitter", attachment)
            pe2.Texture = "rbxassetid://243098098"
            pe2.Color = ColorSequence.new(Color3.fromRGB(255, 160, 0))
            pe2.LightEmission = 1
            pe2.Size = NumberSequence.new{NumberSequenceKeypoint.new(0, 0.4), NumberSequenceKeypoint.new(1, 0)}
            pe2.Lifetime = NumberRange.new(1.5, 2.5)
            pe2.Rate = 280
            pe2.Speed = NumberRange.new(20, 35)
            pe2.SpreadAngle = Vector2.new(180, 180)
            pe2.Acceleration = Vector3.new(0, -15, 0)
            -- Orbe de feu avec fire
            local orb = Instance.new("Part")
            orb.Size = Vector3.new(3.5, 3.5, 3.5)
            orb.Shape = Enum.PartType.Ball
            orb.Color = Color3.fromRGB(255, 60, 0)
            orb.Material = Enum.Material.Neon
            orb.Anchored = true
            orb.CanCollide = false
            orb.Parent = workspace
            local fire = Instance.new("Fire", orb)
            fire.Heat = 12
            fire.Size = 5
            fire.Color = Color3.fromRGB(255, 100, 0)
            fire.SecondaryColor = Color3.fromRGB(255, 200, 0)
            local ang = 0
            task.spawn(function()
                while orb.Parent and auraEnabled do
                    ang = ang + 0.06
                    orb.CFrame = root.CFrame * CFrame.new(math.cos(ang) * 6, math.sin(ang * 1.4) * 2.5 + 2, math.sin(ang) * 6)
                    RunService.RenderStepped:Wait()
                end
                if orb.Parent then orb:Destroy() end
            end)
            return {pe1, pe2, orb, fire}
        end,
    },

    -- 3. GLACE ARCTIQUE : cristaux, givre, traînée bleue froide
    GlaceArctique = {
        build = function(attachment, root)
            local pe1 = Instance.new("ParticleEmitter", attachment)
            pe1.Texture = "rbxassetid://297658536"
            pe1.Color = ColorSequence.new{
                ColorSequenceKeypoint.new(0, Color3.fromRGB(180, 240, 255)),
                ColorSequenceKeypoint.new(0.5, Color3.fromRGB(100, 200, 255)),
                ColorSequenceKeypoint.new(1, Color3.fromRGB(200, 240, 255)),
            }
            pe1.LightEmission = 0.7
            pe1.Size = NumberSequence.new{NumberSequenceKeypoint.new(0, 6), NumberSequenceKeypoint.new(0.7, 3), NumberSequenceKeypoint.new(1, 0)}
            pe1.Lifetime = NumberRange.new(2.5, 3.5)
            pe1.Rate = 80
            pe1.Speed = NumberRange.new(1, 3)
            pe1.SpreadAngle = Vector2.new(360, 360)
            pe1.Acceleration = Vector3.new(0, -2, 0)
            -- Fragments de glace
            local pe2 = Instance.new("ParticleEmitter", attachment)
            pe2.Texture = "rbxassetid://243098098"
            pe2.Color = ColorSequence.new(Color3.fromRGB(220, 248, 255))
            pe2.LightEmission = 0.8
            pe2.Size = NumberSequence.new{NumberSequenceKeypoint.new(0, 0.5), NumberSequenceKeypoint.new(0.4, 0.8), NumberSequenceKeypoint.new(1, 0)}
            pe2.Lifetime = NumberRange.new(1.5, 2.5)
            pe2.Rate = 150
            pe2.Speed = NumberRange.new(10, 18)
            pe2.SpreadAngle = Vector2.new(360, 360)
            pe2.RotSpeed = NumberRange.new(-90, 90)
            -- Souffle de givre (bas)
            local pe3 = Instance.new("ParticleEmitter", attachment)
            pe3.Texture = "rbxassetid://241353019"
            pe3.Color = ColorSequence.new(Color3.fromRGB(200, 240, 255))
            pe3.LightEmission = 0.5
            pe3.Transparency = NumberSequence.new{NumberSequenceKeypoint.new(0, 0.3), NumberSequenceKeypoint.new(1, 1)}
            pe3.Size = NumberSequence.new{NumberSequenceKeypoint.new(0, 2), NumberSequenceKeypoint.new(1, 8)}
            pe3.Lifetime = NumberRange.new(1, 2)
            pe3.Rate = 40
            pe3.Speed = NumberRange.new(5, 10)
            pe3.SpreadAngle = Vector2.new(360, 360)
            pe3.Acceleration = Vector3.new(0, -8, 0)
            return {pe1, pe2, pe3}
        end,
    },

    -- 4. ÉLECTRIQUE : éclairs, arcs, jaune/violet intense
    Electrique = {
        build = function(attachment, root)
            local pe1 = Instance.new("ParticleEmitter", attachment)
            pe1.Texture = "rbxassetid://297658536"
            pe1.Color = ColorSequence.new{
                ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 255, 100)),
                ColorSequenceKeypoint.new(0.5, Color3.fromRGB(180, 100, 255)),
                ColorSequenceKeypoint.new(1, Color3.fromRGB(100, 150, 255)),
            }
            pe1.LightEmission = 1
            pe1.Size = NumberSequence.new{NumberSequenceKeypoint.new(0, 4), NumberSequenceKeypoint.new(0.3, 2), NumberSequenceKeypoint.new(1, 0)}
            pe1.Lifetime = NumberRange.new(0.3, 0.7)
            pe1.Rate = 300
            pe1.Speed = NumberRange.new(25, 45)
            pe1.SpreadAngle = Vector2.new(360, 360)
            -- Étincelles
            local pe2 = Instance.new("ParticleEmitter", attachment)
            pe2.Texture = "rbxassetid://243098098"
            pe2.Color = ColorSequence.new(Color3.fromRGB(255, 255, 0))
            pe2.LightEmission = 1
            pe2.Size = NumberSequence.new{NumberSequenceKeypoint.new(0, 0.7), NumberSequenceKeypoint.new(1, 0)}
            pe2.Lifetime = NumberRange.new(0.2, 0.5)
            pe2.Rate = 400
            pe2.Speed = NumberRange.new(30, 55)
            pe2.SpreadAngle = Vector2.new(360, 360)
            -- Éclats violets
            local pe3 = Instance.new("ParticleEmitter", attachment)
            pe3.Texture = "rbxassetid://297658536"
            pe3.Color = ColorSequence.new(Color3.fromRGB(200, 100, 255))
            pe3.LightEmission = 1
            pe3.Size = NumberSequence.new{NumberSequenceKeypoint.new(0, 5), NumberSequenceKeypoint.new(1, 0)}
            pe3.Lifetime = NumberRange.new(0.15, 0.4)
            pe3.Rate = 180
            pe3.Speed = NumberRange.new(50, 80)
            pe3.SpreadAngle = Vector2.new(180, 180)
            return {pe1, pe2, pe3}
        end,
    },

    -- 5. OMBRE NOIRE : fumée sombre, spirale maléfique, orbe noir
    OmbreNoire = {
        build = function(attachment, root)
            local pe1 = Instance.new("ParticleEmitter", attachment)
            pe1.Texture = "rbxassetid://297658536"
            pe1.Color = ColorSequence.new{
                ColorSequenceKeypoint.new(0, Color3.fromRGB(40, 0, 60)),
                ColorSequenceKeypoint.new(0.5, Color3.fromRGB(80, 0, 100)),
                ColorSequenceKeypoint.new(1, Color3.fromRGB(20, 0, 30)),
            }
            pe1.LightEmission = 0.5
            pe1.Size = NumberSequence.new{NumberSequenceKeypoint.new(0, 12), NumberSequenceKeypoint.new(0.5, 7), NumberSequenceKeypoint.new(1, 0)}
            pe1.Transparency = NumberSequence.new{NumberSequenceKeypoint.new(0, 0.1), NumberSequenceKeypoint.new(1, 1)}
            pe1.Lifetime = NumberRange.new(2.5, 4)
            pe1.Rate = 100
            pe1.Speed = NumberRange.new(0, 4)
            pe1.SpreadAngle = Vector2.new(360, 360)
            pe1.RotSpeed = NumberRange.new(-20, 20)
            -- Volutes sombres
            local pe2 = Instance.new("ParticleEmitter", attachment)
            pe2.Texture = "rbxassetid://241353019"
            pe2.Color = ColorSequence.new(Color3.fromRGB(100, 0, 140))
            pe2.LightEmission = 0.6
            pe2.Size = NumberSequence.new{NumberSequenceKeypoint.new(0, 2), NumberSequenceKeypoint.new(1, 6)}
            pe2.Transparency = NumberSequence.new{NumberSequenceKeypoint.new(0, 0.2), NumberSequenceKeypoint.new(1, 1)}
            pe2.Lifetime = NumberRange.new(1.5, 2.5)
            pe2.Rate = 70
            pe2.Speed = NumberRange.new(6, 12)
            pe2.SpreadAngle = Vector2.new(180, 180)
            pe2.Acceleration = Vector3.new(0, 5, 0)
            -- Orbe ombre avec darkness
            local orb = Instance.new("Part")
            orb.Size = Vector3.new(3, 3, 3)
            orb.Shape = Enum.PartType.Ball
            orb.Color = Color3.fromRGB(30, 0, 50)
            orb.Material = Enum.Material.Neon
            orb.Anchored = true
            orb.CanCollide = false
            orb.Parent = workspace
            local smoke = Instance.new("Smoke", orb)
            smoke.Color = Color3.fromRGB(60, 0, 80)
            smoke.Opacity = 0.5
            smoke.RiseVelocity = 3
            local ang = 0
            task.spawn(function()
                while orb.Parent and auraEnabled do
                    ang = ang - 0.04  -- sens inverse
                    orb.CFrame = root.CFrame * CFrame.new(math.cos(ang) * 5, math.sin(ang * 0.5) * 3 + 1, math.sin(ang) * 5)
                    RunService.RenderStepped:Wait()
                end
                if orb.Parent then orb:Destroy() end
            end)
            return {pe1, pe2, orb, smoke}
        end,
    },

    -- 6. ARC-EN-CIEL : couleurs cycliques, explosion de confettis, effet prismatique
    ArcEnCiel = {
        build = function(attachment, root)
            local pe1 = Instance.new("ParticleEmitter", attachment)
            pe1.Texture = "rbxassetid://297658536"
            pe1.Color = ColorSequence.new(Color3.fromRGB(255, 100, 200))
            pe1.LightEmission = 1
            pe1.Size = NumberSequence.new{NumberSequenceKeypoint.new(0, 9), NumberSequenceKeypoint.new(0.5, 5), NumberSequenceKeypoint.new(1, 0)}
            pe1.Lifetime = NumberRange.new(1.5, 2.2)
            pe1.Rate = 160
            pe1.Speed = NumberRange.new(0, 2)
            pe1.SpreadAngle = Vector2.new(360, 360)
            local pe2 = Instance.new("ParticleEmitter", attachment)
            pe2.Texture = "rbxassetid://243098098"
            pe2.Color = ColorSequence.new(Color3.fromRGB(100, 255, 200))
            pe2.LightEmission = 1
            pe2.Size = NumberSequence.new{NumberSequenceKeypoint.new(0, 0.6), NumberSequenceKeypoint.new(0.5, 1), NumberSequenceKeypoint.new(1, 0)}
            pe2.Lifetime = NumberRange.new(0.8, 1.5)
            pe2.Rate = 250
            pe2.Speed = NumberRange.new(18, 32)
            pe2.SpreadAngle = Vector2.new(360, 360)
            -- Bandes de couleurs arc-en-ciel
            local pe3 = Instance.new("ParticleEmitter", attachment)
            pe3.Texture = "rbxassetid://241353019"
            pe3.Color = ColorSequence.new(Color3.fromRGB(100, 200, 255))
            pe3.LightEmission = 0.8
            pe3.Size = NumberSequence.new{NumberSequenceKeypoint.new(0, 3), NumberSequenceKeypoint.new(1, 0)}
            pe3.Lifetime = NumberRange.new(1, 1.8)
            pe3.Rate = 120
            pe3.Speed = NumberRange.new(8, 16)
            pe3.SpreadAngle = Vector2.new(360, 360)
            -- Animation couleurs cycliques
            rainbowConn = RunService.RenderStepped:Connect(function()
                local h = (tick() * 0.35) % 1
                local c1 = Color3.fromHSV(h, 1, 1)
                local c2 = Color3.fromHSV((h + 0.33) % 1, 1, 1)
                local c3 = Color3.fromHSV((h + 0.66) % 1, 1, 1)
                pe1.Color = ColorSequence.new(c1)
                pe2.Color = ColorSequence.new(c2)
                pe3.Color = ColorSequence.new(c3)
            end)
            return {pe1, pe2, pe3}
        end,
    },
}

local function clearAura()
    for _, e in ipairs(auraEmitters) do
        if e and e.Parent then
            pcall(function() e:Destroy() end)
        end
    end
    auraEmitters = {}
    if rainbowConn then rainbowConn:Disconnect() rainbowConn = nil end
end

local function toggleAura(state, styleName)
    auraEnabled = state
    clearAura()
    if not state then
        if auraAttachment then auraAttachment:Destroy() auraAttachment = nil end
        return
    end

    local char = localPlayer.Character
    if not char or not char:FindFirstChild("HumanoidRootPart") then return end
    local root = char.HumanoidRootPart

    styleName = styleName or currentAuraStyle
    currentAuraStyle = styleName

    if auraAttachment then auraAttachment:Destroy() end
    auraAttachment = Instance.new("Attachment", root)

    local styleData = auraStyles[styleName]
    if not styleData then styleData = auraStyles["Cosmique"] end

    local objs = styleData.build(auraAttachment, root)
    for _, obj in ipairs(objs) do
        table.insert(auraEmitters, obj)
    end
end

-- ==================== ADMIN TITLE ====================
local function toggleAdminTitle(state)
    adminTitleEnabled = state
    local char = localPlayer.Character
    if not char or not char:FindFirstChild("Head") then return end

    if state then
        if adminTitleBb then adminTitleBb:Destroy() end
        adminTitleBb = Instance.new("BillboardGui")
        adminTitleBb.Size = UDim2.new(0, 130, 0, 40)
        adminTitleBb.StudsOffset = Vector3.new(0, 4, 0)
        adminTitleBb.AlwaysOnTop = true
        adminTitleBb.Adornee = char.Head
        adminTitleBb.Parent = char.Head

        local badge = Instance.new("Frame")
        badge.Size = UDim2.new(1, 0, 1, 0)
        badge.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
        badge.BackgroundTransparency = 0.2
        badge.Parent = adminTitleBb
        makeCorner(badge, 6)
        makeStroke(badge, CONFIG.Accent, 1.5)

        local lbl = Instance.new("TextLabel")
        lbl.Size = UDim2.new(1, 0, 1, 0)
        lbl.BackgroundTransparency = 1
        lbl.Text = "⚡ ADMIN"
        lbl.TextColor3 = CONFIG.Accent
        lbl.Font = Enum.Font.GothamBlack
        lbl.TextSize = 17
        lbl.Parent = badge
    else
        if adminTitleBb then adminTitleBb:Destroy() adminTitleBb = nil end
    end
end

-- ==================== ADMIN CHAT ====================
local function sendAdminChat(msg)
    local char = localPlayer.Character
    if char and char:FindFirstChild("Head") then
        local bb = Instance.new("BillboardGui")
        bb.Size = UDim2.new(0, 320, 0, 50)
        bb.StudsOffset = Vector3.new(0, 7, 0)
        bb.AlwaysOnTop = true
        bb.Adornee = char.Head
        bb.Parent = char.Head

        local bg2 = Instance.new("Frame")
        bg2.Size = UDim2.new(1, 0, 1, 0)
        bg2.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
        bg2.BackgroundTransparency = 0.18
        bg2.Parent = bb
        makeCorner(bg2, 8)
        makeStroke(bg2, CONFIG.Accent, 1)

        local lbl = Instance.new("TextLabel")
        lbl.Size = UDim2.new(1, -8, 1, 0)
        lbl.Position = UDim2.new(0, 4, 0, 0)
        lbl.BackgroundTransparency = 1
        lbl.Text = "⚡ [ADMIN] " .. localPlayer.Name .. " : " .. msg
        lbl.TextColor3 = Color3.new(1, 1, 1)
        lbl.Font = Enum.Font.GothamBold
        lbl.TextSize = 13
        lbl.TextWrapped = true
        lbl.Parent = bg2

        task.delay(5, function() bb:Destroy() end)
    end
    pcall(function()
        local fullMsg = "[ADMIN] " .. localPlayer.Name .. " : " .. msg
        game:GetService("ReplicatedStorage").DefaultChatSystemChatEvents.SayMessageRequest:FireServer(fullMsg, "All")
    end)
end

-- ==================== ESP (grand + distance infinie) ====================
local function toggleESP(state)
    espEnabled = state
    if state then
        for _, plr in Players:GetPlayers() do
            if plr ~= localPlayer and plr.Character then
                local hl = Instance.new("Highlight")
                hl.FillColor = Color3.fromRGB(255, 40, 130)
                hl.OutlineColor = CONFIG.Accent
                hl.FillTransparency = 0.4
                hl.OutlineTransparency = 0
                hl.Adornee = plr.Character
                hl.Parent = plr.Character
                highlights[plr] = hl

                -- Billboard plus grand, distance infinie
                local bb = Instance.new("BillboardGui")
                bb.Adornee = plr.Character:FindFirstChild("Head") or plr.Character.PrimaryPart
                bb.Size = UDim2.new(0, 320, 0, 120)  -- plus grand
                bb.StudsOffset = Vector3.new(0, 7, 0)
                bb.AlwaysOnTop = true
                bb.MaxDistance = 1e9
                bb.Parent = plr.Character:FindFirstChild("Head") or plr.Character

                local bg2 = Instance.new("Frame")
                bg2.Size = UDim2.new(1, 0, 1, 0)
                bg2.BackgroundColor3 = Color3.new(0, 0, 0)
                bg2.BackgroundTransparency = 0.28
                bg2.Parent = bb
                makeCorner(bg2, 10)
                makeStroke(bg2, CONFIG.Accent, 1.5)

                -- Accent bar gauche
                local accentBar = Instance.new("Frame")
                accentBar.Size = UDim2.new(0, 3, 1, -8)
                accentBar.Position = UDim2.new(0, 4, 0, 4)
                accentBar.BackgroundColor3 = CONFIG.Accent
                accentBar.BorderSizePixel = 0
                accentBar.Parent = bg2
                makeCorner(accentBar, 2)

                local txt = Instance.new("TextLabel")
                txt.Size = UDim2.new(1, -18, 1, 0)
                txt.Position = UDim2.new(0, 14, 0, 0)
                txt.BackgroundTransparency = 1
                txt.TextColor3 = Color3.new(1, 1, 1)
                txt.Font = Enum.Font.GothamBold
                txt.TextSize = 14
                txt.TextWrapped = true
                txt.TextXAlignment = Enum.TextXAlignment.Left
                txt.Parent = bg2
                bb.InfoLabel = txt
                infoBillboards[plr] = bb
            end
        end

        espUpdateConnection = RunService.Heartbeat:Connect(function()
            for plr, bb in pairs(infoBillboards) do
                local lp = localPlayer.Character
                local pp = plr.Character
                if pp and pp:FindFirstChild("HumanoidRootPart") and lp and lp:FindFirstChild("HumanoidRootPart") then
                    local dist = (pp.HumanoidRootPart.Position - lp.HumanoidRootPart.Position).Magnitude
                    local hp, maxHp = 0, 100
                    if pp:FindFirstChild("Humanoid") then
                        hp = math.floor(pp.Humanoid.Health)
                        maxHp = math.max(pp.Humanoid.MaxHealth, 1)
                    end
                    local hpPct = math.floor(hp / maxHp * 100)
                    local tool = "Aucun"
                    for _, v in ipairs(pp:GetChildren()) do
                        if v:IsA("Tool") then tool = v.Name break end
                    end
                    local hpColor = hpPct > 60 and "🟢" or (hpPct > 30 and "🟡" or "🔴")
                    bb.InfoLabel.Text = string.format(
                        "👤  %s\n%s  HP: %d/%d (%d%%)\n📏  Distance: %.0f studs\n🛠  Item: %s",
                        plr.Name, hpColor, hp, maxHp, hpPct, dist, tool
                    )
                end
            end
        end)
    else
        for _, v in pairs(highlights) do v:Destroy() end highlights = {}
        for _, v in pairs(infoBillboards) do v:Destroy() end infoBillboards = {}
        if espUpdateConnection then espUpdateConnection:Disconnect() espUpdateConnection = nil end
    end
end

-- ==================== FLY / NOCLIP / GOD / INFJUMP ====================
local function toggleFly(state)
    flyEnabled = state
    local char = localPlayer.Character
    if not char or not char:FindFirstChild("HumanoidRootPart") then return end
    local root = char.HumanoidRootPart
    if state then
        if flyBodyVelocity then flyBodyVelocity:Destroy() end
        flyBodyVelocity = Instance.new("BodyVelocity")
        flyBodyVelocity.MaxForce = Vector3.new(math.huge, math.huge, math.huge)
        flyBodyVelocity.Parent = root
        char.Humanoid.PlatformStand = true
        movementConnection = RunService.RenderStepped:Connect(function()
            if not flyEnabled then return end
            local cam = workspace.CurrentCamera
            local dir = Vector3.new()
            if UserInputService:IsKeyDown(Enum.KeyCode.W) then dir = dir + cam.CFrame.LookVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.S) then dir = dir - cam.CFrame.LookVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.A) then dir = dir - cam.CFrame.RightVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.D) then dir = dir + cam.CFrame.RightVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.Space) then dir = dir + Vector3.new(0,1,0) end
            if UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) then dir = dir - Vector3.new(0,1,0) end
            flyBodyVelocity.Velocity = dir * flySpeed
        end)
    else
        if flyBodyVelocity then flyBodyVelocity:Destroy() flyBodyVelocity = nil end
        if movementConnection then movementConnection:Disconnect() movementConnection = nil end
        if char.Humanoid then char.Humanoid.PlatformStand = false end
    end
end

local function toggleNoclip(state)
    noclipEnabled = state
    local char = localPlayer.Character
    if not char then return end
    if state then
        noclipConnection = RunService.Stepped:Connect(function()
            if not noclipEnabled then return end
            for _, part in ipairs(char:GetDescendants()) do
                if part:IsA("BasePart") then part.CanCollide = false end
            end
        end)
    else
        if noclipConnection then noclipConnection:Disconnect() noclipConnection = nil end
    end
end

local function toggleGod(state)
    godEnabled = state
    local char = localPlayer.Character
    if not char or not char:FindFirstChild("Humanoid") then return end
    if state then
        char.Humanoid.MaxHealth = math.huge
        char.Humanoid.Health = math.huge
    else
        char.Humanoid.MaxHealth = 100
        char.Humanoid.Health = 100
    end
end

local function toggleInfJump(state)
    infJumpEnabled = state
    if state then
        infJumpConnection = UserInputService.JumpRequest:Connect(function()
            if infJumpEnabled and localPlayer.Character and localPlayer.Character:FindFirstChild("Humanoid") then
                localPlayer.Character.Humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
            end
        end)
    else
        if infJumpConnection then infJumpConnection:Disconnect() end
    end
end

-- ==================== MONDE ====================
local function toggleFullBright(state)
    fullBrightEnabled = state
    if state then
        Lighting.Brightness = 10
        Lighting.Ambient = Color3.new(1,1,1)
        Lighting.GlobalShadows = false
    else
        for k,v in pairs(originalLighting) do Lighting[k] = v end
    end
end

local function toggleNoFog(state)
    noFogEnabled = state
    Lighting.FogEnd = state and 100000 or originalLighting.FogEnd
end

local function toggleRain(state)
    rainEnabled = state
    if state then
        if rainEmitter then rainEmitter:Destroy() end
        local att = Instance.new("Attachment", workspace.CurrentCamera)
        rainEmitter = Instance.new("ParticleEmitter", att)
        rainEmitter.Texture = "rbxassetid://241353019"
        rainEmitter.Color = ColorSequence.new(Color3.fromRGB(180, 220, 255))
        rainEmitter.Rate = 300
        rainEmitter.Lifetime = NumberRange.new(3,6)
        rainEmitter.Speed = NumberRange.new(80,120)
        rainEmitter.Acceleration = Vector3.new(0,-50,0)
    else
        if rainEmitter then rainEmitter:Destroy() end
    end
end

-- ==================== EFFETS TROLL ====================
local function toggleColorInvert(state)
    colorInvertEnabled = state
    if state then
        if not invertEffect then invertEffect = Instance.new("ColorCorrectionEffect", Lighting) end
        invertEffect.Saturation = -1
        invertEffect.Contrast = 0.3
    else
        if invertEffect then invertEffect.Saturation=0 invertEffect.Contrast=0 end
    end
end

-- ==================== ÉVÉNEMENTS ====================
local function triggerApocalypse()
    for i=1,30 do
        local lava=Instance.new("Part")
        lava.Size=Vector3.new(math.random(20,60),8,math.random(20,60))
        lava.Color=Color3.fromRGB(255,80,0) lava.Material=Enum.Material.Neon
        lava.Position=localPlayer.Character.HumanoidRootPart.Position+Vector3.new(math.random(-200,200),100,math.random(-200,200))
        lava.Anchored=false lava.Parent=workspace
        tween(lava,{Position=lava.Position-Vector3.new(0,200,0)},8)
        task.delay(10,function() lava:Destroy() end)
    end
end
local function triggerTornado()
    local center=localPlayer.Character.HumanoidRootPart.Position
    for i=1,25 do
        local d=Instance.new("Part") d.Size=Vector3.new(4,4,4) d.Color=Color3.fromRGB(120,120,120)
        d.Position=center+Vector3.new(math.random(-80,80),math.random(10,80),math.random(-80,80))
        d.Anchored=false d.Parent=workspace
        task.spawn(function()
            for _=1,80 do
                d.CFrame=d.CFrame*CFrame.Angles(0,0.3,0)
                d.Position=d.Position+Vector3.new(0,1,0)
                RunService.RenderStepped:Wait()
            end
            d:Destroy()
        end)
    end
end
local function triggerTsunami()
    for i=1,20 do
        local w=Instance.new("Part")
        w.Size=Vector3.new(300,8,40) w.Color=Color3.fromRGB(0,100,255)
        w.Material=Enum.Material.ForceField
        w.Position=localPlayer.Character.HumanoidRootPart.Position+Vector3.new(math.random(-150,150),5,math.random(-200,200))
        w.Anchored=false w.Parent=workspace
        tween(w,{Position=w.Position+Vector3.new(0,-30,0)},6)
        task.delay(8,function() w:Destroy() end)
    end
end
local function triggerLavaRise()
    for i=1,15 do
        local l=Instance.new("Part")
        l.Size=Vector3.new(60,12,60) l.Color=Color3.fromRGB(255,80,0)
        l.Material=Enum.Material.Neon
        l.Position=localPlayer.Character.HumanoidRootPart.Position+Vector3.new(math.random(-120,120),-20,math.random(-120,120))
        l.Anchored=true l.Parent=workspace
        tween(l,{Position=l.Position+Vector3.new(0,40,0)},10)
        task.delay(12,function() l:Destroy() end)
    end
end
local function triggerExplosions()
    for i=1,12 do
        task.delay(math.random()*3,function()
            local e=Instance.new("Part")
            e.Size=Vector3.new(15,15,15) e.Color=Color3.fromRGB(255,150,0)
            e.Material=Enum.Material.Neon
            e.Position=localPlayer.Character.HumanoidRootPart.Position+Vector3.new(math.random(-150,150),math.random(10,80),math.random(-150,150))
            e.Parent=workspace
            tween(e,{Size=Vector3.new(0,0,0)},1.5)
            task.delay(2,function() e:Destroy() end)
        end)
    end
end

-- ==================== SCANNER ====================
local function scanItems()
    local items = {}
    for _, obj in ipairs(workspace:GetDescendants()) do
        if obj:IsA("Tool") or obj:IsA("Model") or obj:IsA("Part") then
            if not table.find(items, obj.Name) and obj.Name ~= "" and obj.Name ~= "Baseplate" and obj.Name ~= "Terrain" then
                table.insert(items, obj.Name)
                if #items >= 80 then break end
            end
        end
    end
    pcall(function()
        for _, obj in ipairs(game:GetService("ReplicatedStorage"):GetDescendants()) do
            if obj:IsA("Tool") and not table.find(items, obj.Name) then
                table.insert(items, obj.Name)
            end
        end
    end)
    return items
end

local function scanEvents()
    local events = {}
    for _, obj in ipairs(game:GetDescendants()) do
        if obj:IsA("RemoteEvent") or obj:IsA("BindableEvent") then
            if not table.find(events, obj.Name) then
                table.insert(events, {name=obj.Name, ref=obj})
                if #events >= 60 then break end
            end
        end
    end
    return events
end

-- ==================== VÉHICULE ====================
local function detectVehicle()
    local char = localPlayer.Character
    if not char then return nil end
    local humanoid = char:FindFirstChild("Humanoid")
    if humanoid and humanoid.SeatPart then return humanoid.SeatPart end
    return nil
end

local function setVehicleSpeed(val)
    local seat = detectVehicle()
    if seat and seat:IsA("VehicleSeat") then seat.MaxSpeed = val end
end

local function setVehicleHealth(val)
    local char = localPlayer.Character
    if not char then return end
    local humanoid = char:FindFirstChild("Humanoid")
    if humanoid and humanoid.SeatPart then
        local vehicle = humanoid.SeatPart.Parent
        local vh = vehicle:FindFirstChildWhichIsA("Humanoid")
        if vh then vh.Health = val end
    end
end

-- ==================== ADMIN CHARACTER ====================
local function giveAdminPowers(char)
    local backpack = localPlayer.Backpack
    local fireballTool = Instance.new("Tool")
    fireballTool.Name = "Fireball (52 dmg)"
    fireballTool.RequiresHandle = false
    fireballTool.Parent = backpack
    fireballTool.Activated:Connect(function()
        local root = char.HumanoidRootPart
        local ball = Instance.new("Part")
        ball.Size = Vector3.new(4,4,4) ball.Shape = Enum.PartType.Ball
        ball.Color = Color3.fromRGB(255,100,0) ball.Material = Enum.Material.Neon
        ball.CFrame = root.CFrame * CFrame.new(0,0,-8)
        ball.Velocity = root.CFrame.LookVector * 120
        ball.Parent = workspace
        Instance.new("Fire", ball).Heat = 8
        ball.Touched:Connect(function(hit)
            local hum = hit.Parent:FindFirstChild("Humanoid")
            if hum and hit.Parent ~= char then hum:TakeDamage(52) ball:Destroy() end
        end)
        task.delay(3, function() if ball.Parent then ball:Destroy() end end)
    end)
    toggleAura(true, "ArcEnCiel")
end

localPlayer.CharacterAdded:Connect(function(char)
    task.wait(1.5)
    if adminCharacterMode == "Admin" then
        giveAdminPowers(char)
        adminCharacterMode = nil
    end
    if char:FindFirstChild("Humanoid") then
        char.Humanoid.WalkSpeed = walkSpeed
        char.Humanoid.JumpPower = jumpPower
    end
end)

-- ==================== LOAD CATEGORY ====================
local function loadCategory(cat)
    for _, c in ipairs(contentFrame:GetChildren()) do
        if c:IsA("GuiObject") then c:Destroy() end
    end

    if cat == "Mouvement" then
        makeSectionLabel(contentFrame, "PERSONNAGE")
        createSlider(contentFrame, "Vitesse de marche", 0, 10000, walkSpeed, function(v)
            walkSpeed = v
            local c = localPlayer.Character
            if c and c:FindFirstChild("Humanoid") then c.Humanoid.WalkSpeed = v end
        end)
        createSlider(contentFrame, "Puissance de saut", 0, 10000, jumpPower, function(v)
            jumpPower = v
            local c = localPlayer.Character
            if c and c:FindFirstChild("Humanoid") then c.Humanoid.JumpPower = v end
        end)
        createSlider(contentFrame, "Vitesse de vol", 0, 10000, flySpeed, function(v) flySpeed = v end)
        makeDivider(contentFrame)
        makeSectionLabel(contentFrame, "CAPACITÉS")
        createToggle(contentFrame, "Voler", "WASD + Espace/Ctrl", flyEnabled, toggleFly)
        createToggle(contentFrame, "Noclip", "Traverser les murs", noclipEnabled, toggleNoclip)
        createToggle(contentFrame, "Saut infini", nil, infJumpEnabled, toggleInfJump)

    elseif cat == "Véhicule" then
        makeSectionLabel(contentFrame, "DÉTECTION")
        local detectCard = makeCard(contentFrame, 54)
        local detectLbl = Instance.new("TextLabel")
        detectLbl.Size = UDim2.new(1, -120, 1, 0)
        detectLbl.Position = UDim2.new(0, 14, 0, 0)
        detectLbl.BackgroundTransparency = 1
        detectLbl.Text = "Véhicule : Aucun détecté"
        detectLbl.TextColor3 = CONFIG.TextMuted
        detectLbl.TextXAlignment = Enum.TextXAlignment.Left
        detectLbl.Font = Enum.Font.GothamBold
        detectLbl.TextSize = 13
        detectLbl.Parent = detectCard
        local detectBtn = Instance.new("TextButton")
        detectBtn.Size = UDim2.new(0, 100, 0, 36)
        detectBtn.Position = UDim2.new(1, -110, 0.5, -18)
        detectBtn.BackgroundColor3 = CONFIG.Accent
        detectBtn.Text = "SCANNER"
        detectBtn.TextColor3 = Color3.fromRGB(5, 20, 15)
        detectBtn.Font = Enum.Font.GothamBlack
        detectBtn.TextSize = 12
        detectBtn.Parent = detectCard
        makeCorner(detectBtn, 8)
        detectBtn.MouseButton1Click:Connect(function()
            local seat = detectVehicle()
            if seat then
                detectLbl.Text = "Véhicule : " .. seat.Parent.Name
                detectLbl.TextColor3 = CONFIG.Accent
            else
                detectLbl.Text = "Aucun véhicule détecté"
                detectLbl.TextColor3 = CONFIG.Danger
            end
        end)
        makeDivider(contentFrame)
        makeSectionLabel(contentFrame, "CONTRÔLE VÉHICULE")
        createSlider(contentFrame, "Vitesse max véhicule", 0, 1000, 100, setVehicleSpeed)
        createSlider(contentFrame, "Vie véhicule (HP)", 0, 10000, 100, setVehicleHealth)
        createButton(contentFrame, "🔧  Réparer le véhicule", nil, function()
            local char = localPlayer.Character
            if char and char:FindFirstChild("Humanoid") and char.Humanoid.SeatPart then
                local v = char.Humanoid.SeatPart.Parent
                local vh = v:FindFirstChildWhichIsA("Humanoid")
                if vh then vh.Health = vh.MaxHealth end
            end
        end)

    elseif cat == "Visuels" then
        makeSectionLabel(contentFrame, "DÉTECTION JOUEURS")
        createToggle(contentFrame, "ESP Avancé", "Infini + HP + Distance + Item", espEnabled, toggleESP)

    elseif cat == "Joueur" then
        makeSectionLabel(contentFrame, "SURVIE")
        createToggle(contentFrame, "Mode Dieu", "HP infini", godEnabled, toggleGod)
        makeDivider(contentFrame)
        createButton(contentFrame, "💀  Se tuer", CONFIG.Danger, function()
            local char = localPlayer.Character
            if char and char:FindFirstChild("Humanoid") then char.Humanoid.Health = 0 end
        end)

    elseif cat == "Monde" then
        makeSectionLabel(contentFrame, "ÉCLAIRAGE")
        createToggle(contentFrame, "Plein jour", nil, fullBrightEnabled, toggleFullBright)
        createToggle(contentFrame, "Sans brouillard", nil, noFogEnabled, toggleNoFog)
        createSlider(contentFrame, "Heure (0-24)", 0, 24, Lighting.ClockTime, function(v) Lighting.ClockTime = v end)
        makeDivider(contentFrame)
        makeSectionLabel(contentFrame, "MÉTÉO")
        createToggle(contentFrame, "Pluie", nil, rainEnabled, toggleRain)

    elseif cat == "Fun" then
        makeSectionLabel(contentFrame, "AURA")
        createToggle(contentFrame, "Aura active", nil, auraEnabled, function(s)
            toggleAura(s, currentAuraStyle)
        end)
        makeDivider(contentFrame)
        makeSectionLabel(contentFrame, "STYLE D'AURA (6 uniques)")
        local auraDescriptions = {
            Cosmique     = "💜  Cosmique — Orbe orbital + étoiles",
            FeuInfernal  = "🔥  Feu Infernal — Flammes + braises + orbe",
            GlaceArctique= "❄️  Glace Arctique — Cristaux + givre",
            Electrique   = "⚡  Électrique — Éclairs + étincelles",
            OmbreNoire   = "🖤  Ombre Noire — Fumée + spirale + smoke",
            ArcEnCiel    = "🌈  Arc-en-Ciel — Couleurs cycliques",
        }
        for styleName, desc in pairs(auraDescriptions) do
            local n = styleName
            createButton(contentFrame, desc, nil, function()
                currentAuraStyle = n
                if auraEnabled then toggleAura(true, n) end
            end)
        end

    elseif cat == "Événements" then
        makeSectionLabel(contentFrame, "CATASTROPHES")
        createButton(contentFrame, "🌋  Apocalypse Lave", nil, triggerApocalypse)
        createButton(contentFrame, "🌪️  Tornade", nil, triggerTornado)
        createButton(contentFrame, "🌊  Tsunami", nil, triggerTsunami)
        createButton(contentFrame, "🔥  Montée de Lave", nil, triggerLavaRise)
        createButton(contentFrame, "💥  Explosions", nil, triggerExplosions)

    elseif cat == "Troll" then
        makeSectionLabel(contentFrame, "ADMIN CHAT")
        local chatInfo = makeCard(contentFrame, 48)
        local chatInfoLbl = Instance.new("TextLabel")
        chatInfoLbl.Size = UDim2.new(1, -16, 1, 0)
        chatInfoLbl.Position = UDim2.new(0, 8, 0, 0)
        chatInfoLbl.BackgroundTransparency = 1
        chatInfoLbl.Text = "Envoie avec le tag ⚡ [ADMIN] Nom :"
        chatInfoLbl.TextColor3 = CONFIG.TextMuted
        chatInfoLbl.Font = Enum.Font.Gotham
        chatInfoLbl.TextSize = 13
        chatInfoLbl.TextWrapped = true
        chatInfoLbl.Parent = chatInfo
        createTextInput(contentFrame, "Ton message admin...", sendAdminChat)
        makeDivider(contentFrame)
        makeSectionLabel(contentFrame, "TITRE ADMIN")
        createToggle(contentFrame, "Titre ADMIN au-dessus", "Badge ⚡ ADMIN visible par tous", adminTitleEnabled, toggleAdminTitle)
        makeDivider(contentFrame)
        makeSectionLabel(contentFrame, "EFFETS")
        createToggle(contentFrame, "Inverser les couleurs", nil, colorInvertEnabled, toggleColorInvert)

    elseif cat == "Scanner" then
        makeSectionLabel(contentFrame, "ITEMS DU JEU")
        createButton(contentFrame, "🔍  Scanner les items", nil, function()
            for _, c in ipairs(contentFrame:GetChildren()) do
                if c:IsA("GuiObject") then c:Destroy() end
            end
            makeSectionLabel(contentFrame, "ITEMS TROUVÉS")
            local items = scanItems()
            if #items == 0 then
                local noItem = makeCard(contentFrame, 42)
                local l = Instance.new("TextLabel")
                l.Size = UDim2.new(1, -16, 1, 0)
                l.Position = UDim2.new(0, 8, 0, 0)
                l.BackgroundTransparency = 1
                l.Text = "Aucun item trouvé."
                l.TextColor3 = CONFIG.TextMuted
                l.Font = Enum.Font.Gotham
                l.TextSize = 13
                l.Parent = noItem
            else
                for _, name in ipairs(items) do
                    local itemCard = makeCard(contentFrame, 42)
                    local lbl = Instance.new("TextLabel")
                    lbl.Size = UDim2.new(0.7, 0, 1, 0)
                    lbl.Position = UDim2.new(0, 10, 0, 0)
                    lbl.BackgroundTransparency = 1
                    lbl.Text = "📦 " .. name
                    lbl.TextColor3 = CONFIG.Text
                    lbl.TextXAlignment = Enum.TextXAlignment.Left
                    lbl.Font = Enum.Font.GothamBold
                    lbl.TextSize = 13
                    lbl.Parent = itemCard
                    local goBtn = Instance.new("TextButton")
                    goBtn.Size = UDim2.new(0, 70, 0, 28)
                    goBtn.Position = UDim2.new(1, -76, 0.5, -14)
                    goBtn.BackgroundColor3 = CONFIG.Accent
                    goBtn.Text = "TP"
                    goBtn.TextColor3 = Color3.fromRGB(5, 20, 15)
                    goBtn.Font = Enum.Font.GothamBlack
                    goBtn.TextSize = 12
                    goBtn.Parent = itemCard
                    makeCorner(goBtn, 6)
                    local n = name
                    goBtn.MouseButton1Click:Connect(function()
                        local target = workspace:FindFirstChild(n, true)
                        if target and target:IsA("BasePart") then
                            local char = localPlayer.Character
                            if char and char:FindFirstChild("HumanoidRootPart") then
                                char.HumanoidRootPart.CFrame = target.CFrame + Vector3.new(0, 5, 0)
                            end
                        end
                    end)
                end
            end
            makeDivider(contentFrame)
            makeSectionLabel(contentFrame, "ÉVÉNEMENTS DU JEU")
            local events = scanEvents()
            for _, ev in ipairs(events) do
                local evCard = makeCard(contentFrame, 42)
                local lbl = Instance.new("TextLabel")
                lbl.Size = UDim2.new(0.65, 0, 1, 0)
                lbl.Position = UDim2.new(0, 10, 0, 0)
                lbl.BackgroundTransparency = 1
                lbl.Text = "⚡ " .. ev.name
                lbl.TextColor3 = CONFIG.Text
                lbl.TextXAlignment = Enum.TextXAlignment.Left
                lbl.Font = Enum.Font.GothamBold
                lbl.TextSize = 12
                lbl.TextTruncate = Enum.TextTruncate.AtEnd
                lbl.Parent = evCard
                local fireBtn = Instance.new("TextButton")
                fireBtn.Size = UDim2.new(0, 70, 0, 28)
                fireBtn.Position = UDim2.new(1, -76, 0.5, -14)
                fireBtn.BackgroundColor3 = Color3.fromRGB(45, 15, 75)
                fireBtn.Text = "FIRE"
                fireBtn.TextColor3 = Color3.fromRGB(200, 160, 255)
                fireBtn.Font = Enum.Font.GothamBlack
                fireBtn.TextSize = 12
                fireBtn.Parent = evCard
                makeCorner(fireBtn, 6)
                local ref = ev.ref
                fireBtn.MouseButton1Click:Connect(function()
                    pcall(function()
                        if ref:IsA("BindableEvent") then ref:Fire()
                        elseif ref:IsA("RemoteEvent") then ref:FireServer() end
                    end)
                end)
            end
        end)

        local hintCard = makeCard(contentFrame, 56)
        local hint = Instance.new("TextLabel")
        hint.Size = UDim2.new(1, -16, 1, 0)
        hint.Position = UDim2.new(0, 8, 0, 0)
        hint.BackgroundTransparency = 1
        hint.Text = "Clique sur « Scanner les items » pour analyser le jeu actuel."
        hint.TextColor3 = CONFIG.TextMuted
        hint.Font = Enum.Font.Gotham
        hint.TextSize = 13
        hint.TextWrapped = true
        hint.Parent = hintCard

    elseif cat == "Admin Char" then
        makeSectionLabel(contentFrame, "ADMIN ULTIME")
        local infoCard = makeCard(contentFrame, 64)
        local t = Instance.new("TextLabel")
        t.Size = UDim2.new(1, -16, 1, 0) t.Position = UDim2.new(0, 8, 0, 0)
        t.BackgroundTransparency = 1
        t.Text = "Recharge ton perso avec aura Arc-en-ciel + Fireball dans le sac."
        t.TextColor3 = CONFIG.TextMuted t.Font = Enum.Font.Gotham t.TextSize = 13 t.TextWrapped = true t.Parent = infoCard
        createButton(contentFrame, "🐉  LANCER ADMIN CHAR", nil, function()
            adminCharacterMode = "Admin"
            localPlayer:LoadCharacter()
        end)

    elseif cat == "Paramètres" then
        makeSectionLabel(contentFrame, "INTERFACE")
        createSlider(contentFrame, "Transparence GUI", 0, 100, 0, function(v)
            mainFrame.BackgroundTransparency = v / 100
        end)
        makeDivider(contentFrame)
        makeSectionLabel(contentFrame, "COULEUR THÈME + GRILLE (SYNC)")
        createSlider(contentFrame, "Teinte (Hue 0-360)", 0, 360, CONFIG.AccentHue, function(v)
            updateGridColor(v)
        end)
        makeDivider(contentFrame)
        makeSectionLabel(contentFrame, "GRILLE DIAGONALE")
        createToggle(contentFrame, "Grille animée", "Diagonale haut-droit → bas-gauche", true, function(s)
            if gridCanvas then gridCanvas.Visible = s end
        end)
    end
end

-- ==================== MINIMIZED ICON ====================
local function createMinimizedIcon()
    if minimizedIcon then return end
    minimizedIcon = Instance.new("TextButton")
    minimizedIcon.Size = UDim2.new(0, 56, 0, 56)
    minimizedIcon.Position = UDim2.new(1, -68, 0, 12)
    minimizedIcon.BackgroundColor3 = CONFIG.BgCard
    minimizedIcon.Text = "v10"
    minimizedIcon.TextColor3 = CONFIG.Accent
    minimizedIcon.TextSize = 17
    minimizedIcon.Font = Enum.Font.GothamBlack
    minimizedIcon.Parent = menuGui
    makeCorner(minimizedIcon, 13)
    makeStroke(minimizedIcon, CONFIG.Accent, 1)
    minimizedIcon.MouseButton1Click:Connect(function()
        minimized = false
        minimizedIcon.Visible = false
        mainFrame.Visible = true
        tween(mainFrame, {Size = CONFIG.MainSize}, 0.38, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
        buildDiagonalGrid(mainFrame)
    end)
end

-- ==================== CRÉATION DU GUI PRINCIPAL ====================
local function createAdminMenu()
    if menuGui then return end

    menuGui = Instance.new("ScreenGui")
    menuGui.ResetOnSpawn = false
    menuGui.Parent = localPlayer.PlayerGui

    mainFrame = Instance.new("Frame")
    mainFrame.Size = UDim2.new(0, 0, 0, 0)
    mainFrame.Position = UDim2.new(0.5, -420, 0.5, -290)
    mainFrame.BackgroundColor3 = CONFIG.BgDark
    mainFrame.Parent = menuGui
    makeCorner(mainFrame, 16)
    makeStroke(mainFrame, CONFIG.Border, 1)

    -- Grille diagonale animée en fond
    buildDiagonalGrid(mainFrame)

    -- Ligne accent haut
    local accentLine = Instance.new("Frame")
    accentLine.Size = UDim2.new(1, 0, 0, 2)
    accentLine.Position = UDim2.new(0, 0, 0, 58)
    accentLine.BackgroundColor3 = CONFIG.Accent
    accentLine.BorderSizePixel = 0
    accentLine.ZIndex = 5
    accentLine.Parent = mainFrame

    -- Top Bar
    local topBar = Instance.new("Frame")
    topBar.Size = UDim2.new(1, 0, 0, 58)
    topBar.BackgroundColor3 = CONFIG.BgSidebar
    topBar.ZIndex = 4
    topBar.Parent = mainFrame
    makeCorner(topBar, 16)
    local topPatch = Instance.new("Frame")
    topPatch.Size = UDim2.new(1, 0, 0.5, 0)
    topPatch.Position = UDim2.new(0, 0, 0.5, 0)
    topPatch.BackgroundColor3 = CONFIG.BgSidebar
    topPatch.BorderSizePixel = 0
    topPatch.ZIndex = 4
    topPatch.Parent = topBar

    local logoBox = Instance.new("Frame")
    logoBox.Size = UDim2.new(0, 36, 0, 36)
    logoBox.Position = UDim2.new(0, 12, 0.5, -18)
    logoBox.BackgroundColor3 = CONFIG.Accent
    logoBox.ZIndex = 6
    logoBox.Parent = topBar
    makeCorner(logoBox, 8)
    local logoLbl = Instance.new("TextLabel")
    logoLbl.Size = UDim2.new(1, 0, 1, 0)
    logoLbl.BackgroundTransparency = 1
    logoLbl.Text = "A"
    logoLbl.TextColor3 = Color3.fromRGB(5, 20, 15)
    logoLbl.Font = Enum.Font.GothamBlack
    logoLbl.TextSize = 20
    logoLbl.ZIndex = 7
    logoLbl.Parent = logoBox

    local titleLbl = Instance.new("TextLabel")
    titleLbl.Size = UDim2.new(0, 200, 0, 22)
    titleLbl.Position = UDim2.new(0, 58, 0, 9)
    titleLbl.BackgroundTransparency = 1
    titleLbl.Text = CONFIG.Title
    titleLbl.TextColor3 = CONFIG.Text
    titleLbl.Font = Enum.Font.GothamBlack
    titleLbl.TextSize = 17
    titleLbl.TextXAlignment = Enum.TextXAlignment.Left
    titleLbl.ZIndex = 6
    titleLbl.Parent = topBar

    local subtitleLbl = Instance.new("TextLabel")
    subtitleLbl.Size = UDim2.new(0, 200, 0, 14)
    subtitleLbl.Position = UDim2.new(0, 58, 0, 33)
    subtitleLbl.BackgroundTransparency = 1
    subtitleLbl.Text = CONFIG.Subtitle
    subtitleLbl.TextColor3 = CONFIG.Accent
    subtitleLbl.Font = Enum.Font.GothamBold
    subtitleLbl.TextSize = 11
    subtitleLbl.TextXAlignment = Enum.TextXAlignment.Left
    subtitleLbl.ZIndex = 6
    subtitleLbl.Parent = topBar

    local function makeTopBtn(text, posX, cb)
        local btn = Instance.new("TextButton")
        btn.Size = UDim2.new(0, 34, 0, 34)
        btn.Position = UDim2.new(1, posX, 0.5, -17)
        btn.BackgroundColor3 = CONFIG.BgCard
        btn.Text = text
        btn.TextColor3 = CONFIG.TextMuted
        btn.Font = Enum.Font.GothamBold
        btn.TextSize = 17
        btn.ZIndex = 6
        btn.Parent = topBar
        makeCorner(btn, 8)
        btn.MouseEnter:Connect(function() tween(btn, {TextColor3 = CONFIG.Text}, 0.1) end)
        btn.MouseLeave:Connect(function() tween(btn, {TextColor3 = CONFIG.TextMuted}, 0.1) end)
        btn.MouseButton1Click:Connect(cb)
    end
    makeTopBtn("✕", -11, function() menuGui.Enabled = false end)
    makeTopBtn("−", -51, function()
        minimized = true
        if gridAnimConn then gridAnimConn:Disconnect() gridAnimConn = nil end
        tween(mainFrame, {Size = UDim2.new(0, 0, 0, 0)}, 0.28, Enum.EasingStyle.Back, Enum.EasingDirection.In)
        task.wait(0.3)
        mainFrame.Visible = false
        createMinimizedIcon()
        minimizedIcon.Visible = true
    end)

    -- Drag
    local dragging, dragStart, startPos = false, nil, nil
    topBar.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = true dragStart = input.Position startPos = mainFrame.Position
        end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
            local d = input.Position - dragStart
            mainFrame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + d.X, startPos.Y.Scale, startPos.Y.Offset + d.Y)
        end
    end)
    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then dragging = false end
    end)

    -- Resize
    local resizeHandle = Instance.new("Frame")
    resizeHandle.Size = UDim2.new(0, 18, 0, 18)
    resizeHandle.Position = UDim2.new(1, -18, 1, -18)
    resizeHandle.BackgroundColor3 = CONFIG.Accent
    resizeHandle.BackgroundTransparency = 0.5
    resizeHandle.Parent = mainFrame
    makeCorner(resizeHandle, 4)
    local resizing = false
    resizeHandle.InputBegan:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 then resizing = true end
    end)
    UserInputService.InputEnded:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 then resizing = false end
    end)
    RunService.RenderStepped:Connect(function()
        if resizing then
            local mp = UserInputService:GetMouseLocation()
            local fp = mainFrame.AbsolutePosition
            local nW = math.clamp(mp.X - fp.X, CONFIG.MinSize.X, CONFIG.MaxSize.X)
            local nH = math.clamp(mp.Y - fp.Y, CONFIG.MinSize.Y, CONFIG.MaxSize.Y)
            mainFrame.Size = UDim2.new(0, nW, 0, nH)
        end
    end)

    -- Sidebar
    sidebar = Instance.new("ScrollingFrame")
    sidebar.Size = UDim2.new(0, 160, 1, -62)
    sidebar.Position = UDim2.new(0, 0, 0, 62)
    sidebar.BackgroundColor3 = CONFIG.BgSidebar
    sidebar.ScrollBarThickness = 0
    sidebar.ZIndex = 3
    sidebar.Parent = mainFrame
    local sidePad = Instance.new("UIPadding")
    sidePad.PaddingTop = UDim.new(0, 10) sidePad.PaddingBottom = UDim.new(0, 10)
    sidePad.PaddingLeft = UDim.new(0, 7) sidePad.PaddingRight = UDim.new(0, 7)
    sidePad.Parent = sidebar
    local sideList = Instance.new("UIListLayout")
    sideList.Padding = UDim.new(0, 3)
    sideList.Parent = sidebar

    local tabs = {
        {name = "Mouvement",  icon = "🚀"},
        {name = "Véhicule",   icon = "🚗"},
        {name = "Visuels",    icon = "👁"},
        {name = "Joueur",     icon = "🧍"},
        {name = "Monde",      icon = "🌍"},
        {name = "Fun",        icon = "✨"},
        {name = "Événements", icon = "🌋"},
        {name = "Troll",      icon = "😈"},
        {name = "Scanner",    icon = "🔍"},
        {name = "Admin Char", icon = "🐉"},
        {name = "Paramètres", icon = "⚙"},
    }

    local sidebarBtns = {}
    for _, tab in ipairs(tabs) do
        local btn = Instance.new("TextButton")
        btn.Size = UDim2.new(1, 0, 0, 44)
        btn.BackgroundTransparency = 1
        btn.Text = tab.icon .. "  " .. tab.name
        btn.TextColor3 = CONFIG.TextMuted
        btn.Font = Enum.Font.GothamSemibold
        btn.TextSize = 13
        btn.TextXAlignment = Enum.TextXAlignment.Left
        btn.ZIndex = 4
        btn.Parent = sidebar
        makeCorner(btn, 8)

        local bar = Instance.new("Frame")
        bar.Size = UDim2.new(0, 3, 0.55, 0)
        bar.Position = UDim2.new(0, 0, 0.225, 0)
        bar.BackgroundColor3 = CONFIG.Accent
        bar.BackgroundTransparency = 1
        bar.ZIndex = 5
        bar.Parent = btn
        makeCorner(bar, 2)

        sidebarBtns[tab.name] = {btn = btn, bar = bar}

        btn.MouseEnter:Connect(function()
            if currentTab ~= tab.name then
                btn.BackgroundColor3 = CONFIG.BgCard
                tween(btn, {BackgroundTransparency = 0.85}, 0.12)
            end
        end)
        btn.MouseLeave:Connect(function()
            if currentTab ~= tab.name then
                tween(btn, {BackgroundTransparency = 1}, 0.12)
            end
        end)
        btn.MouseButton1Click:Connect(function()
            for _, d in pairs(sidebarBtns) do
                tween(d.btn, {BackgroundTransparency = 1, TextColor3 = CONFIG.TextMuted}, 0.14)
                tween(d.bar, {BackgroundTransparency = 1}, 0.14)
            end
            currentTab = tab.name
            btn.BackgroundColor3 = CONFIG.BgCard
            tween(btn, {BackgroundTransparency = 0.8, TextColor3 = CONFIG.Text}, 0.14)
            tween(bar, {BackgroundTransparency = 0}, 0.14)
            loadCategory(tab.name)
        end)
    end

    local first = sidebarBtns["Mouvement"]
    first.btn.BackgroundColor3 = CONFIG.BgCard
    first.btn.BackgroundTransparency = 0.8
    first.btn.TextColor3 = CONFIG.Text
    first.bar.BackgroundTransparency = 0

    local divSide = Instance.new("Frame")
    divSide.Size = UDim2.new(0, 1, 1, -62)
    divSide.Position = UDim2.new(0, 160, 0, 62)
    divSide.BackgroundColor3 = CONFIG.Border
    divSide.BorderSizePixel = 0
    divSide.ZIndex = 3
    divSide.Parent = mainFrame

    contentFrame = Instance.new("ScrollingFrame")
    contentFrame.Size = UDim2.new(1, -172, 1, -74)
    contentFrame.Position = UDim2.new(0, 168, 0, 70)
    contentFrame.BackgroundTransparency = 1
    contentFrame.ScrollBarThickness = 4
    contentFrame.ScrollBarImageColor3 = CONFIG.Accent
    contentFrame.ZIndex = 3
    contentFrame.Parent = mainFrame

    local contPad = Instance.new("UIPadding")
    contPad.PaddingTop = UDim.new(0, 8) contPad.PaddingBottom = UDim.new(0, 20)
    contPad.Parent = contentFrame
    local contList = Instance.new("UIListLayout")
    contList.Padding = UDim.new(0, 7)
    contList.Parent = contentFrame

    loadCategory("Mouvement")

    tween(mainFrame, {Size = CONFIG.MainSize}, 0.44, Enum.EasingStyle.Back, Enum.EasingDirection.Out)

    print("✅ Menu Admin v10 — Grille diagonale + 6 auras uniques + ESP amélioré + Loading ultra stylé")
end

-- ==================== INPUT ====================
UserInputService.InputBegan:Connect(function(input)
    if input.KeyCode == Enum.KeyCode.Insert then
        if menuGui then
            menuGui.Enabled = not menuGui.Enabled
        end
    end
end)

-- ==================== LANCEMENT ====================
showLoadingScreen(function()
    createAdminMenu()
end)