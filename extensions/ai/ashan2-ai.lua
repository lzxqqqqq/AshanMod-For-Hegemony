--[[********************************************************
    这是 忧郁の月兔 制作的【英雄无敌Ⅵ-亚山之殇-秘】的AI文件
]]--********************************************************
--[[
    【鳄鲛】
]]--
--致残
sgs.ai_skill_invoke["Mzhican"] = function(self, data)
	local damage = data:toDamage()
	if self:isEnemy(damage.to) then
		return true
	end
	return false
end
--残暴
sgs.ai_skill_invoke["Mcanbao"] = function(self, data)
	local damage = data:toDamage()
	if self:isEnemy(damage.to) then
		return true
	end
	return false
end
--创伤（无需ai）
--[[
    【珍珠巫女】
]]--
--烟波
sgs.ai_skill_invoke["Myanbo"] = true
--蛇舞
sgs.ai_skill_invoke["Mshewu"] = function(self, data)
    local target, has_red, has_black, red_slash
	for _, card in sgs.qlist(self.player:getHandcards()) do
		if card:isRed() then
		    has_red = true
			if card:isKindOf("Slash") then
			    red_slash = true
			end
		end
		if card:isBlack() then
		    has_black = true
		end
	end
	local targets = sgs.QList2Table(self.room:getOtherPlayers(self.player))
	if has_red then
	    local m = 0
		self:sort(targets, "handcard")
		for _, p in ipairs(targets) do
		    if self:isFriend(p) and p:isWounded() and not p:isKongcheng() then
			    for _, card in sgs.qlist(p:getHandcards()) do
				    if card:isBlack() then
					    m = m+1
					end
				end
				if m < 3 then
				    target = p
					self.room:setPlayerFlag(p, "shewu_target")
					return true
				end
			end
		end
	end
	if has_black and red_slash and self:getCardsNum("Analeptic") == 0 then
	    self:sort(targets, "hp")
		for _, p in ipairs(targets) do
		    if self:isEnemy(p) and p:getHp() == 1 and not p:isKongcheng() and self.player:inMyAttackRange(p) then
			    target = p
				self.room:setPlayerFlag(p, "shewu_target")
				return true
			end
		end
	end
	return false
end
sgs.ai_skill_playerchosen["Mshewu"] = function(self, targets)
    local target
	for _, p in sgs.qlist(self.room:getOtherPlayers(self.player)) do
		if p:hasFlag("shewu_target") then
		    target = p
			self.room:setPlayerFlag(p, "-shewu_target")
			break
		end
	end
	return target
end
sgs.ai_skill_choice["Mshewu"] = function(self, choices, data)
    local target = data:toPlayer()
	if self:isEnemy(target) then
	    return "shewu_black"
	else
	    return "shewu_red"
	end
end
--需求
sgs.ai_cardneed["Mshewu"] = function(to, card, self)
	if card:isRed() and card:isKindOf("Slash") then
	    return to:getHandcardNum() < 3
	end
end
--[[
    【河伯】
]]--
--迅捷
sgs.ai_skill_invoke["Mxunjie"] = true
--急雨
sgs.ai_skill_invoke["Mjiyu"] = function(self, data)
    if self:getCardsNum("Jink") == 0 and self:getCardsNum("Peach") == 0 then
	    return true
	end
	return false
end
--[[
    【川灵】
]]--
--弱水
sgs.ai_skill_invoke["Mruoshui"] = function(self, data)
    local damage = data:toDamage()
	if self:isFriend(damage.from) then
	    return false
	end
	return true
end
sgs.ai_slash_prohibit["Mruoshui"] = function(self, from, to, card)
	if to:hasShownSkill("Mruoshui") and not self:isWeak(to) and to:getHandcardNum() > 1 and from:getHp() < 2 then
		if card:isVirtualCard() then
			if not from:isKongcheng() and from:getHandcardNum() < 4 and (getCardsNum("Jink", from, from) + getCardsNum("Peach", from, from)) > 0 then
				return true
			end
		else
			if from:getHandcardNum() > 1 and from:getHandcardNum() < 5 and (getCardsNum("Jink", from, from) + getCardsNum("Peach", from, from)) > 0 then
				return true
			end
		end
	end
	return false
end
--纯净
sgs.ai_skill_invoke["Mchunjing"] = true
--羁绊
sgs.ai_skill_invoke["Mjiban"] = true
--[[
    【冰女】
]]--
--冰晶
sgs.ai_skill_cardask["@bingjing_invoke"] = function(self, data)
    local use = data:toCardUse()
	local has_card, spade_card
	local cards = sgs.QList2Table(self.player:getHandcards())
	self:sortByUseValue(cards, false)
	for _,cd in ipairs(cards) do
	    if (self:getKeepValue(cd) <= self:getKeepValue(use.card)) or (use.card:isKindOf("TrickCard") and not use.card:isNDTrick()) then
			if cd:getSuit() == sgs.Card_Spade then
				spade_card = cd
			else
				has_card = cd
			end
		end
	end
	if spade_card then
	    return "$" .. spade_card:getEffectiveId()
	else
		if has_card then
			return "$" .. has_card:getEffectiveId()
		end
	end
	return "."
end
--魔性（已添加至smart-ai）
--冻结
sgs.ai_skill_use["@@Mdongjie"] = function(self, prompt)
    local target
	local card_ids = {}
	local basic, trick, equip
	local targets = sgs.QList2Table(self.room:getOtherPlayers(self.player))
    self:sort(targets, "hp", true)
	for _, p in ipairs(targets) do
	    if p:hasShownOneGeneral() and self:isEnemy(p) and p:hasEquip() then
		    target = p
			break
		end
	end
	if target then
	    local cards = sgs.QList2Table(self.player:getCards("he"))
		self:sortByUseValue(cards, true)
		for _, card in ipairs(cards) do
		    if card:isKindOf("BasicCard") and card:getSuit() == sgs.Card_Spade and not basic then
		        basic = true
				table.insert(card_ids, card:getId())
		    elseif card:isKindOf("TrickCard") and card:getSuit() == sgs.Card_Spade and not trick then
		        trick = true
				table.insert(card_ids, card:getId())
		    elseif card:isKindOf("EquipCard") and card:getSuit() == sgs.Card_Spade and not equip then
		        equip = true
				table.insert(card_ids, card:getId())
			end
		end
		if basic and trick and equip then
			local card_str = "#MdongjieCard:"..table.concat(card_ids, "+")..":->"..target:objectName()
			return card_str
		end
	end
	return "."
end
--[[
    【剑圣】
]]--
--浪斩
sgs.ai_skill_invoke["Mlangzhan"] = function(self, data)
    local target = data:toPlayer()
	if self:isFriend(target) then
	    return false
	end
	return true
end
--挑战
sgs.ai_skill_invoke["Mtiaozhan"] = function(self, data)
	local targets = sgs.QList2Table(self.room:getOtherPlayers(self.player))
    self:sort(targets, "hp", true)
	for _, p in ipairs(targets) do
	    if p:hasShownOneGeneral() and self:isEnemy(p) and p:getHp() >= self.player:getHp() then
			self.room:setPlayerFlag(p, "tiaozhan_target")
			return true
		end
	end
	return false
end
sgs.ai_skill_playerchosen["Mtiaozhan"] = function(self, targets)
    local target
	for _, p in sgs.qlist(self.room:getOtherPlayers(self.player)) do
		if p:hasFlag("tiaozhan_target") then
		    target = p
			self.room:setPlayerFlag(p, "-tiaozhan_target")
			break
		end
	end
	return target
end
sgs.ai_playerchosen_intention["Mtiaozhan"] = 50
sgs.ai_skill_choice["Mtiaozhan"] = function(self, choices, data)
	if self:getCardsNum("Peach") > 0 then
	    return "tiaozhan_hurt"
	end
	return "tiaozhan_throw"
end
--残阳
sgs.ai_skill_invoke["Mcanyang"] = function(self, data)
    if self:getAllPeachNum() > 0 or self.player:getHp() > 0 then
	    return false
	end
	return true
end
--需求
sgs.ai_cardneed["Mlangzhan"] = function(to, card, self)
	return card:getNumber() > 8 and card:isKindOf("Slash")
end
--[[
    【圣麒麟】
]]--
--根源
sgs.ai_skill_invoke["Mgenyuan"] = function(self, data)
    if self:getAllPeachNum() > 0 or self.player:getHp() > 0 then
	    return false
	end
	return true
end
--冰雹
sgs.ai_skill_invoke["Mbingbao"] = function(self, data)
    local damage = data:toDamage()
	if self:isEnemy(damage.to) then
	    if not (self:doNotDiscard(damage.to, "e") or damage.to:hasShownSkills(sgs.lose_equip_skill))then
		    return true
		end
	end
	return false
end
--凌波
sgs.ai_skill_invoke["Mlingbo"] = function(self, data)
	if self:isWeak(self.player) then
		return false
	end
	return true
end
--雾霭
sgs.ai_skill_invoke["Mwuai"] = function(self, data)
	if not self:isWeak(self.player) then
		local x = self.player:getPlayerNumWithSameKingdom("wuai")
		x = math.min(x, 4)
		local y = x - self.player:getHandcardNum()
		if y > 1 then
			return true
		end
	end
	return false
end
--[[
    【海龙】
]]--
--源泉
sgs.ai_skill_invoke["Myuanquan"] = true
--暴雪
sgs.ai_skill_cardask["@baoxue_invoke"] = function(self, data)
	local damage = data:toDamage()
	local has_trick
	local cards = sgs.QList2Table(self.player:getCards("he"))
	self:sortByUseValue(cards, true)
	for _, card in ipairs(cards) do
	    if card:isKindOf("TrickCard") then
		    has_trick = card
			break
		end
	end
	if has_trick then
		if self:isEnemy(damage.to) then
			if self:getOverflow(damage.to) > 2 and damage.to:getMark("@baoxueplay") == 0 then
				self.room:setPlayerFlag(self.player, "choose_baoxue_draw")
				return "$" .. has_trick:getEffectiveId()
			else
				if damage.to:getHandcardNum() < 3 and damage.to:getMark("@baoxuedraw") == 0 then
					self.room:setPlayerFlag(self.player, "choose_baoxue_play")
					return "$" .. has_trick:getEffectiveId()
				end
			end
		elseif self:isFriend(damage.to) and damage.to:getMark("@baoxuedis") == 0 then
			return "$" .. has_trick:getEffectiveId()
		end
	end
	return "."
end
sgs.ai_skill_choice["Mbaoxue"] = function(self, choices, data)
    local damage = data:toDamage()
	if self.player:hasFlag("choose_baoxue_draw") then
	    self.room:setPlayerFlag(self.player, "-choose_baoxue_draw")
		return "baoxue_skipdraw"
	elseif self.player:hasFlag("choose_baoxue_play") then
	    self.room:setPlayerFlag(self.player, "-choose_baoxue_play")
		return "baoxue_skipplay"
	end
	return "baoxue_skipthrow"
end
--凌云
sgs.ai_slash_prohibit["Mlingyun"] = function(self, from, to, card)
	if to:hasShownSkill("Mlingyun") and to:hasArmorEffect("EightDiagram") and not from:hasSkills(sgs.slash_benefit_skill) and not (from:hasWeapon("axe") and from:getEquips():length()+from:getHandcardNum() > 2) then
	    return true
	end
	return false
end
--云迹
sgs.ai_skill_invoke["Myunji"] = true
--[[
    【莎拉萨】
]]--
--波澜
sgs.ai_skill_invoke["Mbolan"] = function(self, data)
	local use = data:toCardUse()
	if use.card:isKindOf("SavageAssault") or use.card:isKindOf("ArcheryAttack") then
		local has_friend
		for _,p in sgs.qlist(use.to) do
			if p:hasShownOneGeneral() and self.player:isFriendWith(p) then
				has_friend = true
				break
			end
		end
		if has_friend then
			self.room:setPlayerFlag(self.player, "choose_bolan_friend")
			return true
		end
	elseif use.card:isKindOf("GodSalvation") or use.card:isKindOf("AmazingGrace") then
		local x = 0
		for _,p in sgs.qlist(use.to) do
			if p:hasShownOneGeneral() and not self.player:isFriendWith(p) then
				if self:isEnemy(p) then
					x = x+1
				else
					x = x-1
				end
			end
		end
		if x > 0 then
			return true
		end
	end
	return false
end
sgs.ai_skill_choice["Mbolan"] = function(self, choices, data)
	if self.player:hasFlag("choose_bolan_friend") then
	    self.room:setPlayerFlag(self.player, "-choose_bolan_friend")
		return "bolan_friend"
	else
		return "bolan_enemy"
	end
end
--怒涛
sgs.ai_skill_cardask["@nutao_red"] = function(self, data)
    local use = data:toCardUse()
	if use.card:isKindOf("IronChain") then return "." end
	local red_trick
	local cards = sgs.QList2Table(self.player:getCards("h"))
	self:sortByUseValue(cards, true)
	for _, card in ipairs(cards) do
		if self:getUseValue(card) < self:getUseValue(use.card) then
			if card:isKindOf("TrickCard") and card:isRed() then
				red_trick = card
				break
			end
		end
	end
	if red_trick then
		return "$" .. red_trick:getEffectiveId()
	end
	return "."
end
sgs.ai_skill_cardask["@nutao_black"] = function(self, data)
    local use = data:toCardUse()
	if use.card:isKindOf("IronChain") then return "." end
	local black_trick
	local cards = sgs.QList2Table(self.player:getCards("h"))
	self:sortByUseValue(cards, true)
	for _, card in ipairs(cards) do
		if self:getUseValue(card) < self:getUseValue(use.card) then
			if card:isKindOf("TrickCard") and card:isBlack() then
				black_trick = card
				break
			end
		end
	end
	if black_trick then
		return "$" .. black_trick:getEffectiveId()
	end
	return "."
end
--需求
sgs.ai_cardneed["Mnutao"] = function(to, card, self)
    return card:isNDTrick()
end
--[[
    【暗影】
]]--
--背刺
sgs.ai_skill_cardask["@beici_invoke"] = function(self, data)
    local equip
	local cards = sgs.QList2Table(self.player:getCards("he"))
	self:sortByUseValue(cards, true)
	for _, card in ipairs(cards) do
		if card:isKindOf("EquipCard") then
			equip = card
			break
		end
	end
	if equip then
	    return "$" .. equip:getEffectiveId()
	else
	    return "."
	end
end
sgs.ai_slash_prohibit["Mbeici"] = function(self, from, to, card)
	if to:hasShownSkill("Mbeici") and to:getMark("@yinni") > 0 then
	    return true
	end
	return false
end
--毒刃
sgs.ai_skill_invoke["Mduren"] = function(self, data)
	local damage = data:toDamage()
	if self:isFriend(damage.to) then
		return false
	end
	return true
end
--[[
    【环刃舞者】
]]--
--暗咒
sgs.ai_skill_invoke["Manzhou"] = function(self, data)
    local damage = data:toDamage()
	if self:isFriend(damage.to) then
	    return false
	end
	return true
end
--环舞
sgs.ai_skill_cardask["@huanwu_invoke"] = function(self, data)
	local weapon
	local cards = sgs.QList2Table(self.player:getCards("he"))
	self:sortByUseValue(cards, true)
	for _, card in ipairs(cards) do
		if card:isKindOf("Weapon") then
			weapon = card
			break
		end
	end
	if weapon then
	    local slash = sgs.cloneCard("slash")
		local x = 0
		for _, p in sgs.qlist(self.room:getOtherPlayers(self.player)) do
		    if p:hasShownOneGeneral() and not (self.player:isFriendWith(p) or self.player:willBeFriendWith(p)) and not p:inMyAttackRange(self.player) then
				if self:slashIsEffective(slash, p) and not self:slashProhibit(slash, p) and self:damageIsEffective(p, sgs.DamageStruct_Normal, self.player) then
					if self:isFriend(p) then
						x = x-1
					else
						x = x+1
					end
				end
			end
		end
		if x > 0 then
		    return "$" .. weapon:getEffectiveId()
		end
	end
	return "."
end
--[[
    【阴影凝视者】
]]--
--窥视
sgs.ai_skill_cardask["@kuishi_invoke"] = function(self, data)
    local target = data:toPlayer()
	if not target:hasShownOneGeneral() then return "." end
	local trick
	local cards = sgs.QList2Table(self.player:getHandcards())
	self:sortByUseValue(cards, true)
	for _, card in ipairs(cards) do
		if card:isKindOf("TrickCard") then
			trick = card
			break
		end
	end
	if trick then
		if self:isEnemy(target) and self.player:isWounded() then
		    return "$" .. trick:getEffectiveId()
		end
	end
	return "."
end
--折虐
sgs.ai_skill_invoke["Mzhenue"] = function(self, data)
	local use = data:toCardUse()
	if self:isFriend(use.from) then
	    return false
	end
	return true
end
sgs.ai_slash_prohibit["Mzhenue"] = function(self, from, to, card)
	if to:hasShownSkill("Mzhenue") and self:isEnemy(from, to) then
		if to:isWounded() then
			if card:isVirtualCard() then
				if not from:isKongcheng() and from:getHandcardNum() < 4 and (getCardsNum("Peach", from, from) > 0 or (not from:hasSkills(sgs.slash_benefit_skill) and getCardsNum("Jink", from, from) > 0)) then
					return true
				end
			else
				if from:getHandcardNum() > 1 and from:getHandcardNum() < 5 and (getCardsNum("Peach", from, from) > 0 or (not from:hasSkills(sgs.slash_benefit_skill) and getCardsNum("Jink", from, from) > 0)) then
					return true
				end
			end
		end
	end
	return false
end
--需求
sgs.ai_cardneed["Mkuishi"] = function(to, card, self)
    if to:getHandcardNum() < 4 then
	    return card:isKindOf("TrickCard")
	end
end
--[[
    【毒蝎狮】
]]--
--瘫痪
sgs.ai_skill_invoke["Mtanhuan"] = function(self, data)
	local damage = data:toDamage()
	if self:isEnemy(damage.to) then
	    return true
	end
	return false
end
--腐蚀
sgs.ai_skill_invoke["Mfushi"] = function(self, data)
	local target = data:toPlayer()
	if self:isFriend(target) then
	    if not (self:doNotDiscard(target, "e") or target:hasSkills(sgs.lose_equip_skill) or (target:isWounded() and target:getEquips():length() == 1 and target:hasArmorEffect("SilverLion"))) then
		    return false
		end
	else
	    if self:doNotDiscard(target, "e") or target:hasSkills(sgs.lose_equip_skill) or (target:isWounded() and target:getEquips():length() == 1 and target:hasArmorEffect("SilverLion")) then
	        return false
		end
	end
	return true
end
--溶解
sgs.ai_skill_invoke["Mrongjie"] = function(self, data)
	if self:getAllPeachNum() > 0 or self.player:getHp() > 0 then
	    return false
	end
	return true
end
--[[
    【无面者傀儡师】
]]--
--影击
sgs.ai_skill_invoke["Myingji"] = function(self, data)
	local damage = data:toDamage()
	if not self:isFriend(damage.to) then
		if damage.to:getHp() < 2 then return false end
	    if not (damage.to:isWounded() or self:hasHeavySlashDamage(self.player, damage.card, damage.to)) then
			self.room:setPlayerFlag(self.player, "yingji_choose_hp")
			return true
		else
			if not damage.to:isNude() and damage.to:getJudgingArea():length() == 0 then
				if damage.to:hasEquip() then
					if not (self:doNotDiscard(damage.to, "e") or damage.to:hasSkills(sgs.lose_equip_skill) or (damage.to:getEquips():length() == 1 and damage.to:isWounded() and damage.to:hasArmorEffect("SilverLion"))) and damage.to:getHandcardNum() > 2 then
						return true
					end
				else
					if damage.to:getHandcardNum() > 2 then
						return true
					end
				end
			end
		end
	else
		if damage.to:getJudgingArea():length() > 0 then
			return true
		else
			if damage.to:hasEquip() then
				if self:doNotDiscard(damage.to, "e") or damage.to:hasSkills(sgs.lose_equip_skill) or (damage.to:getEquips():length() == 1 and damage.to:isWounded() and damage.to:hasArmorEffect("SilverLion")) then
					return true
				end
			end
		end
		if (damage.to:getLostHp() > 1 or (damage.to:isWounded() and self:hasHeavySlashDamage(self.player, damage.card, damage.to))) and getCardsNum("Peach", damage.to, self.player) == 0 then
		    self.room:setPlayerFlag(self.player, "yingji_choose_hp")
			return true
		end
	end
	return false
end
sgs.ai_skill_choice["Myingji"] = function(self, choices, data)
	if self.player:hasFlag("yingji_choose_hp") then
	    self.room:setPlayerFlag(self.player, "-yingji_choose_hp")
		return "yingji_hp"
	end
	return "yingji_throw"
end
sgs.ai_skill_choice["yingji_throw"] = function(self, choices, data)
	if self.player:getJudgingArea():length() > 0 then
		return "yingji_judge"
	else
		if self.player:hasEquip() then
			if (self:doNotDiscard(self.player, "e") or self.player:hasSkills(sgs.lose_equip_skill) or (self.player:getEquips():length() == 1 and self.player:isWounded() and self.player:hasArmorEffect("SilverLion"))) or self.player:getHandcardNum() > 2 then
				return "yingji_equip"
			else
				if self.player:isKongcheng() then
					return "yingji_equip"
				else
					return "yingji_hand"
				end
			end
		else
			return "yingji_hand"
		end
	end
	return "."
end
--操纵
sgs.ai_skill_invoke["Mcaozong"] = function(self, data)
    local target
	local targets = sgs.QList2Table(self.room:getAlivePlayers())
	self:sort(targets, "handcard")
	for _, p in ipairs(targets) do
		if self:isEnemy(p) then
			if p:hasShownOneGeneral() and not (self.player:isFriendWith(p) or self.player:willBeFriendWith(p)) and self.player:inMyAttackRange(p) and p:getMark("caozong") == 0 then
				target = p
				self.room:setPlayerFlag(p, "caozong_target")
				break
			end
		end
	end
	if target then
	    return true
	end
end
sgs.ai_skill_playerchosen["Mcaozong"] = function(self, targets)
    local target
	for _, p in sgs.qlist(self.room:getOtherPlayers(self.player)) do
		if p:hasFlag("caozong_target") then
		    target = p
			self.room:setPlayerFlag(p, "-caozong_target")
			break
		end
	end
	return target
end
--侵袭
sgs.ai_skill_cardask["@qinxi_invoke"] = function(self, data)
    local target = self.player:getNextAlive()
	if self:isFriend(target) then return "." end
	local handcard
	local cards = sgs.QList2Table(self.player:getHandcards())
	self:sortByUseValue(cards, true)
	for _, card in ipairs(cards) do
		if not card:isKindOf("Peach") then
			handcard = card
			break
		end
	end
	if handcard then
		return "$" .. handcard:getEffectiveId()
	end
	return "."
end
--[[
    【牛头卫士】
]]--
--先攻
sgs.ai_skill_invoke["Mxiangong"] = true
--压制
sgs.ai_skill_invoke["Myazhi"] = true
--需求
sgs.ai_cardneed["Mxiangong"] = function(to, card, self)
    if to:getHandcardNum() < 4 then
	    return card
	end
end
--[[
    【黑龙】
]]--
--龙息
sgs.ai_skill_invoke["Mlongxi"] = function(self, data)
	local target
	local x = self.player:getHandcardNum() - self.player:getHp()
	if x < 3 then
	    local slash = sgs.cloneCard("fire_slash")
		local targets = sgs.QList2Table(self.room:getOtherPlayers(self.player))
		self:sort(targets)
		for _, p in ipairs(targets) do
		    if not self.player:inMyAttackRange(p) and self:isEnemy(p) then
				if self:slashIsEffective(slash, p) and self:damageIsEffective(p, sgs.DamageStruct_Fire, self.player) and not self:slashProhibit(slash, p) then
					target = p
					self.room:setPlayerFlag(p, "longxi_target")
				end
			end
		end
	end
	if target then
	    return true
	end
	return false
end
sgs.ai_skill_playerchosen["Mlongxi"] = function(self, targets)
    local target
	for _, p in sgs.qlist(self.room:getOtherPlayers(self.player)) do
		if p:hasFlag("longxi_target") then
		    target = p
			self.room:setPlayerFlag(p, "-longxi_target")
			break
		end
	end
	if target then
		return target
	end
	return nil
end
sgs.ai_playerchosen_intention["Mlongxi"] = 40
--龙鳞
sgs.ai_skill_invoke["Mlonglin"] = function(self, data)
	local use = data:toCardUse()
	if use.card:isKindOf("GodSalvation") or use.card:isKindOf("AmazingGrace") or use.card:isKindOf("AwaitExhausted") or (self:isFriend(use.from) and (use.card:isKindOf("BefriendAttacking") or use.card:isKindOf("IronChain") or use.card:isKindOf("Dismantlement") or use.card:isKindOf("Snatch"))) then
		return false
	end
	return true
end
--[[
    【虚空化身】
]]--
--否定
sgs.ai_skill_invoke["Mfouding"] = function(self, data)
    local target = data:toPlayer()
	if self:isFriend(target) then
	    return false
	end
	return true
end
--黑镜
sgs.ai_skill_invoke["Mheijing"] = function(self, data)
	local damage = data:toDamage()
	if self.player:isWounded() then
		if self:isFriend(damage.from) and self.player:getHp() > damage.from:getHp() then
			return false
		end
	end
	return true
end
--[[
    【玛拉萨】
]]--
--低吟
sgs.ai_skill_invoke["Mdiyin"] = function(self, data)
	local target = data:toPlayer()
	local x = self.player:getHandcardNum()/2
	local y = target:getHandcardNum()
	if self:isFriend(target) then
		if self.player:isFriendWith(target) or (x > y) then
			return true
		end
	else
		if x < y then
			return true
		end
	end
	return false
end
sgs.ai_skill_choice["Mdiyin"] = function(self, choices, data)
	local target = data:toPlayer()
	local x = self.player:getHandcardNum()/2
	local y = target:getHandcardNum()
	local x = 0
	for _, card in sgs.qlist(self.player:getHandcards()) do
		if card:isRed() then
			x = x+1
		elseif card:isBlack() then
			x = x-1
		end
	end
	if self:isFriend(target) then
		if x >= 0 then
			return "diyin_black"
		else
			return "diyin_red"
		end
	else
		if x >= 0 then
			return "diyin_red"
		else
			return "diyin_black"
		end
	end
end
--渊识
sgs.ai_skill_cardask["@yuanshi_invoke"] = function(self, data)
	local weapon, armor, defense, offense
	local cards = sgs.QList2Table(self.player:getCards("he"))
	self:sortByUseValue(cards, true)
	for _, card in ipairs(cards) do
		if card:isKindOf("Weapon") and not weapon then
			weapon = card
		elseif card:isKindOf("Armor") and not armor then
			armor = card
		elseif card:isKindOf("OffensiveHorse") and not offense then
			offense = card
		elseif card:isKindOf("DefensiveHorse") and not defense then
			defense = card
		end
	end
	if weapon or armor or defense or offense then
		local targets = sgs.QList2Table(self.room:getOtherPlayers(self.player))
		self:sort(targets)
		for _, p in ipairs(targets) do
			if self:isFriend(p) then
				if not (p:hasShownOneGeneral() and not self.player:isFriendWith(p)) then
				    if weapon and not p:getWeapon() then
					    self.room:setPlayerFlag(self.player, "yuanshi_weapon")
						self.room:setPlayerFlag(p, "yuanshi_target")
						break
					elseif offense and not p:getOffensiveHorse() then
					    self.room:setPlayerFlag(self.player, "yuanshi_offense")
						self.room:setPlayerFlag(p, "yuanshi_target")
						break
					elseif defense and not p:getDefensiveHorse() then
					    self.room:setPlayerFlag(self.player, "yuanshi_defense")
						self.room:setPlayerFlag(p, "yuanshi_target")
						break
					elseif armor and not p:getArmor() then
					    self.room:setPlayerFlag(self.player, "yuanshi_armor")
						self.room:setPlayerFlag(p, "yuanshi_target")
						break
					end
				end
			end
		end
		if self.player:hasFlag("yuanshi_weapon") then
			self.room:setPlayerFlag(self.player, "-yuanshi_weapon")
			return "$" .. weapon:getEffectiveId()
		elseif self.player:hasFlag("yuanshi_offense") then
		    self.room:setPlayerFlag(self.player, "-yuanshi_offense")
			return "$" .. offense:getEffectiveId()
		elseif self.player:hasFlag("yuanshi_defense") then
		    self.room:setPlayerFlag(self.player, "-yuanshi_defense")
			return "$" .. defense:getEffectiveId()
		elseif self.player:hasFlag("yuanshi_armor") then
		    self.room:setPlayerFlag(self.player, "-yuanshi_armor")
			return "$" .. armor:getEffectiveId()
		end
	end
	local x = self.player:getMaxHp() - self.player:getHandcardNum()
	if x < 2 then return "." end
	local hand_weapon, hand_armor, hand_defense, hand_offense
	local cards = sgs.QList2Table(self.player:getCards("h"))
	self:sortByUseValue(cards, true)
	for _, card in ipairs(cards) do
		if card:isKindOf("Weapon") and not weapon then
			hand_weapon = card
		elseif card:isKindOf("Armor") and not armor then
			hand_armor = card
		elseif card:isKindOf("OffensiveHorse") and not offense then
			hand_offense = card
		elseif card:isKindOf("DefensiveHorse") and not defense then
			hand_defense = card
		end
	end
	if hand_weapon or hand_armor or hand_defense or hand_offense then
		local targets = sgs.QList2Table(self.room:getOtherPlayers(self.player))
		self:sort(targets)
		for _, p in ipairs(targets) do
			if self:isEnemy(p) and p:hasShownOneGeneral() and not self.player:isFriendWith(p) then
				if getCardsNum("EquipCard", p, self.player) > 0 or (getCardsNum("Peach", p, self.player) and p:isWounded()) then
					if hand_weapon and not p:getWeapon() then
					    self.room:setPlayerFlag(self.player, "yuanshi_weapon")
						self.room:setPlayerFlag(p, "yuanshi_target")
						break
					elseif hand_offense and not p:getOffensiveHorse() then
					    self.room:setPlayerFlag(self.player, "yuanshi_offense")
						self.room:setPlayerFlag(p, "yuanshi_target")
						break
					elseif hand_defense and not p:getDefensiveHorse() then
					    self.room:setPlayerFlag(self.player, "yuanshi_defense")
						self.room:setPlayerFlag(p, "yuanshi_target")
						break
					elseif hand_armor and not p:getArmor() then
					    self.room:setPlayerFlag(self.player, "yuanshi_armor")
						self.room:setPlayerFlag(p, "yuanshi_target")
						break
					end
				end
			end
		end
		if self.player:hasFlag("yuanshi_weapon") then
			self.room:setPlayerFlag(self.player, "-yuanshi_weapon")
			return "$" .. hand_weapon:getEffectiveId()
		elseif self.player:hasFlag("yuanshi_offense") then
		    self.room:setPlayerFlag(self.player, "-yuanshi_offense")
			return "$" .. hand_offense:getEffectiveId()
		elseif self.player:hasFlag("yuanshi_defense") then
		    self.room:setPlayerFlag(self.player, "-yuanshi_defense")
			return "$" .. hand_defense:getEffectiveId()
		elseif self.player:hasFlag("yuanshi_armor") then
		    self.room:setPlayerFlag(self.player, "-yuanshi_armor")
			return "$" .. hand_armor:getEffectiveId()
		end
	end
	return "."
end
sgs.ai_skill_playerchosen["Myuanshi"] = function(self, targets)
    local target
	for _, p in sgs.qlist(self.room:getOtherPlayers(self.player)) do
		if p:hasFlag("yuanshi_target") then
		    target = p
			self.room:setPlayerFlag(p, "-yuanshi_target")
			break
		end
	end
	return target
end