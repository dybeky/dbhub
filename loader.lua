-- DBHUB launcher. It does not contain the hub: it asks the server, and the server checks the key
-- and sends the hub code (and the pictures) only to a valid key.
local API = "https://dbhub-api-production.up.railway.app"   -- address of your server, e.g. "https://dbhub-api.YOURNAME.workers.dev" (see server/README.md)
local KEY_LINK = "https://discord.gg/ka4eFn8VZu"   -- copied by the GET KEY button

local Players = game:GetService("Players")
local HttpService = game:GetService("HttpService")
local player = Players.LocalPlayer
local genv = getgenv()
local DIR, KEYFILE = "DBHub", "DBHub/key.txt"
local SPLIT = "\n--[[DBHUB-SPLIT]]\n"
local httpRequest = (syn and syn.request) or request or http_request or (http and http.request)

local ERR_TEXT = {
    invalid = "Invalid key",
    revoked = "This key was disabled",
    expired = "This key has expired",
    limit = "This key is already used on another account",
    ratelimit = "Too many attempts, try again later",
    network = "Cannot reach the server",
    noapi = "The launcher is not configured yet",
    norequest = "Your executor cannot send web requests",
    server = "Server error, try again later",
}

-- asks the server; returns the hub code (text) or nil + an error code
local function launch(key)
    if API == "" then return nil, "noapi" end
    if not httpRequest then return nil, "norequest" end
    local ok, res = pcall(httpRequest, {
        Url = API .. "/launch", Method = "POST",
        Headers = { ["Content-Type"] = "application/json" },
        Body = HttpService:JSONEncode({
            key = key, userId = player.UserId, placeId = game.PlaceId, gameId = game.GameId,
            hwid = (function()
                local ok, v = pcall(function() return game:GetService("RbxAnalyticsService"):GetClientId() end)
                return ok and tostring(v) or ""
            end)(),
        }),
    })
    if not ok or type(res) ~= "table" then return nil, "network" end
    if res.StatusCode == 200 and type(res.Body) == "string" and #res.Body > 0 then return res.Body end
    local code = "network"
    pcall(function() code = HttpService:JSONDecode(res.Body).error or "invalid" end)
    return nil, code
end
-- falling snow inside a GUI container: small white dots that drift down and start again from the top
local function DBSnow(parent, count, zindex)
    local TS = game:GetService("TweenService")
    for _ = 1, count do
        task.spawn(function()
            pcall(function()
                local f = Instance.new("Frame")
                local size = math.random(3, 7)
                f.Size = UDim2.fromOffset(size, size)
                f.BackgroundColor3 = Color3.new(1, 1, 1)
                f.BorderSizePixel = 0
                f.ZIndex = zindex or 1
                f.Parent = parent
                local c = Instance.new("UICorner"); c.CornerRadius = UDim.new(1, 0); c.Parent = f
                task.wait(math.random() * 4)
                while f.Parent and parent.Parent do
                    local x = math.random()
                    f.Position = UDim2.new(x, 0, 0, -10)
                    f.BackgroundTransparency = 0.2 + math.random() * 0.45
                    local dur = 4 + math.random() * 5
                    local tw = TS:Create(f, TweenInfo.new(dur, Enum.EasingStyle.Linear),
                        { Position = UDim2.new(math.clamp(x + (math.random() - 0.5) * 0.25, 0, 1), 0, 1, 10) })
                    tw:Play()
                    tw.Completed:Wait()
                end
            end)
        end)
    end
end

-- the key window (the same chunky cartoon style as the "game not supported" window);
-- returns the hub code when the server accepted the key, false when the window was closed
local function DBGate()
    local TS = game:GetService("TweenService")
    -- a key saved on a previous run is checked by the server again, every time
    local saved, startMsg = "", nil
    pcall(function() if isfile and isfile(KEYFILE) then saved = readfile(KEYFILE) end end)
    if saved ~= "" then
        local payload, err = launch(saved)
        if payload then return payload end
        if err ~= "invalid" then startMsg = ERR_TEXT[err] end
    end

    local INK = Color3.fromRGB(34, 16, 70)
    local ICE = Color3.fromRGB(248, 243, 255)
    local PINK, VIOLET = Color3.fromRGB(255, 150, 230), Color3.fromRGB(140, 96, 255)
    local GOOD, BAD = Color3.fromRGB(120, 235, 150), Color3.fromRGB(255, 125, 155)

    local gui = Instance.new("ScreenGui")
    gui.Name = "DBHubKey"
    gui.ResetOnSpawn = false
    gui.IgnoreGuiInset = true
    gui.DisplayOrder = 1000
    gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    local okParent = pcall(function() gui.Parent = (gethui and gethui()) or game:GetService("CoreGui") end)
    if not okParent then gui.Parent = player:WaitForChild("PlayerGui") end

    local function tween(o, t, props, style, dir)
        TS:Create(o, TweenInfo.new(t, style or Enum.EasingStyle.Quint, dir or Enum.EasingDirection.Out), props):Play()
    end
    local function corner(o, r) local c = Instance.new("UICorner"); c.CornerRadius = r; c.Parent = o end
    local function outline(o, th, col)
        local s = Instance.new("UIStroke")
        s.Color = col or INK
        s.Thickness = th
        s.LineJoinMode = Enum.LineJoinMode.Round
        s.Parent = o
        return s
    end
    local function text(parent, str, size, y, h, color, font)
        local l = Instance.new("TextLabel")
        l.BackgroundTransparency = 1
        l.Text = str
        l.Font = font or Enum.Font.GothamBold
        l.TextSize = size
        l.TextColor3 = color
        l.TextWrapped = true
        l.AnchorPoint = Vector2.new(0.5, 0)
        l.Position = UDim2.new(0.5, 0, 0, y)
        l.Size = UDim2.new(1, -40, 0, h)
        l.ZIndex = 6
        l.Parent = parent
        return l
    end

    -- the window
    local root = Instance.new("CanvasGroup")
    root.AnchorPoint = Vector2.new(0.5, 0.5)
    root.Position = UDim2.fromScale(0.5, 0.5)
    root.Size = UDim2.fromOffset(450, 372)
    root.BackgroundColor3 = Color3.fromRGB(30, 20, 52)
    root.GroupTransparency = 1
    root.Parent = gui
    corner(root, UDim.new(0, 26))
    local scale = Instance.new("UIScale")
    scale.Scale = 0.92
    scale.Parent = root
    local bg = Instance.new("Frame")
    bg.Size = UDim2.fromScale(1, 1)
    bg.BackgroundColor3 = Color3.new(1, 1, 1)
    bg.BorderSizePixel = 0
    bg.Parent = root
    local grad = Instance.new("UIGradient")
    grad.Rotation = 90
    grad.Color = ColorSequence.new(Color3.fromRGB(118, 76, 186), Color3.fromRGB(34, 20, 62))
    grad.Parent = bg
    local rim = Instance.new("Frame")                       -- a soft light line along the top edge
    rim.AnchorPoint = Vector2.new(0.5, 0)
    rim.Position = UDim2.new(0.5, 0, 0, 7)
    rim.Size = UDim2.new(1, -56, 0, 3)
    rim.BackgroundColor3 = Color3.new(1, 1, 1)
    rim.BackgroundTransparency = 0.75
    rim.BorderSizePixel = 0
    rim.ZIndex = 3
    rim.Parent = root
    corner(rim, UDim.new(1, 0))
    DBSnow(root, 22, 2)

    -- the outline is a frame INSIDE the window: the window clips it to its rounded shape, so the corners are smooth
    local edge = Instance.new("Frame")
    edge.Size = UDim2.fromScale(1, 1)
    edge.BackgroundTransparency = 1
    edge.BorderSizePixel = 0
    edge.ZIndex = 30
    edge.Parent = root
    corner(edge, UDim.new(0, 26))
    outline(edge, 8)

    -- wordmark (the real logo is only sent by the server after the key check)
    local mark = text(root, "DBHUB", 58, 30, 70, ICE, Enum.Font.GothamBlack)
    mark.TextWrapped = false
    outline(mark, 4)
    local mg = Instance.new("UIGradient")
    mg.Rotation = 90
    mg.Color = ColorSequence.new(Color3.fromRGB(255, 176, 240), Color3.fromRGB(150, 112, 255))
    mg.Parent = mark

    -- "INVITE ONLY" badge
    local badge = Instance.new("Frame")
    badge.AnchorPoint = Vector2.new(0.5, 0)
    badge.Position = UDim2.new(0.5, 0, 0, 108)
    badge.Size = UDim2.fromOffset(134, 24)
    badge.BackgroundColor3 = Color3.new(1, 1, 1)
    badge.BorderSizePixel = 0
    badge.ZIndex = 5
    badge.Parent = root
    corner(badge, UDim.new(1, 0))
    outline(badge, 3)
    local bgrad = Instance.new("UIGradient")
    bgrad.Color = ColorSequence.new(PINK, VIOLET)
    bgrad.Parent = badge
    local bl = text(badge, "INVITE ONLY", 12, 0, 24, ICE, Enum.Font.GothamBlack)
    bl.AnchorPoint = Vector2.new(0, 0)
    bl.Position = UDim2.fromScale(0, 0)
    bl.Size = UDim2.fromScale(1, 1)
    bl.TextWrapped = false
    outline(bl, 2)

    local title = text(root, "Enter your key to continue", 19, 148, 26, ICE, Enum.Font.GothamBlack)
    title.TextWrapped = false
    outline(title, 3)

    -- the key field
    local box = Instance.new("TextBox")
    box.AnchorPoint = Vector2.new(0.5, 0)
    box.Position = UDim2.new(0.5, 0, 0, 190)
    box.Size = UDim2.fromOffset(350, 48)
    box.BackgroundColor3 = Color3.fromRGB(40, 24, 78)
    box.TextColor3 = ICE
    box.PlaceholderText = "DBHUB-XXXX-XXXX-XXXX"
    box.PlaceholderColor3 = Color3.fromRGB(150, 130, 196)
    box.Font = Enum.Font.GothamBold
    box.TextSize = 17
    box.Text = ""
    box.ClearTextOnFocus = false
    box.ZIndex = 6
    box.Parent = root
    corner(box, UDim.new(0, 15))
    local boxStroke = Instance.new("UIStroke")
    boxStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    boxStroke.Color = INK
    boxStroke.Thickness = 3
    boxStroke.Parent = box
    box.Focused:Connect(function() tween(boxStroke, 0.2, { Color = VIOLET }) end)

    local status = text(root, startMsg or "", 13, 244, 18, Color3.fromRGB(226, 212, 255), Enum.Font.GothamBold)
    status.TextWrapped = false

    -- chunky buttons: dark outline, a "3D" base under them, a glossy strip, they lift on hover and sink when pressed
    local function cbutton(label, x, w, base, dark, onClick)
        local holder = Instance.new("Frame")
        holder.AnchorPoint = Vector2.new(0.5, 0)
        holder.Position = UDim2.new(0.5, x, 0, 280)
        holder.Size = UDim2.fromOffset(w, 54)
        holder.BackgroundTransparency = 1
        holder.ZIndex = 5
        holder.Parent = root
        local base3d = Instance.new("Frame")
        base3d.Position = UDim2.fromOffset(0, 6)
        base3d.Size = UDim2.new(1, 0, 0, 44)
        base3d.BackgroundColor3 = dark
        base3d.BorderSizePixel = 0
        base3d.ZIndex = 5
        base3d.Parent = holder
        corner(base3d, UDim.new(0, 15))
        outline(base3d, 3)
        local body = Instance.new("Frame")
        body.Size = UDim2.new(1, 0, 0, 44)
        body.BackgroundColor3 = base
        body.BorderSizePixel = 0
        body.ZIndex = 6
        body.Parent = holder
        corner(body, UDim.new(0, 15))
        outline(body, 3)
        local gloss = Instance.new("Frame")
        gloss.AnchorPoint = Vector2.new(0.5, 0)
        gloss.Position = UDim2.new(0.5, 0, 0, 4)
        gloss.Size = UDim2.new(1, -22, 0, 5)
        gloss.BackgroundColor3 = Color3.new(1, 1, 1)
        gloss.BackgroundTransparency = 0.6
        gloss.BorderSizePixel = 0
        gloss.ZIndex = 7
        gloss.Parent = body
        corner(gloss, UDim.new(1, 0))
        local lbl = Instance.new("TextLabel")
        lbl.BackgroundTransparency = 1
        lbl.Size = UDim2.fromScale(1, 1)
        lbl.Text = label
        lbl.Font = Enum.Font.GothamBlack
        lbl.TextSize = 16
        lbl.TextColor3 = ICE
        lbl.ZIndex = 8
        lbl.Parent = body
        outline(lbl, 2.5)
        local hit = Instance.new("TextButton")
        hit.BackgroundTransparency = 1
        hit.Text = ""
        hit.Size = UDim2.new(1, 0, 0, 50)
        hit.ZIndex = 9
        hit.Parent = holder
        hit.MouseEnter:Connect(function() tween(body, 0.12, { Position = UDim2.fromOffset(0, -2) }) end)
        hit.MouseLeave:Connect(function() tween(body, 0.12, { Position = UDim2.fromOffset(0, 0) }) end)
        hit.MouseButton1Down:Connect(function() tween(body, 0.06, { Position = UDim2.fromOffset(0, 5) }) end)
        hit.MouseButton1Up:Connect(function() tween(body, 0.1, { Position = UDim2.fromOffset(0, -2) }) end)
        hit.MouseButton1Click:Connect(onClick)
        return holder
    end

    local done, result, fails, lockedUntil, busy = false, false, 0, 0, false
    local function finish(ok)
        if done then return end
        tween(root, 0.3, { GroupTransparency = 1 }, Enum.EasingStyle.Sine)
        tween(scale, 0.3, { Scale = ok and 1.05 or 0.94 }, Enum.EasingStyle.Sine)
        task.wait(0.35)
        result, done = ok, true
    end
    local function shake()
        local base = root.Position
        for _, dx in ipairs({ -10, 9, -6, 4, 0 }) do
            tween(root, 0.045, { Position = base + UDim2.fromOffset(dx, 0) }, Enum.EasingStyle.Sine)
            task.wait(0.05)
        end
    end
    local function try()
        if busy or done then return end
        busy = true
        if os.clock() < lockedUntil then
            status.TextColor3 = BAD
            status.Text = "Too many attempts, wait " .. math.ceil(lockedUntil - os.clock()) .. " s"
            busy = false
            return
        end
        status.TextColor3 = Color3.fromRGB(226, 212, 255)
        status.Text = "Checking the key..."
        local payload, err = launch(box.Text)
        if payload then
            pcall(function()
                if makefolder and isfolder and not isfolder(DIR) then makefolder(DIR) end
                writefile(KEYFILE, box.Text)
            end)
            status.TextColor3 = GOOD
            status.Text = "Key accepted"
            tween(boxStroke, 0.2, { Color = GOOD })
            task.wait(0.45)
            finish(payload)
            return
        end
        fails = fails + 1
        status.TextColor3 = BAD
        status.Text = ERR_TEXT[err] or "Something went wrong"
        tween(boxStroke, 0.15, { Color = BAD })
        shake()
        tween(boxStroke, 0.4, { Color = INK })
        if fails >= 5 then
            lockedUntil = os.clock() + 30
            fails = 0
        end
        busy = false
    end
    box.FocusLost:Connect(function(enterPressed)
        tween(boxStroke, 0.2, { Color = INK })
        if enterPressed then try() end
    end)

    cbutton("ACTIVATE", -100, 176, Color3.fromRGB(150, 104, 240), Color3.fromRGB(84, 52, 160), try)
    cbutton("GET KEY", 100, 176, Color3.fromRGB(104, 118, 255), Color3.fromRGB(58, 66, 176), function()
        pcall(setclipboard, KEY_LINK)
        status.TextColor3 = Color3.fromRGB(255, 226, 150)
        status.Text = "Discord link copied to clipboard"
    end)

    -- round close button with a drawn cross that turns on hover
    local close = Instance.new("Frame")
    close.AnchorPoint = Vector2.new(1, 0)
    close.Position = UDim2.new(1, -16, 0, 16)
    close.Size = UDim2.fromOffset(34, 34)
    close.BackgroundColor3 = Color3.fromRGB(64, 46, 102)
    close.BorderSizePixel = 0
    close.ZIndex = 40
    close.Parent = root
    corner(close, UDim.new(1, 0))
    outline(close, 3)
    local cross = Instance.new("Frame")
    cross.BackgroundTransparency = 1
    cross.AnchorPoint = Vector2.new(0.5, 0.5)
    cross.Position = UDim2.fromScale(0.5, 0.5)
    cross.Size = UDim2.fromOffset(14, 14)
    cross.ZIndex = 41
    cross.Parent = close
    for _, rot in ipairs({ 45, -45 }) do
        local bar = Instance.new("Frame")
        bar.BorderSizePixel = 0
        bar.BackgroundColor3 = ICE
        bar.AnchorPoint = Vector2.new(0.5, 0.5)
        bar.Position = UDim2.fromScale(0.5, 0.5)
        bar.Size = UDim2.new(1.35, 0, 0, 3)
        bar.Rotation = rot
        bar.ZIndex = 41
        bar.Parent = cross
        corner(bar, UDim.new(1, 0))
    end
    local closeHit = Instance.new("TextButton")
    closeHit.BackgroundTransparency = 1
    closeHit.Text = ""
    closeHit.Size = UDim2.fromScale(1, 1)
    closeHit.ZIndex = 42
    closeHit.Parent = close
    closeHit.MouseEnter:Connect(function()
        tween(close, 0.2, { BackgroundColor3 = Color3.fromRGB(216, 70, 110) })
        tween(cross, 0.3, { Rotation = 90 }, Enum.EasingStyle.Back)
    end)
    closeHit.MouseLeave:Connect(function()
        tween(close, 0.2, { BackgroundColor3 = Color3.fromRGB(64, 46, 102) })
        tween(cross, 0.3, { Rotation = 0 }, Enum.EasingStyle.Back)
    end)
    closeHit.MouseButton1Click:Connect(function() finish(false) end)

    -- opening: the window grows and fades in
    tween(root, 0.45, { GroupTransparency = 0 })
    tween(scale, 0.6, { Scale = 1 }, Enum.EasingStyle.Back)

    while not done do task.wait(0.1) end
    gui:Destroy()
    return result
end
-- run the code the server sent: several parts, one after another (the shared part, the loading screen, the game)
local payload = DBGate()
if not payload then return end
for _, chunk in ipairs(string.split(payload, SPLIT)) do
    local fn, err = loadstring(chunk)
    if not fn then
        warn("DBHUB: " .. tostring(err))
        return
    end
    local ok, runErr = pcall(fn)
    if not ok then
        warn("DBHUB: " .. tostring(runErr))
        return
    end
end