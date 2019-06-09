# Copyright (C) 2019 Rupansh Sekar
#
# Licensed under the Raphielscape Public License, Version 1.b (the "License");
# you may not use this file except in compliance with the License.
#

import config
import essentials
from strutils import split
import times

import telebot, asyncdispatch, logging, options


proc banHandler*(b: TeleBot, c: Command) {.async.} =
    let response = c.message
    let bot = await b.getMe()
    if not (await canBotRestrict(b, response)):
        var msg = newMessage(response.chat.id, "I can't ban users!")
        msg.replyToMessageId = response.messageId
        discard await b.send(msg)
        return
    
    if response.replyToMessage.isSome:
        if response.replyToMessage.get.fromUser.get().id == bot.id:
            var msg = newMessage(response.chat.id, "I am not banning myself :^)")
            msg.replyToMessageId = response.messageId
            discard await b.send(msg)
            return
        
        if await isUserAdm(b, response.chat.id.int, response.replyToMessage.get.fromUser.get().id):
            var msg = newMessage(response.chat.id, "I can't touch this guy :^(")
            msg.replyToMessageId = response.messageId
            discard await b.send(msg)
            return

        let chatUser = await getChatMember(b, $response.chat.id.int, response.fromUser.get().id)
        if chatUser.status in ["creator", "administrator"]:
            discard await kickChatMember(b, $response.chat.id, response.replyToMessage.get.fromUser.get().id, (toUnix(getTime()) - 31).int)
            var msg = newMessage(response.chat.id, "They won't be bugging you in this chat anymore!")
            msg.replyToMessageId = response.messageId
            discard await b.send(msg)
        else:
            var msg = newMessage(response.chat.id, "You aren't adm :^(")
            msg.replyToMessageId = response.messageId
            discard await b.send(msg)
    else:
        var msg = newMessage(response.chat.id, "Reply to a user to ban them!")
        msg.replyToMessageId = response.messageId
        discard await b.send(msg)

proc tbanHandler*(b: TeleBot, c: Command) {.async.} =
    let response = c.message
    let bot = await b.getMe()
    if not (await canBotRestrict(b, response)):
        var msg = newMessage(response.chat.id, "I can't ban users!")
        msg.replyToMessageId = response.messageId
        discard await b.send(msg)
        return
    
    var time = getTime(b, response)
    if time == 0:
        return

    if response.replyToMessage.isSome:
        if response.replyToMessage.get.fromUser.get().id == bot.id:
            var msg = newMessage(response.chat.id, "I am not banning myself :^)")
            msg.replyToMessageId = response.messageId
            discard await b.send(msg)
            return
        
        if await isUserAdm(b, response.chat.id.int, response.replyToMessage.get.fromUser.get().id):
            var msg = newMessage(response.chat.id, "I can't touch this guy :^(")
            msg.replyToMessageId = response.messageId
            discard await b.send(msg)
            return

        let chatUser = await getChatMember(b, $response.chat.id.int, response.fromUser.get().id)
        if chatUser.status in ["creator", "administrator"]:
            discard await kickChatMember(b, $response.chat.id, response.replyToMessage.get.fromUser.get().id, time)
            var msg = newMessage(response.chat.id, "They won't be bugging you in this chat for the next " & response.text.get.split(" ")[^1])
            msg.replyToMessageId = response.messageId
            discard await b.send(msg)
        else:
            var msg = newMessage(response.chat.id, "You aren't adm :^(")
            msg.replyToMessageId = response.messageId
            discard await b.send(msg)
    else:
        var msg = newMessage(response.chat.id, "Reply to a user to tban them!")
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
    if not (await canBotRestrict(b, response)):
        var msg = newMessage(response.chat.id, "I can't unban users!")
        msg.replyToMessageId = response.messageId
        discard await b.send(msg)
        return
    
    if response.replyToMessage.isSome:
        if response.replyToMessage.get.fromUser.get().id == bot.id:
            var msg = newMessage(response.chat.id, "Why'd i unban myself when i am here :v")
            msg.replyToMessageId = response.messageId
            discard await b.send(msg)
            return
        
        if await isUserInChat(b, response.chat.id.int, response.replyToMessage.get.fromUser.get().id):
            var msg = newMessage(response.chat.id, "He's already in the group lol")
            msg.replyToMessageId = response.messageId
            discard await b.send(msg)
            return

        let chatUser = await getChatMember(b, $response.chat.id.int, response.fromUser.get().id)
        if chatUser.status in ["creator", "administrator"]:
            discard await unbanChatMember(b, $response.chat.id, response.replyToMessage.get.fromUser.get().id)
            var msg = newMessage(response.chat.id, "Unbanned!")
            msg.replyToMessageId = response.messageId
            discard await b.send(msg)
        else:
            var msg = newMessage(response.chat.id, "You aren't adm :^(")
            msg.replyToMessageId = response.messageId
            discard await b.send(msg)
    else:
        var msg = newMessage(response.chat.id, "Reply to a user to unban them!")
        msg.replyToMessageId = response.messageId
        discard await b.send(msg)

proc kickHandler*(b: TeleBot, c: Command) {.async.} =
    let response = c.message
    let bot = await b.getMe()
    if not (await canBotRestrict(b, response)):
        var msg = newMessage(response.chat.id, "I can't kick users!")
        msg.replyToMessageId = response.messageId
        discard await b.send(msg)
        return
    
    if response.replyToMessage.isSome:
        if response.replyToMessage.get.fromUser.get().id == bot.id:
            var msg = newMessage(response.chat.id, "I am not kicking myself :^)")
            msg.replyToMessageId = response.messageId
            discard await b.send(msg)
            return
        
        if await isUserAdm(b, response.chat.id.int, response.replyToMessage.get.fromUser.get().id):
            var msg = newMessage(response.chat.id, "I can't touch this guy :^(")
            msg.replyToMessageId = response.messageId
            discard await b.send(msg)
            return

        let chatUser = await getChatMember(b, $response.chat.id.int, response.fromUser.get().id)
        if chatUser.status in ["creator", "administrator"]:
            discard await kickChatMember(b, $response.chat.id, response.replyToMessage.get.fromUser.get().id, toUnix(getTime()).int + 1)
            var msg = newMessage(response.chat.id, "Kicked!")
            msg.replyToMessageId = response.messageId
            discard await b.send(msg)
        else:
            var msg = newMessage(response.chat.id, "You aren't adm :^(")
            msg.replyToMessageId = response.messageId
            discard await b.send(msg)
    else:
        var msg = newMessage(response.chat.id, "Reply to a user to kick them!")
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