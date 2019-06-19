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

import telebot, asyncdispatch, logging, options


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
        discard await restrictChatMember(b, $response.chat.id, response.fromUser.get.id, canSendMessages = false)
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

            var msg = newMessage(response.chat.id, "Gbanned this tard!")
            msg.replyToMessageId = response.messageId
            discard await b.send(msg)
        else:
            var msg = newMessage(response.chat.id, "This tard is already gbanned!")
            msg.replyToMessageId = response.messageId
            discard await b.send(msg)
    else:
        var msg = newMessage(response.chat.id, "Only sudos can execute this command!")
        msg.replyToMessageId = response.messageId
        discard await b.send(msg)

proc ungbanHandler*(b: TeleBot, c: Command) {.async.} =
    let response = c.message

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

            var msg = newMessage(response.chat.id, "User unGbanned!")
            msg.replyToMessageId = response.messageId
            discard await b.send(msg)
        else:
            var msg = newMessage(response.chat.id, "This guy was never Gbanned!")
            msg.replyToMessageId = response.messageId
            discard await b.send(msg)
    else:
        var msg = newMessage(response.chat.id, "Only sudos can execute this command!")
        msg.replyToMessageId = response.messageId
        discard await b.send(msg)

proc gmuteHandler*(b: TeleBot, c: Command) {.async.} =
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
    
        let gbanList = waitFor getRedisList("gmuted")

        if not (banid in gbanList):
            await appRedisList("gmuted", banid)

            var msg = newMessage(response.chat.id, "Gmuted this tard!")
            msg.replyToMessageId = response.messageId
            discard await b.send(msg)
        else:
            var msg = newMessage(response.chat.id, "This tard is already gmuted!")
            msg.replyToMessageId = response.messageId
            discard await b.send(msg)
    else:
        var msg = newMessage(response.chat.id, "Only sudos can execute this command!")
        msg.replyToMessageId = response.messageId
        discard await b.send(msg)

proc ungmuteHandler*(b: TeleBot, c: Command) {.async.} =
    let response = c.message

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
                        discard await restrictChatMember(b, group, parseInt(banid),
                        canSendMessages = true,
                        canSendMediaMessages = true,
                        canSendOtherMessages = true,
                        canAddWebPagePreviews = true)

            var msg = newMessage(response.chat.id, "User unGmuted!")
            msg.replyToMessageId = response.messageId
            discard await b.send(msg)
        else:
            var msg = newMessage(response.chat.id, "This guy was never Gmuted!")
            msg.replyToMessageId = response.messageId
            discard await b.send(msg)
    else:
        var msg = newMessage(response.chat.id, "Only sudos can execute this command!")
        msg.replyToMessageId = response.messageId
        discard await b.send(msg)