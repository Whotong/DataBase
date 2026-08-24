--!strict
-- Re: Hub GUI Library v2.0 "Obsidian"
-- Flat near-black surfaces, hairline strokes, electric accent.
-- Runtime theming: Library:SetTheme(nameOrTable) / SetTransparency(t)

local Library = {}
Library.__index = Library

-- ═══════════════════════════════════════════
-- SERVICES
-- ═══════════════════════════════════════════
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local HttpService = game:GetService("HttpService")

local LocalPlayer = Players.LocalPlayer

-- ═══════════════════════════════════════════
-- MOTION TOKENS
-- ═══════════════════════════════════════════
local Motion = {
	Fast = TweenInfo.new(0.08, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
	Base = TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
	Slow = TweenInfo.new(0.25, Enum.EasingStyle.Quart, Enum.EasingDirection.Out),
	Spring = TweenInfo.new(0.18, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
	Exit = TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
}

-- ═══════════════════════════════════════════
-- THEME (Obsidian)
-- ═══════════════════════════════════════════
local Theme: {[string]: any} = {
	Name = "Violet",
	Background = Color3.fromRGB(11, 11, 14),     -- #0B0B0E window
	SurfaceAlt = Color3.fromRGB(15, 15, 19),     -- #0F0F13 topbar/sidebar
	Surface = Color3.fromRGB(18, 18, 22),        -- #121216 sections
	Item = Color3.fromRGB(26, 27, 33),           -- #1A1B21 buttons/inputs
	ItemHover = Color3.fromRGB(35, 36, 44),      -- #23242C
	Stroke = Color3.fromRGB(38, 39, 46),         -- #26272E hairlines
	TrackOff = Color3.fromRGB(42, 43, 51),       -- #2A2B33 toggle-off/slider track
	Scrollbar = Color3.fromRGB(42, 43, 51),
	Text = Color3.fromRGB(242, 242, 245),        -- #F2F2F5
	Subtext = Color3.fromRGB(154, 154, 165),     -- #9A9AA5
	Accent = Color3.fromRGB(124, 127, 255),      -- #7C7FFF violet
	AccentHover = Color3.fromRGB(148, 142, 255), -- #948EFF
	AccentPress = Color3.fromRGB(102, 99, 230),  -- #6663E6
	Danger = Color3.fromRGB(255, 95, 87),        -- close dot
	Warn = Color3.fromRGB(254, 188, 46),         -- minimize dot
}

local Presets: {[string]: any} = {
	Violet = {
		Accent = Color3.fromRGB(124, 127, 255),
		AccentHover = Color3.fromRGB(148, 142, 255),
		AccentPress = Color3.fromRGB(102, 99, 230),
	},
	Cyan = {
		Accent = Color3.fromRGB(34, 211, 238),
		AccentHover = Color3.fromRGB(103, 232, 249),
		AccentPress = Color3.fromRGB(14, 165, 233),
	},
	Mint = {
		Accent = Color3.fromRGB(52, 211, 153),
		AccentHover = Color3.fromRGB(110, 231, 183),
		AccentPress = Color3.fromRGB(16, 185, 129),
	},
	Amber = {
		Accent = Color3.fromRGB(251, 191, 36),
		AccentHover = Color3.fromRGB(253, 212, 105),
		AccentPress = Color3.fromRGB(217, 119, 6),
	},
	Rose = {
		Accent = Color3.fromRGB(251, 113, 133),
		AccentHover = Color3.fromRGB(253, 164, 175),
		AccentPress = Color3.fromRGB(225, 29, 72),
	},
}

-- Style registry: entries applied on every theme/transparency change
local StyleReg: {[number]: any} = {}   -- {inst, prop, role, baseT}
local HookReg: {[number]: any} = {}    -- functions re-applying stateful styles
local ActiveWindow = nil               -- set by :Start for tab-state hooks

local CurrentT = 0

local function reg(inst: any, prop: string, role: string, baseT: number?)
	table.insert(StyleReg, { inst = inst, prop = prop, role = role, baseT = baseT or 0 })
	inst[prop] = Theme[role]
	if baseT then
		inst[(prop == "ScrollBarImageColor3") and "ScrollBarImageTransparency" or "BackgroundTransparency"] = baseT
	end
end

local function hook(fn: () -> ())
	table.insert(HookReg, fn)
	fn()
end

-- Transparency only softens the big surface fills; items stay solid for readability.
local function roleTransparency(role: string, baseT: number): number
	if CurrentT <= 0 then return baseT end
	if role == "Background" then
		return math.min(0.55, baseT + CurrentT * 0.55)
	elseif role == "Surface" or role == "SurfaceAlt" then
		return math.min(0.5, baseT + CurrentT * 0.45)
	end
	return baseT
end

local function refreshStyles()
	for i = #StyleReg, 1, -1 do
		local e = StyleReg[i]
		local ok = pcall(function()
			e.inst[e.prop] = Theme[e.role]
			if e.prop == "BackgroundColor3" then
				e.inst.BackgroundTransparency = roleTransparency(e.role, e.baseT)
			elseif e.prop == "ScrollBarImageColor3" then
				e.inst.ScrollBarImageTransparency = e.baseT
			end
		end)
		if not ok then
			table.remove(StyleReg, i)
		end
	end
	for i = #HookReg, 1, -1 do
		local ok = pcall(HookReg[i])
		if not ok then
			table.remove(HookReg, i)
		end
	end
end

-- ═══════════════════════════════════════════
-- FONTS
-- ═══════════════════════════════════════════
local Fonts = {
	Title = Enum.Font.GothamBold,
	ItemTitle = Enum.Font.GothamSemibold,
	Body = Enum.Font.GothamMedium,
	Small = Enum.Font.Gotham,
}

-- ═══════════════════════════════════════════
-- UTILITY
-- ═══════════════════════════════════════════
local function Create(className: string, props: {[string]: any}): Instance
	local inst = Instance.new(className)
	for k, v in pairs(props) do
		if k ~= "Parent" and k ~= "Children" then
			(inst :: any)[k] = v
		end
	end
	if props.Children then
		for _, child in ipairs(props.Children) do
			child.Parent = inst
		end
	end
	if props.Parent then
		inst.Parent = props.Parent
	end
	return inst
end

local function Round(num: number, factor: number): number
	local result = math.floor(num / factor + (math.sign(num) * 0.5)) * factor
	if result < 0 then result = result + factor end
	return result
end

local function MakeDraggable(topbar: Frame, frame: Frame)
	local dragging, dragStart, startPos
	topbar.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			dragging = true
			dragStart = input.Position
			startPos = frame.Position
		end
	end)
	UserInputService.InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			dragging = false
		end
	end)
	UserInputService.InputChanged:Connect(function(input)
		if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
			local delta = input.Position - dragStart
			frame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
		end
	end)
end

local function CircleClick(button: GuiObject, x: number, y: number)
	task.spawn(function()
		local circle = Create("ImageLabel", {
			Image = "rbxassetid://266543268",
			ImageColor3 = Theme.Accent,
			ImageTransparency = 0.85,
			BackgroundTransparency = 1,
			ZIndex = 100,
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.new(0, x - button.AbsolutePosition.X, 0, y - button.AbsolutePosition.Y),
			Parent = button,
		})
		local size = math.max(button.AbsoluteSize.X, button.AbsoluteSize.Y) * 1.5
		TweenService:Create(circle, Motion.Slow, {
			Size = UDim2.new(0, size, 0, size),
			ImageTransparency = 1,
		}):Play()
		task.wait(0.25)
		circle:Destroy()
	end)
end

local function MouseLocation(): Vector2
	return UserInputService:GetMouseLocation()
end

-- ═══════════════════════════════════════════
-- NOTIFICATION SYSTEM
-- ═══════════════════════════════════════════
local NotifContainer: Frame? = nil

local function EnsureNotifContainer(): Frame
	if NotifContainer then return NotifContainer end
	NotifContainer = Create("Frame", {
		Name = "ReHubNotifications",
		AnchorPoint = Vector2.new(1, 1),
		Position = UDim2.new(1, -16, 1, -16),
		Size = UDim2.new(0, 300, 0, 0),
		BackgroundTransparency = 1,
		Parent = LocalPlayer:WaitForChild("PlayerGui"),
	}) :: Frame
	Create("UIListLayout", {
		SortOrder = Enum.SortOrder.LayoutOrder,
		VerticalAlignment = Enum.VerticalAlignment.Bottom,
		Padding = UDim.new(0, 8),
		Parent = NotifContainer,
	})
	return NotifContainer
end

function Library:Notify(config: any)
	config = config or {}
	local title: string = config.Title or "Re: Hub"
	local content: string = config.Content or ""
	local color: Color3 = config.Color or Theme.Accent
	local delayTime: number = config.Delay or 4

	local container = EnsureNotifContainer()

	local notif = Create("Frame", {
		Name = "Notification",
		Size = UDim2.new(1, 0, 0, 56),
		BackgroundColor3 = Theme.Surface,
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		ClipsDescendants = true,
		Parent = container,
	})
	Create("UICorner", { CornerRadius = UDim.new(0, 8), Parent = notif })
	reg(notif, "BackgroundColor3", "Surface")
	Create("UIStroke", { Color = Theme.Stroke, Thickness = 1, Parent = notif })
	local notifStroke = notif:FindFirstChildOfClass("UIStroke")
	reg(notifStroke, "Color", "Stroke")

	Create("Frame", {
		Name = "AccentBar",
		Size = UDim2.new(0, 3, 1, 0),
		BackgroundColor3 = color,
		BorderSizePixel = 0,
		Parent = notif,
	})

	Create("TextLabel", {
		Name = "Title",
		Position = UDim2.new(0, 12, 0, 9),
		Size = UDim2.new(1, -24, 0, 16),
		BackgroundTransparency = 1,
		Text = title,
		TextColor3 = Theme.Text,
		Font = Fonts.Title,
		TextSize = 12,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextTruncate = Enum.TextTruncate.AtEnd,
		Parent = notif,
	})

	Create("TextLabel", {
		Name = "Content",
		Position = UDim2.new(0, 12, 0, 28),
		Size = UDim2.new(1, -24, 0, 22),
		BackgroundTransparency = 1,
		Text = content,
		TextColor3 = Theme.Subtext,
		Font = Fonts.Small,
		TextSize = 11,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextWrapped = true,
		Parent = notif,
	})

	-- Slide in from the right
	notif.Position = UDim2.new(0, 320, 0, 0)
	TweenService:Create(notif, Motion.Slow, { Position = UDim2.new(0, 0, 0, 0) }):Play()
	TweenService:Create(notif, Motion.Base, { BackgroundTransparency = 0 }):Play()

	-- Auto-remove
	task.delay(delayTime, function()
		TweenService:Create(notif, Motion.Exit, { Position = UDim2.new(0, 340, 0, 0) }):Play()
		TweenService:Create(notif, Motion.Exit, { BackgroundTransparency = 1 }):Play()
		task.wait(0.2)
		notif:Destroy()
	end)
end

-- ═══════════════════════════════════════════
-- WINDOW
-- ═══════════════════════════════════════════
local SIDEBAR_W = 140
local TOPBAR_H = 44

function Library:Start(config: any)
	config = config or {}
	local windowName: string = config.Name or "Re: Hub"
	local accentColor: Color3? = config.Color
	local saveFolder: string? = config.SaveFolder
	local closeCallback: (() -> ())? = config.CloseCallBack

	if accentColor then
		-- Custom accent supplied: overlay it onto the current preset slot
		Theme.Accent = accentColor
		Theme.AccentHover = accentColor:Lerp(Color3.new(1, 1, 1), 0.2)
		Theme.AccentPress = accentColor:Lerp(Color3.new(0, 0, 0), 0.2)
		Presets.Custom = {
			Accent = accentColor,
			AccentHover = accentColor:Lerp(Color3.new(1, 1, 1), 0.2),
			AccentPress = accentColor:Lerp(Color3.new(0, 0, 0), 0.2),
		}
	end

	local self = setmetatable({}, { __index = Library })
	self._tabs = {}
	self._tabButtons = {}
	self._currentPage = nil
	self._saveFolder = saveFolder
	self._flags = {}
	ActiveWindow = self

	-- Load saved flags
	if saveFolder then
		local ok, data = pcall(function()
			return readfile(saveFolder .. ".json")
		end)
		if ok and data then
			local okDecode, decoded = pcall(function()
				return HttpService:JSONDecode(data)
			end)
			if okDecode and type(decoded) == "table" then
				self._flags = decoded
			end
		end
	end

	-- ScreenGui
	self._gui = Create("ScreenGui", {
		Name = "ReHubGui",
		ResetOnSpawn = false,
		ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
		DisplayOrder = 999,
		Parent = LocalPlayer:WaitForChild("PlayerGui"),
	})

	-- Main Frame
	self._mainFrame = Create("Frame", {
		Name = "MainFrame",
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.new(0.5, 0, 0.5, 0),
		Size = UDim2.new(0, 560, 0, 360),
		BackgroundColor3 = Theme.Background,
		BorderSizePixel = 0,
		Parent = self._gui,
	})
	Create("UICorner", { CornerRadius = UDim.new(0, 10), Parent = self._mainFrame })
	reg(self._mainFrame, "BackgroundColor3", "Background")
	local mainStroke = Create("UIStroke", { Color = Theme.Stroke, Thickness = 1, Parent = self._mainFrame })
	reg(mainStroke, "Color", "Stroke")

	-- Drop shadow
	Create("ImageLabel", {
		Name = "Shadow",
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.new(0.5, 0, 0.5, 4),
		Size = UDim2.new(1, 30, 1, 30),
		BackgroundTransparency = 1,
		Image = "rbxassetid://5554236805",
		ImageColor3 = Color3.fromRGB(0, 0, 0),
		ImageTransparency = 0.55,
		ScaleType = Enum.ScaleType.Slice,
		SliceCenter = Rect.new(23, 23, 277, 277),
		ZIndex = -1,
		Parent = self._mainFrame,
	})

	-- Top Bar
	self._topBar = Create("Frame", {
		Name = "TopBar",
		Size = UDim2.new(1, 0, 0, TOPBAR_H),
		BackgroundColor3 = Theme.SurfaceAlt,
		BorderSizePixel = 0,
		Parent = self._mainFrame,
	})
	Create("UICorner", { CornerRadius = UDim.new(0, 10), Parent = self._topBar })
	reg(self._topBar, "BackgroundColor3", "SurfaceAlt")
	-- Fix bottom corners of topbar
	Create("Frame", {
		Name = "BottomFix",
		Position = UDim2.new(0, 0, 1, -10),
		Size = UDim2.new(1, 0, 0, 10),
		BackgroundColor3 = Theme.SurfaceAlt,
		BorderSizePixel = 0,
		Parent = self._topBar,
	})
	reg(self._topBar.BottomFix, "BackgroundColor3", "SurfaceAlt")

	-- Accent dot + Title
	local accentDot = Create("Frame", {
		Name = "AccentDot",
		Position = UDim2.new(0, 14, 0.5, -3),
		Size = UDim2.new(0, 6, 0, 6),
		BackgroundColor3 = Theme.Accent,
		BorderSizePixel = 0,
		Parent = self._topBar,
	})
	Create("UICorner", { CornerRadius = UDim.new(1, 0), Parent = accentDot })
	reg(accentDot, "BackgroundColor3", "Accent")

	local titleLabel = Create("TextLabel", {
		Name = "Title",
		Position = UDim2.new(0, 28, 0, 0),
		Size = UDim2.new(0.5, 0, 1, 0),
		BackgroundTransparency = 1,
		Text = windowName,
		TextColor3 = Theme.Text,
		Font = Fonts.Title,
		TextSize = 14,
		TextXAlignment = Enum.TextXAlignment.Left,
		Parent = self._topBar,
	})
	reg(titleLabel, "TextColor3", "Text")

	-- Traffic lights
	local closeBtn = Create("TextButton", {
		Name = "CloseBtn",
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, -14, 0.5, 0),
		Size = UDim2.new(0, 12, 0, 12),
		BackgroundColor3 = Theme.Danger,
		BorderSizePixel = 0,
		Text = "",
		AutoButtonColor = false,
		Parent = self._topBar,
	})
	Create("UICorner", { CornerRadius = UDim.new(1, 0), Parent = closeBtn })
	reg(closeBtn, "BackgroundColor3", "Danger")

	local minBtn = Create("TextButton", {
		Name = "MinBtn",
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, -34, 0.5, 0),
		Size = UDim2.new(0, 12, 0, 12),
		BackgroundColor3 = Theme.Warn,
		BorderSizePixel = 0,
		Text = "",
		AutoButtonColor = false,
		Parent = self._topBar,
	})
	Create("UICorner", { CornerRadius = UDim.new(1, 0), Parent = minBtn })
	reg(minBtn, "BackgroundColor3", "Warn")

	closeBtn.MouseButton1Click:Connect(function()
		if self._gui then
			self._gui:Destroy()
		end
		if closeCallback then closeCallback() end
	end)

	minBtn.MouseButton1Click:Connect(function()
		self._mainFrame.Visible = false
	end)

	-- Sidebar
	self._sidebar = Create("Frame", {
		Name = "Sidebar",
		Position = UDim2.new(0, 0, 0, TOPBAR_H),
		Size = UDim2.new(0, SIDEBAR_W, 1, -TOPBAR_H),
		BackgroundColor3 = Theme.SurfaceAlt,
		BorderSizePixel = 0,
		Parent = self._mainFrame,
	})
	reg(self._sidebar, "BackgroundColor3", "SurfaceAlt")

	-- Sidebar separator line (parented to MainFrame so the sidebar's UIListLayout doesn't manage it)
	local sepLine = Create("Frame", {
		Name = "Separator",
		Position = UDim2.new(0, SIDEBAR_W, 0, TOPBAR_H),
		Size = UDim2.new(0, 1, 1, -TOPBAR_H),
		BackgroundColor3 = Theme.Stroke,
		BorderSizePixel = 0,
		Parent = self._mainFrame,
	})
	reg(sepLine, "BackgroundColor3", "Stroke")

	Create("UIListLayout", {
		SortOrder = Enum.SortOrder.LayoutOrder,
		Padding = UDim.new(0, 4),
		Parent = self._sidebar,
	})
	Create("UIPadding", {
		PaddingTop = UDim.new(0, 10),
		PaddingLeft = UDim.new(0, 8),
		PaddingRight = UDim.new(0, 8),
		Parent = self._sidebar,
	})

	-- Content Area
	self._content = Create("Frame", {
		Name = "Content",
		Position = UDim2.new(0, SIDEBAR_W, 0, TOPBAR_H),
		Size = UDim2.new(1, -SIDEBAR_W, 1, -TOPBAR_H),
		BackgroundTransparency = 1,
		Parent = self._mainFrame,
	})

	MakeDraggable(self._topBar, self._mainFrame)

	-- Re-show on double-click topbar (when minimized)
	local lastClick = 0
	self._topBar.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 then
			local now = tick()
			if now - lastClick < 0.3 then
				self._mainFrame.Visible = true
			end
			lastClick = now
		end
	end)

	-- Load notification
	self:Notify({
		Title = windowName,
		Content = "Loaded successfully",
		Delay = 3,
	})

	-- Initial style pass (registers made before Start still get picked up here)
	refreshStyles()

	return self
end

-- ═══════════════════════════════════════════
-- THEME API
-- ═══════════════════════════════════════════
-- Accepts a preset name ("Violet"|"Cyan"|...) or a partial theme table.
function Library:SetTheme(input: any)
	if type(input) == "string" and Presets[input] then
		for k, v in pairs(Presets[input]) do
			Theme[k] = v
		end
		Theme.Name = input
	elseif type(input) == "table" then
		for k, v in pairs(input) do
			Theme[k] = v
		end
		Theme.Name = (input :: any).Name or Theme.Name
	end
	refreshStyles()
end

function Library:GetThemeNames(): { string }
	local names = {}
	for name in pairs(Presets) do
		table.insert(names, name)
	end
	table.sort(names)
	return names
end

function Library:GetTheme(): {[string]: any}
	local copy = {}
	for k, v in pairs(Theme) do
		copy[k] = v
	end
	return copy
end

-- Accepts 0..1 (or 0..100, divided automatically).
function Library:SetTransparency(value: number)
	local t: number = value
	if t > 1 then t = t / 100 end
	CurrentT = math.clamp(t, 0, 1)
	refreshStyles()
end

-- ═══════════════════════════════════════════
-- TAB SYSTEM
-- ═══════════════════════════════════════════
local function applyTabState(entry: any)
	if entry.active then
		entry.btn.BackgroundColor3 = Theme.Item
		entry.label.TextColor3 = Theme.Text
		entry.indicator.BackgroundColor3 = Theme.Accent
	else
		entry.btn.BackgroundColor3 = Theme.Item
		entry.label.TextColor3 = Theme.Subtext
	end
end

function Library:MakeTab(name: string)
	local tab: any = {}
	tab._name = name
	tab._sections = {}

	-- Tab page (scrollable content)
	local page = Create("ScrollingFrame", {
		Name = name .. "Page",
		Size = UDim2.new(1, -20, 1, -20),
		Position = UDim2.new(0, 10, 0, 10),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		ScrollBarThickness = 3,
		ScrollBarImageColor3 = Theme.Scrollbar,
		ScrollBarImageTransparency = 0.2,
		CanvasSize = UDim2.new(0, 0, 0, 0),
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
		Parent = self._content,
	})
	reg(page, "ScrollBarImageColor3", "Scrollbar", 0.2)
	Create("UIListLayout", {
		SortOrder = Enum.SortOrder.LayoutOrder,
		Padding = UDim.new(0, 8),
		Parent = page,
	})

	tab._page = page

	-- Tab button in sidebar
	local order = #self._tabs + 1
	local btn = Create("TextButton", {
		Name = name .. "Btn",
		Size = UDim2.new(1, 0, 0, 30),
		BackgroundColor3 = Theme.Item,
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		Text = "",
		AutoButtonColor = false,
		LayoutOrder = order,
		Parent = self._sidebar,
	})
	Create("UICorner", { CornerRadius = UDim.new(0, 6), Parent = btn })

	local label = Create("TextLabel", {
		Name = "Label",
		Size = UDim2.new(1, -22, 1, 0),
		Position = UDim2.new(0, 12, 0, 0),
		BackgroundTransparency = 1,
		Text = name,
		TextColor3 = Theme.Subtext,
		Font = Fonts.Body,
		TextSize = 12,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextTruncate = Enum.TextTruncate.AtEnd,
		Parent = btn,
	})

	-- Active indicator bar
	local indicator = Create("Frame", {
		Name = "Indicator",
		AnchorPoint = Vector2.new(0, 0.5),
		Position = UDim2.new(0, 0, 0.5, 0),
		Size = UDim2.new(0, 3, 0, 0),
		BackgroundColor3 = Theme.Accent,
		BorderSizePixel = 0,
		Parent = btn,
	})
	Create("UICorner", { CornerRadius = UDim.new(0, 2), Parent = indicator })

	local entry = {
		btn = btn,
		label = label,
		indicator = indicator,
		page = page,
		active = false,
	}

	local function setActive(isActive: boolean)
		entry.active = isActive
		page.Visible = isActive
		TweenService:Create(indicator, Motion.Base, {
			Size = UDim2.new(0, 3, 0, isActive and 14 or 0),
		}):Play()
		TweenService:Create(label, Motion.Base, {
			TextColor3 = isActive and Theme.Text or Theme.Subtext,
		}):Play()
		TweenService:Create(btn, Motion.Base, {
			BackgroundTransparency = isActive and 0 or 1,
		}):Play()
		btn.BackgroundColor3 = Theme.Item
	end

	-- Stateful restyle hook: reapplied on theme changes
	hook(function()
		applyTabState(entry)
		indicator.BackgroundColor3 = Theme.Accent
	end)

	local function activate()
		for _, t in ipairs(self._tabButtons) do
			t.active = false
			t.page.Visible = false
			TweenService:Create(t.indicator, Motion.Base, { Size = UDim2.new(0, 3, 0, 0) }):Play()
			TweenService:Create(t.label, Motion.Base, { TextColor3 = Theme.Subtext }):Play()
			TweenService:Create(t.btn, Motion.Base, { BackgroundTransparency = 1 }):Play()
		end
		setActive(true)
	end

	btn.MouseEnter:Connect(function()
		if not entry.active then
			TweenService:Create(btn, Motion.Fast, { BackgroundTransparency = 0.4 }):Play()
		end
	end)
	btn.MouseLeave:Connect(function()
		if not entry.active then
			TweenService:Create(btn, Motion.Fast, { BackgroundTransparency = 1 }):Play()
		end
	end)

	btn.MouseButton1Click:Connect(function()
		CircleClick(btn, MouseLocation().X, MouseLocation().Y)
		activate()
	end)

	table.insert(self._tabButtons, entry)

	-- Auto-select first tab
	if #self._tabButtons == 1 then
		setActive(true)
	end

	-- Method to show a tab by name (fixed: was firing a Roblox signal directly)
	function Library:ShowTab(tabName: string)
		for _, t in ipairs(self._tabButtons) do
			if t.btn.Name == tabName .. "Btn" then
				-- Replicate the click activation
				for _, other in ipairs(self._tabButtons) do
					other.active = false
					other.page.Visible = false
					TweenService:Create(other.indicator, Motion.Base, { Size = UDim2.new(0, 3, 0, 0) }):Play()
					TweenService:Create(other.label, Motion.Base, { TextColor3 = Theme.Subtext }):Play()
					TweenService:Create(other.btn, Motion.Base, { BackgroundTransparency = 1 }):Play()
				end
				t.active = true
				t.page.Visible = true
				TweenService:Create(t.indicator, Motion.Base, { Size = UDim2.new(0, 3, 0, 14) }):Play()
				TweenService:Create(t.label, Motion.Base, { TextColor3 = Theme.Text }):Play()
				TweenService:Create(t.btn, Motion.Base, { BackgroundTransparency = 0 }):Play()
				break
			end
		end
	end

	function tab:Section(config: any)
		config = config or {}
		local title: string = config.Title or "Section"
		local content: string = config.Content or ""

		local section: any = {}

		local frame = Create("Frame", {
			Name = title .. "Section",
			Size = UDim2.new(1, 0, 0, 33),
			BackgroundColor3 = Theme.Surface,
			BorderSizePixel = 0,
			Parent = page,
		})
		Create("UICorner", { CornerRadius = UDim.new(0, 8), Parent = frame })
		reg(frame, "BackgroundColor3", "Surface")
		local sectionStroke = Create("UIStroke", { Color = Theme.Stroke, Thickness = 1, Parent = frame })
		reg(sectionStroke, "Color", "Stroke")
		Create("UIPadding", {
			PaddingTop = UDim.new(0, 10),
			PaddingBottom = UDim.new(0, 10),
			PaddingLeft = UDim.new(0, 12),
			PaddingRight = UDim.new(0, 12),
			Parent = frame,
		})

		-- Header block
		local headerH = 16
		Create("TextLabel", {
			Name = "Title",
			Size = UDim2.new(1, 0, 0, 16),
			BackgroundTransparency = 1,
			Text = title,
			TextColor3 = Theme.Subtext,
			Font = Fonts.ItemTitle,
			TextSize = 12,
			TextXAlignment = Enum.TextXAlignment.Left,
			Parent = frame,
		})

		if content ~= "" then
			headerH = 34
			Create("TextLabel", {
				Name = "Description",
				Position = UDim2.new(0, 0, 0, 18),
				Size = UDim2.new(1, 0, 0, 16),
				BackgroundTransparency = 1,
				Text = content,
				TextColor3 = Theme.Subtext,
				Font = Fonts.Small,
				TextSize = 11,
				TextXAlignment = Enum.TextXAlignment.Left,
				TextWrapped = true,
				Parent = frame,
			})
		end

		-- Items container
		local itemsFrame = Create("Frame", {
			Name = "Items",
			Position = UDim2.new(0, 0, 0, headerH + 8),
			Size = UDim2.new(1, 0, 0, 0),
			BackgroundTransparency = 1,
			Parent = frame,
		})
		Create("UIListLayout", {
			SortOrder = Enum.SortOrder.LayoutOrder,
			Padding = UDim.new(0, 6),
			Parent = itemsFrame,
		})

		-- Auto-resize section
		local ITEM_GAP = 6
		local function updateSize()
			local offsetY = headerH + 8
			for _, child in ipairs(itemsFrame:GetChildren()) do
				if child:IsA("GuiObject") then
					offsetY += child.Size.Y.Offset + ITEM_GAP
				end
			end
			offsetY += 10 -- bottom padding (UIPadding is additive, this trims trailing gap)
			frame.Size = UDim2.new(1, 0, 0, offsetY)
		end

		itemsFrame.ChildAdded:Connect(updateSize)
		itemsFrame.ChildRemoved:Connect(updateSize)

		-- ── Section Items ──

		function section:Button(config: any)
			config = config or {}
			local btnTitle: string = config.Title or "Button"
			local btnContent: string = config.Content or ""
			local callback: () -> () = config.Callback or function() end

			local btnHeight = btnContent ~= "" and 46 or 32

			local btnFrame = Create("Frame", {
				Name = btnTitle .. "Button",
				Size = UDim2.new(1, 0, 0, btnHeight),
				BackgroundTransparency = 1,
				Parent = itemsFrame,
			})

			local btn = Create("TextButton", {
				Size = UDim2.new(1, 0, 1, 0),
				BackgroundColor3 = Theme.Item,
				BorderSizePixel = 0,
				Text = "",
				AutoButtonColor = false,
				Parent = btnFrame,
			})
			Create("UICorner", { CornerRadius = UDim.new(0, 6), Parent = btn })
			reg(btn, "BackgroundColor3", "Item")

			Create("TextLabel", {
				Name = "Title",
				Position = UDim2.new(0, 10, 0, btnContent ~= "" and 5 or 0),
				Size = UDim2.new(1, -20, 0, 16),
				BackgroundTransparency = 1,
				Text = btnTitle,
				TextColor3 = Theme.Text,
				Font = Fonts.Body,
				TextSize = 12,
				TextXAlignment = Enum.TextXAlignment.Left,
				Parent = btn,
			})

			if btnContent ~= "" then
				Create("TextLabel", {
					Name = "Content",
					Position = UDim2.new(0, 10, 0, 23),
					Size = UDim2.new(1, -20, 0, 14),
					BackgroundTransparency = 1,
					Text = btnContent,
					TextColor3 = Theme.Subtext,
					Font = Fonts.Small,
					TextSize = 11,
					TextXAlignment = Enum.TextXAlignment.Left,
					TextTruncate = Enum.TextTruncate.AtEnd,
					Parent = btn,
				})
			end

			-- Hover (reads Theme live so retheme keeps hover correct)
			btn.MouseEnter:Connect(function()
				btn.BackgroundColor3 = Theme.ItemHover
			end)
			btn.MouseLeave:Connect(function()
				btn.BackgroundColor3 = Theme.Item
			end)
			hook(function()
				btn.BackgroundColor3 = Theme.Item
			end)

			btn.MouseButton1Click:Connect(function()
				CircleClick(btn, MouseLocation().X, MouseLocation().Y)
				callback()
			end)

			return { Set = function(_, _val) end }
		end

		function section:Toggle(config: any)
			config = config or {}
			local toggleTitle: string = config.Title or "Toggle"
			local toggleContent: string = config.Content or ""
			local default: boolean = config.Default or false
			local callback: (boolean) -> () = config.Callback or function() end
			local flag: string? = config.Flag

			local toggleHeight = toggleContent ~= "" and 46 or 32
			local toggled = default

			-- Check saved flag
			if flag and self._saveFolder and self._flags[flag] ~= nil then
				toggled = self._flags[flag]
			end

			local toggleFrame = Create("Frame", {
				Name = toggleTitle .. "Toggle",
				Size = UDim2.new(1, 0, 0, toggleHeight),
				BackgroundTransparency = 1,
				Parent = itemsFrame,
			})

			Create("TextLabel", {
				Name = "Title",
				Position = UDim2.new(0, 2, 0, toggleContent ~= "" and 5 or 0),
				Size = UDim2.new(1, -60, 0, 16),
				BackgroundTransparency = 1,
				Text = toggleTitle,
				TextColor3 = Theme.Text,
				Font = Fonts.Body,
				TextSize = 12,
				TextXAlignment = Enum.TextXAlignment.Left,
				Parent = toggleFrame,
			})

			if toggleContent ~= "" then
				Create("TextLabel", {
					Name = "Content",
					Position = UDim2.new(0, 2, 0, 23),
					Size = UDim2.new(1, -60, 0, 14),
					BackgroundTransparency = 1,
					Text = toggleContent,
					TextColor3 = Theme.Subtext,
					Font = Fonts.Small,
					TextSize = 11,
					TextXAlignment = Enum.TextXAlignment.Left,
					Parent = toggleFrame,
				})
			end

			-- Toggle track
			local track = Create("Frame", {
				Name = "Track",
				AnchorPoint = Vector2.new(1, 0.5),
				Position = UDim2.new(1, -2, 0.5, 0),
				Size = UDim2.new(0, 36, 0, 20),
				BackgroundColor3 = toggled and Theme.Accent or Theme.TrackOff,
				BorderSizePixel = 0,
				Parent = toggleFrame,
			})
			Create("UICorner", { CornerRadius = UDim.new(1, 0), Parent = track })

			-- Toggle knob
			local knob = Create("Frame", {
				Name = "Knob",
				Position = toggled and UDim2.new(1, -18, 0.5, -8) or UDim2.new(0, 2, 0.5, -8),
				Size = UDim2.new(0, 16, 0, 16),
				BackgroundColor3 = Theme.Text,
				BorderSizePixel = 0,
				Parent = track,
			})
			Create("UICorner", { CornerRadius = UDim.new(1, 0), Parent = knob })

			-- Stateful restyle hook
			hook(function()
				track.BackgroundColor3 = toggled and Theme.Accent or Theme.TrackOff
				knob.BackgroundColor3 = Theme.Text
			end)

			local toggleFunc = {}

			local function setToggle(val: boolean, silent: boolean?)
				toggled = val
				local newPos = val and UDim2.new(1, -18, 0.5, -8) or UDim2.new(0, 2, 0.5, -8)
				TweenService:Create(knob, Motion.Spring, { Position = newPos }):Play()
				TweenService:Create(track, Motion.Base, {
					BackgroundColor3 = val and Theme.Accent or Theme.TrackOff,
				}):Play()

				-- Save flag
				if flag and self._saveFolder then
					self._flags[flag] = val
					pcall(function()
						writefile(self._saveFolder .. ".json", HttpService:JSONEncode(self._flags))
					end)
				end

				if not silent then
					callback(val)
				end
			end

			-- Single click handler on the row (fixes double-fire bug)
			toggleFrame.InputBegan:Connect(function(input)
				if input.UserInputType == Enum.UserInputType.MouseButton1 then
					setToggle(not toggled)
				end
			end)

			function toggleFunc:Set(val: boolean)
				setToggle(val)
			end

			return toggleFunc
		end

		function section:Slider(config: any)
			config = config or {}
			local sliderTitle: string = config.Title or "Slider"
			local sliderContent: string = config.Content or ""
			local min: number = config.Min or 0
			local max: number = config.Max or 100
			local increment: number = config.Increment or 1
			local default: number = config.Default or 50
			local callback: (number) -> () = config.Callback or function() end

			local value = default
			local sliderHeight = sliderContent ~= "" and 62 or 48
			local trackY = sliderContent ~= "" and 40 or 28

			local sliderFrame = Create("Frame", {
				Name = sliderTitle .. "Slider",
				Size = UDim2.new(1, 0, 0, sliderHeight),
				BackgroundTransparency = 1,
				Parent = itemsFrame,
			})

			Create("TextLabel", {
				Name = "Title",
				Position = UDim2.new(0, 2, 0, 0),
				Size = UDim2.new(0.6, 0, 0, 16),
				BackgroundTransparency = 1,
				Text = sliderTitle,
				TextColor3 = Theme.Text,
				Font = Fonts.Body,
				TextSize = 12,
				TextXAlignment = Enum.TextXAlignment.Left,
				Parent = sliderFrame,
			})

			-- Value label
			local valueLabel = Create("TextLabel", {
				Name = "Value",
				AnchorPoint = Vector2.new(1, 0),
				Position = UDim2.new(1, -2, 0, 0),
				Size = UDim2.new(0, 50, 0, 16),
				BackgroundTransparency = 1,
				Text = tostring(value),
				TextColor3 = Theme.Accent,
				Font = Fonts.Body,
				TextSize = 12,
				TextXAlignment = Enum.TextXAlignment.Right,
				Parent = sliderFrame,
			})
			reg(valueLabel, "TextColor3", "Accent")

			if sliderContent ~= "" then
				Create("TextLabel", {
					Name = "Content",
					Position = UDim2.new(0, 2, 0, 18),
					Size = UDim2.new(1, -4, 0, 14),
					BackgroundTransparency = 1,
					Text = sliderContent,
					TextColor3 = Theme.Subtext,
					Font = Fonts.Small,
					TextSize = 11,
					TextXAlignment = Enum.TextXAlignment.Left,
					Parent = sliderFrame,
				})
			end

			-- Slider track
			local trackBg = Create("Frame", {
				Name = "TrackBg",
				Position = UDim2.new(0, 2, 0, trackY),
				Size = UDim2.new(1, -4, 0, 4),
				BackgroundColor3 = Theme.TrackOff,
				BorderSizePixel = 0,
				Parent = sliderFrame,
			})
			Create("UICorner", { CornerRadius = UDim.new(1, 0), Parent = trackBg })
			reg(trackBg, "BackgroundColor3", "TrackOff")

			-- Fill bar
			local fillPercent = (value - min) / (max - min)
			local fill = Create("Frame", {
				Name = "Fill",
				Size = UDim2.new(fillPercent, 0, 1, 0),
				BackgroundColor3 = Theme.Accent,
				BorderSizePixel = 0,
				Parent = trackBg,
			})
			Create("UICorner", { CornerRadius = UDim.new(1, 0), Parent = fill })
			reg(fill, "BackgroundColor3", "Accent")

			-- Knob
			local knobDot = Create("Frame", {
				Name = "Knob",
				AnchorPoint = Vector2.new(0.5, 0.5),
				Position = UDim2.new(fillPercent, 0, 0.5, 0),
				Size = UDim2.new(0, 12, 0, 12),
				BackgroundColor3 = Theme.Text,
				BorderSizePixel = 0,
				Parent = trackBg,
			})
			Create("UICorner", { CornerRadius = UDim.new(1, 0), Parent = knobDot })
			local knobStroke = Create("UIStroke", { Color = Theme.Stroke, Thickness = 1, Parent = knobDot })
			reg(knobStroke, "Color", "Stroke")

			-- Slider logic
			local sliding = false

			local function updateSlider(inputX: number)
				local relX = math.clamp((inputX - trackBg.AbsolutePosition.X) / trackBg.AbsoluteSize.X, 0, 1)
				value = Round(min + (max - min) * relX, increment)
				value = math.clamp(value, min, max)
				local pct = (value - min) / (max - min)
				fill.Size = UDim2.new(pct, 0, 1, 0)
				knobDot.Position = UDim2.new(pct, 0, 0.5, 0)
				valueLabel.Text = tostring(value)
				callback(value)
			end

			trackBg.InputBegan:Connect(function(input)
				if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
					sliding = true
					updateSlider(input.Position.X)
				end
			end)

			UserInputService.InputEnded:Connect(function(input)
				if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
					sliding = false
				end
			end)

			UserInputService.InputChanged:Connect(function(input)
				if sliding and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
					updateSlider(input.Position.X)
				end
			end)

			local sliderFunc = {}
			function sliderFunc:Set(val: number)
				value = math.clamp(val, min, max)
				local pct = (value - min) / (max - min)
				TweenService:Create(fill, Motion.Base, { Size = UDim2.new(pct, 0, 1, 0) }):Play()
				TweenService:Create(knobDot, Motion.Base, { Position = UDim2.new(pct, 0, 0.5, 0) }):Play()
				valueLabel.Text = tostring(value)
				callback(value)
			end

			return sliderFunc
		end

		function section:Dropdown(config: any)
			config = config or {}
			local dropTitle: string = config.Title or "Dropdown"
			local multi: boolean = config.Multi or false
			local options: { string } = config.Options or {}
			local default = config.Default or (multi and {} or { options[1] })
			local callback: (any) -> () = config.Callback or function() end
			local placeholder: string = config.PlaceHolderText or "Select Options"

			local selected: any = multi and {} or (default[1] or nil)
			local dropped = false

			local HEADER_H = 46
			local dropFrame = Create("Frame", {
				Name = dropTitle .. "Dropdown",
				Size = UDim2.new(1, 0, 0, HEADER_H),
				BackgroundColor3 = Theme.Item,
				BorderSizePixel = 0,
				ClipsDescendants = true,
				Parent = itemsFrame,
			})
			Create("UICorner", { CornerRadius = UDim.new(0, 6), Parent = dropFrame })
			reg(dropFrame, "BackgroundColor3", "Item")

			-- Header click region ONLY (fixes option-click bubbling into open/close)
			local headerBtn = Create("TextButton", {
				Name = "Header",
				Size = UDim2.new(1, 0, 0, HEADER_H),
				BackgroundColor3 = Theme.Item,
				BorderSizePixel = 0,
				Text = "",
				AutoButtonColor = false,
				Parent = dropFrame,
			})
			headerBtn.BackgroundColor3 = dropFrame.BackgroundColor3

			Create("TextLabel", {
				Name = "Title",
				Position = UDim2.new(0, 10, 0, 7),
				Size = UDim2.new(1, -30, 0, 16),
				BackgroundTransparency = 1,
				Text = dropTitle,
				TextColor3 = Theme.Text,
				Font = Fonts.Body,
				TextSize = 12,
				TextXAlignment = Enum.TextXAlignment.Left,
				Parent = headerBtn,
			})

			-- Selected display
			local display = Create("TextLabel", {
				Name = "Display",
				Position = UDim2.new(0, 10, 0, 25),
				Size = UDim2.new(1, -30, 0, 16),
				BackgroundTransparency = 1,
				Text = "",
				TextColor3 = Theme.Accent,
				Font = Fonts.Body,
				TextSize = 12,
				TextXAlignment = Enum.TextXAlignment.Left,
				TextTruncate = Enum.TextTruncate.AtEnd,
				Parent = headerBtn,
			})
			reg(display, "TextColor3", "Accent")

			-- Arrow
			local arrow = Create("TextLabel", {
				Name = "Arrow",
				AnchorPoint = Vector2.new(1, 0.5),
				Position = UDim2.new(1, -12, 0, HEADER_H / 2),
				Size = UDim2.new(0, 16, 0, 16),
				BackgroundTransparency = 1,
				Text = "▾",
				TextColor3 = Theme.Subtext,
				Font = Fonts.Body,
				TextSize = 14,
				Parent = headerBtn,
			})
			reg(arrow, "TextColor3", "Subtext")

			-- Options container
			local optionsFrame = Create("Frame", {
				Name = "Options",
				Position = UDim2.new(0, 0, 0, HEADER_H + 4),
				Size = UDim2.new(1, 0, 0, 0),
				BackgroundTransparency = 1,
				Parent = dropFrame,
			})
			Create("UIListLayout", {
				SortOrder = Enum.SortOrder.LayoutOrder,
				Padding = UDim.new(0, 2),
				Parent = optionsFrame,
			})

			local optionState: {[string]: any} = {}

			local function updateDisplay()
				if multi then
					display.Text = #selected == 0 and placeholder or table.concat(selected, ", ")
				else
					display.Text = selected or placeholder
					display.TextColor3 = selected and Theme.Accent or Theme.Subtext
				end
			end

			local function refreshOptionVisual(opt: string)
				local st = optionState[opt]
				if not st then return end
				st.bar.Size = UDim2.new(0, 3, 0, st.selected and 14 or 0)
				st.label.TextColor3 = st.selected and Theme.Text or Theme.Subtext
			end

			local function toggleOption(opt: string)
				if multi then
					local st = optionState[opt]
					st.selected = not st.selected
					local idx = table.find(selected, opt)
					if idx then
						table.remove(selected, idx)
					else
						table.insert(selected, opt)
					end
					refreshOptionVisual(opt)
				else
					local prev = selected
					selected = opt
					dropped = false
					TweenService:Create(dropFrame, Motion.Slow, { Size = UDim2.new(1, 0, 0, HEADER_H) }):Play()
					TweenService:Create(arrow, Motion.Slow, { Rotation = 0 }):Play()
					if prev and optionState[prev] then
						optionState[prev].selected = false
						refreshOptionVisual(prev)
					end
					optionState[opt].selected = true
					refreshOptionVisual(opt)
				end
				updateDisplay()
				callback(selected)
			end

			local function buildOption(opt: string, index: number)
				local optBtn = Create("TextButton", {
					Name = opt,
					Size = UDim2.new(1, -12, 0, 26),
					Position = UDim2.new(0, 6, 0, 0),
					BackgroundColor3 = Theme.ItemHover,
					BorderSizePixel = 0,
					Text = "",
					AutoButtonColor = false,
					LayoutOrder = index,
					Parent = optionsFrame,
				})
				Create("UICorner", { CornerRadius = UDim.new(0, 4), Parent = optBtn })

				local bar = Create("Frame", {
					Name = "Bar",
					Position = UDim2.new(0, 6, 0.5, -7),
					Size = UDim2.new(0, 3, 0, 0),
					BackgroundColor3 = Theme.Accent,
					BorderSizePixel = 0,
					Parent = optBtn,
				})
				Create("UICorner", { CornerRadius = UDim.new(0, 2), Parent = bar })
				reg(bar, "BackgroundColor3", "Accent")

				local optLabel = Create("TextLabel", {
					Name = "Label",
					Position = UDim2.new(0, 16, 0, 0),
					Size = UDim2.new(1, -24, 1, 0),
					BackgroundTransparency = 1,
					Text = opt,
					TextColor3 = Theme.Subtext,
					Font = Fonts.Body,
					TextSize = 12,
					TextXAlignment = Enum.TextXAlignment.Left,
					Parent = optBtn,
				})

				optBtn.MouseEnter:Connect(function()
					optBtn.BackgroundColor3 = Theme.Stroke
				end)
				optBtn.MouseLeave:Connect(function()
					optBtn.BackgroundColor3 = Theme.ItemHover
				end)

				optBtn.MouseButton1Click:Connect(function()
					toggleOption(opt)
				end)

				local isSelected = (multi and table.find(selected, opt) ~= nil) or selected == opt
				optionState[opt] = { btn = optBtn, label = optLabel, bar = bar, selected = isSelected }
				refreshOptionVisual(opt)
			end

			for i, opt in ipairs(options) do
				buildOption(opt, i)
			end

			-- Open/close (header only)
			local function toggleDrop()
				dropped = not dropped
				local optCount = #options
				local targetH = dropped and (HEADER_H + 4 + optCount * 28 + 4) or HEADER_H
				TweenService:Create(dropFrame, Motion.Slow, { Size = UDim2.new(1, 0, 0, targetH) }):Play()
				TweenService:Create(arrow, Motion.Slow, { Rotation = dropped and 180 or 0 }):Play()
			end

			headerBtn.Activated:Connect(toggleDrop)

			updateDisplay()

			local dropFunc = {}
			function dropFunc:Set(val: any)
				if multi then
					local newSel = type(val) == "table" and val or { val }
					for _, st in pairs(optionState) do
						st.selected = false
					end
					selected = {}
					for _, opt in ipairs(newSel) do
						if optionState[opt] then
							optionState[opt].selected = true
							table.insert(selected, opt)
						end
					end
					for _, st in pairs(optionState) do
						refreshOptionVisual(st.label.Text)
					end
				else
					local prev = selected
					selected = val
					if prev and optionState[prev] then
						optionState[prev].selected = false
						refreshOptionVisual(prev)
					end
					if val and optionState[val] then
						optionState[val].selected = true
						refreshOptionVisual(val)
					end
				end
				updateDisplay()
				callback(selected)
			end

			function dropFunc:Add(opt: string)
				table.insert(options, opt)
				buildOption(opt, #options)
			end

			function dropFunc:Clear()
				options = {}
				optionState = {}
				for _, child in ipairs(optionsFrame:GetChildren()) do
					if child:IsA("TextButton") then child:Destroy() end
				end
				selected = multi and {} or nil
				updateDisplay()
			end

			function dropFunc:Refresh(newOpts: { string }, newDefault: any)
				self:Clear()
				options = newOpts
				for _, opt in ipairs(options) do
					self:Add(opt)
				end
				if newDefault then
					self:Set(newDefault)
				end
			end

			return dropFunc
		end

		function section:TextInput(config: any)
			config = config or {}
			local inputTitle: string = config.Title or "Input"
			local inputContent: string = config.Content or ""
			local placeholder: string = config.PlaceHolderText or "Enter text..."
			local clearOnFocus: boolean = config.ClearTextOnFocus ~= false
			local default: string = config.Default or ""
			local callback: (string) -> () = config.Callback or function() end

			local inputHeight = inputContent ~= "" and 64 or 50
			local boxY = inputContent ~= "" and 36 or 26

			local inputFrame = Create("Frame", {
				Name = inputTitle .. "Input",
				Size = UDim2.new(1, 0, 0, inputHeight),
				BackgroundTransparency = 1,
				Parent = itemsFrame,
			})

			Create("TextLabel", {
				Name = "Title",
				Position = UDim2.new(0, 2, 0, 0),
				Size = UDim2.new(1, -4, 0, 16),
				BackgroundTransparency = 1,
				Text = inputTitle,
				TextColor3 = Theme.Text,
				Font = Fonts.Body,
				TextSize = 12,
				TextXAlignment = Enum.TextXAlignment.Left,
				Parent = inputFrame,
			})

			if inputContent ~= "" then
				Create("TextLabel", {
					Name = "Content",
					Position = UDim2.new(0, 2, 0, 18),
					Size = UDim2.new(1, -4, 0, 14),
					BackgroundTransparency = 1,
					Text = inputContent,
					TextColor3 = Theme.Subtext,
					Font = Fonts.Small,
					TextSize = 11,
					TextXAlignment = Enum.TextXAlignment.Left,
					Parent = inputFrame,
				})
			end

			local box = Create("TextBox", {
				Name = "Box",
				Position = UDim2.new(0, 2, 0, boxY),
				Size = UDim2.new(1, -4, 0, 24),
				BackgroundColor3 = Theme.Item,
				BorderSizePixel = 0,
				ClearTextOnFocus = clearOnFocus,
				Text = default,
				TextColor3 = Theme.Text,
				PlaceholderText = placeholder,
				PlaceholderColor3 = Theme.Subtext,
				Font = Fonts.Small,
				TextSize = 12,
				TextXAlignment = Enum.TextXAlignment.Left,
				Parent = inputFrame,
			})
			Create("UICorner", { CornerRadius = UDim.new(0, 6), Parent = box })
			reg(box, "BackgroundColor3", "Item")
			local boxStroke = Create("UIStroke", { Color = Theme.Stroke, Thickness = 1, Parent = box })
			reg(boxStroke, "Color", "Stroke")
			Create("UIPadding", {
				PaddingLeft = UDim.new(0, 8),
				PaddingRight = UDim.new(0, 8),
				Parent = box,
			})

			box.Focused:Connect(function()
				TweenService:Create(boxStroke, Motion.Fast, { Color = Theme.Accent }):Play()
			end)
			box.FocusLost:Connect(function()
				TweenService:Create(boxStroke, Motion.Fast, { Color = Theme.Stroke }):Play()
				callback(box.Text)
			end)

			local inputFunc = {}
			function inputFunc:Set(val: string)
				box.Text = val
				callback(val)
			end

			return inputFunc
		end

		function section:Paragraph(config: any)
			config = config or {}
			local paraTitle: string = config.Title or ""
			local paraContent: string = config.Content or ""

			local paraHeight = paraContent ~= "" and 36 or 20

			local paraFrame = Create("Frame", {
				Name = "Paragraph",
				Size = UDim2.new(1, 0, 0, paraHeight),
				BackgroundTransparency = 1,
				Parent = itemsFrame,
			})

			local titleLabel = Create("TextLabel", {
				Name = "Title",
				Position = UDim2.new(0, 2, 0, 0),
				Size = UDim2.new(1, -4, 0, paraContent ~= "" and 16 or paraHeight),
				BackgroundTransparency = 1,
				Text = paraTitle,
				TextColor3 = Theme.Text,
				Font = Fonts.Body,
				TextSize = 12,
				TextXAlignment = Enum.TextXAlignment.Left,
				TextWrapped = paraContent == "",
				Parent = paraFrame,
			})
			reg(titleLabel, "TextColor3", "Text")

			local contentLabel = nil
			if paraContent ~= "" then
				contentLabel = Create("TextLabel", {
					Name = "Content",
					Position = UDim2.new(0, 2, 0, 18),
					Size = UDim2.new(1, -4, 0, 16),
					BackgroundTransparency = 1,
					Text = paraContent,
					TextColor3 = Theme.Subtext,
					Font = Fonts.Small,
					TextSize = 11,
					TextXAlignment = Enum.TextXAlignment.Left,
					TextWrapped = true,
					Parent = paraFrame,
				})
				reg(contentLabel, "TextColor3", "Subtext")
			end

			local paraFunc = {}
			function paraFunc:Set(cfg: any)
				cfg = cfg or {}
				if cfg.Title then titleLabel.Text = cfg.Title end
				if cfg.Content and contentLabel then
					contentLabel.Text = cfg.Content
				elseif cfg.Content then
					contentLabel = Create("TextLabel", {
						Name = "Content",
						Position = UDim2.new(0, 2, 0, 18),
						Size = UDim2.new(1, -4, 0, 16),
						BackgroundTransparency = 1,
						Text = cfg.Content,
						TextColor3 = Theme.Subtext,
						Font = Fonts.Small,
						TextSize = 11,
						TextXAlignment = Enum.TextXAlignment.Left,
						TextWrapped = true,
						Parent = paraFrame,
					})
					reg(contentLabel, "TextColor3", "Subtext")
				end
			end

			return paraFunc
		end

		function section:Seperator(name: string?)
			name = name or ""

			local sepFrame = Create("Frame", {
				Name = "Separator",
				Size = UDim2.new(1, 0, 0, 18),
				BackgroundTransparency = 1,
				Parent = itemsFrame,
			})

			Create("Frame", {
				Name = "Line",
				Position = UDim2.new(0, 0, 0.5, 0),
				Size = UDim2.new(1, 0, 0, 1),
				BackgroundColor3 = Theme.Stroke,
				BorderSizePixel = 0,
				Parent = sepFrame,
			})
			reg(sepFrame.Line, "BackgroundColor3", "Stroke")

			local chip = nil
			if name ~= "" then
				chip = Create("TextLabel", {
					Name = "Label",
					Position = UDim2.new(0.5, 0, 0.5, 0),
					AnchorPoint = Vector2.new(0.5, 0.5),
					Size = UDim2.new(0, 0, 0, 16),
					AutomaticSize = Enum.AutomaticSize.X,
					BackgroundColor3 = Theme.Surface,
					BorderSizePixel = 0,
					Text = "  " .. name .. "  ",
					TextColor3 = Theme.Subtext,
					Font = Fonts.Body,
					TextSize = 10,
					Parent = sepFrame,
				})
				Create("UICorner", { CornerRadius = UDim.new(0, 4), Parent = chip })
				reg(chip, "BackgroundColor3", "Surface")
				reg(chip, "TextColor3", "Subtext")
			end

			local sepFunc = {}
			function sepFunc:Set(newName: string)
				if newName and chip then
					chip.Text = "  " .. newName .. "  "
				end
			end
			return sepFunc
		end

		return section
	end

	-- Store tab reference
	table.insert(self._tabs, tab)

	return tab
end

function Library:ToggleUI()
	if self._mainFrame then
		self._mainFrame.Visible = not self._mainFrame.Visible
	end
end

function Library:CloseUI()
	if self._gui then
		self._gui:Destroy()
	end
	if NotifContainer then
		NotifContainer:Destroy()
		NotifContainer = nil
	end
	StyleReg = {}
	HookReg = {}
	ActiveWindow = nil
end

return Library
