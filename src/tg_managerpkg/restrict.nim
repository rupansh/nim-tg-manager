# Copyright (C) 2019 Rupansh Sekar
#
# Licensed under the Raphielscape Public License, Version 1.b (the "License");
# you may not use this file except in compliance with the License.
#

import essentials
from strutils import split, parseInt
import times

import telebot, asyncdispatch, options


proc banHandler*(b: TgManager, c: Command) {.async.} =
    let response = c.message
    let bot = await b.bot.getMe()
    var banId = 0
    var msgTxt = "Reply to a user to ban them"
    if not (await canBotRestrict(b, response)):
        discard await b.bot.sendMessage(response.chat.id, "I can't ban users!", replyToMessageId = response.messageId)
        return

    if response.replyToMessage.isSome:
        banId = response.replyToMessage.get.fromUser.get.id
    elif ' ' in response.text.get:
        if response.text.get.split(" ").len > 1:
            banId = parseInt(response.text.get.split(" ")[^1])
            if not (await isUserInChat(b, response.chat.id.int, banId)):
                banId = 0
                msgTxt = "Invalid user id"

    if banId == bot.id:
        banId = 0
        msgTxt = "I am not banning myself :^)"
    elif await isUserAdm(b, response.chat.id.int, banId):
        banId = 0
        msgTxt = "I can't touch this guy :^("

    if await isUserAdm(b, response.chat.id.int, response.fromUser.get.id):
        if banId != 0:
            discard await kickChatMember(b.bot, $response.chat.id, banId, (toUnix(getTime()) - 31).int)
            msgTxt = "They won't be bugging you in this chat anymore!"
    else:
        msgTxt = "You aren't adm :^("

    discard await b.bot.sendMessage(response.chat.id, msgTxt, replyToMessageId = response.messageId)

proc tbanHandler*(b: TgManager, c: Command) {.async.} =
    let response = c.message
    let bot = await b.bot.getMe()
    var banId = 0
    var msgTxt = "Reply to a user to tban them!"
    if not (await canBotRestrict(b, response)):
        discard await b.bot.sendMessage(response.chat.id, "I can't ban users!", replyToMessageId = response.messageId)
        return

    var time = await getTime(b, response)
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
                    msgTxt = "Invalid user id"
    
        if banId == bot.id:
            banId = 0
            msgTxt = "I am not banning myself :^)"
        elif await isUserAdm(b, response.chat.id.int, banId):
            banId = 0
            msgTxt = "I can't touch this guy :^("

        if banId != 0:
            discard await b.bot.kickChatMember($response.chat.id, banId, time)
            msgTxt = "They won't be bugging you in this chat for the next " & response.text.get.split(" ")[^1]
    else:
        msgTxt = "You aren't adm :^("

    discard await b.bot.sendMessage(response.chat.id, msgTxt, replyToMessageId = response.messageId)

proc banMeHandler*(b: TgManager, c: Command) {.async.} =
    let response = c.message
    if not (await canBotRestrict(b, response)):
        discard await b.bot.sendMessage(response.chat.id, "I can't ban users!", replyToMessageId = response.messageId)
        return

    if await isUserAdm(b, response.chat.id.int, response.replyToMessage.get.fromUser.get().id):
        discard await b.bot.sendMessage(response.chat.id, "I can't touch you :^(", replyToMessageId =response.messageId)
        return

    discard await kickChatMember(b.bot, $response.chat.id, response.replyToMessage.get.fromUser.get().id, toUnix(getTime()).int - 31)
    discard await b.bot.sendMessage(response.chat.id, "Get Out lol", replyToMessageId = response.messageId)

proc unbanHandler*(b: TgManager, c: Command) {.async.} =
    let response = c.message
    let bot = await b.bot.getMe()
    var unbanId = 0
    var msgTxt = "Reply to a user to unban them"
    if not (await canBotRestrict(b, response)):
        discard await b.bot.sendMessage(response.chat.id, "I can't unban users!", replyToMessageId = response.messageId)
        return

    if await isUserAdm(b, response.chat.id.int, response.fromUser.get.id):
        if response.replyToMessage.isSome:
            unbanId = response.replyToMessage.get.fromUser.get.id
        elif ' ' in response.text.get:
            if response.text.get.split(" ").len > 1:
                unbanId = parseInt(response.text.get.split(" ")[^1])
                try:
                    let usr = await getChatMember(b.bot, $response.chat.id.int, unbanId)
                    if usr.untilDate.isNone:
                        unbanId = 0
                        msgTxt = "He's already in the group"
                except IOError:
                    unbanId = 0
                    msgTxt = "Invalid user id"
    
        if unbanId == bot.id:
            unbanId = 0
            msgTxt = "Why'd i unban myself when i am here :v"

        if unbanId != 0:
            discard await unbanChatMember(b.bot, $response.chat.id, unbanId)
            msgTxt = "Unbanned!"
    else:
        msgTxt = "You aren't adm :^("

    discard await b.bot.sendMessage(response.chat.id, msgTxt, replyToMessageId = response.messageId)

proc kickHandler*(b: TgManager, c: Command) {.async.} =
    let response = c.message
    let bot = await b.bot.getMe()
    var kickId = 0
    var msgTxt = "Reply to a user to kick them!"
    if not (await canBotRestrict(b, response)):
        discard await b.bot.sendMessage(response.chat.id, "I can't kick users!", replyToMessageId = response.messageId)
        return

    if await isUserAdm(b, response.chat.id.int, response.fromUser.get.id):
        if response.replyToMessage.isSome:
            kickId = response.replyToMessage.get.fromUser.get.id
        elif ' ' in response.text.get:
            if response.text.get.split(" ").len > 1:
                kickId = parseInt(response.text.get.split(" ")[^1])
                if not (await isUserInChat(b, response.chat.id.int, kickId)):
                    kickId = 0
                    msgTxt = "Invalid user id"
    
        if kickId == bot.id:
            kickId = 0
            msgTxt = "I am not kicking myself :^)"
        elif await isUserAdm(b, response.chat.id.int, kickId):
            kickId = 0
            msgTxt = "I can't touch this guy :^("

        if kickId != 0:
            discard await kickChatMember(b.bot, $response.chat.id, kickId, toUnix(getTime()).int + 1)
            msgTxt = "Kicked!"
    else:
        msgTxt = "You aren't adm :^("

    discard await b.bot.sendMessage(response.chat.id, msgTxt, replyToMessageId = response.messageId)

proc kickMeHandler*(b: TgManager, c: Command) {.async.} =
        let response = c.message
        if not (await canBotRestrict(b, response)):
            discard await b.bot.sendMessage(response.chat.id, "I can't kick users!", replyToMessageId = response.messageId)
            return

        if await isUserAdm(b, response.chat.id.int, response.replyToMessage.get.fromUser.get().id):
            discard await b.bot.sendMessage(response.chat.id, "I can't touch you :^(", replyToMessageId = response.messageId)
            return

        discard await kickChatMember(b.bot, $response.chat.id, response.replyToMessage.get.fromUser.get().id, toUnix(getTime()).int + 1)
        discard await b.bot.sendMessage(response.chat.id, "Get Out lol", replyToMessageId = response.messageId)

proc muteHandler*(b: TgManager, c: Command) {.async.} =
    let response = c.message
    let bot = await b.bot.getMe()
    var muteId = 0
    var msgTxt = "Reply to a user to mute them!"
    if not (await canBotRestrict(b, response)):
        discard await b.bot.sendMessage(response.chat.id, "I can't mute users!", replyToMessageId = response.messageId)
        return

    if await isUserAdm(b, response.chat.id.int, response.fromUser.get.id):
        if response.replyToMessage.isSome:
            muteId = response.replyToMessage.get.fromUser.get.id
        elif ' ' in response.text.get:
            if response.text.get.split(" ").len > 1:
                muteId = parseInt(response.text.get.split(" ")[^1])
                if not (await isUserInChat(b, response.chat.id.int, muteId)):
                    muteId = 0
                    msgTxt = "Invalid user id"
    
        if muteId == bot.id:
            muteId = 0
            msgTxt = "I am not muting myself :^)"
        elif await isUserAdm(b, response.chat.id.int, muteId):
            muteId = 0
            msgTxt = "I can't touch this guy :^("

        if muteId != 0:
            let user = await getChatMember(b.bot, $response.chat.id.int, response.replyToMessage.get.fromUser.get().id)
            if user.canSendMessages.isNone or user.canSendMessages.get:
                let perms = ChatPermissions(canSendMessages: some(false))
                discard await restrictChatMember(b.bot, $response.chat.id, response.replyToMessage.get.fromUser.get().id, perms)
                msgTxt = "User Muted!"
            else:
                msgTxt = "User is already muted!"
    else:
        msgTxt = "You aren't Adm! :^("

    discard await b.bot.sendMessage(response.chat.id, msgTxt, replyToMessageId = response.messageId)

proc tmuteHandler*(b: TgManager, c: Command) {.async.} =
    let response = c.message
    let bot = await b.bot.getMe()
    var muteId = 0
    var msgTxt = "Reply to a user to tmute them!"
    if not (await canBotRestrict(b, response)):
        discard await b.bot.sendMessage(response.chat.id, "I can't mute users!", replyToMessageId = response.messageId)
        return

    var time = await getTime(b, response)
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
                    msgTxt = "Invalid user id"
    
        if muteId == bot.id:
            muteId = 0
            msgTxt = "I am not muting myself :^)"
        elif await isUserAdm(b, response.chat.id.int, muteId):
            muteId = 0
            msgTxt = "I can't touch this guy :^("

        if muteId != 0:
            let user = await getChatMember(b.bot, $response.chat.id.int, response.replyToMessage.get.fromUser.get().id)
            if user.canSendMessages.isNone or user.canSendMessages.get:
                let perms = ChatPermissions(canSendMessages: some(false))
                discard await restrictChatMember(b.bot, $response.chat.id, response.replyToMessage.get.fromUser.get().id, perms, untilDate = time)
                msgTxt = "User Muted for the next " & response.text.get.split(" ")[^1]
            else:
                msgTxt = "User is already muted!"
    else:
        msgTxt = "You aren't Adm :^("

    discard await b.bot.sendMessage(response.chat.id, msgTxt, replyToMessageId = response.messageId)

proc unmuteHandler*(b: TgManager, c: Command) {.async.} =
    let response = c.message
    var unmuteId = 0
    var msgTxt = "Reply to a user to unmute them!"
    if not (await canBotRestrict(b, response)):
        discard await b.bot.sendMessage(response.chat.id, "I can't unmute users!", replyToMessageId = response.messageId)
        return

    if await isUserAdm(b, response.chat.id.int, response.fromUser.get.id):
        if response.replyToMessage.isSome:
            unmuteId = response.replyToMessage.get.fromUser.get.id
        elif ' ' in response.text.get:
            if response.text.get.split(" ").len > 1:
                unmuteId = parseInt(response.text.get.split(" ")[^1])
                if not (await isUserInChat(b, response.chat.id.int, unmuteId)):
                    unmuteId = 0
                    msgTxt = "Invalid user id"
    
        if await isUserAdm(b, response.chat.id.int, unmuteId):
            unmuteId = 0
            msgTxt = "This guy can't be muted lol! so no need to unmute"

        if unmuteId != 0:
            let user = await getChatMember(b.bot, $response.chat.id.int, unmuteId)
            if not(user.canSendMessages.isNone or user.canSendMessages.get):
                let perms = ChatPermissions(canSendMessages: some(true), 
                canSendMediaMessages: some(true),
                canSendOtherMessages: some(true),
                canAddWebPagePreviews: some(true))
                discard await restrictChatMember(b.bot, $response.chat.id, unmuteId, perms)
                msgTxt = "User Un-Muted!"
            else:
                msgTxt = "User was never muted"
    else:
        msgTxt = "You aren't Adm :^("

    discard await b.bot.sendMessage(response.chat.id, msgTxt, replyToMessageId = response.messageId)
