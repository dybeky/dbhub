-- DBHUB launcher. It does not contain the hub: it asks the server, and the server checks the key
-- and sends the hub code (and the pictures) only to a valid key.
local API = "https://dbhub-api-production.up.railway.app"   -- address of your server, e.g. "https://dbhub-api.YOURNAME.workers.dev" (see server/README.md)
local KEY_LINK = "https://discord.gg/ux9r4KJRAC"   -- copied by the GET KEY button

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
        Body = HttpService:JSONEncode({ key = key, userId = player.UserId, placeId = game.PlaceId, gameId = game.GameId }),
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

-- the key window; returns the hub code when the server accepted the key, false when the window was closed
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
    -- ---- key window ----
    local RED, GOLD = Color3.fromRGB(150, 104, 240), Color3.fromRGB(206, 174, 255)
    local SOFT = Color3.fromRGB(248, 243, 255)
    local EDGE = Color3.fromRGB(104, 78, 156)

    local gui = Instance.new("ScreenGui")
    gui.Name = "DBHubKey"
    gui.ResetOnSpawn = false
    gui.IgnoreGuiInset = true
    gui.DisplayOrder = 1000
    gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    local okParent = pcall(function() gui.Parent = (gethui and gethui()) or game:GetService("CoreGui") end)
    if not okParent then gui.Parent = player:WaitForChild("PlayerGui") end

    local function tween(o, t, props, style, dir)
        local tw = TS:Create(o, TweenInfo.new(t, style or Enum.EasingStyle.Quint, dir or Enum.EasingDirection.Out), props)
        tw:Play()
        return tw
    end
    local function corner(o, r)
        local c = Instance.new("UICorner"); c.CornerRadius = r; c.Parent = o
    end
    local function stroke(o, col, th, tr)
        local s = Instance.new("UIStroke")
        s.ApplyStrokeMode = Enum.ApplyStrokeMode.Border   -- a border only, never an outline around the letters
        s.Color = col
        s.Thickness = th
        s.Transparency = tr or 0
        s.Parent = o
        return s
    end
    local function label(parent, text, size, y, color, font)
        local l = Instance.new("TextLabel")
        l.BackgroundTransparency = 1
        l.Text = text
        l.Font = font or Enum.Font.Gotham
        l.TextSize = size
        l.TextColor3 = color
        l.AnchorPoint = Vector2.new(0.5, 0)
        l.Position = UDim2.new(0.5, 0, 0, y)
        l.Size = UDim2.new(1, -40, 0, size + 8)
        l.Parent = parent
        return l
    end

    -- CanvasGroup: the whole window fades as one piece
    local root = Instance.new("CanvasGroup")
    root.AnchorPoint = Vector2.new(0.5, 0.5)
    root.Position = UDim2.fromScale(0.5, 0.5)
    root.Size = UDim2.fromOffset(420, 400)
    root.BackgroundColor3 = Color3.fromRGB(30, 20, 52)
    root.GroupTransparency = 1
    root.Parent = gui
    corner(root, UDim.new(0, 18))
    local scale = Instance.new("UIScale")
    scale.Scale = 0.9
    scale.Parent = root

    local bg = Instance.new("Frame")
    bg.Size = UDim2.fromScale(1, 1)
    bg.BackgroundColor3 = Color3.new(1, 1, 1)
    bg.BorderSizePixel = 0
    bg.Parent = root
    local grad = Instance.new("UIGradient")
    grad.Rotation = 90
    grad.Color = ColorSequence.new(Color3.fromRGB(100, 64, 158), Color3.fromRGB(24, 15, 44))
    grad.Parent = bg
    DBSnow(root, 22, 1)
    do   -- outline INSIDE the clipped window (smooth rounded corners)
        local edge = Instance.new("Frame")
        edge.Size = UDim2.fromScale(1, 1)
        edge.BackgroundTransparency = 1
        edge.BorderSizePixel = 0
        edge.ZIndex = 30
        edge.Parent = root
        corner(edge, UDim.new(0, 18))
        stroke(edge, GOLD, 3, 0.35)
    end

    do   -- wordmark (the real logo is only sent by the server after the key check)
        local mark = label(root, "DBHUB", 56, 52, SOFT, Enum.Font.GothamBlack)
        local st = Instance.new("UIStroke")
        st.Color = Color3.fromRGB(34, 16, 70)
        st.Thickness = 4
        st.LineJoinMode = Enum.LineJoinMode.Round
        st.Parent = mark
        local g = Instance.new("UIGradient")
        g.Rotation = 90
        g.Color = ColorSequence.new(Color3.fromRGB(255, 170, 238), Color3.fromRGB(150, 112, 255))
        g.Parent = mark
        label(root, "invite only", 14, 128, Color3.fromRGB(208, 192, 232), Enum.Font.GothamBold)
    end
    label(root, "Enter your key to continue", 15, 202, Color3.fromRGB(208, 192, 232))

    local box = Instance.new("TextBox")
    box.AnchorPoint = Vector2.new(0.5, 0)
    box.Position = UDim2.new(0.5, 0, 0, 238)
    box.Size = UDim2.fromOffset(340, 44)
    box.BackgroundColor3 = Color3.fromRGB(44, 30, 74)
    box.TextColor3 = SOFT
    box.PlaceholderText = "DBHUB-XXXX-XXXX-XXXX"
    box.PlaceholderColor3 = Color3.fromRGB(142, 116, 168)
    box.Font = Enum.Font.Gotham
    box.TextSize = 16
    box.Text = ""
    box.ClearTextOnFocus = false
    box.Parent = root
    corner(box, UDim.new(0, 10))
    local boxStroke = stroke(box, EDGE, 1)
    box.Focused:Connect(function() tween(boxStroke, 0.2, { Color = GOLD }) end)

    local status = label(root, startMsg or "", 14, 290, SOFT)

    local function button(text, x, width, base, hover)
        local b = Instance.new("TextButton")
        b.AutoButtonColor = false
        b.Position = UDim2.new(0.5, x, 0, 328)
        b.Size = UDim2.fromOffset(width, 44)
        b.BackgroundColor3 = base
        b.Text = text
        b.Font = Enum.Font.GothamBold
        b.TextSize = 15
        b.TextColor3 = Color3.new(1, 1, 1)
        b.Parent = root
        corner(b, UDim.new(0, 10))
        b.MouseEnter:Connect(function() tween(b, 0.15, { BackgroundColor3 = hover }) end)
        b.MouseLeave:Connect(function() tween(b, 0.15, { BackgroundColor3 = base }) end)
        return b
    end

    local hasLink = KEY_LINK ~= ""
    local go = button("ACTIVATE", -170, hasLink and 165 or 340, RED, Color3.fromRGB(176, 136, 255))
    if hasLink then
        local get = button("GET KEY", 5, 165, Color3.fromRGB(78, 56, 134), Color3.fromRGB(106, 80, 172))
        stroke(get, GOLD, 1.2, 0.2)
        get.MouseButton1Click:Connect(function()
            pcall(setclipboard, KEY_LINK)
            status.TextColor3 = GOLD
            status.Text = "Link copied to clipboard"
        end)
    end

    -- round close button with a drawn cross that turns on hover
    local close = Instance.new("TextButton")
    close.AutoButtonColor = false
    close.Text = ""
    close.AnchorPoint = Vector2.new(1, 0)
    close.Position = UDim2.new(1, -12, 0, 12)
    close.Size = UDim2.fromOffset(30, 30)
    close.BackgroundColor3 = Color3.fromRGB(64, 46, 102)
    close.ZIndex = 5
    close.Parent = root
    corner(close, UDim.new(1, 0))
    local cross = Instance.new("Frame")
    cross.BackgroundTransparency = 1
    cross.AnchorPoint = Vector2.new(0.5, 0.5)
    cross.Position = UDim2.fromScale(0.5, 0.5)
    cross.Size = UDim2.fromOffset(14, 14)
    cross.ZIndex = 6
    cross.Parent = close
    for _, rot in ipairs({ 45, -45 }) do
        local bar = Instance.new("Frame")
        bar.BorderSizePixel = 0
        bar.BackgroundColor3 = SOFT
        bar.AnchorPoint = Vector2.new(0.5, 0.5)
        bar.Position = UDim2.fromScale(0.5, 0.5)
        bar.Size = UDim2.new(1.35, 0, 0, 2)
        bar.Rotation = rot
        bar.ZIndex = 6
        bar.Parent = cross
        corner(bar, UDim.new(1, 0))
    end
    close.MouseEnter:Connect(function()
        tween(close, 0.2, { BackgroundColor3 = RED })
        tween(cross, 0.3, { Rotation = 90 }, Enum.EasingStyle.Back)
    end)
    close.MouseLeave:Connect(function()
        tween(close, 0.2, { BackgroundColor3 = Color3.fromRGB(64, 46, 102) })
        tween(cross, 0.3, { Rotation = 0 }, Enum.EasingStyle.Back)
    end)

    local done, result, fails, lockedUntil, busy = false, false, 0, 0, false
    local function finish(ok)
        if done then return end
        tween(root, 0.28, { GroupTransparency = 1 })
        tween(scale, 0.28, { Scale = ok and 1.06 or 0.92 })
        task.wait(0.3)
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
            status.TextColor3 = RED
            status.Text = "Too many attempts, wait " .. math.ceil(lockedUntil - os.clock()) .. " s"
            busy = false
            return
        end
        status.TextColor3 = SOFT
        status.Text = "Checking the key..."
        local payload, err = launch(box.Text)
        if payload then
            pcall(function()
                if makefolder and isfolder and not isfolder(DIR) then makefolder(DIR) end
                writefile(KEYFILE, box.Text)
            end)
            status.TextColor3 = Color3.fromRGB(110, 230, 110)
            status.Text = "Key accepted"
            tween(boxStroke, 0.2, { Color = Color3.fromRGB(110, 230, 110) })
            task.wait(0.45)
            finish(payload)
            return
        end
        fails = fails + 1
        status.TextColor3 = RED
        status.Text = ERR_TEXT[err] or "Something went wrong"
        tween(boxStroke, 0.15, { Color = RED })
        shake()
        tween(boxStroke, 0.4, { Color = EDGE })
        if fails >= 5 then
            lockedUntil = os.clock() + 30
            fails = 0
        end
        busy = false
    end
    go.MouseButton1Click:Connect(try)
    box.FocusLost:Connect(function(enterPressed)
        tween(boxStroke, 0.2, { Color = EDGE })
        if enterPressed then try() end
    end)
    close.MouseButton1Click:Connect(function() finish(false) end)

    -- open animation
    tween(root, 0.4, { GroupTransparency = 0 })
    tween(scale, 0.5, { Scale = 1 }, Enum.EasingStyle.Back)

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