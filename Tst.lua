local ts = game:GetService("TweenService")
local ui = game:GetService("UserInputService")
local plr = game:GetService("Players")
local lg = game:GetService("Lighting")
local rs = game:GetService("RunService")
local gs = game:GetService("GuiService")
local hs = game:GetService("HttpService")

local n = "Acrylic"

-- SISTEMA DE TEMAS
local Themes = {
    Dark = {
        Background = Color3.fromRGB(12, 12, 12),
        Secondary = Color3.fromRGB(20, 20, 20),
        Border = Color3.fromRGB(39, 39, 39),
        Text = Color3.fromRGB(255, 255, 255),
        TextDark = Color3.fromRGB(93, 93, 93),
        TextFade = Color3.fromRGB(9, 9, 9),
        Accent = Color3.fromRGB(255, 255, 255),
        Toggle = {
            Enabled = Color3.fromRGB(255, 255, 255),
            Disabled = Color3.fromRGB(32, 32, 32),
            Circle = Color3.fromRGB(20, 20, 20)
        },
        Notification = {
            Background = Color3.fromRGB(11, 11, 11),
            Border = Color3.fromRGB(26, 26, 26),
            Timer = Color3.fromRGB(255, 255, 255)
        }
    },
    Light = {
        Background = Color3.fromRGB(248, 248, 248),
        Secondary = Color3.fromRGB(255, 255, 255),
        Border = Color3.fromRGB(220, 220, 220),
        Text = Color3.fromRGB(20, 20, 20),
        TextDark = Color3.fromRGB(140, 140, 140),
        TextFade = Color3.fromRGB(230, 230, 230),
        Accent = Color3.fromRGB(50, 50, 50),
        Toggle = {
            Enabled = Color3.fromRGB(50, 50, 50),
            Disabled = Color3.fromRGB(230, 230, 230),
            Circle = Color3.fromRGB(255, 255, 255)
        },
        Notification = {
            Background = Color3.fromRGB(255, 255, 255),
            Border = Color3.fromRGB(230, 230, 230),
            Timer = Color3.fromRGB(50, 50, 50)
        }
    }
}

local CurrentTheme = "Dark"
local c = Themes[CurrentTheme]

local s = {
    v0rtexd = {Width = 500, Height = 300},
    Minv0rtexd = {Width = 500, Height = 300},
    Maxv0rtexd = {Width = 1200, Height = 800},
    Toggle = {Width = 38, Height = 21, Circle = 13},
    Button = {Height = 39},
    Slider = {Height = 46},
    Dropdown = {Height = 39, OptionHeight = 30},
    Tab = {Width = 135, Height = 35},
    ColorPicker = {Width = 180, Height = 160},
    Notification = {Width = 220, Height = 70},
    TextBox = {Height = 39, InputWidth = 150}
}

local f = {
    Regular = Font.new("rbxasset://fonts/families/GothamSSm.json", Enum.FontWeight.SemiBold),
    Bold = Font.new("rbxasset://fonts/families/GothamSSm.json", Enum.FontWeight.Bold)
}

local textsize = {
    Title = 14,
    Normal = 14,
    Small = 13,
    Tiny = 11
}

local animationspeed = {
    Fast = 0.1,
    Normal = 0.15,
    Slow = 0.2,
    VerySlow = 0.3
}

local Library = {}
Library.__index = Library

local Connections = {}
local NotificationQueue = {}
local NotificationContainer = nil
local ThemeElements = {} -- Armazena todos os elementos que precisam ser atualizados quando o tema muda

local function CreateTween(instance, properties, duration, easingStyle, easingDirection)
    local tween = ts:Create(
        instance,
        TweenInfo.new(
            duration or animationspeed.Normal,
            easingStyle or Enum.EasingStyle.Quad,
            easingDirection or Enum.EasingDirection.Out
        ),
        properties
    )
    tween:Play()
    return tween
end

local function CreateInstance(className, properties)
    local instance = Instance.new(className)
    for property, value in pairs(properties) do
        if property ~= "Parent" then
            instance[property] = value
        end
    end
    if properties.Parent then
        instance.Parent = properties.Parent
    end
    return instance
end

local function CreateCorner(parent, radius)
    return CreateInstance("UICorner", {
        CornerRadius = UDim.new(0, radius or 5),
        Parent = parent
    })
end

local function CreateStroke(parent, color, transparency)
    return CreateInstance("UIStroke", {
        ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
        Color = color or c.Border,
        Transparency = transparency or 0,
        Thickness = 1,
        Parent = parent
    })
end

local function CreatePadding(parent, top, bottom, left, right)
    return CreateInstance("UIPadding", {
        PaddingTop = UDim.new(0, top or 0),
        PaddingBottom = UDim.new(0, bottom or 0),
        PaddingLeft = UDim.new(0, left or 0),
        PaddingRight = UDim.new(0, right or 0),
        Parent = parent
    })
end

local function CreateListLayout(parent, padding, sortOrder, direction)
    return CreateInstance("UIListLayout", {
        Padding = UDim.new(0, padding or 0),
        SortOrder = sortOrder or Enum.SortOrder.LayoutOrder,
        FillDirection = direction or Enum.FillDirection.Vertical,
        Parent = parent
    })
end

-- Função para registrar elementos que precisam ser atualizados quando o tema muda
local function RegisterThemeElement(element, colorProperty, themeKey, subKey)
    table.insert(ThemeElements, {
        Element = element,
        Property = colorProperty,
        ThemeKey = themeKey,
        SubKey = subKey
    })
end

-- Função para aplicar tema em todos os elementos registrados
local function ApplyTheme(themeName)
    if not Themes[themeName] then return end
    
    CurrentTheme = themeName
    c = Themes[CurrentTheme]
    
    for _, data in ipairs(ThemeElements) do
        if data.Element and data.Element.Parent then
            local color
            if data.SubKey then
                color = c[data.ThemeKey][data.SubKey]
            else
                color = c[data.ThemeKey]
            end
            
            CreateTween(data.Element, {[data.Property] = color}, animationspeed.Fast)
        end
    end
end

local function IsMobileDevice()
    return ui.TouchEnabled and not ui.KeyboardEnabled
end

local function MakeDraggable(frame, handle)
    local dragging = false
    local dragInput, dragStart, startPos
    handle = handle or frame

    local function OnInputBegan(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPos = frame.Position
            local connection
            connection = input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    dragging = false
                    if connection then
                        connection:Disconnect()
                    end
                end
            end)
        end
    end

    local function OnInputChanged(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
            dragInput = input
        end
    end

    handle.InputBegan:Connect(OnInputBegan)
    handle.InputChanged:Connect(OnInputChanged)

    ui.InputChanged:Connect(function(input)
        if input == dragInput and dragging then
            local delta = input.Position - dragStart
            frame.Position = UDim2.new(
                startPos.X.Scale,
                startPos.X.Offset + delta.X,
                startPos.Y.Scale,
                startPos.Y.Offset + delta.Y
            )
        end
    end)
end

local function DisconnectAll()
    for _, connection in pairs(Connections) do
        if typeof(connection) == "RBXScriptConnection" then
            connection:Disconnect()
        end
    end
    Connections = {}
end

local function GetConfigFolder(configName)
    return "AcrylicConfigs/" .. configName
end

local function EnsureConfigFolder()
    if isfolder and not isfolder("AcrylicConfigs") then
        makefolder("AcrylicConfigs")
    end
end

local function GetAvailableConfigs()
    local configs = {}
    if isfolder and listfiles then
        EnsureConfigFolder()
        local files = listfiles("AcrylicConfigs")
        for _, file in ipairs(files) do
            local name = file:match("AcrylicConfigs/(.+)%.json$") or file:match("AcrylicConfigs\\(.+)%.json$")
            if name then
                table.insert(configs, name)
            end
        end
    end
    return configs
end

local AcrylicBlur = {}
AcrylicBlur.__index = AcrylicBlur

function AcrylicBlur.new(object)
    local self = setmetatable({
        _object = object,
        _folder = nil,
        _root = nil,
        _frame = nil,
        _dof = nil,
        _enabled = true
    }, AcrylicBlur)
    self:_Initialize()
    return self
end

function AcrylicBlur:_CreateDepthOfField()
    local existingDOF = lg:FindFirstChild("AcrylicBlur")
    if existingDOF then
        existingDOF:Destroy()
    end
    local existingBlur = lg:FindFirstChild("AcrylicBlurEffect")
    if existingBlur then
        existingBlur:Destroy()
    end
    
    local dof = CreateInstance("DepthOfFieldEffect", {
        Name = "AcrylicBlur",
        FarIntensity = 0,
        FocusDistance = 0.05,
        InFocusRadius = 0.1,
        NearIntensity = 0.5, 
        Parent = lg
    })
    
    self._dof = dof
    return dof
end

function AcrylicBlur:_CreateFolder()
    local existingFolder = workspace.CurrentCamera:FindFirstChild("AcrylicBlur")
    if existingFolder then
        existingFolder:Destroy()
    end
    self._folder = CreateInstance("Folder", {
        Name = "AcrylicBlur",
        Parent = workspace.CurrentCamera
    })
end

function AcrylicBlur:_CreateRoot()
    local part = CreateInstance("Part", {
        Name = "Root",
        Color = Color3.new(0, 0, 0),
        Size = Vector3.new(1, 1, 1),
        Transparency = 1,
        Anchored = true,
        CanCollide = false,
        Parent = self._folder
    })
    self._root = part
    return part
end

function AcrylicBlur:_CreateFrame()
    local frame = CreateInstance("SurfaceGui", {
        Name = "Frame",
        Adornee = self._root,
        Face = Enum.NormalId.Front,
        Parent = self._root
    })
    self._frame = frame
    return frame
end

function AcrylicBlur:_UpdatePosition()
    if not self._enabled or not self._object or not self._root then
        return
    end
    
    local camera = workspace.CurrentCamera
    if not camera then return end
    
    local objPos = self._object.AbsolutePosition
    local objSize = self._object.AbsoluteSize
    local viewport = camera.ViewportSize
    
    local centerX = objPos.X + (objSize.X / 2)
    local centerY = objPos.Y + (objSize.Y / 2)
    
    local normX = centerX / viewport.X
    local normY = centerY / viewport.Y
    
    local ray = camera:ViewportPointToRay(centerX, centerY)
    local distance = 10
    
    self._root.CFrame = CFrame.new(ray.Origin + ray.Direction * distance) * CFrame.Angles(0, math.pi, 0)
    
    local scaleFactor = distance * 0.05
    local width = (objSize.X / viewport.X) * scaleFactor
    local height = (objSize.Y / viewport.Y) * scaleFactor
    
    self._root.Size = Vector3.new(width, height, 0.1)
end

function AcrylicBlur:_Initialize()
    self:_CreateFolder()
    self:_CreateRoot()
    self:_CreateFrame()
    self:_CreateDepthOfField()
    
    local connection = rs.RenderStepped:Connect(function()
        self:_UpdatePosition()
    end)
    
    table.insert(Connections, connection)
    
    if self._object then
        local ancestryConnection = self._object.AncestryChanged:Connect(function()
            if not self._object or not self._object.Parent then
                self:Destroy()
            end
        end)
        table.insert(Connections, ancestryConnection)
    end
end

function AcrylicBlur:Enable()
    self._enabled = true
    if self._dof then
        self._dof.Enabled = true
    end
end

function AcrylicBlur:Disable()
    self._enabled = false
    if self._dof then
        self._dof.Enabled = false
    end
end

function AcrylicBlur:Destroy()
    self._enabled = false
    if self._folder then
        self._folder:Destroy()
    end
    if self._dof then
        self._dof:Destroy()
    end
end

function Library.new(config)
    local self = setmetatable({}, Library)
    
    self.name = config.Name or "Acrylic UI"
    self.configSystem = config.ConfigSystem == nil and true or config.ConfigSystem
    self.blur = config.Blur == nil and true or config.Blur
    self._tabs = {}
    self._currentTab = nil
    self._configElements = {}
    self._autoSave = false
    self._currentConfig = "default"
    
    self:_CreateUI()
    
    return self
end

function Library:_CreateUI()
    local screenGui = CreateInstance("ScreenGui", {
        Name = n,
        ResetOnSpawn = false,
        ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
        Parent = game.CoreGui
    })
    
    local mainFrame = CreateInstance("Frame", {
        Name = "Main",
        AnchorPoint = Vector2.new(0.5, 0.5),
        BackgroundColor3 = c.Background,
        BorderSizePixel = 0,
        Position = UDim2.new(0.5, 0, 0.5, 0),
        Size = UDim2.new(0, s.v0rtexd.Width, 0, s.v0rtexd.Height),
        Parent = screenGui
    })
    RegisterThemeElement(mainFrame, "BackgroundColor3", "Background")
    
    CreateCorner(mainFrame, 8)
    local mainStroke = CreateStroke(mainFrame)
    RegisterThemeElement(mainStroke, "Color", "Border")
    
    if self.blur then
        AcrylicBlur.new(mainFrame)
    end
    
    local topBar = CreateInstance("Frame", {
        Name = "TopBar",
        BackgroundColor3 = c.Secondary,
        BackgroundTransparency = 0.7,
        BorderSizePixel = 0,
        Size = UDim2.new(1, 0, 0, 40),
        Parent = mainFrame
    })
    RegisterThemeElement(topBar, "BackgroundColor3", "Secondary")
    
    CreateCorner(topBar, 8)
    local topBarStroke = CreateStroke(topBar)
    RegisterThemeElement(topBarStroke, "Color", "Border")
    
    local bottomCornerCover = CreateInstance("Frame", {
        Name = "BottomCornerCover",
        BackgroundColor3 = c.Secondary,
        BackgroundTransparency = 0.7,
        BorderSizePixel = 0,
        Position = UDim2.new(0, 0, 1, -8),
        Size = UDim2.new(1, 0, 0, 8),
        Parent = topBar
    })
    RegisterThemeElement(bottomCornerCover, "BackgroundColor3", "Secondary")
    
    local title = CreateInstance("TextLabel", {
        Name = "Title",
        FontFace = f.Bold,
        Text = self.name,
        TextColor3 = c.Text,
        TextSize = textsize.Title,
        TextXAlignment = Enum.TextXAlignment.Left,
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 15, 0, 0),
        Size = UDim2.new(1, -80, 1, 0),
        Parent = topBar
    })
    RegisterThemeElement(title, "TextColor3", "Text")
    
    local closeBtn = CreateInstance("TextButton", {
        Name = "CloseButton",
        Text = "×",
        FontFace = f.Bold,
        TextColor3 = c.Text,
        TextSize = 24,
        BackgroundTransparency = 1,
        AnchorPoint = Vector2.new(1, 0.5),
        Position = UDim2.new(1, -15, 0.5, 0),
        Size = UDim2.new(0, 30, 0, 30),
        Parent = topBar
    })
    RegisterThemeElement(closeBtn, "TextColor3", "Text")
    
    closeBtn.MouseButton1Click:Connect(function()
        CreateTween(mainFrame, {Size = UDim2.new(0, 0, 0, 0)}, animationspeed.Normal)
        task.wait(animationspeed.Normal)
        screenGui:Destroy()
        DisconnectAll()
    end)
    
    closeBtn.MouseEnter:Connect(function()
        CreateTween(closeBtn, {TextColor3 = Color3.fromRGB(255, 85, 85)}, animationspeed.Fast)
    end)
    
    closeBtn.MouseLeave:Connect(function()
        CreateTween(closeBtn, {TextColor3 = c.Text}, animationspeed.Fast)
    end)
    
    local minimizeBtn = CreateInstance("TextButton", {
        Name = "MinimizeButton",
        Text = "−",
        FontFace = f.Bold,
        TextColor3 = c.Text,
        TextSize = 22,
        BackgroundTransparency = 1,
        AnchorPoint = Vector2.new(1, 0.5),
        Position = UDim2.new(1, -45, 0.5, 0),
        Size = UDim2.new(0, 30, 0, 30),
        Parent = topBar
    })
    RegisterThemeElement(minimizeBtn, "TextColor3", "Text")
    
    local isMinimized = false
    local originalSize = mainFrame.Size
    
    minimizeBtn.MouseButton1Click:Connect(function()
        isMinimized = not isMinimized
        if isMinimized then
            CreateTween(mainFrame, {Size = UDim2.new(0, s.v0rtexd.Width, 0, 40)}, animationspeed.Normal)
        else
            CreateTween(mainFrame, {Size = originalSize}, animationspeed.Normal)
        end
    end)
    
    minimizeBtn.MouseEnter:Connect(function()
        CreateTween(minimizeBtn, {TextColor3 = c.Accent}, animationspeed.Fast)
    end)
    
    minimizeBtn.MouseLeave:Connect(function()
        CreateTween(minimizeBtn, {TextColor3 = c.Text}, animationspeed.Fast)
    end)
    
    MakeDraggable(mainFrame, topBar)
    
    local tabsContainer = CreateInstance("Frame", {
        Name = "TabsContainer",
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 0, 0, 40),
        Size = UDim2.new(0, s.Tab.Width, 1, -40),
        Parent = mainFrame
    })
    
    local tabsList = CreateInstance("ScrollingFrame", {
        Name = "TabsList",
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        ScrollBarThickness = 4,
        ScrollBarImageColor3 = c.TextDark,
        Size = UDim2.new(1, 0, 1, 0),
        CanvasSize = UDim2.new(0, 0, 0, 0),
        Parent = tabsContainer
    })
    RegisterThemeElement(tabsList, "ScrollBarImageColor3", "TextDark")
    
    CreateListLayout(tabsList, 5)
    CreatePadding(tabsList, 10, 10, 10, 10)
    
    local contentContainer = CreateInstance("Frame", {
        Name = "ContentContainer",
        BackgroundColor3 = c.Secondary,
        BackgroundTransparency = 0.95,
        BorderSizePixel = 0,
        Position = UDim2.new(0, s.Tab.Width, 0, 40),
        Size = UDim2.new(1, -s.Tab.Width, 1, -40),
        Parent = mainFrame
    })
    RegisterThemeElement(contentContainer, "BackgroundColor3", "Secondary")
    
    self.gui = screenGui
    self.main = mainFrame
    self.tabsContainer = tabsContainer
    self.tabsList = tabsList
    self.contentContainer = contentContainer
    
    tabsList:GetPropertyChangedSignal("AbsoluteCanvasSize"):Connect(function()
        tabsList.CanvasSize = UDim2.new(0, 0, 0, tabsList.AbsoluteCanvasSize.Y)
    end)
end

function Library:CreateTab(name)
    local tab = {
        name = name,
        _library = self,
        button = nil,
        content = nil
    }
    
    local tabBtn = CreateInstance("TextButton", {
        Name = "Tab_" .. name,
        Text = name,
        FontFace = f.Regular,
        TextColor3 = c.TextDark,
        TextSize = textsize.Normal,
        BackgroundColor3 = c.Secondary,
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        Size = UDim2.new(1, -20, 0, s.Tab.Height),
        Parent = self.tabsList
    })
    RegisterThemeElement(tabBtn, "TextColor3", "TextDark")
    RegisterThemeElement(tabBtn, "BackgroundColor3", "Secondary")
    
    CreateCorner(tabBtn, 5)
    local tabStroke = CreateStroke(tabBtn)
    RegisterThemeElement(tabStroke, "Color", "Border")
    tabStroke.Transparency = 1
    
    local tabContent = CreateInstance("ScrollingFrame", {
        Name = "Content_" .. name,
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        ScrollBarThickness = 4,
        ScrollBarImageColor3 = c.TextDark,
        Size = UDim2.new(1, 0, 1, 0),
        CanvasSize = UDim2.new(0, 0, 0, 0),
        Visible = false,
        Parent = self.contentContainer
    })
    RegisterThemeElement(tabContent, "ScrollBarImageColor3", "TextDark")
    
    CreateListLayout(tabContent, 8)
    CreatePadding(tabContent, 15, 15, 15, 15)
    
    tab.button = tabBtn
    tab.content = tabContent
    
    tabBtn.MouseButton1Click:Connect(function()
        self:_SelectTab(tab)
    end)
    
    tabBtn.MouseEnter:Connect(function()
        if self._currentTab ~= tab then
            CreateTween(tabBtn, {BackgroundTransparency = 0.9}, animationspeed.Fast)
        end
    end)
    
    tabBtn.MouseLeave:Connect(function()
        if self._currentTab ~= tab then
            CreateTween(tabBtn, {BackgroundTransparency = 1}, animationspeed.Fast)
        end
    end)
    
    tabContent:GetPropertyChangedSignal("AbsoluteCanvasSize"):Connect(function()
        tabContent.CanvasSize = UDim2.new(0, 0, 0, tabContent.AbsoluteCanvasSize.Y)
    end)
    
    table.insert(self._tabs, tab)
    
    if not self._currentTab then
        self:_SelectTab(tab)
    end
    
    return setmetatable(tab, {__index = Library})
end

function Library:_SelectTab(tab)
    for _, t in ipairs(self._tabs) do
        t.content.Visible = false
        CreateTween(t.button, {
            BackgroundTransparency = 1,
            TextColor3 = c.TextDark
        }, animationspeed.Fast)
        local stroke = t.button:FindFirstChildOfClass("UIStroke")
        if stroke then
            CreateTween(stroke, {Transparency = 1}, animationspeed.Fast)
        end
    end
    
    tab.content.Visible = true
    CreateTween(tab.button, {
        BackgroundTransparency = 0.7,
        TextColor3 = c.Text
    }, animationspeed.Fast)
    
    local stroke = tab.button:FindFirstChildOfClass("UIStroke")
    if stroke then
        CreateTween(stroke, {Transparency = 0}, animationspeed.Fast)
    end
    
    self._currentTab = tab
end

function Library._CreateContentSection(tab, title)
    local section = CreateInstance("TextLabel", {
        Name = "Section_" .. title,
        Text = title,
        FontFace = f.Bold,
        TextColor3 = c.Text,
        TextSize = textsize.Normal,
        TextXAlignment = Enum.TextXAlignment.Left,
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 0, 25),
        Parent = tab.content
    })
    RegisterThemeElement(section, "TextColor3", "Text")
    
    CreatePadding(section, 0, 0, 5, 0)
    
    return section
end

function Library._CreateButton(tab, config)
    local name = config.Name or "Button"
    local callback = config.Callback or function() end
    
    local button = CreateInstance("TextButton", {
        Name = "Button_" .. name,
        Text = name,
        FontFace = f.Regular,
        TextColor3 = c.Text,
        TextSize = textsize.Normal,
        BackgroundColor3 = c.Secondary,
        BackgroundTransparency = 0.4,
        BorderSizePixel = 0,
        Size = UDim2.new(1, 0, 0, s.Button.Height),
        Parent = tab.content
    })
    RegisterThemeElement(button, "TextColor3", "Text")
    RegisterThemeElement(button, "BackgroundColor3", "Secondary")
    
    CreateCorner(button, 5)
    local buttonStroke = CreateStroke(button)
    RegisterThemeElement(buttonStroke, "Color", "Border")
    
    button.MouseButton1Click:Connect(function()
        CreateTween(button, {BackgroundTransparency = 0}, animationspeed.Fast)
        task.wait(0.1)
        CreateTween(button, {BackgroundTransparency = 0.4}, animationspeed.Fast)
        callback()
    end)
    
    button.MouseEnter:Connect(function()
        CreateTween(button, {BackgroundTransparency = 0.2}, animationspeed.Fast)
        CreateTween(buttonStroke, {Color = c.Accent}, animationspeed.Fast)
    end)
    
    button.MouseLeave:Connect(function()
        CreateTween(button, {BackgroundTransparency = 0.4}, animationspeed.Fast)
        CreateTween(buttonStroke, {Color = c.Border}, animationspeed.Fast)
    end)
    
    return button
end

function Library._CreateToggle(tab, config)
    local name = config.Name or "Toggle"
    local default = config.Default or false
    local callback = config.Callback or function() end
    local flag = config.Flag
    local enabled = default
    
    local frame = CreateInstance("Frame", {
        Name = "Toggle_" .. name,
        BackgroundColor3 = c.Secondary,
        BackgroundTransparency = 0.4,
        BorderSizePixel = 0,
        Size = UDim2.new(1, 0, 0, s.Button.Height),
        Parent = tab.content
    })
    RegisterThemeElement(frame, "BackgroundColor3", "Secondary")
    
    CreateCorner(frame, 5)
    local frameStroke = CreateStroke(frame)
    RegisterThemeElement(frameStroke, "Color", "Border")
    
    local nameLabel = CreateInstance("TextLabel", {
        Name = "Name",
        FontFace = f.Regular,
        TextColor3 = c.Text,
        Text = name,
        TextXAlignment = Enum.TextXAlignment.Left,
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 10, 0, 0),
        TextSize = textsize.Normal,
        Size = UDim2.new(1, -60, 1, 0),
        Parent = frame
    })
    RegisterThemeElement(nameLabel, "TextColor3", "Text")
    
    local toggleBtn = CreateInstance("TextButton", {
        Name = "ToggleButton",
        Text = "",
        BackgroundColor3 = enabled and c.Toggle.Enabled or c.Toggle.Disabled,
        BorderSizePixel = 0,
        AnchorPoint = Vector2.new(1, 0.5),
        Position = UDim2.new(1, -10, 0.5, 0),
        Size = UDim2.new(0, s.Toggle.Width, 0, s.Toggle.Height),
        Parent = frame
    })
    RegisterThemeElement(toggleBtn, "BackgroundColor3", "Toggle", enabled and "Enabled" or "Disabled")
    
    CreateCorner(toggleBtn, 20)
    
    local circle = CreateInstance("Frame", {
        Name = "Circle",
        BackgroundColor3 = c.Toggle.Circle,
        BorderSizePixel = 0,
        Position = enabled and UDim2.new(1, -s.Toggle.Circle - 4, 0.5, 0) or UDim2.new(0, 4, 0.5, 0),
        AnchorPoint = Vector2.new(0, 0.5),
        Size = UDim2.new(0, s.Toggle.Circle, 0, s.Toggle.Circle),
        Parent = toggleBtn
    })
    RegisterThemeElement(circle, "BackgroundColor3", "Toggle", "Circle")
    
    CreateCorner(circle, 20)
    
    local function Toggle()
        enabled = not enabled
        
        CreateTween(toggleBtn, {
            BackgroundColor3 = enabled and c.Toggle.Enabled or c.Toggle.Disabled
        }, animationspeed.Fast)
        
        CreateTween(circle, {
            Position = enabled and UDim2.new(1, -s.Toggle.Circle - 4, 0.5, 0) or UDim2.new(0, 4, 0.5, 0)
        }, animationspeed.Fast, Enum.EasingStyle.Back)
        
        callback(enabled)
    end
    
    toggleBtn.MouseButton1Click:Connect(Toggle)
    
    frame.MouseEnter:Connect(function()
        CreateTween(frame, {BackgroundTransparency = 0.2}, animationspeed.Fast)
    end)
    
    frame.MouseLeave:Connect(function()
        CreateTween(frame, {BackgroundTransparency = 0.4}, animationspeed.Fast)
    end)
    
    local methods = {
        SetValue = function(_, value)
            if value ~= enabled then
                Toggle()
            end
        end,
        GetValue = function()
            return enabled
        end
    }
    
    if flag and tab._library then
        tab._library:_RegisterConfigElement(flag, "Toggle", 
            function() return enabled end,
            function(value) methods:SetValue(value) end
        )
    end
    
    return methods
end

function Library._CreateSlider(tab, config)
    local name = config.Name or "Slider"
    local min = config.Min or 0
    local max = config.Max or 100
    local default = config.Default or min
    local increment = config.Increment or 1
    local suffix = config.Suffix or ""
    local callback = config.Callback or function() end
    local flag = config.Flag
    local currentValue = default
    
    local frame = CreateInstance("Frame", {
        Name = "Slider_" .. name,
        BackgroundColor3 = c.Secondary,
        BackgroundTransparency = 0.4,
        BorderSizePixel = 0,
        Size = UDim2.new(1, 0, 0, s.Slider.Height),
        Parent = tab.content
    })
    RegisterThemeElement(frame, "BackgroundColor3", "Secondary")
    
    CreateCorner(frame, 5)
    local frameStroke = CreateStroke(frame)
    RegisterThemeElement(frameStroke, "Color", "Border")
    
    local nameLabel = CreateInstance("TextLabel", {
        Name = "Name",
        FontFace = f.Regular,
        TextColor3 = c.Text,
        Text = name,
        TextXAlignment = Enum.TextXAlignment.Left,
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 10, 0, 5),
        TextSize = textsize.Normal,
        Size = UDim2.new(1, -20, 0, 16),
        Parent = frame
    })
    RegisterThemeElement(nameLabel, "TextColor3", "Text")
    
    local valueLabel = CreateInstance("TextLabel", {
        Name = "Value",
        FontFace = f.Bold,
        TextColor3 = c.Accent,
        Text = tostring(currentValue) .. suffix,
        TextXAlignment = Enum.TextXAlignment.Right,
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 10, 0, 5),
        TextSize = textsize.Normal,
        Size = UDim2.new(1, -20, 0, 16),
        Parent = frame
    })
    RegisterThemeElement(valueLabel, "TextColor3", "Accent")
    
    local sliderBg = CreateInstance("Frame", {
        Name = "SliderBackground",
        BackgroundColor3 = c.Secondary,
        BackgroundTransparency = 0.04,
        BorderSizePixel = 0,
        Position = UDim2.new(0, 10, 1, -20),
        Size = UDim2.new(1, -20, 0, 6),
        Parent = frame
    })
    RegisterThemeElement(sliderBg, "BackgroundColor3", "Secondary")
    
    CreateCorner(sliderBg, 10)
    local sliderStroke = CreateStroke(sliderBg)
    RegisterThemeElement(sliderStroke, "Color", "Border")
    
    local sliderFill = CreateInstance("Frame", {
        Name = "Fill",
        BackgroundColor3 = c.Accent,
        BorderSizePixel = 0,
        Size = UDim2.new((currentValue - min) / (max - min), 0, 1, 0),
        Parent = sliderBg
    })
    RegisterThemeElement(sliderFill, "BackgroundColor3", "Accent")
    
    CreateCorner(sliderFill, 10)
    
    local dragging = false
    
    local function UpdateSlider(input)
        local pos = (input.Position.X - sliderBg.AbsolutePosition.X) / sliderBg.AbsoluteSize.X
        pos = math.clamp(pos, 0, 1)
        
        local value = min + (pos * (max - min))
        value = math.floor(value / increment + 0.5) * increment
        value = math.clamp(value, min, max)
        
        currentValue = value
        valueLabel.Text = tostring(currentValue) .. suffix
        
        CreateTween(sliderFill, {
            Size = UDim2.new((currentValue - min) / (max - min), 0, 1, 0)
        }, animationspeed.Fast)
        
        callback(currentValue)
    end
    
    sliderBg.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            UpdateSlider(input)
        end
    end)
    
    sliderBg.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = false
        end
    end)
    
    ui.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            UpdateSlider(input)
        end
    end)
    
    frame.MouseEnter:Connect(function()
        CreateTween(frame, {BackgroundTransparency = 0.2}, animationspeed.Fast)
    end)
    
    frame.MouseLeave:Connect(function()
        CreateTween(frame, {BackgroundTransparency = 0.4}, animationspeed.Fast)
    end)
    
    local methods = {
        SetValue = function(_, value)
            currentValue = math.clamp(value, min, max)
            currentValue = math.floor(currentValue / increment + 0.5) * increment
            valueLabel.Text = tostring(currentValue) .. suffix
            CreateTween(sliderFill, {
                Size = UDim2.new((currentValue - min) / (max - min), 0, 1, 0)
            }, animationspeed.Fast)
            callback(currentValue)
        end,
        GetValue = function()
            return currentValue
        end
    }
    
    if flag and tab._library then
        tab._library:_RegisterConfigElement(flag, "Slider", 
            function() return currentValue end,
            function(value) methods:SetValue(value) end
        )
    end
    
    return methods
end

function Library._CreateDropdown(tab, config)
    local name = config.Name or "Dropdown"
    local options = config.Options or {}
    local default = config.Default or (options[1] or "")
    local callback = config.Callback or function() end
    local flag = config.Flag
    local currentOption = default
    local expanded = false
    
    local frame = CreateInstance("Frame", {
        Name = "Dropdown_" .. name,
        BackgroundColor3 = c.Secondary,
        BackgroundTransparency = 0.4,
        BorderSizePixel = 0,
        Size = UDim2.new(1, 0, 0, s.Dropdown.Height),
        ClipsDescendants = false,
        Parent = tab.content
    })
    RegisterThemeElement(frame, "BackgroundColor3", "Secondary")
    
    CreateCorner(frame, 5)
    local frameStroke = CreateStroke(frame)
    RegisterThemeElement(frameStroke, "Color", "Border")
    
    local header = CreateInstance("TextButton", {
        Name = "Header",
        Text = "",
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 0, s.Dropdown.Height),
        Parent = frame
    })
    
    local nameLabel = CreateInstance("TextLabel", {
        Name = "Name",
        FontFace = f.Regular,
        TextColor3 = c.Text,
        Text = name,
        TextXAlignment = Enum.TextXAlignment.Left,
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 10, 0, 0),
        TextSize = textsize.Normal,
        Size = UDim2.new(0.5, -10, 1, 0),
        Parent = header
    })
    RegisterThemeElement(nameLabel, "TextColor3", "Text")
    
    local valueLabel = CreateInstance("TextLabel", {
        Name = "Value",
        FontFace = f.Regular,
        TextColor3 = c.TextDark,
        Text = currentOption,
        TextXAlignment = Enum.TextXAlignment.Right,
        BackgroundTransparency = 1,
        Position = UDim2.new(0.5, 0, 0, 0),
        TextSize = textsize.Normal,
        TextTruncate = Enum.TextTruncate.AtEnd,
        Size = UDim2.new(0.5, -30, 1, 0),
        Parent = header
    })
    RegisterThemeElement(valueLabel, "TextColor3", "TextDark")
    
    local arrow = CreateInstance("TextLabel", {
        Name = "Arrow",
        FontFace = f.Bold,
        TextColor3 = c.TextDark,
        Text = "›",
        TextSize = 18,
        BackgroundTransparency = 1,
        AnchorPoint = Vector2.new(1, 0.5),
        Position = UDim2.new(1, -10, 0.5, 0),
        Size = UDim2.new(0, 20, 0, 20),
        Rotation = 90,
        Parent = header
    })
    RegisterThemeElement(arrow, "TextColor3", "TextDark")
    
    local optionsContainer = CreateInstance("Frame", {
        Name = "Options",
        BackgroundColor3 = c.Secondary,
        BackgroundTransparency = 0,
        BorderSizePixel = 0,
        Position = UDim2.new(0, 0, 0, s.Dropdown.Height + 5),
        Size = UDim2.new(1, 0, 0, 0),
        ClipsDescendants = true,
        Visible = false,
        ZIndex = 100,
        Parent = frame
    })
    RegisterThemeElement(optionsContainer, "BackgroundColor3", "Secondary")
    
    CreateCorner(optionsContainer, 5)
    local optionsStroke = CreateStroke(optionsContainer)
    RegisterThemeElement(optionsStroke, "Color", "Border")
    
    local optionsList = CreateInstance("Frame", {
        Name = "List",
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 1, 0),
        Parent = optionsContainer
    })
    
    CreateListLayout(optionsList, 2)
    CreatePadding(optionsList, 5, 5, 5, 5)
    
    local function CreateOption(option)
        local optionBtn = CreateInstance("TextButton", {
            Name = "Option_" .. option,
            Text = option,
            FontFace = f.Regular,
            TextColor3 = c.Text,
            TextSize = textsize.Small,
            TextXAlignment = Enum.TextXAlignment.Left,
            BackgroundColor3 = c.Secondary,
            BackgroundTransparency = 0.9,
            BorderSizePixel = 0,
            Size = UDim2.new(1, 0, 0, s.Dropdown.OptionHeight),
            Parent = optionsList
        })
        RegisterThemeElement(optionBtn, "TextColor3", "Text")
        RegisterThemeElement(optionBtn, "BackgroundColor3", "Secondary")
        
        CreateCorner(optionBtn, 4)
        CreatePadding(optionBtn, 0, 0, 8, 8)
        
        optionBtn.MouseButton1Click:Connect(function()
            currentOption = option
            valueLabel.Text = option
            expanded = false
            
            CreateTween(optionsContainer, {Size = UDim2.new(1, 0, 0, 0)}, animationspeed.Fast)
            CreateTween(arrow, {Rotation = 90}, animationspeed.Fast)
            task.wait(animationspeed.Fast)
            optionsContainer.Visible = false
            
            callback(option)
        end)
        
        optionBtn.MouseEnter:Connect(function()
            CreateTween(optionBtn, {BackgroundTransparency = 0.6}, animationspeed.Fast)
        end)
        
        optionBtn.MouseLeave:Connect(function()
            CreateTween(optionBtn, {BackgroundTransparency = 0.9}, animationspeed.Fast)
        end)
    end
    
    for _, option in ipairs(options) do
        CreateOption(option)
    end
    
    local function ToggleDropdown()
        expanded = not expanded
        
        if expanded then
            optionsContainer.Visible = true
            local height = math.min(#options * (s.Dropdown.OptionHeight + 2) + 10, 200)
            CreateTween(optionsContainer, {Size = UDim2.new(1, 0, 0, height)}, animationspeed.Normal)
            CreateTween(arrow, {Rotation = -90}, animationspeed.Fast)
        else
            CreateTween(optionsContainer, {Size = UDim2.new(1, 0, 0, 0)}, animationspeed.Fast)
            CreateTween(arrow, {Rotation = 90}, animationspeed.Fast)
            task.wait(animationspeed.Fast)
            optionsContainer.Visible = false
        end
    end
    
    header.MouseButton1Click:Connect(ToggleDropdown)
    
    frame.MouseEnter:Connect(function()
        if not expanded then
            CreateTween(frame, {BackgroundTransparency = 0.2}, animationspeed.Fast)
        end
    end)
    
    frame.MouseLeave:Connect(function()
        if not expanded then
            CreateTween(frame, {BackgroundTransparency = 0.4}, animationspeed.Fast)
        end
    end)
    
    local methods = {
        SetValue = function(_, value)
            for _, option in ipairs(options) do
                if option == value then
                    currentOption = value
                    valueLabel.Text = value
                    callback(value)
                    break
                end
            end
        end,
        GetValue = function()
            return currentOption
        end,
        Refresh = function(_, newOptions)
            options = newOptions or {}
            for _, child in ipairs(optionsList:GetChildren()) do
                if child:IsA("TextButton") then
                    child:Destroy()
                end
            end
            for _, option in ipairs(options) do
                CreateOption(option)
            end
            if not table.find(options, currentOption) and options[1] then
                currentOption = options[1]
                valueLabel.Text = currentOption
                callback(currentOption)
            end
        end
    }
    
    if flag and tab._library then
        tab._library:_RegisterConfigElement(flag, "Dropdown", 
            function() return currentOption end,
            function(value) methods:SetValue(value) end
        )
    end
    
    return methods
end

function Library._CreateColorPicker(tab, config)
    local name = config.Name or "Color Picker"
    local default = config.Default or Color3.fromRGB(255, 255, 255)
    local callback = config.Callback or function() end
    local flag = config.Flag
    local currentColor = default
    local hue, sat, val = default:ToHSV()
    local expanded = false
    
    local frame = CreateInstance("Frame", {
        Name = "ColorPicker_" .. name,
        BackgroundColor3 = c.Secondary,
        BackgroundTransparency = 0.4,
        BorderSizePixel = 0,
        Size = UDim2.new(1, 0, 0, s.Button.Height),
        Parent = tab.content
    })
    RegisterThemeElement(frame, "BackgroundColor3", "Secondary")
    
    CreateCorner(frame, 5)
    local frameStroke = CreateStroke(frame)
    RegisterThemeElement(frameStroke, "Color", "Border")
    
    local nameLabel = CreateInstance("TextLabel", {
        Name = "Name",
        FontFace = f.Regular,
        TextColor3 = c.Text,
        Text = name,
        TextXAlignment = Enum.TextXAlignment.Left,
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 10, 0, 0),
        TextSize = textsize.Normal,
        Size = UDim2.new(1, -60, 1, 0),
        Parent = frame
    })
    RegisterThemeElement(nameLabel, "TextColor3", "Text")
    
    local previewBtn = CreateInstance("TextButton", {
        Name = "Preview",
        Text = "",
        BackgroundColor3 = currentColor,
        BorderSizePixel = 0,
        AnchorPoint = Vector2.new(1, 0.5),
        Position = UDim2.new(1, -10, 0.5, 0),
        Size = UDim2.new(0, 35, 0, 25),
        Parent = frame
    })
    
    CreateCorner(previewBtn, 4)
    local previewStroke = CreateStroke(previewBtn, c.Border, 0)
    RegisterThemeElement(previewStroke, "Color", "Border")
    
    local pickerContainer = CreateInstance("Frame", {
        Name = "PickerContainer",
        BackgroundColor3 = c.Secondary,
        BorderSizePixel = 0,
        Position = UDim2.new(0, 0, 0, 0),
        Size = UDim2.new(0, s.ColorPicker.Width, 0, s.ColorPicker.Height),
        Visible = false,
        ZIndex = 1000,
        Parent = tab.content.Parent.Parent
    })
    RegisterThemeElement(pickerContainer, "BackgroundColor3", "Secondary")
    
    CreateCorner(pickerContainer, 6)
    local pickerStroke = CreateStroke(pickerContainer)
    RegisterThemeElement(pickerStroke, "Color", "Border")
    
    local satValPicker = CreateInstance("ImageButton", {
        Name = "SatValPicker",
        Image = "rbxassetid://4155801252",
        ImageColor3 = Color3.fromHSV(hue, 1, 1),
        BackgroundColor3 = Color3.new(1, 1, 1),
        BorderSizePixel = 0,
        Position = UDim2.new(0, 10, 0, 10),
        Size = UDim2.new(1, -20, 0, 100),
        Parent = pickerContainer
    })
    
    CreateCorner(satValPicker, 4)
    
    local satValCursor = CreateInstance("Frame", {
        Name = "Cursor",
        BackgroundColor3 = Color3.new(1, 1, 1),
        BorderSizePixel = 0,
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.new(sat, 0, 1 - val, 0),
        Size = UDim2.new(0, 8, 0, 8),
        Parent = satValPicker
    })
    
    CreateCorner(satValCursor, 20)
    CreateStroke(satValCursor, Color3.new(0, 0, 0), 0)
    
    local huePicker = CreateInstance("ImageButton", {
        Name = "HuePicker",
        Image = "rbxassetid://3641079629",
        ImageColor3 = Color3.new(1, 1, 1),
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 10, 0, 120),
        Size = UDim2.new(1, -20, 0, 15),
        Parent = pickerContainer
    })
    
    CreateCorner(huePicker, 4)
    
    local hueCursor = CreateInstance("Frame", {
        Name = "Cursor",
        BackgroundColor3 = Color3.new(1, 1, 1),
        BorderSizePixel = 0,
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.new(hue, 0, 0.5, 0),
        Size = UDim2.new(0, 3, 1, 4),
        Parent = huePicker
    })
    
    CreateCorner(hueCursor, 20)
    CreateStroke(hueCursor, Color3.new(0, 0, 0), 0)
    
    local function UpdateColor()
        currentColor = Color3.fromHSV(hue, sat, val)
        previewBtn.BackgroundColor3 = currentColor
        satValPicker.ImageColor3 = Color3.fromHSV(hue, 1, 1)
        callback(currentColor)
    end
    
    local satValDragging = false
    satValPicker.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            satValDragging = true
        end
    end)
    
    satValPicker.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            satValDragging = false
        end
    end)
    
    ui.InputChanged:Connect(function(input)
        if satValDragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            local posX = math.clamp((input.Position.X - satValPicker.AbsolutePosition.X) / satValPicker.AbsoluteSize.X, 0, 1)
            local posY = math.clamp((input.Position.Y - satValPicker.AbsolutePosition.Y) / satValPicker.AbsoluteSize.Y, 0, 1)
            sat = posX
            val = 1 - posY
            satValCursor.Position = UDim2.new(sat, 0, 1 - val, 0)
            UpdateColor()
        end
    end)
    
    local hueDragging = false
    huePicker.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            hueDragging = true
        end
    end)
    
    huePicker.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            hueDragging = false
        end
    end)
    
    ui.InputChanged:Connect(function(input)
        if hueDragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            local posX = math.clamp((input.Position.X - huePicker.AbsolutePosition.X) / huePicker.AbsoluteSize.X, 0, 1)
            hue = posX
            hueCursor.Position = UDim2.new(hue, 0, 0.5, 0)
            UpdateColor()
        end
    end)
    
    local function ClosePicker()
        pickerContainer.Visible = false
        expanded = false
    end
    
    local function OpenPicker()
        local btnPos = previewBtn.AbsolutePosition
        local viewport = workspace.CurrentCamera.ViewportSize
        
        local targetX = btnPos.X - s.ColorPicker.Width + 45
        local targetY = btnPos.Y + 30

        if targetY + 115 > viewport.Y then
            targetY = viewport.Y - 125
        end
        if targetX < 0 then
            targetX = btnPos.X + 50
        end

        pickerContainer.Position = UDim2.new(0, targetX, 0, targetY)
        pickerContainer.Visible = true
        expanded = true
    end

    previewBtn.MouseButton1Click:Connect(function()
        if expanded then
            ClosePicker()
        else
            OpenPicker()
        end
    end)

    local methods = {
        SetColor = function(_, color)
            currentColor = color
            hue, sat, val = color:ToHSV()
            UpdateColor()
        end,
        GetColor = function()
            return currentColor
        end
    }

    if flag and tab._library then
        tab._library:_RegisterConfigElement(flag, "ColorPicker", 
            function() return currentColor end,
            function(value) methods:SetColor(value) end
        )
    end

    return methods
end

function Library._CreateTextBox(tab, config)
    local name = config.Name or "TextBox"
    local default = config.Default or ""
    local placeholder = config.Placeholder or "Enter text..."
    local callback = config.Callback or function() end
    local clearOnFocus = config.ClearOnFocus or false
    local numbersOnly = config.NumbersOnly or false
    local flag = config.Flag
    local currentText = default

    local frame = CreateInstance("Frame", {
        Name = "TextBox_" .. name,
        BackgroundColor3 = c.Secondary,
        BackgroundTransparency = 0.4,
        BorderSizePixel = 0,
        Size = UDim2.new(1, 0, 0, s.TextBox.Height),
        Parent = tab.content
    })
    RegisterThemeElement(frame, "BackgroundColor3", "Secondary")
    
    CreateCorner(frame, 5)
    local frameStroke = CreateStroke(frame)
    RegisterThemeElement(frameStroke, "Color", "Border")

    local nameLabel = CreateInstance("TextLabel", {
        Name = "Name",
        FontFace = f.Regular,
        TextColor3 = c.Text,
        Text = name,
        TextXAlignment = Enum.TextXAlignment.Left,
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 10, 0.5, -10),
        TextSize = textsize.Normal,
        Size = UDim2.new(0, 150, 0, 20),
        Parent = frame
    })
    RegisterThemeElement(nameLabel, "TextColor3", "Text")

    local icon = CreateInstance("ImageLabel", {
        Name = "Icon",
        BackgroundTransparency = 1,
        Image = "rbxassetid://93828793199781",
        ImageColor3 = c.TextDark,
        AnchorPoint = Vector2.new(1, 0.5),
        Position = UDim2.new(1, -165, 0.5, 0),
        Size = UDim2.new(0, 18, 0, 18),
        Parent = frame
    })
    RegisterThemeElement(icon, "ImageColor3", "TextDark")

    local textBoxContainer = CreateInstance("Frame", {
        Name = "TextBoxContainer",
        BackgroundColor3 = c.Secondary,
        BackgroundTransparency = 0.04,
        AnchorPoint = Vector2.new(1, 0.5),
        Position = UDim2.new(1, -10, 0.5, 0),
        BorderSizePixel = 0,
        Size = UDim2.new(0, s.TextBox.InputWidth, 0, 26),
        Parent = frame
    })
    RegisterThemeElement(textBoxContainer, "BackgroundColor3", "Secondary")
    
    CreateCorner(textBoxContainer, 5)
    local textBoxStroke = CreateStroke(textBoxContainer)
    RegisterThemeElement(textBoxStroke, "Color", "Border")

    local textBox = CreateInstance("TextBox", {
        Name = "Input",
        FontFace = f.Regular,
        TextColor3 = c.Text,
        PlaceholderText = placeholder,
        PlaceholderColor3 = c.TextDark,
        Text = currentText,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextTruncate = Enum.TextTruncate.AtEnd,
        BackgroundTransparency = 1,
        TextSize = textsize.Small,
        Size = UDim2.new(1, -16, 1, 0),
        Position = UDim2.new(0, 8, 0, 0),
        ClearTextOnFocus = clearOnFocus,
        Parent = textBoxContainer
    })
    RegisterThemeElement(textBox, "TextColor3", "Text")
    RegisterThemeElement(textBox, "PlaceholderColor3", "TextDark")

    textBox.Focused:Connect(function()
        CreateTween(textBoxContainer, {BackgroundTransparency = 0}, animationspeed.Fast)
        CreateTween(textBoxStroke, {Color = c.Accent}, animationspeed.Fast)
        CreateTween(icon, {ImageColor3 = c.Text}, animationspeed.Fast)
    end)

    textBox.FocusLost:Connect(function(enterPressed)
        CreateTween(textBoxContainer, {BackgroundTransparency = 0.04}, animationspeed.Fast)
        CreateTween(textBoxStroke, {Color = c.Border}, animationspeed.Fast)
        CreateTween(icon, {ImageColor3 = c.TextDark}, animationspeed.Fast)
        
        if numbersOnly then
            local numValue = tonumber(textBox.Text)
            if numValue then
                currentText = tostring(numValue)
                textBox.Text = currentText
            else
                textBox.Text = currentText
            end
        else
            currentText = textBox.Text
        end
        
        callback(currentText, enterPressed)
    end)

    if numbersOnly then
        textBox:GetPropertyChangedSignal("Text"):Connect(function()
            local text = textBox.Text
            local filtered = text:gsub("[^%d%.%-]", "")
            if text ~= filtered then
                textBox.Text = filtered
            end
        end)
    end

    local methods = {
        SetText = function(_, text)
            currentText = tostring(text)
            textBox.Text = currentText
        end,
        GetText = function()
            return currentText
        end,
        SetPlaceholder = function(_, newPlaceholder)
            textBox.PlaceholderText = newPlaceholder
        end,
        Focus = function()
            textBox:CaptureFocus()
        end
    }

    if flag and tab._library then
        tab._library:_RegisterConfigElement(flag, "TextBox", 
            function() return currentText end,
            function(value) methods:SetText(value) end
        )
    end

    return methods
end

function Library._CreateConfigSection(tab)
    local lib = tab._library
    
    Library._CreateContentSection(tab, "Configuration")

    local configNameBox = Library._CreateTextBox(tab, {
        Name = "Config Name",
        Default = "default",
        Placeholder = "Enter config name...",
        Callback = function(text)
            lib._currentConfig = text
        end
    })

    local configDropdown
    configDropdown = Library._CreateDropdown(tab, {
        Name = "Select Config",
        Options = lib:GetConfigs(),
        Default = "default",
        Callback = function(selected)
            configNameBox:SetText(selected)
            lib._currentConfig = selected
        end
    })

    Library._CreateButton(tab, {
        Name = "Save Config",
        Callback = function()
            local configName = configNameBox:GetText()
            if configName and configName ~= "" then
                lib:SaveConfig(configName)
                configDropdown:Refresh(lib:GetConfigs())
            end
        end
    })

    Library._CreateButton(tab, {
        Name = "Load Config",
        Callback = function()
            local configName = configNameBox:GetText()
            if configName and configName ~= "" then
                lib:LoadConfig(configName)
            end
        end
    })

    Library._CreateButton(tab, {
        Name = "Delete Config",
        Callback = function()
            local configName = configNameBox:GetText()
            if configName and configName ~= "" then
                lib:DeleteConfig(configName)
                configDropdown:Refresh(lib:GetConfigs())
            end
        end
    })

    Library._CreateButton(tab, {
        Name = "Refresh Configs",
        Callback = function()
            configDropdown:Refresh(lib:GetConfigs())
            lib:Notify({
                Title = "Configs Refreshed",
                Description = "Config list updated",
                Duration = 2,
                Icon = "rbxassetid://10723356507"
            })
        end
    })

    Library._CreateToggle(tab, {
        Name = "Auto Save",
        Default = false,
        Callback = function(enabled)
            lib:SetAutoSave(enabled)
        end
    })
    
    -- NOVO: Adicionar seletor de tema
    Library._CreateContentSection(tab, "Theme")
    
    Library._CreateDropdown(tab, {
        Name = "Select Theme",
        Options = {"Dark", "Light"},
        Default = CurrentTheme,
        Callback = function(selected)
            ApplyTheme(selected)
            lib:Notify({
                Title = "Theme Changed",
                Description = "Theme set to " .. selected,
                Duration = 2,
                Icon = "rbxassetid://10723356507"
            })
        end
    })

    return {
        RefreshConfigs = function()
            configDropdown:Refresh(lib:GetConfigs())
        end
    }
end

function Library:_RegisterConfigElement(flag, elementType, getValue, setValue)
    self._configElements[flag] = {
        Type = elementType,
        Get = getValue,
        Set = setValue
    }
end

function Library:SaveConfig(configName)
    EnsureConfigFolder()
    
    local configData = {
        Theme = CurrentTheme,
        Elements = {}
    }
    
    for flag, element in pairs(self._configElements) do
        configData.Elements[flag] = element.Get()
    end
    
    local success, encoded = pcall(function()
        return hs:JSONEncode(configData)
    end)
    
    if success and writefile then
        writefile(GetConfigFolder(configName) .. ".json", encoded)
        self:Notify({
            Title = "Config Saved",
            Description = "Configuration '" .. configName .. "' saved successfully",
            Duration = 3,
            Icon = "rbxassetid://10723356507"
        })
        return true
    end
    
    return false
end

function Library:LoadConfig(configName)
    local filePath = GetConfigFolder(configName) .. ".json"
    
    if not isfile or not readfile or not isfile(filePath) then
        self:Notify({
            Title = "Load Failed",
            Description = "Config '" .. configName .. "' not found",
            Duration = 3,
            Icon = "rbxassetid://10723356507"
        })
        return false
    end
    
    local success, decoded = pcall(function()
        return hs:JSONDecode(readfile(filePath))
    end)
    
    if success and decoded then
        -- Aplicar tema salvo
        if decoded.Theme and Themes[decoded.Theme] then
            ApplyTheme(decoded.Theme)
        end
        
        -- Aplicar configurações dos elementos
        if decoded.Elements then
            for flag, value in pairs(decoded.Elements) do
                if self._configElements[flag] then
                    pcall(function()
                        self._configElements[flag].Set(value)
                    end)
                end
            end
        end
        
        self:Notify({
            Title = "Config Loaded",
            Description = "Configuration '" .. configName .. "' loaded successfully",
            Duration = 3,
            Icon = "rbxassetid://10723356507"
        })
        return true
    end
    
    return false
end

function Library:DeleteConfig(configName)
    local filePath = GetConfigFolder(configName) .. ".json"
    
    if delfile and isfile and isfile(filePath) then
        delfile(filePath)
        self:Notify({
            Title = "Config Deleted",
            Description = "Configuration '" .. configName .. "' deleted",
            Duration = 3,
            Icon = "rbxassetid://10723356507"
        })
        return true
    end
    
    return false
end

function Library:GetConfigs()
    return GetAvailableConfigs()
end

function Library:SetAutoSave(enabled)
    self._autoSave = enabled
    
    if enabled and self._currentConfig then
        if self._autoSaveConnection then
            self._autoSaveConnection:Disconnect()
        end
        
        self._autoSaveConnection = rs.Heartbeat:Connect(function()
            task.wait(30)
            self:SaveConfig(self._currentConfig)
        end)
    elseif self._autoSaveConnection then
        self._autoSaveConnection:Disconnect()
        self._autoSaveConnection = nil
    end
end

function Library:Notify(config)
    local title = config.Title or "Notification"
    local description = config.Description or ""
    local duration = config.Duration or 3
    local icon = config.Icon
    
    if not NotificationContainer then
        NotificationContainer = CreateInstance("Frame", {
            Name = "NotificationContainer",
            BackgroundTransparency = 1,
            Position = UDim2.new(1, -230, 0, 10),
            Size = UDim2.new(0, s.Notification.Width, 1, -20),
            Parent = self.gui or game.CoreGui:FindFirstChild(n)
        })
        
        CreateListLayout(NotificationContainer, 10, Enum.SortOrder.LayoutOrder, Enum.FillDirection.Vertical)
    end
    
    local notification = CreateInstance("Frame", {
        Name = "Notification",
        BackgroundColor3 = c.Notification.Background,
        BorderSizePixel = 0,
        Size = UDim2.new(1, 0, 0, s.Notification.Height),
        BackgroundTransparency = 1,
        Parent = NotificationContainer
    })
    RegisterThemeElement(notification, "BackgroundColor3", "Notification", "Background")
    
    CreateCorner(notification, 6)
    local notifStroke = CreateStroke(notification, c.Notification.Border)
    RegisterThemeElement(notifStroke, "Color", "Notification", "Border")
    
    local content = CreateInstance("Frame", {
        Name = "Content",
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 1, 0),
        Parent = notification
    })
    
    CreatePadding(content, 10, 10, icon and 45 or 10, 10)
    
    if icon then
        local iconImage = CreateInstance("ImageLabel", {
            Name = "Icon",
            Image = icon,
            ImageColor3 = c.Text,
            BackgroundTransparency = 1,
            Position = UDim2.new(0, 10, 0, 10),
            Size = UDim2.new(0, 25, 0, 25),
            Parent = notification
        })
        RegisterThemeElement(iconImage, "ImageColor3", "Text")
    end
    
    local titleLabel = CreateInstance("TextLabel", {
        Name = "Title",
        Text = title,
        FontFace = f.Bold,
        TextColor3 = c.Text,
        TextSize = textsize.Normal,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextYAlignment = Enum.TextYAlignment.Top,
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 0, 16),
        Parent = content
    })
    RegisterThemeElement(titleLabel, "TextColor3", "Text")
    
    local descLabel = CreateInstance("TextLabel", {
        Name = "Description",
        Text = description,
        FontFace = f.Regular,
        TextColor3 = c.TextDark,
        TextSize = textsize.Small,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextYAlignment = Enum.TextYAlignment.Top,
        TextWrapped = true,
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 0, 0, 18),
        Size = UDim2.new(1, 0, 1, -18),
        Parent = content
    })
    RegisterThemeElement(descLabel, "TextColor3", "TextDark")
    
    local timer = CreateInstance("Frame", {
        Name = "Timer",
        BackgroundColor3 = c.Notification.Timer,
        BorderSizePixel = 0,
        Position = UDim2.new(0, 0, 1, -2),
        Size = UDim2.new(1, 0, 0, 2),
        Parent = notification
    })
    RegisterThemeElement(timer, "BackgroundColor3", "Notification", "Timer")
    
    CreateTween(notification, {BackgroundTransparency = 0}, animationspeed.Normal)
    CreateTween(timer, {Size = UDim2.new(0, 0, 0, 2)}, duration, Enum.EasingStyle.Linear)
    
    task.delay(duration, function()
        CreateTween(notification, {BackgroundTransparency = 1}, animationspeed.Normal)
        task.wait(animationspeed.Normal)
        notification:Destroy()
    end)
end

-- NOVA FUNÇÃO PÚBLICA: Permite mudar o tema programaticamente
function Library:SetTheme(themeName)
    if Themes[themeName] then
        ApplyTheme(themeName)
        return true
    end
    return false
end

-- NOVA FUNÇÃO PÚBLICA: Retorna o tema atual
function Library:GetCurrentTheme()
    return CurrentTheme
end

-- NOVA FUNÇÃO PÚBLICA: Retorna todos os temas disponíveis
function Library:GetAvailableThemes()
    local themeList = {}
    for themeName, _ in pairs(Themes) do
        table.insert(themeList, themeName)
    end
    return themeList
end

function Library:Destroy()
    DisconnectAll()
    if self.gui then
        self.gui:Destroy()
    end
    if NotificationContainer then
        NotificationContainer:Destroy()
        NotificationContainer = nil
    end
end

return Library
