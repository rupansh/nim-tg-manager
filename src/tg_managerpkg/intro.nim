# Copyright (C) 2019 Rupansh Sekar
#
# Licensed under the Raphielscape Public License, Version 1.b (the "License");
# you may not use this file except in compliance with the License.
#

import config
import essentials

import telebot, asyncdispatch, logging, options


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
