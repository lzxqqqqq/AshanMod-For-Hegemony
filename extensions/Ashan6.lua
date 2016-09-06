--[[*************************************************
    这是 忧郁の月兔 制作的【英雄无敌Ⅵ-亚山之殇-资料片】
]]--*************************************************

--[[
    创建拓展包“亚山之殇-拓展功能”
]]--
Ashan6 = sgs.Package("Ashan6", sgs.Package_GeneralPack)

sgs.LoadTranslationTable{
    ["Ashan6"] = "拓展功能",
}

--[[************
    拓展简述
]]--************
--[[
	1.开启随机BGM模式（该功能移植自饺神的“高达杀”，感谢饺神，吃掉饺神！）
]]--

	
--[[*******************************
    功能开关（true为开，false为关）
]]--*******************************
auto_bgm = true --切换BGM


--建立切换BGM效果
Mchangebgm_mode = sgs.General(Ashan6, "Mchangebgm_mode", "god", 0, true, true)

function file_exists(name)
	local f = io.open(name, "r")
	if f ~= nil then io.close(f) return true else return false end
end

changeBGM = function(name)
	sgs.SetConfig("BackgroundMusic", "audio/system/"..name..".ogg")
end

decideBGM = function()
	math.random()
	local n = -1
	for i = 1, 99, 1 do
		if file_exists("audio/system/BGM"..i..".ogg") then
			n = i
		else
			break
		end
	end
	if n == -1 or math.random(0, n) == 0 then return "background" end
	return "BGM"..math.random(1, n)
end

MchangeBGM = sgs.CreateTriggerSkill{
	name = "MchangeBGM",
	frequency = sgs.Skill_Compulsory,
	events = {sgs.GameStart},
	priority = 3,
	global = true,
	can_preshow = false,
	on_record = function(self, event, room, player, data)
		if auto_bgm == true then
			local bgm = decideBGM()
			changeBGM(bgm)
			local ip = room:getOwner():getIp()
			if ip ~= "" and string.find(ip, "127.0.0.1") then
				if bgm == "background" then bgm = "BGM0" end
				local log = sgs.LogMessage()
				log.type = "#BGM"
				log.arg = bgm
				room:sendLog(log)
			end
		end
	end,
	can_trigger = function(self, event, room, player, data)
		return ""
	end,
}

Mchangebgm_mode:addSkill(MchangeBGM)
--sgs.addSkillToEngine(MchangeBGM)

--翻译表
sgs.LoadTranslationTable{
	["Mchangebgm_mode"] = "随机BGM",
	["&Mchangebgm_mode"] = "随机BGM",
	["#Mchangebgm_mode"] = "拓展功能",
	["cv:Mchangebgm_mode"] = "无",
	["illustrator:Mchangebgm_mode"] = "无",
	["designer:Mchangebgm_mode"] = "月兔君",
	["MchangeBGM"] = "随机BGM",
	[":MchangeBGM"] = "在游戏开始时随机播放BGM。关闭和开启此功能请于extensions/Ashan6.lua中设置。",
	["#BGM"] = "当前的BGM为 %arg",
	["BGM0"] = "[Faded]",
	["BGM1"] = "[Child Of Light]",
	["BGM2"] = "[Venice Rooftops]",
	["BGM3"] = "[BattleBlock Theater]",
	["BGM4"] = "[Precipitation]",
	["BGM5"] = "[Magic the Gathering]",
	["BGM6"] = "[Might & Magic Heroes VI]",
	["BGM7"] = "[Neverwinter Nights 2]",
	["BGM8"] = "[For River]",
	["BGM9"] = "[Soviet March Remix]",
}

return {Ashan6}