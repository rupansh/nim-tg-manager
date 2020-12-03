# Copyright (C) 2019 Rupansh Sekar
#
# Licensed under the Raphielscape Public License, Version 1.b (the "License");
# you may not use this file except in compliance with the License.
#

import config
import essentials
from redis import redisNil
import redishandling
import strutils

import telebot, asyncdispatch, options


proc newUsrListener*(b: TgManager, u: Update) {.async.} =
    let r = u.message
    if r.isNone:
        return
    let response = r.get
    if response.newChatMembers.isSome:
        let welcomeMsg = await b.db.getRedisKey("welcome" & $response.chat.id.int)
        if welcomeMsg == redisNil:
            return
        else:
            discard await b.bot.sendMessage(response.chat.id, welcomeMsg, parseMode = "markdown", replyToMessageId = response.messageId)


proc startHandler*(b: TgManager, c: Command) {.async.} =
    let response = c.message
    var msgTxt: string

    if (response.fromUser.get.id in b.config.sudos) or ($response.fromUser.get.id == b.config.owner):
        msgTxt = "***Hoi Master!*** 😁"
    else:
        msgTxt = "***I AM UP!***"
    
    discard await b.bot.sendMessage(response.chat.id, msgTxt, parseMode = "markdown", replyToMessageId = response.messageId)

proc helpHandler*(b: TgManager, c: Command) {.async.} =
    let response = c.message

    discard await b.bot.sendMessage(
                  response.chat.id,
                  """[Command List](https://rupansh.github.io/nimtg-man.github.io/paperplane/cmds.html)
[Source Code](https://github.com/rupansh/nim-tg-manager)""",
                  parseMode = "markdown",
                  replyToMessageId = response.messageId
    )

proc setwelcomeHandler*(b: TgManager, c: Command) {.async.} =
    let response = c.message
    var welComeMsg = ""

    if not (await isUserAdm(b, response.chat.id.int, response.fromUser.get.id)):
        return

    if not response.replyToMessage.isSome:
        if not (' ' in response.text.get):
            return
        if response.text.get.split(" ").len < 2:
            return
        else:
            welComeMsg = response.text.get.split(" ", 1)[^1]
    else:
        if response.replyToMessage.get.text.isSome:
            welComeMsg = response.replyToMessage.get.text.get
        else:
            return

    await b.db.setRedisKey("welcome" & $response.chat.id.int, welComeMsg)
    discard await b.bot.sendMessage(response.chat.id, "Welcome message set!", replyToMessageId = response.messageId)

proc clearWelcomeHandler*(b: TgManager, c: Command) {.async.} =
    let response = c.message

    if not (await isUserAdm(b, response.chat.id.int, response.fromUser.get.id)):
        return

    let welcomeMsg = await b.db.getRedisKey("welcome" & $response.chat.id.int)
    if welcomeMsg == redisNil:
        return
    else:
        await b.db.clearRedisKey("welcome" & $response.chat.id.int)
        discard await b.bot.sendMessage(response.chat.id, "Cleared welcome message!", replyToMessageId = response.messageId)
