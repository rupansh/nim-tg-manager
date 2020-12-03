# Copyright (C) 2019 Rupansh Sekar
#
# Licensed under the Raphielscape Public License, Version 1.b (the "License");
# you may not use this file except in compliance with the License.
#

import essentials
import redishandling
import strutils

import telebot, asyncdispatch, options


proc disableHandler*(b: TgManager, c: Command) {.async.} =
    let response = c.message
    if not(await isUserAdm(b, response.chat.id.int, response.fromUser.get.id)):
        return

    var text: string
    if ' ' in c.message.text.get:
        text = c.message.text.get.split(" ")[^1]
    if text == "":
        return

    let disabled = await b.db.getRedisList("disabled" & $response.chat.id.int)
    var msgTxt: string
    if not (text in disabled):
        await b.db.appRedisList("disabled" & $response.chat.id.int, text)
        msgTxt = text & " Disabled if possible!"
    else:
        msgTxt = text & "Can't disable this command!"

    discard await b.bot.sendMessage(response.chat.id, msgTxt, replyToMessageId = response.messageId)

proc enableHandler*(b: TgManager, c: Command) {.async.} =
    let response = c.message
    if not(await isUserAdm(b, response.chat.id.int, response.fromUser.get.id)):
        return

    var text: string
    if ' ' in c.message.text.get:
        text = c.message.text.get.split(" ")[^1]
    if text == "":
        return

    let disabled = await b.db.getRedisList("disabled" & $response.chat.id.int)
    if text in disabled:
        await b.db.rmRedisList("disabled" & $response.chat.id.int, text)

        discard await b.bot.sendMessage(response.chat.id, text & " Enabled", replyToMessageId = response.messageId)

proc getDisabledHandler*(b: TgManager, c: Command) {.async.} =
    let response = c.message

    if await isUserAdm(b, response.chat.id.int, response.fromUser.get.id):
        let disabled = await b.db.getRedisList("disabled" & $response.chat.id.int)
        discard await b.bot.sendMessage(response.chat.id, "***disabled cmds:***\n" & disabled.join("\n"), parseMode = "markdown", replyToMessageId = response.messageId)