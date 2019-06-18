# Copyright (C) 2019 Rupansh Sekar
#
# Licensed under the Raphielscape Public License, Version 1.b (the "License");
# you may not use this file except in compliance with the License.
#

import essentials
import redishandling
from redis import redisNil
from strutils import split, parseInt
import times
from unicode import isAlpha

import telebot, asyncdispatch, logging, options


# slightly experimental as i have noticed some unexpected behaviour
proc floodListener*(b: Telebot, u: Update) {.async.} =
    let r = u.message
    if r.isNone:
        return
    let response = r.get

    let limit = waitFor getRedisKey("floodlimit" & $response.chat.id.int)
    if limit == redisNil:
        return

    if await canBotRestrict(b, response):
        let currFlood = waitFor getRedisKey("currflood" & $response.chat.id.int) # run in blocking
        if currFlood == redisNil:
            await setRedisKey("currflood" & $response.chat.id.int, $response.fromUser.get.id & " 1")
        
        if $response.fromUser.get.id == currFlood.split(" ")[0]:
            let userFlood = parseInt(currFlood.split(" ")[1]) + 1
            await setRedisKey("currflood" & $response.chat.id.int, $response.fromUser.get.id & " " & $userFlood)
        else:
            await setRedisKey("currflood" & $response.chat.id.int, $response.fromUser.get.id & " 1")

        if (not await isUserAdm(b, response.chat.id.int, response.fromUser.get.id)) and parseInt(currFlood.split(" ")[1]) > parseInt(limit):
            var msg = newMessage(response.chat.id, "Get out of here!")
            msg.replyToMessageId = response.messageId
            discard await b.send(msg)

            discard await kickChatMember(b, $response.chat.id, response.fromUser.get().id, toUnix(getTime()).int - 31)



proc setFloodHandler*(b: TeleBot, c: Command) {.async.} =
    let response = c.message

    if await isUserAdm(b, response.chat.id.int, response.fromUser.get.id):
        var text: string
        if ' ' in c.message.text.get:
            text = c.message.text.get.split(" ")[^1]
        if (text == "") or text.isAlpha or (parseInt(text) <= 0):
            return
        
        await setRedisKey("floodlimit" & $response.chat.id.int, text)

        var msg = newMessage(response.chat.id.int, "Flood limit set to " & text)
        msg.replyToMessageId = response.messageId
        discard await b.send(msg)

proc clearFloodHandler*(b: TeleBot, c: Command) {.async.} =
    let response = c.message

    if await isUserAdm(b, response.chat.id.int, response.fromUser.get.id):
        let limit = waitFor getRedisKey("floodlimit" & $response.chat.id.int)
        if limit == redisNil:
            return
        else:
            await clearRedisKey("floodlimit" & $response.chat.id.int)
        
        var msg = newMessage(response.chat.id, "Cleared flood limit!")
        msg.replyToMessageId = response.messageId
        discard await b.send(msg)

proc getFloodHandler*(b: TeleBot, c: Command) {.async.} =
    let response = c.message

    if await isUserAdm(b, response.chat.id.int, response.fromUser.get.id):
        let limit = waitFor getRedisKey("floodlimit" & $response.chat.id.int)
        if limit == redisNil:
            return
        else:
            var msg = newMessage(response.chat.id.int, "Current flood limit: " & limit)
            msg.replyToMessageId = response.messageId
            discard await b.send(msg)