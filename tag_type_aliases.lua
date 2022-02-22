--[[
	? @document-start
	====================
	| TAG TYPE ALIASES |
	==================================================================================================================================

	? @author:                 William J. Horn
	? @document-name:          tag_type_aliases.lua
	? @document-created:       09/15/2021
	? @document-modified:      02/22/2022
	? @document-version:       v0.1.0.0

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

	[not available]

	----------------------------------------------------------------------------------------------------------------------------------

	? @document-changelog
	======================
	| DOCUMENT CHANGELOG |
	==================================================================================================================================

	* If this program supports changelog records then there should be a 'changelog' folder within the same directory as this program
	file. Learn more about the changelog system here: 
	https://github.com/william-horn/my-coding-conventions/blob/main/document-conventions/about-changelog.txt

	----------------------------------------------------------------------------------------------------------------------------------

	? @document-todo
	=================
	| DOCUMENT TODO |
	==================================================================================================================================

	- 

	----------------------------------------------------------------------------------------------------------------------------------
]]

local valueRefs = {}

local function getArgsFromString(str)
	return unpack(str:split(","))
end

local function getNumberFromIndex(self, value)
	return tonumber(value)
end

local function getColor3FromIndex(self, value)
	return Color3.fromRGB(getArgsFromString(value))
end

local function getEnumFromString(self, value)
	local path = value:split(".")
	local enum = getfenv()[path[1]]

	for i = 2, #path do
		enum = enum[path[i]]
	end

	return enum
end

local function getChoicesFromList(self, value)
	local list = {}
	for k, v in next, value:split(",") do
		if rawget(self, v) then
			list[v] = true
		end
	end
	return list
end

local function returnString(self, k)
	return k
end

valueRefs.returnNumber = setmetatable({}, {
	__index = getNumberFromIndex
})

valueRefs.returnString = setmetatable({}, {
	__index = returnString,
})

valueRefs.numberShorts = setmetatable({
	["inf"] = math.huge,
	["pi"] = math.pi,
}, {
	__index = getNumberFromIndex
})

valueRefs.imageShorts = setmetatable({
	["happy"] = "rbxassetid://0"
}, {
	__index = returnString
})

valueRefs.color3Shorts = setmetatable({
	["blue"] = Color3.fromRGB(0, 0, 255),
	["red"] = Color3.fromRGB(255, 0, 0),
	["green"] = Color3.fromRGB(0, 255, 0),
	["white"] = Color3.fromRGB(255, 255, 255),
	["black"] = Color3.fromRGB(0, 0, 0),
	["yellow"] = Color3.fromRGB(255, 255, 0),
	["orange"] = Color3.fromRGB(255, 85, 0),
	["pink"] = Color3.fromRGB(255, 85, 255),
	["teal"] = Color3.fromRGB(85, 255, 255),
	["purple"] = Color3.fromRGB(85, 0, 255),
	["sea green"] = Color3.fromRGB(85, 170, 127),
	["sky blue"] = Color3.fromRGB(0, 170, 255),
	["light pink"] = Color3.fromRGB(255, 170, 255),
	["dark green"] = Color3.fromRGB(0, 85, 0),
	["dark blue"] = Color3.fromRGB(0, 0, 127),
	["dark red"] = Color3.fromRGB(85, 0, 0)
}, {
	__index = getColor3FromIndex
})

valueRefs.fontShorts = setmetatable({
	["amatic"] = Enum.Font.AmaticSC,
	["arial bold"] = Enum.Font.ArialBold,
	["arialbold"] = Enum.Font.ArialBold,
	["antique"] = Enum.Font.Antique,
	["arcade"] = Enum.Font.Arcade,
	["arial"] = Enum.Font.Arial,
	["bangers"] = Enum.Font.Bangers,
	["bodoni"] = Enum.Font.Bodoni,
	["cartoon"] = Enum.Font.Cartoon,
	["code"] = Enum.Font.Code,
	["creep"] = Enum.Font.Creepster,
	["creepster"] = Enum.Font.Creepster,
	["denkone"] = Enum.Font.DenkOne,
	["denk"] = Enum.Font.DenkOne,
	["fondamento"] = Enum.Font.Fondamento,
	["fond"] = Enum.Font.Fondamento,
	["fredokaone"] = Enum.Font.FredokaOne,
	["fred"] = Enum.Font.FredokaOne,
	["garamond"] = Enum.Font.Garamond,
	["gara"] = Enum.Font.Garamond,
	["gotham"] = Enum.Font.Gotham,
	["gothamblack"] = Enum.Font.GothamBlack,
	["gothambold"] = Enum.Font.GothamBold,
}, {
	__index = getEnumFromString
})

valueRefs.booleans = {
	["true"] = true,
	["false"] = false,
}

-- <filter type=variables,functions> </filter>

valueRefs.filterTypes = setmetatable({
	["all"] = {all = true},
	["variables"] = {variables = true},
	["functions"] = {functions = true},
	["markup"] = {markup = true},
}, {
	__index = getChoicesFromList,
})

valueRefs.animateStyleTypes = {
	["sine"] = {sine = true},
	["linear"] = {linear = true},
}

--"<filter exclude=variables,markup>asd</filter>"
-- tagData.customProperties.exclude.markup


local baseRbxProperties = {
	["visible"] = {"Visible", valueRefs.booleans},
}
baseRbxProperties.__index = baseRbxProperties




local baseCustomProperties = {
	["id"] = valueRefs.numberShorts,
}
baseCustomProperties.__index = baseCustomProperties


local customAnimateProperties = {
	["repeat"] = valueRefs.returnNumber,
	["style"] = valueRefs.animateStyleTypes,
}
setmetatable(customAnimateProperties, baseCustomProperties)

local customFilterProperties = {
	["filterType"] = valueRefs.filterTypes
}
setmetatable(customFilterProperties, baseCustomProperties)



local baseImageProperties = {
	["src"] = {"Image", valueRefs.imageShorts},
	["imgColor"] = {"ImageColor3", valueRefs.color3Shorts},
	["bgColor"] = {"BackgroundColor3", valueRefs.color3Shorts}
}
setmetatable(baseImageProperties, baseRbxProperties)




local baseTextProperties = {
	["textColor"] = {"TextColor3", valueRefs.color3Shorts},
	["font"] = {"Font", valueRefs.fontShorts},
	["bgColor"] = {"BackgroundColor3", valueRefs.color3Shorts},
	["textTransparency"] = {"TextTransparency", valueRefs.numberShorts},
	["bgTransparency"] = {"BackgroundTransparency", valueRefs.numberShorts},
	["textOutlineColor"] = {"TextStrokeColor3", valueRefs.color3Shorts},
	["textOutlineTransparency"] = {"TextStrokeTransparency", valueRefs.numberShorts},
	["textSize"] = {"TextSize", valueRefs.numberShorts},
	["text"] = {"Text", valueRefs.returnString},
}
setmetatable(baseTextProperties, baseRbxProperties)


local customTextLabelProperties = {
	["poop"] = "yes"
}
setmetatable(customTextLabelProperties, baseCustomProperties)


local tagTypeAliases = {
	["label"] = {
		--action = function
		aliasName = "TextLabel",
		requiresClose = true,
		contentType = "Text",
		objBaseRef = Instance.new("TextLabel"),
		rbxPropertiesRef = baseTextProperties,
		customPropertiesRef = customTextLabelProperties,
		defaultAppearance = {
			TextColor3 = Color3.new(1, 1, 1),
			TextSize = 18,
			Font = Enum.Font.Arial,
			BackgroundTransparency = 1,
		},
	},
	["button"] = {
		aliasName = "TextButton",
		requiresClose = true,
		contentType = "Text",
		objBaseRef = Instance.new("TextButton"),
		rbxPropertiesRef = baseTextProperties,
		customPropertiesRef = baseCustomProperties,
		customEventsRef = {},
		rbxEventsRef = {},
		defaultAppearance = {
			TextColor3 = Color3.new(1, 1, 1),
			TextSize = 18,
			Font = Enum.Font.ArialBold,
			BackgroundTransparency = 1,
		},
	},
	["animate"] = {
		action = function() end,
		requiresClose = true,
		--rbxPropertiesRef = {},
		customPropertiesRef = customAnimateProperties,
	},
	["group"] = {
		action = function() end,
		requiresClose = true,
		--rbxPropertiesRef = {},
		customPropertiesRef = {},
	},
	["input"] = {
		aliasName = "TextBox",
		requiresClose = true,
		contentType = "Text",
		objBaseRef = Instance.new("TextBox"),
		rbxPropertiesRef = baseTextProperties,
		customPropertiesRef = baseCustomProperties,
		defaultAppearance = {
			TextColor3 = Color3.new(1, 1, 1),
			TextSize = 18,
			Font = Enum.Font.ArialBold,
			BackgroundTransparency = 1,
		},
	},
	["img"] = {
		aliasName = "ImageLabel",
		requiresClose = false,
		contentType = "Image",
		objBaseRef = Instance.new("ImageLabel"),
		customPropertiesRef = baseCustomProperties,
		rbxPropertiesRef = baseImageProperties,
		defaultAppearance = {
		},
	},
	["imgButton"] = {
		aliasName = "ImageButton",
		requiresClose = false,
		contentType = "Image",
		objBaseRef = Instance.new("ImageButton"),
		customPropertiesRef = baseCustomProperties,
		rbxPropertiesRef = baseImageProperties,
		defaultAppearance = {
		},
	},
	["filter"] = {
		action = function(tagData)
			tagData.filterType = tagData.customProperties.filterType or valueRefs.filterTypes.all
		end,
		requiresClose = true,
		customPropertiesRef = customFilterProperties,
	}
}

for tag, tagInfo in next, tagTypeAliases do
	if not tagInfo.action then
		for key, value in next, tagInfo.defaultAppearance do
			tagInfo.objBaseRef[key] = value
		end
	end
end

setmetatable(tagTypeAliases, {__index = {valueRefs = valueRefs}})
return tagTypeAliases

-- ? @document-end