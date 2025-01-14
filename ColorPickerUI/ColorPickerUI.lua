color=''
path=''
config={}
colorPickerActive=''

internal={
    section='',
    option='',
    filePath='',
    actionQueue=''
}

function Initialize()
    path=SELF:GetOption('ScriptFile'):gsub('%.lua$', '.ini')
    if not path:match('^%w%:.*') then
        path=SKIN:MakePathAbsolute(path)
    end
    local file=assert(io.open(path), string.format('File path %s invalid!', path))
    file:close()
    local pathT=ParseFilePath(path)
    local rootPath=ParseFilePath(SKIN:GetVariable('ROOTCONFIGPATH'))
    if pathT.Ext then
        for i=#rootPath, #pathT-1 do
            table.insert(config, pathT[i])
        end
    else
        for i=#rootPath, #pathT do
            table.insert(config, pathT[i])
        end
    end
    config=table.concat(config, '\\')
end

function SetColor(option, section, format, filePath, actionSection)
    local prevColor
    if section:lower()=='variables' then
        prevColor=SKIN:GetVariable(option, '255,255,255')
    else
        local sec=SKIN:GetMeasure(section) or SKIN:GetMeter(section)
        prevColor=sec and sec:GetOption(option, '255,255,255') or '255,255,255'
    end
    local colorFormats={'rgb','rgba', 'hex', 'hexa', 'hsv', 'hsva', 'hsl', 'hsla'}
    if not format then
        format='rgb'
    elseif not TableContains(colorFormats, format) then
        format='rgb'
    end
    internal.section, internal.option=section, option

    filePath=filePath or ''
    if filePath=='' then
        filePath=SKIN:ReplaceVariables('#CURRENTPATH##CURRENTFILE#')
    end
    internal.filePath=filePath

    if actionSection then
        actionSection=SKIN:GetMeter(actionSection) or SKIN:GetMeasure(actionSection)
        internal.actionQueue=actionSection:GetOption('ColorChangeAction', '')
    end

    local t={'[Variables]'}
    table.insert(t, 'FilePath=' .. internal.filePath)
    table.insert(t, 'ConfigName=' .. SKIN:GetVariable('CURRENTCONFIG'))
    table.insert(t, 'SectionName=' .. section)
    table.insert(t, 'OptionName=' .. option)
    table.insert(t, 'Format=' .. format)
    table.insert(t, 'PreviousColor=' .. prevColor)
    table.insert(t, 'ScriptMeasure=' .. SELF:GetName())
    local theme=SELF:GetOption('Theme', 'Dark'):gsub('^%s*$', 'Dark')
    if not FileExist(path:gsub('ColorPickerUI%.ini$', [[Themes\]]..theme..'.inc')) then
        SKIN:Bang('!Log', 'Theme '..theme..' doesn\'t exist, defaulted to Dark!', 'ERROR')
        theme='Dark'
    end
    table.insert(t, 'Theme='..theme)
    local animation=SELF:GetOption('Animations', '1'):gsub('^%s*$', '1')
    animation=animation=='0' and '2' or '1'
    table.insert(t, 'Animations='..animation)
    local file = assert(io.open(path:gsub('ColorPickerUI%.ini$', 'UserData.inc'), 'w'), 'SetColor: Unable to open user data file!')
    file:write(table.concat(t, '\n'))
    file:close()
    print(colorPickerActive)
    SKIN:Bang('!ActivateConfig', config)
end

function FinishAction()
    local actionQ=ParseAction(internal.actionQueue:gsub('%$color%$', color))
    local action=ParseAction(SELF:GetOption('FinishAction', ''):gsub('%$color%$', color))
    if actionQ~='' then SKIN:Bang(actionQ) end
    if action~='' then SKIN:Bang(action) end
end

function DismissAction()
    local action=ParseAction(SELF:GetOption('DismissAction',''))
    if action~='' then SKIN:Bang(action) end
end

function ParseAction(action)
    action=action:gsub('%$section%$', internal.section)
    action=action:gsub('%$option%$', internal.option)
    action=action:gsub('%$filePath%$', internal.filePath)
    return action
end

function GetSubConfig(s) -- Gets the config name from file path
    local pathT=ParseFilePath(s)
    local configT={}
    local rootPath=ParseFilePath(SKIN:GetVariable('ROOTCONFIGPATH'))
    if pathT.Ext then
        for i=#rootPath, #pathT-1 do
            table.insert(configT, pathT[i])
        end
    else
        for i=#rootPath, #pathT do
            table.insert(configT, pathT[i])
        end
    end
    configT=table.concat(configT, '\\')
    return configT
end

function ParseFilePath(s)
	assert(type(s) == 'string', 'ParseFilePath: string expected, got ' .. type(s) .. '.')
	local t = {}
	for Piece in s:gmatch('[^\\]+') do
		table.insert(t, Piece)
	end
	-- VOLUME
	if #t > 0 then
		local UNCprefix = s:match('^(\\\\)') or ''
		t.Vol = UNCprefix .. t[1] .. '\\'
	end
	-- NAME
	if #t > 1 then
		-- DETECT FOLDER OR SEPARATE EXTENSION
		if s:match('\\$') then
			t.Name = t[#t] .. '\\'
		elseif t[#t]:match('.+%..+') then
			t.Name, t.Ext = t[#t]:match('(.-)%.([^%.]-)$')
		else
			t.Name = t[#t]
		end
	end
	-- FOLDER
	if #t > 2 then
		t.Dir = table.concat(t, '\\', 2, #t-1) .. '\\'
	end
	return t
end

function TableContains(table, value)
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


function FileExist(strFileName)
    local fileHandle, strError = io.open(strFileName,"r")
	if fileHandle ~= nil then
		io.close(fileHandle)
		return true
	elseif string.match(strError,"No such file or directory") then
		return false
	end
end