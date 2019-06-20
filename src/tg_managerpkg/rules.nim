# Copyright (C) 2019 Rupansh Sekar
#
# Licensed under the Raphielscape Public License, Version 1.b (the "License");
# you may not use this file except in compliance with the License.
#

import essentials
from redis import redisNil
import redishandling
from strutils import split

import telebot, asyncdispatch, logging, options


proc setRulesHandler*(b: TeleBot, c: Command) {.async.} =
    let response = c.message
    var rules = ""

    if await isUserAdm(b, response.chat.id.int, response.fromUser.get.id):
        if response.replyToMessage.isSome and response.replyToMessage.get.text.isSome:
            rules = response.replyToMessage.get.text.get
        elif ' ' in response.text.get:
            if response.text.get.split(" ").len > 1:
                rules = response.text.get.split(" ", 1)[1]

        if rules == "":
            var msg = newMessage(response.chat.id, "Reply to a text message to set it as the rule!")
            msg.replyToMessageId = response.messageId
            discard await b.send(msg)
        else:
            let rules = response.replyToMessage.get.text.get
            await setRedisKey("rules" & $response.chat.id, rules)

            var msg = newMessage(response.chat.id.int, "Rules set!")
            msg.replyToMessageId = response.messageId
            discard await b.send(msg)

proc getRulesHandler*(b: TeleBot, c: Command) {.async.} =
    let response = c.message

    let rules = waitFor getRedisKey("rules" & $response.chat.id)
    if rules == redisNil:
        return

    var msg = newMessage(response.chat.id.int, "***Rules for this chat are:\n***" & rules)
    msg.replyToMessageId = response.messageId
    msg.parseMode = "markdown"
    discard await b.send(msg)