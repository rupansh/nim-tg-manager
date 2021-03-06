# Copyright (C) 2019 Rupansh Sekar
#
# Licensed under the Raphielscape Public License, Version 1.b (the "License");
# you may not use this file except in compliance with the License.
#

import essentials
import redishandling
from strutils import split, join

import telebot, asyncdispatch, options


proc blacklistListener*(b: TgManager, u: Update) {.async.} =
    let r = u.message
    if r.isNone:
        return
    let response = r.get
    if response.text.isNone or not (await canBotDelete(b, response)):
        return

    if not (await isUserAdm(b, response.chat.id.int, response.fromUser.get.id)):
        let blacklist = await b.db.getRedisList("blacklist" & $response.chat.id.int)
        if response.text.get in blacklist:
            discard await deleteMessage(b.bot, $response.chat.id.int, response.messageId)

proc addBlacklistHandler*(b: TgManager, c: Command) {.async.} =
    let response = c.message

    if await isUserAdm(b, response.chat.id.int, response.fromUser.get.id):
        var text: string
        if ' ' in c.message.text.get:
            text = c.message.text.get.split(" ")[^1]
        if text == "":
            return

        let blacklist = await b.db.getRedisList("blacklist" & $response.chat.id.int)

        if not (text in blacklist):
            await b.db.appRedisList("blacklist" & $response.chat.id.int, text)

        discard await b.bot.sendMessage(response.chat.id, text & " Blacklisted!", replyToMessageId = response.messageId)

proc rmBlacklistHandler*(b: TgManager, c: Command) {.async.} =
    let response = c.message

    if await isUserAdm(b, response.chat.id.int, response.fromUser.get.id):
        var text: string
        if ' ' in c.message.text.get:
            text = c.message.text.get.split(" ")[^1]
        if text == "":
            return

        let blacklist = await b.db.getRedisList("blacklist" & $response.chat.id.int)
        if text in blacklist:
            await b.db.rmRedisList("blacklist" & $response.chat.id.int, text)
            discard await b.bot.sendMessage(response.chat.id, text & " Removed!", replyToMessageId = response.messageId)

proc getBlacklistHandler*(b: TgManager, c: Command) {.async.} =
    let response = c.message

    if await isUserAdm(b, response.chat.id.int, response.fromUser.get.id):
        let blacklist = await b.db.getRedisList("blacklist" & $response.chat.id.int)
        discard await b.bot.sendMessage(response.chat.id,  "***Blacklisted Words:***\n" & blacklist.join("\n"), parseMode = "markdown", replyToMessageId = response.messageId)
