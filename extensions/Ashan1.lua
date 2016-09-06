--[[********************************************
    这是 忧郁の月兔 制作的【英雄无敌Ⅵ-亚山之殇】
]]--********************************************

--[[
    创建拓展包“亚山之殇-英”
]]--
Ashan1 = sgs.Package("Ashan1", sgs.Package_GeneralPack)

sgs.LoadTranslationTable{
    ["Ashan1"] = "亚山之殇-英",
}

--[[[******************
    创建架空势力【英】
]]--[******************
sgs.addNewKingdom("ying", "#990099")
--[[
do
    require  "lua.config" 
	local config = config
	local kingdoms = config.kingdoms
            table.insert(kingdoms,"ying")
	config.color_de = "#003366"
end
]]
sgs.LoadTranslationTable{
	["ying"] = "英",
}

--[[******************
    建立一些通用内容
]]--******************
--建立空卡
MemptyCard = sgs.CreateSkillCard{
	name = "MemptyCard",
}
--建立table-qlist函数
Table2IntList = function(theTable)
	local result = sgs.IntList()
	for _, x in ipairs(theTable) do
		result:append(x)
	end
	return result
end
--建立获取服务器玩家函数
function getServerPlayer(room, name)
	for _, p in sgs.qlist(room:getAlivePlayers()) do
		if p:objectName() == name then return p end
	end
	return nil
end

--[[******************
    创建种族【圣堂】
]]--******************

--[[
   创建武将【禁卫】
]]--
Mtorian = sgs.General(Ashan1, "Mtorian", "ying", 4)
--珠联璧合：女神官、皇家狮鹫
Mtorian:addCompanion("Mvestal")
Mtorian:addCompanion("Mgriffin")
--[[
*【守卫】当你攻击范围内相同势力的其他角色受到一次不来自与你的伤害时，你可以弃置一张非装备牌将此伤害转移给自己:若此后伤害来源在你的攻击范围内，你视为对其使用了一张【杀】。
【巨盾】锁定技，当你受到无属性伤害时，若该伤害多于1点，防止多余的伤害。锁定技，当你受到一次无属性伤害后，你摸一张牌。
]]--				
Mshouwei = sgs.CreateTriggerSkill{
	name = "Mshouwei",
	frequency = sgs.Skill_NotFrequent,
	events = {sgs.DamageInflicted, sgs.DamageComplete},
	can_preshow = true,
	can_trigger = function(self, event, room, player, data)
		if event == sgs.DamageInflicted then
			local torian =  room:findPlayerBySkillName(self:objectName())
			if torian and torian:isAlive() then
				local damage = data:toDamage()
				if not player:hasShownOneGeneral() then return "" end
				if (damage.from and damage.from:objectName() == torian:objectName()) or player:objectName() == torian:objectName() then return "" end
				if torian:inMyAttackRange(player) and (player:isFriendWith(torian) or torian:willBeFriendWith(player)) then
					local not_equip
					for _, card in sgs.qlist(torian:getHandcards()) do
						if not card:isKindOf("EquipCard") then
							not_equip = card
							break
						end
					end
					if not_equip then
						return self:objectName(), torian
					end
				end
			end
		else
			local damage = data:toDamage()
			if player and player:isAlive() and player:hasSkill(self:objectName()) and damage.transfer and damage.transfer_reason == "Mshouwei" then
				local slash = sgs.Sanguosha:cloneCard("slash")
				slash:setSkillName(self:objectName())
				if damage.from and player:inMyAttackRange(damage.from) and player:canSlash(damage.from,slash,false) then
					room:broadcastSkillInvoke(self:objectName(), 2)
					local use = sgs.CardUseStruct()
						use.from = player
						use.to:append(damage.from)
						use.card = slash
					room:useCard(use, false)
				end
			end
		end
		return ""
	end,
	on_cost = function(self,event,room,player,data)
		local torian =  room:findPlayerBySkillName(self:objectName())
		if torian and torian:isAlive() then
			if room:askForCard(torian, "BasicCard,TrickCard", "@shouwei_invoke", data, sgs.Card_MethodDiscard) then
				room:broadcastSkillInvoke(self:objectName(), 1)
				room:notifySkillInvoked(player, self:objectName())
				local log = sgs.LogMessage()
					log.type = "#shouwei"
					log.from = torian
					log.to:append(player)
				room:sendLog(log)
				return true
			end
		end
		return false
	end,
	on_effect = function(self,event,room,player,data)
		local torian =  room:findPlayerBySkillName(self:objectName())
		if torian and torian:isAlive() then
			local damage = data:toDamage()
			damage.transfer = true
			damage.to = torian
			damage.transfer_reason = "Mshouwei"
			local realdamage = sgs.QVariant()
			realdamage:setValue(damage)
			player:setTag("TransferDamage" , realdamage)
			return true
		end
		return false
	end,
}
Mjudun = sgs.CreateTriggerSkill{
	name = "Mjudun",
	frequency = sgs.Skill_Compulsory,
	events = {sgs.DamageInflicted, sgs.Damaged},
	can_preshow = true,
	can_trigger = function(self, event, room, player, data)
		if player and player:isAlive() and player:hasSkill(self:objectName()) then
			local damage = data:toDamage()
			if event == sgs.DamageInflicted then
				if damage.damage > 1 and damage.nature == sgs.DamageStruct_Normal then
					return self:objectName()
				end
			else
				if damage.nature == sgs.DamageStruct_Normal then
					return self:objectName()
				end
			end
		end
		return ""
	end,
	on_cost = function(self,event,room,player,data)
		if player:hasShownSkill(self) or player:askForSkillInvoke(self:objectName(), data) then
			room:broadcastSkillInvoke(self:objectName())
			room:notifySkillInvoked(player, self:objectName())
			return true
		end
		return false
	end,
	on_effect = function(self,event,room,player,data)
		if event == sgs.DamageInflicted then
			local damage = data:toDamage()
			local log = sgs.LogMessage()
	            log.type = "#judun"
				log.from = player
				log.arg = self:objectName()
			room:sendLog(log)
			damage.damage = 1
			data:setValue(damage)
		else
			player:drawCards(1)
		end
	end,
}
--加入技能“守卫”“巨盾”
Mtorian:addSkill(Mshouwei)
Mtorian:addSkill(Mjudun)
--翻译表
sgs.LoadTranslationTable{
    ["Mtorian"] = "禁卫",
	["&Mtorian"] = "禁卫",
	["#Mtorian"] = "忠诚卫士",
	["Mshouwei"] = "守卫",
	["$Mshouwei1"] = "所有人的守护。",
	["$Mshouwei2"] = "让他们明白！",
	["@shouwei_invoke"] = "是否弃置一张非装备牌发动技能“守卫”？",
	["#shouwei"] = "%from 替 %to 承受了伤害！",
	[":Mshouwei"] = "当你攻击范围内相同势力的其他角色受到一次伤害时，你可以弃置一张非装备牌将此伤害转移给自己；若伤害来源在你的攻击范围内，你视为对其使用了一张【杀】。",
	["Mjudun"] = "巨盾",
	["$Mjudun"] = "光明之末，永不眨眼。",
	["#judun"] = "由于 %arg 的效果，%from 受到的伤害降低至1。",
	[":Mjudun"] = "锁定技，当你受到无属性伤害时，若该伤害多于1点，防止多余的伤害。锁定技，当你受到一次无属性伤害后，你摸一张牌。",
	["~Mtorian"] = "战斗……还没有终结！",
	["cv:Mtorian"] = "全能骑士",
	["illustrator:Mtorian"] = "英雄无敌6",
	["designer:Mtorian"] = "月兔君",
}

--[[
   创建武将【神弩手】
]]--
Mmarksman = sgs.General(Ashan1, "Mmarksman", "ying", 3)
--[[
【神弩】锁定技，当你装备区没有武器时，你使用【杀】没有数量限制，否则你使用【杀】没有距离限制。
【贯穿】当你使用【杀】对目标角色造成一次伤害后，你可以选择一项：1.弃置其装备区一张防具或马匹；2.若其下家不为你，视为你对其下家使用此【杀】。
]]--
Mshennu = sgs.CreateTargetModSkill{
	name = "Mshennu",
	pattern = "Slash",
	residue_func = function(self, player)
	    if not player:getWeapon() then
		    if player:hasSkill(self:objectName()) and player:hasShownSkill(self) then
			    return 100
			end
		end
	end,
	distance_limit_func = function(self, player)
	    if player:getWeapon() then
		    if player:hasSkill(self:objectName()) and player:hasShownSkill(self) then
			    return 100
			end
		end
	end,
}
Mguanchuan = sgs.CreateTriggerSkill{
	name = "Mguanchuan",
	frequency = sgs.Skill_NotFrequent,
	events = {sgs.Damage},
	can_preshow = true,
	can_trigger = function(self, event, room, player, data)
		if player and player:isAlive() and player:hasSkill(self:objectName()) then
			local damage = data:toDamage()
			if damage.card and damage.card:isKindOf("Slash") and not (damage.chain or damage.transfer) then
				if (damage.to:isAlive() and (damage.to:getArmor() or damage.to:getDefensiveHorse() or damage.to:getOffensiveHorse())) or (damage.to:getNextAlive():objectName() ~= player:objectName() and player:canSlash(damage.to:getNextAlive(),damage.card,false)) then
					return self:objectName()
				end
			end
		end
		return ""
	end,
	on_cost = function(self,event,room,player,data)
		if player:askForSkillInvoke(self:objectName(), data) then
			return true
		end
		return false
	end,
	on_effect = function(self,event,room,player,data)
		local damage = data:toDamage()
		if (damage.to:isAlive() and (damage.to:getArmor() or damage.to:getDefensiveHorse() or damage.to:getOffensiveHorse())) and (damage.to:getNextAlive():objectName() ~= player:objectName() and player:canSlash(damage.to:getNextAlive(),damage.card,false)) then
			choice = room:askForChoice(player, self:objectName(), "guan+chuan", data)
		else
			if damage.to:isAlive() and (damage.to:getArmor() or damage.to:getDefensiveHorse() or damage.to:getOffensiveHorse()) then
				choice = "guan"
			else
				choice = "chuan"
			end
		end
		if choice == "guan" then
			local damage = data:toDamage()
			local ai_data = sgs.QVariant()
			ai_data:setValue(damage.to)
			if damage.to:getArmor() then
				if damage.to:getDefensiveHorse() then
					if damage.to:getOffensiveHorse() then
						choice = room:askForChoice(player, "guan_what", "guan_armor+guan_def+guan_off", ai_data)
					else
						choice = room:askForChoice(player, "guan_what", "guan_armor+guan_def", ai_data)
					end
				else
					if damage.to:getOffensiveHorse() then
						choice = room:askForChoice(player, "guan_what", "guan_armor+guan_off", ai_data)
					else
						choice = "guan_armor"
					end
				end
			else
				if damage.to:getDefensiveHorse() then
					if damage.to:getOffensiveHorse() then
						choice = room:askForChoice(player, "guan_what", "guan_def+guan_off", ai_data)
					else
						choice = "guan_def"
					end
				else
					if damage.to:getOffensiveHorse() then
						choice = "guan_off"
					end
				end
			end
			if choice == "guan_armor" then
				room:broadcastSkillInvoke(self:objectName(), 1)
				room:throwCard(damage.to:getArmor(), damage.to, player)
			elseif choice == "guan_def" then
				room:broadcastSkillInvoke(self:objectName(), 2)
				room:throwCard(damage.to:getDefensiveHorse(), damage.to, player)
			else
				room:broadcastSkillInvoke(self:objectName(), 3)
				room:throwCard(damage.to:getOffensiveHorse(), damage.to, player)
			end
		else
			room:broadcastSkillInvoke(self:objectName(), 4)
			local use = sgs.CardUseStruct()
				use.from = player
				use.to:append(damage.to:getNextAlive())
				use.card = damage.card
			room:useCard(use, false)
		end
		return false
	end,
}
--加入技能“神弩”、“贯穿”
Mmarksman:addSkill(Mshennu)
Mmarksman:addSkill(Mguanchuan)
--翻译表
sgs.LoadTranslationTable{
    ["Mmarksman"] = "神弩手",
	["&Mmarksman"] = "神弩手",
	["#Mmarksman"] = "百步穿杨",
	["Mshennu"] = "神弩",
	["$Mshennu"] = "紧随其后！",
	[":Mshennu"] = "锁定技，当你装备区没有武器时，你使用【杀】没有数量限制，否则你使用【杀】没有距离限制。",
	["Mguanchuan"] = "贯穿",
	["$Mguanchuan1"] = "罪有应得！",
	["$Mguanchuan2"] = "让开！",
	["$Mguanchuan3"] = "接受严惩！",
	["$Mguanchuan4"] = "一同消亡吧！",
	["guan"] = "破甲",
	["chuan"] = "穿敌",
	["guan_what"] = "破坏装甲",
	["guan_armor"] = "防具",
	["guan_def"] = "+1马",
	["guan_off"] = "-1马",
	[":Mguanchuan"] = "当你使用【杀】对目标角色造成一次伤害后，你可以选择一项：1.弃置其装备区一张防具或马匹；2.若其下家不为自己，视为你对其下家使用此【杀】。",
	["~Mmarksman"] = "虽死犹荣！",
	["cv:Mmarksman"] = "敌法师",
	["illustrator:Mmarksman"] = "英雄无敌6",
	["designer:Mmarksman"] = "月兔君",
}

--[[
   创建武将【女神官】
]]--
Mvestal = sgs.General(Ashan1, "Mvestal", "ying", 3, false)
--[[
*【治愈】摸牌阶段，你可以放弃摸牌，改为令一名已受伤的其他角色回复1点体力，然后你摸X张牌（X为其已损失体力且最多为2）。
*【信仰】主将技，当你受到一次伤害后，你可以展示一张牌进行一次判定：若结果与你展示的牌花色相同，你回复1点体力；否则你弃置该牌然后获得该判定牌。
*【平和】副将技，锁定技，当你使用【杀】对目标角色造成一次伤害后，若其与你势力不同，你弃置其一张手牌，若此时其手牌数不小于其体力，你回复1点体力否则摸一张牌。
]]--
Mzhiyu = sgs.CreateTriggerSkill{
	name = "Mzhiyu",
	frequency = sgs.Skill_NotFrequent,
	events = {sgs.EventPhaseStart},
	can_preshow = true,
	can_trigger = function(self, event, room, player, data)
		if player and player:isAlive() and player:hasSkill(self:objectName()) then
			if player:getPhase() == sgs.Player_Draw then
				local targets = sgs.SPlayerList()
				for _,p in sgs.qlist(room:getOtherPlayers(player)) do
					if p:isWounded() then
						targets:append(p)
					end
				end
				if not targets:isEmpty() then
					return self:objectName()
				end
			end
		end
		return ""
	end,
	on_cost = function(self,event,room,player,data)
		if player:askForSkillInvoke(self:objectName(), data) then
			return true
		end
		return false
	end,
	on_effect = function(self,event,room,player,data)
		local targets = sgs.SPlayerList()
		for _,p in sgs.qlist(room:getOtherPlayers(player)) do
			if p:isWounded() then
				targets:append(p)
			end
		end
		if not targets:isEmpty() then
			local target = room:askForPlayerChosen(player, targets, self:objectName())
			if target:getLostHp() > 2 then
				room:broadcastSkillInvoke(self:objectName(), 1)
			else
				room:broadcastSkillInvoke(self:objectName(), 2)
			end
			local recover = sgs.RecoverStruct()
				recover.who = player
				recover.recover = 1
			room:recover(target, recover)
			room:notifySkillInvoked(target, self:objectName())
			local x = target:getLostHp()
			x = math.min(x, 2)
			if x > 0 then
				player:drawCards(x)
			end
			return true
		end
	end,
}
Mpinghe = sgs.CreateTriggerSkill{
	name = "Mpinghe",
	frequency = sgs.Skill_Compulsory,
	events = {sgs.Damage},
	relate_to_place = "deputy",
	can_preshow = true,
	can_trigger = function(self, event, room, player, data)
		if player and player:isAlive() and player:hasSkill(self:objectName()) then
			local damage = data:toDamage()
			if not (damage.to and damage.to:hasShownOneGeneral()) then return "" end
			if damage.card and damage.card:isKindOf("Slash") and not (damage.chain or damage.transfer) then
				if damage.to:isAlive() and not (player:isFriendWith(damage.to) or player:willBeFriendWith(damage.to)) and not damage.to:isKongcheng() then
					return self:objectName()
				end
			end
		end
		return ""
	end,
	on_cost = function(self,event,room,player,data)
		if player:hasShownSkill(self) or player:askForSkillInvoke(self:objectName(), data) then
			room:broadcastSkillInvoke(self:objectName())
			room:notifySkillInvoked(player, self:objectName())
			return true
		end
		return false
	end,
	on_effect = function(self,event,room,player,data)
		local damage = data:toDamage()
		local id = room:askForCardChosen(player, damage.to, "h", self:objectName())
		room:throwCard(id, damage.to, player)
		if damage.to:getHandcardNum() >= damage.to:getHp() then
			if player:isWounded() then
				local recover = sgs.RecoverStruct()
					recover.who = player
					recover.recover = 1
				room:recover(player, recover)
			else
				player:drawCards(1)
			end
		end
	end,
}
Mxinyang = sgs.CreateTriggerSkill{
	name = "Mxinyang", 
	frequency = sgs.Skill_NotFrequent, 
	events = {sgs.Damaged},
	relate_to_place = "head",
	can_preshow = true,
	can_trigger = function(self, event, room, player, data)
		if player and player:isAlive() and player:hasSkill(self:objectName()) then
			if not player:isNude() then
				return self:objectName()
			end
		end
		return ""
	end,
	on_cost = function(self,event,room,player,data)
		if player:askForSkillInvoke(self:objectName(), data) then
			return true
		end
		return false
	end,
	on_effect = function(self,event,room,player,data)
		local id = room:askForExchange(player, self:objectName(), 1, 1, "xinyang_show", "", ""):getSubcards():first()
		room:showCard(player, id)
		local card = sgs.Sanguosha:getWrappedCard(id)
		local judge = sgs.JudgeStruct()
			if card:getSuit() == sgs.Card_Spade then
				judge.pattern = ".|spade|."
			elseif card:getSuit() == sgs.Card_Heart then
				judge.pattern = ".|heart|."
			elseif card:getSuit() == sgs.Card_Club then
				judge.pattern = ".|club|."
			else
				judge.pattern = ".|diamond|."
			end
			judge.good = true
			judge.reason = self:objectName()
			judge.who = player
			judge.play_animation = true
			judge.negative = false
		room:judge(judge)
		if judge:isGood() then
			room:broadcastSkillInvoke(self:objectName(), 1)
			local recover = sgs.RecoverStruct()
				recover.who = player
				recover.recover = 1
			room:recover(player, recover)
			room:notifySkillInvoked(player, self:objectName())
		else
			room:throwCard(card, player)
			room:broadcastSkillInvoke(self:objectName(), 2)
			player:obtainCard(judge.card, true)
		end
		return false
	end,
}
--加入技能=“平和”“信仰”“感召”“治愈”
Mvestal:addSkill(Mzhiyu)
Mvestal:addSkill(Mpinghe)
Mvestal:addSkill(Mxinyang)
--翻译表
sgs.LoadTranslationTable{
    ["Mvestal"] = "女神官",
	["&Mvestal"] = "女神官",
	["#Mvestal"] = "战场之花",
	["Mzhiyu"] = "治愈",
	["$Mzhiyu1"] = "疗伤之术！",
	["$Mzhiyu2"] = "打起精神来~",
	[":Mzhiyu"] = "摸牌阶段，你可以放弃摸牌，改为令一名已受伤的其他角色回复1点体力，然后你摸X张牌（X为其已损失体力且最多为2）。",
	["Mpinghe"] = "平和",
	["$Mpinghe"] = "肯定被我迷住了~",
	["@pinghe"] = "平和",
	[":Mpinghe"] = "副将技，锁定技，当你使用【杀】对目标角色造成一次伤害后，若其与你势力不同，你弃置其一张手牌，若此时其手牌数不小于其体力，你回复1点体力否则摸一张牌。",
	["Mxinyang"] = "信仰",
	["xinyang_show"] = "请展示一张手牌。",
	["$Mxinyang1"] = "这是天意！",
	["$Mxinyang2"] = "怎么这样……",
	[":Mxinyang"] = "主将技，当你受到一次伤害后，你可以展示一张牌进行一次判定：若结果与你展示的牌花色相同，你回复1点体力；否则你弃置该牌然后获得该判定牌。",
	["~Mvestal"] = "我的心很痛……",
	["cv:Mvestal"] = "魅惑魔女",
	["illustrator:Mvestal"] = "英雄无敌6",
	["designer:Mvestal"] = "月兔君",
}

--[[
   创建武将【皇家狮鹫】
]]--
Mgriffin = sgs.General(Ashan1, "Mgriffin", "ying", 4)
--[[
【反击】当你受到攻击范围内其他角色造成的一次伤害后，你可以弃置一张基本牌（若你武将牌已叠置则不弃）视为对其使用了一张【杀】。
【俯冲】弃牌阶段结束时，若你的武将牌未叠置，你可以摸一张牌并将你的武将牌叠置。锁定技，当你成为【杀】和【决斗】的目标时，若你武将牌已叠置，你取消之。锁定技，当你的武将牌取消叠置时，你视为对一名其他角色使用了一张【杀】。
]]--
Mfanji = sgs.CreateTriggerSkill{
	name = "Mfanji",  
	frequency = sgs.Skill_Compulsory, 
	events = {sgs.Damaged},
	can_preshow = true,
	can_trigger = function(self, event, room, player, data)
		if player and player:isAlive() and player:hasSkill(self:objectName()) then
			local damage = data:toDamage()
			local slash = sgs.Sanguosha:cloneCard("slash")
			slash:setSkillName(self:objectName())
			if damage.from and player:objectName() ~= damage.from:objectName() and player:inMyAttackRange(damage.from) and player:canSlash(damage.from,slash,false) and not player:isKongcheng() then
				local basic
				for _, card in sgs.qlist(player:getHandcards()) do
					if card:isKindOf("BasicCard") then
						basic = card
						break
					end
				end
				if basic or not player:faceUp() then
					return self:objectName()
				end
			end
		end
		return ""
	end,
	on_cost = function(self,event,room,player,data)
		if player:faceUp() then
			if room:askForCard(player, "BasicCard", "@fanji_invoke", data, sgs.Card_MethodDiscard) then
				room:broadcastSkillInvoke(self:objectName())
				return true
			end
		else
			if room:askForSkillInvoke(player, self:objectName(), data) then
				room:broadcastSkillInvoke(self:objectName())
				return true
			end
		end
		return false
	end,
	on_effect = function(self,event,room,player,data)
		local damage = data:toDamage()
		local slash = sgs.Sanguosha:cloneCard("slash")
		slash:setSkillName(self:objectName())
		local use = sgs.CardUseStruct()
			use.from = player
			use.to:append(damage.from)
			use.card = slash
		room:useCard(use, false)
	end,
}
Mfuchong = sgs.CreateTriggerSkill{
	name = "Mfuchong",  
	frequency = sgs.Skill_NotFrequent, 
	events = {sgs.EventPhaseEnd, sgs.TurnedOver},
	can_preshow = true,
	can_trigger = function(self, event, room, player, data)
		if player and player:isAlive() and player:hasSkill(self:objectName()) then
			if event == sgs.EventPhaseEnd then
				if player:getPhase() == sgs.Player_Discard and player:faceUp() then
					return self:objectName()
				end
			else
				if not player:faceUp() then
					room:broadcastSkillInvoke(self:objectName(), 1)
					local log = sgs.LogMessage()
						log.type = "#fuchong"
						log.from = player
					room:sendLog(log)
				else
					local slash = sgs.Sanguosha:cloneCard("slash")
					slash:setSkillName(self:objectName())
					local targets = sgs.SPlayerList()
					for _,p in sgs.qlist(room:getOtherPlayers(player)) do
						if player:canSlash(p,slash,false) then
							targets:append(p)
						end
					end
					if not targets:isEmpty() then
						return self:objectName()
					end
				end
			end
		end
		return ""
	end,
	on_cost = function(self,event,room,player,data)
		if event == sgs.EventPhaseEnd then
			if room:askForSkillInvoke(player, self:objectName(), data) then
				return true
			end
		else
			room:notifySkillInvoked(player, self:objectName())
			return true
		end
		return false
	end,
	on_effect = function(self,event,room,player,data)
		if event == sgs.EventPhaseEnd then
			player:drawCards(1)
			player:turnOver()
		else
			local slash = sgs.Sanguosha:cloneCard("slash")
			slash:setSkillName(self:objectName())
			local targets = sgs.SPlayerList()
			for _,p in sgs.qlist(room:getOtherPlayers(player)) do
				if player:canSlash(p,slash,false) then
					targets:append(p)
				end
			end
			if not targets:isEmpty() then
				local target = room:askForPlayerChosen(player, targets, self:objectName())
				room:broadcastSkillInvoke(self:objectName(), 2)
				local use = sgs.CardUseStruct()
					use.from = player
					use.to:append(target)
					use.card = slash
				room:useCard(use, false)
			end
		end
		return false
	end,
}
Mfuchong_avoid = sgs.CreateTriggerSkill{
	name = "#Mfuchong_avoid",  
	frequency = sgs.Skill_Compulsory,
	events = {sgs.TargetConfirming},
	can_preshow = true,
	can_trigger = function(self, event, room, player, data)
		if player and player:isAlive() and player:hasSkill("Mfuchong") then
			local use = data:toCardUse()
			if use.card and (use.card:isKindOf("Slash") or use.card:isKindOf("Duel")) and not player:faceUp() and use.to:contains(player) then
				return self:objectName(), player
			end
		end
		return ""
	end,
	on_cost = function(self,event,room,player,data)
		if player:hasShownSkill(Mfuchong) or player:askForSkillInvoke(self:objectName(), data) then
			room:broadcastSkillInvoke("Mfuchong", 3)
			room:notifySkillInvoked(player, self:objectName())
			return true
		end
		return false
	end,
	on_effect = function(self,event,room,player,data)
		local use = data:toCardUse()
		sgs.Room_cancelTarget(use, player)
	--	use.to:removeOne(player)
		data:setValue(use)
		return false
	end,
}
--加入技能“反击”“俯冲”
Mgriffin:addSkill(Mfanji)
Mgriffin:addSkill(Mfuchong)
Mgriffin:addSkill(Mfuchong_avoid)
Ashan1:insertRelatedSkills("Mfuchong", "#Mfuchong_avoid")
--翻译表
sgs.LoadTranslationTable{
    ["Mgriffin"] = "皇家狮鹫",
	["&Mgriffin"] = "皇家狮鹫",
	["#Mgriffin"] = "翱翔之翼",
	["Mfanji"] = "反击",
	["$Mfanji"] = "送你去死!",
	["@fanji_invoke"] = "是否弃置一张基本牌发动技能“反击”？",
	[":Mfanji"] = "当你受到攻击范围内其他角色造成的一次伤害后，你可以弃置一张基本牌（若你武将牌已叠置则不弃）视为对其使用了一张【杀】。",
	["Mfuchong"] = "俯冲",
	["#Mfuchong_avoid"] = "俯冲",
	["$Mfuchong1"] = "我要飞得更高！",
	["$Mfuchong2"] = "以后，你得多注意天空！",
	["$Mfuchong3"] = "注意侦查。",
	["#fuchong"] = "%from 飞至高空。",
	[":Mfuchong"] = "弃牌阶段结束时，若你的武将牌未叠置，你可以摸一张牌并将你的武将牌叠置。锁定技，当你成为【杀】和【决斗】的目标时，若你武将牌已叠置，你取消之。锁定技，当你的武将牌取消叠置时，你视为对一名其他角色使用了一张【杀】。",
	["~Mgriffin"] = "感觉不到我的翅膀了。",
	["cv:Mgriffin"] = "冥界亚龙",
	["illustrator:Mgriffin"] = "英雄无敌6",
	["designer:Mgriffin"] = "月兔君",
}

--[[
   创建武将【耀灵】
]]--
Mblazing = sgs.General(Ashan1, "Mblazing", "ying", 3, false)
--[[
【耀击】当你使用【杀】对目标角色造成一次伤害时，你可以防止该伤害并选择一项：1.令其体力上限-1，直到其造成一次伤害；2.直到其回合结束，其使用的基本牌若指定除其自身以外的目标时，取消之。
【光速】当你需要使用或打出一张【闪】时，若你手牌数等于当前体力，你可以视为使用或打出了一张【闪】，若如此做，你可以摸一张牌。
]]--
Mguangsu = sgs.CreateTriggerSkill{
	name = "Mguangsu",
	frequency = sgs.NotFrequent,
	events = {sgs.CardAsked},
	can_preshow = true,
	can_trigger = function(self, event, room, player, data)
		if player and player:isAlive() and player:hasSkill(self:objectName()) then
			local pattern = data:toStringList()[1]
			if pattern == "jink" then
				if player:getHandcardNum() == player:getHp() then
					return self:objectName()
				end
			end
		end
		return ""
	end,
	on_cost = function(self,event,room,player,data)
		if player:askForSkillInvoke(self:objectName(), data) then
			return true
		end
		return false
	end,
	on_effect = function(self,event,room,player,data)
		local jink = sgs.Sanguosha:cloneCard("jink")
		if player:getMark("@liming") > 0 then
			jink:setSkillName("Mliming4")
			room:broadcastSkillInvoke("Mliming", 4)
		else
			jink:setSkillName(self:objectName())
		end
		room:provide(jink)
		choice = room:askForChoice(player, self:objectName(), "gs_yes+gs_no", data)
		if choice == "gs_yes" then
			player:drawCards(1)
		end
		return true
	end,
}
Myaoji = sgs.CreateTriggerSkill{
	name = "Myaoji",
	frequency = sgs.Skill_NotFrequent,
	events = {sgs.DamageCaused},
	can_preshow = true,
	can_trigger = function(self, event, room, player, data)
		if player and player:isAlive() and player:hasSkill(self:objectName()) then
			local damage = data:toDamage()
			if damage.to and damage.to:isAlive() and damage.card and damage.card:isKindOf("Slash") and not (damage.chain or damage.transfer) then
				return self:objectName()
			end
		end
		return ""
	end,
	on_cost = function(self,event,room,player,data)
		if player:askForSkillInvoke(self:objectName(), data) then
			return true
		end
		return false
	end,
	on_effect = function(self,event,room,player,data)
		local damage = data:toDamage()
		if damage.to:getMark("@yaojibasic") == 0 then
			choice = room:askForChoice(player, self:objectName(), "yaoji_hp+yaoji_basic", data)
		else
			choice = "yaoji_hp"
		end
		if choice == "yaoji_hp" then
			room:broadcastSkillInvoke(self:objectName(), 1)
			local log = sgs.LogMessage()
				log.type = "#yaoji1"
				log.from = damage.to
			room:sendLog(log)
			room:loseMaxHp(damage.to)
			local x = damage.to:getMark("@yaojihp")
			room:setPlayerMark(damage.to, "@yaojihp", x+1)
		else
			room:broadcastSkillInvoke(self:objectName(), 2)
			local log = sgs.LogMessage()
				log.type = "#yaoji2"
				log.from = damage.to
			room:sendLog(log)
			room:setPlayerMark(damage.to, "@yaojibasic", 1)
		end
		return true
	end,
}
Myaoji_avoid_hp = sgs.CreateTriggerSkill{
	name = "#Myaoji_avoid_hp",
	frequency = sgs.Skill_Compulsory,
	events = {sgs.Damage},
	can_trigger = function(self, event, room, player, data)
		if player and player:isAlive() and player:getMark("@yaojihp") > 0 then
			room:broadcastSkillInvoke("Myaoji", 3)
			room:setPlayerProperty(player, "maxhp", sgs.QVariant(player:getMaxHp()+player:getMark("@yaojihp")))
			room:setPlayerMark(player, "@yaojihp", 0)
			local log = sgs.LogMessage()
				log.type = "#yaoji3"
				log.from = player
			room:sendLog(log)
			room:notifySkillInvoked(player, self:objectName())
		end
	end,
}
Myaoji_avoid_basic = sgs.CreateTriggerSkill{
	name = "#Myaoji_avoid_basic",
	frequency = sgs.Skill_Compulsory,
	events = {sgs.EventPhaseChanging, sgs.CardUsed, sgs.TargetConfirming},
	can_trigger = function(self, event, room, player, data)
		if player and player:isAlive() then
			if event == sgs.EventPhaseChanging then
				local change = data:toPhaseChange()
				if change.to == sgs.Player_NotActive and player:getMark("@yaojibasic") == 1 then
					room:setPlayerMark(player, "@yaojibasic", 0)
					room:broadcastSkillInvoke("Myaoji", 4)
					local log = sgs.LogMessage()
						log.type = "#yaoji4"
						log.from = player
					room:sendLog(log)
					room:notifySkillInvoked(player, self:objectName())
				end
			elseif event == sgs.CardUsed then
				local use = data:toCardUse()
				if use.card and use.card:isKindOf("BasicCard") and player:getMark("@yaojibasic") == 1 then
					room:setPlayerFlag(player, "yaoji_user")
				end
			else
				local use = data:toCardUse()
				if use.card and use.card:isKindOf("BasicCard") then
					if use.from and use.from:hasFlag("yaoji_user") and use.from:objectName() ~= player:objectName() and use.to:contains(player) then
						return self:objectName()
					end
				end
			end
		end
		return ""
	end,
	on_cost = function(self,event,room,player,data)
		return true
	end,
	on_effect = function(self,event,room,player,data)
		if event == sgs.TargetConfirming then
			local use = data:toCardUse()
			room:broadcastSkillInvoke("Myaoji", 5)
			room:notifySkillInvoked(player, self:objectName())
			room:setPlayerFlag(use.from, "-yaoji_user")
			sgs.Room_cancelTarget(use, player)
			data:setValue(use)
		end
		return false
	end,
}
--加入技能“光速”“耀击”
Mblazing:addSkill(Mguangsu)
Mblazing:addSkill(Myaoji)
Mblazing:addSkill(Myaoji_avoid_hp)
Mblazing:addSkill(Myaoji_avoid_basic)
Ashan1:insertRelatedSkills("Myaoji", "#Myaoji_avoid_hp")
Ashan1:insertRelatedSkills("Myaoji", "#Myaoji_avoid_basic")
--翻译表
sgs.LoadTranslationTable{
    ["Mblazing"] = "耀灵",
	["&Mblazing"] = "耀灵",
	["#Mblazing"] = "闪烁之光",
	["Mguangsu"] = "光速",
	["Mliming4"] = "光速",
	["gs_yes"] = "摸一张牌",
	["gs_no"] = "不摸牌",
	["$Mguangsu"] = "（嘲笑声）",
	[":Mguangsu"] = "当你需要使用或打出一张【闪】时，若你手牌数等于当前体力，你可以视为使用或打出了一张【闪】，若如此做，你可以摸一张牌。",
	["Myaoji"] = "耀击",
	["#Myaoji_avoid_hp"] = "耀击",
	["#Myaoji_avoid_basic"] = "耀击",
	["$Myaoji1"] = "真是个废物！",
	["$Myaoji2"] = "还不算太耀眼~",
	["$Myaoji3"] = "不……",
	["$Myaoji4"] = "灰飞烟灭。",
	["$Myaoji5"] = "尽情燃烧~",
	["@yaojihp"] = "耀击上限",
	["@yaojibasic"] = "耀击使用",
	["yaoji_hp"] = "体质损伤",
	["yaoji_basic"] = "视力破坏",
	["#yaoji1"] = "%from 体质受到损害，现在很虚弱！",
	["#yaoji2"] = "%from 视力受到损害，无法瞄准目标了！",
	["#yaoji3"] = "%from 的体质恢复！",
	["#yaoji4"] = "%from 的视力恢复！",
	[":Myaoji"] = "当你使用【杀】对目标角色造成一次伤害时，你可以防止该伤害并选择一项：1.令其体力上限-1，直到其造成一次伤害；2.直到其回合结束，其使用的基本牌若指定除其自身以外的目标时，取消之。",
	["~Mblazing"] = "热情褪去了……",
	["cv:Mblazing"] = "莉娜",
	["illustrator:Mblazing"] = "英雄无敌6",
	["designer:Mblazing"] = "月兔君",
}

--[[
   创建武将【烈日十字军】
]]--
Mcrusader = sgs.General(Ashan1, "Mcrusader", "ying", 4)
--珠联璧合：女神官、皇家狮鹫
Mcrusader:addCompanion("Mmarksman")
Mcrusader:addCompanion("Mcelestial")
--[[
【冲锋】锁定技，当你使用【杀】对目标角色造成一次伤害时，若其与你的距离大于1，此伤害+1。
【荣光】副将技，当你处于濒死状态时，其他你所在队列里的角色可以弃置一张手牌并失去1点体力，令你回复1点体力并摸一张牌。
【神驹】主将技，锁定技，与你势力相同的角色装备区每有一张马，摸牌阶段你额外摸一张牌。主将技，每当你失去装备区里的马后，若你已受伤，你可以回复1点体力。
]]--
Mchongfeng = sgs.CreateTriggerSkill{
	name = "Mchongfeng",
	frequency = sgs.Skill_Compulsory,
	events = {sgs.ConfirmDamage},
	can_preshow = true,
	can_trigger = function(self, event, room, player, data)
		if player and player:isAlive() and player:hasSkill(self:objectName()) then
			local damage = data:toDamage()
			if damage.card and damage.card:isKindOf("Slash") and not (damage.chain or damage.transfer) then
				if damage.to:distanceTo(player) > 1 then
					return self:objectName()
				end
			end
		end
		return ""
	end,
	on_cost = function(self,event,room,player,data)
		if player:hasShownSkill(self) or player:askForSkillInvoke(self:objectName(), data) then
			room:broadcastSkillInvoke(self:objectName())
			room:notifySkillInvoked(player, self:objectName())
			return true
		end
		return false
	end,
	on_effect = function(self,event,room,player,data)
		local damage = data:toDamage()
		local log = sgs.LogMessage()
			log.type = "#DamageMore"
			log.arg = self:objectName()
			log.from = player
		room:sendLog(log)
		damage.damage = damage.damage + 1
		data:setValue(damage)
	end,
}
Mrongguang = sgs.CreateTriggerSkill{
	name = "Mrongguang",
	events = {sgs.AskForPeaches},
	relate_to_place = "deputy",
	can_trigger = function(self, event, room, player, data)
		if player and player:isAlive() then
			local dying = data:toDying()
			if dying.who:hasSkill(self:objectName()) and dying.who:hasShownSkill(self) then
				local formation = dying.who:getFormation()
				if formation:length() > 1 then
					if formation:contains(player) and not player:isKongcheng() and player:objectName() ~= dying.who:objectName() then
						return self:objectName(), player
					end
				end
			end
		end
		return ""
	end,
	on_cost = function(self,event,room,player,data)
		if room:askForCard(player, ".|.|.|hand", "@rongguang_invoke", data, sgs.Card_MethodDiscard) then
			room:broadcastSkillInvoke(self:objectName())
			return true
		end
		return false
	end,
	on_effect = function(self,event,room,player,data)
		local dying = data:toDying()
		room:loseHp(player, 1)
		local recover = sgs.RecoverStruct()
			recover.who = player
			recover.recover = 1
		room:recover(dying.who, recover)
		room:notifySkillInvoked(dying.who, self:objectName())
		dying.who:drawCards(1)
	end,
}
Mshenju = sgs.CreateDrawCardsSkill{
	name = "Mshenju",
	frequency = sgs.Skill_Compulsory,
	relate_to_place = "head",
	can_preshow = true,
	can_trigger = function(self, event, room, player, data)
		if player and player:isAlive() and player:hasSkill(self:objectName()) then
			local n = 0
			for _,p in sgs.qlist(room:getAlivePlayers()) do
				if p:isFriendWith(player) then
					if p:getDefensiveHorse()then
						n = n+1
						if p:getOffensiveHorse() then
							n = n+1
						end
					else
						if p:getOffensiveHorse() then
							n = n+1
						end
					end
				end
			end
			if n > 0 then
				room:setPlayerMark(player, "shenju_draw", n)
				return self:objectName()
			end
		end
		return ""
	end,
	on_cost = function(self,event,room,player,data)
		if player:hasShownSkill(self) or player:askForSkillInvoke(self:objectName(), data) then
			room:broadcastSkillInvoke(self:objectName())
			return true
		end
		return false
	end,
	draw_num_func = function(self,player,n)
		local m = player:getMark("shenju_draw")
		player:setMark("shenju_draw", 0)
		return n+m
	end,
}
Mshenju_recover = sgs.CreateTriggerSkill{
	name = "#Mshenju_recover",
	events = {sgs.CardsMoveOneTime},
	frequency = sgs.Skill_Frequent,
	relate_to_place = "head",
	can_preshow = true,
	can_trigger = function(self,event,room,player,data)
		if not player or player:isDead() or not player:isWounded() or not player:hasSkill(self:objectName()) then return false end
		local move = data:toMoveOneTime()
		if move.from and move.from:objectName() == player:objectName() and move.from_places:contains(sgs.Player_PlaceEquip) then
			local card_ids = sgs.IntList()
			local invoke
			for _,id in sgs.list(move.card_ids) do
				if sgs.Sanguosha:getCard(id):isKindOf("DefensiveHorse") or sgs.Sanguosha:getCard(id):isKindOf("OffensiveHorse") then
					invoke = true
					break
				end
			end
			if invoke then return self:objectName() end
		end
	end,
	on_cost = function(self,event,room,player,data)
		if player:askForSkillInvoke(self:objectName(), data) then
			room:broadcastSkillInvoke("Mshenju")
			return true
		end
		return false
	end,
	on_effect = function(self,event,room,player,data)
        if player:isWounded() then
			local recover = sgs.RecoverStruct()
				recover.who = player
				recover.recover = 1
			room:recover(player, recover)
			room:notifySkillInvoked(player, self:objectName())
		end
	end,
}
--加入技能“冲锋”“荣光”“神驹”
Mcrusader:addSkill(Mchongfeng)
Mcrusader:addSkill(Mrongguang)
Mcrusader:addSkill(Mshenju)
Mcrusader:addSkill(Mshenju_recover)
Ashan1:insertRelatedSkills("Mshenju", "#Mshenju_recover")
--翻译表
sgs.LoadTranslationTable{
    ["Mcrusader"] = "烈日十字军",
	["&Mcrusader"] = "烈日十字军",
	["#Mcrusader"] = "虔诚誓言",
	["Mchongfeng"] = "冲锋",
	["$Mchongfeng"] = "这是你虚弱的见证！",
	["#DamageMore"] = "由于 %arg 的效果，%from 造成的伤害+1。",
	[":Mchongfeng"] = "锁定技，当你使用【杀】对目标角色造成一次伤害时，若其与你的距离大于1，此伤害+1。",
	["Mrongguang"] = "荣光",
	["$Mrongguang"] = "考验你的时刻到了！",
	["@rongguang_invoke"] = "是否弃置一张手牌并失去1点体力发动技能“荣光”？",
	["$rongguang"] = "考验你的时刻到了",
	[":Mrongguang"] = "副将技，当你处于濒死状态时，其他你所在队列里的角色可以弃置一张手牌并失去1点体力，令你回复1点体力并摸一张牌。",
	["Mshenju"] = "神驹",
	["#Mshenju_recover"] = "神驹",
	["$Mshenju"] = "时刻准备！",
	[":Mshenju"] = "主将技，锁定技，与你势力相同的角色装备区每有一张马，摸牌阶段你额外摸一张牌。主将技，每当你失去装备区里的马后，若你已受伤，你可以回复1点体力。",
	["~Mcrusader"] = "骑士……陨落了！",
	["cv:Mcrusader"] = "混沌骑士",
	["illustrator:Mcrusader"] = "英雄无敌6",
	["designer:Mcrusader"] = "月兔君",
}

--[[
   创建武将【昊天使】
]]--
Mcelestial = sgs.General(Ashan1, "Mcelestial", "ying", 3, false)
--珠联璧合：耀灵
Mcelestial:addCompanion("Mblazing")
--[[
*【审判】锁定技，摸牌阶段，你须放弃摸牌，改为获得其他角色各一张手牌：若你以此法获得大于三张牌，你失去1点体力；若你以此法没有获得牌，你摸两张牌。
*【怜悯】锁定技，你的梅花手牌均视为【桃】。
*【夙愿】主将技，锁定技，当你第一次明置此武将牌时，你的体力上限-1。主将技，锁定技，你的手牌上限+1。主将技，限定技，准备阶段开始时，若你没有手牌，你可以与一名你攻击范围内不同势力的其他角色交换血牌，然后你选择失去技能“审判”或“怜悯”。
]]--
Mshenpan = sgs.CreateTriggerSkill{
	name = "Mshenpan",  
	frequency = sgs.Skill_Compulsory, 
	events = {sgs.EventPhaseStart},
	can_preshow = true,
	can_trigger = function(self, event, room, player, data)
		if player and player:isAlive() and player:hasSkill(self:objectName()) then
			if player:getPhase() == sgs.Player_Draw then
				return self:objectName()
			end
		end
		return ""
	end,
	on_cost = function(self,event,room,player,data)
		if player:hasShownSkill(self) or player:askForSkillInvoke(self:objectName(), data) then
			room:broadcastSkillInvoke(self:objectName())
			room:notifySkillInvoked(player, self:objectName())
			return true
		end
		return false
	end,
	on_effect = function(self,event,room,player,data)
		local x = 0
		for _,p in sgs.qlist(room:getOtherPlayers(player)) do
			if not p:isKongcheng() then
				local id = room:askForCardChosen(player, p, "h", self:objectName())
				room:obtainCard(player, id, false)
				x = x+1
			end
		end
		if x > 0 then
			if x > 3 then
				room:loseHp(player, 1)
			end
		else
			player:drawCards(2)
		end
		return true
	end,
}
Mlianmin = sgs.CreateFilterSkill{
    name = "Mlianmin",
	view_filter = function(self, to_select)
		local room = sgs.Sanguosha:currentRoom()
		local player = room:getCardOwner(to_select:getEffectiveId())
		if player and player:hasShownSkill(self) then
			local suit = to_select:getSuit()
			local place = room:getCardPlace(to_select:getEffectiveId())
			return suit == sgs.Card_Club and place == sgs.Player_PlaceHand
		end
	end,
	view_as = function(self, card)
	    local id = card:getId()
		local suit = card:getSuit()
		local point = card:getNumber()
		local peach = sgs.Sanguosha:cloneCard("peach", suit, point)
		peach:setSkillName(self:objectName())
		local vs_card = sgs.Sanguosha:getWrappedCard(id)
		vs_card:takeOver(peach)
		return vs_card
	end,
}
Msuyuan = sgs.CreateTriggerSkill{
	name = "Msuyuan",
	limit_mark = "@suyuan_use",
	frequency = sgs.Skill_Limited,
	events = {sgs.GeneralShown, sgs.EventPhaseStart},
	relate_to_place = "head",
	can_preshow = true,
	can_trigger = function(self, event, room, player, data)
		if player and player:isAlive() and player:hasSkill(self:objectName()) then
			if event == sgs.GeneralShown then
				if data:toBool() and player:getMark("suyuan_show") == 0 then
					room:setPlayerMark(player, "suyuan_show", 1)
					room:broadcastSkillInvoke(self:objectName(), 4)
					room:loseMaxHp(player)
				end
			else
				if player:getPhase() == sgs.Player_Start and player:isKongcheng() and player:getMark("@suyuan_use") == 1 then
					local targets = sgs.SPlayerList()
					for _,p in sgs.qlist(room:getOtherPlayers(player)) do
						if p:hasShownOneGeneral() and player:inMyAttackRange(p) and not (player:isFriendWith(p) or player:willBeFriendWith(p)) then
							targets:append(p)
						end
					end
					if not targets:isEmpty() then
						return self:objectName()
					end
				end
			end
		end
		return ""
	end,
	on_cost = function(self,event,room,player,data)
		if player:askForSkillInvoke(self:objectName(), data) then
			room:setPlayerMark(player, "@suyuan_use", 0)
			room:broadcastSkillInvoke(self:objectName(), 1)
			room:doSuperLightbox("Mcelestial", self:objectName())
			return true
		end
		return false
	end,
	on_effect = function(self,event,room,player,data)
		local targets = sgs.SPlayerList()
		for _,p in sgs.qlist(room:getOtherPlayers(player)) do
			if p:hasShownOneGeneral() and player:inMyAttackRange(p) and not (player:isFriendWith(p) or player:willBeFriendWith(p)) then
				targets:append(p)
			end
		end
		if not targets:isEmpty() then
			local target = room:askForPlayerChosen(player, targets, self:objectName())
			local hp1 = player:getHp()
			local mhp1 = player:getMaxHp()
			local hp2 = target:getHp()
			local mhp2 = target:getMaxHp()
			room:setPlayerProperty(player, "hp", sgs.QVariant(hp2))
			room:setPlayerProperty(target, "hp", sgs.QVariant(hp1))
			room:setPlayerProperty(player, "maxhp", sgs.QVariant(mhp2))
			room:setPlayerProperty(target, "maxhp", sgs.QVariant(mhp1))
			room:notifySkillInvoked(player, self:objectName())
			room:notifySkillInvoked(target, self:objectName())
			local log = sgs.LogMessage()
			    log.type = "#suyuan"
				log.from = player
				log.to:append(target)
				log.arg = self:objectName()
			room:sendLog(log)
			if player:hasSkill("Mshenpan") then
				if player:hasSkill("Mlianmin") then
					choice = room:askForChoice(player, self:objectName(), "lose_shenpan+lose_lianmin", data)
				else
					choice = "lose_shenpan"
				end
			else
				if player:hasSkill("Mlianmin") then
					choice = "lose_lianmin"
				end
			end
			if choice == "lose_shenpan" then
				room:handleAcquireDetachSkills(player, "-Mshenpan")
				room:broadcastSkillInvoke(self:objectName(), 2)
			elseif choice == "lose_lianmin" then
				room:handleAcquireDetachSkills(player, "-Mlianmin")
				room:broadcastSkillInvoke(self:objectName(), 3)
			end
		end
		return false
	end,
}
Msuyuan_max = sgs.CreateMaxCardsSkill{
	name = "#Msuyuan_max",
	extra_func = function(self,player)
		if player:hasSkill("Msuyuan") and player:hasShownSkill(Msuyuan) then
			return 1
		end
	end,
}
--加入技能“审判”“怜悯”“夙愿”
Mcelestial:addSkill(Mshenpan)
Mcelestial:addSkill(Mlianmin)
Mcelestial:addSkill(Msuyuan)
Mcelestial:addSkill(Msuyuan_max)
Ashan1:insertRelatedSkills("Msuyuan", "#Msuyuan_max")
--翻译表
sgs.LoadTranslationTable{
    ["Mcelestial"] = "昊天使",
	["&Mcelestial"] = "昊天使",
	["#Mcelestial"] = "审判之刃",
	["Mshenpan"] = "审判",
	["$Mshenpan"] = "你的葬身之地，将成为秘密。",
	[":Mshenpan"] = "锁定技，摸牌阶段，你须放弃摸牌，改为获得其他角色各一张手牌：若你以此法获得大于三张牌，你失去1点体力；若你以此法没有获得牌，你摸两张牌。",
	["Mlianmin"] = "怜悯",
	["$Mlianmin"] = "恢复。",
	[":Mlianmin"] = "锁定技，你的梅花手牌均视为【桃】。",
	["Msuyuan"] = "夙愿",
	["#Msuyuan_max"] = "夙愿",
	["$Msuyuan1"] = "圣堂的秘密，需要我的守护。",
	["$Msuyuan2"] = "我的无知又少了一分。",
	["$Msuyuan3"] = "以我的荣誉为名，这次绝无闪失！",
	["$Msuyuan4"] = "除了性命，我无以效忠！",
	["#suyuan"] = "由于 %arg 的效果，%from 与 %to 的血牌互相交换！",
	["@suyuan_use"] = "夙愿使用",
	["lose_shenpan"] = "失去审判",
	["lose_lianmin"] = "失去怜悯",
	[":Msuyuan"] = "主将技，锁定技，当你第一次明置此武将牌时，你的体力上限-1。主将技，锁定技，你的手牌上限+1。主将技，限定技，准备阶段开始时，若你没有手牌，你可以与一名你攻击范围内不同势力的其他角色交换血牌，然后你选择失去技能“审判”或“怜悯”。",
	["~Mcelestial"] = "没了我，谁来守护圣堂？",
	["cv:Mcelestial"] = "圣堂刺客",
	["illustrator:Mcelestial"] = "英雄无敌6",
	["designer:Mcelestial"] = "月兔君",
}

--[[
   创建武将【米迦勒】
]]--
Mmichael = sgs.General(Ashan1, "Mmichael", "ying", 4)
--[[
*【圣言】摸牌阶段开始前，你可以弃置一张装备牌进行一次判定：若结果为红色，你可以令一名与你相同势力的角色回复1点体力或摸两张牌；若结果为梅花，你弃置一名其他角色区域内一张牌；若结果为黑桃，你跳过摸牌阶段。
*【黎明】主将技，锁定技，与你势力相同的其他角色死亡后，若此时场上没有与你势力相同的角色且你未进入黎明状态，你（无视特殊模式带来的死亡惩罚）回复体力至上限，摸3张牌，获得技能“英姿”“光速”“冲锋”，然后你获得7枚“黎明”标记，进入“黎明”状态：“黎明”状态下，结束阶段结束时，你须移除1枚“黎明”标记，否则你失去当前体力。
*【光耀】副将技，与你势力相同的其他角色进入濒死状态时，若其有手牌，你可以令其选择一项：1.让你获得其全部手牌；2.让你摸一张牌。
]]--
Mshengyan = sgs.CreateTriggerSkill{
    name = "Mshengyan",
    events = {sgs.EventPhaseChanging},
    frequency = sgs.Skill_NotFrequent,
	can_preshow = true,
	can_trigger = function(self, event, room, player, data)
		if player and player:isAlive() and player:hasSkill(self:objectName()) then
			local change = data:toPhaseChange()
			if change.to == sgs.Player_Draw and not player:isSkipped(sgs.Player_Draw) then
				local equip
				for _, card in sgs.qlist(player:getCards("he")) do
					if card:isKindOf("EquipCard") then
						equip = card
						break
					end
				end
				if equip then
					return self:objectName()
				end
			end
		end
		return ""
	end,
	on_cost = function(self,event,room,player,data)
		if room:askForCard(player, "EquipCard", "@shengyan_invoke", data, sgs.Card_MethodDiscard) then
			room:broadcastSkillInvoke(self:objectName(), 1)
			return true
		end
		return false
	end,
	on_effect = function(self,event,room,player,data)
		local judge = sgs.JudgeStruct()
			judge.who = player
			judge.pattern = ".|spade|."
			judge.good = false
			judge.reason = self:objectName()
			judge.play_animation = true
			judge.negative = true
		room:judge(judge)
		if judge.card:isRed() then
			local targets = sgs.SPlayerList()
			for _,p in sgs.qlist(room:getAlivePlayers()) do
				if p:hasShownOneGeneral() and player:isFriendWith(p) then
					targets:append(p)
				end
			end
			if not targets:isEmpty() then
				local target = room:askForPlayerChosen(player, targets, "Mshengyan_red")
				if target:isWounded() then
					local ai_data = sgs.QVariant()
					ai_data:setValue(target)
					choice = room:askForChoice(player, self:objectName(), "sy_recover+sy_draw", ai_data)
    			else
	    			choice = "sy_draw"
		    	end
			    if choice == "sy_recover" then
					room:broadcastSkillInvoke(self:objectName(), 2)
					local recover = sgs.RecoverStruct()
						recover.who = player
					room:recover(target, recover)
					room:notifySkillInvoked(player, self:objectName())
    			else
		    		room:broadcastSkillInvoke(self:objectName(), 3)
					target:drawCards(2)
			    end
			end
		elseif judge.card:getSuit() == sgs.Card_Club then
			local targets = sgs.SPlayerList()
			for _,p in sgs.qlist(room:getOtherPlayers(player)) do
				if not p:isAllNude() then
					targets:append(p)
				end
			end
			if not targets:isEmpty() then
				local target = room:askForPlayerChosen(player, targets, "Mshengyan_club")
				local id = room:askForCardChosen(player, target, "hej", self:objectName())
				room:broadcastSkillInvoke(self:objectName(), 4)
				room:throwCard(id, target, player)
			end
	    elseif judge.card:getSuit() == sgs.Card_Spade then
			room:broadcastSkillInvoke(self:objectName(), 5)
			player:skip(sgs.Player_Draw)
		end
		return false
	end,
}
Mguangyao = sgs.CreateTriggerSkill{
	name = "Mguangyao",  
	frequency = sgs.Skill_NotFrequent,
	events = {sgs.Dying},
	relate_to_place = "deputy",
	can_preshow = true,
	can_trigger = function(self, event, room, player, data)
		if player and player:isAlive() and player:hasSkill(self:objectName()) then
			local dying = data:toDying()
			if not dying.who:hasShownOneGeneral() then return "" end
			if (player:isFriendWith(dying.who) or player:willBeFriendWith(dying.who)) and player:objectName() ~= dying.who:objectName() and not dying.who:isKongcheng() then
				return self:objectName()
			end
		end
		return ""
	end,
	on_cost = function(self,event,room,player,data)
		if room:askForSkillInvoke(player, self:objectName(), data) then
			room:broadcastSkillInvoke(self:objectName(), 1)
			return true
		end
		return false
	end,
	on_effect = function(self,event,room,player,data)
		local dying = data:toDying()
		choice = room:askForChoice(dying.who, self:objectName(), "gy_hand+gy_draw", data)
		if choice == "gy_hand" then
			room:broadcastSkillInvoke(self:objectName(), 2)
			local emptycard = MemptyCard:clone()
			for _, card in sgs.qlist(dying.who:getHandcards()) do
				emptycard:addSubcard(card)
			end
			if emptycard:subcardsLength() > 0 then
				player:obtainCard(emptycard, false)
			end
		else
			room:broadcastSkillInvoke(self:objectName(), 3)
			player:drawCards(1)
		end
		return false
	end,
}
Mliming = sgs.CreateTriggerSkill{
	name = "Mliming",  
	frequency = sgs.Skill_Compulsory,
	events = {sgs.Death},
	relate_to_place = "head",
	can_preshow = true,
	can_trigger = function(self, event, room, player, data)
		if player and player:isAlive() and player:hasSkill(self:objectName()) and player:getMark("liming") == 0 then
			local death = data:toDeath()
			if death.who:objectName() ~= player:objectName() and death.who:hasShownOneGeneral() and (player:isFriendWith(death.who) or player:willBeFriendWith(death.who)) then
				local alone = true
				for _,p in sgs.qlist(room:getOtherPlayers(player)) do
					if p:hasShownOneGeneral() and player:isFriendWith(p) and p:objectName() ~= death.who:objectName() then
						alone = false
						break
					end
				end
				if alone then
					return self:objectName()
				end
			end
		end
		return ""
	end,
	on_cost = function(self,event,room,player,data)
		if player:hasShownSkill(self) or player:askForSkillInvoke(self:objectName(), data) then
			room:setPlayerMark(player, "liming", 1)
			room:broadcastSkillInvoke(self:objectName(), 1)
			room:doSuperLightbox("Mmichael", self:objectName())
			return true
		end
		return false
	end,
	on_effect = function(self,event,room,player,data)
		local x = player:getMaxHp() - player:getHp()
		local recover = sgs.RecoverStruct()
			recover.recover = x
		room:recover(player, recover)
		player:drawCards(3)
		if not player:hasSkill("yingzi") then
			room:handleAcquireDetachSkills(player, "yingzi")
		end
		if not player:hasSkill("Mguangsu") then
			room:handleAcquireDetachSkills(player, "Mguangsu")
		end
		if not player:hasSkill("Mchongfeng") then
			room:handleAcquireDetachSkills(player, "Mchongfeng")
		end
		player:gainMark("@liming", 7)
	end,
}
Mliming_effect = sgs.CreateTriggerSkill{
	name = "#Mliming_effect",  
	frequency = sgs.Skill_Compulsory,
	events = {sgs.EventPhaseEnd},
	can_trigger = function(self, event, room, player, data)
		if player and player:isAlive() then
			if player:getPhase() == sgs.Player_Finish and player:getMark("liming") == 1 then
				return self:objectName()
			end
		end
		return ""
	end,
	on_cost = function(self,event,room,player,data)
		room:notifySkillInvoked(player, self:objectName())
		return true
	end,
	on_effect = function(self,event,room,player,data)
		if player:getMark("@liming") > 0 then
			player:loseMark("@liming", 1)
			if player:getMark("@liming") < 4 then
				room:broadcastSkillInvoke("Mliming", 2)
			end
		else
			room:broadcastSkillInvoke("Mliming", 3)
			room:doLightbox("$limingdeath", 2000)
			room:loseHp(player, player:getHp())
		end
		return false
	end,
}
--加入技能“圣言”“光耀”“黎明”
Mmichael:addSkill(Mshengyan)
Mmichael:addSkill(Mguangyao)
Mmichael:addSkill(Mliming)
Mmichael:addSkill(Mliming_effect)
Ashan1:insertRelatedSkills("Mliming", "#Mliming_effect")
--翻译表
sgs.LoadTranslationTable{
    ["Mmichael"] = "米迦勒",
	["&Mmichael"] = "米迦勒",
	["#Mmichael"] = "至高天使",
	["Mshengyan"] = "圣言",
	["Mshengyan_red"] = "恩赐圣言",
	["Mshengyan_club"] = "惩戒圣言",
	["Mshengyan_club"] = "惩戒圣言",
	["$Mshengyan1"] = "没有人能够逃避审判。",
	["$Mshengyan2"] = "接受洗礼。",
	["$Mshengyan3"] = "无上守护。",
	["$Mshengyan4"] = "你罪孽深重。",
	["$Mshengyan5"] = "全能之神，别注视我！",
	["@shengyan_invoke"] = "是否弃置一张装备牌发动技能“圣言”？",
	["sy_recover"] = "回复",
	["sy_draw"] = "摸牌",
	[":Mshengyan"] = "摸牌阶段开始前，你可以弃置一张装备牌进行一次判定：若结果为红色，你可以令一名与你相同势力的角色回复1点体力或摸两张牌；若结果为梅花，你弃置一名其他角色区域内一张牌；若结果为黑桃，你跳过摸牌阶段。",
	["Mguangyao"] = "光耀",
	["$Mguangyao1"] = "你将无所畏惧。",
	["$Mguangyao2"] = "无处不在。",
	["$Mguangyao3"] = "未雨绸缪。",
	["gy_hand"] = "交给其手牌",
	["gy_draw"] = "其摸一张牌",
	[":Mguangyao"] = "副将技，与你势力相同的其他角色进入濒死状态时，若其有手牌，你可以令其选择一项：1.让你获得其全部手牌；2.让你摸一张牌。",
	["Mliming"] = "黎明",
	["#Mliming_effect"] = "黎明",
	["$Mliming1"] = "噢，全知的神，请看着我！",
	["$Mliming2"] = "我被完全压制了！",
	["$Mliming3"] = "我们失败了！",
	["$Mliming4"] = "全知的神会保佑大家。",
	["$limingdeath"] = "我们失败了",
	["@liming"] = "黎明",
	[":Mliming"] = "主将技，锁定技，与你势力相同的其他角色死亡后，若此时场上没有与你势力相同的角色且你未进入黎明状态，你（无视特殊模式带来的死亡惩罚）回复体力至上限，摸3张牌，获得技能“英姿”“光速”“冲锋”，然后你获得7枚“黎明”标记，进入“黎明”状态：“黎明”状态下，结束阶段结束时，你须移除1枚“黎明”标记，否则你失去当前体力。",
	["~Mmichael"] = "这就是死亡。",
	["cv:Mmichael"] = "全能骑士",
	["illustrator:Mmichael"] = "英雄无敌6",
	["designer:Mmichael"] = "月兔君",
}

--[[
   创建武将【艾尔拉思】
]]--
Melrath = sgs.General(Ashan1, "Melrath", "ying", 4)
lord_Melrath = sgs.General(Ashan1, "lord_Melrath$", "ying", 4, true, true)
--非君主时珠联璧合：米迦勒
Melrath:addCompanion("Mmichael")
--[[
*【辉耀】君主技，锁定技，你拥有“圣光之眼”。
“圣光之眼”锁定技，当你攻击范围内体力小于你的相同势力的角色对其他势力角色造成/受到其他势力角色造成的一次伤害时，你令该伤害+1/-1。
*【正义】当其他势力的角色造成一次伤害后，若其拥有的牌数不小于受到伤害的角色，你可以令其/受伤害的角色弃置/摸X张牌（X为你已损失体力且最大为2）。
]]--
Mhuiyao = sgs.CreateTriggerSkill{
	name = "Mhuiyao$",
	frequency = sgs.Skill_Compulsory,
	events={sgs.ConfirmDamage, sgs.DamageInflicted},
	can_preshow = false,
	can_trigger = function(self, event, room, player, data)
		if player and player:isAlive() and player:hasShownOneGeneral() then
			local elrath
			for _,p in sgs.qlist(room:getOtherPlayers(player)) do
				if player:isFriendWith(p) and p:hasSkill(self:objectName()) and p:getRole() ~= "careerist" then
					elrath = p
					break
				end
			end
			if elrath and elrath:hasShownSkill(self) and player:getHp() < elrath:getHp() and elrath:inMyAttackRange(player) then
				local damage = data:toDamage()
				if event == sgs.ConfirmDamage then
					if damage.to and damage.to:hasShownOneGeneral() and not player:isFriendWith(damage.to) then
						return self:objectName(), elrath
					end
				else
					if damage.from and damage.from:hasShownOneGeneral() and not player:isFriendWith(damage.from) then
						return self:objectName(), elrath
					end
				end
			end
		end
		return ""
	end,
	on_cost = function(self,event,room,player,data)
		return true
	end,
	on_effect = function(self,event,room,player,data)
		local damage = data:toDamage()
		if event == sgs.ConfirmDamage then
			local log = sgs.LogMessage()
				log.type = "#DamageMore"
				log.from = player
				log.arg = self:objectName()
			room:sendLog(log)
			room:notifySkillInvoked(player, self:objectName())
			damage.damage = damage.damage + 1
			data:setValue(damage)
		else
			local log = sgs.LogMessage()
	            log.type = "#DamageLess"
				log.from = damage.from
				log.arg = self:objectName()
			room:sendLog(log)
			if damage.damage > 1 then
				room:broadcastSkillInvoke(self:objectName(), 2)
				damage.damage = damage.damage - 1
				data:setValue(damage)
				room:notifySkillInvoked(player, self:objectName())
			else
				room:broadcastSkillInvoke(self:objectName(), 2)
				room:notifySkillInvoked(player, self:objectName())
				return true
			end
		end
	end,
}
Mzhengyi = sgs.CreateTriggerSkill{
	name = "Mzhengyi",
	frequency = sgs.Skill_NotFrequent, 
	events = {sgs.Damage},
	can_preshow = true,
	can_trigger = function(self, event, room, player, data)
		if not player:hasShownOneGeneral() then return "" end
		local elrath =  room:findPlayerBySkillName(self:objectName())
		if elrath and elrath:isAlive() and elrath:isWounded() then
			local damage = data:toDamage()
			if damage.to:isAlive() and (player:getHandcardNum()+player:getEquips():length()) >= (damage.to:getHandcardNum()+damage.to:getEquips():length()) and not (elrath:isFriendWith(player) or elrath:willBeFriendWith(player)) then
				return self:objectName(), elrath
			end
		end
		return ""
	end,
	on_cost = function(self,event,room,player,data)
		local elrath =  room:findPlayerBySkillName(self:objectName())
		if room:askForSkillInvoke(elrath, self:objectName(), data) then
			return true
		end
		return false
	end,
	on_effect = function(self,event,room,player,data)
		local damage = data:toDamage()
		local elrath =  room:findPlayerBySkillName(self:objectName())
		local x = elrath:getLostHp()
		x = math.min(x, 2)
		if x == 1 then
			room:broadcastSkillInvoke(self:objectName(), 1)
		else
			room:broadcastSkillInvoke(self:objectName(), 2)
		end
		local y = player:getHandcardNum() + player:getEquips():length()
		if x >= y then
			player:throwAllHandCardsAndEquips()
		else
			room:askForDiscard(player, self:objectName(), x, x, false, true)
		end
		damage.to:drawCards(x)
	end,
}
--武将加入技能“正义”“辉耀”
Melrath:addSkill(Mzhengyi)
lord_Melrath:addSkill(Mzhengyi)
lord_Melrath:addSkill(Mhuiyao)
--武将注释
sgs.LoadTranslationTable{
    ["Melrath"] = "艾尔拉思",
	["&Melrath"] = "艾尔拉思",
	["#Melrath"] = "光明之龙",
	["lord_Melrath"] = "艾尔拉思",
	["&lord_Melrath"] = "艾尔拉思",
	["#lord_Melrath"] = "光明之龙",
	["Mhuiyao"] = "辉耀",
	["$Mhuiyao1"] = "封印你的命运。",
	["$Mhuiyao2"] = "我履行了我的承诺。",
	["#DamageLess"] = "由于 %arg 的效果，%from 造成的伤害-1。",
	[":Mhuiyao"] = "君主技，锁定技，你拥有“圣光之眼”。\n\n“圣光之眼”\n锁定技，当你攻击范围内体力小于你的相同势力的角色对其他势力角色造成/受到其他势力角色造成的一次伤害时，你令该伤害+1/-1。",
	["Mzhengyi"] = "正义",
	["$Mzhengyi1"] = "正如我所预见的！",
	["$Mzhengyi2"] = "结局早已注定。",
	[":Mzhengyi"] = "当其他势力的角色造成一次伤害后，若其拥有的牌数不小于受到伤害的角色，你可以令其/受伤害的角色弃置/摸X张牌（X为你已损失体力且最大为2）。",
	["~Melrath"] = "一个时代的结束！",
	["cv:Melrath"] = "虚空假面",
	["illustrator:Melrath"] = "英雄无敌6",
	["designer:Melrath"] = "月兔君",
	["cv:lord_Melrath"] = "虚空假面",
	["illustrator:lord_Melrath"] = "英雄无敌6",
	["designer:lord_Melrath"] = "月兔君",
}


--[[******************
    创建种族【据点】
]]--******************

--[[
   创建武将【碎击兵】
]]--
Mcrusher = sgs.General(Ashan1, "Mcrusher", "ying", 4)
--[[
【饮血】锁定技，你的回合外，当你受到1点伤害时，你获得1枚“饮血”标记；出牌阶段，你使用【杀】造成的第一次伤害+X（X为当前“饮血”标记数且最大为3）；结束阶段开始时，你移除所有“饮血”标记。
*【蹈锋】副将技，当你造成一次伤害后，若该伤害大于1点：若你已受伤，你可以回复1点体力；否则你可以摸一张牌。
*【强攻】主将技，出牌阶段限一次，当你使用的【杀】被【闪】抵消后，若你已受伤，你可以进行一次判定：若为红色，你视为对该角色使用了一张【雷杀】。
]]--
Myinxue = sgs.CreateTriggerSkill{
	name = "Myinxue",  
	frequency = sgs.Skill_Compulsory,
	events = {sgs.Damaged, sgs.EventPhaseStart, sgs.ConfirmDamage},
	can_preshow = true,
	can_trigger = function(self, event, room, player, data)
		if player and player:isAlive() and player:hasSkill(self:objectName()) then
			if event == sgs.Damaged then
				if player:getPhase() == sgs.Player_NotActive then
					return self:objectName()
				end
			elseif event == sgs.EventPhaseStart then
				if player:getPhase() == sgs.Player_Finish and player:getMark("@yinxue") > 0 then
					return self:objectName()
				end
			else
				local damage = data:toDamage()
				if damage.card and damage.card:isKindOf("Slash") then
					if player:getPhase() == sgs.Player_Play and not player:hasFlag("yinxue") and player:getMark("@yinxue") > 0 then
						return self:objectName()
					end
				end
			end
		end
		return ""
	end,
	on_cost = function(self,event,room,player,data)
		if player:hasShownSkill(self) or player:askForSkillInvoke(self:objectName(), data) then
			room:notifySkillInvoked(player, self:objectName())
			if event == sgs.Damaged then
				room:broadcastSkillInvoke(self:objectName(), 1)
			elseif event == sgs.EventPhaseStart then
				if not player:hasFlag("yinxue") then
					room:broadcastSkillInvoke(self:objectName(), 3)
				end
			else
				room:broadcastSkillInvoke(self:objectName(), 2)
			end
			return true
		end
		return false
	end,
	on_effect = function(self,event,room,player,data)
		if event == sgs.Damaged then
			local damage = data:toDamage()
			player:gainMark("@yinxue", damage.damage)
		elseif event == sgs.EventPhaseStart then
			player:loseAllMarks("@yinxue")
		else
			local damage = data:toDamage()
			room:setPlayerFlag(player, "yinxue")
			local x = player:getMark("@yinxue")
			x = math.min(3, x)
			local log = sgs.LogMessage()
				log.type = "#yinxue"
				log.from = player
				log.arg = x
				log.arg2 = self:objectName()
			room:sendLog(log)
			damage.damage = damage.damage + x
			data:setValue(damage)
		end
	end,
}
Mdaofeng = sgs.CreateTriggerSkill{
	name = "Mdaofeng",  
	frequency = sgs.Skill_NotFrequent, 
	events = {sgs.Damage},
	relate_to_place = "deputy",
	can_preshow = true,
	can_trigger = function(self, event, room, player, data)
		if player and player:isAlive() and player:hasSkill(self:objectName()) then
			local damage = data:toDamage()
			if damage.damage > 1 then
				return self:objectName()
			end
		end
		return ""
	end,
	on_cost = function(self,event,room,player,data)
		if player:askForSkillInvoke(self:objectName(), data) then
			if player:isWounded() then
				room:broadcastSkillInvoke(self:objectName(), 2)
			else
				room:broadcastSkillInvoke(self:objectName(), 1)
			end
			return true
		end
		return false
	end,
	on_effect = function(self,event,room,player,data)
		if player:isWounded() then
			local recover = sgs.RecoverStruct()
				recover.who = player
				recover.recover = 1
			room:recover(player, recover)
			room:notifySkillInvoked(player, self:objectName())
		else
			player:drawCards(1)
		end
	end,
}
Mqianggong = sgs.CreateTriggerSkill{
	name = "Mqianggong",
	frequency = sgs.Skill_NotFrequent,
	events = {sgs.SlashMissed},
	relate_to_place = "head",
	can_preshow = true,
	can_trigger = function(self, event, room, player, data)
		if player and player:isAlive() and player:hasSkill(self:objectName()) then
			if player:getPhase() == sgs.Player_Play and player:isWounded() and not player:hasFlag("qianggong") then
				return self:objectName()
			end
		end
		return ""
	end,
	on_cost = function(self,event,room,player,data)
		if player:askForSkillInvoke(self:objectName(), data) then
			room:setPlayerFlag(player, "qianggong")
			return true
		end
		return false
	end,
	on_effect = function(self,event,room,player,data)
		local effect = data:toSlashEffect()
		local judge = sgs.JudgeStruct()
		    judge.pattern = ".|red|."
			judge.good = true
			judge.reason = self:objectName()
			judge.who = player
			judge.play_animation = true
			judge.negative = false
		room:judge(judge)
		local slash = sgs.Sanguosha:cloneCard("thunder_slash")
		slash:setSkillName(self:objectName())
		if judge:isGood() and player:canSlash(effect.to,slash,false) then
			room:broadcastSkillInvoke(self:objectName(), 1)
			local use = sgs.CardUseStruct()
				use.from = player
				use.to:append(effect.to)
				use.card = slash
			room:useCard(use, false)
		else
			room:broadcastSkillInvoke(self:objectName(), 2)
		end
	end,
}
--加入技能“饮血”“蹈锋”“强攻”
Mcrusher:addSkill(Myinxue)
Mcrusher:addSkill(Mdaofeng)
Mcrusher:addSkill(Mqianggong)
--翻译表
sgs.LoadTranslationTable{
    ["Mcrusher"] = "碎击兵",
	["&Mcrusher"] = "碎击兵",
	["#Mcrusher"] = "蹈锋饮血",
	["Myinxue"] = "饮血",
	["$Myinxue1"] = "（忍痛声）",
	["$Myinxue2"] = "你的血我拿下了！",
	["$Myinxue3"] = "（愤愤声）",
	["@yinxue"] = "饮血",
	["#yinxue"] = "由于 %arg2 的效果，%from 造成的伤害+ %arg 。",
	[":Myinxue"] = "锁定技，你的回合外，当你受到1点伤害时，你获得1枚“饮血”标记；出牌阶段，你使用【杀】造成的第一次伤害+X（X为当前“饮血”标记数且最大为3）；结束阶段开始时，你移除所有“饮血”标记。",
	["Mdaofeng"] = "蹈锋",
	["$Mdaofeng1"] = "袭击他们。",
	["$Mdaofeng2"] = "擦亮獠牙。",
	[":Mdaofeng"] = "副将技，当你造成一次伤害后，若该伤害大于1点：若你已受伤，你可以回复1点体力；否则你可以摸一张牌。",
	["Mqianggong"] = "强攻",
	["$Mqianggong1"] = "撕裂和猛击，加倍的！",
	["$Mqianggong2"] = "我应该更凶猛些。",
	[":Mqianggong"] = "主将技，出牌阶段限一次，当你使用的【杀】被【闪】抵消后，你可以进行一次判定：若为红色，你视为对该角色使用了一张【雷杀】。",
	["~Mcrusher"] = "我最后的战斗！",
	["cv:Mcrusher"] = "熊战士",
	["illustrator:Mcrusher"] = "英雄无敌6",
	["designer:Mcrusher"] = "月兔君",
}

--[[
   创建武将【地精猎手】
]]--
Mgoblin = sgs.General(Ashan1, "Mgoblin", "ying", 4)
--[[
*【逃窜】锁定技，当其他势力的角色使用【杀】对目标角色造成一次伤害后，若你在其攻击范围内且你有手牌，你须将一张手牌置于你的武将牌上称为“匿”。锁定技，你与其他角色的距离+X（X为“匿”的数目）。锁定技，回合结束时，你将一张“匿”置入弃牌堆。
*【狡黠】副将技，锁定技，弃牌阶段结束时，若你有“匿”，你摸X张牌（X为“匿”的数目）。
*【陷阱】主将技，当其他角色指定你为【杀】或【决斗】的目标后，若你有“匿”，你可以翻开牌堆顶上的一张牌：若为红色，你获得之；若为黑色，你选择一项：1.对方失去1点体力；2.该【杀】或【决斗】对你无效。
]]--
Mtaocuan = sgs.CreateTriggerSkill{
	name = "Mtaocuan",
	frequency = sgs.Skill_Compulsory,
	events = {sgs.Damage},
	can_preshow = true,
	can_trigger = function(self, event, room, player, data)
		local damage = data:toDamage()
		if damage.card and damage.card:isKindOf("Slash") and not (damage.chain or damage.transfer) then
			local goblin =  room:findPlayerBySkillName(self:objectName())
			if goblin and goblin:isAlive() and not goblin:isKongcheng() and player:hasShownOneGeneral() and player:isAlive() and player:inMyAttackRange(goblin) and not (goblin:isFriendWith(player) or goblin:willBeFriendWith(player)) then
				return self:objectName(), goblin
			end
		end
		return ""
	end,
	on_cost = function(self,event,room,player,data)
		local goblin =  room:findPlayerBySkillName(self:objectName())
		if goblin:hasShownSkill(self) or goblin:askForSkillInvoke(self:objectName(), data) then
			room:broadcastSkillInvoke(self:objectName())
			room:notifySkillInvoked(goblin, self:objectName())
			return true
		end
		return false
	end,
	on_effect = function(self,event,room,player,data)
		local goblin =  room:findPlayerBySkillName(self:objectName())
		local id
		if goblin:getHandcardNum() == 1 then
			id = goblin:handCards():first()
		else
			id = room:askForExchange(goblin, self:objectName(), 1, 1, "taocuan_push", "", ".|.|.|hand"):getSubcards():first()
		end
		goblin:addToPile("tao", id)
	end,
}
Mtaocuan_far = sgs.CreateDistanceSkill{
	name = "#Mtaocuan_far",
	correct_func = function(self, from, to)
		if to:hasSkill("Mtaocuan") and to:hasShownSkill(Mtaocuan) and to:objectName() ~= from:objectName() then
			local x = to:getPile("tao"):length()
			if x > 0 then
			    return x
			end
		end
	end,
}
Mtaocuan_recover = sgs.CreateTriggerSkill{
	name = "#Mtaocuan_recover", 
	frequency = sgs.Skill_Compulsory, 
	events = {sgs.EventPhaseChanging},
	can_trigger = function(self, event, room, player, data)
		if player and player:isAlive() then
			local change = data:toPhaseChange()
			if change.to == sgs.Player_NotActive and player:hasSkill("Mtaocuan") then
				local taos = player:getPile("tao")
				local x = taos:length()
				if x > 0 then
					local id
					if x == 1 then
						id = taos:first()
					else
						room:fillAG(taos)
						id = room:askForAG(player, taos, false, self:objectName())
						if id then
							room:clearAG()
						end
					end
					local reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_REMOVE_FROM_PILE, player:objectName(), self:objectName(), "")
					room:throwCard(sgs.Sanguosha:getCard(id), reason, nil)
				end
			end
		end
		return ""
	end,
}
Mxianjing = sgs.CreateTriggerSkill{ 
    name = "Mxianjing",
    frequency = sgs.Skill_NotFrequent,
    events = {sgs.TargetConfirmed},
	relate_to_place = "head",
	can_preshow = true,
	can_trigger = function(self, event, room, player, data)
		if player and player:isAlive() and player:hasSkill(self:objectName()) then
			local use = data:toCardUse()
			if use.card and (use.card:isKindOf("Slash") or use.card:isKindOf("Duel")) and use.to:contains(player) then
				local taos = player:getPile("tao")
				if taos:length() > 0 then
					return self:objectName()
				end
			end
		end
		return ""
	end,
	on_cost = function(self, event, room, player, data)
		if room:askForSkillInvoke(player, self:objectName(), data) then
			return true
		end
		return false
	end,
	on_effect = function(self, event, room, player, data)
		local use = data:toCardUse()
		local card = sgs.Sanguosha:getCard(room:drawCard())
		room:moveCardTo(card, nil, nil, sgs.Player_PlaceTable,sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_TURNOVER, player:objectName(),"", self:objectName(), ""), true)
		room:getThread():delay(1000)
		if card:isRed() then
			room:broadcastSkillInvoke(self:objectName(), 1)
			player:obtainCard(card, true)
		else
			choice = room:askForChoice(player, self:objectName(), "xianjing_harm+xianjing_def", data)
			if choice == "xianjing_harm" then
				room:broadcastSkillInvoke(self:objectName(), 2)
				room:loseHp(use.from)
				room:throwCard(card, player)
			else
				room:setPlayerFlag(player, "xianjing_avoid")
				room:broadcastSkillInvoke(self:objectName(), 3)
			end
		end
	end,
}
Mxianjing_avoid = sgs.CreateTriggerSkill{
	name = "#Mxianjing_avoid",
	frequency = sgs.Skill_Compulsory,
	events = {sgs.SlashEffected, sgs.CardEffected},
	can_trigger = function(self, event, room, player, data)
		if player and player:isAlive() and player:hasSkill("Mxianjing") and player:hasFlag("xianjing_avoid") then
			if event == sgs.SlashEffected then
				local effect = data:toSlashEffect()
				if effect.slash then
					return self:objectName()
				end
			else
				local effect = data:toCardEffect()
				if effect.card and effect.card:isKindOf("Duel")then
					return self:objectName()
				end
			end
		end
		return ""
	end,
	on_cost = function(self, event, room, player, data)
		room:setPlayerFlag(player, "-xianjing_avoid")
		room:notifySkillInvoked(player, self:objectName())
		return true
	end,
	on_effect = function(self, event, room, player, data)
		if event == sgs.SlashEffected then
			local effect = data:toSlashEffect()
			local log = sgs.LogMessage()
				log.type = "#DanlaoAvoid"
				log.from = effect.to
				log.arg2 = self:objectName()
				log.arg = effect.slash:objectName()
			room:sendLog(log)
		else
			local effect = data:toCardEffect()
			local log = sgs.LogMessage()
				log.type = "#DanlaoAvoid"
				log.from = effect.to
				log.arg2 = self:objectName()
				log.arg = effect.card:objectName()
			room:sendLog(log)
		end
		return true
	end,
}
Mjiaoxia = sgs.CreateTriggerSkill{
	name = "Mjiaoxia",
	frequency = sgs.Skill_Compulsory,
	events = {sgs.EventPhaseEnd},
	relate_to_place = "deputy",
	can_preshow = true,
	can_trigger = function(self, event, room, player, data)
		if player and player:isAlive() and player:hasSkill(self:objectName()) then
			if player:getPhase() == sgs.Player_Discard then
				local taos = player:getPile("tao")
				if taos:length() > 0 then
					return self:objectName()
				end
			end
		end
		return ""
	end,
	on_cost = function(self,event,room,player,data)
		if player:hasShownSkill(self) or room:askForSkillInvoke(player, self:objectName(), data) then
			room:notifySkillInvoked(player, self:objectName())
			return true
		end
		return false
	end,
	on_effect = function(self, event, room, player, data)
		local taos = player:getPile("tao")
		local x = taos:length()
		if x > 0 then
			if x == 1 then
				room:broadcastSkillInvoke(self:objectName(), 1)
			else
				room:broadcastSkillInvoke(self:objectName(), 2)
			end
			player:drawCards(x)
		end
	end,
}
--加入技能“逃窜”“狡黠”“陷阱”
Mgoblin:addSkill(Mtaocuan)
Mgoblin:addSkill(Mtaocuan_far)
Mgoblin:addSkill(Mtaocuan_recover)
Ashan1:insertRelatedSkills("Mtaocuan", "#Mtaocuan_far")
Ashan1:insertRelatedSkills("Mtaocuan", "#Mtaocuan_recover")
Mgoblin:addSkill(Mjiaoxia)
Mgoblin:addSkill(Mxianjing)
Mgoblin:addSkill(Mxianjing_avoid)
Ashan1:insertRelatedSkills("Mxianjing", "#Mxianjing_avoid")
--翻译表
sgs.LoadTranslationTable{
    ["Mgoblin"] = "地精猎手",
	["&Mgoblin"] = "地精猎手",
	["#Mgoblin"] = "奸诈胆怯",
	["Mtaocuan"] = "逃窜",
	["#Mtaocuan_far"] = "逃窜",
	["#Mtaocuan_recover"] = "逃窜",
	["$Mtaocuan"] = "嘿，打不过他们那么多人！",
	["tao"] = "匿",
	["taocuan_push"] = "请将一手牌置于武将牌上。",
	[":Mtaocuan"] = "锁定技，当其他势力的角色使用【杀】对目标角色造成一次伤害后，若你在其攻击范围内且你有手牌，你须将一张手牌置于你的武将牌上称为“匿”。锁定技，你与其他角色的距离+X（X为“匿”的数目）。锁定技，回合结束时，你将一张“匿”置入弃牌堆。",
	["Mjiaoxia"] = "狡黠",
	["$Mjiaoxia1"] = "我一直想要这个东西~",
	["$Mjiaoxia2"] = "正是我一直想要的~",
	[":Mjiaoxia"] = "副将技，锁定技，弃牌阶段结束时，若你有“匿”，你摸X张牌（X为“匿”的数目）。",
	["Mxianjing"] = "陷阱",
	["#Mxianjing_avoid"] = "陷阱",
	["$Mxianjing1"] = "我就是这么打算的，没错~",
	["$Mxianjing2"] = "捆住你啦！",
	["$Mxianjing3"] = "你看不见我，对吧？",
	["xianjing_harm"] = "伤害陷阱",
	["xianjing_def"] = "防护陷阱",
	[":Mxianjing"] = "主将技，当其他角色指定你为【杀】或【决斗】的目标后，若你有“匿”，你可以翻开牌堆顶上的一张牌：若为红色，你获得之；若为黑色，你选择一项：1.对方失去1点体力；2.该【杀】或【决斗】对你无效。",
	["~Mgoblin"] = "本以为我能成功！",
	["cv:Mgoblin"] = "地卜师",
	["illustrator:Mgoblin"] = "英雄无敌6",
	["designer:Mgoblin"] = "月兔君",
}

--[[
   创建武将【鸢妖】
]]--
Mfury = sgs.General(Ashan1, "Mfury", "ying", 3, false)
--[[
【往返】出牌阶段开始时，你可以与一名其他角色拼点：若你赢，视为你对其使用了一张【杀】；若你没赢且你的体力小于对方，你摸一张牌。
【灵禽】锁定技，当其他角色使用【杀】指定你为目标后，需弃置一张与该【杀】相同颜色的手牌，否则此【杀】对你无效。
]]--
Mwangfan = sgs.CreateTriggerSkill{
	name = "Mwangfan", 
	frequency = sgs.Skill_NotFrequent, 
	events = {sgs.EventPhaseStart},
	can_preshow = true,
	can_trigger = function(self, event, room, player, data)
		if player and player:isAlive() and player:hasSkill(self:objectName()) then
			if player:getPhase() == sgs.Player_Play then
				if not player:isKongcheng() then
					local targets = sgs.SPlayerList()	
					for _,p in sgs.qlist(room:getOtherPlayers(player)) do
						if not p:isKongcheng() then
							targets:append(p)
						end
					end
					if not targets:isEmpty() then
						return self:objectName()
					end
				end
			end
		end
		return ""
	end,
	on_cost = function(self,event,room,player,data)
		local targets = sgs.SPlayerList()	
		for _,p in sgs.qlist(room:getOtherPlayers(player)) do
			if not p:isKongcheng() then
				targets:append(p)
			end
		end
		if not targets:isEmpty() then
			local target = room:askForPlayerChosen(player, targets, self:objectName(), "wangfan_invoke",true, true)
			if target then
				room:broadcastSkillInvoke(self:objectName(), 1)
				room:setPlayerFlag(target, "wangfan_target")
				local pd = player:pindianSelect(target, self:objectName())
				local v = sgs.QVariant()
					v:setValue(pd)
				player:setTag("wangfan_tag", v)
				return true
			end
		end
		return false
	end,
	on_effect = function(self, event, room, player, data)
		local pd = player:getTag("wangfan_tag"):toPindian()
		player:removeTag("wangfan_tag")
		local target
		for _, p in sgs.qlist(room:getOtherPlayers(player)) do
			if p:hasFlag("wangfan_target") then
				target = p
				room:setPlayerFlag(target, "-wangfan_target")
				break
			end
		end
		if target then
			local success = player:pindian(pd)
			if success then
				room:broadcastSkillInvoke(self:objectName(), 2)
				local slash = sgs.Sanguosha:cloneCard("slash")
				slash:setSkillName(self:objectName())
				if player:canSlash(target,slash,false) then
					local use = sgs.CardUseStruct()
						use.from = player
						use.to:append(target)
						use.card = slash
					room:useCard(use, false)
				end
			else
				room:broadcastSkillInvoke(self:objectName(), 3)
				if player:getHp() < target:getHp() then
					player:drawCards(1)
				end
			end
		end
	end,
}
Mlingqin = sgs.CreateTriggerSkill{
	name = "Mlingqin", 
	frequency = sgs.Skill_Compulsory, 
	events = {sgs.TargetConfirmed},
	can_preshow = true,
	can_trigger = function(self, event, room, player, data)
		if player and player:isAlive() and player:hasSkill(self:objectName()) then
			local use = data:toCardUse()
			if use.card and use.card:isKindOf("Slash") and use.to:contains(player) then
				return self:objectName()
			end
		end
		return ""
	end,
	on_cost = function(self,event,room,player,data)
		if player:hasShownSkill(self) or room:askForSkillInvoke(player, self:objectName(), data) then
			room:broadcastSkillInvoke(self:objectName())
			return true
		end
		return false
	end,
	on_effect = function(self, event, room, player, data)
		local use = data:toCardUse()
		local ai_data = sgs.QVariant()
		ai_data:setValue(player)
		if use.card:isRed() then
			if not room:askForCard(use.from, ".|red|.|hand", "@lingqin_red", ai_data, sgs.Card_MethodDiscard) then
				room:setPlayerFlag(player, "Mlingqin_avoid")
			end
		elseif use.card:isBlack() then
			if not room:askForCard(use.from, ".|black|.|hand", "@lingqin_black", ai_data, sgs.Card_MethodDiscard) then
				room:setPlayerFlag(player, "Mlingqin_avoid")
			end
		elseif use.card:getSuit() == sgs.Card_NoSuit then
			room:setPlayerFlag(player, "Mlingqin_avoid")
		end
	end,
}
Mlingqin_avoid = sgs.CreateTriggerSkill{
	name = "#Mlingqin_avoid",
	frequency = sgs.Skill_Compulsory,
	events = {sgs.SlashEffected},
	can_trigger = function(self, event, room, player, data)
		if player and player:isAlive() and player:hasSkill("Mlingqin") and player:hasShownSkill(Mlingqin) and player:hasFlag("Mlingqin_avoid") then
			return self:objectName()
		end
		return ""
	end,
	on_cost = function(self, event, room, player, data)
		room:setPlayerFlag(player, "-Mlingqin_avoid")
		room:notifySkillInvoked(player, self:objectName())
		return true
	end,
	on_effect = function(self, event, room, player, data)
		local effect = data:toSlashEffect()
		local log = sgs.LogMessage()
			log.type = "#DanlaoAvoid"
            log.from = effect.to
            log.arg2 = self:objectName()
			log.arg = effect.slash:objectName()
        room:sendLog(log)
		return true
	end,
}
--加入技能“往返”“灵禽”
Mfury:addSkill(Mwangfan)
Mfury:addSkill(Mlingqin)
Mfury:addSkill(Mlingqin_avoid)
Ashan1:insertRelatedSkills("Mlingqin", "#Mlingqin_avoid")
--翻译表
sgs.LoadTranslationTable{
    ["Mfury"] = "鸢妖",
	["&Mfury"] = "鸢妖",
	["#Mfury"] = "往来如风",
	["Mwangfan"] = "往返",
	["wangfan_invoke"] = "是否选择一名目标发动技能“往返”？",
	["$Mwangfan1"] = "毁掉他们！",
	["$Mwangfan2"] = "这是他们应得的！",
	["$Mwangfan3"] = "他们会后悔的！",
	[":Mwangfan"] = "出牌阶段开始时，你可以与一名其他角色拼点：若你赢，视为你对其使用了一张【杀】；若你没赢且你的体力小于对方，你摸一张牌。",
	["Mlingqin"] = "灵禽",
	["#Mlingqin_avoid"] = "灵禽",
	["$Mlingqin"] = "回头见~",
	["#lingqin"] = "%from 的飞行令【杀】落空！",
	["@lingqin_black"] = "请弃置一张黑色手牌否则此【杀】无效。",
	["@lingqin_red"] = "请弃置一张红色手牌否则此【杀】无效。",
	[":Mlingqin"] = "锁定技，当你被其他角色指定为【杀】的目标后，其需弃置一张与该【杀】相同颜色的手牌，否则此【杀】对你无效。",
	["~Mfury"] = "我不该死的这么早。",
	["cv:Mfury"] = "精灵龙",
	["illustrator:Mfury"] = "英雄无敌6",
	["designer:Mfury"] = "月兔君",
}
	
--[[
   创建武将【掠梦巫】
]]--
Mdream = sgs.General(Ashan1, "Mdream", "ying", 4)
--珠联璧合：鸢妖、半人马掠夺者
Mdream:addCompanion("Mfury")
Mdream:addCompanion("Mcentaur")
--[[
*【天地】其他角色使用非延时锦囊（【无懈可击】除外）时，你可以将一张相同花色的非装备牌置于你的武将牌上称为“天地”，然后使该锦囊无效；若此时你的“天地”不大于一张，你摸一张牌。你的回合外，任意非延时锦囊结算后进入弃牌堆后，你可以用一张相同颜色的“天地”替换之。
*【传承】主将技，与你相同势力的其他角色摸牌阶段开始时，其可以交给你一张手牌，若此时你的手牌数不大于体力上限，其摸一张牌，否则你须将一张手牌交给该角色。
*【梦行】副将技，锁定技，此武将牌上单独的阴阳鱼个数-1。副将技，结束阶段开始时，你可以将一张“天地”置入弃牌堆并指定一名已受伤并有手牌角色，然后选择一项：1.其回复1点体力然后弃置X张手牌；2.其摸X张牌然后失去1点体力（X为其已损失体力且至少为1）。
]]--
Mtiandi = sgs.CreateTriggerSkill{
	name = "Mtiandi",
	frequency = sgs.Skill_NotFrequent,
	events = {sgs.CardUsed, sgs.CardFinished},
	can_preshow = true,
	can_trigger = function(self, event, room, player, data)
		local use = data:toCardUse()
		if event == sgs.CardUsed then
			if use.card:isNDTrick() and not use.card:isKindOf("Nullification") then
				local dream =  room:findPlayerBySkillName(self:objectName())
				if dream and dream:isAlive() and dream:objectName() ~= player:objectName() then
					local basic
					for _,card in sgs.qlist(dream:getHandcards()) do
						if not card:isKindOf("EquipCard") and card:getSuit() == use.card:getSuit() then
							basic = card
							break
						end
					end
					if basic then
						return self:objectName(), dream
					end
				end
			end
		else
			if use.card:isNDTrick() and not use.card:isVirtualCard() and room:getCardPlace(use.card:getId()) == sgs.Player_DiscardPile then
		        local dream = room:findPlayerBySkillName(self:objectName())
				if dream and dream:isAlive() and dream:getPhase() == sgs.Player_NotActive then
				    local tiandipile = dream:getPile("tiandi")
					if tiandipile:length() > 0 then
						local tiandicard
						for _,id in sgs.qlist(tiandipile) do
						    if (sgs.Sanguosha:getCard(id):isRed() and use.card:isRed()) or (sgs.Sanguosha:getCard(id):isBlack() and use.card:isBlack()) then
							    tiandicard = id
								break
							end
						end
						if tiandicard then
							return self:objectName(), dream
						end
					end
				end
			end
		end
		return ""
	end,
	on_cost = function(self, event, room, player, data)
		local dream =  room:findPlayerBySkillName(self:objectName())
		local use = data:toCardUse()
		if event == sgs.CardUsed then
			local tiandicard
			if use.card:getSuit() == sgs.Card_Heart then
				tiandicard = room:askForCard(dream, "BasicCard,TrickCard|heart|.|hand", "@tiandi_heart", data, sgs.Card_MethodNone)
			elseif use.card:getSuit() == sgs.Card_Diamond then
				tiandicard = room:askForCard(dream, "BasicCard,TrickCard|diamond|.|hand", "@tiandi_diamond", data, sgs.Card_MethodNone)
			elseif use.card:getSuit() == sgs.Card_Spade then
				tiandicard = room:askForCard(dream, "BasicCard,TrickCard|spade|.|hand", "@tiandi_spade", data, sgs.Card_MethodNone)
			elseif use.card:getSuit() == sgs.Card_Club then
				tiandicard = room:askForCard(dream, "BasicCard,TrickCard|club|.|hand", "@tiandi_club", data, sgs.Card_MethodNone)
			end
			if tiandicard then
				dream:addToPile("tiandi", tiandicard)
				room:broadcastSkillInvoke(self:objectName(), 1)
				return true
			end
		else
			local tiandipile = dream:getPile("tiandi")
			local tiandicard
			for _,id in sgs.qlist(tiandipile) do
				if (sgs.Sanguosha:getCard(id):isRed() and use.card:isRed()) or (sgs.Sanguosha:getCard(id):isBlack() and use.card:isBlack()) then
					tiandicard = id
					break
				end
			end
			if tiandicard and room:askForSkillInvoke(dream, self:objectName(), data) then
				local reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_REMOVE_FROM_PILE, dream:objectName(), self:objectName(), "")
				room:throwCard(sgs.Sanguosha:getCard(tiandicard), reason, nil)
				room:broadcastSkillInvoke(self:objectName(), 2)
				return true
			end
		end
		return false
	end,
	on_effect = function(self, event, room, player, data)
		local dream =  room:findPlayerBySkillName(self:objectName())
		local use = data:toCardUse()
		if event == sgs.CardUsed then
			local log = sgs.LogMessage()
				log.type = "#tiandi1"
				log.from = dream
				log.arg = use.card:objectName()
			room:sendLog(log)
			room:notifySkillInvoked(dream, self:objectName())
			local tiandipile = dream:getPile("tiandi")
			if tiandipile:length() < 2 then
				dream:drawCards(1)
			end
			return true
		else
			dream:obtainCard(use.card)
			local log = sgs.LogMessage()
				log.type = "#tiandi2"
				log.from = dream
				log.arg = use.card:objectName()
			room:sendLog(log)
		end
	end,
}
Mchuancheng = sgs.CreateTriggerSkill{
	name = "Mchuancheng", 
	frequency = sgs.Skill_NotFrequent, 
	events = {sgs.EventPhaseStart},
	relate_to_place = "head",
	can_preshow = false,
	can_trigger = function(self, event, room, player, data)
		if player:getPhase() == sgs.Player_Draw and not player:isKongcheng() and player:hasShownOneGeneral() then
			local dream =  room:findPlayerBySkillName(self:objectName())
			if dream and dream:isAlive() and dream:hasShownSkill(self) and player:objectName() ~= dream:objectName() and player:isFriendWith(dream) then
				return self:objectName(), player
			end
		end
		return ""
	end,
	on_cost = function(self, event, room, player, data)
		local dream =  room:findPlayerBySkillName(self:objectName())
		local ai_data = sgs.QVariant()
		ai_data:setValue(dream)
		if room:askForSkillInvoke(player, self:objectName(), ai_data) then
			room:broadcastSkillInvoke(self:objectName(), 1)
			return true
		end
		return false
	end,
	on_effect = function(self, event, room, player, data)
		local dream =  room:findPlayerBySkillName(self:objectName())
		local card = room:askForExchange(player, self:objectName(), 1, 1, "chuancheng_give", "", ".|.|.|hand")
		dream:obtainCard(card, false)
		if dream:getHandcardNum() > dream:getMaxHp() then
			local return_card = room:askForExchange(dream, self:objectName(), 1, 1, "chuancheng_re", "", ".|.|.|hand")
			room:broadcastSkillInvoke(self:objectName(), 2)
			player:obtainCard(return_card, false)
		else
			player:drawCards(1)
		end
	end,
}
Mdream:setDeputyMaxHpAdjustedValue(-1)
Mmengxing = sgs.CreateTriggerSkill{
	name = "Mmengxing",  
	frequency = sgs.Skill_NotFrequent,
	events = {sgs.EventPhaseStart},
	relate_to_place = "deputy",
	can_preshow = true,
	can_trigger = function(self, event, room, player, data)
		if player and player:isAlive() and player:hasSkill(self:objectName()) then
			if player:getPhase() == sgs.Player_Finish then
				local tiandipile = player:getPile("tiandi")
				if tiandipile:length() > 0 then
					local targets = sgs.SPlayerList()
					for _,p in sgs.qlist(room:getAlivePlayers()) do
						if p:isWounded() and not p:isKongcheng() then
							targets:append(p)
						end
					end
					if not targets:isEmpty() then
						return self:objectName(), player
					end
				end
			end
		end
		return ""
	end,
	on_cost = function(self, event, room, player, data)
		if room:askForSkillInvoke(player, self:objectName(), data) then
			return true
		end
		return false
	end,
	on_effect = function(self, event, room, player, data)
		local tiandipile = player:getPile("tiandi")
		local targets = sgs.SPlayerList()
			for _,p in sgs.qlist(room:getAlivePlayers()) do
				if p:isWounded() and not p:isKongcheng() then
					targets:append(p)
				end
			end
		if not targets:isEmpty() then
			local id
			if tiandipile:length() == 1 then
				id = tiandipile:first()
			else
				room:fillAG(tiandipile)
				id = room:askForAG(player, tiandipile, false, self:objectName())
				if id then
					room:clearAG()
				end
			end
			local reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_REMOVE_FROM_PILE, player:objectName(), self:objectName(), "")
			room:throwCard(sgs.Sanguosha:getCard(id), reason, nil)
			local target = room:askForPlayerChosen(player, targets, self:objectName())
			choice = room:askForChoice(player, self:objectName(), "mengxing_good+mengxing_bad", data)
			if choice == "mengxing_good" then
				room:broadcastSkillInvoke(self:objectName(), 1)
				local recover = sgs.RecoverStruct()
					recover.recover = 1
					recover.who = player
				room:recover(target, recover)
				room:notifySkillInvoked(target, self:objectName())
				local x = target:getLostHp()
				if x == 0 then
					room:askForDiscard(target, self:objectName(), 1, 1, false, false)
				elseif x > 0 and x < target:getHandcardNum() then
					room:askForDiscard(target, self:objectName(), x, x, false, false)
				else
					target:throwAllHandCards()
				end
			else
	    		room:broadcastSkillInvoke(self:objectName(), 2)
				target:drawCards(target:getLostHp())
				room:loseHp(target)
			end
		end
	end,
}
--加入技能“天地”“传承”“梦行”
Mdream:addSkill(Mtiandi)
Mdream:addSkill(Mchuancheng)
Mdream:addSkill(Mmengxing)
--翻译表
sgs.LoadTranslationTable{
    ["Mdream"] = "掠梦巫",
	["&Mdream"] = "掠梦巫",
	["#Mdream"] = "亘古誓言",
	["Mtiandi"] = "天地",
	["tiandi"] = "天地",
	["$Mtiandi1"] = "大家集合！",
	["$Mtiandi2"] = "拿来给我。",
	["#tiandi1"] = "%from 使用的 %arg 被无效化了！",
	["#tiandi2"] = "%from 从弃牌堆获得了 %arg ！",
	["@tiandi_heart"] = "是否将一张红桃非装备牌置于武将牌上使当前锦囊无效？",
	["@tiandi_club"] = "是否一张梅花非装备牌置于武将牌上使当前锦囊无效？",
	["@tiandi_diamond"] = "是否一张方块非装备牌置于武将牌上使当前锦囊无效？",
	["@tiandi_spade"] = "是否一张黑桃非装备牌置于武将牌上使当前锦囊无效？",
	[":Mtiandi"] = "其他角色使用非延时锦囊（【无懈可击】除外）时，你可以将一张相同花色的非装备牌置于你的武将牌上称为“天地”，然后使该锦囊无效；若此时你的“天地”不大于一张，你摸一张牌。你的回合外，任意非延时锦囊结算后进入弃牌堆后，你可以用一张相同颜色的“天地”替换之。",
	["Mchuancheng"] = "传承",
	["$Mchuancheng1"] = "力量增强了！",
	["$Mchuancheng2"] = "正和我的心意。",
	["chuancheng_give"] = "请交给对方一张手牌。",
	["chuancheng_re"] = "请交还对方一张手牌。",
	[":Mchuancheng"] = "主将技，与你相同势力的其他角色摸牌阶段开始时，其可以交给你一张手牌，若此时你的手牌数不大于体力上限，其摸一张牌，否则你须将一张手牌交给该角色。",
	["Mmengxing"] = "梦行",
	["$Mmengxing1"] = "让你自己暖和点~",
	["$Mmengxing2"] = "诅咒你！",
	["mengxing_good"] = "美梦",
	["mengxing_bad"] = "噩梦",
	[":Mmengxing"] = "副将技，锁定技，此武将牌上单独的阴阳鱼个数-1。副将技，结束阶段开始时，你可以将一张“天地”置入弃牌堆并指定一名已受伤并有手牌角色，然后选择一项：1.其回复1点体力然后弃置X张手牌；2.其摸X张牌然后失去1点体力（X为其已损失体力且至少为1）。",
	["~Mdream"] = "你会为我超度么？",
	["cv:Mdream"] = "巫医",
	["illustrator:Mdream"] = "英雄无敌6",
	["designer:Mdream"] = "月兔君",
}

--[[
   创建武将【半人马掠夺者】
]]--
Mcentaur = sgs.General(Ashan1, "Mcentaur", "ying", 3, false)
--[[
*【警戒】其他势力的角色出牌阶段开始时，若其在你攻击范围内，你可以摸一张牌，若如此做，你须对其使用一张【杀】，否则你无法发动此技能直到你准备阶段开始。
*【规避】锁定技，当你使用【杀】对目标角色造成一次伤害后，若你的“规避”不大于三张，你摸一张牌，然后将一张手牌置于武将牌上，称为“规避”。结束阶段开始时，若你有“规避”，你可以将一张“规避”置入弃牌堆并选择一项：1.直到下回合开始，其他势力的角色与你的距离+1，你与其他势力的角色的距离-1；2.与你上家或下家交换位置。
]]--
Mjingjie = sgs.CreateTriggerSkill{
	name = "Mjingjie",
	frequency = sgs.Skill_NotFrequent,
	events = {sgs.EventPhaseStart},
	can_preshow = true,
	can_trigger = function(self, event, room, player, data)
		if player:getPhase() == sgs.Player_Play and player:hasShownOneGeneral() then
			local centaur = room:findPlayerBySkillName(self:objectName())
			if centaur and centaur:isAlive() and centaur:getMark("@jingjiefail") == 0 and player:objectName() ~= centaur:objectName() and not (centaur:isFriendWith(player) or centaur:willBeFriendWith(player)) and centaur:inMyAttackRange(player) then
				return self:objectName(), centaur
			end
		elseif player:getPhase() == sgs.Player_Start then
			if player:getMark("@jingjiefail") == 1 then
				room:setPlayerMark(player, "@jingjiefail", 0)
			end
		end
		return ""
	end,
	on_cost = function(self, event, room, player, data)
		local centaur = room:findPlayerBySkillName(self:objectName())
		local ai_data = sgs.QVariant()
		ai_data:setValue(player)
		if room:askForSkillInvoke(centaur, self:objectName(), ai_data) then
			room:broadcastSkillInvoke(self:objectName(), 1)
			return true
		end
		return false
	end,
	on_effect = function(self, event, room, player, data)
		local centaur = room:findPlayerBySkillName(self:objectName())
		centaur:drawCards(1)
		if not room:askForUseSlashTo(centaur, player, "@jingjie_slash") then
			room:broadcastSkillInvoke(self:objectName(), 2)
			local log = sgs.LogMessage()
				log.type = "#jingjie"
				log.from = centaur
			room:sendLog(log)
			room:setPlayerMark(centaur, "@jingjiefail", 1)
		end
	end,
}
Mguibi = sgs.CreateTriggerSkill{
	name = "Mguibi", 
	frequency = sgs.Skill_NotFrequent, 
	events = {sgs.Damage, sgs.EventPhaseStart},
	can_preshow = true,
	can_trigger = function(self, event, room, player, data)
		if player and player:isAlive() and player:hasSkill(self:objectName()) then
			if event == sgs.Damage then
				local damage = data:toDamage()
				if damage.card and damage.card:isKindOf("Slash") and not (damage.chain or damage.transfer) then
					if player:getPile("guibi"):length() > 3 then return "" end
					return self:objectName()
				end
			else
				if player:getPhase() == sgs.Player_Finish then
					local guibipile = player:getPile("guibi")
					if guibipile:length() > 0 then
						return self:objectName()
					end
				elseif player:getPhase() == sgs.Player_Start then
					room:setPlayerMark(player, "@guibimove", 0)
				end
			end
		end
		return ""
	end,
	on_cost = function(self, event, room, player, data)
		if event == sgs.Damage then
			if player:hasShownSkill(self) or room:askForSkillInvoke(player, self:objectName(), data) then
				room:broadcastSkillInvoke(self:objectName(), 1)
				return true
			end
		else
			if room:askForSkillInvoke(player, "Mguibi_skill", data) then
				return true
			end
		end
		return false
	end,
	on_effect = function(self, event, room, player, data)
		if event == sgs.Damage then
			player:drawCards(1)
			if not player:isKongcheng() then
				local id
				if player:getHandcardNum() == 1 then
					id = player:handCards():first()
				else
					id = room:askForExchange(player, self:objectName(), 1, 1, "guibi_push", "", ".|.|.|hand"):getSubcards():first()
				end
				player:addToPile("guibi", id)
			end
		else
			local guibipile = player:getPile("guibi")
			if player:aliveCount() > 2 then
				choice = room:askForChoice(player, self:objectName(), "guibi_a+guibi_b+guibi_c", data)
			else
				choice = "guibi_a"
			end
			if choice == "guibi_a" then
				room:broadcastSkillInvoke(self:objectName(), 2)
				local id
				if guibipile:length() == 1 then
					id = guibipile:first()
				else
					room:fillAG(guibipile)
					id = room:askForAG(player, guibipile, false, self:objectName())
					if id then
						room:clearAG()
					end
				end
				local reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_REMOVE_FROM_PILE, player:objectName(), self:objectName(), "")
				room:throwCard(sgs.Sanguosha:getCard(id), reason, nil)
				room:setPlayerMark(player, "@guibimove", 1)
				local log = sgs.LogMessage()
					log.type = "#guibi1"
					log.from = player
				room:sendLog(log)
			elseif choice == "guibi_b" then
				room:broadcastSkillInvoke(self:objectName(), 3)
				local lastp = getServerPlayer(room, player:getLastAlive():objectName())
				if lastp and lastp:isAlive() then
					room:swapSeat(player, lastp)
					local log = sgs.LogMessage()
						log.type = "#guibi2"
						log.from = player
						log.to:append(lastp)
					room:sendLog(log)
				end
			else
				room:broadcastSkillInvoke(self:objectName(), 4)
				local nextp = getServerPlayer(room, player:getNextAlive():objectName())
				if nextp and nextp:isAlive() then
					room:swapSeat(player, nextp)
					local log = sgs.LogMessage()
						log.type = "#guibi2"
						log.from = player
						log.to:append(nextp)
					room:sendLog(log)
				end
			end
		end
		return false
	end,
}
Mguibi_distance = sgs.CreateDistanceSkill{
	name = "#Mguibi_distance",
	correct_func = function(self, from, to)
		if to:getMark("@guibimove") == 1 and to:hasSkill("Mguibi") and to:hasShownSkill(Mguibi) and from:hasShownOneGeneral() and not from:isFriendWith(to) then
			return 1
		end
		if from:getMark("@guibimove") == 1 and from:hasSkill("Mguibi") and from:hasShownSkill(Mguibi) and to:hasShownOneGeneral() and not to:isFriendWith(from) then
		    return -1
		end
	end,
}
--加入技能“警戒”“规避”
Mcentaur:addSkill(Mjingjie)
Mcentaur:addSkill(Mguibi)
Mcentaur:addSkill(Mguibi_distance)
Ashan1:insertRelatedSkills("Mguibi", "#Mguibi_distance")
--翻译表
sgs.LoadTranslationTable{
    ["Mcentaur"] = "半人马掠夺者",
	["&Mcentaur"] = "半人马掠夺者",
	["#Mcentaur"] = "警戒之眼",
	["Mjingjie"] = "警戒",
	["$Mjingjie1"] = "加入战斗！",
	["$Mjingjie2"] = "我应该做的更好。",
	["@jingjie_slash"] = "请对当前回合角色使用一张【杀】。",	
	["#jingjie"] = "%from 警戒任务失败！",
	["@jingjiefail"] = "警戒失败",
	[":Mjingjie"] = "其他势力的角色出牌阶段开始时，若其在你攻击范围内，你可以摸一张牌，若如此做，你须对其使用一张【杀】，否则你无法发动此技能直到你准备阶段开始。",
	["Mguibi"] = "规避",
	["Mguibi_skill"] = "规避（技巧）",
	["$Mguibi1"] = "等待时机成熟。",
	["$Mguibi2"] = "战争，总是风云变化。",
	["$Mguibi3"] = "强攻不成，就要智取。",
	["$Mguibi4"] = "冲上前线！",
	["guibi"] = "规避",
	["@guibimove"] = "规避",	
	["#Mguibi_distance"] = "规避",
	["guibi_a"] = "游走干扰",
	["guibi_b"] = "后撤御敌",
	["guibi_c"] = "全军突进",
	["guibi_push"] = "请选择一张手牌置于武将牌上。",
	["#guibi1"] = "%from 开始奔袭！",
	["#guibi2"] = "%from 与 %to 交换了位置！",
	[":Mguibi"] = "锁定技，当你使用【杀】对目标角色造成一次伤害后，若你的“规避”不大于三张，你摸一张牌，然后将一张手牌置于武将牌上，称为“规避”。结束阶段开始时，若你有“规避”，你可以将一张“规避”置入弃牌堆并选择一项：1.直到下回合开始，其他势力的角色与你的距离+1，你与其他势力的角色的距离-1；2.与你上家或下家交换位置。",
	["~Mcentaur"] = "我……决不投降！",
	["cv:Mcentaur"] = "军团指挥官",
	["illustrator:Mcentaur"] = "英雄无敌6",
	["designer:Mcentaur"] = "月兔君",
}

--[[
   创建武将【黑豹战士】
]]--
Mpanther = sgs.General(Ashan1, "Mpanther", "ying", 4)
--珠联璧合：碎击兵
Mpanther:addCompanion("Mcrusher")
--[[
*【爪牙】当你使用的普通【杀】被【闪】抵消后，你可以摸一张牌，若如此做，你须对其再使用一张【杀】且此【杀】造成的伤害+1，否则对方弃置你一张牌。
*【狂舞】限定技，弃牌阶段开始时，若你装备区有武器和防具，你可以弃置该防具视为对攻击范围内体力不小于你的其他势力角色使用了一张【杀】。
]]--
Mzhaoya = sgs.CreateTriggerSkill{
	name = "Mzhaoya",
	frequency = sgs.Skill_NotFrequent,
	events = {sgs.SlashMissed, sgs.ConfirmDamage},
	can_preshow = true,
	can_trigger = function(self, event, room, player, data)
		if player and player:isAlive() and player:hasSkill(self:objectName()) then
			if event == sgs.SlashMissed then
				local effect = data:toSlashEffect()
				room:setPlayerFlag(player, "-zhaoya")
				return self:objectName()
			else
				local damage = data:toDamage()
				local card = damage.card
				if damage.card and damage.card:isKindOf("Slash") and not damage.card:isKindOf("NatureSlash") and not (damage.chain or damage.transfer) and player:hasFlag("zhaoya") then
					return self:objectName()
				end
			end
		end
		return ""
	end,
	on_cost = function(self, event, room, player, data)
		if event == sgs.SlashMissed then
			if room:askForSkillInvoke(player, self:objectName(), data) then
				room:broadcastSkillInvoke(self:objectName(), 1)
				room:setPlayerFlag(player, "zhaoya")
				return true
			end
		else
			if player:hasShownSkill(self) then
				room:setPlayerFlag(player, "-zhaoya")
				room:broadcastSkillInvoke(self:objectName(), 3)
				room:notifySkillInvoked(player, self:objectName())
				return true
			end
		end
		return false
	end,
	on_effect = function(self, event, room, player, data)
		if event == sgs.SlashMissed then
			local effect = data:toSlashEffect()
			player:drawCards(1)
			if not room:askForUseSlashTo(player, effect.to, "@zhaoya_slash") then
				room:broadcastSkillInvoke(self:objectName(), 2)
				room:setPlayerFlag(player, "-zhaoya")
				local id = room:askForCardChosen(effect.to, player, "he", self:objectName())
				room:throwCard(id, player, effect.to)
			end
		else
			local damage = data:toDamage()
			local log = sgs.LogMessage()
				log.type = "#DamageMore"
				log.from = player
				log.arg = self:objectName()
			room:sendLog(log)
			damage.damage = damage.damage + 1
			data:setValue(damage)
		end
		return false
	end,
}
Mkuangwu = sgs.CreateTriggerSkill{
	name = "Mkuangwu",
	limit_mark = "@kuangwu_use",
	frequency = sgs.Skill_Limited, 
	events = {sgs.EventPhaseStart},
	can_preshow = true,
	can_trigger = function(self, event, room, player, data)
		if player and player:isAlive() and player:hasSkill(self:objectName()) then
			if player:getPhase() == sgs.Player_Discard and player:getWeapon() and player:getArmor() then
				local slash = sgs.Sanguosha:cloneCard("slash")
				slash:setSkillName(self:objectName())
				local targets = sgs.SPlayerList()
				for _, p in sgs.qlist(room:getOtherPlayers(player)) do
					if p:hasShownOneGeneral() and player:inMyAttackRange(p) and not (player:isFriendWith(p) or player:willBeFriendWith(p)) and player:canSlash(p,slash,false) and player:getHp() <= p:getHp() then
						targets:append(p)
					end
				end
				if not targets:isEmpty() and player:getMark("@kuangwu_use") == 1 then
					return self:objectName()
				end
			end
		end
		return ""
	end,
	on_cost = function(self, event, room, player, data)
		if room:askForSkillInvoke(player, self:objectName(), data) then
			room:setPlayerMark(player, "@kuangwu_use", 0)
			room:throwCard(player:getArmor(), player)
			room:broadcastSkillInvoke(self:objectName())
			room:doSuperLightbox("Mpanther", self:objectName())
			return true
		end
		return false
	end,
	on_effect = function(self, event, room, player, data)
		local slash = sgs.Sanguosha:cloneCard("slash")
		slash:setSkillName(self:objectName())
		local targets = sgs.SPlayerList()
		for _, p in sgs.qlist(room:getOtherPlayers(player)) do
			if p:hasShownOneGeneral() and player:inMyAttackRange(p) and not (player:isFriendWith(p) or player:willBeFriendWith(p)) and player:canSlash(p,slash,false) and player:getHp() <= p:getHp() then
				targets:append(p)
			end
		end
		local use = sgs.CardUseStruct()
			use.from = player
			use.to = targets
			use.card = slash
		room:useCard(use, false)
	end,
}
--加入技能“爪牙”“狂舞”
Mpanther:addSkill(Mzhaoya)
Mpanther:addSkill(Mkuangwu)
--翻译表
sgs.LoadTranslationTable{
    ["Mpanther"] = "黑豹战士",
	["&Mpanther"] = "黑豹战士",
	["#Mpanther"] = "残酷旋风",
	["Mzhaoya"] = "爪牙",
	["$Mzhaoya1"] = "四分五裂！",
	["$Mzhaoya2"] = "徒劳无功。",
	["$Mzhaoya3"] = "撕碎！",
	[":Mzhaoya"] = "当你使用的普通【杀】被【闪】抵消后，你可以摸一张牌，若如此做，你须对其再使用一张【杀】且此【杀】造成的伤害+1，否则对方弃置你一张牌。",
	["@zhaoya_slash"] = "是否对目标使用一张【杀】（该【杀】伤害+1）？",
	["Mkuangwu"] = "狂舞",
	["$Mkuangwu"] = "我的利爪在你的血泊中沐浴！",
	["@kuangwu_use"] = "狂舞使用",
	[":Mkuangwu"] = "限定技，弃牌阶段开始时，若你装备区有武器和防具，你可以弃置该防具视为对攻击范围内体力不小于你的其他势力角色使用了一张【杀】。",
	["~Mpanther"] = "我命在旦夕！",
	["cv:Mpanther"] = "狼人",
	["illustrator:Mpanther"] = "英雄无敌6",
	["designer:Mpanther"] = "月兔君",
}

--[[
   创建武将【怒眼独眼】
]]--
Mcyclops = sgs.General(Ashan1, "Mcyclops", "ying", 4)
--珠联璧合：地精猎手
Mcyclops:addCompanion("Mgoblin")
--[[
【遗忘】锁定技，任意时刻你的体力降低至0或更低时，若你有手牌，你回复体力至0并跳过濒死结算。锁定技，体力为0时你的手牌上限+1。
【迟钝】锁定技，当你受到一次无属性伤害时，防止此伤害，改为在伤害来源准备阶段开始时对你造成同样点数的无属性伤害。
【兽血】当你受到一次伤害后，若你装备区不为空，你可以弃置装备区所有牌视为使用了一张【南蛮入侵】。
]]--
Myiwang = sgs.CreateTriggerSkill{
	name = "Myiwang",
	frequency = sgs.Skill_Compulsory,
	events = {sgs.PostHpReduced, sgs.CardsMoveOneTime},
	can_preshow = true,
	can_trigger = function(self, event, room, player, data)
		if player and player:isAlive() and player:hasSkill(self:objectName()) then
			if event == sgs.PostHpReduced then
				if player:getHp() <= 0 then
					return self:objectName()
				end
			else
				local move = data:toMoveOneTime()
				if move.from and move.from:objectName() == player:objectName() and player:isKongcheng() then
					if move.from_places:contains(sgs.Player_PlaceHand) and player:getHp() <= 0 then
						return self:objectName()
					end
				end
			end
		end
		return ""
	end,
	on_cost = function(self, event, room, player, data)
		if player:hasShownSkill(self) or room:askForSkillInvoke(player, self:objectName(), data) then
			room:notifySkillInvoked(player, self:objectName())
			if event == sgs.PostHpReduced then
				room:broadcastSkillInvoke(self:objectName(), 1)
				return true
			else
				room:broadcastSkillInvoke(self:objectName(), 2)
				return true
			end
		end
		return false
	end,
	on_effect = function(self, event, room, player, data)
		if event == sgs.PostHpReduced then
			if player:getHp() < 0 then
				local x = 0 - player:getHp()
				local recover = sgs.RecoverStruct()
					recover.recover = x
				room:recover(player, recover)
			end
			if not player:isKongcheng() then
				return true
			end
		else
			room:loseHp(player, 1)
		end
	end,
}
Myiwang_max = sgs.CreateMaxCardsSkill{
	name = "#Myiwang_max", 
	extra_func = function(self, target)
		if target:hasSkill("Myiwang") and target:getHp() == 0 and target:hasShownSkill(Myiwang) then
			return 1
		end
	end,
}
Mchidun = sgs.CreateTriggerSkill{
	name = "Mchidun",
	frequency = sgs.Skill_Compulsory,
	events = {sgs.DamageInflicted},
	can_preshow = true,
	can_trigger = function(self, event, room, player, data)
		if player and player:isAlive() and player:hasSkill(self:objectName()) then
			local damage = data:toDamage()
			if not damage.from or (damage.from and damage.from:getPhase() ~= sgs.Player_Start) then
				if damage.nature == sgs.DamageStruct_Normal then
					return self:objectName()
				end
			end
		end
		return ""
	end,
	on_cost = function(self, event, room, player, data)
		if player:hasShownSkill(self) or room:askForSkillInvoke(player, self:objectName(), data) then
			room:broadcastSkillInvoke(self:objectName(), 1)
			room:notifySkillInvoked(player, self:objectName())
			return true
		end
		return false
	end,
	on_effect = function(self, event, room, player, data)
		local damage = data:toDamage()
		local log = sgs.LogMessage()
			log.type = "#chidun1"
			log.from = player
		room:sendLog(log)
		if damage.from then
			local x = damage.from:getMark("@chidun")
			room:setPlayerMark(damage.from, "@chidun", damage.damage+x)
		end
		return true
	end,
}
Mchidun_effect = sgs.CreateTriggerSkill{
	name = "#Mchidun_effect",
	frequency = sgs.Skill_Compulsory,
	events = {sgs.EventPhaseStart},
	can_trigger = function(self, event, room, player, data)
		if player:getPhase() == sgs.Player_Start then
			local x = player:getMark("@chidun")
			if x > 0 then
				local cyclops = room:findPlayerBySkillName("Mchidun")
				if cyclops and cyclops:isAlive() and cyclops:hasShownSkill(Mchidun) then
					return self:objectName()
				end
			end
		end
		return ""
	end,
	on_cost = function(self, event, room, player, data)
		return true
	end,
	on_effect = function(self, event, room, player, data)
		local cyclops = room:findPlayerBySkillName("Mchidun")
		room:notifySkillInvoked(cyclops, self:objectName())
		local x = player:getMark("@chidun")
		room:setPlayerMark(player, "@chidun", 0)
		room:broadcastSkillInvoke("Mchidun", 2)
		local log = sgs.LogMessage()
			log.type = "#chidun2"
			log.from = cyclops
		room:sendLog(log)
		local damage = sgs.DamageStruct()
			damage.from = player
			damage.damage = x
			damage.to = cyclops
		room:damage(damage)
	end,
}
Mshouxue = sgs.CreateTriggerSkill{
	name = "Mshouxue", 
	frequency = sgs.Skill_NotFrequent, 
	events = {sgs.Damaged},
	can_preshow = true,
	can_trigger = function(self, event, room, player, data)
		if player and player:isAlive() and player:hasSkill(self:objectName()) then
			if player:hasEquip() then
				return self:objectName()
			end
		end
		return ""
	end,
	on_cost = function(self, event, room, player, data)
		if room:askForSkillInvoke(player, self:objectName(), data) then
			room:broadcastSkillInvoke(self:objectName())
			player:throwAllEquips()
			return true
		end
		return false
	end,
	on_effect = function(self, event, room, player, data)
		local savage = sgs.Sanguosha:cloneCard("savage_assault")
		savage:setSkillName(self:objectName())
		local use = sgs.CardUseStruct()
			use.from = player
			use.card = savage
		room:useCard(use, false)
	end,
}
--加入技能“迟钝”“遗忘”“兽血”
Mcyclops:addSkill(Myiwang)
Mcyclops:addSkill(Myiwang_max)
Ashan1:insertRelatedSkills("Myiwang", "#Myiwang_max")
Mcyclops:addSkill(Mchidun)
Mcyclops:addSkill(Mchidun_effect)
Ashan1:insertRelatedSkills("Mchidun", "#Mchidun_effect")
Mcyclops:addSkill(Mshouxue)
--翻译表
sgs.LoadTranslationTable{
    ["Mcyclops"] = "怒眼独眼",
	["&Mcyclops"] = "怒眼独眼",
	["#Mcyclops"] = "懵懂巨人",
	["Myiwang"] = "遗忘",
	["#Myiwang_max"] = "遗忘",
	["$Myiwang1"] = "我现在做了什么？",
	["$Myiwang2"] = "可悲的尝试。",
	[":Myiwang"] = "锁定技，任意时刻你的体力降低至0或更低时，你回复体力至0：若你有手牌，你跳过濒死结算。锁定技，体力为0时你的手牌上限+1。 ",
	["Mchidun"] = "迟钝",
	["#Mchidun_effect"] = "迟钝",
	["$Mchidun1"] = "你最好还是再练练。",
	["$Mchidun2"] = "噢，我骨头疼！",
	["#chidun1"] = "%from 忽视了伤势！",
	["#chidun2"] = "%from 注意到伤害！",
	["@chidun"] = "迟钝",
	[":Mchidun"] = "锁定技，当你受到一次无属性伤害时，防止此伤害，改为在伤害来源准备阶段开始时对你造成同样点数的无属性伤害。",
	["Mshouxue"] = "兽血",
	["$Mshouxue"] = "撕成碎片。",
	[":Mshouxue"] = "当你受到一次伤害后，若你装备区不为空，你可以弃置装备区所有牌视为使用了一张【南蛮入侵】。",
	["~Mcyclops"] = "回归原始……",
	["cv:Mcyclops"] = "泰坦",
	["illustrator:Mcyclops"] = "英雄无敌6",
	["designer:Mcyclops"] = "月兔君",
}

--[[
   创建武将【雷鸟】
]]--
Mthunder = sgs.General(Ashan1, "Mthunder", "ying", 4)
--[[
【雷霆】锁定技，你即将造成的不来自于锦囊的无属性伤害视为雷属性。锁定技，当你造成一次雷属性伤害后，你摸一张牌并获得1枚“雷霆”标记。
*【辉煌】副将技，当你使用锦囊对目标角色造成一次伤害后，你可以移除1枚“雷霆”标记并展示其一张手牌，然后你可以弃置一张与之相同花色的手牌，若如此做，其弃置所有该类型的手牌。
*【奔腾】主将技，锁定技，此武将牌上单独的阴阳鱼个数-1。主将技，出牌阶段结束时，你可以移除2枚“雷霆”标记并失去1点体力（若你已受伤则不失去），指定一名没有“奔腾”标记的其他势力角色获得“奔腾”标记。主将技，锁定技，拥有“奔腾”标记的角色出牌阶段结束时，视为你对其使用了一张【雷杀】。主将技，锁定技，拥有“奔腾”标记的角色对一名其他角色造成一次伤害后，移除“奔腾”标记，你摸X张牌（X为伤害点数）。
]]--
Mleiting = sgs.CreateTriggerSkill{
	name = "Mleiting",
	frequency = sgs.Skill_Compulsory,
	events = {sgs.Predamage, sgs.Damage},
	can_preshow = true,
	can_trigger = function(self, event, room, player, data)
		if player and player:isAlive() and player:hasSkill(self:objectName()) then
			local damage = data:toDamage()
			if event == sgs.Predamage then
				if not (damage.card and damage.card:isKindOf("TrickCard") or damage.nature ~= sgs.DamageStruct_Normal) then
					return self:objectName()
				end
			else
				if damage.nature == sgs.DamageStruct_Thunder then
					return self:objectName()
				end
			end
		end
		return ""
	end,
	on_cost = function(self, event, room, player, data)
		if player:hasShownSkill(self) or room:askForSkillInvoke(player, self:objectName(), data) then
			room:broadcastSkillInvoke(self:objectName())
			room:notifySkillInvoked(player, self:objectName())
			return true
		end
		return false
	end,
	on_effect = function(self, event, room, player, data)
		local damage = data:toDamage()
		if event == sgs.Predamage then
			local log = sgs.LogMessage()
				log.type = "#leiting"
				log.from = player
			room:sendLog(log)
			damage.nature = sgs.DamageStruct_Thunder
			data:setValue(damage)
		else
			player:drawCards(1)
			player:gainMark("@leiting")
		end
	end,
}
Mhuihuang = sgs.CreateTriggerSkill{
	name = "Mhuihuang",
	frequency = sgs.Skill_NotFrequent,
	events = {sgs.Damage},
	relate_to_place = "deputy",
	can_preshow = true,
	can_trigger = function(self, event, room, player, data)
		if player and player:isAlive() and player:hasSkill(self:objectName()) then
			local damage = data:toDamage()
			if damage.to:isAlive() and not damage.to:isKongcheng() and damage.card and damage.card:isKindOf("TrickCard") and not (damage.chain or damage.transfer) then
				if player:getMark("@leiting") > 0 then
					return self:objectName()
				end
			end
		end
		return ""
	end,
	on_cost = function(self, event, room, player, data)
		if room:askForSkillInvoke(player, self:objectName(), data) then
			player:loseMark("@leiting", 1)
			room:broadcastSkillInvoke(self:objectName(), 1)
			return true
		end
		return false
	end,
	on_effect = function(self, event, room, player, data)
		local damage = data:toDamage()
		local id = room:askForCardChosen(player, damage.to , "h", self:objectName())
		room:showCard(damage.to, id)
		if not player:isNude() then
			local realcard = sgs.Sanguosha:getWrappedCard(id)
			local invoke
			for _, card in sgs.qlist(player:getCards("h")) do
				if realcard:getSuit() == card:getSuit() then
					invoke = true
					break
				end
			end
			if invoke then
				if realcard:getSuit() == sgs.Card_Heart then
					if not room:askForCard(player, ".|heart|.|hand", "@huihuang_heart", data, sgs.Card_MethodDiscard) then
						invoke = false
					end
				elseif realcard:getSuit() == sgs.Card_Diamond then
					if not room:askForCard(player, ".|diamond|.|hand", "@huihuang_diamond", data, sgs.Card_MethodDiscard) then
						invoke = false
					end
				elseif realcard:getSuit() == sgs.Card_Spade then
					if not room:askForCard(player, ".|spade|.|hand", "@huihuang_spade", data, sgs.Card_MethodDiscard) then
						invoke = false
					end
				elseif realcard:getSuit() == sgs.Card_Club then
					if not room:askForCard(player, ".|club|.|hand", "@huihuang_club", data, sgs.Card_MethodDiscard) then
						invoke = false
					end
				end
				if invoke then
					if math.random() < 0.5 then
						room:broadcastSkillInvoke(self:objectName(), 2)
					else
						room:broadcastSkillInvoke(self:objectName(), 3)
					end
					local throw_cards = MemptyCard:clone()
					if realcard:isKindOf("BasicCard") then
						for _, cd in sgs.qlist(damage.to:getHandcards()) do
							if cd:isKindOf("BasicCard") then
								throw_cards:addSubcard(cd)
							end
						end
					elseif realcard:isKindOf("EquipCard") then
						for _, cd in sgs.qlist(damage.to:getHandcards()) do
							if cd:isKindOf("EquipCard") then
								throw_cards:addSubcard(cd)
							end
						end
					elseif realcard:isKindOf("TrickCard") then
						for _, cd in sgs.qlist(damage.to:getHandcards()) do
							if cd:isKindOf("TrickCard") then
								throw_cards:addSubcard(cd)
							end
						end
					end
					if throw_cards:subcardsLength() > 0 then
						room:throwCard(throw_cards, damage.to)
					end
				else
					room:broadcastSkillInvoke(self:objectName(), 4)
				end
			else
				room:broadcastSkillInvoke(self:objectName(), 4)
			end
		end
		return false
	end,
}
Mthunder:setHeadMaxHpAdjustedValue(-1)
Mbenteng = sgs.CreateTriggerSkill{
	name = "Mbenteng", 
	frequency = sgs.Skill_NotFrequent, 
	events = {sgs.EventPhaseEnd},
	relate_to_place = "head",
	can_preshow = true,
	can_trigger = function(self, event, room, player, data)
		if player and player:isAlive() and player:hasSkill(self:objectName()) then
			if player:getPhase() == sgs.Player_Play then
				if player:getMark("@leiting") > 1 then
					local invoke
					for _,p in sgs.qlist(room:getOtherPlayers(player)) do
						if p:hasShownOneGeneral() and p:getMark("@benteng") == 0 and not (player:isFriendWith(p) or player:willBeFriendWith(p)) then
							invoke = true
							break
						end
					end
					if invoke then
						return self:objectName()
					end
				end
			end
		end
		return ""
	end,
	on_cost = function(self, event, room, player, data)
		if room:askForSkillInvoke(player, self:objectName(), data) then
			player:loseMark("@leiting", 2)
			if not player:isWounded() then
				room:loseHp(player, 1)
			end
			room:broadcastSkillInvoke(self:objectName(), 1)
			return true
		end
		return false
	end,
	on_effect = function(self, event, room, player, data)
		local targets = sgs.SPlayerList()
		for _,p in sgs.qlist(room:getOtherPlayers(player)) do
			if p:hasShownOneGeneral() and p:getMark("@benteng") == 0 and not (player:isFriendWith(p) or player:willBeFriendWith(p)) then
				targets:append(p)
			end
		end
		if not targets:isEmpty() then
			local target = room:askForPlayerChosen(player, targets, self:objectName())
			room:setPlayerMark(target, "@benteng", 1)
		end
	end,
}
Mbenteng_effect = sgs.CreateTriggerSkill{
	name = "#Mbenteng_effect", 
	frequency = sgs.Skill_Compulsory, 
	events = {sgs.EventPhaseEnd, sgs.Damage},
	can_trigger = function(self, event, room, player, data)
		if player and player:isAlive() and player:getMark("@benteng") == 1 then
			if event == sgs.EventPhaseEnd then
				if player:getPhase() == sgs.Player_Play then
					local thunder = room:findPlayerBySkillName("Mbenteng")
					if thunder and thunder:isAlive() then
						local slash = sgs.Sanguosha:cloneCard("thunder_slash")
						slash:setSkillName(self:objectName())
						if thunder:canSlash(player,slash,false) then
							return self:objectName()
						end
					end
				end
			else
				local damage = data:toDamage()
				if player:objectName() ~= damage.to:objectName() then
					return self:objectName()
				end
			end
		end
		return ""
	end,
	on_cost = function(self, event, room, player, data)
		return true
	end,
	on_effect = function(self, event, room, player, data)
		local thunder = room:findPlayerBySkillName("Mbenteng")
		if event == sgs.EventPhaseEnd then
			room:broadcastSkillInvoke("Mbenteng", 2)
			room:notifySkillInvoked(thunder, self:objectName())
			local slash = sgs.Sanguosha:cloneCard("thunder_slash")
			slash:setSkillName(self:objectName())
			local use = sgs.CardUseStruct()
				use.from = thunder
				use.to:append(player)
				use.card = slash
			room:useCard(use, false)
		else
			local damage = data:toDamage()
			room:setPlayerMark(player, "@benteng", 0)
			if thunder and thunder:isAlive() then
				room:notifySkillInvoked(thunder, self:objectName())
				room:broadcastSkillInvoke("Mbenteng", 3)
				thunder:drawCards(damage.damage)
			end
		end
		return false
	end,
}
--加入技能“雷霆”“辉煌”“奔腾”
Mthunder:addSkill(Mleiting)
Mthunder:addSkill(Mhuihuang)
Mthunder:addSkill(Mbenteng)
Mthunder:addSkill(Mbenteng_effect)
Ashan1:insertRelatedSkills("Mbenteng", "#Mbenteng_effect")
--翻译表
sgs.LoadTranslationTable{
    ["Mthunder"] = "雷鸟",
	["&Mthunder"] = "雷鸟",
	["#Mthunder"] = "闪电精魂",
	["Mleiting"] = "雷霆",
	["@leiting"] = "雷霆",
	["$Mleiting"] = "你的死是给我的贡品。",
	["#leiting"] = "%from 是将普通伤害转化为雷属性！",
	[":Mleiting"] = "锁定技，你即将造成的不来自于锦囊的无属性伤害视为雷属性。锁定技，当你造成一次雷属性伤害后，你摸一张牌并获得1枚“雷霆”标记。",
	["Mhuihuang"] = "辉煌",
	["$Mhuihuang1"] = "你无可奈何。",
	["$Mhuihuang2"] = "啊，凡人。",
	["$Mhuihuang3"] = "是的，我比你神圣。",
	["$Mhuihuang4"] = "我不会要你的贡品。",
	["@huihuang_heart"] = "请弃置一张红桃牌。",
	["@huihuang_diamond"] = "请弃置一张方块牌。",
	["@huihuang_spade"] = "请弃置一张黑桃牌。",
	["@huihuang_club"] = "请弃置一张红心牌。",
	[":Mhuihuang"] = "副将技，当你使用锦囊对目标角色造成一次伤害后，你可以移除1枚“雷霆”标记并展示其一张手牌，然后你可以弃置一张与之相同花色的牌，若如此做，其弃置所有该类型的手牌。",
	["Mbenteng"] = "奔腾",
	["#Mbenteng_effect"] = "奔腾",
	["@benteng"] = "奔腾",
	["$Mbenteng1"] = "敢惹神的人都是活腻了！",
	["$Mbenteng2"] = "天罚！",
	["$Mbenteng3"] = "你的死是给我的贡品。",
	[":Mbenteng"] = "主将技，锁定技，此武将牌上单独的阴阳鱼个数-1。主将技，出牌阶段结束时，你可以移除2枚“雷霆”标记并失去1点体力（若你已受伤则不失去），指定一名没有“奔腾”标记的其他势力角色获得“奔腾”标记。主将技，锁定技，拥有“奔腾”标记的角色出牌阶段结束时，视为你对其使用了一张【雷杀】。主将技，锁定技，拥有“奔腾”标记的角色对一名其他角色造成一次伤害后，移除“奔腾”标记，你摸X张牌（X为伤害点数）。",
	["~Mthunder"] = "（哭泣）悲惨的一天！",
	["cv:Mthunder"] = "宙斯",
	["illustrator:Mthunder"] = "英雄无敌6",
	["designer:Mthunder"] = "月兔君",
}

--[[
   创建武将【伊亚拉斯】
]]--
Mylath = sgs.General(Ashan1, "Mylath", "ying", 4)
lord_Mylath = sgs.General(Ashan1, "lord_Mylath$", "ying", 4, true, true)
--非君主时珠联璧合：雷鸟
Mylath:addCompanion("Mthunder")
--[[
*【探索】君主技，锁定技，你拥有“不倦之翼”。
“不倦之翼”锁定技，与你相同势力的角色出牌阶段结束时，若其有手牌，其可以观看一名其距离1内手牌数大于他的其他势力的角色的手牌：若其中存在其手牌区没有花色的牌，其获得之；若不存在，其弃置所有手牌。
*【自由】锁定技，你的摸牌阶段始终视为出牌阶段。锁定技，你的出牌阶段开始时，若你手牌数小于任一攻击范围内其他势力的角色或你手牌数不大于一张，你摸两张牌。
]]--
Mtansuo = sgs.CreateTriggerSkill{
	name = "Mtansuo$",
	frequency = sgs.Skill_NotFrequent, 
	events = {sgs.EventPhaseEnd},
	can_preshow = false,
	can_trigger = function(self, event, room, player, data)
		if player:getPhase() == sgs.Player_Play and player:hasShownOneGeneral() then
			local haslord
			if player:isKongcheng() then return "" end
			if player:hasSkill(self:objectName()) and player:hasShownSkill(self) and player:isAlive() and player:getRole() ~= "careerist" then
				haslord = true
			else
				local ylath
				for _,p in sgs.qlist(room:getOtherPlayers(player)) do
					if player:isFriendWith(p) and p:hasSkill(self:objectName()) and p:hasShownSkill(self) and p:getRole() ~= "careerist" then
						ylath = p
						break
					end
				end
				if ylath and ylath:isAlive() then
					haslord = true
				end
			end
			if haslord then
				local targets = sgs.SPlayerList()
				for _, p in sgs.qlist(room:getOtherPlayers(player)) do
					if p:hasShownOneGeneral() and player:distanceTo(p) < 2 and player:distanceTo(p) ~= -1 and player:getHandcardNum() < p:getHandcardNum() and not p:isFriendWith(player) then
						targets:append(p)
					end
				end
				if not targets:isEmpty() then
					return self:objectName()
				end
			end
		end
		return ""
	end,
	on_cost = function(self, event, room, player, data)
		if room:askForSkillInvoke(player, self:objectName(), data) then
			room:broadcastSkillInvoke(self:objectName(), 1)
			return true
		end
		return false
	end,
	on_effect = function(self, event, room, player, data)
		local targets = sgs.SPlayerList()
		for _, p in sgs.qlist(room:getOtherPlayers(player)) do
			if p:hasShownOneGeneral() and player:distanceTo(p) < 2 and player:distanceTo(p) ~= -1 and player:getHandcardNum() < p:getHandcardNum() and not p:isFriendWith(player) then
				targets:append(p)
			end
		end
		if not targets:isEmpty() then
			local target = room:askForPlayerChosen(player, targets, self:objectName())
			local x = target:getHandcardNum()
			room:showAllCards(target, player)
			local has_heart
			local has_spade
			local has_diamond
			local has_club
			for _, card in sgs.qlist(player:getHandcards()) do
				if card:getSuit() == sgs.Card_Heart then
					has_heart = true
				elseif card:getSuit() == sgs.Card_Spade then
					has_spade = true
				elseif card:getSuit() == sgs.Card_Diamond then
					 has_diamond = true
				elseif card:getSuit() == sgs.Card_Club then
					has_club = true
				end
			end
			local emptycard = MemptyCard:clone()
			for _, card in sgs.qlist(target:getHandcards()) do
				if card:getSuit() == sgs.Card_Heart and not has_heart then
					emptycard:addSubcard(card)
				elseif card:getSuit() == sgs.Card_Spade and not has_spade then
					emptycard:addSubcard(card)
				elseif card:getSuit() == sgs.Card_Diamond and not has_diamond then
					emptycard:addSubcard(card)
				elseif card:getSuit() == sgs.Card_Club and not has_club then
					emptycard:addSubcard(card)
				end
			end
			if emptycard:subcardsLength() > 0 then
				if emptycard:subcardsLength() < x then
					room:broadcastSkillInvoke(self:objectName(), 2)
				else
					room:broadcastSkillInvoke(self:objectName(), 3)
				end
				player:obtainCard(emptycard, false)
			else
				room:broadcastSkillInvoke(self:objectName(), 3)
				player:throwAllHandCards()
			end
		end
		return false
	end,
}
Mziyou = sgs.CreateTriggerSkill{
	name = "Mziyou",
	frequency = sgs.Skill_Compulsory,
	events = {sgs.EventPhaseChanging},
	can_preshow = true,
	can_trigger = function(self, event, room, player, data)
		if player and player:isAlive() and player:hasSkill(self:objectName()) then
			local change = data:toPhaseChange()
			if change.to == sgs.Player_Draw and not player:isSkipped(sgs.Player_Draw) then
				return self:objectName()
			end
		end
		return ""
	end,
	on_cost = function(self, event, room, player, data)
		if player:hasShownSkill(self) or room:askForSkillInvoke(player, self:objectName(), data) then
			room:broadcastSkillInvoke(self:objectName(), 1)
			room:notifySkillInvoked(player, self:objectName())
			return true
		end
		return false
	end,
	on_effect = function(self, event, room, player, data)
		local log = sgs.LogMessage()
	        log.type = "#ziyou1"
			log.from = player
		room:sendLog(log)
		player:skip(sgs.Player_Draw)
		room:getThread():delay(1000)
		player:setPhase(sgs.Player_Play)
		room:broadcastProperty(player, "phase")
		if not room:getThread():trigger(sgs.EventPhaseStart, room, player) then
			room:getThread():trigger(sgs.EventPhaseProceeding, room, player)
		end
		room:getThread():trigger(sgs.EventPhaseEnd, room, player)
		room:broadcastSkillInvoke(self:objectName(), 2)
		local log = sgs.LogMessage()
			log.type = "#ziyou2"
			log.from = player
		room:sendLog(log)
		room:getThread():delay(1000)
	end,
}
Mziyou_effect = sgs.CreateTriggerSkill{
	name = "#Mziyou_effect",
	frequency = sgs.Skill_Compulsory,
	events = {sgs.EventPhaseStart},
	can_trigger = function(self, event, room, player, data)
		if player and player:isAlive() and player:hasSkill("Mziyou") then
			if player:getPhase() == sgs.Player_Play then
				local less
				for _, p in sgs.qlist(room:getOtherPlayers(player)) do
					if p:hasShownOneGeneral() and player:inMyAttackRange(p) and not (player:isFriendWith(p) or player:willBeFriendWith(p)) and player:getHandcardNum() < p:getHandcardNum() then
						less = true
						break
					end
				end
				if less or player:getHandcardNum() < 2 then
					return self:objectName()
				end
			end
		end
		return ""
	end,
	on_cost = function(self, event, room, player, data)
		if player:hasShownSkill(Mziyou) or room:askForSkillInvoke(player, self:objectName(), data) then
			room:broadcastSkillInvoke("Mziyou", 3)
			room:notifySkillInvoked(player, self:objectName())
			return true
		end
		return false
	end,
	on_effect = function(self, event, room, player, data)
		player:drawCards(2)
	end,
}
--武将加入技能“探索”“自由”
Mylath:addSkill(Mziyou)
Mylath:addSkill(Mziyou_effect)
lord_Mylath:addSkill(Mtansuo)
lord_Mylath:addSkill(Mziyou)
lord_Mylath:addSkill(Mziyou_effect)
Ashan1:insertRelatedSkills("Mziyou", "#Mziyou_effect")
--武将注释
sgs.LoadTranslationTable{
    ["Mylath"] = "伊亚拉斯",
	["&Mylath"] = "伊亚拉斯",
	["#Mylath"] = "天空之龙",
	["lord_Mylath"] = "伊亚拉斯",
	["&lord_Mylath"] = "伊亚拉斯",
	["#lord_Mylath"] = "天空之龙",
	["Mtansuo"] = "探索",
	["$Mtansuo1"] = "比跳入台风中心还刺激~",
	["$Mtansuo2"] = "令人惊奇。",
	["$Mtansuo3"] = "全是我的~",
	["$Mtansuo4"] = "反正我也需要休息一下~",
	[":Mtansuo"] = "君主技，锁定技，你拥有“不倦之翼”。\n\n“不倦之翼”\n与你相同势力的角色出牌阶段结束时，若其有手牌，其可以观看一名其距离1内手牌数大于他的其他势力的角色的手牌：若其中存在其手牌区没有花色的牌，其获得之；若不存在，其弃置所有手牌。",
	["Mziyou"] = "自由",
	["#Mziyou_effect"] = "自由",
	["$Mziyou1"] = "噢，我错过了什么？",
	["$Mziyou2"] = "今天属于我们。",
	["$Mziyou3"] = "不用担心，人人有份。",
	["#ziyou1"] = "%from 的摸牌阶段转化为出牌阶段!",
	["#ziyou2"] = "%from 转化的出牌阶段结束!",
	[":Mziyou"] = "锁定技，你的摸牌阶段始终视为出牌阶段。锁定技，你的出牌阶段开始时，若你手牌数小于任一攻击范围内其他势力的角色或你手牌数不大于一张，你摸两张牌。",
	["~Mylath"] = "不……",
	["cv:Mylath"] = "风暴之灵",
	["illustrator:Mylath"] = "英雄无敌6",
	["designer:Mylath"] = "月兔君",
	["cv:lord_Mylath"] = "风暴之灵",
	["illustrator:lord_Mylath"] = "英雄无敌6",
	["designer:lord_Mylath"] = "月兔君",
}

return {Ashan1}