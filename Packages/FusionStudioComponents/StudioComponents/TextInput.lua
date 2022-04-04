-- Roact version by @sircfenner
-- Ported to Fusion by @YasuYoshida

local Plugin = script:FindFirstAncestorWhichIsA("Plugin")
local Fusion = require(Plugin:FindFirstChild("Fusion", true))

local StudioComponents = script.Parent
local StudioComponentsUtil = StudioComponents:FindFirstChild("Util")

local BoxBorder = require(StudioComponents.BoxBorder)

local getState = require(StudioComponentsUtil.getState)
local themeProvider = require(StudioComponentsUtil.themeProvider)
local constants = require(StudioComponentsUtil.constants)
local unwrap = require(StudioComponentsUtil.unwrap)
local types = require(StudioComponentsUtil.types)

local Computed = Fusion.Computed
local OnChange = Fusion.OnChange
local Children = Fusion.Children
local Hydrate = Fusion.Hydrate
local OnEvent = Fusion.OnEvent
local Value = Fusion.Value
local New = Fusion.New

local PLACEHOLDER_TEXT_COLOR = Color3.fromRGB(102, 102, 102)

type state = {[any]: any}
type LabelProperties = {
	Enabled: (boolean | types.StateObject<boolean>)?,
	[any]: any,
}

return function(props: LabelProperties): TextLabel
	local isEnabled = getState(props.Enabled, true)
	local isHovering = Value(false)
	local isFocused = Value(false)
	
	local mainModifier = Computed(function()
		if not unwrap(isEnabled) then
			return Enum.StudioStyleGuideModifier.Disabled
		end
		return Enum.StudioStyleGuideModifier.Default
	end)
	
	local borderModifier = Computed(function()
		local isDisabled = not unwrap(isEnabled)
		local isHovering = unwrap(isHovering)
		local isFocused = unwrap(isFocused)
		if isDisabled then
			return Enum.StudioStyleGuideModifier.Disabled
		elseif isFocused then
			return Enum.StudioStyleGuideModifier.Selected
		elseif isHovering then
			return Enum.StudioStyleGuideModifier.Hover
		end
		return Enum.StudioStyleGuideModifier.Default
	end)
	
	local currentTextBounds = Value(Vector2.new())
	local absoluteTextBoxSize = Value(Vector2.new())
	
	local newTextBox = New "TextBox" {
		Name = "TextInput",
		Size = UDim2.new(1, 0, 0, 25),
		BackgroundColor3 = themeProvider:GetColor(Enum.StudioStyleGuideColor.InputFieldBackground, mainModifier),
		Font = themeProvider:GetFont("Default"),
		Text = "",
		TextSize = constants.TextSize,
		TextColor3 = themeProvider:GetColor(Enum.StudioStyleGuideColor.MainText, mainModifier),
		PlaceholderColor3 = PLACEHOLDER_TEXT_COLOR,
		TextXAlignment = Computed(function()
			local bounds = unwrap(currentTextBounds).X + 5 -- because of padding
			local pixels = unwrap(absoluteTextBoxSize).X
			return if bounds >= pixels then Enum.TextXAlignment.Right else Enum.TextXAlignment.Left
		end),
		TextEditable = isEnabled,
		ClipsDescendants = true,
		ClearTextOnFocus = Computed(function()
			local clearTextOnFocus = (unwrap(props.ClearTextOnFocus) or false)
			local isEnabled = unwrap(isEnabled)
			return clearTextOnFocus and isEnabled
		end),
		
		[OnChange "TextBounds"] = function(newTextBounds)
			currentTextBounds:set(newTextBounds)
		end,
		[OnChange "AbsoluteSize"] = function(newAbsoluteSize)
			absoluteTextBoxSize:set(newAbsoluteSize)
		end,
		[OnEvent "InputBegan"] = function(inputObject)
			if not unwrap(isEnabled) then
				return
			elseif inputObject.UserInputType == Enum.UserInputType.MouseMovement then
				isHovering:set(true)
			end
		end,
		[OnEvent "InputEnded"] = function(inputObject)
			if not unwrap(isEnabled) then
				return
			elseif inputObject.UserInputType == Enum.UserInputType.MouseMovement then
				isHovering:set(false)
			end
		end,
		[OnEvent "Focused"] = function()
			isFocused:set(true)
		end,
		[OnEvent "FocusLost"] = function()
			isFocused:set(false)
		end,
		
		[Children] = New "UIPadding" {
			PaddingLeft = UDim.new(0, 5),
			PaddingRight = UDim.new(0, 5),
		},
	}
	
	BoxBorder(newTextBox, {
		Color = themeProvider:GetColor(Enum.StudioStyleGuideColor.InputFieldBorder, borderModifier)
	})
	
	local hydrateProps = table.clone(props)
	for _,propertyIndex in pairs({"Enabled", "ClearTextOnFocus"}) do
		hydrateProps[propertyIndex] = nil
	end
	
	return Hydrate(newTextBox)(hydrateProps)
end