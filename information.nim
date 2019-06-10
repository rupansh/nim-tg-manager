# Copyright (C) 2019 Rupansh Sekar
#
# Licensed under the Raphielscape Public License, Version 1.b (the "License");
# you may not use this file except in compliance with the License.
#

import net
import times
import config
from strutils import parseInt

import telebot, asyncdispatch, logging, options


proc idHandler*(b: TeleBot, c: Command) {.async.} =
    let response = c.message
    var sendid: string
    if response.replyToMessage.isSome:
        if response.replyToMessage.get.fromUser.get().isBot:
            sendid = "Bot's id: " & $response.replyToMessage.get.fromUser.get().id
        else:
            sendid = "User's id: " & $response.replyToMessage.get.fromUser.get().id
    else:
        sendid = "Group id: " & $response.chat.id
    
    var msg = newMessage(response.chat.id.int, sendid)
    msg.replyToMessageId = response.messageId
    discard await b.send(msg)

proc infoHandler*(b: TeleBot, c: Command) {.async.} =
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
    if (await getChatMember(b, $response.chat.id, user.id)).status in ["creator", "administrator"]:
        txt = txt & "***Admin***\n"
    if user.id == parseInt(owner):
        txt = txt & "***Bot_Owner***\n"
    if user.id in sudos:
        txt = txt & "***Sudo***\n"
    txt = txt & "ID:  " & $user.id & "\n"
    txt = txt & "First Name:  " & user.firstName & "\n"
    if user.lastName.isSome:
        txt = txt & "Last Name:  " & user.lastName.get & "\n"
    if user.username.isSome:
        txt = txt & "Username:  @" & user.username.get & "\n"
    
    var msg = newMessage(response.chat.id.int, txt)
    msg.replyToMessageId = response.messageId
    msg.parseMode = "markdown"
    discard b.send(msg)

proc pingHandler*(b: TeleBot, c: Command) {.async.} =
    let socket = newSocket()
    let time = cpuTime()
    socket.connect("api.telegram.org", Port(80))
    let avgTime = ((cpuTime() - time)*1000).int

    let response = c.message
    var msg = newMessage(response.chat.id.int, "***PONG!***\nPing: " & $avgTime & "ms")
    msg.replyToMessageId = response.messageId
    msg.parseMode = "markdown"
    discard b.send(msg)