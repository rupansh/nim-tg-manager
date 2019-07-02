# Copyright (C) 2019 Rupansh Sekar
#
# Licensed under the Raphielscape Public License, Version 1.b (the "License");
# you may not use this file except in compliance with the License.
#

import config
import essentials
from strutils import split, parseInt
import times

import telebot, asyncdispatch, logging, options


proc banHandler*(b: TeleBot, c: Command) {.async.} =
    let response = c.message
    let bot = await b.getMe()
    var banId = 0
    var failStr = "Reply to a user to ban them"
    if not (await canBotRestrict(b, response)):
        var msg = newMessage(response.chat.id, "I can't ban users!")
        msg.replyToMessageId = response.messageId
        discard await b.send(msg)
        return

    if response.replyToMessage.isSome:
        banId = response.replyToMessage.get.fromUser.get.id
    elif ' ' in response.text.get:
        if response.text.get.split(" ").len > 1:
            banId = parseInt(response.text.get.split(" ")[^1])
            if not (await isUserInChat(b, response.chat.id.int, banId)):
                banId = 0
                failStr = "Invalid user id"

    if banId == bot.id:
        banId = 0
        failStr = "I am not banning myself :^)"
    elif await isUserAdm(b, response.chat.id.int, banId):
        banId = 0
        failStr = "I can't touch this guy :^("

    if await isUserAdm(b, response.chat.id.int, response.fromUser.get.id):
        if banId == 0:
            var msg = newMessage(response.chat.id, failStr)
            msg.replyToMessageId = response.messageId
            discard await b.send(msg)
        else:
            discard await kickChatMember(b, $response.chat.id, banId, (toUnix(getTime()) - 31).int)
            var msg = newMessage(response.chat.id, "They won't be bugging you in this chat anymore!")
            msg.replyToMessageId = response.messageId
            discard await b.send(msg)
    else:
        var msg = newMessage(response.chat.id, "You aren't adm :^(")
        msg.replyToMessageId = response.messageId
        discard await b.send(msg)

proc tbanHandler*(b: TeleBot, c: Command) {.async.} =
    let response = c.message
    let bot = await b.getMe()
    var banId = 0
    var failStr = "Reply to a user to tban them!"
    if not (await canBotRestrict(b, response)):
        var msg = newMessage(response.chat.id, "I can't ban users!")
        msg.replyToMessageId = response.messageId
        discard await b.send(msg)
        return

    var time = getTime(b, response)
    if time == 0:
        return

    if await isUserAdm(b, response.chat.id.int, response.fromUser.get.id):
        if response.replyToMessage.isSome:
            banId = response.replyToMessage.get.fromUser.get.id
        elif ' ' in response.text.get:
            if response.text.get.split(" ").len > 2:
                banId = parseInt(response.text.get.split(" ")[^1])
                if not (await isUserInChat(b, response.chat.id.int, banId)):
                    banId = 0
                    failStr = "Invalid user id"
    
        if banId == bot.id:
            banId = 0
            failStr = "I am not banning myself :^)"
        elif await isUserAdm(b, response.chat.id.int, banId):
            banId = 0
            failStr = "I can't touch this guy :^("

        if banId == 0:
            var msg = newMessage(response.chat.id, failStr)
            msg.replyToMessageId = response.messageId
            discard await b.send(msg)
        else:
            discard await kickChatMember(b, $response.chat.id, banId, time)
            var msg = newMessage(response.chat.id, "They won't be bugging you in this chat for the next " & response.text.get.split(" ")[^1])
            msg.replyToMessageId = response.messageId
            discard await b.send(msg)
    else:
        var msg = newMessage(response.chat.id, "You aren't adm :^(")
        msg.replyToMessageId = response.messageId
        discard await b.send(msg)

proc banMeHandler*(b: TeleBot, c: Command) {.async.} =
    let response = c.message
    if not (await canBotRestrict(b, response)):
        var msg = newMessage(response.chat.id, "I can't ban users!")
        msg.replyToMessageId = response.messageId
        discard await b.send(msg)
        return

    if await isUserAdm(b, response.chat.id.int, response.replyToMessage.get.fromUser.get().id):
        var msg = newMessage(response.chat.id, "I can't touch you :^(")
        msg.replyToMessageId = response.messageId
        discard await b.send(msg)
        return

    discard await kickChatMember(b, $response.chat.id, response.replyToMessage.get.fromUser.get().id, toUnix(getTime()).int - 31)
    var msg = newMessage(response.chat.id, "Get Out lol")
    msg.replyToMessageId = response.messageId
    discard await b.send(msg)

proc unbanHandler*(b: TeleBot, c: Command) {.async.} =
    let response = c.message
    let bot = await b.getMe()
    var unbanId = 0
    var failStr = "Reply to a user to unban them"
    if not (await canBotRestrict(b, response)):
        var msg = newMessage(response.chat.id, "I can't unban users!")
        msg.replyToMessageId = response.messageId
        discard await b.send(msg)
        return

    if await isUserAdm(b, response.chat.id.int, response.fromUser.get.id):
        if response.replyToMessage.isSome:
            unbanId = response.replyToMessage.get.fromUser.get.id
        elif ' ' in response.text.get:
            if response.text.get.split(" ").len > 1:
                unbanId = parseInt(response.text.get.split(" ")[^1])
                try:
                    let usr = await getChatMember(b, $response.chat.id.int, unbanId)
                    if usr.untilDate.isNone:
                        unbanId = 0
                        failStr = "He's already in the group"
                except IOError:
                    unbanId = 0
                    failStr = "Invalid user id"
    
        if unbanId == bot.id:
            unbanId = 0
            failStr = "Why'd i unban myself when i am here :v"

        if unbanId == 0:
            var msg = newMessage(response.chat.id, failStr)
            msg.replyToMessageId = response.messageId
            discard await b.send(msg)
        else:
            discard await unbanChatMember(b, $response.chat.id, unbanId)
            var msg = newMessage(response.chat.id, "Unbanned!")
            msg.replyToMessageId = response.messageId
            discard await b.send(msg)
    else:
        var msg = newMessage(response.chat.id, "You aren't adm :^(")
        msg.replyToMessageId = response.messageId
        discard await b.send(msg)

proc kickHandler*(b: TeleBot, c: Command) {.async.} =
    let response = c.message
    let bot = await b.getMe()
    var kickId = 0
    var failStr = "Reply to a user to kick them!"
    if not (await canBotRestrict(b, response)):
        var msg = newMessage(response.chat.id, "I can't kick users!")
        msg.replyToMessageId = response.messageId
        discard await b.send(msg)
        return

    if await isUserAdm(b, response.chat.id.int, response.fromUser.get.id):
        if response.replyToMessage.isSome:
            kickId = response.replyToMessage.get.fromUser.get.id
        elif ' ' in response.text.get:
            if response.text.get.split(" ").len > 1:
                kickId = parseInt(response.text.get.split(" ")[^1])
                if not (await isUserInChat(b, response.chat.id.int, kickId)):
                    kicKId = 0
                    failStr = "Invalid user id"
    
        if kickId == bot.id:
            kickId = 0
            failStr = "I am not kicking myself :^)"
        elif await isUserAdm(b, response.chat.id.int, kickId):
            kickId = 0
            failStr = "I can't touch this guy :^("

        if kickId == 0:
            var msg = newMessage(response.chat.id, failStr)
            msg.replyToMessageId = response.messageId
            discard await b.send(msg)
        else:
            discard await kickChatMember(b, $response.chat.id, response.replyToMessage.get.fromUser.get().id, toUnix(getTime()).int + 1)
            var msg = newMessage(response.chat.id, "Kicked!")
            msg.replyToMessageId = response.messageId
            discard await b.send(msg)
    else:
        var msg = newMessage(response.chat.id, "You aren't adm :^(")
        msg.replyToMessageId = response.messageId
        discard await b.send(msg)

proc kickMeHandler*(b: TeleBot, c: Command) {.async.} =
        let response = c.message
        if not (await canBotRestrict(b, response)):
            var msg = newMessage(response.chat.id, "I can't kick users!")
            msg.replyToMessageId = response.messageId
            discard await b.send(msg)
            return

        if await isUserAdm(b, response.chat.id.int, response.replyToMessage.get.fromUser.get().id):
            var msg = newMessage(response.chat.id, "I can't touch you :^(")
            msg.replyToMessageId = response.messageId
            discard await b.send(msg)
            return

        discard await kickChatMember(b, $response.chat.id, response.replyToMessage.get.fromUser.get().id, toUnix(getTime()).int + 1)
        var msg = newMessage(response.chat.id, "Get Out lol")
        msg.replyToMessageId = response.messageId
        discard await b.send(msg)

proc muteHandler*(b: TeleBot, c: Command) {.async.} =
    let response = c.message
    let bot = await b.getMe()
    var muteId = 0
    var failStr = "Reply to a user to mute them!"
    if not (await canBotRestrict(b, response)):
        var msg = newMessage(response.chat.id, "I can't mute users!")
        msg.replyToMessageId = response.messageId
        discard await b.send(msg)
        return

    if await isUserAdm(b, response.chat.id.int, response.fromUser.get.id):
        if response.replyToMessage.isSome:
            muteId = response.replyToMessage.get.fromUser.get.id
        elif ' ' in response.text.get:
            if response.text.get.split(" ").len > 1:
                muteId = parseInt(response.text.get.split(" ")[^1])
                if not (await isUserInChat(b, response.chat.id.int, muteId)):
                    muteId = 0
                    failStr = "Invalid user id"
    
        if muteId == bot.id:
            muteId = 0
            failStr = "I am not muting myself :^)"
        elif await isUserAdm(b, response.chat.id.int, muteId):
            muteId = 0
            failStr = "I can't touch this guy :^("

        if muteId == 0:
            var msg = newMessage(response.chat.id, failStr)
            msg.replyToMessageId = response.messageId
            discard await b.send(msg)
        else:
            let user = await getChatMember(b, $response.chat.id.int, response.replyToMessage.get.fromUser.get().id)
            if user.canSendMessages.isNone or user.canSendMessages.get:
                discard await restrictChatMember(b, $response.chat.id, response.replyToMessage.get.fromUser.get().id, canSendMessages = false)
                var msg = newMessage(response.chat.id, "User Muted!")
                msg.replyToMessageId = response.messageId
                discard await b.send(msg)
            else:
                var msg = newMessage(response.chat.id, "User is already muted!")
                msg.replyToMessageId = response.messageId
                discard await b.send(msg)
    else:
        var msg = newMessage(response.chat.id, "You aren't Adm! :^(")
        msg.replyToMessageId = response.messageId
        discard await b.send(msg)

proc tmuteHandler*(b: TeleBot, c: Command) {.async.} =
    let response = c.message
    let bot = await b.getMe()
    var muteId = 0
    var failStr = "Reply to a user to tmute them!"
    if not (await canBotRestrict(b, response)):
        var msg = newMessage(response.chat.id, "I can't mute users!")
        msg.replyToMessageId = response.messageId
        discard await b.send(msg)
        return

    var time = getTime(b, response)
    if time == 0:
        return

    if await isUserAdm(b, response.chat.id.int, response.fromUser.get.id):
        if response.replyToMessage.isSome:
            muteId = response.replyToMessage.get.fromUser.get.id
        elif ' ' in response.text.get:
            if response.text.get.split(" ").len > 2:
                muteId = parseInt(response.text.get.split(" ")[^1])
                if not (await isUserInChat(b, response.chat.id.int, muteId)):
                    muteId = 0
                    failStr = "Invalid user id"
    
        if muteId == bot.id:
            muteId = 0
            failStr = "I am not muting myself :^)"
        elif await isUserAdm(b, response.chat.id.int, muteId):
            muteId = 0
            failStr = "I can't touch this guy :^("

        if muteId == 0:
            var msg = newMessage(response.chat.id, failStr)
            msg.replyToMessageId = response.messageId
            discard await b.send(msg)
        else:
            let user = await getChatMember(b, $response.chat.id.int, response.replyToMessage.get.fromUser.get().id)
            if user.canSendMessages.isNone or user.canSendMessages.get:
                discard await restrictChatMember(b, $response.chat.id, response.replyToMessage.get.fromUser.get().id, untilDate = time, canSendMessages = false)
                var msg = newMessage(response.chat.id, "User Muted for the next " & response.text.get.split(" ")[^1])
                msg.replyToMessageId = response.messageId
                discard await b.send(msg)
            else:
                var msg = newMessage(response.chat.id, "User is already muted!")
                msg.replyToMessageId = response.messageId
                discard await b.send(msg)
    else:
        var msg = newMessage(response.chat.id, "You aren't Adm :^(")
        msg.replyToMessageId = response.messageId
        discard await b.send(msg)

proc unmuteHandler*(b: TeleBot, c: Command) {.async.} =
    let response = c.message
    var unmuteId = 0
    var failStr = "Reply to a user to unmute them!"
    if not (await canBotRestrict(b, response)):
        var msg = newMessage(response.chat.id, "I can't unmute users!")
        msg.replyToMessageId = response.messageId
        discard await b.send(msg)
        return

    if await isUserAdm(b, response.chat.id.int, response.fromUser.get.id):
        if response.replyToMessage.isSome:
            unmuteId = response.replyToMessage.get.fromUser.get.id
        elif ' ' in response.text.get:
            if response.text.get.split(" ").len > 1:
                unmuteId = parseInt(response.text.get.split(" ")[^1])
                if not (await isUserInChat(b, response.chat.id.int, unmuteId)):
                    unmuteId = 0
                    failStr = "Invalid user id"
    
        if await isUserAdm(b, response.chat.id.int, unmuteId):
            unmuteId = 0
            failStr = "This guy can't be muted lol! so no need to unmute"

        if unmuteId == 0:
            var msg = newMessage(response.chat.id, failStr)
            msg.replyToMessageId = response.messageId
            discard await b.send(msg)
        else:
            let user = await getChatMember(b, $response.chat.id.int, response.replyToMessage.get.fromUser.get().id)
            if not(user.canSendMessages.isNone or user.canSendMessages.get):
                discard await restrictChatMember(b, $response.chat.id, response.replyToMessage.get.fromUser.get().id,
                canSendMessages = true,
                canSendMediaMessages = true,
                canSendOtherMessages = true,
                canAddWebPagePreviews = true)
                var msg = newMessage(response.chat.id, "User Un-Muted!")
                msg.replyToMessageId = response.messageId
                discard await b.send(msg)
            else:
                var msg = newMessage(response.chat.id, "User was never muted")
                msg.replyToMessageId = response.messageId
                discard await b.send(msg)
    else:
        var msg = newMessage(response.chat.id, "You aren't Adm :^(")
        msg.replyToMessageId = response.messageId
        discard await b.send(msg)
