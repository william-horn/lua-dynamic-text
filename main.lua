--[[
	? @document-start
	================
	| DYNAMIC TEXT |
	==================================================================================================================================

	? @author:                 William J. Horn
	? @document-name:          main.lua
	? @document-created:       09/12/2021
	? @document-modified:      02/22/2022
	? @document-version:       v2.76.14.25

	----------------------------------------------------------------------------------------------------------------------------------

	? @document-about
	==================
	| ABOUT DOCUMENT |
	==================================================================================================================================

	Fastest version so far.

	----------------------------------------------------------------------------------------------------------------------------------

	? @document-api
	================
	| DOCUMENT API |
	==================================================================================================================================

	[coming soon]

	----------------------------------------------------------------------------------------------------------------------------------

	? @document-changelog
	======================
	| DOCUMENT CHANGELOG |
	==================================================================================================================================

	[Version v2.76.14.25]

		-   changes made

	* If this program supports changelog records then there should be a 'changelog' folder within the same directory as this program
	file. Learn more about the changelog system here: 
	https://github.com/william-horn/my-coding-conventions/blob/main/document-conventions/about-changelog.txt

	----------------------------------------------------------------------------------------------------------------------------------

	? @document-todo
	=================
	| DOCUMENT TODO |
	==================================================================================================================================

	*	- add support for single tags, i.e <img src="">
	*	- add class property w/ inheritance, i.e: <label class=c1.c2.c3>...</label>
	*	- add animation tag support
	*	- finish implementing property decoder
	*	- look into alternative for nested loops when doing comparisons of 2 tables

	----------------------------------------------------------------------------------------------------------------------------------
]]

-- ROBLOX game services
local RunService = game:GetService("RunService")
local TextService = game:GetService("TextService")

-- quick refs
local tonum = tonumber
local print = print
local typeof = typeof
local unpack = unpack
local next = next
local fromRGB = Color3.fromRGB
local newColor3 = Color3.new
local newUDim2 = UDim2.new
local newInstance = Instance.new

-- quick objects
local inf2d = Vector2.new(-1, -1)

-- module
local DynamicText = {}
do local globalFunctions = {}
	globalFunctions.__index = globalFunctions
	DynamicText.globalFunctions = globalFunctions
end
do local globalVariables = {}
	globalVariables.__index = globalVariables
	DynamicText.globalVariables = globalVariables
end

local tagTypeAliases = require(script.tag_type_aliases)

local parseRules = {
	openOrClose = "()<(/?)([%a%d%-]+)(.-)>()",
	tagProperties = "([%a%-%d]+)%s*=%s*(.-);"
}


local function escapeChars(str, chars)
	return str:gsub("/([/"..chars:gsub(".", "%%%0").."])", function(n) return "\1"..string.byte(n).."\1" end)
end

local function unescapeChars(str, chars)
	return str:gsub("\1(%d+)\1", chars or function(n) return string.char(n) end)
end

-- used for parsing function arguments (a, b, ...)
local function splitWithIgnoreDelimSpace(str, delim, unescape)
	local t = {}
	for element in str:gmatch("[^"..delim.."]+") do
		element = unescape and unescapeChars(element) or element
		t[#t + 1] = element:match("%S+.-$") -- "%S+.-$": remove spaces after the delimeter (",  hello" becomes just "hello")
	end
	return t
end




local function subVariables(str, localVariables)
	return str:gsub("%$([%w_]+)", localVariables)
end

local subFunctionResults do
	local depth = 0
	function subFunctionResults(str, localFunctions)
		return str:gsub("%$([%w_]+)(%b())", function(name, args)
			local func = localFunctions[name]
			if func then
				args = escapeChars(args:sub(2, -2), ",")
				depth = depth + 1 -- find a better way to handle unescaping trying at final depth?
				local args = subFunctionResults(args, localFunctions)
				depth = depth - 1
				return func(unpack(splitWithIgnoreDelimSpace(args, ",", depth == 0)))
			else
				return "$"..name..args
			end
		end)
	end
end

-- @bug:start:"currently this does not support 'settings.defaultSettings' when it comes to non-string properties because they will not get sorted"
-- fix this, WILL! YOU IDIOT!
local function decodeAndSortProperty(tagData, key, value)
	local tagInfo = tagData.info

	local customProperty = tagInfo.customPropertiesRef[key]
	local rbxProperty = tagInfo.rbxProperties and tagInfo.rbxProperties[key]

	if typeof(value) == "string" then
		value = unescapeChars(value)

		if tagInfo.customPropertiesRef[key] then
			value = tagInfo.customPropertiesRef[key][value]
			tagData.customProperties[key] = value
		elseif tagInfo.rbxPropertiesRef and tagInfo.rbxPropertiesRef[key] then
			value = tagInfo.rbxPropertiesRef[key][2][value]
			tagData.rbxProperties[key] = value
		else
			error(key.." is not a valid property of "..tagData.name)
		end
	end

	tagData.propertiesRef[key] = value
end

local function parsePropertyString(str, tagData)
	--str = table.concat({str, ">"})
	str = subFunctionResults(subVariables(str, tagData.settings.localVariables), tagData.settings.localFunctions)..";"
	local tagInfo = tagData.info

	for key, value in str:gmatch(parseRules.tagProperties) do
		decodeAndSortProperty(tagData, key, value)
	end

end

-- rethink how action tags are going to be handled. they will only have argument data in their tag, no property data
local function inheritAnscestorTagProperties(anscestorTag, ancestorTagChildren, lastPhysicalTag)
	lastPhysicalTag = not anscestorTag.info.action and anscestorTag or lastPhysicalTag

	for _, childTag in next, ancestorTagChildren do
		childTag.parent = anscestorTag
		childTag.lastPhysicalTag = lastPhysicalTag

		if lastPhysicalTag and (not childTag.info.action) then
			for field, value in next, lastPhysicalTag.propertiesRef do
				if childTag.propertiesRef[field] == nil then
					if childTag.info.customPropertiesRef[field] then
						childTag.customProperties[field] = value
					elseif childTag.info.rbxPropertiesRef[field] then
						childTag.rbxProperties[field] = value
					end
					childTag.propertiesRef[field] = value
				end
			end
		end

		if childTag.info.requiresClose and #childTag.children > 0 then
			inheritAnscestorTagProperties(childTag, childTag.children, lastPhysicalTag)
		end
	end
end


local function createTextBodyElement(tagData, tagContent)
	if tagData.info.requiresClose then
		if not tagData.filterType.all then
			if not tagData.filterType.variables then
				tagContent = subVariables(tagContent, tagData.settings.localVariables)
			end
			if not tagData.filterType.functions then
				tagContent = subFunctionResults(tagContent, tagData.settings.localFunctions)
			end
		end
		tagContent = unescapeChars(tagContent)
	else
		tagContent = "Not Available"
	end

	return {
		content = tagContent,
		tagData = tagData,
	}
end


local function compileTagData(source, settings)

	local openTagQueue = {}
	local tagHierarchy = {}

	-- begin hierarchy sorting
	for tagStartPos, closeTagIndicator, tagName, tagProperties, tagEndPos in source:gmatch(parseRules.openOrClose) do
		local tagInfo = tagTypeAliases[tagName]

		-- check for valid tag name
		if tagInfo then

			-- check if tag is a closing tag i.e, </tagName>
			if #closeTagIndicator > 0 then
				local openTag = openTagQueue[#openTagQueue]

				-- check if closure tag is valid (matches with most recent open tag)
				if openTag and openTag.name == tagName then
					openTagQueue[#openTagQueue] = nil

					local anscestorTag = openTag
					local ancestorTagChildren = {}

					if not tagInfo.action then
						anscestorTag.rbxProperties = {}
					end

					anscestorTag.customProperties = {}
					anscestorTag.propertiesRef = {}
					anscestorTag.info = tagInfo

					if #anscestorTag.encodedProperties > 0 then
						-- encodedProperties already escaped: $<>();,
						parsePropertyString(anscestorTag.encodedProperties, anscestorTag)
					end

					anscestorTag.closeTagStartPos = tagStartPos - 1
					anscestorTag.closeTagEndPos = tagEndPos
					anscestorTag.children = ancestorTagChildren

					if tagInfo.action then
						tagInfo.action(anscestorTag)
					end

					anscestorTag.filterType = anscestorTag.filterType or {}

					-- set child tags to anscestor tag if necessary
					local insertIndex
					for index = 1, #tagHierarchy do
						local descendantTag = tagHierarchy[index]
						if anscestorTag.openTagStartPos < descendantTag.openTagStartPos and anscestorTag.closeTagEndPos > descendantTag.closeTagEndPos then

							-- if tag is a filter and filter type disables markup, give the filter tag no children
							if not (anscestorTag.filterType.all or anscestorTag.filterType.markup) then
								ancestorTagChildren[#ancestorTagChildren + 1] = descendantTag
							end

							tagHierarchy[index] = nil
							if not insertIndex then
								insertIndex = index
							end
						end
					end

					-- update tag hierarchy table
					inheritAnscestorTagProperties(anscestorTag, ancestorTagChildren)
					tagHierarchy[insertIndex or #tagHierarchy + 1] = anscestorTag

				end

			else
				-- if tag is opening tag then partially construct tagObject
				local openTag = {
					name = tagName,
					openTagStartPos = tagStartPos - 1,
					openTagEndPos = tagEndPos,
					settings = settings
				}

				if not tagInfo.requiresClose then
					openTag.info = tagInfo

					if #tagProperties > 0 then
						-- encodedProperties already escaped: $<>();,
						parsePropertyString(tagProperties, openTag)
					end

					openTag.closeTagStartPos = openTag.openTagStartPos
					openTag.closeTagEndPos = openTag.openTagEndPos

					tagHierarchy[#tagHierarchy + 1] = openTag
				else
					openTag.encodedProperties = tagProperties
					openTagQueue[#openTagQueue + 1] = openTag
				end
			end
		end

	end

	-- clear any unclosed open tags from the queue
	for i = 1, #openTagQueue do
		openTagQueue[i] = nil
	end
	openTagQueue = nil

	-- return sorted tag hierarchy table
	return tagHierarchy

end

function DynamicText:compileText(sourceText, settings)
	settings = settings or {}
	settings.__index = settings

	settings.defaultProperties = settings.defaultProperties or {}
	settings.defaultTag = settings.defaultTag or "label"
	settings.localVariables = setmetatable(settings.localVariables or {}, self.globalVariables)
	settings.localFunctions = setmetatable(settings.localFunctions or {}, self.globalFunctions)

	local defaultTagData = {
		settings = settings,
		name = settings.defaultTag,
		info = tagTypeAliases[settings.defaultTag],
		propertiesRef = settings.defaultProperties,
		rbxProperties = {},
		children = {},
		filterType = {},
	}
	defaultTagData.parent = defaultTagData

	if not (defaultTagData.info.contentType == "Text") then
		error("defaultTag must be a ROBLOX text object")
	end

	-- decode and sort default tag data properties
	for key, value in next, defaultTagData.propertiesRef do
		decodeAndSortProperty(defaultTagData, key, value)
	end

	--[[
	globally escape chars: $<>();,
	]]
	sourceText = escapeChars(sourceText, "$<>();,")

	local compiledTagData = compileTagData(sourceText, settings)
	inheritAnscestorTagProperties(defaultTagData, compiledTagData)

	local textBody = {}

	if #compiledTagData > 0 then
		local startIndex = 1

		local function deepSearchTagHierarchy(tagChildren)
			for _, tagData in next, tagChildren do

				local textBeforeOpen = sourceText:sub(startIndex, tagData.openTagStartPos)
				if #textBeforeOpen > 0 then
					textBody[#textBody + 1] = createTextBodyElement(tagData.parent, textBeforeOpen)
				end
				startIndex = tagData.openTagEndPos

				-- if tag requires a close and has children, recursively search the children
				-- maybe do something with tagData.action here?
				if tagData.info.requiresClose then
					if #tagData.children > 0 then
						deepSearchTagHierarchy(tagData.children)
					end
				else
					textBody[#textBody + 1] = createTextBodyElement(tagData)
				end

				local textAfterOpen = sourceText:sub(startIndex, tagData.closeTagStartPos)
				if #textAfterOpen > 0 then
					textBody[#textBody + 1] = createTextBodyElement(tagData, textAfterOpen)
				end
				startIndex = tagData.closeTagEndPos
			end
		end

		deepSearchTagHierarchy(compiledTagData)

		local textAfterLastClose = sourceText:sub(startIndex, -1)
		if #textAfterLastClose > 0 then
			textBody[#textBody + 1] = createTextBodyElement(defaultTagData, textAfterLastClose)
		end
	else
		textBody[#textBody + 1] = createTextBodyElement(defaultTagData, sourceText)
	end

	return setmetatable(textBody, {__index = {settings = settings}})

end

function DynamicText:renderText(compiledText, frame)
	local settings = compiledText.settings
end

-- @debug-off:start:"generate long string"
--local teststring = "before <label font=arial; textColor=red>"..string.rep("<button>b", 100).."between"..string.rep("</button>", 100).."$doButton(haha)</label> after"
-- @debug-off:end

-- @bug:start:"some tag properties not registering, probably an issue with the decoder & sorting properties function"
local textBody = DynamicText:compileText("/$playerName $add(1, $add(1, 0)) <label textSize=999>hello <animate> <button $preset1>world</button></animate></label>kk", {
	defaultProperties = {
		textColor = "red",
		font = Enum.Font.ArialBold,
	},
	localVariables = {
		playerName = "Will",
		preset1 = "font=code; bgColor=purple; bgTransparency=0",
		pi = math.pi,
	},
	localFunctions = {
		newButton = function(content)
			return "<button font=gara>"..content.."</button>"
		end,
		add = function(a, b)
			return tostring(a + b)
		end,
		concat = function(a, b)
			if b then
				return a.."<-->"..b
			else
				return a
			end
		end
	}
})


print(textBody)



-- ? @document-end