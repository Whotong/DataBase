--!strict
-- Re: Hub GUI Library v1.0
-- Custom dark theme with green accent

local Library = {}
Library.__index = Library

-- ═══════════════════════════════════════════
-- SERVICES
-- ═══════════════════════════════════════════
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local HttpService = game:GetService("HttpService")
local Lighting = game:GetService("Lighting")

local LocalPlayer = Players.LocalPlayer

-- ═══════════════════════════════════════════
-- UTILITY
-- ═══════════════════════════════════════════
local function Create(className, props)
	local inst = Instance.new(className)
	for k, v in pairs(props) do
		if k ~= "Parent" and k ~= "Children" then
			inst[k] = v
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

local function Round(num, factor)
	local result = math.floor(num / factor + (math.sign(num) * 0.5)) * factor
	if result < 0 then result = result + factor end
	return result
end

local function MakeDraggable(topbar, frame)
	local dragging, dragStart, startPos

	topbar.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			dragging = true
			dragStart = input.Position
			startPos = frame.Position
		end
	end)

	topbar.InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			dragging = false
		end
	end)

	UserInputService.InputChanged:Connect(function(input)
		if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
			local delta = input.Position - dragStart
			TweenService:Create(frame, TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
				Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
			}):Play()
		end
	end)
end

local function CircleClick(button, x, y)
	task.spawn(function()
		local circle = Create("ImageLabel", {
			Image = "rbxassetid://266543268",
			ImageColor3 = Color3.fromRGB(255, 255, 255),
			ImageTransparency = 0.8,
			BackgroundTransparency = 1,
			ZIndex = 100,
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.new(0, x - button.AbsolutePosition.X, 0, y - button.AbsolutePosition.Y),
			Parent = button
		})

		local size = math.max(button.AbsoluteSize.X, button.AbsoluteSize.Y) * 1.5
		TweenService:Create(circle, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
			Size = UDim2.new(0, size, 0, size),
			ImageTransparency = 1
		}):Play()

		task.wait(0.3)
		circle:Destroy()
	end)
end

-- ═══════════════════════════════════════════
-- COLORS
-- ═══════════════════════════════════════════
local Colors = {
	Background = Color3.fromRGB(26, 26, 46),      -- #1a1a2e
	Panel = Color3.fromRGB(22, 33, 62),            -- #16213e
	Accent = Color3.fromRGB(0, 230, 118),          -- #00e676
	AccentDark = Color3.fromRGB(0, 200, 83),       -- #00c853
	Text = Color3.fromRGB(255, 255, 255),          -- #ffffff
	Subtext = Color3.fromRGB(138, 138, 154),       -- #8a8a9a
	Border = Color3.fromRGB(15, 52, 96),           -- #0f3460
	DarkPanel = Color3.fromRGB(20, 20, 38),        -- #141426
	ButtonDefault = Color3.fromRGB(30, 45, 80),    -- #1e2d50
	ButtonHover = Color3.fromRGB(40, 60, 100),     -- #283c64
	ToggleOff = Color3.fromRGB(60, 60, 80),        -- #3c3c50
	SliderTrack = Color3.fromRGB(40, 40, 60),      -- #28283c
}

-- ═══════════════════════════════════════════
-- FONTS
-- ═══════════════════════════════════════════
local Fonts = {
	Title = Enum.Font.GothamBold,
	Body = Enum.Font.GothamMedium,
	Small = Enum.Font.Gotham,
}

-- ═══════════════════════════════════════════
-- NOTIFICATION SYSTEM
-- ═══════════════════════════════════════════
local NotifContainer = nil

local function EnsureNotifContainer()
	if NotifContainer then return NotifContainer end
	NotifContainer = Create("Frame", {
		Name = "ReHubNotifications",
		AnchorPoint = Vector2.new(1, 1),
		Position = UDim2.new(1, -16, 1, -16),
		Size = UDim2.new(0, 300, 0, 0),
		BackgroundTransparency = 1,
		Parent = LocalPlayer:WaitForChild("PlayerGui")
	})
	Create("UIListLayout", {
		SortOrder = Enum.SortOrder.LayoutOrder,
		VerticalAlignment = Enum.VerticalAlignment.Bottom,
		Padding = UDim.new(0, 8),
		Parent = NotifContainer
	})
	return NotifContainer
end

function Library:Notify(config)
	config = config or {}
	local title = config.Title or "Re: Hub"
	local content = config.Content or ""
	local color = config.Color or Colors.Accent
	local delay = config.Delay or 4

	local container = EnsureNotifContainer()

	local notif = Create("Frame", {
		Name = "Notification",
		Size = UDim2.new(1, 0, 0, 60),
		BackgroundColor3 = Colors.Panel,
		BorderSizePixel = 0,
		Parent = container
	})
	Create("UICorner", { CornerRadius = UDim.new(0, 8), Parent = notif })
	Create("UIStroke", { Color = color, Thickness = 1.5, Parent = notif })

	Create("Frame", {
		Name = "AccentBar",
		Size = UDim2.new(0, 4, 1, 0),
		BackgroundColor3 = color,
		BorderSizePixel = 0,
		Parent = notif
	})

	Create("TextLabel", {
		Name = "Title",
		Position = UDim2.new(0, 14, 0, 8),
		Size = UDim2.new(1, -24, 0, 18),
		BackgroundTransparency = 1,
		Text = title,
		TextColor3 = Colors.Text,
		Font = Fonts.Title,
		TextSize = 14,
		TextXAlignment = Enum.TextXAlignment.Left,
		Parent = notif
	})

	Create("TextLabel", {
		Name = "Content",
		Position = UDim2.new(0, 14, 0, 30),
		Size = UDim2.new(1, -24, 0, 22),
		BackgroundTransparency = 1,
		Text = content,
		TextColor3 = Colors.Subtext,
		Font = Fonts.Small,
		TextSize = 12,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextWrapped = true,
		Parent = notif
	})

	-- Animate in
	notif.Size = UDim2.new(1, 0, 0, 0)
	notif.BackgroundTransparency = 1
	TweenService:Create(notif, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
		Size = UDim2.new(1, 0, 0, 60),
		BackgroundTransparency = 0
	}):Play()

	-- Auto-remove
	task.delay(delay, function()
		TweenService:Create(notif, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
			Size = UDim2.new(1, 0, 0, 0),
			BackgroundTransparency = 1
		}):Play()
		task.wait(0.3)
		notif:Destroy()
	end)
end

-- ═══════════════════════════════════════════
-- WINDOW
-- ═══════════════════════════════════════════
function Library:Start(config)
	config = config or {}
	local windowName = config.Name or "Re: Hub"
	local accentColor = config.Color or Colors.Accent
	local saveFolder = config.SaveFolder
	local closeCallback = config.CloseCallBack

	Colors.Accent = accentColor

	local self = setmetatable({}, { __index = Library })
	self._tabs = {}
	self._tabButtons = {}
	self._currentPage = nil
	self._saveFolder = saveFolder
	self._flags = {}

	-- Load saved flags
	if saveFolder then
		local ok, data = pcall(function()
			return readfile(saveFolder .. ".json")
		end)
		if ok and data then
			local decoded = pcall(function() return HttpService:JSONDecode(data) end)
			if decoded then self._flags = decoded end
		end
	end

	-- ScreenGui
	self._gui = Create("ScreenGui", {
		Name = "ReHubGui",
		ResetOnSpawn = false,
		ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
		DisplayOrder = 999,
		Parent = LocalPlayer:WaitForChild("PlayerGui")
	})

	-- Main Frame
	local mainSize = UDim2.new(0, 520, 0, 340)
	self._mainFrame = Create("Frame", {
		Name = "MainFrame",
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.new(0.5, 0, 0.5, 0),
		Size = mainSize,
		BackgroundColor3 = Colors.Background,
		BorderSizePixel = 0,
		Parent = self._gui
	})
	Create("UICorner", { CornerRadius = UDim.new(0, 10), Parent = self._mainFrame })
	Create("UIStroke", { Color = Colors.Border, Thickness = 1.5, Parent = self._mainFrame })

	-- Drop shadow (visual only)
	Create("ImageLabel", {
		Name = "Shadow",
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.new(0.5, 0, 0.5, 4),
		Size = UDim2.new(1, 30, 1, 30),
		BackgroundTransparency = 1,
		Image = "rbxassetid://5554236805",
		ImageColor3 = Color3.fromRGB(0, 0, 0),
		ImageTransparency = 0.6,
		ScaleType = Enum.ScaleType.Slice,
		SliceCenter = Rect.new(23, 23, 277, 277),
		ZIndex = -1,
		Parent = self._mainFrame
	})

	-- Top Bar
	self._topBar = Create("Frame", {
		Name = "TopBar",
		Size = UDim2.new(1, 0, 0, 40),
		BackgroundColor3 = Colors.DarkPanel,
		BorderSizePixel = 0,
		Parent = self._mainFrame
	})
	Create("UICorner", { CornerRadius = UDim.new(0, 10), Parent = self._topBar })
	-- Fix bottom corners of topbar
	Create("Frame", {
		Name = "BottomFix",
		Position = UDim2.new(0, 0, 1, -10),
		Size = UDim2.new(1, 0, 0, 10),
		BackgroundColor3 = Colors.DarkPanel,
		BorderSizePixel = 0,
		Parent = self._topBar
	})

	-- Title
	Create("TextLabel", {
		Name = "Title",
		Position = UDim2.new(0, 14, 0, 0),
		Size = UDim2.new(0.5, 0, 1, 0),
		BackgroundTransparency = 1,
		Text = windowName,
		TextColor3 = accentColor,
		Font = Fonts.Title,
		TextSize = 16,
		TextXAlignment = Enum.TextXAlignment.Left,
		Parent = self._topBar
	})

	-- Close Button
	local closeBtn = Create("TextButton", {
		Name = "CloseBtn",
		Position = UDim2.new(1, -34, 0, 10),
		Size = UDim2.new(0, 20, 0, 20),
		BackgroundColor3 = Color3.fromRGB(255, 70, 70),
		BorderSizePixel = 0,
		Text = "",
		Parent = self._topBar
	})
	Create("UICorner", { CornerRadius = UDim.new(1, 0), Parent = closeBtn })
	closeBtn.MouseButton1Click:Connect(function()
		if self._gui then
			self._gui:Destroy()
		end
		if closeCallback then closeCallback() end
	end)

	-- Minimize Button
	local minBtn = Create("TextButton", {
		Name = "MinBtn",
		Position = UDim2.new(1, -60, 0, 10),
		Size = UDim2.new(0, 20, 0, 20),
		BackgroundColor3 = Color3.fromRGB(255, 180, 50),
		BorderSizePixel = 0,
		Text = "",
		Parent = self._topBar
	})
	Create("UICorner", { CornerRadius = UDim.new(1, 0), Parent = minBtn })
	minBtn.MouseButton1Click:Connect(function()
		self._mainFrame.Visible = false
	end)

	-- Sidebar
	self._sidebar = Create("Frame", {
		Name = "Sidebar",
		Position = UDim2.new(0, 0, 0, 40),
		Size = UDim2.new(0, 130, 1, -40),
		BackgroundColor3 = Colors.DarkPanel,
		BorderSizePixel = 0,
		Parent = self._mainFrame
	})

	-- Sidebar separator line (parented to MainFrame so the sidebar's UIListLayout doesn't manage it)
	Create("Frame", {
		Name = "Separator",
		Position = UDim2.new(0, 130, 0, 40),
		Size = UDim2.new(0, 1, 1, -40),
		BackgroundColor3 = Colors.Border,
		BorderSizePixel = 0,
		Parent = self._mainFrame
	})

	Create("UIListLayout", {
		SortOrder = Enum.SortOrder.LayoutOrder,
		Padding = UDim.new(0, 4),
		Parent = self._sidebar
	})
	Create("UIPadding", {
		PaddingTop = UDim.new(0, 8),
		PaddingLeft = UDim.new(0, 6),
		PaddingRight = UDim.new(0, 6),
		Parent = self._sidebar
	})

	-- Content Area
	self._content = Create("Frame", {
		Name = "Content",
		Position = UDim2.new(0, 130, 0, 40),
		Size = UDim2.new(1, -130, 1, -40),
		BackgroundTransparency = 1,
		Parent = self._mainFrame
	})

	-- Make draggable
	MakeDraggable(self._topBar, self._mainFrame)

	-- Minimize restore on click anywhere
	self._gui:GetPropertyChangedSignal("Enabled"):Connect(function() end)

	-- Re-show on double-click topbar
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

	-- Notification on load
	self:Notify({
		Title = windowName,
		Content = "Loaded successfully",
		Color = accentColor,
		Delay = 3
	})

	return self
end

-- ═══════════════════════════════════════════
-- TAB SYSTEM
-- ═══════════════════════════════════════════
function Library:MakeTab(name)
	local tab = {}
	tab._name = name
	tab._sections = {}

	-- Tab page (scrollable content)
	local page = Create("ScrollingFrame", {
		Name = name .. "Page",
		Size = UDim2.new(1, -16, 1, -16),
		Position = UDim2.new(0, 8, 0, 8),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		ScrollBarThickness = 3,
		ScrollBarImageColor3 = Colors.Accent,
		ScrollBarImageTransparency = 0.3,
		CanvasSize = UDim2.new(0, 0, 0, 0),
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
		Parent = self._content
	})
	Create("UIListLayout", {
		SortOrder = Enum.SortOrder.LayoutOrder,
		Padding = UDim.new(0, 8),
		Parent = page
	})

	tab._page = page

	-- Tab button in sidebar
	local order = #self._tabs + 1
	local btn = Create("TextButton", {
		Name = name .. "Btn",
		Size = UDim2.new(1, 0, 0, 32),
		BackgroundColor3 = Colors.ButtonDefault,
		BorderSizePixel = 0,
		Text = "",
		LayoutOrder = order,
		Parent = self._sidebar
	})
	Create("UICorner", { CornerRadius = UDim.new(0, 6), Parent = btn })

	local label = Create("TextLabel", {
		Name = "Label",
		Size = UDim2.new(1, -12, 1, 0),
		Position = UDim2.new(0, 12, 0, 0),
		BackgroundTransparency = 1,
		Text = name,
		TextColor3 = Colors.Subtext,
		Font = Fonts.Body,
		TextSize = 13,
		TextXAlignment = Enum.TextXAlignment.Left,
		Parent = btn
	})

	-- Active indicator bar
	local indicator = Create("Frame", {
		Name = "Indicator",
		Size = UDim2.new(0, 3, 0, 0),
		Position = UDim2.new(0, 0, 0.5, 0),
		AnchorPoint = Vector2.new(0, 0.5),
		BackgroundColor3 = Colors.Accent,
		BorderSizePixel = 0,
		Parent = btn
	})
	Create("UICorner", { CornerRadius = UDim.new(0, 2), Parent = indicator })

	-- Click handler
	btn.MouseButton1Click:Connect(function()
		CircleClick(btn, UserInputService:GetMouseLocation().X, UserInputService:GetMouseLocation().Y)

		-- Deactivate all tabs
		for _, t in ipairs(self._tabButtons) do
			TweenService:Create(t.btn, TweenInfo.new(0.2), { BackgroundColor3 = Colors.ButtonDefault }):Play()
			TweenService:Create(t.label, TweenInfo.new(0.2), { TextColor3 = Colors.Subtext }):Play()
			TweenService:Create(t.indicator, TweenInfo.new(0.2), { Size = UDim2.new(0, 3, 0, 0) }):Play()
			t.page.Visible = false
		end

		-- Activate this tab
		TweenService:Create(btn, TweenInfo.new(0.2), { BackgroundColor3 = Colors.AccentDark }):Play()
		TweenService:Create(label, TweenInfo.new(0.2), { TextColor3 = Colors.Text }):Play()
		TweenService:Create(indicator, TweenInfo.new(0.2), { Size = UDim2.new(0, 3, 0.6, 0) }):Play()
		page.Visible = true
	end)

	-- Store tab button info
	table.insert(self._tabButtons, {
		btn = btn,
		label = label,
		indicator = indicator,
		page = page
	})

	-- Auto-select first tab
	if #self._tabButtons == 1 then
		btn.BackgroundColor3 = Colors.AccentDark
		label.TextColor3 = Colors.Text
		indicator.Size = UDim2.new(0, 3, 0.6, 0)
	else
		page.Visible = false
	end

	-- Tab methods
	function tab:Section(config)
		config = config or {}
		local title = config.Title or "Section"
		local content = config.Content or ""

		local section = {}
		local sectionHeight = 33
		if content ~= "" then
			sectionHeight = 55
		end

		local frame = Create("Frame", {
			Name = title .. "Section",
			Size = UDim2.new(1, 0, 0, sectionHeight),
			BackgroundColor3 = Colors.Panel,
			BorderSizePixel = 0,
			Parent = page
		})
		Create("UICorner", { CornerRadius = UDim.new(0, 8), Parent = frame })
		Create("UIPadding", {
			PaddingTop = UDim.new(0, 8),
			PaddingBottom = UDim.new(0, 8),
			PaddingLeft = UDim.new(0, 12),
			PaddingRight = UDim.new(0, 12),
			Parent = frame
		})

		-- Title
		Create("TextLabel", {
			Name = "Title",
			Size = UDim2.new(1, 0, 0, 16),
			BackgroundTransparency = 1,
			Text = title,
			TextColor3 = Colors.Accent,
			Font = Fonts.Title,
			TextSize = 13,
			TextXAlignment = Enum.TextXAlignment.Left,
			Parent = frame
		})

		-- Description
		local descLabel = nil
		if content ~= "" then
			descLabel = Create("TextLabel", {
				Name = "Description",
				Position = UDim2.new(0, 0, 0, 20),
				Size = UDim2.new(1, 0, 0, 16),
				BackgroundTransparency = 1,
				Text = content,
				TextColor3 = Colors.Subtext,
				Font = Fonts.Small,
				TextSize = 11,
				TextXAlignment = Enum.TextXAlignment.Left,
				TextWrapped = true,
				Parent = frame
			})
		end

		-- Items container
		local itemsFrame = Create("Frame", {
			Name = "Items",
			Position = UDim2.new(0, 0, 0, sectionHeight - 8),
			Size = UDim2.new(1, 0, 0, 0),
			BackgroundTransparency = 1,
			Parent = frame
		})
		Create("UIListLayout", {
			SortOrder = Enum.SortOrder.LayoutOrder,
			Padding = UDim.new(0, 6),
			Parent = itemsFrame
		})

		-- Auto-resize section
		local function updateSize()
			local offsetY = 33
			for _, child in ipairs(itemsFrame:GetChildren()) do
				if child:IsA("GuiObject") then
					offsetY = offsetY + child.Size.Y.Offset + 6
				end
			end
			frame.Size = UDim2.new(1, 0, 0, offsetY)
		end

		itemsFrame.ChildAdded:Connect(updateSize)
		itemsFrame.ChildRemoved:Connect(updateSize)

		-- ── Section Items ──

		function section:Button(config)
			config = config or {}
			local btnTitle = config.Title or "Button"
			local btnContent = config.Content or ""
			local callback = config.Callback or function() end

			local btnHeight = btnContent ~= "" and 46 or 32

			local btnFrame = Create("Frame", {
				Name = btnTitle .. "Button",
				Size = UDim2.new(1, 0, 0, btnHeight),
				BackgroundTransparency = 1,
				Parent = itemsFrame
			})

			local btn = Create("TextButton", {
				Size = UDim2.new(1, 0, 1, 0),
				BackgroundColor3 = Colors.ButtonDefault,
				BorderSizePixel = 0,
				Text = "",
				Parent = btnFrame
			})
			Create("UICorner", { CornerRadius = UDim.new(0, 6), Parent = btn })

			Create("TextLabel", {
				Name = "Title",
				Position = UDim2.new(0, 10, 0, btnContent ~= "" and 4 or 0),
				Size = UDim2.new(1, -20, 0, 16),
				BackgroundTransparency = 1,
				Text = btnTitle,
				TextColor3 = Colors.Text,
				Font = Fonts.Body,
				TextSize = 13,
				TextXAlignment = Enum.TextXAlignment.Left,
				Parent = btn
			})

			if btnContent ~= "" then
				Create("TextLabel", {
					Name = "Content",
					Position = UDim2.new(0, 10, 0, 22),
					Size = UDim2.new(1, -20, 0, 14),
					BackgroundTransparency = 1,
					Text = btnContent,
					TextColor3 = Colors.Subtext,
					Font = Fonts.Small,
					TextSize = 11,
					TextXAlignment = Enum.TextXAlignment.Left,
					Parent = btn
				})
			end

			-- Hover
			btn.MouseEnter:Connect(function()
				TweenService:Create(btn, TweenInfo.new(0.15), { BackgroundColor3 = Colors.ButtonHover }):Play()
			end)
			btn.MouseLeave:Connect(function()
				TweenService:Create(btn, TweenInfo.new(0.15), { BackgroundColor3 = Colors.ButtonDefault }):Play()
			end)

			btn.MouseButton1Click:Connect(function()
				CircleClick(btn, UserInputService:GetMouseLocation().X, UserInputService:GetMouseLocation().Y)
				callback()
			end)

			return { Set = function(_, val) end }
		end

		function section:Toggle(config)
			config = config or {}
			local toggleTitle = config.Title or "Toggle"
			local toggleContent = config.Content or ""
			local default = config.Default or false
			local callback = config.Callback or function() end
			local flag = config.Flag

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
				Parent = itemsFrame
			})

			Create("TextLabel", {
				Name = "Title",
				Position = UDim2.new(0, 10, 0, toggleContent ~= "" and 4 or 0),
				Size = UDim2.new(1, -60, 0, 16),
				BackgroundTransparency = 1,
				Text = toggleTitle,
				TextColor3 = Colors.Text,
				Font = Fonts.Body,
				TextSize = 13,
				TextXAlignment = Enum.TextXAlignment.Left,
				Parent = toggleFrame
			})

			if toggleContent ~= "" then
				Create("TextLabel", {
					Name = "Content",
					Position = UDim2.new(0, 10, 0, 22),
					Size = UDim2.new(1, -60, 0, 14),
					BackgroundTransparency = 1,
					Text = toggleContent,
					TextColor3 = Colors.Subtext,
					Font = Fonts.Small,
					TextSize = 11,
					TextXAlignment = Enum.TextXAlignment.Left,
					Parent = toggleFrame
				})
			end

			-- Toggle track
			local track = Create("Frame", {
				Name = "Track",
				AnchorPoint = Vector2.new(1, 0.5),
				Position = UDim2.new(1, -10, 0.5, 0),
				Size = UDim2.new(0, 40, 0, 20),
				BackgroundColor3 = toggled and Colors.Accent or Colors.ToggleOff,
				BorderSizePixel = 0,
				Parent = toggleFrame
			})
			Create("UICorner", { CornerRadius = UDim.new(1, 0), Parent = track })

			-- Toggle knob
			local knob = Create("Frame", {
				Name = "Knob",
				Position = toggled and UDim2.new(1, -22, 0.5, -8) or UDim2.new(0, 4, 0.5, -8),
				Size = UDim2.new(0, 16, 0, 16),
				BackgroundColor3 = Colors.Text,
				BorderSizePixel = 0,
				Parent = track
			})
			Create("UICorner", { CornerRadius = UDim.new(1, 0), Parent = knob })

			-- Toggle function
			local toggleFunc = {}

			local function setToggle(val)
				toggled = val
				local newPos = val and UDim2.new(1, -22, 0.5, -8) or UDim2.new(0, 4, 0.5, -8)
				local newColor = val and Colors.Accent or Colors.ToggleOff
				TweenService:Create(knob, TweenInfo.new(0.2, Enum.EasingStyle.Quad), { Position = newPos }):Play()
				TweenService:Create(track, TweenInfo.new(0.2), { BackgroundColor3 = newColor }):Play()

				-- Save flag
				if flag and self._saveFolder then
					self._flags[flag] = val
					pcall(function()
						writefile(self._saveFolder .. ".json", HttpService:JSONEncode(self._flags))
					end)
				end

				callback(val)
			end

			-- Initialize with default
			if toggled then
				knob.Position = UDim2.new(1, -22, 0.5, -8)
				track.BackgroundColor3 = Colors.Accent
			end

			-- Click to toggle
			track.InputBegan:Connect(function(input)
				if input.UserInputType == Enum.UserInputType.MouseButton1 then
					setToggle(not toggled)
				end
			end)

			toggleFrame.InputBegan:Connect(function(input)
				if input.UserInputType == Enum.UserInputType.MouseButton1 then
					setToggle(not toggled)
				end
			end)

			function toggleFunc:Set(val)
				setToggle(val)
			end

			return toggleFunc
		end

		function section:Slider(config)
			config = config or {}
			local sliderTitle = config.Title or "Slider"
			local sliderContent = config.Content or ""
			local min = config.Min or 0
			local max = config.Max or 100
			local increment = config.Increment or 1
			local default = config.Default or 50
			local callback = config.Callback or function() end

			local value = default
			local sliderHeight = sliderContent ~= "" and 60 or 48

			local sliderFrame = Create("Frame", {
				Name = sliderTitle .. "Slider",
				Size = UDim2.new(1, 0, 0, sliderHeight),
				BackgroundTransparency = 1,
				Parent = itemsFrame
			})

			Create("TextLabel", {
				Name = "Title",
				Position = UDim2.new(0, 10, 0, sliderContent ~= "" and 4 or 2),
				Size = UDim2.new(0.6, 0, 0, 16),
				BackgroundTransparency = 1,
				Text = sliderTitle,
				TextColor3 = Colors.Text,
				Font = Fonts.Body,
				TextSize = 13,
				TextXAlignment = Enum.TextXAlignment.Left,
				Parent = sliderFrame
			})

			-- Value label
			local valueLabel = Create("TextLabel", {
				Name = "Value",
				Position = UDim2.new(1, -50, 0, sliderContent ~= "" and 4 or 2),
				Size = UDim2.new(0, 40, 0, 16),
				BackgroundTransparency = 1,
				Text = tostring(value),
				TextColor3 = Colors.Accent,
				Font = Fonts.Body,
				TextSize = 13,
				TextXAlignment = Enum.TextXAlignment.Right,
				Parent = sliderFrame
			})

			if sliderContent ~= "" then
				Create("TextLabel", {
					Name = "Content",
					Position = UDim2.new(0, 10, 0, 22),
					Size = UDim2.new(1, -20, 0, 14),
					BackgroundTransparency = 1,
					Text = sliderContent,
					TextColor3 = Colors.Subtext,
					Font = Fonts.Small,
					TextSize = 11,
					TextXAlignment = Enum.TextXAlignment.Left,
					Parent = sliderFrame
				})
			end

			-- Slider track
			local trackY = sliderContent ~= "" and 42 or 30
			local trackBg = Create("Frame", {
				Name = "TrackBg",
				Position = UDim2.new(0, 10, 0, trackY),
				Size = UDim2.new(1, -20, 0, 6),
				BackgroundColor3 = Colors.SliderTrack,
				BorderSizePixel = 0,
				Parent = sliderFrame
			})
			Create("UICorner", { CornerRadius = UDim.new(1, 0), Parent = trackBg })

			-- Fill bar
			local fillPercent = (value - min) / (max - min)
			local fill = Create("Frame", {
				Name = "Fill",
				Size = UDim2.new(fillPercent, 0, 1, 0),
				BackgroundColor3 = Colors.Accent,
				BorderSizePixel = 0,
				Parent = trackBg
			})
			Create("UICorner", { CornerRadius = UDim.new(1, 0), Parent = fill })

			-- Knob
			local knobDot = Create("Frame", {
				Name = "Knob",
				AnchorPoint = Vector2.new(0.5, 0.5),
				Position = UDim2.new(fillPercent, 0, 0.5, 0),
				Size = UDim2.new(0, 14, 0, 14),
				BackgroundColor3 = Colors.Text,
				BorderSizePixel = 0,
				Parent = trackBg
			})
			Create("UICorner", { CornerRadius = UDim.new(1, 0), Parent = knobDot })

			-- Slider logic
			local sliding = false

			local function updateSlider(inputX)
				local relX = math.clamp((inputX - trackBg.AbsolutePosition.X) / trackBg.AbsoluteSize.X, 0, 1)
				value = Round(min + (max - min) * relX, increment)
				value = math.clamp(value, min, max)
				local pct = (value - min) / (max - min)
				TweenService:Create(fill, TweenInfo.new(0.1), { Size = UDim2.new(pct, 0, 1, 0) }):Play()
				TweenService:Create(knobDot, TweenInfo.new(0.1), { Position = UDim2.new(pct, 0, 0.5, 0) }):Play()
				valueLabel.Text = tostring(value)
				callback(value)
			end

			trackBg.InputBegan:Connect(function(input)
				if input.UserInputType == Enum.UserInputType.MouseButton1 then
					sliding = true
					updateSlider(input.Position.X)
				end
			end)

			UserInputService.InputEnded:Connect(function(input)
				if input.UserInputType == Enum.UserInputType.MouseButton1 then
					sliding = false
				end
			end)

			UserInputService.InputChanged:Connect(function(input)
				if sliding and input.UserInputType == Enum.UserInputType.MouseMovement then
					updateSlider(input.Position.X)
				end
			end)

			local sliderFunc = {}
			function sliderFunc:Set(val)
				value = math.clamp(val, min, max)
				local pct = (value - min) / (max - min)
				fill.Size = UDim2.new(pct, 0, 1, 0)
				knobDot.Position = UDim2.new(pct, 0, 0.5, 0)
				valueLabel.Text = tostring(value)
				callback(value)
			end

			return sliderFunc
		end

		function section:Dropdown(config)
			config = config or {}
			local dropTitle = config.Title or "Dropdown"
			local multi = config.Multi or false
			local options = config.Options or {}
			local default = config.Default or (multi and {} or { options[1] })
			local callback = config.Callback or function() end
			local placeholder = config.PlaceHolderText or "Select Options"

			local selected = multi and {} or (default[1] or nil)
			local dropped = false

			local dropHeight = 34
			local dropFrame = Create("Frame", {
				Name = dropTitle .. "Dropdown",
				Size = UDim2.new(1, 0, 0, dropHeight),
				BackgroundColor3 = Colors.Panel,
				BorderSizePixel = 0,
				ClipsDescendants = true,
				Parent = itemsFrame
			})
			Create("UICorner", { CornerRadius = UDim.new(0, 6), Parent = dropFrame })

			Create("TextLabel", {
				Name = "Title",
				Position = UDim2.new(0, 10, 0, 8),
				Size = UDim2.new(1, -20, 0, 16),
				BackgroundTransparency = 1,
				Text = dropTitle,
				TextColor3 = Colors.Text,
				Font = Fonts.Body,
				TextSize = 13,
				TextXAlignment = Enum.TextXAlignment.Left,
				Parent = dropFrame
			})

			-- Selected display
			local displayText = multi and placeholder or (selected or placeholder)
			local display = Create("TextLabel", {
				Name = "Display",
				Position = UDim2.new(0, 10, 0, 26),
				Size = UDim2.new(1, -30, 0, 18),
				BackgroundTransparency = 1,
				Text = displayText,
				TextColor3 = Colors.Accent,
				Font = Fonts.Small,
				TextSize = 12,
				TextXAlignment = Enum.TextXAlignment.Left,
				Parent = dropFrame
			})

			-- Arrow
			local arrow = Create("TextLabel", {
				Name = "Arrow",
				Position = UDim2.new(1, -24, 0, 8),
				Size = UDim2.new(0, 16, 0, 16),
				BackgroundTransparency = 1,
				Text = "▼",
				TextColor3 = Colors.Subtext,
				Font = Fonts.Small,
				TextSize = 10,
				Parent = dropFrame
			})

			-- Options container
			local optionsFrame = Create("Frame", {
				Name = "Options",
				Position = UDim2.new(0, 0, 0, 48),
				Size = UDim2.new(1, 0, 0, 0),
				BackgroundTransparency = 1,
				Parent = dropFrame
			})
			Create("UIListLayout", {
				SortOrder = Enum.SortOrder.LayoutOrder,
				Padding = UDim.new(0, 2),
				Parent = optionsFrame
			})

			-- Build options
			local optionButtons = {}

			local function updateDisplay()
				if multi then
					if #selected == 0 then
						display.Text = placeholder
					else
						display.Text = table.concat(selected, ", ")
					end
				else
					display.Text = selected or placeholder
				end
			end

			local function toggleOption(opt)
				if multi then
					local idx = table.find(selected, opt)
					if idx then
						table.remove(selected, idx)
					else
						table.insert(selected, opt)
					end
				else
					selected = opt
					dropped = false
					-- Collapse
					local targetH = 48 + 2
					TweenService:Create(dropFrame, TweenInfo.new(0.2), { Size = UDim2.new(1, 0, 0, targetH) }):Play()
					TweenService:Create(arrow, TweenInfo.new(0.2), { Rotation = 0 }):Play()
				end
				updateDisplay()
				callback(selected)
			end

			for i, opt in ipairs(options) do
				local optBtn = Create("TextButton", {
					Name = opt,
					Size = UDim2.new(1, -12, 0, 26),
					Position = UDim2.new(0, 6, 0, 0),
					BackgroundColor3 = Colors.ButtonDefault,
					BorderSizePixel = 0,
					Text = "",
					LayoutOrder = i,
					Parent = optionsFrame
				})
				Create("UICorner", { CornerRadius = UDim.new(0, 4), Parent = optBtn })

				Create("TextLabel", {
					Name = "Label",
					Position = UDim2.new(0, 10, 0, 0),
					Size = UDim2.new(1, -20, 1, 0),
					BackgroundTransparency = 1,
					Text = opt,
					TextColor3 = Colors.Text,
					Font = Fonts.Small,
					TextSize = 12,
					TextXAlignment = Enum.TextXAlignment.Left,
					Parent = optBtn
				})

				optBtn.MouseButton1Click:Connect(function()
					toggleOption(opt)
				end)

				optionButtons[opt] = optBtn
			end

			-- Toggle dropdown
			local function toggleDrop()
				dropped = not dropped
				local optCount = #options
				local targetH = dropped and (48 + optCount * 28 + 4) or 48
				TweenService:Create(dropFrame, TweenInfo.new(0.25, Enum.EasingStyle.Quad), { Size = UDim2.new(1, 0, 0, targetH) }):Play()
				TweenService:Create(arrow, TweenInfo.new(0.25), { Rotation = dropped and 180 or 0 }):Play()
			end

			dropFrame.InputBegan:Connect(function(input)
				if input.UserInputType == Enum.UserInputType.MouseButton1 then
					toggleDrop()
				end
			end)

			updateDisplay()

			local dropFunc = {}
			function dropFunc:Set(val)
				if multi then
					selected = type(val) == "table" and val or { val }
				else
					selected = val
				end
				updateDisplay()
				callback(selected)
			end
			function dropFunc:Add(opt)
				table.insert(options, opt)
				local optBtn = Create("TextButton", {
					Name = opt,
					Size = UDim2.new(1, -12, 0, 26),
					Position = UDim2.new(0, 6, 0, 0),
					BackgroundColor3 = Colors.ButtonDefault,
					BorderSizePixel = 0,
					Text = "",
					LayoutOrder = #options,
					Parent = optionsFrame
				})
				Create("UICorner", { CornerRadius = UDim.new(0, 4), Parent = optBtn })
				Create("TextLabel", {
					Name = "Label",
					Position = UDim2.new(0, 10, 0, 0),
					Size = UDim2.new(1, -20, 1, 0),
					BackgroundTransparency = 1,
					Text = opt,
					TextColor3 = Colors.Text,
					Font = Fonts.Small,
					TextSize = 12,
					TextXAlignment = Enum.TextXAlignment.Left,
					Parent = optBtn
				})
				optBtn.MouseButton1Click:Connect(function()
					toggleOption(opt)
				end)
			end
			function dropFunc:Clear()
				options = {}
				for _, child in ipairs(optionsFrame:GetChildren()) do
					if child:IsA("TextButton") then child:Destroy() end
				end
				selected = multi and {} or nil
				updateDisplay()
			end
			function dropFunc:Refresh(newOpts, newDefault)
				self:Clear()
				options = newOpts
				for i, opt in ipairs(options) do
					self:Add(opt)
				end
				if newDefault then
					self:Set(newDefault)
				end
			end

			return dropFunc
		end

		function section:TextInput(config)
			config = config or {}
			local inputTitle = config.Title or "Input"
			local inputContent = config.Content or ""
			local placeholder = config.PlaceHolderText or "Enter text..."
			local clearOnFocus = config.ClearTextOnFocus ~= false
			local default = config.Default or ""
			local callback = config.Callback or function() end

			local inputHeight = inputContent ~= "" and 60 or 46

			local inputFrame = Create("Frame", {
				Name = inputTitle .. "Input",
				Size = UDim2.new(1, 0, 0, inputHeight),
				BackgroundTransparency = 1,
				Parent = itemsFrame
			})

			Create("TextLabel", {
				Name = "Title",
				Position = UDim2.new(0, 10, 0, 4),
				Size = UDim2.new(1, -20, 0, 16),
				BackgroundTransparency = 1,
				Text = inputTitle,
				TextColor3 = Colors.Text,
				Font = Fonts.Body,
				TextSize = 13,
				TextXAlignment = Enum.TextXAlignment.Left,
				Parent = inputFrame
			})

			if inputContent ~= "" then
				Create("TextLabel", {
					Name = "Content",
					Position = UDim2.new(0, 10, 0, 20),
					Size = UDim2.new(1, -20, 0, 14),
					BackgroundTransparency = 1,
					Text = inputContent,
					TextColor3 = Colors.Subtext,
					Font = Fonts.Small,
					TextSize = 11,
					TextXAlignment = Enum.TextXAlignment.Left,
					Parent = inputFrame
				})
			end

			local box = Create("TextBox", {
				Name = "Box",
				Position = UDim2.new(0, 10, 0, inputContent ~= "" and 38 or 24),
				Size = UDim2.new(1, -20, 0, 22),
				BackgroundColor3 = Colors.ButtonDefault,
				BorderSizePixel = 0,
				ClearTextOnFocus = clearOnFocus,
				Text = default,
				TextColor3 = Colors.Text,
				PlaceholderText = placeholder,
				PlaceholderColor3 = Colors.Subtext,
				Font = Fonts.Small,
				TextSize = 12,
				TextXAlignment = Enum.TextXAlignment.Left,
				Parent = inputFrame
			})
			Create("UICorner", { CornerRadius = UDim.new(0, 4), Parent = box })
			Create("UIPadding", {
				PaddingLeft = UDim.new(0, 8),
				PaddingRight = UDim.new(0, 8),
				Parent = box
			})

			box.FocusLost:Connect(function()
				callback(box.Text)
			end)

			local inputFunc = {}
			function inputFunc:Set(val)
				box.Text = val
				callback(val)
			end

			return inputFunc
		end

		function section:Paragraph(config)
			config = config or {}
			local paraTitle = config.Title or ""
			local paraContent = config.Content or ""

			local paraHeight = 30
			if paraContent ~= "" then paraHeight = 48 end
			if paraTitle ~= "" and paraContent ~= "" then paraHeight = 48 end

			local paraFrame = Create("Frame", {
				Name = "Paragraph",
				Size = UDim2.new(1, 0, 0, paraHeight),
				BackgroundTransparency = 1,
				Parent = itemsFrame
			})

			local titleLabel = Create("TextLabel", {
				Name = "Title",
				Position = UDim2.new(0, 4, 0, 0),
				Size = UDim2.new(1, -8, 0, 16),
				BackgroundTransparency = 1,
				Text = paraTitle,
				TextColor3 = Colors.Text,
				Font = Fonts.Body,
				TextSize = 13,
				TextXAlignment = Enum.TextXAlignment.Left,
				Parent = paraFrame
			})

			local contentLabel = nil
			if paraContent ~= "" then
				contentLabel = Create("TextLabel", {
					Name = "Content",
					Position = UDim2.new(0, 4, 0, 18),
					Size = UDim2.new(1, -8, 0, 14),
					BackgroundTransparency = 1,
					Text = paraContent,
					TextColor3 = Colors.Subtext,
					Font = Fonts.Small,
					TextSize = 11,
					TextXAlignment = Enum.TextXAlignment.Left,
					TextWrapped = true,
					Parent = paraFrame
				})
			end

			local paraFunc = {}
			function paraFunc:Set(cfg)
				cfg = cfg or {}
				if cfg.Title then titleLabel.Text = cfg.Title end
				if cfg.Content and contentLabel then
					contentLabel.Text = cfg.Content
				elseif cfg.Content then
					contentLabel = Create("TextLabel", {
						Name = "Content",
						Position = UDim2.new(0, 4, 0, 18),
						Size = UDim2.new(1, -8, 0, 14),
						BackgroundTransparency = 1,
						Text = cfg.Content,
						TextColor3 = Colors.Subtext,
						Font = Fonts.Small,
						TextSize = 11,
						TextXAlignment = Enum.TextXAlignment.Left,
						TextWrapped = true,
						Parent = paraFrame
					})
				end
			end

			return paraFunc
		end

		function section:Seperator(name)
			name = name or ""

			local sepFrame = Create("Frame", {
				Name = "Separator",
				Size = UDim2.new(1, 0, 0, 20),
				BackgroundTransparency = 1,
				Parent = itemsFrame
			})

			Create("Frame", {
				Name = "Line",
				Position = UDim2.new(0, 0, 0.5, 0),
				Size = UDim2.new(1, 0, 0, 1),
				BackgroundColor3 = Colors.Border,
				BorderSizePixel = 0,
				Parent = sepFrame
			})

			if name ~= "" then
				Create("TextLabel", {
					Name = "Label",
					Position = UDim2.new(0.5, 0, 0.5, 0),
					AnchorPoint = Vector2.new(0.5, 0.5),
					Size = UDim2.new(0, 0, 0, 14),
					BackgroundColor3 = Colors.Panel,
					BorderSizePixel = 0,
					Text = "  " .. name .. "  ",
					TextColor3 = Colors.Subtext,
					Font = Fonts.Small,
					TextSize = 11,
					Parent = sepFrame
				})
			end

			local sepFunc = {}
			function sepFunc:Set(newName)
				if newName then
					name = newName
				end
			end
			return sepFunc
		end

		return section
	end

	-- Store tab reference
	table.insert(self._tabs, tab)

	-- Method to show a tab by name
	function Library:ShowTab(tabName)
		for _, t in ipairs(self._tabButtons) do
			if t.btn.Name == tabName .. "Btn" then
				t.btn.MouseButton1Click:Fire()
				break
			end
		end
	end

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
end

return Library