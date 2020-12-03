# Copyright (C) 2019 Rupansh Sekar
#
# Licensed under the Raphielscape Public License, Version 1.b (the "License");
# you may not use this file except in compliance with the License.
#

import config
import essentials
import redishandling
from strutils import split, parseInt
import times

import telebot, asyncdispatch, options


proc grestrictListener*(b: TgManager, u: Update) {.async.} =
    let res = u.message
    var response: Message
    if res.isSome:
        response = res.get
    else:
        return

    if not (await canBotRestrict(b, response)):
        return

    let gbanList = await b.db.getRedisList("gbanned")
    if $response.fromUser.get.id in gbanList:
        discard await kickChatMember(b.bot, $response.chat.id, response.fromUser.get.id, (toUnix(getTime()) - 31).int)
        await b.db.appRedisList("gban-groups-" & $response.fromUser.get.id, $response.chat.id)

    let gmuteList = await b.db.getRedisList("gmuted")
    if $response.fromUser.get.id in gmuteList:
        let perms = ChatPermissions(canSendMessages : some(false))
        discard await restrictChatMember(b.bot, $response.chat.id, response.fromUser.get.id, perms)
        await b.db.appRedisList("gmute-groups-" & $response.fromUser.get.id, $response.chat.id)

proc gbanHandler*(b: TgManager, c: Command) {.async.} =
    let response = c.message
    var msgTxt: string

    if response.fromUser.get.id in b.config.sudos or $response.fromUser.get.id == b.config.owner:
        let bot = await b.bot.getMe()
        var banid: string

        if response.replyToMessage.isSome:
            banid = $response.replyToMessage.get.fromUser.get.id
        elif ' ' in response.text.get:
            if response.text.get.split(" ").len > 1:
                banid = response.text.get.split(" ")[^1]
            else:
                return
        else:
            return
        if banid == $bot.id or parseInt(banid) in b.config.sudos or banid == b.config.owner:
            return

        let gbanList = await b.db.getRedisList("gbanned")

        var msgTxt: string
        if not (banid in gbanList):
            await b.db.appRedisList("gbanned", banid)
            msgTxt = "Gbanned this tard!"
        else:
            msgTxt = "This tard is already gbanned!"
    else:
        msgTxt = "Only sudos can execute this command!"

    discard await b.bot.sendMessage(response.chat.id, msgTxt, replyToMessageId = response.messageId)

proc ungbanHandler*(b: TgManager, c: Command) {.async.} =
    let response = c.message
    var msgTxt: string

    if response.fromUser.get.id in b.config.sudos or $response.fromUser.get.id == b.config.owner:
        var banid: string

        if response.replyToMessage.isSome:
            banid = $response.replyToMessage.get.fromUser.get.id
        elif ' ' in response.text.get:
            if response.text.get.split(" ").len > 1:
                banid = response.text.get.split(" ")[^1]
            else:
                return
        else:
            return

        let gbanList = await b.db.getRedisList("gbanned")

        if banid in gbanList:
            await b.db.rmRedisList("gbanned", banid)
            let gbannedGroups = await b.db.getRedisList("gban-groups-" & banid)
            if not (gbannedGroups == @[]):
                for group in gbannedGroups:
                    if await canBotRestrict2(b, group):
                        discard await unbanChatMember(b.bot, group, parseInt(banid))
            msgTxt = "User unGbanned"
        else:
            msgTxt = "Only sudos can execute this command!"
    else:
        msgTxt = "Only sudos can execute this command!"

    discard await b.bot.sendMessage(response.chat.id, msgTxt, replyToMessageId = response.messageId)

proc gmuteHandler*(b: TgManager, c: Command) {.async.} =
    let response = c.message
    var msgTxt: string

    if response.fromUser.get.id in b.config.sudos or $response.fromUser.get.id == b.config.owner:
        let bot = await b.bot.getMe()
        var banid: string

        if response.replyToMessage.isSome:
            banid = $response.replyToMessage.get.fromUser.get.id
        elif ' ' in response.text.get:
            if response.text.get.split(" ").len > 1:
                banid = response.text.get.split(" ")[^1]
            else:
                return
        else:
            return
        if banid == $bot.id or parseInt(banid) in b.config.sudos or banid == b.config.owner:
            return

        let gbanList = await b.db.getRedisList("gmuted")

        if not (banid in gbanList):
            await b.db.appRedisList("gmuted", banid)
            msgTxt = "Gmuted this tard!"
        else:
            msgTxt = "This tard is already gmuted!"
    else:
        msgTxt = "Only sudos can execute this command!"

    discard await b.bot.sendMessage(response.chat.id, msgTxt, replyToMessageId = response.messageId)

proc ungmuteHandler*(b: TgManager, c: Command) {.async.} =
    let response = c.message
    var msgTxt: string

    if response.fromUser.get.id in b.config.sudos or $response.fromUser.get.id == b.config.owner:
        var banid: string

        if response.replyToMessage.isSome:
            banid = $response.replyToMessage.get.fromUser.get.id
        elif ' ' in response.text.get:
            if response.text.get.split(" ").len > 1:
                banid = response.text.get.split(" ")[^1]
            else:
                return
        else:
            return

        let gbanList = await b.db.getRedisList("gmuted")

        if banid in gbanList:
            await b.db.rmRedisList("gmuted", banid)
            let gmutedGroups = await b.db.getRedisList("gmute-groups-" & banid)
            if not (gmutedGroups == @[]):
                for group in gmutedGroups:
                    if await canBotRestrict2(b, group):
                        let perms = ChatPermissions(canSendMessages: some(true), 
                        canSendMediaMessages: some(true),
                        canSendOtherMessages: some(true),
                        canAddWebPagePreviews: some(true))
                        discard await restrictChatMember(b.bot, group, parseInt(banid), perms)

            msgTxt = "User unGmuted!"
        else:
            msgTxt = "This guy was never Gmuted!"
    else:
        msgTxt = "Only sudos can execute this command!"

    discard await b.bot.sendMessage(response.chat.id, msgTxt, replyToMessageId = response.messageId)
