/********************************************************************
    Copyright (c) 2013-2015 - Mogara

    This file is part of QSanguosha-Hegemony.

    This game is free software; you can redistribute it and/or
    modify it under the terms of the GNU General Public License as
    published by the Free Software Foundation; either version 3.0
    of the License, or (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
    General Public License for more details.

    See the LICENSE file for more details.

    Mogara
    *********************************************************************/

#include "gamerule.h"
#include "serverplayer.h"
#include "room.h"
#include "standard.h"
#include "engine.h"
#include "settings.h"
#include "json.h"
#include "roomthread.h"

#include <QTime>

class GameRule_AskForGeneralShowHead : public TriggerSkill
{
public:
    GameRule_AskForGeneralShowHead() : TriggerSkill("GameRule_AskForGeneralShowHead")
    {
        events << EventPhaseStart;
        global = true;
    }

    virtual bool cost(TriggerEvent, Room *, ServerPlayer *player, QVariant &, ServerPlayer *) const
    {
        player->showGeneral(true, true);
        return false;
    }

    virtual bool triggerable(const ServerPlayer *player) const
    {
        return player->getPhase() == Player::Start
            && !player->hasShownGeneral1()
            && player->disableShow(true).isEmpty();
    }
};

class GameRule_AskForGeneralShowDeputy : public TriggerSkill
{
public:
    GameRule_AskForGeneralShowDeputy() : TriggerSkill("GameRule_AskForGeneralShowDeputy")
    {
        events << EventPhaseStart;
        global = true;
    }

    virtual bool cost(TriggerEvent, Room *, ServerPlayer *player, QVariant &, ServerPlayer *) const
    {
        player->showGeneral(false, true);
        return false;
    }

    virtual bool triggerable(const ServerPlayer *player) const
    {
        return player->getPhase() == Player::Start
            && player->getGeneral2()
            && !player->hasShownGeneral2()
            && player->disableShow(false).isEmpty();
    }
};

class GameRule_AskForArraySummon : public TriggerSkill
{
public:
    GameRule_AskForArraySummon() : TriggerSkill("GameRule_AskForArraySummon")
    {
        events << EventPhaseStart;
        global = true;
    }

    virtual bool cost(TriggerEvent, Room *, ServerPlayer *player, QVariant &, ServerPlayer *) const
    {
        foreach (const Skill *skill, player->getVisibleSkillList()) {
            if (!skill->inherits("BattleArraySkill")) continue;
            const BattleArraySkill *baskill = qobject_cast<const BattleArraySkill *>(skill);
            if (!player->askForSkillInvoke(objectName())) return false;
            player->showGeneral(player->inHeadSkills(skill->objectName()));
            baskill->summonFriends(player);
            break;
        }
        return false;
    }

    virtual QStringList triggerable(TriggerEvent, Room *room, ServerPlayer *player, QVariant &, ServerPlayer * &) const
    {
        if (player->getPhase() != Player::Start) return QStringList();
        if (room->getAlivePlayers().length() < 4) return QStringList();
        foreach (const Skill *skill, player->getVisibleSkillList()) {
            if (!skill->inherits("BattleArraySkill")) continue;
            return (qobject_cast<const BattleArraySkill *>(skill)->getViewAsSkill()->isEnabledAtPlay(player)) ? QStringList(objectName()) : QStringList();
        }
        return QStringList();
    }
};

class GameRule_LordConvertion : public TriggerSkill
{
public:
    GameRule_LordConvertion() : TriggerSkill("GameRule_LordConvertion")
    {
        events << GameStart;
        global = true;
    }

    virtual TriggerList triggerable(TriggerEvent, Room *room, ServerPlayer *player, QVariant &) const
    {
        TriggerList trigger_map;

        if (!Config.value("EnableLordConvertion", true).toBool())
            return trigger_map;

        if (player == NULL) {
            foreach (ServerPlayer *p, room->getAllPlayers()) {
                if (p->getActualGeneral1() != NULL) {
                    QString lord = "lord_" + p->getActualGeneral1()->objectName();
                    const General *lord_general = Sanguosha->getGeneral(lord);
                    if (lord_general && !Sanguosha->getBanPackages().contains(lord_general->getPackage())) {
                        trigger_map.insert(p, QStringList(objectName()));
                    }
                }
            }
        }

        return trigger_map;
    }

    virtual bool cost(TriggerEvent, Room *, ServerPlayer *, QVariant &, ServerPlayer *ask_who) const
    {
        return ask_who->askForSkillInvoke("userdefine:changetolord");
    }

    virtual bool effect(TriggerEvent, Room *, ServerPlayer *, QVariant &, ServerPlayer *ask_who) const
    {
        ask_who->changeToLord();
        return false;
    }
};

GameRule::GameRule(QObject *parent)
    : TriggerSkill("game_rule")
{
    setParent(parent);

    events << GameStart << TurnStart
        << EventPhaseProceeding << EventPhaseEnd << EventPhaseChanging
        << PreCardUsed << CardUsed << CardFinished << CardEffected
        << PostHpReduced
        << EventLoseSkill << EventAcquireSkill
        << AskForPeaches << AskForPeachesDone << BuryVictim
        << BeforeGameOverJudge << GameOverJudge
        << SlashHit << SlashEffected << SlashProceed
        << ConfirmDamage << DamageDone << DamageComplete
        << FinishRetrial << FinishJudge
        << ChoiceMade << GeneralShown
        << BeforeCardsMove << CardsMoveOneTime;

    QList<Skill *> list;
    list << new GameRule_AskForGeneralShowHead;
    list << new GameRule_AskForGeneralShowDeputy;
    list << new GameRule_AskForArraySummon;
    list << new GameRule_LordConvertion;

    QList<const Skill *> list_copy;
    foreach (Skill *s, list) {
        if (Sanguosha->getSkill(s->objectName())) {
            delete s;
        } else {
            list_copy << s;
        }
    }
    Sanguosha->addSkills(list_copy);
}

QStringList GameRule::triggerable(TriggerEvent, Room *, ServerPlayer *, QVariant &, ServerPlayer * &ask_who) const
{
    ask_who = NULL;
    return QStringList(objectName());
}

int GameRule::getPriority() const
{
    return 0;
}

void GameRule::onPhaseProceed(ServerPlayer *player) const
{
    Room *room = player->getRoom();
    switch (player->getPhase()) {
    case Player::PhaseNone: {
        Q_ASSERT(false);
    }
    case Player::RoundStart:{
        break;
    }
    case Player::Start: {
        break;
    }
    case Player::Judge: {
        QList<const Card *> tricks = player->getJudgingArea();
        while (!tricks.isEmpty() && player->isAlive()) {
            const Card *trick = tricks.takeLast();
            bool on_effect = room->cardEffect(trick, NULL, player);
            if (!on_effect)
                trick->onNullified(player);
        }
        break;
    }
    case Player::Draw: {
        QVariant qnum;
        int num = 2;
        if (player->hasFlag("Global_FirstRound")) {
            room->setPlayerFlag(player, "-Global_FirstRound");
        }

        qnum = num;
        Q_ASSERT(room->getThread() != NULL);
        room->getThread()->trigger(DrawNCards, room, player, qnum);
        num = qnum.toInt();
		// M&M 争锋模式中领主的额外摸牌
		if (player->getMark("@zhengfeng_lord") > 0)
			num = num + 1;
		//
        if (num > 0)
            player->drawCards(num);
        qnum = num;
        room->getThread()->trigger(AfterDrawNCards, room, player, qnum);
        break;
    }
    case Player::Play: {
        while (player->isAlive()) {
            CardUseStruct card_use;
            room->activate(player, card_use);
            if (card_use.card != NULL)
                room->useCard(card_use);
            else
                break;
        }
        break;
    }
    case Player::Discard: {
        int discard_num = player->getHandcardNum() - player->getMaxCards(MaxCardsType::Normal);
        if (discard_num > 0)
            if (!room->askForDiscard(player, "gamerule", discard_num, discard_num))
                break;
        break;
    }
    case Player::Finish: {
        break;
    }
    case Player::NotActive:{
        break;
    }
    }
}

bool GameRule::effect(TriggerEvent triggerEvent, Room *room, ServerPlayer *player, QVariant &data, ServerPlayer *) const
{
    if (room->getTag("SkipGameRule").toBool()) {
        room->removeTag("SkipGameRule");
        return false;
    }

    // Handle global events
    if (player == NULL) {
        if (triggerEvent == GameStart) {
            foreach (ServerPlayer *player, room->getPlayers()) {
                Q_ASSERT(player->getGeneral() != NULL);
                /*
                if (player->getGeneral()->getKingdom() == "god" && player->getGeneralName() != "anjiang") {
                QString new_kingdom = room->askForKingdom(player);
                room->setPlayerProperty(player, "kingdom", new_kingdom);

                LogMessage log;
                log.type = "#ChooseKingdom";
                log.from = player;
                log.arg = new_kingdom;
                room->sendLog(log);
                }
                */
                foreach (const Skill *skill, player->getVisibleSkillList()) {
                    if (skill->getFrequency() == Skill::Limited && !skill->getLimitMark().isEmpty() && (!skill->isLordSkill() || player->hasLordSkill(skill->objectName()))) {
                        JsonArray arg;
                        arg << player->objectName();
                        arg << skill->getLimitMark();
                        arg << 1;
                        room->doNotify(player, QSanProtocol::S_COMMAND_SET_MARK, arg);
                        player->setMark(skill->getLimitMark(), 1);
                    }
                }
            }
            room->setTag("FirstRound", true);
            if (room->getMode() != "custom_scenario")
                room->drawCards(room->getPlayers(), 4, QString());
            if (Config.LuckCardLimitation > 0)
                room->askForLuckCard();
			// M&M 两个自定义模式的开场效果
			QStringList all_packs = Sanguosha->getExtensions();
			QStringList ban_packs = Sanguosha->getBanPackages();
			if (all_packs.contains("Ashan5") && !ban_packs.contains("Ashan5")){//争锋模式相关
				QStringList kingdoms;
				foreach (ServerPlayer *p, room->getAllPlayers()){
					if (p->ownSkill("shouyue") || p->ownSkill("hongfa") || p->ownSkill("Mhuiyao") || p->ownSkill("Mtansuo") || p->ownSkill("Mbolan") || p->ownSkill("Mdiyin") || p->ownSkill("Mxiangzheng") || p->ownSkill("Mhundun")) {
						QString kingdom = p->getActualGeneral1()->getKingdom();
						if (!kingdoms.contains(kingdom))
							kingdoms << kingdom;
					}
				}
				int kingdom_num = kingdoms.length();
				if (kingdom_num > 1){
					room->doLightbox("$zhengfeng_open", 2000);
					LogMessage log;
					log.type = "#zhengfeng1";
					room->sendLog(log);
					QStringList real_kingdoms;
					foreach (ServerPlayer *p, room->getAllPlayers()){
						if (p->ownSkill("shouyue") || p->ownSkill("hongfa") || p->ownSkill("Mhuiyao") || p->ownSkill("Mtansuo") || p->ownSkill("Mbolan") || p->ownSkill("Mdiyin") || p->ownSkill("Mxiangzheng") || p->ownSkill("Mhundun")) {
							QString kingdom = p->getActualGeneral1()->getKingdom();
							if (!real_kingdoms.contains(kingdom)){
								real_kingdoms << kingdom;
								p->showGeneral(true, true);
								LogMessage log;
								log.type = "#zhengfeng2";
								log.from = p;
								log.arg = kingdom;
								room->sendLog(log);
								room->setPlayerMark(p, "@zhengfeng_lord", 1);
								room->setPlayerProperty(p, "maxhp", p->getMaxHp() + 1);
								room->setPlayerProperty(p, "hp", p->getMaxHp());
								p->drawCards(1);
							} else {
								room->setPlayerMark(p, "zhengfeng_careerist", 1);
							}
						}
					}
					kingdoms << "careerist";
					foreach (ServerPlayer *p, room->getAllPlayers()){
						if (p->getMark("@zhengfeng_lord") == 0){
							if (p->ownSkill("shouyue") || p->ownSkill("hongfa") || p->ownSkill("Mhuiyao") || p->ownSkill("Mtansuo") || p->ownSkill("Mbolan") || p->ownSkill("Mdiyin") || p->ownSkill("Mxiangzheng") || p->ownSkill("Mhundun")) {
								p->setRole("careerist");
								room->notifyProperty(p, p, "role");
							} else {
								QString kingdom = p->getActualGeneral1()->getKingdom();
								if (!kingdoms.contains(kingdom)){
									QString choice = room->askForChoice(p, "zhengfeng_mode", kingdoms.join("+"));
									if (choice != "careerist"){
									    p->setKingdom(choice);
									    room->notifyProperty(p, p, "kingdom");
									    room->setPlayerMark(p, choice, 1);
									} else {
									    p->setRole("careerist");
										room->notifyProperty(p, p, "role");
										room->setPlayerMark(p, "zhengfeng_careerist", 1);
									}
								}
							}
						}
					}
				}
			}
			if (all_packs.contains("Ashan4") && !ban_packs.contains("Ashan4")){//血洗模式相关
				bool has_lord = false;
				foreach (ServerPlayer *p, room->getAllPlayers()){
					if (p->ownSkill("shouyue") || p->ownSkill("hongfa") || p->ownSkill("Mhuiyao") || p->ownSkill("Mtansuo") || p->ownSkill("Mbolan") || p->ownSkill("Mdiyin") || p->ownSkill("Mxiangzheng") || p->ownSkill("Mhundun")) {
						has_lord = true;
						break;
					}
				}
				if (!has_lord){
					room->doLightbox("$xuexi_open", 2000);
					LogMessage log;
					log.type = "#xuexi1";
					room->sendLog(log);
					foreach (ServerPlayer *p, room->getAllPlayers()){
						room->setPlayerMark(p, "xuexi_open", 1);
					}
				}
			}
			//
        }
        return false;
    }

    switch (triggerEvent) {
    case TurnStart: {
        player = room->getCurrent();
        if (room->getTag("FirstRound").toBool()) {
            room->setTag("FirstRound", false);
            room->setPlayerFlag(player, "Global_FirstRound");
        }

        LogMessage log;
        log.type = "$AppendSeparator";
        room->sendLog(log);
        room->addPlayerMark(player, "Global_TurnCount");

        JsonArray update_handcards_array;
        foreach (ServerPlayer *p, room->getPlayers()) {
            JsonArray _current;
            _current << p->objectName();
            _current << p->getHandcardNum();
            update_handcards_array << _current;
        }
        room->doBroadcastNotify(QSanProtocol::S_COMMAND_UPDATE_HANDCARD_NUM, update_handcards_array);

        if (!player->faceUp()) {
            room->setPlayerFlag(player, "-Global_FirstRound");
            player->turnOver();
#ifndef QT_NO_DEBUG
            if (player->isAlive() && !player->getAI() && player->askForSkillInvoke("userdefine:playNormally"))
                player->play();
#endif
        } else if (player->isAlive())
            player->play();

        break;
    }
    case EventPhaseProceeding: {
        onPhaseProceed(player);
        break;
    }
    case EventPhaseEnd: {
        if (player->getPhase() == Player::Play)
            room->addPlayerHistory(player, ".");
		// M&M 血洗模式规则4
		if (player->getPhase() == Player::Start && player->getMark("@xuexi") > 0)
			room->setPlayerMark(player, "@xuexi", 0);
		//
        break;
    }
    case EventPhaseChanging: {
        PhaseChangeStruct change = data.value<PhaseChangeStruct>();
        if (change.to == Player::NotActive) {
            room->setPlayerFlag(player, ".");
            room->clearPlayerCardLimitation(player, true);
            foreach (ServerPlayer *p, room->getAllPlayers()) {
                if (p->getMark("drank") > 0) {
                    LogMessage log;
                    log.type = "#UnsetDrankEndOfTurn";
                    log.from = p;
                    room->sendLog(log);

                    room->setPlayerMark(p, "drank", 0);
                }
            }
            if (room->getTag("ImperialOrderInvoke").toBool()) {
                room->setTag("ImperialOrderInvoke", false);
                LogMessage log;
                log.type = "#ImperialOrderEffect";
                log.from = player;
                log.arg = "imperial_order";
                room->sendLog(log);
                const Card *io = room->getTag("ImperialOrderCard").value<const Card *>();
                if (io) {
                    foreach (ServerPlayer *p, room->getAllPlayers()) {
                        if (!p->hasShownOneGeneral() && !Sanguosha->isProhibited(NULL, p, io)) // from is NULL!
                            room->cardEffect(io, NULL, p);
                    }
                }
            }
        } else if (change.to == Player::Play) {
            room->addPlayerHistory(player, ".");
        } else if (change.to == Player::Start) {
            if (!player->hasShownGeneral1()
                && Sanguosha->getGeneral(room->getTag(player->objectName()).toStringList().first())->isLord())
                player->showGeneral();
        }
        break;
    }
    case PreCardUsed: {
        if (data.canConvert<CardUseStruct>()) {
            CardUseStruct card_use = data.value<CardUseStruct>();
            if (card_use.from->hasFlag("Global_ForbidSurrender")) {
                card_use.from->setFlags("-Global_ForbidSurrender");
                room->doNotify(card_use.from, QSanProtocol::S_COMMAND_ENABLE_SURRENDER, true);
            }

            card_use.from->broadcastSkillInvoke(card_use.card);
            if (!card_use.card->getSkillName().isNull() && card_use.card->getSkillName(true) == card_use.card->getSkillName(false)
                && card_use.m_isOwnerUse && card_use.from->hasSkill(card_use.card->getSkillName()))
                room->notifySkillInvoked(card_use.from, card_use.card->getSkillName());
        }
        break;
    }
    case CardUsed: {
        if (data.canConvert<CardUseStruct>()) {
            CardUseStruct card_use = data.value<CardUseStruct>();
            RoomThread *thread = room->getThread();

            if (card_use.card->hasPreAction())
                card_use.card->doPreAction(room, card_use);

            QList<ServerPlayer *> targets = card_use.to;

            if (card_use.from != NULL) {
                thread->trigger(TargetChoosing, room, card_use.from, data);
                CardUseStruct new_use = data.value<CardUseStruct>();
                targets = new_use.to;
            }

            if (card_use.from && !targets.isEmpty()) {
                QList<ServerPlayer *> targets_copy = targets;
                foreach (ServerPlayer *to, targets_copy) {
                    if (targets.contains(to)) {
                        thread->trigger(TargetConfirming, room, to, data);
                        CardUseStruct new_use = data.value<CardUseStruct>();
                        targets = new_use.to;
                        if (targets.isEmpty()) break;
                    }
                }
            }
            card_use = data.value<CardUseStruct>();

            if (card_use.card && !(card_use.card->isVirtualCard() && card_use.card->getSubcards().isEmpty())
                && !card_use.card->targetFixed() && card_use.to.isEmpty()) {
                QList<int> table_cardids = room->getCardIdsOnTable(card_use.card);
                if (!table_cardids.isEmpty()) {
                    DummyCard dummy(table_cardids);
                    CardMoveReason reason(CardMoveReason::S_REASON_NATURAL_ENTER, QString());
                    room->throwCard(&dummy, reason, NULL);
                    break;
                }
            }

            try {
                QVariantList jink_list_backup;
                if (card_use.card->isKindOf("Slash")) {
                    jink_list_backup = card_use.from->tag["Jink_" + card_use.card->toString()].toList();
                    QVariantList jink_list;
                    for (int i = 0; i < card_use.to.length(); i++)
                        jink_list.append(QVariant(1));
                    card_use.from->tag["Jink_" + card_use.card->toString()] = QVariant::fromValue(jink_list);
                }
                if (card_use.from && !card_use.to.isEmpty()) {
                    thread->trigger(TargetChosen, room, card_use.from, data);
                    foreach(ServerPlayer *p, room->getAllPlayers())
                        thread->trigger(TargetConfirmed, room, p, data);
                }
                card_use = data.value<CardUseStruct>();
                room->setTag("CardUseNullifiedList", QVariant::fromValue(card_use.nullified_list));
                card_use.card->use(room, card_use.from, card_use.to);
                if (!jink_list_backup.isEmpty())
                    card_use.from->tag["Jink_" + card_use.card->toString()] = QVariant::fromValue(jink_list_backup);
            }
            catch (TriggerEvent triggerEvent) {
                if (triggerEvent == TurnBroken || triggerEvent == StageChange)
                    card_use.from->tag.remove("Jink_" + card_use.card->toString());
                throw triggerEvent;
            }
        }

        break;
    }
    case CardFinished: {
        CardUseStruct use = data.value<CardUseStruct>();
        room->clearCardFlag(use.card);

        if (use.card->isNDTrick())
            room->removeTag(use.card->toString() + "HegNullificationTargets");

        foreach(ServerPlayer *p, room->getAlivePlayers())
            room->doNotify(p, QSanProtocol::S_COMMAND_NULLIFICATION_ASKED, QString("."));
        if (use.card->isKindOf("Slash"))
            use.from->tag.remove("Jink_" + use.card->toString());

        break;
    }
    case EventAcquireSkill:
    case EventLoseSkill: {
        QString skill_name = data.toString();
        const Skill *skill = Sanguosha->getSkill(skill_name);
        bool refilter = skill->inherits("FilterSkill");

        if (!refilter && skill->inherits("TriggerSkill")) {
            const TriggerSkill *trigger = qobject_cast<const TriggerSkill *>(skill);
            const ViewAsSkill *vsskill = trigger->getViewAsSkill();
            if (vsskill && vsskill->inherits("FilterSkill"))
                refilter = true;
        }

        if (refilter)
            room->filterCards(player, player->getCards("he"), triggerEvent == EventLoseSkill);

        break;
    }
    case PostHpReduced: {
        if (player->getHp() > 0 || player->hasFlag("Global_Dying")) // newest GameRule -- a player cannot enter dying when it is dying.
            break;
        if (data.canConvert<DamageStruct>()) {
            DamageStruct damage = data.value<DamageStruct>();
            room->enterDying(player, &damage);
        } else
            room->enterDying(player, NULL);

        break;
    }
    case AskForPeaches: {
        DyingStruct dying = data.value<DyingStruct>();
        const Card *peach = NULL;

        try {
            ServerPlayer *jiayu = room->getCurrent();
            if (jiayu->hasSkill("wansha") && jiayu->hasShownSkill("wansha")
                && jiayu->isAlive() && jiayu->getPhase() != Player::NotActive) {
                if (player != dying.who && player != jiayu)
                    room->setPlayerFlag(player, "Global_PreventPeach");
            }

            if (!player->hasFlag("Global_PreventPeach") && dying.who->isRemoved())
                room->setPlayerFlag(player, "Global_PreventPeach");

            while (dying.who->getHp() <= 0) {
                peach = NULL;
                if (dying.who->isAlive())
                    peach = room->askForSinglePeach(player, dying.who);
                if (peach == NULL)
                    break;
                room->useCard(CardUseStruct(peach, player, dying.who), false);
            }
            if (player->hasFlag("Global_PreventPeach"))
                room->setPlayerFlag(player, "-Global_PreventPeach");
        }
        catch (TriggerEvent triggerEvent) {
            if (triggerEvent == TurnBroken || triggerEvent == StageChange) {
                if (player->hasFlag("Global_PreventPeach"))
                    room->setPlayerFlag(player, "-Global_PreventPeach");
            }
            throw triggerEvent;
        }

        break;
    }
    case AskForPeachesDone: {
        if (player->getHp() <= 0 && player->isAlive()) {
#ifndef QT_NO_DEBUG
            if (!player->getAI() && player->askForSkillInvoke("userdefine:revive")) {
                room->setPlayerProperty(player, "hp", player->getMaxHp());
                break;
            }
#endif
            DyingStruct dying = data.value<DyingStruct>();
            room->killPlayer(player, dying.damage);
        }

        break;
    }
    case ConfirmDamage: {
        DamageStruct damage = data.value<DamageStruct>();
        if (damage.card && damage.to->getMark("SlashIsDrank") > 0) {
            LogMessage log;
            log.type = "#AnalepticBuff";
            log.from = damage.from;
            log.to << damage.to;
            log.arg = QString::number(damage.damage);

            damage.damage += damage.to->getMark("SlashIsDrank");
            damage.to->setMark("SlashIsDrank", 0);

            log.arg2 = QString::number(damage.damage);

            room->sendLog(log);

            data = QVariant::fromValue(damage);
        }

        break;
    }
    case DamageDone: {
        DamageStruct damage = data.value<DamageStruct>();
        if (damage.from && !damage.from->isAlive())
            damage.from = NULL;
        data = QVariant::fromValue(damage);
        room->sendDamageLog(damage);

        room->applyDamage(player, damage);
        if (damage.nature != DamageStruct::Normal && player->isChained() && !damage.chain) {
            int n = room->getTag("is_chained").toInt();
            n++;
            room->setTag("is_chained", n);
        }
        room->getThread()->trigger(PostHpReduced, room, player, data);

        break;
    }
    case DamageComplete: {
        DamageStruct damage = data.value<DamageStruct>();
        if (damage.prevented)
            return false;
        if (damage.nature != DamageStruct::Normal && player->isChained())
            room->setPlayerProperty(player, "chained", false);
        if (room->getTag("is_chained").toInt() > 0) {
            if (damage.nature != DamageStruct::Normal && !damage.chain) {
                // iron chain effect
                int n = room->getTag("is_chained").toInt();
                n--;
                room->setTag("is_chained", n);
                QList<ServerPlayer *> chained_players;
                if (room->getCurrent()->isDead())
                    chained_players = room->getOtherPlayers(room->getCurrent());
                else
                    chained_players = room->getAllPlayers();
                foreach (ServerPlayer *chained_player, chained_players) {
                    if (chained_player->isChained()) {
                        room->getThread()->delay();
                        LogMessage log;
                        log.type = "#IronChainDamage";
                        log.from = chained_player;
                        room->sendLog(log);

                        DamageStruct chain_damage = damage;
                        chain_damage.to = chained_player;
                        chain_damage.chain = true;
                        chain_damage.transfer = false;
                        chain_damage.transfer_reason = QString();

                        room->damage(chain_damage);
                    }
                }
            }
        }
        foreach (ServerPlayer *p, room->getAllPlayers()) {
            if (p->hasFlag("Global_DFDebut")) {
                p->setFlags("-Global_DFDebut");
                room->getThread()->trigger(DFDebut, room, p);
            }
        }
        break;
    }
    case CardEffected: {
        if (data.canConvert<CardEffectStruct>()) {
            CardEffectStruct effect = data.value<CardEffectStruct>();
            if (!effect.card->isKindOf("Slash") && effect.nullified) {
                LogMessage log;
                log.type = "#CardNullified";
                log.from = effect.to;
                log.arg = effect.card->objectName();
                room->sendLog(log);

                return true;
            } else if (effect.card->getTypeId() == Card::TypeTrick && room->isCanceled(effect)) {
                effect.to->setFlags("Global_NonSkillNullify");
                return true;
            }
            QVariant _effect = QVariant::fromValue(effect);
            room->getThread()->trigger(CardEffectConfirmed, room, effect.to, _effect);
            if (effect.to->isAlive() || effect.card->isKindOf("Slash"))
                effect.card->onEffect(effect);
        }

        break;
    }
    case SlashEffected: {
        SlashEffectStruct effect = data.value<SlashEffectStruct>();
        if (effect.nullified) {
            LogMessage log;
            log.type = "#CardNullified";
            log.from = effect.to;
            log.arg = effect.slash->objectName();
            room->sendLog(log);

            return true;
        }

        if (effect.jink_num > 0)
            room->getThread()->trigger(SlashProceed, room, effect.from, data);
        else
            room->slashResult(effect, NULL);
        break;
    }
    case SlashProceed: {
        SlashEffectStruct effect = data.value<SlashEffectStruct>();
        QString slasher = effect.from->objectName();
        if (!effect.to->isAlive())
            break;
        if (effect.jink_num == 1) {
            const Card *jink = room->askForCard(effect.to, "jink", "slash-jink:" + slasher, data, Card::MethodUse, effect.from);
            room->slashResult(effect, room->isJinkEffected(effect.to, jink) ? jink : NULL);
        } else {
            DummyCard *jink = new DummyCard;
            const Card *asked_jink = NULL;
            for (int i = effect.jink_num; i > 0; i--) {
                QString prompt = QString("@multi-jink%1:%2::%3").arg(i == effect.jink_num ? "-start" : QString())
                    .arg(slasher).arg(i);
                asked_jink = room->askForCard(effect.to, "jink", prompt, data, Card::MethodUse, effect.from);
                if (!room->isJinkEffected(effect.to, asked_jink)) {
                    delete jink;
                    room->slashResult(effect, NULL);
                    return false;
                } else {
                    jink->addSubcard(asked_jink->getEffectiveId());
                }
            }
            room->slashResult(effect, jink);
        }

        break;
    }
    case SlashHit: {
        SlashEffectStruct effect = data.value<SlashEffectStruct>();

        if (effect.drank > 0) effect.to->setMark("SlashIsDrank", effect.drank);
        room->damage(DamageStruct(effect.slash, effect.from, effect.to, 1, effect.nature));

        break;
    }
    case BeforeGameOverJudge: {
        if (!player->hasShownGeneral1())
            player->showGeneral(true, false, false);
        if (!player->hasShownGeneral2())
            player->showGeneral(false, false, false);
        break;
    }
    case GameOverJudge: {
        QString winner = getWinner(player);
        if (!winner.isNull()) {
            room->gameOver(winner);
            return true;
        }

        break;
    }
    case BuryVictim: {
        DeathStruct death = data.value<DeathStruct>();
        // M&M 新增规则的死亡奖惩内容
		if (player->getMark("@zhengfeng_lord") > 0){
			player->bury();
			room->setPlayerMark(player, "@zhengfeng_lord", 1);
		} else {
			player->bury(); // 防止死亡时丢失领主标记
		}

        if (room->getTag("SkipNormalDeathProcess").toBool() || player->getGeneralName() == "Mbug")// 魔婴的死亡不计入奖惩
            return false;

        ServerPlayer *killer = death.damage ? death.damage->from : NULL;
        if (killer)
            rewardAndPunish(killer, player);

		if (player == data.value<DeathStruct>().who){
			if (player->getMark("@zhengfeng_lord") > 0){ // 争锋模式规则6
				if (player->getKingdom() == "shu")
					room->doLightbox("$zhengfeng_shu", 2000);
				if (player->getKingdom() == "wei")
					room->doLightbox("$zhengfeng_wei", 2000);
				if (player->getKingdom() == "wu")
					room->doLightbox("$zhengfeng_wu", 2000);
				if (player->getKingdom() == "qun")
					room->doLightbox("$zhengfeng_qun", 2000);
				if (player->getKingdom() == "ying")
					room->doLightbox("$zhengfeng_ying", 2000);
				if (player->getKingdom() == "mi")
					room->doLightbox("$zhengfeng_mi", 2000);
				if (player->getKingdom() == "an")
					room->doLightbox("$zhengfeng_an", 2000);

				room->setPlayerMark(player, "@zhengfeng_lord", 0);
				foreach (ServerPlayer *p, room->getOtherPlayers(player, false)){
					if (p->isFriendWith(player) && p->hasShownOneGeneral()){
						if (p->getMark("fanyan_ing") < 1 && p->getMark("@liming") < 7){
							room->killPlayer(p);
						}
					}
				}
				if (killer && killer->hasShownOneGeneral()){
					foreach (ServerPlayer *p, room->getAlivePlayers()){
						if (p->isFriendWith(killer) && p->hasShownOneGeneral()){
							if (p->isWounded()){
								RecoverStruct recover;
								recover.who = player;
								recover.recover = 1;
								room->recover(p, recover);
							}
							else
								p->drawCards(1);
						}
					}
				}
			}
			else { // 争锋模式规则5
				foreach (ServerPlayer *p, room->getOtherPlayers(player, false)){
					if (p->isFriendWith(player) && p->getMark("@zhengfeng_lord") > 0){
						LogMessage log;
						log.type = "#zhengfeng3";
						log.to << player;
						log.from = p;
						room->sendLog(log);
						room->loseHp(p, 1);
						if (!p->isNude()){
							room->askForDiscard(p, "gamerule", 1, 1, false, true);
						}
						break;
					}
				}
			}
		}

		if (player->getMark("xuexi_open") > 0 && player == data.value<DeathStruct>().who) {
			if (killer){
				if (killer->isAlive()){ // 血洗模式规则4
					LogMessage log;
					log.type = "#xuexi2";
					log.from = killer;
					log.arg = "xuexi_mode";
					room->sendLog(log);
					room->setPlayerMark(killer, "@xuexi", killer->getMark("@xuexi") + 1);
				}
				if (killer->hasShownOneGeneral()){ // 血洗模式规则3
					if (player->getKingdom() == "shu")
						room->doLightbox("$xuexi_shu", 2000);
					if (player->getKingdom() == "wei")
						room->doLightbox("$xuexi_wei", 2000);
					if (player->getKingdom() == "wu")
						room->doLightbox("$xuexi_wu", 2000);
					if (player->getKingdom() == "qun")
						room->doLightbox("$xuexi_qun", 2000);
					if (player->getKingdom() == "ying")
						room->doLightbox("$xuexi_ying", 2000);
					if (player->getKingdom() == "mi")
						room->doLightbox("$xuexi_mi", 2000);
					if (player->getKingdom() == "an")
						room->doLightbox("$xuexi_an", 2000);

					foreach (ServerPlayer *p, room->getOtherPlayers(player, false)){
						if (p->isFriendWith(player) && p->hasShownOneGeneral()){
							if (p->getMark("fanyan_ing") < 1 && p->getMark("@liming") < 7){
								room->killPlayer(p);
							}
						}
					}
					if (killer->getRole() != "careerist"){
						foreach (ServerPlayer *p, room->getAlivePlayers()){
							if (p->isFriendWith(killer) && p->hasShownOneGeneral()){
								if (p->isWounded()){
									RecoverStruct recover;
									recover.who = player;
									recover.recover = 1;
									room->recover(p, recover);
								}
							else
								p->drawCards(1);
							}
						}
					}
					else {
						if (killer->isWounded()){
							int x = killer->getMaxHp() - killer->getHp();
							RecoverStruct recover;
							recover.who = killer;
							recover.recover = x;
							room->recover(killer, recover);
						}
						if (killer->getHandcardNum() < killer->getMaxHp()){
							int x = killer->getMaxHp() - killer->getHandcardNum();
							killer->drawCards(x);
						}
					}
				}
			}
		}

        if (player->getGeneral()->isLord() && player->getRole() != "careerist" && player == data.value<DeathStruct>().who) {
            foreach (ServerPlayer *p, room->getOtherPlayers(player, true)){
                if (p->getKingdom() == player->getKingdom() || p->getMark(player->getKingdom()) > 0){
                    room->setPlayerMark(p, player->getKingdom(), 0);
					if (p->hasShownOneGeneral())
                        room->setPlayerProperty(p, "role", "careerist");
                    else {
                        p->setRole("careerist");
                        room->notifyProperty(p, p, "role");
                    }
                }
            }
        }
        //
        break;
    }
    case FinishRetrial: {
        JudgeStruct *judge = data.value<JudgeStruct *>();

        LogMessage log;
        log.type = "$JudgeResult";
        log.from = player;
        log.card_str = QString::number(judge->card->getEffectiveId());
        room->sendLog(log);

        int delay = Config.AIDelay;
        if (judge->time_consuming) delay /= 1.25;
        Q_ASSERT(room->getThread() != NULL);
        room->getThread()->delay(delay);
        if (judge->play_animation) {
            room->sendJudgeResult(judge);
            room->getThread()->delay(Config.S_JUDGE_LONG_DELAY);
        }

        break;
    }
    case FinishJudge: {
        JudgeStruct *judge = data.value<JudgeStruct *>();

        if (room->getCardPlace(judge->card->getEffectiveId()) == Player::PlaceJudge) {
            CardMoveReason reason(CardMoveReason::S_REASON_JUDGEDONE, judge->who->objectName(), QString(), judge->reason);
            room->moveCardTo(judge->card, judge->who, NULL, Player::DiscardPile, reason, true);
        }

        break;
    }
    case ChoiceMade: {
        foreach (ServerPlayer *p, room->getAlivePlayers()) {
            foreach (const QString &flag, p->getFlagList()) {
                if (flag.startsWith("Global_") && flag.endsWith("Failed"))
                    room->setPlayerFlag(p, "-" + flag);
            }
        }
        break;
    }
    case GeneralShown: {
        QString winner = getWinner(player);
        if (!winner.isNull()) {
            room->gameOver(winner); // if all hasShownGenreal, and they are all friend, game over.
            return true;
        }
        if (Config.RewardTheFirstShowingPlayer && room->getTag("TheFirstToShowRewarded").isNull() && room->getScenario() == NULL) {
            LogMessage log;
            log.type = "#FirstShowReward";
            log.from = player;
            room->sendLog(log);
            if (player->askForSkillInvoke("userdefine:FirstShowReward"))
                player->drawCards(2);
            room->setTag("TheFirstToShowRewarded", true);
        }
        if (player->isAlive() && player->hasShownAllGenerals()) {
            if (player->getMark("CompanionEffect") > 0) {
                QStringList choices;
                if (player->isWounded())
                    choices << "recover";
                choices << "draw" << "cancel";
                LogMessage log;
                log.type = "#CompanionEffect";
                log.from = player;
                room->sendLog(log);
                QString choice = room->askForChoice(player, "CompanionEffect", choices.join("+"));
                if (choice == "recover") {
                    RecoverStruct recover;
                    recover.who = player;
                    recover.recover = 1;
                    room->recover(player, recover);
                } else if (choice == "draw")
                    player->drawCards(2);
                room->removePlayerMark(player, "CompanionEffect");

                room->setEmotion(player, "companion");
            }
            if (player->getMark("HalfMaxHpLeft") > 0) {
                LogMessage log;
                log.type = "#HalfMaxHpLeft";
                log.from = player;
                room->sendLog(log);
                if (player->askForSkillInvoke("userdefine:halfmaxhp"))
                    player->drawCards(1);
                room->removePlayerMark(player, "HalfMaxHpLeft");
            }
        }
    }
    case BeforeCardsMove: {
        if (data.canConvert<CardsMoveOneTimeStruct>()) {
            CardsMoveOneTimeStruct move = data.value<CardsMoveOneTimeStruct>();
            bool should_find_io = false;
            if (move.to_place == Player::DiscardPile) {
                if (move.reason.m_reason != CardMoveReason::S_REASON_USE) {
                    should_find_io = true; // not use
                } else if (move.card_ids.length() > 1) {
                    should_find_io = true; // use card isn't IO
                } else {
                    const Card *card = Sanguosha->getCard(move.card_ids.first());
                    if (card->isKindOf("ImperialOrder") && !card->hasFlag("imperial_order_normal_use"))
                        should_find_io = true; // use card isn't IO
                }
            }
            if (should_find_io) {
                foreach (int id, move.card_ids) {
                    const Card *card = Sanguosha->getCard(id);
                    if (card->isKindOf("ImperialOrder")) {
                        room->moveCardTo(card, NULL, Player::PlaceTable, true);
                        room->getPlayers().first()->addToPile("#imperial_order", card, false);
                        LogMessage log;
                        log.type = "#RemoveImperialOrder";
                        log.arg = "imperial_order";
                        room->sendLog(log);
                        room->setTag("ImperialOrderInvoke", true);
                        room->setTag("ImperialOrderCard", QVariant::fromValue(card));
                        int i = move.card_ids.indexOf(id);
                        move.from_places.removeAt(i);
                        move.open.removeAt(i);
                        move.from_pile_names.removeAt(i);
                        move.card_ids.removeOne(id);
                        data = QVariant::fromValue(move);
                        break;
                    }
                }
            }
        }
        break;
    }
    case CardsMoveOneTime: {
        if (data.canConvert<CardsMoveOneTimeStruct>()) {
            CardsMoveOneTimeStruct move = data.value<CardsMoveOneTimeStruct>();
            if (move.from_places.contains(Player::DrawPile) && room->getDrawPile().isEmpty())
                room->swapPile();
        }

        break;
    }
    default:
        break;
    }

    return false;
}

void GameRule::rewardAndPunish(ServerPlayer *killer, ServerPlayer *victim) const
{
    // M&M 新增规则的死亡奖惩内容
	Q_ASSERT(killer->getRoom() != NULL);
	Room *room = killer->getRoom();

	if (killer->hasShownOneGeneral()){
		if (killer->getMark("xuexi_open") && killer->isFriendWith(victim)){ // 血洗模式规则2
			room->doLightbox("$xuexi_1", 2000);
			room->setPlayerProperty(killer, "role", "careerist");
		}
		if (killer->getMark("@zhengfeng_lord") > 0 && killer->isFriendWith(victim)){ // 争锋模式规则4
			room->doLightbox("$zhengfeng_1", 2000);
			room->setPlayerProperty(victim, "role", "careerist");
		}
		if (victim->getMark("@zhengfeng_lord") > 0 && killer->getRole() == "careerist"){ // 争锋模式规则4
			room->doLightbox("$zhengfeng_3", 2000);
			room->setPlayerMark(killer, "@zhengfeng_lord", 1);
			room->setPlayerMark(victim, "@zhengfeng_lord", 0);
			room->setPlayerProperty(killer, "role", HegemonyMode::GetMappedRole(victim->getGeneral()->getKingdom()));
			room->setPlayerProperty(killer, "kingdom", victim->getGeneral()->getKingdom());
			room->setPlayerProperty(killer, "maxhp", killer->getMaxHp() + 1);
			if (killer->getHandcardNum() < killer->getMaxHp()){
				int x = killer->getMaxHp() - killer->getHandcardNum();
				killer->drawCards(x);
			}
			room->setPlayerProperty(victim, "role", "careerist");
		}
		if (victim->getMark("@zhengfeng_lord") > 0 && killer->isFriendWith(victim) && victim->objectName() != killer->objectName()){
			room->doLightbox("$zhengfeng_2", 2000); // 争锋模式规则4
			room->setPlayerProperty(killer, "role", "careerist");
		}
	}
	if (killer->isDead())
		return;
	//
    if (!killer->isFriendWith(victim)) {
        int n = 1;
        foreach (ServerPlayer *p, room->getOtherPlayers(victim)) {
            if (victim->isFriendWith(p))
                ++n;
        }
        killer->drawCards(n);
    } else
        killer->throwAllHandCardsAndEquips();
}

QString GameRule::getWinner(ServerPlayer *victim) const
{
    Room *room = victim->getRoom();
    QStringList winners;
    QList<ServerPlayer *> players = room->getAlivePlayers();
    ServerPlayer *win_player = players.first();
    if (players.length() == 1) {
        if (!win_player->hasShownGeneral1())
            win_player->showGeneral(true, false, false);
        if (!win_player->hasShownGeneral2())
            win_player->showGeneral(false, false, false);
        foreach (ServerPlayer *p, room->getPlayers()) {
            if (win_player->isFriendWith(p))
                winners << p->objectName();
        }
    } else {
        bool has_diff_kingdoms = false;
        foreach (ServerPlayer *p, players) {
            foreach (ServerPlayer *p2, players) {
                if (p->hasShownOneGeneral() && p2->hasShownOneGeneral() && !p->isFriendWith(p2)) {
                    has_diff_kingdoms = true;
                    break;// if both shown but not friend, hehe.
                }
                if ((p->hasShownOneGeneral() && !p2->hasShownOneGeneral() && !p2->willBeFriendWith(p))
                    || (!p->hasShownOneGeneral() && p2->hasShownOneGeneral() && !p->willBeFriendWith(p2))) {
                    has_diff_kingdoms = true;
                    break;// if either shown but not friend, hehe.
                }
                if (!p->hasShownOneGeneral() && !p2->hasShownOneGeneral()) {
                    if (p->getActualGeneral1()->getKingdom() != p2->getActualGeneral1()->getKingdom()) {
                        has_diff_kingdoms = true;
                        break;  // if neither shown and not friend, hehe.
                    }
                }
            }
            if (has_diff_kingdoms)
                break;
        }
        if (!has_diff_kingdoms) { // judge careerist
            QMap<QString, int> kingdoms;
            QSet<QString> lords;
            foreach(ServerPlayer *p, room->getPlayers())
                if (p->isLord() || p->getActualGeneral1()->isLord())
                    if (p->isAlive())
                        lords << p->getActualGeneral1()->getKingdom();
            foreach (ServerPlayer *p, room->getPlayers()) {
                QString kingdom;
                if (p->hasShownOneGeneral())
                    kingdom = p->getKingdom();
                else if (!lords.isEmpty())
                    return QString(); // if hasLord() and there are someone haven't shown its kingdom, it means this one could kill
                // the lord to become careerist.
                else
                    kingdom = p->getActualGeneral1()->getKingdom();
                if (lords.contains(kingdom)) continue;
                if (room->getLord(kingdom, true) && room->getLord(kingdom, true)->isDead())
                    kingdoms[kingdom] += 10;
                else
                    kingdoms[kingdom] ++;
                if (p->isAlive() && !p->hasShownOneGeneral() && kingdoms[kingdom] > room->getPlayers().length() / 2) {
                    has_diff_kingdoms = true;
                    break;  //has careerist, hehe
                }
            }
        }

        if (has_diff_kingdoms) return QString();    //if has enemy, hehe

        // if run here, all are friend.
        foreach (ServerPlayer *p, players) {
            if (!p->hasShownGeneral1())
                p->showGeneral(true, false, false); // dont trigger event
            if (!p->hasShownGeneral2())
                p->showGeneral(false, false, false);
        }

        foreach (ServerPlayer *p, room->getPlayers()) {
            if (win_player->isFriendWith(p))
                winners << p->objectName();
        }
    }

    return winners.join("+");
}
