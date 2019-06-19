# Copyright (C) 2019 Rupansh Sekar
#
# Licensed under the Raphielscape Public License, Version 1.b (the "License");
# you may not use this file except in compliance with the License.
#

import essentials
import telebot, asyncdispatch, logging, options


proc purgeHandler*(b: TeleBot, c: Command) {.async.} =
    let response = c.message
    if not (await canBotDelete(b, response)):
        var msg = newMessage(response.chat.id, "I can't delete messages!")
        msg.replyToMessageId = response.messageId
        discard await b.send(msg)
        return

    if not (await isUserAdm(b, response.chat.id.int, response.fromUser.get.id)):
        var msg = newMessage(response.chat.id, "You aren't Adm :^(")
        msg.replyToMessageId = response.messageId
        discard await b.send(msg)
        return

    if response.replyToMessage.isSome:
        for msgid in countdown(response.messageId, response.replyToMessage.get.messageId):
            try:
                discard await deleteMessage(b, $response.chat.id.int, msgid)
            except IOError:
                continue
        var msg = newMessage(response.chat.id, "Purge Complete!")
        discard await b.send(msg)
    else:
        var msg = newMessage(response.chat.id, "Reply to a message to start purging!")
        discard await b.send(msg)

proc delHandler*(b: TeleBot, c: Command) {.async.} =
    let response = c.message
    if not (await canBotDelete(b, response)):
        var msg = newMessage(response.chat.id, "I can't delete messages!")
        msg.replyToMessageId = response.messageId
        discard await b.send(msg)
        return

    if not (await isUserAdm(b, response.chat.id.int, response.fromUser.get.id)):
        var msg = newMessage(response.chat.id, "You aren't Adm :^(")
        msg.replyToMessageId = response.messageId
        discard await b.send(msg)
        return

    if response.replyToMessage.isSome:
        discard await deleteMessage(b, $response.chat.id.int, response.replyToMessage.get.messageId)
        discard await deleteMessage(b, $response.chat.id.int, response.messageId)
    else:
        return
