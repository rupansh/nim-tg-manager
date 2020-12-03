# Copyright (C) 2019 Rupansh Sekar
#
# Licensed under the Raphielscape Public License, Version 1.b (the "License");
# you may not use this file except in compliance with the License.
#

import essentials
from strutils import split, parseInt

import telebot, asyncdispatch, options


proc promoteHandler*(b: TgManager, c: Command) {.async.} =
    var response = c.message
    let bot = await b.bot.getMe()
    let botChat = await getChatMember(b.bot, $response.chat.id.int, bot.id)
    var promId = 0
    var msgTxt = "Reply to a person to promote them!"
    if await canBotPromote(b, response):
        if await isUserAdm(b, response.chat.id.int, response.fromUser.get.id):
            if response.replyToMessage.isSome:
                promId = response.replyToMessage.get.fromUser.get.id
            elif ' ' in response.text.get:
                if response.text.get.split(" ").len > 1:
                    promId = parseInt(response.text.get.split(" ")[^1])
                    if not (await isUserInChat(b, response.chat.id.int, promId)):
                        promId = 0
                        msgTxt = "Invalid user id"

            if promId != 0:
                discard await promoteChatMember(b.bot, $response.chat.id.int, promId,
                canChangeInfo = botChat.canChangeInfo.get,
                canInviteUsers = botChat.canInviteUsers.get,
                canDeleteMessages = botChat.canDeleteMessages.get,
                canRestrictMembers = botChat.canRestrictMembers.get,
                canPinMessages = botChat.canPinMessages.get)
                msgTxt = "Promoted!"
        else:
            msgTxt = "You aren't adm :^("
    else:
        msgTxt = "I can't promote members!"

    discard b.bot.sendMessage(response.chat.id, msgTxt, replyToMessageid = response.messageId)

proc demoteHandler*(b: TgManager, c: Command) {.async.} =
    var response = c.message
    var demId = 0
    var msgTxt = "Reply to a user to demote them"
    if await canBotPromote(b, response):
        if await isUserAdm(b, response.chat.id.int, response.fromUser.get.id):
            if response.replyToMessage.isSome:
                demId = response.replyToMessage.get.fromUser.get.id
            elif ' ' in response.text.get:
                if response.text.get.split(" ").len > 1:
                    demId = parseInt(response.text.get.split(" ")[^1])
                    if not (await isUserInChat(b, response.chat.id.int, demId)):
                        demId = 0
                        msgTxt = "Invalid user id"

            if demId != 0:
                try:
                    discard await promoteChatMember(b.bot, $response.chat.id.int, demId,
                        canChangeInfo = false,
                        canInviteUsers = false,
                        canDeleteMessages = false,
                        canRestrictMembers = false,
                        canPinMessages = false)
                    msgTxt = "Demoted!"
                except IOError:
                    msgTxt = "Failed to demote!"
        else:
            msgTxt = "You aren't adm :^("
    else:
        msgTxt = "I can't demote members!"

    discard await b.bot.sendMessage(response.chat.id, msgTxt, replyToMessageId = response.messageId)

proc pinHandler*(b: TgManager, c: Command) {.async.} =
    var response = c.message
    var msgTxt: string
    if await canBotPin(b, response):
        if response.replyToMessage.isSome:
            if await isUserAdm(b, response.chat.id.int, response.fromUser.get.id):
                discard await pinChatMessage(b.bot, $response.chat.id.int, response.replyToMessage.get.messageId)
                return
            else:
                msgTxt = "You aren't adm :^("
        else:
            msgTxt = "Reply to a message to pin it!"
    else:
        msgTxt = "I can't Pin Messages!"

    discard await b.bot.sendMessage(response.chat.id, msgTxt, replyToMessageId = response.messageId)

proc unpinHandler*(b: TgManager, c: Command) {.async.} =
    var response = c.message
    var msgTxt: string
    if await canBotPin(b, response):
        if response.text.isSome:
            if await isUserAdm(b, response.chat.id.int, response.fromUser.get.id):
                discard await unpinChatMessage(b.bot, $response.chat.id.int)
                return
            else:
                msgTxt = "You aren't adm :^("
    else:
        msgTxt = "I can't unpin Messages!"

    discard await b.bot.sendMessage(response.chat.id, msgTxt, replyToMessageId = response.messageId)

proc inviteHandler*(b: TgManager, c: Command) {.async.} =
    var response = c.message
    var msgTxt: string

    if response.text.isSome:
        let chat = await getChat(b.bot, $response.chat.id.int)
        if chat.username.isSome:
            msgTxt = "@" & chat.username.get
        elif await canBotInvite(b, response):
            if chat.invitelink.isSome:
                msgTxt = chat.inviteLink.get
            else:
                msgTxt = await exportChatInviteLink(b.bot, $response.chat.id.int)
        else:
            msgTxt = "I do not have permissions to make invite links!"

        discard await b.bot.sendMessage(response.chat.id, msgTxt, replyToMessageId = response.messageId)

proc adminList*(b: TgManager, c: Command) {.async.} =
    let response = c.message

    let admins = await getChatAdministrators(b.bot, $response.chat.id.int)
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

    discard await b.bot.sendMessage(response.chat.id, text, replyToMessageId = response.messageId)

proc safeHandler*(b: TgManager, c: Command) {.async.} =
    let response = c.message
    var msgTxt: string

    if await isUserAdm(b, response.chat.id.int, response.fromUser.get.id):
        if await canBotInfo(b, response):
            var perm: ChatPermissions
            var mode: string
            if ' ' in response.text.get:
                if response.text.get.split(" ").len > 1:
                    mode = response.text.get.split(" ")[^1]
                    if mode == "on":
                        perm = ChatPermissions(canSendMediaMessages: some(false))
                    elif mode == "off":
                        perm = ChatPermissions(canSendMediaMessages: some(true))
                    else:
                        msgTxt = "Invalid usage! please use on or off"
            else: 
                discard await setChatPermissions(b.bot, $response.chat.id, perm)
                msgTxt = "Safe mode " & mode
        else:
            msgTxt = "I can't change chat permissions!"

        discard await b.bot.sendMessage(response.chat.id, msgTxt, replyToMessageId = response.messageId)
