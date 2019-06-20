# Copyright (C) 2019 Rupansh Sekar
#
# Licensed under the Raphielscape Public License, Version 1.b (the "License");
# you may not use this file except in compliance with the License.
#

import config
import essentials
from strutils import split, parseInt

import telebot, asyncdispatch, logging, options


proc promoteHandler*(b: TeleBot, c: Command) {.async.} =
    var response = c.message
    let bot = await b.getMe()
    let botChat = await getChatMember(b, $response.chat.id.int, bot.id)
    var promId = 0
    var failStr = "Reply to a person to promote them!"
    if not (await canBotPromote(b, response)):
        var msg = newMessage(response.chat.id, "I can't promote members!")
        msg.replyToMessageId = response.messageId
        discard await b.send(msg)
        return

    if await isUserAdm(b, response.chat.id.int, response.fromUser.get.id):
        if response.replyToMessage.isSome:
            promId = response.replyToMessage.get.fromUser.get.id
        elif ' ' in response.text.get:
            if response.text.get.split(" ").len > 1:
                promId = parseInt(response.text.get.split(" ")[^1])
                if not (await isUserInChat(b, response.chat.id.int, promId)):
                    promId = 0
                    failStr = "Invalid user id"

        if promId == 0:
            var msg = newMessage(response.chat.id, failStr)
            msg.replyToMessageId = response.messageId
            discard await b.send(msg)
        else:
            discard await promoteChatMember(b, $response.chat.id.int, promId,
            canChangeInfo = botChat.canChangeInfo.get,
            canInviteUsers = botChat.canInviteUsers.get,
            canDeleteMessages = botChat.canDeleteMessages.get,
            canRestrictMembers = botChat.canRestrictMembers.get,
            canPinMessages = botChat.canPinMessages.get)
            var msg = newMessage(response.chat.id, "Promoted!")
            msg.replyToMessageId = response.messageId
            discard await b.send(msg)
    else:
        var msg = newMessage(response.chat.id, "You aren't adm :^(")
        msg.replyToMessageId = response.messageId
        discard await b.send(msg)

proc demoteHandler*(b: TeleBot, c: Command) {.async.} =
    var response = c.message
    var demId = 0
    var failStr = "Reply to a user to demote them"
    if not (await canBotPromote(b, response)):
        var msg = newMessage(response.chat.id, "I can't demote members!")
        msg.replyToMessageId = response.messageId
        discard await b.send(msg)
        return

    if await isUserAdm(b, response.chat.id.int, response.fromUser.get.id):
        if response.replyToMessage.isSome:
            demId = response.replyToMessage.get.fromUser.get.id
        elif ' ' in response.text.get:
            if response.text.get.split(" ").len > 1:
                demId = parseInt(response.text.get.split(" ")[^1])
                if not (await isUserInChat(b, response.chat.id.int, demId)):
                    demId = 0
                    failStr = "Invalid user id"

        if demId == 0:
            var msg = newMessage(response.chat.id, failStr)
            msg.replyToMessageId = response.messageId
            discard await b.send(msg)
        else:
            try:
                discard await promoteChatMember(b, $response.chat.id.int, demId,
                    canChangeInfo = false,
                    canInviteUsers = false,
                    canDeleteMessages = false,
                    canRestrictMembers = false,
                    canPinMessages = false)
                var msg = newMessage(response.chat.id, "Demoted!")
                msg.replyToMessageId = response.messageId
                discard await b.send(msg)
            except IOError:
                var msg = newMessage(response.chat.id, "Failed to demote!")
                msg.replyToMessageId = response.messageId
                discard await b.send(msg)
    else:
        var msg = newMessage(response.chat.id, "You aren't adm :^(")
        msg.replyToMessageId = response.messageId
        discard await b.send(msg)

proc pinHandler*(b: TeleBot, c: Command) {.async.} =
    var response = c.message
    if not (await canBotPin(b, response)):
        var msg = newMessage(response.chat.id, "I can't Pin Messages!")
        msg.replyToMessageId = response.messageId
        discard await b.send(msg)
        return

    if response.replyToMessage.isSome:
        if await isUserAdm(b, response.chat.id.int, response.fromUser.get.id):
            discard await pinChatMessage(b, $response.chat.id.int, response.replyToMessage.get.messageId)
        else:
            var msg = newMessage(response.chat.id, "You aren't adm :^(")
            msg.replyToMessageId = response.messageId
            discard await b.send(msg)
    else:
        var msg = newMessage(response.chat.id, "Reply to a message to pin it!")
        msg.replyToMessageId = response.messageId
        discard await b.send(msg)

proc unpinHandler*(b: TeleBot, c: Command) {.async.} =
    var response = c.message
    if not (await canBotPin(b, response)):
        var msg = newMessage(response.chat.id, "I can't unpin Messages!")
        msg.replyToMessageId = response.messageId
        discard await b.send(msg)
        return

    if response.text.isSome:
        if await isUserAdm(b, response.chat.id.int, response.fromUser.get.id):
            discard await unpinChatMessage(b, $response.chat.id.int)
        else:
            var msg = newMessage(response.chat.id, "You aren't adm :^(")
            msg.replyToMessageId = response.messageId
            discard await b.send(msg)

proc inviteHandler*(b: TeleBot, c: Command) {.async.} =
    var response = c.message

    if response.text.isSome:
        let chat = await getChat(b, $response.chat.id.int)
        if chat.username.isSome:
            var msg = newMessage(response.chat.id, "@" & chat.username.get)
            msg.replyToMessageId = response.messageId
            discard await b.send(msg)
        elif await canBotInvite(b, response):
            var inviteLink : string

            if chat.invitelink.isSome:
                inviteLink = chat.inviteLink.get
            else:
                inviteLink = await exportChatInviteLink(b, $response.chat.id.int)

            var msg = newMessage(response.chat.id, inviteLink)
            msg.replyToMessageId = response.messageId
            discard await b.send(msg)
        else:
            var msg = newMessage(response.chat.id, "I do not have permissions to make invite links!")
            msg.replyToMessageId = response.messageId
            discard await b.send(msg)

proc adminList*(b: TeleBot, c: Command) {.async.} =
    let response = c.message

    let admins = await getChatAdministrators(b, $response.chat.id.int)
    var text = "Admins in this chat:\n"
    for admin in admins:
        if admin.user.username.isSome:
            text = text & admin.user.username.get
        else:
            text = text & admin.user.firstName

        if admin.status == "creator":
            text = text & " (Creator)\n"
        else:
            text = text & "\n"

    var msg = newMessage(response.chat.id, text)
    msg.replyToMessageId = response.messageId
    discard await b.send(msg)
