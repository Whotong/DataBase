-- Re: Hub — Mist. Construction and rendering never invoke feature callbacks.
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local HttpService = game:GetService("HttpService")
local Workspace = game:GetService("Workspace")
local Library = { Version = "3.0.0-mist" }
Library.__index = Library
local activeWindow
local Section = {}
Section.__index = Section
local Tokens = {
	Color = {
		Canvas = Color3.fromRGB(16,21,26), Shell = Color3.fromRGB(21,29,35), Raised = Color3.fromRGB(29,40,48),
		Hover = Color3.fromRGB(38,52,61), Text = Color3.fromRGB(238,243,241), Secondary = Color3.fromRGB(175,191,190),
		Quiet = Color3.fromRGB(137,157,156), Divider = Color3.fromRGB(52,69,76), Accent = Color3.fromRGB(182,214,205),
		Active = Color3.fromRGB(208,233,224), Warning = Color3.fromRGB(220,198,155), Error = Color3.fromRGB(240,165,160),
	},
	Space = {4,8,12,16,24,32}, Radius = {Shell=18, Panel=12, Control=9},
	Type = {Heading=24, Section=18, Action=16, Body=14, Meta=12},
	Motion = {Feedback=0.11, Switch=0.16, Expand=0.18, Page=0.16, Open=0.2},
}
Library.Tokens = Tokens
local C = Tokens.Color
local function create(class, props, parent)
	local inst = Instance.new(class)
	for key,value in pairs(props or {}) do inst[key] = value end
	inst.Parent = parent
	return inst
end
local function frame(parent, name)
	return create("Frame", {Name=name, BackgroundTransparency=1, BorderSizePixel=0,
		Size=UDim2.new(1,0,0,0), AutomaticSize=Enum.AutomaticSize.Y}, parent)
end
local function round(inst, radius) create("UICorner", {CornerRadius=UDim.new(0,radius or Tokens.Radius.Control)}, inst) end
local function pad(inst, x, y)
	return create("UIPadding", {PaddingLeft=UDim.new(0,x), PaddingRight=UDim.new(0,x),
		PaddingTop=UDim.new(0,y or x), PaddingBottom=UDim.new(0,y or x)}, inst)
end
local function list(inst, gap, horizontal)
	return create("UIListLayout", {Padding=UDim.new(0,gap or 8), SortOrder=Enum.SortOrder.LayoutOrder,
		FillDirection=horizontal and Enum.FillDirection.Horizontal or Enum.FillDirection.Vertical}, inst)
end
local function label(parent, text, size, color, bold)
	return create("TextLabel", {BackgroundTransparency=1, BorderSizePixel=0, Text=text or "", TextColor3=color or C.Text,
		Font=bold and Enum.Font.GothamSemibold or Enum.Font.Gotham, TextSize=size or 14, TextWrapped=true,
		TextXAlignment=Enum.TextXAlignment.Left, TextYAlignment=Enum.TextYAlignment.Top,
		Size=UDim2.new(1,0,0,0), AutomaticSize=Enum.AutomaticSize.Y}, parent)
end
local function resolve(self) return self == Library and activeWindow or self end
local function keyId(text) return (tostring(text):lower():gsub("[^%w]+", "-")) end
local function isPointer(input)
	return input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch
end
function Library:Connect(signal, fn)
	local win = resolve(self)
	local connection = signal:Connect(fn)
	table.insert(win._connectionScope or win._connections, connection)
	return connection
end
function Library:_later(seconds, fn)
	local thread
	thread = task.delay(seconds, function()
		self._tasks[thread] = nil
		if not self._closed then fn() end
	end)
	self._tasks[thread] = true
	return thread
end
function Library:_activate(button, fn)
	local pointerStart
	self:Connect(button.InputBegan,function(input) if isPointer(input) then pointerStart=input.Position end end)
	self:Connect(button.Activated, function(input)
		if self._closed then return end
		if input and isPointer(input) and pointerStart then
			local delta=input.Position-pointerStart
			if math.abs(delta.X)>10 or math.abs(delta.Y)>10 then return end
		end
		local thread
		thread = task.defer(function()
			local ok,err = pcall(fn)
			self._connectionScope=nil
			self._tasks[thread] = nil
			if not ok and not self._closed then self:ReportError(button.Name, err) end
		end)
		self._tasks[thread] = true
	end)
end
function Library:_tween(inst, duration, props)
	local old = self._tweens[inst]
	if old then old:Cancel() end
	if self._prefs.ReducedMotion then for k,v in pairs(props) do inst[k]=v end return end
	local tween = TweenService:Create(inst,TweenInfo.new(duration,Enum.EasingStyle.Quad,Enum.EasingDirection.Out),props)
	self._tweens[inst] = tween
	tween:Play()
end
function Library:_button(parent, text, callback, width)
	local button = create("TextButton", {Name=text, Text=text, TextSize=14, Font=Enum.Font.GothamMedium,
		TextWrapped=true, TextColor3=C.Text, BackgroundColor3=C.Raised, BorderSizePixel=0,
		Size=UDim2.new(width and 0 or 1,width or 0,0,44), AutoButtonColor=false, Selectable=true}, parent)
	round(button) pad(button,8,4)
	local stroke = create("UIStroke", {Color=C.Divider, Thickness=1, Transparency=0.5, ApplyStrokeMode=Enum.ApplyStrokeMode.Border},button)
	local function hover(on) self:_tween(button,Tokens.Motion.Feedback,{BackgroundColor3=on and C.Hover or C.Raised}) end
	self:Connect(button.MouseEnter,function() hover(true) end)
	self:Connect(button.MouseLeave,function() hover(false) end)
	self:Connect(button.SelectionGained,function() stroke.Color=C.Accent end)
	self:Connect(button.SelectionLost,function() stroke.Color=C.Divider end)
	self:Connect(button.InputBegan,function(input) if isPointer(input) then hover(true) end end)
	self:Connect(button.InputEnded,function(input) if isPointer(input) then hover(false) end end)
	if callback then self:_activate(button,callback) end
	return button
end
function Library:_textBox(parent, placeholder, value)
	local box = create("TextBox", {Name=placeholder, Text=value or "", PlaceholderText=placeholder, ClearTextOnFocus=false,
		TextColor3=C.Text, PlaceholderColor3=C.Quiet, TextSize=14, Font=Enum.Font.Gotham, TextXAlignment=Enum.TextXAlignment.Left,
		BackgroundColor3=C.Raised, BorderSizePixel=0, Size=UDim2.new(1,0,0,44)}, parent)
	round(box) pad(box,12,6)
	local stroke = create("UIStroke", {Color=C.Divider,ApplyStrokeMode=Enum.ApplyStrokeMode.Border},box)
	self:Connect(box.Focused,function()
		stroke.Color=C.Accent
		self:_later(0.15,function() self:_revealInput(box) end)
	end)
	self:Connect(box.FocusLost,function() stroke.Color=C.Divider end)
	return box
end
function Library:SaveFlags()
	local win=resolve(self)
	if not win or not win._saveFolder or type(writefile) ~= "function" then return false end
	local ok,data=pcall(HttpService.JSONEncode,HttpService,win._flags)
	if not ok then return false end
	return pcall(writefile,win._saveFolder..".json",data)
end
function Library:_savePrefs() self._flags.Interface=self._prefs self:SaveFlags() end
function Library:SetPreference(key,value)
	local win=resolve(self)
	if key=="Scale" then value=math.clamp(tonumber(value) or 1,0.85,1.25) end
	win._prefs[key]=value win:_savePrefs() win:_layout()
end
function Library:Notify(config)
	local win=resolve(self)
	if not win or win._closed or win._prefs.Notifications==false then return end
	while #win._notices>=2 do table.remove(win._notices,1):Destroy() end
	local notice=frame(win._notifications,"Notice")
	notice.BackgroundTransparency=0 notice.BackgroundColor3=C.Raised round(notice,12) pad(notice,12) list(notice,4)
	label(notice,config.Title or "Re: Hub",14,config.Color or C.Accent,true)
	label(notice,config.Content or "",14,C.Secondary)
	table.insert(win._notices,notice)
	win:_later(config.Delay or 5,function()
		local i=table.find(win._notices,notice) if i then table.remove(win._notices,i) end
		notice:Destroy()
	end)
end
function Library:ReportError(source,err)
	local win=resolve(self)
	if not win then warn("Re: Hub "..tostring(source)..": "..tostring(err)) return end
	local message=tostring(err):sub(1,600)
	local signature=tostring(source)..message
	local now=os.clock()
	if win._errorTimes[signature] and now-win._errorTimes[signature]<10 then return end
	win._errorTimes[signature]=now
	local entry={t=os.date("%H:%M:%S"),source=tostring(source),message=message}
	table.insert(win._errors,entry) if #win._errors>50 then table.remove(win._errors,1) end
	for _,fn in ipairs(win._errorWatchers) do pcall(fn,entry) end
	warn("REHUB_ERR ["..entry.source.."] "..message)
	win:Notify({Title="Error · "..entry.source,Content=message.." · See Settings / Diagnostics.",Color=C.Error,Delay=8})
end
function Library:GetErrors() return table.clone(resolve(self)._errors) end
function Library:ClearErrors()
	local win=resolve(self) table.clear(win._errors)
	for _,fn in ipairs(win._errorWatchers) do pcall(fn) end
end
function Library:WatchErrors(fn)
	local win=resolve(self) table.insert(win._errorWatchers,fn)
	return function() local i=table.find(win._errorWatchers,fn) if i then table.remove(win._errorWatchers,i) end end
end

-- Set invokes callbacks (legacy contract). Sync publishes module-owned state
-- without invoking callbacks. Every Home and Actions view binds this same object.
function Library:RegisterAction(def)
	assert(type(def.Id)=="string" and not self._actions[def.Id],"Duplicate action ID: "..tostring(def.Id))
	local win=self
	local action={Id=def.Id,Title=def.Title,Description=def.Content or def.Description or "",Category=def.Category,
		Kind=def.Kind or "Toggle",Enabled=false,Busy=false,Available=def.Available~=false,Reason=def.UnavailableReason,
		_views={},_def=def,_section=def.Section}
	function action:_publish() for _,render in ipairs(self._views) do render() end win:_updateActions() end
	function action:Get() return self.Enabled end
	function action:Sync(value,status) self.Enabled=value==true self.Status=status self:_publish() end
	function action:SetStatus(status) self.Status=status self:_publish() end
	function action:SetAvailable(available,reason) self.Available=available==true self.Reason=reason self:_publish() end
	function action:Set(value)
		value=value==true
		if win._closed or (win._closing and value) then return false end
		if self.Busy then
			if value or self.Kind~="Toggle" or not self._requestThread or self._requestThread==coroutine.running() then return false end
			local cancelled,err=pcall(task.cancel,self._requestThread)
			if not cancelled then win:ReportError(self.Id.."/cancel",err) return false end
			self.Busy=false self.Enabled=true -- force the owning callback's off path
		end
		if self.Kind=="Toggle" and value==self.Enabled then return true end
		self.Busy=true self.Error=nil self.Status=nil self._requestThread=coroutine.running() self:_publish()
		if value then
			if def.CanActivate then
				local ok,available,reason=pcall(def.CanActivate)
				self.Available=ok and available==true self.Reason=ok and reason or tostring(available)
			end
			if not self.Available then self.Busy=false self._requestThread=nil self:_publish() return false end
		end
		local ok,result=pcall(def.Callback or function() end,value)
		if ok and result~=false then
			if self.Kind=="Toggle" then self.Enabled=value end
			if self.Kind=="Button" then self.Status=def.Feedback or "Check the game or action details for the result." end
		else
			self.Error=tostring(ok and "Request declined" or result)
			if value and self.Kind=="Toggle" then
				local cleaned,cleanupResult=pcall(def.Callback or function() end,false)
				if not cleaned or cleanupResult==false then
					self.Enabled=true self.Error..=" · Cleanup needs attention: "..tostring(cleanupResult)
				end
			end
			win:ReportError(self.Id,self.Error)
		end
		self.Busy=false self._requestThread=nil self:_publish()
		return ok and result~=false
	end
	function action:Invoke() return self:Set(true) end
	self._actions[def.Id]=action table.insert(self._actionOrder,action)
	return action
end
function Library:GetAction(id) return self._actions[id] end
function Library:StopAll()
	local win=resolve(self)
	local failed={}
	for _,action in ipairs(win._actionOrder) do
		if action.Kind=="Toggle" and (action.Enabled or action.Busy) then
			if not action:Set(false) then table.insert(failed,action.Title) end
		end
	end
	win._stopStatus.Text=#failed>0 and ("Stop needs attention: "..table.concat(failed,", "))
		or "Stop requested for enabled controls. Already-sent server requests cannot be recalled."
	return #failed==0
end
function Library:_actionView(parent,action,shortcut)
	local row=frame(parent,action.Id) pad(row,shortcut and 16 or 0,12)
	if shortcut then row.BackgroundTransparency=0 row.BackgroundColor3=C.Raised round(row,12) end
	local body=frame(row,"Copy") body.Size=UDim2.new(1,-100,0,0) list(body,5)
	label(body,action.Title,16,C.Text,true)
	if action.Description~="" then label(body,action.Description,14,C.Secondary) end
	local status=label(body,"Off",12,C.Quiet)
	local control=self:_button(row,"Off",nil,88)
	control.AnchorPoint=Vector2.new(1,0) control.Position=UDim2.new(1,0,0,0)
	local track,knob
	if action.Kind=="Toggle" then
		control.Text="" control.BackgroundTransparency=1
		track=create("Frame",{Name="Switch",BorderSizePixel=0,BackgroundColor3=C.Divider,
			Size=UDim2.fromOffset(44,26),Position=UDim2.new(1,-44,0,9)},control) round(track,13)
		knob=create("Frame",{Name="Knob",BorderSizePixel=0,BackgroundColor3=C.Text,
			Size=UDim2.fromOffset(18,18),Position=UDim2.fromOffset(4,4)},track) round(knob,9)
	end
	local function render()
		status.Text=action.Busy and "Please wait" or action.Error and ("Error · "..action.Error)
			or not action.Available and (action.Reason or "Unavailable") or action.Status
			or (action.Kind=="Toggle" and (action.Enabled and "Enabled" or "Off") or "One-shot action")
		status.TextColor3=action.Error and C.Error or action.Enabled and C.Accent or C.Quiet
		control.Active=not action.Busy and (action.Available or action.Enabled or action._def.CanActivate~=nil) control.Selectable=control.Active
		if track then
			self:_tween(track,Tokens.Motion.Switch,{BackgroundColor3=action.Enabled and C.Accent or C.Divider})
			self:_tween(knob,Tokens.Motion.Switch,{Position=UDim2.fromOffset(action.Enabled and 22 or 4,4),BackgroundColor3=action.Enabled and C.Shell or C.Text})
		else control.Text=action.Busy and "Wait…" or action._def.ButtonText or "Run" end
	end
	table.insert(action._views,render)
	self:_activate(control,function() if action.Kind=="Toggle" then action:Set(not action.Enabled) else action:Invoke() end end)
	if shortcut and action._section then
		local settings=self:_button(body,action._section.HasConfig and "Settings →" or "View in Actions →",function() self:FocusSection(action._section) end) settings.LayoutOrder=10
	end
	render() return row
end

-- All content regions have one vertical scroll owner. Section configuration
-- expands inside it; dropdowns use a separate modal instead of nested scrolling.
function Library:MakeTab(name)
	local win=resolve(self)
	if name=="Main" or name=="Automation" or name=="Misc" then
		return {Section=function(_,config) return win._pages.Actions:Section(config) end}
	end
	if win._pages[name] then return win._pages[name] end
	assert(name=="Home" or name=="Actions" or name=="Settings","Use sections inside Actions for game content")
	local scroll=create("ScrollingFrame",{Name=name,BackgroundTransparency=1,BorderSizePixel=0,
		Size=UDim2.fromScale(1,1),CanvasSize=UDim2.new(),AutomaticCanvasSize=Enum.AutomaticSize.Y,
		ScrollBarThickness=3,ScrollBarImageColor3=C.Divider,ScrollingDirection=Enum.ScrollingDirection.Y,
		Visible=false,ClipsDescendants=true},win._content)
	pad(scroll,24,24) list(scroll,24)
	local page={Name=name,Frame=scroll,Sections={},Window=win}
	function page:Section(config)
		config=config or {}
		local section=setmetatable({Window=win,Page=self,Title=config.Title or "Controls",Rows={},Actions={},Expanded=false},Section)
		section.Frame=frame(scroll,section.Title) list(section.Frame,8)
		local header=frame(section.Frame,"Section heading") header.LayoutOrder=0 list(header,8)
		label(header,section.Title,18,C.Text,true)
		if config.Content then label(header,config.Content,14,C.Secondary) end
		section.Body=frame(section.Frame,"Actions") section.Body.LayoutOrder=1 list(section.Body,0)
		section.ConfigButton=win:_button(section.Frame,"Show settings",function()
			section.Expanded=not section.Expanded section:_refreshConfig()
		end)
		section.ConfigButton.LayoutOrder=2 section.ConfigButton.Visible=false
		section.Config=frame(section.Frame,"Configuration") section.Config.LayoutOrder=3 section.Config.Visible=false
		pad(section.Config,12,8) list(section.Config,12)
		section.Config.BackgroundColor3=C.Canvas section.Config.BackgroundTransparency=0 round(section.Config,12)
		section.HasConfig=false
		table.insert(self.Sections,section) table.insert(win._sections,section)
		return section
	end
	win._pages[name]=page
	return page
end
function Section:_refreshConfig()
	local standalone=#self.Actions==0
	self.ConfigButton.Visible=self.HasConfig and not standalone
	self.ConfigButton.Text=self.Expanded and "Hide settings" or "Show settings"
	self.Config.Visible=self.HasConfig and (standalone or self.Expanded)
end
function Section:_setting(config)
	self.HasConfig=true self:_refreshConfig()
	local row=frame(self.Config,config.Title or "Setting") list(row,8)
	label(row,config.Title or "Setting",16,C.Text,true)
	if config.Content and config.Content~="" then label(row,config.Content,14,C.Secondary) end
	return row
end
function Section:_action(config,kind)
	local def=table.clone(config)
	def.Id=config.Id or config.Flag or (keyId(self.Title).."/"..keyId(config.Title))
	def.Category=config.Category or self.Title def.Kind=kind def.Section=self
	local action=self.Window:RegisterAction(def)
	table.insert(self.Actions,action)
	local row=self.Window:_actionView(self.Body,action,false)
	table.insert(self.Rows,{Frame=row,Action=action})
	self:_refreshConfig()
	return action
end
function Section:Toggle(config)
	config=config or {}
	if self.Page.Name=="Actions" and not config.Setting then return self:_action(config,"Toggle") end
	local win=self.Window
	local row=self:_setting(config)
	local value=config.Default==true
	if config.Preference then value=win._prefs[config.Preference]==true end
	local button=win:_button(row,value and "Enabled" or "Off")
	if config.Available==false then
		button.Active=false button.Selectable=false button.Text="Unavailable"
		label(row,config.UnavailableReason or "This setting is unavailable.",14,C.Quiet)
	end
	local control={}
	function control:Get() return value end
	function control:Sync(v) value=v==true button.Text=value and "Enabled" or "Off" end
	function control:Set(v)
		if config.Available==false then return false end
		v=v==true
		local ok,result=pcall(config.Callback or function() end,v)
		if ok and result~=false then
			self:Sync(v)
			if config.Preference then win:SetPreference(config.Preference,v) end
		else win:ReportError(config.Title,result) return false end
		return true
	end
	win:_activate(button,function() control:Set(not value) end)
	return control
end
function Section:Button(config)
	config=config or {}
	if self.Page.Name=="Actions" and not config.Setting then return self:_action(config,"Button") end
	local row=self:_setting(config)
	local win=self.Window
	local busy=false
	local button
	button=win:_button(row,config.ButtonText or config.Title or "Run",function()
		if busy then return end busy=true button.Text="Please wait…"
		local ok,err=pcall(config.Callback or function() end)
		busy=false
		if not win._closed then button.Text=config.ButtonText or config.Title or "Run" end
		if not ok then win:ReportError(config.Title,err) end
	end)
	return {Set=function(_,text) button.Text=tostring(text) end}
end
function Section:Paragraph(config)
	config=config or {}
	local row=frame(self.Body,"Paragraph") pad(row,0,8) list(row,5)
	local title=label(row,config.Title or "",16,C.Text,true)
	local content=label(row,config.Content or "",14,C.Secondary)
	return {Set=function(_,nextConfig)
		if nextConfig.Title~=nil then title.Text=tostring(nextConfig.Title) end
		if nextConfig.Content~=nil then content.Text=tostring(nextConfig.Content) end
	end}
end
function Section:Seperator(name)
	local row=frame(self.Body,"Separator") pad(row,0,8) list(row,8)
	local line=create("Frame",{Size=UDim2.new(1,0,0,1),BackgroundColor3=C.Divider,BorderSizePixel=0},row)
	local text=label(row,name or "",14,C.Secondary,true)
	return {Set=function(_,value) text.Text=tostring(value) end,Frame=line}
end
Section.Separator=Section.Seperator
function Section:Slider(config)
	local win=self.Window
	local row=self:_setting(config)
	local min,max=config.Min or 0,config.Max or 100
	assert(max>min,"Slider maximum must exceed minimum")
	local step=math.max(config.Increment or 1,0.001)
	local value=math.clamp(config.Default or min,min,max)
	local values=frame(row,"Slider values") values.Size=UDim2.new(1,0,0,44) values.AutomaticSize=Enum.AutomaticSize.None
	local number=label(values,tostring(value)..(config.Unit and " "..config.Unit or ""),14,C.Accent)
	number.Size=UDim2.new(1,-104,1,0) number.AutomaticSize=Enum.AutomaticSize.None number.TextYAlignment=Enum.TextYAlignment.Center
	local minus=win:_button(values,"−",nil,44) minus.Position=UDim2.new(1,-96,0,0)
	local plus=win:_button(values,"+",nil,44) plus.Position=UDim2.new(1,-44,0,0)
	local hit=win:_button(row,"",nil)
	local track=create("Frame",{Size=UDim2.new(1,-24,0,4),Position=UDim2.new(0,12,0.5,-2),BackgroundColor3=C.Divider,BorderSizePixel=0},hit) round(track,2)
	local fill=create("Frame",{Size=UDim2.new((value-min)/(max-min),0,1,0),BackgroundColor3=C.Accent,BorderSizePixel=0},track) round(fill,2)
	local knob=create("Frame",{Size=UDim2.fromOffset(18,18),AnchorPoint=Vector2.new(0.5,0.5),
		Position=UDim2.new((value-min)/(max-min),0,0.5,0),BackgroundColor3=C.Active,BorderSizePixel=0},track) round(knob,9)
	local control={}
	function control:Get() return value end
	function control:Sync(v)
		value=math.clamp(v,min,max)
		number.Text=tostring(math.floor(value*1000+0.5)/1000)..(config.Unit and " "..config.Unit or "")
		fill.Size=UDim2.new((value-min)/(max-min),0,1,0) knob.Position=UDim2.new((value-min)/(max-min),0,0.5,0)
	end
	function control:Set(v)
		v=math.clamp(min+math.floor((v-min)/step+0.5)*step,min,max)
		local ok,err=pcall(config.Callback or function() end,v)
		if ok then self:Sync(v) else win:ReportError(config.Title,err) end
	end
	win:_activate(minus,function() control:Set(value-step) end)
	win:_activate(plus,function() control:Set(value+step) end)
	local dragging
	local function move(input)
		if track.AbsoluteSize.X<=0 then return end
		control:Set(min+math.clamp((input.Position.X-track.AbsolutePosition.X)/track.AbsoluteSize.X,0,1)*(max-min))
	end
	win:Connect(hit.InputBegan,function(input)
		if isPointer(input) then
			dragging=input
			-- Settings callbacks run outside input signals.
			win:_later(0,function() if dragging==input then move(input) end end)
		end
	end)
	win:Connect(UserInputService.InputChanged,function(input)
		if dragging and (input==dragging or (dragging.UserInputType==Enum.UserInputType.MouseButton1 and input.UserInputType==Enum.UserInputType.MouseMovement)) then
			win:_later(0,function() if dragging then move(input) end end)
		end
	end)
	win:Connect(UserInputService.InputEnded,function(input) if input==dragging then dragging=nil end end)
	return control
end
function Section:TextInput(config)
	local win=self.Window
	local row=self:_setting(config)
	local value=tostring(config.Default or "")
	local box=win:_textBox(row,config.PlaceHolderText or "Enter text",value)
	box.ClearTextOnFocus=config.ClearTextOnFocus==true
	local control={Box=box}
	function control:Get() return value end
	function control:Sync(v) value=tostring(v) box.Text=value end
	function control:Set(v)
		local ok,err=pcall(config.Callback or function() end,tostring(v))
		if ok then self:Sync(v) else win:ReportError(config.Title,err) end
	end
	win:Connect(box.FocusLost,function() win:_later(0,function() control:Set(box.Text) end) end)
	return control
end
function Library:_closeOverlay()
	self._connectionScope=nil
	for _,conn in ipairs(self._overlayConnections) do conn:Disconnect() end
	table.clear(self._overlayConnections)
	if self._overlay then
		for inst,tween in pairs(self._tweens) do
			if inst==self._overlay or inst:IsDescendantOf(self._overlay) then tween:Cancel() self._tweens[inst]=nil end
		end
		self._overlay:Destroy() self._overlay=nil
	end
end
function Library:_openSheet(title)
	self:_closeOverlay()
	self._connectionScope=self._overlayConnections
	local overlay=create("Frame",{Name="SheetOverlay",BackgroundColor3=C.Canvas,BackgroundTransparency=0.08,
		BorderSizePixel=0,Size=UDim2.fromScale(1,1),ZIndex=20,Active=true},self._mainFrame)
	self._overlay=overlay pad(overlay,16) list(overlay,12)
	local close=self:_button(overlay,"Done · "..title,function() self:_closeOverlay() end) close.LayoutOrder=0
	local scroll=create("ScrollingFrame",{Name="SheetContent",Size=UDim2.new(1,0,1,-56),BackgroundTransparency=1,
		BorderSizePixel=0,CanvasSize=UDim2.new(),AutomaticCanvasSize=Enum.AutomaticSize.Y,
		ScrollBarThickness=3,ScrollBarImageColor3=C.Divider,ScrollingDirection=Enum.ScrollingDirection.Y,LayoutOrder=1},overlay)
	list(scroll,8) pad(scroll,4,4)
	return scroll
end
function Section:Dropdown(config)
	local win=self.Window
	local row=self:_setting(config)
	local options=table.clone(config.Options or {})
	local multi=config.Multi==true
	local default=config.Default
	local selected=multi and (type(default)=="table" and table.clone(default) or {})
		or (type(default)=="table" and default[1] or default or options[1])
	local button=win:_button(row,"")
	local control={}
	local function render()
		button.Text=(multi and (#selected>0 and table.concat(selected,", ") or config.PlaceHolderText or "Select options")
			or selected or config.PlaceHolderText or "Select an option").."  ▾"
	end
	function control:Get() return multi and table.clone(selected) or selected end
	function control:Sync(v)
		selected=multi and (type(v)=="table" and table.clone(v) or {v}) or (type(v)=="table" and v[1] or v) render()
	end
	function control:Set(v)
		local nextValue=multi and (type(v)=="table" and table.clone(v) or {v}) or (type(v)=="table" and v[1] or v)
		local ok,err=pcall(config.Callback or function() end,nextValue)
		if ok then self:Sync(nextValue) else win:ReportError(config.Title,err) end
	end
	function control:Add(opt) if not table.find(options,opt) then table.insert(options,opt) end end
	function control:Clear() options={} self:Sync(multi and {} or nil) end
	function control:Refresh(newOptions,newDefault)
		options=table.clone(newOptions or {})
		self:Sync(newDefault or (multi and {} or options[1]))
	end
	win:_activate(button,function()
		local scroll=win:_openSheet(config.Title or "Select")
		if #options==0 then label(scroll,"No options available",14,C.Quiet) end
		for _,opt in ipairs(options) do
			local option
			local function caption()
				local picked=multi and table.find(selected,opt)~=nil or not multi and selected==opt
				return (picked and "✓  " or "    ")..tostring(opt)
			end
			option=win:_button(scroll,caption(),function()
				if multi then
					local nextValue=table.clone(selected) local i=table.find(nextValue,opt)
					if i then table.remove(nextValue,i) else table.insert(nextValue,opt) end
					control:Set(nextValue) option.Text=caption()
				else control:Set(opt) win:_closeOverlay() end
			end)
		end
		win._connectionScope=nil
	end)
	render() return control
end

function Library:_updateActions()
	if not self._enabledLabel then return end
	local count=0
	for _,action in ipairs(self._actionOrder) do if action.Kind=="Toggle" and action.Enabled then count+=1 end end
	self._enabledLabel.Text=tostring(count)..(count==1 and " action enabled" or " actions enabled")
	self._stopBar.Visible=count>0
	local term=(self._search and self._search.Text or ""):lower()
	local total,visible=0,0
	for _,section in ipairs(self._sections) do
		if section.Page.Name=="Actions" then
			local matches=0
			for _,entry in ipairs(section.Rows) do
				local action=entry.Action total+=1
				local text=(action.Title.." "..action.Description.." "..section.Title):lower()
				local show=(term=="" or text:find(term,1,true)~=nil) and (not self._enabledOnly or action.Enabled)
				entry.Frame.Visible=show
				if show then matches+=1 visible+=1 end
			end
			section.Frame.Visible=#section.Actions==0 and not self._enabledOnly and (term=="" or section.Title:lower():find(term,1,true)~=nil)
				or matches>0
		end
	end
	self._filterBar.Visible=total>=8
	self._emptyActions.Visible=visible==0
	self._emptyActions.Text=total==0 and (self._readyText or "Loading available controls…")
		or term~="" and ('No actions match “'..(self._search and self._search.Text or "")..'”.')
		or self._enabledOnly and "No enabled actions." or "No actions available."
	self._clearSearch.Visible=total>0 and visible==0 and (term~="" or self._enabledOnly)
	self:_layout()
end
function Library:FocusSection(section)
	self._search.Text="" self._enabledOnly=false self:_updateActions()
	section.Expanded=true section:_refreshConfig()
	self:ShowTab("Actions")
	self:_later(0,function()
		local scroll=self._pages.Actions.Frame
		local y=section.Frame.AbsolutePosition.Y-scroll.AbsolutePosition.Y+scroll.CanvasPosition.Y
		scroll.CanvasPosition=Vector2.new(0,math.max(0,y-16))
	end)
end
function Library:ShowTab(name)
	local win=resolve(self)
	if name=="Main" or name=="Automation" or name=="Misc" then name="Actions" end
	if not win._pages[name] then return end
	win:_closeOverlay()
	for pageName,page in pairs(win._pages) do
		page.Frame.Visible=pageName==name
		local button=win._navButtons[pageName]
		if button then button.BackgroundColor3=pageName==name and C.Hover or C.Shell button.TextColor3=pageName==name and C.Accent or C.Secondary end
	end
	win._currentPage=name win._prefs.Page=name win:_savePrefs()
end
function Library:_revealInput(box)
	if not box or not box:IsDescendantOf(self._gui) then return end
	local parent=box.Parent
	while parent and not parent:IsA("ScrollingFrame") do parent=parent.Parent end
	if not parent then return end
	local bottom=box.AbsolutePosition.Y+box.AbsoluteSize.Y+12
	local limit=parent.AbsolutePosition.Y+parent.AbsoluteSize.Y
	if bottom>limit then parent.CanvasPosition+=Vector2.new(0,bottom-limit) end
	if box.AbsolutePosition.Y<parent.AbsolutePosition.Y then
		parent.CanvasPosition+=Vector2.new(0,box.AbsolutePosition.Y-parent.AbsolutePosition.Y-12)
	end
end
function Library:_layout()
	if not self._root or self._closed then return end
	local area=self._root.AbsoluteSize
	if area.X<=0 or area.Y<=0 then return end
	local usableH=area.Y
	local ok,keyboardY=pcall(function()
		if UserInputService.OnScreenKeyboardVisible then return UserInputService.OnScreenKeyboardPosition.Y-self._root.AbsolutePosition.Y end
	end)
	if ok and keyboardY and keyboardY>0 then usableH=math.min(usableH,keyboardY) end
	local scale=self._prefs.Scale or 1
	self._scale.Scale=scale
	self._stage.Size=UDim2.fromOffset(area.X/scale,area.Y/scale)
	local availW,availH=math.max(1,area.X/scale),math.max(1,usableH/scale)
	local compact=area.X<640
	local short=usableH<500
	local margin=compact and 8 or short and 12 or 24
	local w=math.min(self._prefs.Width or 920,availW-margin*2)
	local h=math.min(self._prefs.Height or 620,availH-margin*2)
	if compact then w=availW-16 h=availH-16 end
	w=math.max(1,w) h=math.max(1,h)
	self._mainFrame.Size=UDim2.fromOffset(w,h)
	local x=compact and margin or math.clamp(self._prefs.X or (availW-w)/2,margin,math.max(margin,availW-w-margin))
	local y=compact and margin or math.clamp(self._prefs.Y or (availH-h)/2,margin,math.max(margin,availH-h-margin))
	self._mainFrame.Position=UDim2.fromOffset(x,y)
	self._compact,self._short=compact,short
	local head=short and 68 or 88
	self._header.Size=UDim2.new(1,0,0,head)
	self._brand.TextSize=short and 16 or 18
	self._gameLabel.Position=UDim2.fromOffset(16,short and 27 or 33)
	self._readiness.Position=UDim2.fromOffset(16,short and 46 or 56)
	local bottom=compact and not short
	local rail=bottom and 0 or (short and 108 or 132)
	local navHeight=bottom and 60 or 0
	self._nav.Position=bottom and UDim2.new(0,8,1,-60) or UDim2.fromOffset(8,head+8)
	self._nav.Size=bottom and UDim2.new(1,-16,0,52) or UDim2.new(0,rail-16,1,-head-16)
	self._navLayout.FillDirection=bottom and Enum.FillDirection.Horizontal or Enum.FillDirection.Vertical
	for _,button in pairs(self._navButtons) do button.Size=bottom and UDim2.new(1/3,-6,0,48) or UDim2.new(1,0,0,48) end
	local stopHeight=self._stopBar.Visible and 52 or 0
	self._stopBar.Position=UDim2.new(0,rail+12,1,-navHeight-stopHeight)
	self._stopBar.Size=UDim2.new(1,-rail-24,0,44)
	self._content.Position=UDim2.fromOffset(rail,head)
	self._content.Size=UDim2.new(1,-rail,1,-head-navHeight-stopHeight)
	for _,page in pairs(self._pages) do
		local padding=page.Frame:FindFirstChildOfClass("UIPadding")
		local inset=(compact or short) and 16 or 24
		padding.PaddingLeft=UDim.new(0,inset) padding.PaddingRight=UDim.new(0,inset)
		padding.PaddingTop=UDim.new(0,short and 12 or 24)
	end
	local horizontal=w-rail>=700
	self._shortcutLayout.FillDirection=horizontal and Enum.FillDirection.Horizontal or Enum.FillDirection.Vertical
	local count=#self._shortcutRows
	for _,row in ipairs(self._shortcutRows) do row.Size=horizontal and UDim2.new(1/math.max(count,1),-12*(count-1)/math.max(count,1),0,0) or UDim2.new(1,0,0,0) end
	self._mist.Visible=not self._prefs.LowEffects
	self._mist.Size=UDim2.new(1,0,1,0)
	self._resize.Visible=not compact and not short
	self._resize.Position=UDim2.new(0,rail-8,1,-8)
	self._notifications.Size=UDim2.new(0,math.min(330,availW-32),0,0)
	self._notifications.Position=UDim2.new(1,-16,1,-navHeight-stopHeight-16)
	local lx=math.clamp(self._prefs.LauncherX or availW-116,8,math.max(8,availW-116))
	local ly=math.clamp(self._prefs.LauncherY or 16,8,math.max(8,availH-52))
	self._launcher.Position=UDim2.fromOffset(lx,ly)
	local focused=UserInputService:GetFocusedTextBox()
	if focused then self:_later(0,function() self:_revealInput(focused) end) end
end
function Library:_drag(handle,target,launcher,resize)
	local dragging,start,origin,initial
	self:Connect(handle.InputBegan,function(input)
		if not isPointer(input) or (not launcher and (self._compact or self._short)) then return end
		dragging=input start=input.Position origin=target.Position initial=target.Size
		if launcher then self._launcherDragged=false end
	end)
	self:Connect(UserInputService.InputChanged,function(input)
		if not dragging or not (input==dragging or (dragging.UserInputType==Enum.UserInputType.MouseButton1 and input.UserInputType==Enum.UserInputType.MouseMovement)) then return end
		local delta=(input.Position-start)/(self._prefs.Scale or 1)
		if launcher and (math.abs(delta.X)>6 or math.abs(delta.Y)>6) then self._launcherDragged=true end
		if resize then
			self._prefs.Width=math.max(320,initial.X.Offset+delta.X)
			self._prefs.Height=math.max(240,initial.Y.Offset+delta.Y)
		elseif launcher then
			self._prefs.LauncherX=origin.X.Offset+delta.X self._prefs.LauncherY=origin.Y.Offset+delta.Y
		else self._prefs.X=origin.X.Offset+delta.X self._prefs.Y=origin.Y.Offset+delta.Y end
		self:_layout()
	end)
	self:Connect(UserInputService.InputEnded,function(input)
		if input==dragging then
			dragging=nil
			if launcher then self._prefs.LauncherX=target.Position.X.Offset self._prefs.LauncherY=target.Position.Y.Offset
			else
				self._prefs.X=target.Position.X.Offset self._prefs.Y=target.Position.Y.Offset
				if resize then self._prefs.Width=target.Size.X.Offset self._prefs.Height=target.Size.Y.Offset end
			end
			self:_savePrefs()
		end
	end)
end
function Library:ToggleUI()
	local win=resolve(self)
	win._mainFrame.Visible=not win._mainFrame.Visible win._launcher.Visible=not win._mainFrame.Visible
end
function Library:GetToggleKey() return Enum.KeyCode[resolve(self)._prefs.Hotkey] or Enum.KeyCode.RightAlt end
function Library:SetToggleKey(key)
	local win=resolve(self)
	if typeof(key)~="EnumItem" or key.EnumType~=Enum.KeyCode or key==Enum.KeyCode.Unknown then return false end
	win:SetPreference("Hotkey",key.Name) return true
end
function Library:CaptureNextKey(callback)
	local win=resolve(self)
	if win._capturing then return end
	win._capturing=true
	local connection
	local finished=false
	local function finish(key)
		if finished then return end
		finished=true
		win._capturing=false connection:Disconnect() callback(key)
	end
	connection=win:Connect(UserInputService.InputBegan,function(input,processed)
		if not processed and not UserInputService:GetFocusedTextBox() and input.UserInputType==Enum.UserInputType.Keyboard then
			win:_later(0,function() finish(input.KeyCode) end)
		end
	end)
	win:_later(5,function() finish(nil) end)
end
function Library:OnClose(fn) table.insert(resolve(self)._closeHandlers,fn) end
function Library:Unload()
	local win=resolve(self)
	if not win or win._closed or win._closing then return end
	win._closing=true
	win:StopAll()
	for _,action in ipairs(win._actionOrder) do
		if action.Busy and action._requestThread and action._requestThread~=coroutine.running() then
			local ok,err=pcall(task.cancel,action._requestThread)
			if not ok then win:ReportError(action.Id.."/unload",err) end
		end
	end
	for _,fn in ipairs(win._closeHandlers) do
		local ok,err=pcall(fn) if not ok then win:ReportError("Unload",err) end
	end
	win:_savePrefs() win._closed=true
	win:_closeOverlay()
	if win._cameraConnection then win._cameraConnection:Disconnect() end
	for _,connection in ipairs(win._connections) do connection:Disconnect() end
	table.clear(win._connections)
	for inst,tween in pairs(win._tweens) do tween:Cancel() win._tweens[inst]=nil end
	for thread in pairs(win._tasks) do if thread~=coroutine.running() then pcall(task.cancel,thread) end end
	table.clear(win._tasks) table.clear(win._errorWatchers)
	win._gui:Destroy()
	if win._environment and win._environment.ReHub==win._hubState then win._environment.ReHub=nil end
	if activeWindow==win then activeWindow=nil end
end
Library.CloseUI=Library.Unload
function Library:GetThemeNames() return {"Mist"} end
function Library:GetTheme() return table.clone(C) end
function Library:SetTheme(name) return name=="Mist" end
function Library:SetTransparency(value)
	local win=resolve(self)
	-- Stable opaque operating surface; only bounded shell transparency is optional.
	win._mainFrame.BackgroundTransparency=math.clamp((tonumber(value) or 0)/100,0,0.15)
end

function Library:CopyLink(title,url)
	if type(url)~="string" or url=="" then return end
	if type(setclipboard)=="function" then
		local ok,result=pcall(setclipboard,url)
		if ok and result~=false then self:Notify({Title="Re: Hub",Content=title.." copied."}) return end
	end
	local scroll=self:_openSheet("Copy manually")
	label(scroll,"Clipboard unavailable. Select the URL and copy it manually.",14,C.Secondary)
	local box=self:_textBox(scroll,title,url) box.TextEditable=false
	self._connectionScope=nil
end
function Library:SetReady(status)
	self._readyText=status self._readiness.Text=status self._experienceStatus.Text=status self:_updateActions()
end
function Library:Finalize(shortcuts)
	for _,id in ipairs(shortcuts or {}) do
		local action=self._actions[id]
		if action and action.Available then
			table.insert(self._shortcutRows,self:_actionView(self._shortcutContainer,action,true))
		end
		if #self._shortcutRows==3 then break end
	end
	self._shortcutEmpty.Visible=#self._shortcutRows==0
	self._shortcutEmpty.Text="No quick actions are available in this place. See Actions for details."
	for _,section in ipairs(self._sections) do section:_refreshConfig() end
	self:_updateActions()
end
function Library:_buildHome(config)
	local home=self._pages.Home.Frame
	local intro=frame(home,"Introduction") list(intro,8) intro.LayoutOrder=0
	label(intro,"Re: Hub",26,C.Text,true)
	label(intro,"Your controls for supported Roblox experiences.",15,C.Secondary)
	local experience=frame(home,"Experience") list(experience,6) experience.LayoutOrder=1
	label(experience,"Connected experience",12,C.Quiet)
	label(experience,config.ExperienceName or "Experience not configured",22,C.Text,true)
	self._experienceStatus=label(experience,config.Status or "Loading available controls…",14,C.Accent)
	self._enabledLabel=label(experience,"0 actions enabled",12,C.Quiet)
	local quick=frame(home,"Quick actions") list(quick,12) quick.LayoutOrder=2
	label(quick,"Quick actions",18,C.Text,true)
	self._shortcutContainer=frame(quick,"Shortcuts") self._shortcutContainer.LayoutOrder=1
	self._shortcutLayout=list(self._shortcutContainer,12)
	self._shortcutEmpty=label(quick,"Loading available controls…",14,C.Quiet) self._shortcutEmpty.LayoutOrder=2
	if type(config.Featured)=="table" and config.Featured.Title and config.Featured.Content then
		local featured=frame(home,"Featured") list(featured,8) featured.LayoutOrder=3
		label(featured,config.Featured.Title,18,C.Text,true) label(featured,config.Featured.Content,14,C.Secondary)
	end
	local links=frame(home,"Community") list(links,8) links.LayoutOrder=4
	label(links,"Stay connected",18,C.Text,true)
	local any=false
	for _,link in ipairs({{Label="Copy Discord invite",URL=config.Discord},{Label="Copy website link",URL=config.Website}}) do
		if type(link.URL)=="string" and link.URL~="" then
			any=true self:_button(links,link.Label,function() self:CopyLink(link.Label:gsub("^Copy ",""),link.URL) end)
		end
	end
	if not any then label(links,"Community links are not configured.",14,C.Quiet) end
end
function Library:_buildSettings(config)
	local settings=self._pages.Settings
	local preferences=settings:Section({Title="Interface"})
	preferences:Paragraph({Title="Mist",Content="Blue-charcoal surfaces with pale sea-glass accents."})
	for _,pref in ipairs({{Key="ReducedMotion",Title="Reduced motion",Content="Apply control changes without animation."},
		{Key="LowEffects",Title="Low effects",Content="Hide the static mist layer."},
		{Key="Notifications",Title="Notifications",Content="Show meaningful event and error notifications."}}) do
		preferences:Toggle({Title=pref.Title,Content=pref.Content,Preference=pref.Key})
	end
	preferences:Slider({Title="Interface size — percent",Min=85,Max=125,Increment=5,Default=self._prefs.Scale*100,
		Unit="%",Callback=function(value) self:SetPreference("Scale",value/100) end})
	local keyPara=preferences:Paragraph({Title="Show / hide key",Content=self:GetToggleKey().Name})
	preferences:Button({Title="Change show / hide key",Content="Press a key within five seconds.",Callback=function()
		self:CaptureNextKey(function(key)
			if key then self:SetToggleKey(key) keyPara:Set({Content=key.Name})
			else self:Notify({Content="Key capture timed out."}) end
		end)
	end})
	local diagnostics=settings:Section({Title="Diagnostics"})
	diagnostics:Paragraph({Title="Experience and place",Content="GameId "..tostring(game.GameId).." · PlaceId "..tostring(game.PlaceId).."\nLibrary "..Library.Version})
	local fileSupport=type(writefile)=="function" and type(readfile)=="function"
	diagnostics:Paragraph({Title="Available APIs",Content="Clipboard: "..(type(setclipboard)=="function" and "available" or "manual copy")
		.." · Preferences: "..(fileSupport and "file API available" or "session only")})
	local errors=diagnostics:Paragraph({Title="Error feed",Content="No errors recorded."})
	local function renderErrors()
		local lines={}
		for _,entry in ipairs(self._errors) do table.insert(lines,entry.t.." · "..entry.source.." · "..entry.message) end
		errors:Set({Content=#lines>0 and table.concat(lines,"\n\n") or "No errors recorded."})
	end
	self:WatchErrors(renderErrors)
	diagnostics:Button({Title="Copy error log",Callback=function()
		local ok,json=pcall(HttpService.JSONEncode,HttpService,self._errors)
		if ok then self:CopyLink("Error log",json) else self:ReportError("Diagnostics",json) end
	end})
	diagnostics:Button({Title="Clear error log",Callback=function() self:ClearErrors() end})
	local lifecycle=settings:Section({Title="Session"})
	lifecycle:Button({Title="Stop all actions",Content="Requests shutdown through the controls that own the work.",Callback=function() self:StopAll() end})
	self._stopStatus=label(lifecycle.Body,"",14,C.Secondary)
	lifecycle:Button({Title="Minimize",Content="Keep enabled actions and show the movable launcher.",Callback=function() self:ToggleUI() end})
	lifecycle:Button({Title="Unload Re: Hub",Content="Stop registered work and remove the interface.",Callback=function() self:Unload() end})
end
function Library:Start(config)
	config=config or {}
	if activeWindow then activeWindow:Unload() end
	local playerGui=Players.LocalPlayer:WaitForChild("PlayerGui")
	local old=playerGui:FindFirstChild("ReHubGui")
	if old then
		local shutdown=old:FindFirstChild("ReHubUnload")
		if shutdown and shutdown:IsA("BindableFunction") then
			local ok,err=pcall(function() shutdown:Invoke() end)
			if not ok then error("Re: Hub previous unload failed: "..tostring(err)) end
		else error("Legacy hub has no shutdown handle. Unload it before loading Mist.") end
		old:Destroy()
	end
	local win=setmetatable({},Library) activeWindow=win
	win._connections={} win._overlayConnections={} win._tasks={} win._tweens={}
	win._pages={} win._sections={} win._actions={} win._actionOrder={} win._navButtons={} win._shortcutRows={}
	win._closeHandlers={} win._errors={} win._errorTimes={} win._errorWatchers={} win._notices={}
	win._saveFolder=config.SaveFolder win._flags={}
	if win._saveFolder and type(readfile)=="function" then
		local ok,data=pcall(readfile,win._saveFolder..".json")
		if ok and type(data)=="string" then
			local decodedOK,decoded=pcall(HttpService.JSONDecode,HttpService,data)
			if decodedOK and type(decoded)=="table" then win._flags=decoded end
		end
	end
	local saved=type(win._flags.Interface)=="table" and win._flags.Interface or {}
	win._prefs={Scale=math.clamp(tonumber(saved.Scale) or 1,0.85,1.25),Hotkey="RightAlt",Page="Home",
		ReducedMotion=saved.ReducedMotion==true,LowEffects=saved.LowEffects==true,Notifications=saved.Notifications~=false}
	for _,key in ipairs({"Width","Height","X","Y","LauncherX","LauncherY"}) do
		local n=tonumber(saved[key]) if n and n==n and math.abs(n)<10000 then win._prefs[key]=n end
	end
	if win._prefs.Width then win._prefs.Width=math.clamp(win._prefs.Width,320,1600) end
	if win._prefs.Height then win._prefs.Height=math.clamp(win._prefs.Height,240,1000) end
	if type(saved.Hotkey)=="string" then
		local ok,key=pcall(function() return Enum.KeyCode[saved.Hotkey] end)
		if ok and key and key~=Enum.KeyCode.Unknown then win._prefs.Hotkey=key.Name end
	end
	if saved.Page=="Actions" or saved.Page=="Settings" then win._prefs.Page=saved.Page end
	local restorePage=win._prefs.Page
	win._gui=create("ScreenGui",{Name="ReHubGui",ResetOnSpawn=false,DisplayOrder=999,
		ZIndexBehavior=Enum.ZIndexBehavior.Sibling,IgnoreGuiInset=false},playerGui)
	local shutdown=create("BindableFunction",{Name="ReHubUnload"},win._gui)
	shutdown.OnInvoke=function() win:Unload() return true end
	-- CoreUISafeInsets covers device cutouts and Roblox top-bar areas.
	local safeOK,safeErr=pcall(function()
		win._gui.ScreenInsets=Enum.ScreenInsets.CoreUISafeInsets
		win._gui.ClipToDeviceSafeArea=true
	end)
	if not safeOK then warn("Re: Hub safe-area fallback: "..tostring(safeErr)) end
	win._root=create("Frame",{Name="SafeArea",Size=UDim2.fromScale(1,1),BackgroundTransparency=1},win._gui)
	win._stage=create("Frame",{Name="ScaledStage",BackgroundTransparency=1,Size=UDim2.fromScale(1,1)},win._root)
	win._scale=create("UIScale",{Scale=win._prefs.Scale},win._stage)
	win._mainFrame=create("Frame",{Name="MistShell",Size=UDim2.fromOffset(920,620),BackgroundColor3=C.Shell,
		BorderSizePixel=0,ClipsDescendants=true},win._stage) round(win._mainFrame,18)
	create("UIStroke",{Color=C.Divider,Transparency=0.35,Thickness=1},win._mainFrame)
	win._header=create("Frame",{Name="Header",Size=UDim2.new(1,0,0,88),BackgroundColor3=C.Shell,BorderSizePixel=0},win._mainFrame)
	win._mist=create("Frame",{Name="MistEdge",Size=UDim2.new(1,0,0,88),BackgroundColor3=C.Accent,
		BackgroundTransparency=0.94,BorderSizePixel=0,Active=false},win._header)
	create("UIGradient",{Rotation=12,Transparency=NumberSequence.new({NumberSequenceKeypoint.new(0,0.25),NumberSequenceKeypoint.new(0.5,0.8),NumberSequenceKeypoint.new(1,1)})},win._mist)
	local drag=create("Frame",{Name="HeaderDrag",Size=UDim2.new(1,-164,1,0),BackgroundTransparency=1,Active=true},win._header)
	win._brand=label(drag,"Re: Hub",18,C.Text,true) win._brand.Position=UDim2.fromOffset(16,8)
	win._brand.Size=UDim2.new(1,-20,0,22) win._brand.AutomaticSize=Enum.AutomaticSize.None
	win._gameLabel=label(drag,config.ExperienceName or "Experience not configured",14,C.Secondary)
	win._gameLabel.Size=UDim2.new(1,-20,0,18) win._gameLabel.AutomaticSize=Enum.AutomaticSize.None
	win._gameLabel.TextWrapped=false win._gameLabel.TextTruncate=Enum.TextTruncate.AtEnd
	win._readiness=label(drag,config.Status or "Loading…",12,C.Accent)
	win._readiness.Size=UDim2.new(1,-20,0,16) win._readiness.AutomaticSize=Enum.AutomaticSize.None
	win._readiness.TextWrapped=false win._readiness.TextTruncate=Enum.TextTruncate.AtEnd
	local minimize=win:_button(win._header,"Hide",function() win:ToggleUI() end,64) minimize.Position=UDim2.new(1,-148,0,12)
	local unload=win:_button(win._header,"Unload",function() win:Unload() end,64) unload.Position=UDim2.new(1,-76,0,12)
	win._nav=create("Frame",{Name="Navigation",BackgroundTransparency=1},win._mainFrame)
	win._navLayout=list(win._nav,8)
	win._content=create("Frame",{Name="Content",BackgroundTransparency=1,ClipsDescendants=true},win._mainFrame)
	for index,name in ipairs({"Home","Actions","Settings"}) do
		win:MakeTab(name)
		local button=win:_button(win._nav,name,function() win:ShowTab(name) end) button.LayoutOrder=index
		win._navButtons[name]=button
	end
	win._stopBar=create("Frame",{Name="StopBar",BackgroundTransparency=1,Visible=false},win._mainFrame)
	win:_button(win._stopBar,"Stop all enabled actions",function() win:StopAll() end)
	win._launcher=win:_button(win._stage,"Re: Hub",function() if not win._launcherDragged then win:ToggleUI() end end,108)
	win._launcher.Visible=false
	win._resize=win:_button(win._mainFrame,"↘",nil,44)
	win._resize.AnchorPoint=Vector2.new(1,1) win._resize.Position=UDim2.new(1,0,1,0) win._resize.BackgroundTransparency=1
	win._notifications=frame(win._stage,"Notifications") win._notifications.AnchorPoint=Vector2.new(1,1)
	win._notifications.Position=UDim2.new(1,-16,1,-16) win._notifications.ZIndex=30
	list(win._notifications,8).VerticalAlignment=Enum.VerticalAlignment.Bottom
	win:_buildHome(config)
	local actions=win._pages.Actions.Frame
	win._filterBar=frame(actions,"Filters") win._filterBar.LayoutOrder=-3 list(win._filterBar,8)
	win._search=win:_textBox(win._filterBar,"Search actions","")
	local filters=frame(win._filterBar,"Views") filters.Size=UDim2.new(1,0,0,44) filters.AutomaticSize=Enum.AutomaticSize.None list(filters,8,true)
	local all=win:_button(filters,"All",nil,88) local enabled=win:_button(filters,"Enabled",nil,100)
	local function filter(value)
		win._enabledOnly=value all.Text=value and "All" or "✓ All" enabled.Text=value and "✓ Enabled" or "Enabled" win:_updateActions()
	end
	win:_activate(all,function() filter(false) end) win:_activate(enabled,function() filter(true) end)
	win._emptyActions=label(actions,"Loading available controls…",14,C.Secondary) win._emptyActions.LayoutOrder=-2
	win._clearSearch=win:_button(actions,"Clear search / show all",function() win._search.Text="" filter(false) end)
	win._clearSearch.LayoutOrder=-1 win._clearSearch.Visible=false
	win:Connect(win._search:GetPropertyChangedSignal("Text"),function() win:_updateActions() end)
	win:_buildSettings(config)
	win:_drag(drag,win._mainFrame,false,false) win:_drag(win._launcher,win._launcher,true,false) win:_drag(win._resize,win._mainFrame,false,true)
	win:Connect(UserInputService.InputBegan,function(input,processed)
		if not processed and not win._capturing and not UserInputService:GetFocusedTextBox()
			and input.UserInputType==Enum.UserInputType.Keyboard and input.KeyCode==win:GetToggleKey() then win:ToggleUI() end
	end)
	win:Connect(win._root:GetPropertyChangedSignal("AbsoluteSize"),function() win:_layout() end)
	local function watchCamera()
		if win._cameraConnection then win._cameraConnection:Disconnect() end
		local camera=Workspace.CurrentCamera
		if camera then win._cameraConnection=camera:GetPropertyChangedSignal("ViewportSize"):Connect(function() win:_layout() end) end
		win:_layout()
	end
	win:Connect(Workspace:GetPropertyChangedSignal("CurrentCamera"),watchCamera)
	for _,property in ipairs({"OnScreenKeyboardVisible","OnScreenKeyboardPosition","OnScreenKeyboardSize"}) do
		pcall(function() win:Connect(UserInputService:GetPropertyChangedSignal(property),function() win:_layout() end) end)
	end
	if config.CloseCallBack then win:OnClose(config.CloseCallBack) end
	watchCamera() win:ShowTab(restorePage) win:_updateActions()
	return win
end

return Library
