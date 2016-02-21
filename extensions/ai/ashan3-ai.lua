--[[********************************************************
    这是 忧郁の月兔 制作的【英雄无敌Ⅵ-亚山之殇-暗】的AI文件
]]--********************************************************
--[[
    【骷髅矛手】
]]--
--尖矛
sgs.ai_skill_invoke["Mjianmao"] = function(self, data)
    local damage = data:toDamage()
	if self:isFriend(damage.to) then
--	    if not (self:doNotDiscard(damage.to, "e") or damage.to:hasShownSkills(sgs.lose_equip_skill) or (damage.to:isWounded() and damage.to:getEquips():length() == 1 and damage.to:hasArmorEffect("SilverLion"))) then
		    return false
--		end
	else
--	    if self:doNotDiscard(damage.to, "e") or damage.to:hasShownSkills(sgs.lose_equip_skill) or (damage.to:isWounded() and damage.to:getEquips():length() == 1 and damage.to:hasArmorEffect("SilverLion")) then
	        return false
--		end
	end
	return true
end
--腐骨
sgs.ai_skill_invoke["Mfugu"] = true
sgs.ai_slash_prohibit["Mfugu"] = function(self, from, to, card)
	if to:hasShownSkill("Mfugu") and from:distanceTo(to) > 1 and not card:isKindOf("NatureSlash") then
	    return true
	end
	return false
end
--蛛网
sgs.ai_skill_cardask["@zhuwang_invoke"] = function(self, data)
    local weapon, target
	local cards = sgs.QList2Table(self.player:getCards("he"))
	self:sortByUseValue(cards, true)
	for _, card in ipairs(cards) do
		if card:isKindOf("Weapon") then
			weapon = card
			break
		end
	end
	if weapon then
	    local targets = sgs.QList2Table(self.room:getOtherPlayers(self.player))
		self:sort(targets, "hp", true)
		for _, p in ipairs(targets) do
	        if self:isEnemy(p) and p:isWounded() and self.player:distanceTo(p) == 1 then
			    target = p
				self.room:setPlayerFlag(p, "zhuwang_target")
				break
			end
		end
	end
	if target then
		return "$" .. weapon:getEffectiveId()
	end
	return "."
end
sgs.ai_skill_playerchosen["Mzhuwang"] = function(self, targets)
    local target
	for _, p in sgs.qlist(self.room:getOtherPlayers(self.player)) do
		if p:hasFlag("zhuwang_target") then
		    target = p
			self.room:setPlayerFlag(target, "-zhuwang_target")
		end
	end
	return target
end
sgs.ai_playerchosen_intention["Mzhuwang"] = 50
--需求
sgs.ai_cardneed["Mzhuwang"] = function(to, card, self)
    if to:getMark("@zhuwang_use") == 1 then
	    if not to:getWeapon() then
	        return card:isKindOf("Weapon")
		end
	end
end
--[[
    【噬尸鬼】
]]--
--憎恶（已在slashIsEffective添加）
sgs.ai_skill_invoke["Mzengwu"] = function(self, data)
	local effect = data:toSlashEffect()
	if self:isFriend(effect.to) or (self.player:getHp() < 3 and effect.to:getHandcardNum() > 2) then
		return false
	end
	return true
end
--需求
sgs.ai_cardneed["Mtanlan"] = function(to, card, self)
	return to:getHandcardNum() < 3 and card:isKindOf("Slash")
end
--保留值
sgs.Mjihen_keep_value = {
	Peach = 6,
	Analeptic = 5.8,
	Jink = 5.7,
	FireSlash = 5.6,
	Slash = 5.4,
	ThunderSlash = 5.5,
	ExNihilo = 4.7
}
--[[
    【怨魂】
]]--
--哀嚎
sgs.ai_skill_invoke["Maihao"] = true
sgs.ai_skill_suit["Maihao"] = function(self)
	local n = math.random(1,2)
	if self.player:isWounded() then
		if n == 1 then
			return 1
		else
		    return 2
		end
	else
		if n == 1 then
			return 0
		else
		    return 3
		end
	end
end
--印记
sgs.ai_skill_invoke["Myinji"] = function(self, data)
	if self.player:getHandcardNum() <= self.player:getMaxCards() then
		return false
	end
	return true
end
--无形（已在hasTrickEffective添加）
sgs.ai_skill_invoke["Mwuxing"] = true
--[[
    【大尸巫】
]]--
--魂拥
sgs.ai_skill_invoke["Mhunyong"] = function(self, data)
	if (self:getCardsNum("Peach") > 0 and self.player:isWounded()) or self.player:getHandcardNum() == self.player:getMaxHp() then
	    return false
	end
	return true
end
--汲取
sgs.ai_skill_invoke["Mjiqu"] = function(self, data)
    local target
	local targets = sgs.QList2Table(self.room:getOtherPlayers(self.player))
	self:sort(targets, "handcard")
	for _, p in ipairs(targets) do
	    if not self:isFriend(p) then
			if not p:isKongcheng() and self.player:distanceTo(p) == 1 and not self:doNotDiscard(p, "h") then
				target = p
				self.room:setPlayerFlag(self.player, "choose_get")
				break
			elseif p:hasShownOneGeneral() and self.player:inMyAttackRange(p) and not p:isNude() and not (self.player:isFriendWith(p) or self.player:willBeFriendWith(p)) and not self:doNotDiscard(p, "he") then
				target = p
				break
			end
		end
	end
	if target then
	    self.room:setPlayerFlag(target, "jiqu_target")
		return true
	end
	return false
end
sgs.ai_skill_choice["Mjiqu"] = function(self, choices, data)
    if self.player:hasFlag("choose_get") then
	    self.room:setPlayerFlag(self.player, "-choose_get")
		return "jiqu_get"
	else
	    return "jiqu_drop"
	end
end
sgs.ai_skill_playerchosen["Mjiqu"] = function(self, targets)
    local target
    for _, p in sgs.qlist(self.room:getOtherPlayers(self.player)) do
		if p:hasFlag("jiqu_target") then
		    target = p
			self.room:setPlayerFlag(target, "-jiqu_target")
		end
	end
	return target
end
sgs.ai_skill_exchange["Mjiqu"] = function(self,pattern,max_num,min_num,expand_pile)
	local to_exchange = {}
	local least = min_num
	local n = 0
	local cards = sgs.QList2Table(self.player:getHandcards())
	self:sortByUseValue(cards, true)
	for _, card in ipairs(cards) do
		if card then
		    table.insert(to_exchange, card:getEffectiveId())
			n = n+1
			if n == least then
				break
			end
		end
	end
	return  to_exchange
end
sgs.ai_playerchosen_intention["Mjiqu"] = 40
--死亡
sgs.ai_skill_cardask["@siwang_invoke"] = function(self, data)
    local dying = data:toDying()
	local spade
	local cards = sgs.QList2Table(self.player:getHandcards())
	self:sortByUseValue(cards, true)
	for _, card in ipairs(cards) do
		if card:getSuit() == sgs.Card_Spade then
		    spade = card
			break
		end
	end
	if spade and self:isEnemy(dying.who) then
	    return "$" .. spade:getEffectiveId()
	else
	    return "."
	end
end
--[[
    【腐毒拉玛苏】
]]--
--虫息
sgs.ai_skill_invoke["Mchongxi"] = function(self, data)
	local damage = data:toDamage()
	if self:isFriend(damage.to) then
		return false
	end
	return true
end
--瘟疫
sgs.ai_skill_invoke["Mwenyi"] = function(self, data)
    if self:getAllPeachNum() > 0 or self.player:getHp() > 0 then
	    return false
	end
	return true
end
--[[
    【吸血伯爵】
]]--
--血握
sgs.ai_skill_invoke["Mxuewo"] = function(self, data)
	local damage = data:toDamage()
	if damage.damge == 1 and self.player:hasSkills(sgs.masochism_skill) and not self.player:getLostHp() > 1 then
		return false
	end
	return true
end
--时空
sgs.ai_skill_invoke["Mshikong"] = function(self, data)
    local a = self.player:getMark("@xue")
	local b = self.player:getHp()
	local c = self.player:getLostHp()
	local d = self:getCardsNum("Peach")
	if (a > 2) or (a >= b+d) or (a > 0 and self.player:isKongcheng()) then
		return true
	else
		if not (d > 0 and c > 0) and (c > 0 and self.player:hasArmorEffect("SilverLion")) then
			return true
		end
	end
	return false
end
sgs.ai_slash_prohibit["Mshikong"] = function(self, from, to, card)
	if to:hasShownSkill("Mshikong") and to:getMark("@shikong") == 1 then
	    return true
	end
	return false
end
--[[
    【织命蛛后】
]]--
--邪知
sgs.ai_skill_invoke["Mxiezhi"] = function(self, data)
	if self.player:getHandcardNum() == 1 then
	    if self:getCard("Peach", self.player) or self:getCard("Analeptic", self.player) then
		    return false
		end
	end
	return true
end
--命运（已在hasTrickEffective添加）
sgs.ai_skill_invoke["Mmingyun"] = true
sgs.ai_slash_prohibit["Mmingyun"] = function(self, from, to, card)
	if to:hasShownSkill("Mmingyun") and not card:isKindOf("NatureSlash") and card:isVirtualCard() then
	    return true
	end
	return false
end
--流逝
sgs.ai_skill_invoke["Mliushi"] = function(self, data)
    local target
    if not (self.player:getHp() > 1 or self:getAllPeachNum(self.player) > 0) then return false end
	local targets = sgs.QList2Table(self.room:getOtherPlayers(self.player))
	self:sort(targets)
	for _, p in ipairs(targets) do
		if self:isEnemy(p) and self.player:inMyAttackRange(p) then
			target = p
			break
		end
	end
	if target then
	    self.room:setPlayerFlag(target, "liushi_target")
	    return true
	end
	return false
end
sgs.ai_skill_playerchosen["Mliushi"] = function(self, targets)
    local target
	for _, p in sgs.qlist(self.room:getOtherPlayers(self.player)) do
		if p:hasFlag("liushi_target") then
		    target = p
			self.room:setPlayerFlag(target, "-liushi_target")
			break
		end
	end
	return target
end
sgs.ai_playerchosen_intention["Mliushi"] = 40
--归宿
sgs.ai_skill_invoke["Mguisu"] = true
--双身
sgs.ai_skill_invoke["Mshuangshen"] = function(self, data)
	if self.player:getHp() < 2 and self:getAllPeachNum() == 0 and self.player:getMark("wenyi_use") == 0 then
		if not (self.player:getMark("@langzhan") > 0 and self.player:hasSkill("Mcanyang")) then
			if not (self.player:hasSkill("Mgenyuan") or self.player:hasSkill("Myuanquan")) then
				return true
			end
		end
	end
	return false
end
--[[
    【阴魂龙】
]]--
--枯萎
sgs.ai_skill_invoke["Mkuwei"] = true
--衰老
sgs.ai_skill_cardask["@shuailao_invoke"] = function(self, data)
    local target
	local targets = sgs.QList2Table(self.room:getOtherPlayers(self.player))
    self:sort(targets, "hp")
	for _, p in ipairs(targets) do
	    if not (self.player:isFriendWith(p) or self.player:willBeFriendWith(p)) and self:isEnemy(p) and p:isWounded() and not (p:hasShownSkill("tiandu") or p:hasShownSkill("Mlingyun")) then
		    target = p
			self.room:setPlayerFlag(target, "shuailao_target")
			break
		end
	end
	if target then
	    local cards = sgs.QList2Table(self.player:getHandcards())
		self:sortByUseValue(cards, true)
		for _, card in ipairs(cards) do
		    if card:isKindOf("BasicCard") then
			    return "$" .. card:getEffectiveId()
			end
		end
	end
	return "."
end
sgs.ai_skill_playerchosen["Mshuailao"] = function(self, targets)
    local target
	for _, p in sgs.qlist(self.room:getOtherPlayers(self.player)) do
		if p:hasFlag("shuailao_target") then
		    target = p
			self.room:setPlayerFlag(target, "-shuailao_target")
			break
		end
	end
	return target
end
sgs.ai_playerchosen_intention["Mshuailao"] = 40
--永暗
sgs.ai_skill_invoke["Myongan"] = function(self, data)
	local x = 0
	for _,p in sgs.qlist(self.room:getOtherPlayers(self.player)) do
		if p:hasEquip() then
			if self:isFriend(p) then
				x = x-1
			else
				x = x+1
			end
		end
	end
	if x > 0 then
		return true
	end
	return false
end
--奴役
sgs.ai_skill_use["@@Mnuyi"] = function(self, prompt)
    local target
	local card_ids = {}
	local basic, trick, equip
	local targets = sgs.QList2Table(self.room:getOtherPlayers(self.player))
    self:sort(targets, "hp", true)
	for _, p in ipairs(targets) do
	    if self:isEnemy(p) and p:getHp() <= self.player:getHp() then
		    target = p
			break
		end
	end
	if target then
	    local cards = sgs.QList2Table(self.player:getCards("he"))
		self:sortByUseValue(cards, true)
		for _, card in ipairs(cards) do
		    if card:isKindOf("BasicCard") and not card:isKindOf("Peach") and not basic then
		        basic = true
				table.insert(card_ids, card:getId())
		    elseif card:isKindOf("TrickCard") and not trick then
		        trick = true
				table.insert(card_ids, card:getId())
		    elseif card:isKindOf("EquipCard") and not card:isKindOf("Armor") and not equip then
		        equip = true
				table.insert(card_ids, card:getId())
			end
		end
		if basic and trick and equip then
			local card_str = "#MnuyiCard:"..table.concat(card_ids, "+")..":->"..target:objectName()
			return card_str
		end
	end
	return "."
end
sgs.ai_skill_exchange["Mnuyi"] = function(self,pattern,max_num,min_num,expand_pile)
	local to_exchange = {}
	local least = min_num
	local n = 0
	local cards = sgs.QList2Table(self.player:getHandcards())
	self:sortByUseValue(cards, true)
	for _, card in ipairs(cards) do
		if card then
		    table.insert(to_exchange, card:getEffectiveId())
			n = n+1
			if n == least then
				break
			end
		end
	end
	return  to_exchange
end
sgs.ai_card_intention.MnuyiCard = 50
--[[
    【亚莎】
]]--
--象征
sgs.ai_skill_choice["Mxiangzheng"] = function(self, choices, data)
	if self.player:getMark("xiangzheng_creat") == 0 then
		return "xiangzheng_creat"
	else
		local x = 0
		for _, p in sgs.qlist(self.room:getOtherPlayers(self.player)) do
			if p:hasShownOneGeneral() and p:getHp() > self.player:getHp() and not self.player:isFriendWith(p) then
				if self:isFriend(p) then
					x = x-1
				else
					x = x+1
				end
			end
		end
		if x > 0 then
			return "xiangzheng_death"
		end
	end
	return "xiangzheng_balance"
end
sgs.ai_skill_invoke["#Mpingheng"] = function(self, data)
	local target = data:toPlayer()
	if self.player:isFriendWith(target) then
		return true
	else
		if self:isEnemy(target) then
			return true
		end
	end
	return false
end
--秩序
sgs.ai_skill_invoke["Mzhixu"] = true
--[[
    【狂魔】
]]--
--扭曲
sgs.ai_skill_invoke["Mniuqu"] = true
--癫笑
sgs.ai_skill_invoke["Mdianxiao1"] = true
sgs.ai_skill_invoke["Mdianxiao2"] = function(self, data)
	local damage = data:toDamage()
	if self:isFriend(damage.to) then
		return false
	end
	return true
end
--[[
    【狼魔】
]]--
--悭吝
sgs.ai_skill_invoke["Mqianlin"] = function(self, data)
	if self.player:isWounded() then
		return true
	end
	return false
end
--饕餮
sgs.ai_skill_invoke["Mtaotie"] = function(self, data)
	local damage = data:toDamage()
	if self:isFriend(damage.to) then
		return false
	end
	return true
end
sgs.ai_skill_invoke["#Mtaotie_effect"] = true
--[[
    【魅魔】
]]--
--愉悦
sgs.ai_skill_invoke["Myuyue"] = function(self, data)
    local target = data:toPlayer()
	if self:isEnemy(target) then
		if (getCardsNum("Jink", target, self.player) > 0) or (target:hasShownSkill("Mguangsu") and target:getHandcardNum() == target:getHp()) or target:hasShownSkill("bazhen") then
			if target:getHp() == 1 then
				return true
			else
				if self.player:isWounded() then
					return true
				else
					if not (self.player:getHandcardNum() == 1 and (self:getCardsNum("Peach") == 1 or self:getCardsNum("Jink") == 1)) then
						return true
					end
				end
			end
		end
	end
	return false
end
sgs.ai_skill_exchange["Myuyue"] = function(self,pattern,max_num,min_num,expand_pile)
	local to_exchange = {}
	local least = min_num
	local n = 0
	local cards = sgs.QList2Table(self.player:getHandcards())
	self:sortByUseValue(cards, true)
	for _, card in ipairs(cards) do
		if card then
		    table.insert(to_exchange, card:getEffectiveId())
			n = n+1
			if n == least then
				break
			end
		end
	end
	return  to_exchange
end
--诱惑
sgs.ai_skill_invoke["Myouhuo"] = function(self, data)
	local target
	local targets = sgs.QList2Table(self.room:getOtherPlayers(self.player))
    self:sort(targets, "handcard", true)
	for _,p in ipairs(targets) do
	    if self:isEnemy(p) and p:getHandcardNum() > 1 and self.player:getGender() ~= p:getGender() then
		    local red = 0
			local black = 0
		    for _,cd in sgs.qlist(p:getHandcards()) do
			    if cd:isRed() then
				    red = red+1
				elseif cd:isBlack() then
				    black = black+1
				end
			end
			if red > 1 then
			    target = p
				break
			elseif black > 1 and has_red then
				self.room:setPlayerFlag(self.player, "youhuo_black")
				break
			end
		end
	end
	if target then
	    self.room:setPlayerFlag(target, "youhuo_target")
		return true
	end
	return false
end
sgs.ai_skill_choice["Myouhuo"] = function(self, choices, data)
	if self.player:hasFlag("youhuo_black") then
		self.room:setPlayerFlag(self.player, "-youhuo_black")
		return "youhuo_black"
	end
	return "youhuo_red"
end
sgs.ai_skill_playerchosen["Myouhuo"] = function(self, targets)
    local target
	for _, p in sgs.qlist(self.room:getOtherPlayers(self.player)) do
		if p:hasFlag("youhuo_target") then
		    target = p
			self.room:setPlayerFlag(p, "-youhuo_target")
			break
		end
	end
	return target
end
sgs.ai_playerchosen_intention["Myouhuo"] = 50
sgs.ai_skill_choice["youhuo_effect"] = function(self, choices, data)
	local target = data:toPlayer()
	if self:isFriend(target) then
		return "youhuo_no"
	end
	return "youhuo_yes"
end
--[[
    【衍魔】
]]--
--增殖
sgs.ai_skill_invoke["Mzengzhi"] = function(self, data)
	if self.player:getPhase() == sgs.Player_NotActive then
		if self.player:getHandcardNum() >= (self.player:getLostHp() + 1) then
			return false
		end
	end
	return true
end
--回归
sgs.ai_skill_invoke["Mhuigui"] = function(self, data)
	local target = data:toPlayer()
	if self:getAllPeachNum(self.player) > 0 or self.player:getHp() > 0 then return false end
	if not (self.player:getMark("@langzhan") > 0 and self.player:hasSkill("Mcanyang")) then
		if not (self.player:hasSkill("Mgenyuan") or self.player:hasSkill("Myuanquan")) then
			return true
		end
	end
	return false
end
--繁衍
sgs.ai_skill_invoke["Mfanyan"] = function(self, data)
	if self:isWeak(self.player) and self:getCardsNum("Peach") > 0 then
		return false
	end
	return true
end
--[[
    【巢虫】
]]--
--噬魔（已添加至smart-ai）
--[[
    【刑魔】
]]--
--苦楚
sgs.ai_skill_cardask["@kuchu_invoke"] = function(self, data)
    local damage = data:toDamage()
	if self:isFriend(damage.to) then return "." end
	local has_card
    local cards = sgs.QList2Table(self.player:getHandcards())
	self:sortByUseValue(cards, true)
	for _,cd in ipairs(cards) do
	    if not cd:isKindOf("Peach") then
		    has_card = cd
			break
		end
	end
	if has_card then
	    return "$" .. has_card:getEffectiveId()
	else
	    return "."
	end
end
--折磨
sgs.ai_skill_invoke["Mzhemo"] = function(self, data)
	local use = data:toCardUse()
	if self.player:isKongcheng() and not self.player:hasEquip() then
		return true
	else
		if use.card:isKindOf("GodSalvation") and self.player:isWounded() then
			return false
		end
	end
	return true
end
--施虐
sgs.ai_skill_invoke["Mshinue"] = true
--[[
    【暴魔】
]]--
--暴行
sgs.ai_skill_invoke["Mbaoxing1"] = function(self, data)
	local target = data:toPlayer()
	if self:isFriend(target) then
		if not (target:hasEquip() and self:doNotDiscard(target, "e") or target:hasShownSkills(sgs.lose_equip_skill) or (target:isWounded() and target:hasArmorEffect("SilverLion"))) then
			return false
		end
	else
		if target:hasEquip() and target:isKongcheng() then
			if self:doNotDiscard(target, "e") or target:hasShownSkills(sgs.lose_equip_skill) or (target:getEquips():length() == 1 and target:isWounded() and target:hasArmorEffect("SilverLion")) then
				return false
			end
		end
	end
	return true
end
sgs.ai_skill_invoke["Mbaoxing2"] = function(self, data)
	local damage = data:toDamage()
	if self:isFriend(damage.from) then
		return false
	end
	return true
end
sgs.ai_skill_exchange["Mbaoxing"] = function(self,pattern,max_num,min_num,expand_pile)
	local to_exchange = {}
	local least = min_num
	local n = 0
	local cards = sgs.QList2Table(self.player:getCards("he"))
	self:sortByUseValue(cards, true)
	for _, card in ipairs(cards) do
		if card then
		    table.insert(to_exchange, card:getEffectiveId())
			n = n+1
			if n == least then
				break
			end
		end
	end
	return  to_exchange
end
--嘲弄（已添加至standard_cards-ai）
sgs.ai_skill_cardask["@chaonong_invoke"] = function(self, data)
	local use = data:toCardUse()
	if not self:isFriend(use.from) and self:isWeak(self.player) and self:getCardsNum("Jink") == 0 and self:getAllPeachNum() == 0 and getCardsNum("Slash", use.from, self.player) > 0 then return "." end
	local has_card
    local cards = sgs.QList2Table(self.player:getHandcards())
	self:sortByUseValue(cards, true)
	for _,cd in ipairs(cards) do
	    if cd:isKindOf("BasicCard") then
		    has_card = cd
			break
		end
	end
	if has_card then
	    return "$" .. has_card:getEffectiveId()
	else
	    return "."
	end
end
--冲撞
sgs.ai_skill_invoke["Mchongzhuang"] = function(self, data)
	if self:getCardsNum("Peach") > 0 and self.player:getHandcardNum() < 3 and self.player:isWounded() then return false end
	local target
	local targets = sgs.QList2Table(self.room:getOtherPlayers(self.player))
    self:sort(targets, "hp")
	for _, p in ipairs(targets) do
	    if p:hasShownOneGeneral() and self:isEnemy(p) then
    		if self.player:distanceTo(p) == 1 and self:damageIsEffective(p, sgs.DamageStruct_Normal, self.player) and getCardsNum("Jink", p, self.player) == 0 then
				target = p
				break
			end
		end
	end
	if target then
		self.room:setPlayerFlag(target, "chongzhuang_target")
		return true
	end
	return false
end
sgs.ai_skill_playerchosen["Mchongzhuang"] = function(self, targets)
    local target
	for _, p in sgs.qlist(self.room:getOtherPlayers(self.player)) do
		if p:hasFlag("chongzhuang_target") then
		    target = p
			self.room:setPlayerFlag(p, "-chongzhuang_target")
			break
		end
	end
	return target
end
sgs.ai_playerchosen_intention["Mchongzhuang"] = 50
--[[
    【深渊领主】
]]--
--睚眦
sgs.ai_skill_invoke["Myazi1"] = true
sgs.ai_skill_invoke["Myazi2"] = function(self, data)
    local damage = data:toDamage()
	if self:isFriend(damage.to) then
		return false
	end
	return true
end
--杀戮
sgs.ai_skill_invoke["Mshalu"] = true
--仇怨
sgs.ai_skill_invoke["Mchouyuan"] = function(self, data)
	local m = 0
	local slash = sgs.cloneCard("fire_slash")
	for _, p in sgs.qlist(self.room:getOtherPlayers(self.player)) do
	    if p:hasShownOneGeneral() and not (self.player:isFriendWith(p) or self.player:willBeFriendWith(p)) and p:getPile("yazi"):length() > 0 and self.player:canSlash(p,slash,false) then
			if self:isFriend(p) then
				m = m-1
			elseif self:isEnemy(p) then
				m = m+1
			end
		end
	end
	if m > 0 then
		return true
	end
	return false
end
--[[
    【阿兹卡尔】
]]--
--敌意
sgs.ai_skill_invoke["Mdiyi1"] = function(self, data)
	local damage = data:toDamage()
	if self:isFriend(damage.from) then
		return false
	end
	return true
end
sgs.ai_skill_invoke["Mdiyi2"] = function(self, data)
	local damage = data:toDamage()
	if self:isFriend(damage.to) then
		return false
	end
	return true
end
sgs.ai_slash_prohibit["Mdiyi"] = function(self, from, to, card)
	if from:getMark("@diyi") == 1 then
        return true
	end
	return false
end
--湮没
sgs.ai_skill_invoke["Myanmo"] = function(self, data)
    local m = self.player:getEquips():length()
	local x = 0
	for _, p in sgs.qlist(self.room:getOtherPlayers(self.player)) do
	    if p:hasShownOneGeneral() and not (self.player:isFriendWith(p) or self.player:willBeFriendWith(p)) and self.player:distanceTo(p) <= m and self.player:distanceTo(p) ~= -1 and self:damageIsEffective(p, sgs.DamageStruct_Fire, self.player) then
			if self:isFriend(p) then
				if p:hasEquip() then
					if (self:doNotDiscard(p, "e") or p:hasSkills(sgs.lose_equip_skill) or (p:isWounded() and p:hasArmorEffect("SilverLion"))) then
						x = x+1
					else
						x = x-1
					end
				else
					x = x-1
				end
			else
				if p:hasEquip() then
					if (self:doNotDiscard(p, "e") or p:hasSkills(sgs.lose_equip_skill) or (p:isWounded() and p:hasArmorEffect("SilverLion"))) then
						x = x-1
					else
						x = x+1
					end
				else
					x = x+1
				end
			end
		end
	end
	if self.player:getEquips():length() <= x or self:getOverflow(self.player) > 2then
	    return true
	end
	return false
end
sgs.ai_skill_cardask["@yanmo_invoke"] = function(self, data)
	local target = data:toPlayer()
	if not self:damageIsEffective(self.player, sgs.DamageStruct_Fire, target) then return "." end
	local has_card
    local cards = sgs.QList2Table(self.player:getCards("he"))
	self:sortByUseValue(cards, true)
	for _,cd in ipairs(cards) do
	    if cd:isKindOf("EquipCard") then
		    has_card = cd
			break
		end
	end
	if has_card then
	    return "$" .. has_card:getEffectiveId()
	end
	return "."
end
--毁灭
sgs.ai_skill_invoke["Mhuimie"] = function(self, data)
    local target
	local targets = sgs.QList2Table(self.room:getOtherPlayers(self.player))
	self:sort(targets, "handcard")
	for _, p in ipairs(targets) do
	    if self:isEnemy(p) and p:getHandcardNum() < 5 then
			if getCardsNum("BasicCard", p, self.player) >= (p:getHandcardNum() - 1) then
				target = p
				break
			end
		end
	end
	if target then
		self.room:setPlayerFlag(target, "huimie_target")
	    return true
	end
	return false
end
sgs.ai_skill_playerchosen["Mhuimie"] = function(self, targets)
    local target
	for _, p in sgs.qlist(self.room:getOtherPlayers(self.player)) do
		if p:hasFlag("huimie_target") then
		    target = p
			self.room:setPlayerFlag(p, "-huimie_target")
			break
		end
	end
	return target
end 
--[[
   创建武将【鄂加斯】
]]--
--混沌（无需ai）
--循环
sgs.ai_skill_invoke["Mxunhuan"] = true
sgs.ai_skill_cardask["@xunhuan_invoke"] = function(self, data)
	local target = data:toPlayer()
	if target:hasShownOneGeneral() and not self.player:isFriendWith(target) and target:getHandcardNum() < 2 then return "." end
	local has_card
	local cards = sgs.QList2Table(self.player:getCards("h"))
	self:sortByUseValue(cards, true)
	for _,cd in ipairs(cards) do
		if cd:isKindOf("TrickCard") then
			has_card = cd
			break
		end
	end
	if has_card then
		return "$" .. has_card:getEffectiveId()
	end
	return "."
end