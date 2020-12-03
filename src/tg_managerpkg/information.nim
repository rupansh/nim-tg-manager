# Copyright (C) 2019 Rupansh Sekar
#
# Licensed under the Raphielscape Public License, Version 1.b (the "License");
# you may not use this file except in compliance with the License.
#

import net
import times
import config
import essentials
from strutils import parseInt

import telebot, asyncdispatch, options


proc idHandler*(b: TgManager, c: Command) {.async.} =
    let response = c.message
    var sendid: string
    if response.replyToMessage.isSome:
        if response.replyToMessage.get.fromUser.get().isBot:
            sendid = "Bot's id: " & $response.replyToMessage.get.fromUser.get().id
        else:
            sendid = "User's id: " & $response.replyToMessage.get.fromUser.get().id
    else:
        sendid = "Group id: " & $response.chat.id

    discard await b.bot.sendMessage(response.chat.id, sendid, replyToMessageId = response.messageId)

proc infoHandler*(b: TgManager, c: Command) {.async.} =
    let response = c.message
    var user: User

    if response.replyToMessage.isSome:
        user = response.replyToMessage.get.fromUser.get
    else:
        user = response.fromUser.get

    var txt: string
    if user.isBot:
        txt = "***Bot Info***\n\n"
    else:
        txt = "***User Info***\n\n"
    if (await getChatMember(b.bot, $response.chat.id, user.id)).status in ["creator", "administrator"]:
        txt = txt & "***Admin***\n"
    if user.id == parseInt(b.config.owner):
        txt = txt & "***Bot_Owner***\n"
    if user.id in b.config.sudos:
        txt = txt & "***Sudo***\n"
    txt = txt & "ID:  " & $user.id & "\n"
    txt = txt & "First Name:  " & user.firstName & "\n"
    if user.lastName.isSome:
        txt = txt & "Last Name:  " & user.lastName.get & "\n"
    if user.username.isSome:
        txt = txt & "Username:  @" & user.username.get & "\n"

    discard b.bot.sendMessage(response.chat.id, txt, parseMode= "markdown", replyToMessageId = response.messageId)

proc pingHandler*(b: TgManager, c: Command) {.async.} =
    let socket = newSocket()
    let time = cpuTime()
    socket.connect("api.telegram.org", Port(80))
    let avgTime = ((cpuTime() - time)*1000).int

    let response = c.message
    discard b.bot.sendMessage(response.chat.id, "***PONG!***\nPing: " & $avgTime & "ms", parseMode = "markdown", replyToMessageId = response.messageId)
