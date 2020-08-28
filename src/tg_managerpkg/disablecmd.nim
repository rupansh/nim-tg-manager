# Copyright (C) 2019 Rupansh Sekar
#
# Licensed under the Raphielscape Public License, Version 1.b (the "License");
# you may not use this file except in compliance with the License.
#

import config
import essentials
import redishandling
import strutils

import telebot, asyncdispatch, options


proc disableHandler*(b: TeleBot, c: Command) {.async.} =
    let response = c.message
    if not(await isUserAdm(b, response.chat.id.int, response.fromUser.get.id)):
        return

    var text: string
    if ' ' in c.message.text.get:
        text = c.message.text.get.split(" ")[^1]
    if text == "":
        return

    let disabled = waitFor getRedisList("disabled" & $response.chat.id.int)
    if text in cmdList and not (text in disabled):
        await appRedisList("disabled" & $response.chat.id.int, text)

        discard await b.sendMessage(response.chat.id, text & " Disabled", replyToMessageId = response.messageId)
    else:
        discard await b.sendMessage(response.chat.id, text & "Can't disable this command!", replyToMessageId = response.messageId)

proc enableHandler*(b: TeleBot, c: Command) {.async.} =
    let response = c.message
    if not(await isUserAdm(b, response.chat.id.int, response.fromUser.get.id)):
        return

    var text: string
    if ' ' in c.message.text.get:
        text = c.message.text.get.split(" ")[^1]
    if text == "":
        return

    let disabled = waitFor getRedisList("disabled" & $response.chat.id.int)
    if text in disabled:
        await rmRedisList("disabled" & $response.chat.id.int, text)

        discard await b.sendMessage(response.chat.id, text & " Enabled", replyToMessageId = response.messageId)

proc getDisabledHandler*(b: TeleBot, c: Command) {.async.} =
    let response = c.message

    if await isUserAdm(b, response.chat.id.int, response.fromUser.get.id):
        let disabled = waitFor getRedisList("disabled" & $response.chat.id.int)
        discard await b.sendMessage(response.chat.id, "***disabled cmds:***\n" & disabled.join("\n"), parseMode = "markdown", replyToMessageId = response.messageId)