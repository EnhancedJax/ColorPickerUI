--[[ Functions provided in this file:

Get.
    Variable(name[, defValue]) : Returns a variable as a string, defValue or '' if variable doesn't exist.
    NumberVariable(name[, defValue]) : Returns a variable as a number, defValue or 0 if variable doesn't exist.
    Option(name, option[, defValue]) : Returns an option as string from a section(measure or meter), defValue or ''
    NumberOption(name, option[, defValue]) : Returns an option as number from a section, defValue or 0
    Value(name[, defValue]) : Returns number value of a measure, defValue or 0
    StringValue(name[, defValue]) : Returns string value of a measure, defValue or ''

TableContains.
    Key(table, key) : Returns true if 'table' contains 'key' or false
    Value(table value) : Returns true if 'table' contains 'value' or false

ConvertColor.
    RGB(string[, outputType]) : Converts rgba to outputType or hex | format ('r,g,b,a')
    HSV(string[, outputType]) : Converts hsva to outputType or rgba | format ('h,s,v,a')
    HSL(string[, outputType]) : Converts hsla to outputType or rgba | format ('h,s,l,a')
    HEX(string[, outputType]) : Converts hex to outputType or rgba | format ('xxxxxxxx')
    outputTypes : 'rgb', 'hex', 'hsv', 'hsl'

Log(string[, level])
    level : 1|'Debug', 2|'Notice' (default), 3|'Warning', 4|'Error' || Use number or string

Delim(string[, Separator])
    Separator: Delimiter by which string is to be separated, default is '|'

TruncWhiteSpace(string) : Removes white space from both ends of a string

Multitype(input, types) : Returns true if 'input' is one of the given 'types' | format (variableName, 'datatype1|datatype2|datatype3|...')
    input : any variable
    types : string made up of data types separated by '|'

ReadINI(inputFile) : Returns a table formatted as below ('returnTable' is used to show the outcome, not a way to access the values)
    returnTable['INI'] : This table contains all the sections and their respective keys and values in the format returntable['INI'][section][key]=value
    returnTable['SectionOrder'] : This table indexes the order of sections in the ini file, starting from 1.
            Can be used to iterate through sections in order.
    returnTable['KeyOrder'] : This table indexes the order of keys in each section in the format returnTable['KeyOrder'][section]={indexed keys}
            Can be used to iterate through options of each section.

--]]

Get = {
    Variable=function(name, defValue)
        return SKIN:GetVariable(name) or defValue or ''
    end,

    NumberVariable=function(name, defValue)
        return tonumber(SKIN:GetVariable(name)) or defValue or 0
    end,

    Option=function(name, option, defValue)
        local section=SKIN:GetMeasure(name) or SKIN:GetMeter(name)
        if not section then 
            Log(string.format("Section %s doesn't exist", name), 4)
        end
        return section:GetOption(option) or defValue or ''
    end,

    NumberOption=function(name, option, defValue)
        local section=SKIN:GetMeasure(name) or SKIN:GetMeter(name)
        if not section then 
            Log(string.format("Section %s doesn't exist", name), 4)
        end
        return tonumber(section:GetOption(option)) or defValue or 0
    end,

    Value=function(name, defValue)
        return tonumber(SKIN:GetMeasure(name):GetValue()) or defValue or 0
    end,

    StringValue=function(name, defValue)
        return SKIN:GetMeasure(name):GetStringValue() or defValue or ''
    end
}

TableContains={
    Key=function(table, key)
        if type(table)~='table' then
            Log(string.format('TableContains: Table expected, got %s.', type(table)), 4)
            return false
        end
        if table[key]~=nil then
            return true
        end
        return false
    end,

    Value=function(table, value)
        if type(table)~='table' then
            Log(string.format('TableContains: Table expected, got %s.', type(table)), 4)
            return
        end
        for k,v in pairs(table) do
            if v==value then
                return true
            end
        end
        return false
    end
}

ConvertColor={
    RGB=function(string, outputType)
        local rgb=Delim(string, ',')

        if table.maxn(rgb)==3 then
            table.insert(rgb, 255)
        end

        local t=outputType and outputType:lower() or 'hex'

        if t=='hsv' then
            return table.concat(RGBtoHSV(rgb[1], rgb[2], rgb[3], rgb[4]), ',')
        elseif t=='hsl' then
            return table.concat(RGBtoHSL(rgb[1], rgb[2], rgb[3], rgb[4]), ',')
        else
            return table.concat(RGBtoHEX(rgb[1], rgb[2], rgb[3], rgb[4]))
        end
    end,

    HSV=function(string, outputType)
        local hsv=Delim(string, ',')

        if table.maxn(hsv)==3 then
            table.insert(hsv, 1)
        end
        outpytType=outputType and outputType:lower() or 'rgb'

        local rgb=table.concat(HSVtoRGB(hsv[1], hsv[2], hsv[3], hsv[4]), ',')

        if outputType=='hex' or outputType=='hsl' then
            return ConvertColor.RGB(rgb, outputType)
        else
            return rgb
        end
    end,

    HSL=function(string, outputType)
        local hsl = Delim(string, ',')

        if table.maxn(hsl)==3 then
            table.insert(hsl, 1)
        end
        local t=outputType and outputType:lower() or 'rgb'

        local rgb=table.concat(HSLtoRGB(hsl[1], hsl[2], hsl[3], hsl[4]), ',')
        
        if string.find('hsv|hex', t) then
            return ConvertColor.RGB(rgb, t)
        else
            return rgb
        end
    end,

    HEX=function(string, outputType)
        local t=outputType and outputType:lower() or 'rgb'
        local rgb=table.concat(HEXtoRGB(string), ',')

        if string.find('hsv|hsl', t) then
            return ConvertColor.RGB(rgb, t)
        else
            return rgb
        end
    end
}

function Log(string, level)
    if type(string)~='string' then
        SKIN:Bang('!Log', string.format('function Log(string): String expected, got %s', type(string)), 'Error')
        return
    end
    if type(level)=='number' then
        local t={'debug', 'notice', 'warning', 'error'}
        level=level<=4 and t[level] or 'notice'
    elseif type(level)~='string' then
        level='notice'
    else
        level=level:upper()
    end
    SKIN:Bang('!Log', string, level)
end

-- code from https://github.com/EmmanuelOga/columns/blob/master/utils/color.lua
-- {

function HSVtoRGB(h, s, v, a)
    local r,g,b

    local c=v*s
    local h1=h/60
    local x=c*(1-((h1%2-1)>0 and (h1%2-1) or -(h1%2-1)))

    if 0<=h1 and h1<=1 then
        r,g,b = c,x,0
    elseif 1<h1 and h1<=2 then
        r,g,b = x,c,0
    elseif 2<h1 and h1<=3 then
        r,g,b = 0,c,x
    elseif 3<h1 and h1<=4 then
        r,g,b = 0,x,c
    elseif 4<h1 and h1<=5 then
        r,g,b = x,0,c
    else
        r,g,b = c,0,x
    end

    local m=v-c
    
    local rgb={(r+m)*255, (g+m)*255, (b+m)*255, (a)*255}

    return rgb
end

function RGBtoHSV(r, g, b, a)
    a=a or 255
    r, g, b, a = r / 255, g / 255, b / 255, a / 255
    local max, min = math.max(r, g, b), math.min(r, g, b)
    local h, s, v
    v = max
  
    local d = max - min
    if max == 0 then s = 0 else s = d / max end
  
    if max == min then
      h = 0 -- achromatic
    else
      if max == r then
      h = (g - b) / d
      if g < b then h = h + 6 end
      elseif max == g then h = (b - r) / d + 2
      elseif max == b then h = (r - g) / d + 4
      end
      h = h*60
    end
  
    return {h, s, v, a}
end
function HSLtoRGB(h, s, l, a)
    local r, g, b
  
    if s == 0 then
      r, g, b = l, l, l -- achromatic
    else
      function hue2rgb(p, q, t)
        if t < 0   then t = t + 1 end
        if t > 1   then t = t - 1 end
        if t < 1/6 then return p + (q - p) * 6 * t end
        if t < 1/2 then return q end
        if t < 2/3 then return p + (q - p) * (2/3 - t) * 6 end
        return p
      end
  
      local q
      if l < 0.5 then q = l * (1 + s) else q = l + s - l * s end
      local p = 2 * l - q
  
      r = hue2rgb(p, q, h + 1/3)
      g = hue2rgb(p, q, h)
      b = hue2rgb(p, q, h - 1/3)
    end
    a=a or 1
    return {r * 255, g * 255, b * 255, a * 255}
end
function RGBtoHSL(r, g, b, a)
    r, g, b = r / 255, g / 255, b / 255
  
    local max, min = math.max(r, g, b), math.min(r, g, b)
    local h, s, l
  
    l = (max + min) / 2
  
    if max == min then
      h, s = 0, 0 -- achromatic
    else
      local d = max - min
      if l > 0.5 then s = d / (2 - max - min) else s = d / (max + min) end
      if max == r then
        h = (g - b) / d
        if g < b then h = h + 6 end
      elseif max == g then h = (b - r) / d + 2
      elseif max == b then h = (r - g) / d + 4
      end
      h = h / 6
    end
    return {h, s, l, a or 255}
end
-- }

-- From https://docs.rainmeter.net/snippets/colors/
-- {
function RGBtoHEX(r,g,b,a)
	local hex = {}
    local color={r,g,b,a}
	for _, v in pairs(color)  do
		table.insert(hex, ('%02X'):format(tonumber(v)))
	end
	return hex
end

function HEXtoRGB(color)
    local rgb = {}
	for hex in color:gmatch('..') do
		table.insert(rgb, tonumber(hex, 16))
	end
	return rgb
end
-- }

-- By smurfier, for Lua Calendar
-- {
function Delim(input, Separator) -- Separates an input string by a delimiter | table
	
	local tbl = {}
	if type(input) == 'string' then
		if not MultiType(Separator, 'nil|string') then
			Log(string.format('Input #2 must be a string. Received %s instead. Using default value.', type(Separator)), 3)
			Separator = '|'
		end
		
		local MatchPattern = string.format('[^%s]+', Separator or '|')
		
		for word in string.gmatch(input, MatchPattern) do
			table.insert(tbl, word:match('^%s*(.-)%s*$'))
		end
	else
		Log(string.format('Input must be a string. Received %s instead', type(input)), 4)
	end

	return tbl
end -- Delim

function MultiType(input, types) -- Test an input against multiple types
	return not not types:find(type(input))
end -- MultiType
-- }

function TruncWhiteSpace(string)
    return string:gsub('^%s*(.-)%s*$', '%1')
end

function ReadIni(inputfile)
	local file = assert(io.open(inputfile, 'r'), 'Unable to open ' .. inputfile)
	local tbl, section = {}
    local sectionReadOrder, keyReadOrder = {}, {}
	local num = 0
	for line in file:lines() do
        --print(line)
		num = num + 1
		if not line:match('^%s-;') then
			local key, command = line:match('^([^=]+)=(.+)')
			if line:match('^%s-%[.+') then
				section = line:match('^%s-%[([^%]]+)')
				if not tbl[section] then
                    tbl[section]={}
                    table.insert(sectionReadOrder, section)
                    if not keyReadOrder[section] then keyReadOrder[section]={} end
                end
			elseif key and command and section then
				tbl[section][key:match('^%s*(%S*)%s*$')] = command:match('^%s*(.-)%s*$')
                table.insert(keyReadOrder[section], key)
                --print(keyReadOrder[section][table.maxn(keyReadOrder[section])])
			elseif #line > 0 and section and not key or command then
				print(num .. ': Invalid property or value.')
			end
		end
	end
    file:close()

    if not section then print('No sections found in ' .. inputfile) return end

    local finalTable={}
    finalTable['INI']=tbl
    finalTable['SectionOrder']=sectionReadOrder
    finalTable['KeyOrder']=keyReadOrder
    return finalTable
end


function Round(num, idp)
	assert(tonumber(num), 'Round expects a number.')
	local mult = 10 ^ (idp or 0)
    local n
	if num >= 0 then
		n=math.floor(num * mult + 0.5) / mult
	else
		n=math.ceil(num * mult - 0.5) / mult
	end
    n=tostring(n)
    local m
    if n:find('%.') then
        m=n:gsub('^%d+%.(%d+)$', '%1')
    end

    m=m and #m or 0
    idp=idp or 0

    if idp > 0 and m < idp then
        if m==0 then 
            n=n..'.0'
            for i=2,idp-m do n=n..0 end
        else
            for i=1,idp-m do n=n..0 end
        end
    end
    return n
end