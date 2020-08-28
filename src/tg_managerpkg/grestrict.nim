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


proc grestrictListener*(b: TeleBot, u: Update) {.async.} =
    let res = u.message
    var response: Message
    if res.isSome:
        response = res.get
    else:
        return

    if not (await canBotRestrict(b, response)):
        return

    let gbanList = waitFor getRedisList("gbanned")
    if $response.fromUser.get.id in gbanList:
        discard await kickChatMember(b, $response.chat.id, response.fromUser.get.id, (toUnix(getTime()) - 31).int)
        await appRedisList("gban-groups-" & $response.fromUser.get.id, $response.chat.id)

    let gmuteList = waitFor getRedisList("gmuted")
    if $response.fromUser.get.id in gmuteList:
        let perms = ChatPermissions(canSendMessages : some(false))
        discard await restrictChatMember(b, $response.chat.id, response.fromUser.get.id, perms)
        await appRedisList("gmute-groups-" & $response.fromUser.get.id, $response.chat.id)

proc gbanHandler*(b: TeleBot, c: Command) {.async.} =
    let response = c.message

    if response.fromUser.get.id in sudos or $response.fromUser.get.id == owner:
        let bot = await b.getMe()
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
        if banid == $bot.id or parseInt(banid) in sudos or banid == owner:
            return

        let gbanList = waitFor getRedisList("gbanned")

        if not (banid in gbanList):
            await appRedisList("gbanned", banid)

            discard await b.sendMessage(response.chat.id, "Gbanned this tard!", replyToMessageId = response.messageId)
        else:
            discard await b.sendMessage(response.chat.id, "This tard is already gbanned!", replyToMessageId = response.messageId)
    else:
        discard await b.sendMessage(response.chat.id, "Only sudos can execute this command!", replyToMessageId = response.messageId)

proc ungbanHandler*(b: TeleBot, c: Command) {.async.} =
    let response = c.message
    var msgTxt: string

    if response.fromUser.get.id in sudos or $response.fromUser.get.id == owner:
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

        let gbanList = waitFor getRedisList("gbanned")

        if banid in gbanList:
            await rmRedisList("gbanned", banid)
            let gbannedGroups = waitFor getRedisList("gban-groups-" & banid)
            if not (gbannedGroups == @[]):
                for group in gbannedGroups:
                    if await canBotRestrict2(b, group):
                        discard await unbanChatMember(b, group, parseInt(banid))
            msgTxt = "User unGbanned"
        else:
            msgTxt = "Only sudos can execute this command!"
    else:
        msgTxt = "Only sudos can execute this command!"

    discard await b.sendMessage(response.chat.id, msgTxt, replyToMessageId = response.messageId)

proc gmuteHandler*(b: TeleBot, c: Command) {.async.} =
    let response = c.message
    var msgTxt: string

    if response.fromUser.get.id in sudos or $response.fromUser.get.id == owner:
        let bot = await b.getMe()
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
        if banid == $bot.id or parseInt(banid) in sudos or banid == owner:
            return

        let gbanList = waitFor getRedisList("gmuted")

        if not (banid in gbanList):
            await appRedisList("gmuted", banid)
            msgTxt = "Gmuted this tard!"
        else:
            msgTxt = "This tard is already gmuted!"
    else:
        msgTxt = "Only sudos can execute this command!"

    discard await b.sendMessage(response.chat.id, msgTxt, replyToMessageId = response.messageId)

proc ungmuteHandler*(b: TeleBot, c: Command) {.async.} =
    let response = c.message
    var msgTxt: string

    if response.fromUser.get.id in sudos or $response.fromUser.get.id == owner:
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

        let gbanList = waitFor getRedisList("gmuted")

        if banid in gbanList:
            await rmRedisList("gmuted", banid)
            let gmutedGroups = waitFor getRedisList("gmute-groups-" & banid)
            if not (gmutedGroups == @[]):
                for group in gmutedGroups:
                    if await canBotRestrict2(b, group):
                        let perms = ChatPermissions(canSendMessages: some(true), 
                        canSendMediaMessages: some(true),
                        canSendOtherMessages: some(true),
                        canAddWebPagePreviews: some(true))
                        discard await restrictChatMember(b, group, parseInt(banid), perms)

            msgTxt = "User unGmuted!"
        else:
            msgTxt = "This guy was never Gmuted!"
    else:
        msgTxt = "Only sudos can execute this command!"

    discard await b.sendMessage(response.chat.id, msgTxt, replyToMessageId = response.messageId)
