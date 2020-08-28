# Copyright (C) 2019 Rupansh Sekar
#
# Licensed under the Raphielscape Public License, Version 1.b (the "License");
# you may not use this file except in compliance with the License.
#

import essentials
import telebot, asyncdispatch, options


proc purgeHandler*(b: TeleBot, c: Command) {.async.} =
    let response = c.message
    var msgTxt: string
    if not (await canBotDelete(b, response)):
        discard await b.sendMessage(response.chat.id, "I can't delete messages!", replyToMessageId = response.messageId)
        return

    if not (await isUserAdm(b, response.chat.id.int, response.fromUser.get.id)):
        discard await b.sendMessage(response.chat.id, "You aren't Adm :^(", replyToMessageId = response.messageId)
        return

    if response.replyToMessage.isSome:
        for msgid in countdown(response.messageId, response.replyToMessage.get.messageId):
            try:
                discard await deleteMessage(b, $response.chat.id.int, msgid)
            except IOError:
                continue
        msgTxt = "Purge Complete!"
    else:
        msgTxt = "Reply to a message to start purging!"

    discard await b.sendMessage(response.chat.id, msgTxt, replyToMessageid = response.messageId)

proc delHandler*(b: TeleBot, c: Command) {.async.} =
    let response = c.message
    var msgTxt: string
    if await canBotDelete(b, response):
        if await isUserAdm(b, response.chat.id.int, response.fromUser.get.id):
            if response.replyToMessage.isSome:
                discard await deleteMessage(b, $response.chat.id.int, response.replyToMessage.get.messageId)
                discard await deleteMessage(b, $response.chat.id.int, response.messageId)
                return
        else:
            msgTxt = "You aren't Adm :^("
    else:
        msgTxt = "I can't delete messages!"

    discard await b.sendMessage(response.chat.id, msgTxt, replyToMessageId = response.messageId)