# Copyright (C) 2019 Rupansh Sekar
#
# Licensed under the Raphielscape Public License, Version 1.b (the "License");
# you may not use this file except in compliance with the License.
#

import essentials
import redishandling
from strutils import split, join

import telebot, asyncdispatch, logging, options


proc blacklistListener*(b: TeleBot, u: Update) {.async.} =
    let response = u.message.get
    if response.text.isNone:
        return
    if not (await canBotDelete(b, response)):
        return

    if not (await isUserAdm(b, response.chat.id.int, response.fromUser.get.id)):
        let blacklist = await getRedisList("blacklist" & $response.chat.id.int)
        if response.text.get in blacklist:
            discard await deleteMessage(b, $response.chat.id.int, response.messageId)

proc addBlacklistHandler*(b: TeleBot, c: Command) {.async.} =
    let response = c.message

    if await isUserAdm(b, response.chat.id.int, response.fromUser.get.id):
        var text: string
        if ' ' in c.message.text.get:
            text = c.message.text.get.split(" ")[^1]
        if text == "":
            return
        
        let blacklist = await getRedisList("blacklist" & $response.chat.id.int)

        if not (text in blacklist):
            await appRedisList("blacklist" & $response.chat.id.int, text)

        var msg = newMessage(response.chat.id, text & " Blacklisted!")
        msg.replyToMessageId = response.messageId
        discard await b.send(msg)

proc rmBlacklistHandler*(b: TeleBot, c: Command) {.async.} =
    let response = c.message

    if await isUserAdm(b, response.chat.id.int, response.fromUser.get.id):
        var text: string
        if ' ' in c.message.text.get:
            text = c.message.text.get.split(" ")[^1]
        if text == "":
            return
        
        let blacklist = await getRedisList("blacklist" & $response.chat.id.int)
        if text in blacklist:
            await rmRedisList("blacklist" & $response.chat.id.int, text)
            var msg = newMessage(response.chat.id, text & " Removed!")
            msg.replyToMessageId = response.messageId
            discard await b.send(msg)

proc getBlacklistHandler*(b: TeleBot, c: Command) {.async.} =
    let response = c.message

    if await isUserAdm(b, response.chat.id.int, response.fromUser.get.id):
        let blacklist = await getRedisList("blacklist" & $response.chat.id.int)
        var msg = newMessage(response.chat.id.int, "***Blacklisted Words:***\n" & blacklist.join("\n"))
        msg.replyToMessageId = response.messageId
        msg.parseMode = "markdown"
        discard await b.send(msg)
