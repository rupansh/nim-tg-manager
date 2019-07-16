# Copyright (C) 2019 Rupansh Sekar
#
# Licensed under the Raphielscape Public License, Version 1.b (the "License");
# you may not use this file except in compliance with the License.
#

import essentials
import redishandling
import strutils

import telebot, asyncdispatch, logging, options


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
    if text in disabled and not (text in disabled):
        await appRedisList("disabled" & $response.chat.id.int, text)

        var msg = newMessage(response.chat.id, text & " Disabled")
        msg.replyToMessageId = response.messageId
        discard await b.send(msg)

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

        var msg = newMessage(response.chat.id, text & " Enabled")
        msg.replyToMessageId = response.messageId
        discard await b.send(msg)

proc getDisabledHandler*(b: TeleBot, c: Command) {.async.} =
    let response = c.message

    if await isUserAdm(b, response.chat.id.int, response.fromUser.get.id):
        let disabled = waitFor getRedisList("disabled" & $response.chat.id.int)
        var msg = newMessage(response.chat.id.int, "***disabled cmds:***\n" & disabled.join("\n"))
        msg.replyToMessageId = response.messageId
        msg.parseMode = "markdown"
        discard await b.send(msg)