--[[********************************************************
    这是 忧郁の月兔 制作的【英雄无敌Ⅵ-亚山之殇-英】的AI文件
]]--********************************************************
--[[
    【禁卫】
]]--
--守卫
sgs.ai_skill_cardask["@shouwei_invoke"] = function(self, data)
    local not_equip
	local cards = sgs.QList2Table(self.player:getHandcards())
	self:sortByUseValue(cards, true)
	for _, card in ipairs(cards) do
		if not card:isKindOf("EquipCard") and not card:isKindOf("Peach") then
		    not_equip = card
			break
		end
	end
	if not not_equip then return "." end
	local damage = data:toDamage()
	local slash = sgs.cloneCard("slash")
	local invoke = false
	if self:isFriend(damage.to) then
	    if damage.from then
		    if self:isFriend(damage.from) then
				if self.player:inMyAttackRange(damage.from) then
				    if not (self:slashIsEffective(slash, damage.from) and self:damageIsEffective(damage.from, sgs.DamageStruct_Normal, self.player) and not self:slashProhibit(slash, damage.from)) then
					    if damage.nature == sgs.DamageStruct_Normal then
    						if self.player:getHp() > 1 or damage.damage >= damage.to:getHp() or damage.damage > 1 then
						        invoke = true
							end
						else
						    if self.player:getHp() > damage.damage and damage.damage >= damage.to:getHp() then
						        invoke = true
							end
						end
					end
				else
				    if damage.nature == sgs.DamageStruct_Normal then
    					if self.player:getHp() > 1 or damage.damage >= damage.to:getHp() or damage.damage > 1 then
						    invoke = true
						end
					else
						if self.player:getHp() > damage.damage and damage.damage >= damage.to:getHp() then
						    invoke = true
						end
					end
				end
			end
			if self:isEnemy(damage.from) then
			    if self.player:inMyAttackRange(damage.from) then
				    if not (self:slashIsEffective(slash, damage.from) and self:damageIsEffective(damage.from, sgs.DamageStruct_Normal, self.player) and not self:slashProhibit(slash, damage.from) and not (damage.from:hasArmorEffect("Vine") and self.player:hasWeapon("Fan"))) then
					    if damage.nature == sgs.DamageStruct_Normal then
    						if self.player:getHp() > 1 or damage.damage >= damage.to:getHp() or damage.damage > 1 then
						        invoke = true
							end
						else
						    if self.player:getHp() > damage.damage and damage.damage >= damage.to:getHp() then
						        invoke = true
							end
						end
					else
					    if damage.nature == sgs.DamageStruct_Normal then
						    if self.player:getHp() > 1 or damage.damage >= damage.to:getHp() or damage.damage > 1 then
							    invoke = true
							end
						else
						    if self.player:getHp() > damage.damage then
							    invoke = true
							end
						end
					end
				else
				    if damage.nature == sgs.DamageStruct_Normal then
    					if self.player:getHp() > 1 or damage.damage >= damage.to:getHp() or damage.damage > 1 then
						    invoke = true
						end
					else
						if self.player:getHp() > damage.damage and damage.damage >= damage.to:getHp() then
						    invoke = true
						end
					end
				end
			end
		else
		    if damage.nature == sgs.DamageStruct_Normal then
    			if self.player:getHp() > 1 or damage.damage >= damage.to:getHp() or damage.damage > 1 then
					invoke = true
				end
			else
				if self.player:getHp() > damage.damage and damage.damage >= damage.to:getHp() then
					invoke = true
				end
			end
		end
	end
	if invoke then
	    return "$" .. not_equip:getEffectiveId()
	end
	return "."
end
--巨盾
sgs.ai_skill_invoke["Mjudun"] = true
--需求
sgs.ai_cardneed["Mshouwei"] = function(to, card, self)
    if card:isKindOf("BaiscCard") then
	    return to:getHandcardNum() < 3
	end
end
--[[
    【神弩手】
]]--
--贯穿
sgs.ai_skill_invoke["Mguanchuan"] = function(self, data)
	local damage = data:toDamage()
	local dest = damage.to:getNextAlive()
	if self:isEnemy(dest) then
	    if self:slashIsEffective(damage.card, dest) and not self:slashProhibit(damage.card, dest) then
		    if damage.card:isKindOf"FireSlash" and self:damageIsEffective(dest, sgs.DamageStruct_Normal, self.player) then
			    self.room:setPlayerFlag(self.player, "choice_chuan")
				return true
			elseif damage.card:isKindOf"ThunderSlash" and self:damageIsEffective(dest, sgs.DamageStruct_Thunder, self.player) then
			    self.room:setPlayerFlag(self.player, "choice_chuan")
				return true
			else
			    if self:damageIsEffective(dest, sgs.DamageStruct_Normal, self.player) and not (dest:hasArmorEffect("Vine") and not self.player:hasWeapon("Fan")) then
				    self.room:setPlayerFlag(self.player, "choice_chuan")
					return true
				end
			end
		end
	else
	    if damage.to:isAlive() and damage.to:hasEquip() then
	        if self:isFriend(damage.to) then
			    if self:doNotDiscard(damage.to, "e") or damage.to:hasShownSkills(sgs.lose_equip_skill) or (damage.to:isWounded() and damage.to:getEquips():length() == 1 and damage.to:hasArmorEffect("SilverLion")) then
				    return true
				end
			else
--			    if not (self:doNotDiscard(damage.to, "e") or damage.to:hasShownSkills(sgs.lose_equip_skill) or (damage.to:isWounded() and damage.to:getEquips():length() == 1 and damage.to:hasArmorEffect("SilverLion"))) then
				    return true
--				end
			end
		end
	end
	return false
end
sgs.ai_skill_choice["Mguanchuan"] = function(self, choices, data)
	if self.player:hasFlag("choice_chuan") then
	    self.room:setPlayerFlag(self.player, "-choice_chuan")
		return "chuan"
	else
	    return "guan"
	end
end
sgs.ai_skill_choice["guan_what"] = function(self, choices, data)
    local target = data:toPlayer()
	if target:getArmor() then
	    return "guan_armor"
	elseif target:getDefensiveHorse() then
	    return "guan_def"
	else
	    return "guan_off"
	end
	return "."
end
--神弩（已在smart-ai添加）
--需求
sgs.ai_cardneed["Mshennu"] = function(to, card, self)
	local has_weapon = to:getWeapon()
	local slash_num = 0
	for _, c in sgs.qlist(to:getHandcards()) do
		local flag = string.format("%s_%s_%s", "visible", self.room:getCurrent():objectName(), to:objectName())
		if c:hasFlag("visible") or c:hasFlag(flag) then
			if c:isKindOf("Weapon") then
				has_weapon = true
			end
			if c:isKindOf("Slash") then slash_num = slash_num + 1 end
		end
	end
	if not has_weapon then
		return card:isKindOf("Weapon")
	else
		return card:isKindOf("Slash") or (slash_num > 1 and card:isKindOf("Analeptic"))
	end
end
--[[
    【女神官】
]]--
--治愈
sgs.ai_skill_invoke["Mzhiyu"] = function(self, data)
    local target
	local targets = sgs.QList2Table(self.room:getOtherPlayers(self.player))
    self:sort(targets, "hp")
	for _, p in ipairs(targets) do
		if self:isFriend(p) then
		    if p:getLostHp() > 1 then
				target = p
				break
			end
		end
	end
	if target then
	    self.room:setPlayerFlag(target, "zhiyu_target")
	    return true
	end
	return false
end
sgs.ai_skill_playerchosen["Mzhiyu"] = function(self, targets)
    local target
	for _, p in sgs.qlist(self.room:getOtherPlayers(self.player)) do
		if p:hasFlag("zhiyu_target") then
		    target = p
			self.room:setPlayerFlag(target, "-zhiyu_target")
		end
	end
	return target
end
sgs.ai_playerchosen_intention["Mzhiyu"] = -40
--平和
sgs.ai_skill_invoke["Mpinghe"] = function(self, data)
	local damage = data:toDamage()
	if self:isFriend(damage.to) then
		return false
	end
	return true
end
--信仰
sgs.ai_skill_invoke["Mxinyang"] = true
--需求
sgs.ai_cardneed["Mzhiyu"] = function(to, card, self)
	return to:getHandcardNum() < 3 and card:isKindOf("Jink")
end
sgs.ai_cardneed["Mxinyang"] = function(to, card, self)
	return to:isKongcheng()
end
--[[
    【皇家狮鹫】
]]--
--反击
sgs.ai_skill_invoke["Mfanji"] = function(self, data)
	local damage = data:toDamage()
	local slash = sgs.cloneCard("slash")
	local invoke = false
	if self:isEnemy(damage.from) then
	    if self:slashIsEffective(slash, damage.from) and self:damageIsEffective(damage.from, sgs.DamageStruct_Normal, self.player) and not self:slashProhibit(slash, damage.from) and not (damage.from:hasArmorEffect("Vine") and not self.player:hasWeapon("Fan")) then
		    invoke = true
		end
	end
	if invoke then
	    return true
	end
	return false
end
sgs.ai_skill_cardask["@fanji_invoke"] = function(self, data)
    local basic
	local invoke = false
	local cards = sgs.QList2Table(self.player:getHandcards())
	self:sortByUseValue(cards, true)
	for _, card in ipairs(cards) do
		if card:isKindOf("BasicCard") and not card:isKindOf("Peach") then
		    basic = card
			break
		end
	end
	if not basic then return "." end
	local damage = data:toDamage()
	local slash = sgs.cloneCard("slash")
	local invoke = false
	if self:isEnemy(damage.from) then
	    if self:slashIsEffective(slash, damage.from) and self:damageIsEffective(damage.from, sgs.DamageStruct_Normal, self.player) and not self:slashProhibit(slash, damage.from) and not (damage.from:hasArmorEffect("Vine") and not self.player:hasWeapon("Fan")) then
		    invoke = true
		end
	end
	if invoke then
	    return "$" .. basic:getEffectiveId()
	end
	return "."
end
sgs.ai_slash_prohibit["Mfanji"] = function(self, from, to, card)
	local slash = sgs.cloneCard("slash")
	if to:hasShownSkill("Mfanji") and self:isWeak(from) and self:isEnemy(from, to) and not self:isWeak(to) and to:getHandcardNum() > 1 then
		if self:slashIsEffective(slash, from) and self:damageIsEffective(from, sgs.DamageStruct_Normal, to) and not self:slashProhibit(slash, from) and not (from:hasArmorEffect("Vine") and not to:hasWeapon("Fan")) then
			if not (getCardsNum("BasicCard", to, from) > 0) then
				return true
			end
		end
	end
	return false
end
--俯冲
sgs.ai_skill_invoke["Mfuchong"] = function(self, data)
	local target
    local slash = sgs.cloneCard("slash")
	local targets = sgs.QList2Table(self.room:getOtherPlayers(self.player))
    self:sort(targets, "hp")
	for _, p in ipairs(targets) do
	    if self:isEnemy(p) then
    		if self:slashIsEffective(slash, p) and self:damageIsEffective(p, sgs.DamageStruct_Normal, self.player) and not self:slashProhibit(slash, p) and not (p:hasArmorEffect("Vine") and not self.player:hasWeapon("Fan")) then
			    target = p
				break
			end
		end
	end
	if target then
		return true
	end
	return false
end
sgs.ai_skill_invoke["#Mfuchong_avoid"] = true
sgs.ai_slash_prohibit["Mfuchong"] = function(self, from, to, card)
	if to:hasShownSkill("Mfuchong") and not to:faceUp() then
	    return true
	end
	return false
end
sgs.ai_skill_playerchosen["Mfuchong"] = function(self, targets)
    local target
    local slash = sgs.cloneCard("slash")
	local targets = sgs.QList2Table(self.room:getOtherPlayers(self.player))
    self:sort(targets, "hp")
	for _, p in ipairs(targets) do
	    if self:isEnemy(p) then
    		if self:slashIsEffective(slash, p) and self:damageIsEffective(p, sgs.DamageStruct_Normal, self.player) and not self:slashProhibit(slash, p) and not (p:hasArmorEffect("Vine") and not self.player:hasWeapon("Fan")) then
			    target = p
				break
			end
		end
	end
	if not target then
	    for _, p in sgs.qlist(self.room:getOtherPlayers(self.player)) do
		    if self:isEnemy(p) then
			    return p
			end
		end
	end
	return target
end
sgs.ai_playerchosen_intention["Mfuchong"] = 40
--需求
sgs.ai_cardneed["Mfanji"] = function(to, card, self)
	return to:getHandcardNum() < 3 and card:isKindOf("BasicCard")
end
--[[
    【耀灵】
]]--
--光速
sgs.ai_skill_invoke["Mguangsu"] = true
sgs.ai_skill_choice["Mguangsu"] = function(self, choices, data)
	return "gs_yes"
end
sgs.ai_slash_prohibit["Mguangsu"] = function(self, from, to, card)
	if to:hasShownSkill("Mguangsu") and not from:hasSkills(sgs.slash_benefit_skill) and to:getHp() == to:getHandcardNum() and not (from:hasWeapon("axe") and from:getEquips():length()+from:getHandcardNum() > 2) then
	    return true
	end
	return false
end
--耀击
sgs.ai_skill_invoke["Myaoji"] = function(self, data)
    local damage = data:toDamage()
	if self:isEnemy(damage.to) then
	    if not (damage.to:isWounded() or self:hasHeavySlashDamage(self.player, damage.card, damage.to)) then
			return true
		else
		    if damage.to:getMark("@yaojibasic") == 0 then
				local n = math.random(1,4)
				if n == 1 and damage.damage < damage.to:getHp() then
					return true
				end
			end
		end
	elseif self:isFriend(damage.to) then
		if (damage.to:getLostHp() > 1 or (damage.to:isWounded() and self:hasHeavySlashDamage(self.player, damage.card, damage.to))) and getCardsNum("Peach", damage.to, self.player) == 0 then
			return true
		end
	end
	return false
end
sgs.ai_skill_choice["Myaoji"] = function(self, choices, data)
    local damage = data:toDamage()
	if self:isFriend(damage.to) then
		return "yaoji1"
	else
		if not damage.to:isWounded() then
			return "yaoji1"
		end
	end
	return "yaoji2"
end
--需求
sgs.ai_cardneed["Mguangsu"] = function(to, card, self)
	return to:getHandcardNum() < to:getHp()
end
--[[
    【烈日十字军】
]]--
--冲锋
sgs.ai_skill_invoke["Mchongfeng"] = function(self, data)
	local damage = data:toDamage()
	if self:isFriend(damage.to) then
		return false
	end
	return true
end
--荣光
sgs.ai_skill_cardask["@rongguang_invoke"] = function(self, data)
	if self:getAllPeachNum() > 0 or self.player:getHp() == 1 then return "." end
	local dying = data:toDying()
	if dying.who:getHp() > 0 then return "." end
	local usecard
	local invoke = false
	local cards = sgs.QList2Table(self.player:getHandcards())
	self:sortByUseValue(cards, true)
	for _, card in ipairs(cards) do
		if not card:isKindOf("Peach") then
		    usecard = card
			break
		end
	end
	if usecard  then
	    return "$" .. usecard:getEffectiveId()
	end
	return "."
end
--神驹
sgs.ai_skill_invoke["Mshenju"] = true
--[[
    【昊天使】
]]--
--审判
sgs.ai_skill_invoke["Mshenpan"] = true
--怜悯（已在smart-ai中添加）
--夙愿
sgs.ai_skill_invoke["Msuyuan"] = function(self, data)
    local targets = sgs.QList2Table(self.room:getOtherPlayers(self.player))
	self:sort(targets, "hp", true)
	for _, p in ipairs(targets) do
	    if p:hasShownOneGeneral() and not (self.player:isFriendWith(p) or self.player:willBeFriendWith(p)) and self:isEnemy(p) and p:getHp() > self.player:getHp() then
		    self.room:setPlayerFlag(p, "suyuan_target")
			return true
		end
	end
	return false
end
sgs.ai_skill_playerchosen["Msuyuan"] = function(self, targets)
    local target
	for _, p in sgs.qlist(self.room:getOtherPlayers(self.player)) do
		if p:hasFlag("suyuan_target") then
		    target = p
			self.room:setPlayerFlag(target, "-suyuan_target")
			break
		end
	end
	return target
end
sgs.ai_playerchosen_intention["Msuyuan"] = 80
--需求
sgs.ai_cardneed["Mlianmin"] = function(to, card, self)
	if to:getHandcardNum() < 3 then
	    return card:getSuit() == sgs.Card_Club
	end
end
--保留值
sgs.Mlianmin_suit_value = {
	heart = 3.9,
	spade = 2,
	club = 7.7,
	diamond = 2.2,
}
--[[
    【米迦勒】
]]--
--圣言
sgs.ai_skill_cardask["@shengyan_invoke"] = function(self, data)
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
	end
	return "."
end
sgs.ai_skill_playerchosen["Mshengyan_red"] = function(self, targets)
	local target
	local targets = sgs.QList2Table(self.room:getAlivePlayers())
    self:sort(targets, "hp")
	for _, p in ipairs(targets) do
		if p:hasShownOneGeneral() and self.player:isFriendWith(p) then
		    if p:getLostHp() > 1 then
				target = p
				break
			end
		end
	end
	if not target then
		self:sort(targets, "handcard")
		for _, p in ipairs(targets) do
			if p:hasShownOneGeneral() and self.player:isFriendWith(p) and p:getHandcardNum() < 2 then
				target = p
				break
			end
		end
		if not target then
			target = self.player
			return target
		end
	end
end
sgs.ai_playerchosen_intention["Mshengyan_red"] = -40
sgs.ai_skill_choice["Mshengyan"] = function(self, choices, data)
    local target = data:toPlayer()
	if target:objectName() ~= self.player:objectName() then
		if target:getLostHp() > 1 then
			return "sy_recover"
		end
	else
		if target:getLostHp() > 1 and self:getCardsNum("Peach") == 0 then
			return "sy_recover"
		end
	end
	return "sy_draw"
end
sgs.ai_skill_playerchosen["Mshengyan_club"] = function(self, targets)
	local target = self:findPlayerToDiscard("hej", false)
	if target then
	    return target
	end
end
sgs.ai_playerchosen_intention["Msuyuan"] = 20
--光耀
sgs.ai_skill_invoke["Mguangyao"] = true
sgs.ai_skill_choice["Mguangyao"] = function(self, choices, data)
	if self.player:getHandcardNum() > 1 and not self:getCard("Analeptic", self.player) then
	    return "gy_hand"
	end
	return "gy_draw"
end
--黎明
sgs.ai_skill_invoke["Mliming"] = true
--需求
sgs.ai_cardneed["Mshengyan"] = function(to, card, self)
	return card:isKindOf("EquipCard")
end
--[[
    【艾尔拉斯】
]]--
--辉耀（无需ai）
--正义
sgs.ai_skill_invoke["Mzhengyi"] = function(self, data)
    local damage = data:toDamage()
	if self:isFriend(damage.to) then
	    if not self:isFriend(damage.from) then
		    if not (self:isEnemy(damage.from) and self.player:getLostHp() == 1 and damage.from:hasEquip() and self:doNotDiscard(damage.to, "e") or damage.to:hasShownSkills(sgs.lose_equip_skill) or (damage.to:isWounded() and damage.to:getEquips():length() == 1 and damage.to:hasArmorEffect("SilverLion"))) then
			    return true
			end
		else
			if damage.from:isNude() then
				return true
			end
		end
	end
	return false
end
--[[
    【碎击兵】
]]--
--饮血
sgs.ai_skill_invoke["Myinxue"] = true
--蹈锋
sgs.ai_skill_invoke["Mdaofeng"] = true
--强攻
sgs.ai_skill_invoke["Mqianggong"] = function(self, data)
    local effect = data:toSlashEffect()
	local slash = sgs.cloneCard("thunder_slash")
	if self:isEnemy(effect.to) then
	    if self:slashIsEffective(slash, effect.to) and self:damageIsEffective(effect.to, sgs.DamageStruct_Thunder, self.player) and not self:slashProhibit(slash, effect.to) then
		    return true
		end
	end
	return false
end
--[[
    【地精猎手】
]]--
--逃窜
sgs.ai_skill_invoke["Mtaocuan"] = true
--狡黠
sgs.ai_skill_invoke["Mjiaoxia"] = true
--陷阱
sgs.ai_skill_invoke["Mxianjing"] = true
sgs.ai_skill_choice["Mxianjing"] = function(self, choices, data)
    local use = data:toCardUse()
	if self:isEnemy(use.from) then
		if use.card:isKindOf("Duel") then
			if self:getCardsNum("Slash") > 0 and not self:isWeak(self.player) then
				return "xianjing_harm"
			end
		else
			if self:getCardsNum("Jink") > 0 and not self:isWeak(self.player) then
				return "xianjing_harm"
			end
		end
	end
	return "xianjing_def"
end
sgs.ai_slash_prohibit["Mxianjing"] = function(self, from, to, card)
	if self:isWeak(from) and self:isEnemy(from, to) and not self:isWeak(to) and to:getPile("tao"):length() > 0 then
		return true
	end
	return false
end
--需求
sgs.ai_cardneed["Mtaocuan"] = function(to, card, self)
	return to:isKongcheng()
end
--[[
    【鸢妖】
]]--
--往返
sgs.ai_skill_playerchosen["Mwangfan"] = function(self, data)
    local target
	local slash = sgs.Sanguosha:cloneCard("slash")
	local targets = sgs.QList2Table(self.room:getOtherPlayers(self.player))
	self:sort(targets, "handcard")
	for _,p in ipairs(targets) do
	    if self:isEnemy(p) then
		    if not p:isKongcheng() and self:slashIsEffective(slash, p) and self:damageIsEffective(p, sgs.DamageStruct_Thunder, self.player) and not self:slashProhibit(slash, p) and not (p:hasArmorEffect("Vine") and not self.player:hasWeapon("Fan")) then
				target = p
				break
			end
		end
	end
	if not target then
		for _,p in ipairs(targets) do
			if self:isEnemy(p) and not p:isKongcheng() then
				if p:getHp() > self.player:getHp() then
					target = p
					break
				end
			end
		end
	end
	if target then
		return target
	end
	return nil
end
sgs.ai_playerchosen_intention["Mwangfan"] = 40
--灵禽
sgs.ai_skill_cardask["@lingqin_red"] = function(self, data)
	local target = data:toPlayer()
	local red
	local cards = sgs.QList2Table(self.player:getCards("h"))
	self:sortByUseValue(cards, true)
	for _, card in ipairs(cards) do
		if card:isRed() and not card:isKindOf("Peach") then
			red = card
			break
		end
	end
	if red and self:isEnemy(target) then
	    return "$" .. red:getEffectiveId()
	end
	return "."
end
sgs.ai_skill_cardask["@lingqin_black"] = function(self, data)
	local target = data:toPlayer()
	local black
	local cards = sgs.QList2Table(self.player:getCards("h"))
	self:sortByUseValue(cards, true)
	for _, card in ipairs(cards) do
		if card:isBlack() then
			black = card
			break
		end
	end
	if black and self:isEnemy(target) then
	    return "$" .. black:getEffectiveId()
	end
	return "."
end
sgs.ai_slash_prohibit["Mlingqin"] = function(self, from, to, card)
	if not to:hasShownSkill("Mlingqin") then return false end
	local lingqin_card
	for _, cd in sgs.qlist(from:getHandcards()) do
		if cd:getEffectiveId() ~= card:getEffectiveId() and not cd:isKindOf("Peach") then
			if (card:isRed() and cd:isRed()) or (card:isBlack() and cd:isBlack()) then
				lingqin_card = cd
				break
			end
		end
	end
	if not lingqin_card then return true end
end
--[[
    【掠梦巫】
]]--
--天地
sgs.ai_skill_cardask["@tiandi_heart"] = function(self, data)
    local use = data:toCardUse()
	local target = use.from
	local has_card
	if not self:isEnemy(target) then return "." end
	local can_invoke
	for _,p in sgs.qlist(use.to) do
		if self:isFriend(p) then
			can_invoke = true
			break
		end
	end
	if not can_invoke then return "." end
	local cards = sgs.QList2Table(self.player:getHandcards())
	self:sortByUseValue(cards, true)
	for _,cd in ipairs(cards) do
	    if not cd:isKindOf("EquipCard") and cd:getSuit() == sgs.Card_Heart and not cd:isKindOf("Peach") then
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
sgs.ai_skill_cardask["@tiandi_diamond"] = function(self, data)
    local use = data:toCardUse()
	local target = use.from
	local has_card
	if not self:isEnemy(target) then return "." end
	local can_invoke
	for _,p in sgs.qlist(use.to) do
		if self:isFriend(p) then
			can_invoke = true
			break
		end
	end
	if not can_invoke then return "." end
	local cards = sgs.QList2Table(self.player:getHandcards())
	self:sortByUseValue(cards, true)
	for _,cd in ipairs(cards) do
	    if not cd:isKindOf("EquipCard") and cd:getSuit() == sgs.Card_Diamond and not cd:isKindOf("Peach") then
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
sgs.ai_skill_cardask["@tiandi_spade"] = function(self, data)
    local use = data:toCardUse()
	local target = use.from
	local has_card
	if not self:isEnemy(target) then return "." end
	local can_invoke
	for _,p in sgs.qlist(use.to) do
		if self:isFriend(p) then
			can_invoke = true
			break
		end
	end
	if not can_invoke then return "." end
	local cards = sgs.QList2Table(self.player:getHandcards())
	self:sortByUseValue(cards, true)
	for _,cd in ipairs(cards) do
	    if not cd:isKindOf("EquipCard") and cd:getSuit() == sgs.Card_Spade then
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
sgs.ai_skill_cardask["@tiandi_club"] = function(self, data)
   local use = data:toCardUse()
	local target = use.from
	local has_card
	if not self:isEnemy(target) then return "." end
	local can_invoke
	for _,p in sgs.qlist(use.to) do
		if self:isFriend(p) then
			can_invoke = true
			break
		end
	end
	if not can_invoke then return "." end
	local cards = sgs.QList2Table(self.player:getHandcards())
	self:sortByUseValue(cards, true)
	for _,cd in ipairs(cards) do
	    if not cd:isKindOf("EquipCard") and cd:getSuit() == sgs.Card_Club then
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
sgs.ai_skill_invoke["Mtiandi"] = function(self, data)
    local use = data:toCardUse()
    if use.card:isKindOf("god_salvation") or use.card:isKindOf("amazing_grace") then
	    return false
	end
	return true
end
--传承
sgs.ai_skill_invoke["Mchuancheng"] = true
--梦行
sgs.ai_skill_invoke["Mmengxing"] = function(self, data)
    local target
	local targets = sgs.QList2Table(self.room:getAlivePlayers())
    self:sort(targets, "hp")
	for _,p in ipairs(targets) do
	    if self:isFriend(p) and self:isWeak(p) and not p:isKongcheng() then
		    target = p
			self.room:setPlayerFlag(p, "mengxing_target")
			self.room:setPlayerFlag(self.player, "mengxing_good")
			break
		end
	end
	if target then
	    return true
	end
	for _,p in ipairs(targets) do
	    if self:isEnemy(p) and p:isWounded() and not p:isKongcheng() and p:getLostHp() < 3 then
		    target = p
			self.room:setPlayerFlag(p, "mengxing_target")
			break
		end
	end
	if target then
	    return true
	end
	return false
end
sgs.ai_skill_playerchosen["Mmengxing"] = function(self, targets)
    local target
	for _, p in sgs.qlist(self.room:getAlivePlayers()) do
		if p:hasFlag("mengxing_target") then
		    target = p
			self.room:setPlayerFlag(p, "-mengxing_target")
			break
		end
	end
	return target
end
sgs.ai_skill_choice["Mmengxing"] = function(self, choices, data)
    if self.player:hasFlag("mengxing_good") then
	    self.room:setPlayerFlag(self.player, "-mengxing_good")
		return "mengxing_good"
	else
	    return "mengxing_bad"
	end
end
--需求
sgs.ai_cardneed["Mtiandi"] = function(to, card, self)
    if to:getHandcardNum() < to:getMaxHp() then
	    return card:isKindOf("BasicCard")
	end
end
--[[
    【半人马掠夺者】
]]--
--警戒
sgs.ai_skill_invoke["Mjingjie"] = function(self, data)
	local target = data:toPlayer()
	if self:isEnemy(target) or target:getNextAlive():objectName() == self.player:objectName() then
	    return true
	end
	return false
end
--规避
sgs.ai_skill_invoke["Mguibi"] = true
sgs.ai_skill_invoke["Mguibi_skill"] = function(self, data)
	for _, p in sgs.qlist(self.room:getOtherPlayers(self.player)) do
	    if self:isEnemy(p) and p:distanceTo(self.player) == p:getAttackRange() or self.player:distanceTo(p, -1) == self.player:getAttackRange() then
		    self.room:setPlayerFlag(self.player, "guibi_a")
			return true
		end
	end
	if self:isFriend(self.player:getLastAlive()) then
		self.room:setPlayerFlag(self.player, "guibi_b")
		return true
	end
	if self:isEnemy(self.player:getNextAlive()) and not (self:isEnemy(self.player:getNextAlive():getNextAlive()) and self.player:aliveCount() == 3) then
		self.room:setPlayerFlag(self.player, "guibi_c")
		return true
	end
	return true
end
sgs.ai_skill_choice["Mguibi"] = function(self, choices, data)
	if self.player:hasFlag("guibi_a") then
		self.room:setPlayerFlag(self.player, "-guibi_a")
		return "guibi_a"
	elseif self.player:hasFlag("guibi_b") then
		self.room:setPlayerFlag(self.player, "-guibi_b")
		return "guibi_b"
	elseif self.player:hasFlag("guibi_c") then
		self.room:setPlayerFlag(self.player, "-guibi_c")
		return "guibi_c"
	end
	return "guibi_a"
end
--[[
    【黑豹战士】
]]--
--爪牙
sgs.ai_skill_invoke["Mzhaoya"] = function(self, data)
    local effect = data:toSlashEffect()
	if self:isEnemy(effect.to) then
	    if self:getCardsNum("Slash") > 0 and not (effect.to:hasArmorEffect("Vine") and not self.player:hasWeapon("Fan")) then
		    return true
		else
		    if not self.player:hasEquip() then
			    return true
			end
		end
	end
	return false
end
--狂舞
sgs.ai_skill_invoke["Mkuangwu"] = function(self, data)
	local slash = sgs.cloneCard("slash")
	local x = 0
    for _, p in sgs.qlist(self.room:getOtherPlayers(self.player)) do
	    if p:hasShownOneGeneral() and not (self.player:isFriendWith(p) or self.player:willBeFriendWith(p)) and p:getHp() >= self.player:getHp() and self.player:inMyAttackRange(p) and self:slashIsEffective(slash, p) and not self:slashProhibit(slash, p) and self:damageIsEffective(p, sgs.DamageStruct_Normal, self.player) and not (p:hasArmorEffect("Vine") and not self.player:hasWeapon("Fan")) then
			if self:isFriend(p) then
				x = x-1
			else
				x = x+1
				if self:isWeak(p) then
					x = x+1
				end
			end
		end
	end
	if x > 1 then
		return true
	end
	return false
end
--需求
sgs.ai_cardneed["Mzhaoya"] = function(to, card, self)
    if to:getHandcardNum() < to:getHp() then
	    return card:isKindOf("Slash")
	end
end
--[[
    【怒眼独眼】
]]--
--遗忘
sgs.ai_skill_invoke["Myiwang"] = true
sgs.ai_slash_prohibit["Myiwang"] = function(self, from, to, card)
	if to:hasShownSkill("Myiwang") and not to:isKongcheng() and to:getHp() <= 1 and not (from:hasWeapon("ice_sword") or (from:hasWeapon("kylin_bow") and (to:getDefensiveHorse() or to:getOffensiveHorse()))) then
	    return getCardsNum("Jink", to, from) == 0
	end
	return false
end
--迟钝
sgs.ai_skill_invoke["Mchidun"] = true
--兽血
sgs.ai_skill_invoke["Mshouxue"] = function(self, data)
    local savage = sgs.cloneCard("savage_assault")
    local m = 0
	for _, p in sgs.qlist(self.room:getOtherPlayers(self.player)) do
	    if self:aoeIsEffective(savage, p, self.player) then
		    if self:isFriend(p) then
			    m = m-1
				if p:getHp() < 2 then
				    m = m-1
				end
			end
			if self:isEnemy(p) then
			    m = m+1
			end
		end
	end
	if m > 0 then
	    return true
	end
	return false
end
--需求
sgs.ai_cardneed["Mshouxue"] = function(to, card, self)
	return card:isKindOf("EquipCard")
end
sgs.ai_cardneed["Myiwang"] = function(to, card, self)
	return to:isKongcheng()
end
--[[
    【雷鸟】
]]--
--雷霆
sgs.ai_skill_invoke["Mleiting"] = true
--辉煌
sgs.ai_skill_invoke["Mhuihuang"] = function(self, data)
    local damage = data:toDamage()
	if self:isEnemy(damage.to) then
	    return true
	end
	return false
end
sgs.ai_skill_cardask["@huihuang_heart"] = function(self, data)
    local damage = data:toDamage()
	local target = damage.to
	local has_card
	if not self:isEnemy(target) then return "." end
	local cards = sgs.QList2Table(self.player:getHandcards())
	self:sortByUseValue(cards, true)
	for _,cd in ipairs(cards) do
	    if cd:getSuit() == sgs.Card_Heart and not cd:isKindOf("Peach") then
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
sgs.ai_skill_cardask["@huihuang_diamond"] = function(self, data)
    local damage = data:toDamage()
	local target = damage.to
	local has_card
	if not self:isEnemy(target) then return "." end
	local cards = sgs.QList2Table(self.player:getHandcards())
	self:sortByUseValue(cards, true)
	for _,cd in ipairs(cards) do
	    if cd:getSuit() == sgs.Card_Diamond and not cd:isKindOf("Peach") then
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
sgs.ai_skill_cardask["@huihuang_spade"] = function(self, data)
    local damage = data:toDamage()
	local target = damage.to
	local has_card
	if not self:isEnemy(target) then return "." end
	local cards = sgs.QList2Table(self.player:getHandcards())
	self:sortByUseValue(cards, true)
	for _,cd in ipairs(cards) do
	    if cd:getSuit() == sgs.Card_Spade then
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
sgs.ai_skill_cardask["@huihuang_club"] = function(self, data)
    local damage = data:toDamage()
	local target = damage.to
	local has_card
	if not self:isEnemy(target) then return "." end
	local cards = sgs.QList2Table(self.player:getHandcards())
	self:sortByUseValue(cards, true)
	for _,cd in ipairs(cards) do
	    if cd:getSuit() == sgs.Card_Club then
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
--奔腾
sgs.ai_skill_invoke["Mbenteng"] = function(self, data)
	if self.player:getHp() == 2 then return false end
	local slash = sgs.cloneCard("thunder_slash")
	local targets = sgs.QList2Table(self.room:getOtherPlayers(self.player))
	self:sort(targets, "hp")
	for _, p in ipairs(targets) do
	    if p:hasShownOneGeneral() and self:isEnemy(p) and p:getMark("@benteng") == 0 then
			if self:slashIsEffective(slash, p) and not self:slashProhibit(slash, p) and self:damageIsEffective(p, sgs.DamageStruct_Thunder, self.player) then
				self.room:setPlayerFlag(p, "bengteng_target")
				return true
			end
		end
	end
	return false
end
sgs.ai_skill_playerchosen["Mbenteng"] = function(self, targets)
    local target
	for _, p in sgs.qlist(self.room:getOtherPlayers(self.player)) do
		if p:hasFlag("bengteng_target") then
		    target = p
			self.room:setPlayerFlag(p, "-bengteng_target")
			break
		end
	end
	return target
end
--[[
    【伊亚拉斯】
]]--
--探索
sgs.ai_skill_invoke["Mtansuo"] = function(self, data)
    local target
	local no_heart = true
	local no_spade = true
	local no_diamond = true
	local no_club = true
	for _, card in sgs.qlist(self.player:getHandcards()) do
		if card:getSuit() == sgs.Card_Heart then
			no_heart = false
		elseif card:getSuit() == sgs.Card_Spade then
			no_spade = false
		elseif card:getSuit() == sgs.Card_Diamond then
			no_diamond = false
		elseif card:getSuit() == sgs.Card_Club then
			no_club = false
		end
	end
	if no_heart or no_spade or no_diamond or no_club then
	    local targets = sgs.QList2Table(self.room:getOtherPlayers(self.player))
		self:sort(targets, "handcard", true)
		for _, p in ipairs(targets) do
		    if p:hasShownOneGeneral() and self:isEnemy(p) and self.player:distanceTo(p) < 2 and self.player:distanceTo(p) ~= -1 and self.player:getHandcardNum() < p:getHandcardNum() then
			    target = p
				self.room:setPlayerFlag(p, "tansuo_target")
				break
			end
		end
		if target then
		    return true
		end
	end
	return false
end
sgs.ai_skill_playerchosen["Mtansuo"] = function(self, targets)
    local target
	for _, p in sgs.qlist(self.room:getOtherPlayers(self.player)) do
		if p:hasFlag("tansuo_target") then
		    target = p
			self.room:setPlayerFlag(p, "-tansuo_target")
			break
		end
	end
	return target
end
sgs.ai_playerchosen_intention["Mtansuo"] = 40
--自由
sgs.ai_skill_invoke["Mziyou"] = true
sgs.ai_skill_invoke["#Mziyou_effect"] = true