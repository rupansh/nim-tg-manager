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

import telebot, asyncdispatch, logging, options


proc newUsrListener*(b: TeleBot, u: Update) {.async.} =
    let r = u.message
    if r.isNone:
        return
    let response = r.get
    if response.newChatMember.isSome:
        let welcomeMsg = await getRedisKey("welcome" & $response.chat.id.int)
        if welcomeMsg == redisNil:
            return
        else:
            var msg = newMessage(response.chat.id, welcomeMsg)
            msg.parseMode = "markdown"
            msg.replyToMessageId = response.messageId
            discard await b.send(msg)


proc startHandler*(b: TeleBot, c: Command) {.async.} =
    let response = c.message
    var msg: MessageObject

    if (response.fromUser.get.id in sudos) or ($response.fromUser.get.id == owner):
        msg = newMessage(response.chat.id, "***Hoi Master!*** 😁")
    else:
        msg = newMessage(response.chat.id, "***I AM UP!***")
    
    msg.replyToMessageId = response.messageId
    msg.parseMode = "markdown"
    discard await b.send(msg)

proc helpHandler*(b: TeleBot, c: Command) {.async.} =
    let response = c.message

    var msg = newMessage(response.chat.id, """[Command List](https://rupansh.github.io/nimtg-man.github.io/paperplane/cmds.html)
[Source Code](https://github.com/rupansh/nim-tg-manager)""")
    msg.replyToMessageId = response.messageId
    msg.parseMode = "markdown"
    discard await b.send(msg)

proc setwelcomeHandler*(b: TeleBot, c: Command) {.async.} =
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

    await setRedisKey("welcome" & $response.chat.id.int, welComeMsg)
    var msg = newMessage(response.chat.id, "Welcome message set!")
    msg.replyToMessageId = response.messageId
    discard await b.send(msg)

proc clearWelcomeHandler*(b: TeleBot, c: Command) {.async.} =
    let response = c.message

    if not (await isUserAdm(b, response.chat.id.int, response.fromUser.get.id)):
        return

    let welcomeMsg = await getRedisKey("welcome" & $response.chat.id.int)
    if welcomeMsg == redisNil:
        return
    else:
        await clearRedisKey("welcome" & $response.chat.id.int)
        var msg = newMessage(response.chat.id, "Cleared welcome message!")
        msg.replyToMessageId = response.messageId
        discard await b.send(msg)