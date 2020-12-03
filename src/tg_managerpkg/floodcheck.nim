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

import telebot, asyncdispatch, options


# slightly experimental as i have noticed some unexpected behaviour
proc floodListener*(b: TgManager, u: Update) {.async.} =
    let r = u.message
    if r.isNone:
        return
    let response = r.get

    let limit = await b.db.getRedisKey("floodlimit" & $response.chat.id.int)
    if limit == redisNil:
        return

    if await canBotRestrict(b, response):
        let currFlood = await b.db.getRedisKey("currflood" & $response.chat.id.int) # run in blocking
        if currFlood == redisNil:
            await b.db.setRedisKey("currflood" & $response.chat.id.int, $response.fromUser.get.id & " 1")

        if $response.fromUser.get.id == currFlood.split(" ")[0]:
            let userFlood = parseInt(currFlood.split(" ")[1]) + 1
            await b.db.setRedisKey("currflood" & $response.chat.id.int, $response.fromUser.get.id & " " & $userFlood)
        else:
            await b.db.setRedisKey("currflood" & $response.chat.id.int, $response.fromUser.get.id & " 1")

        if (not await isUserAdm(b, response.chat.id.int, response.fromUser.get.id)) and parseInt(currFlood.split(" ")[1]) > parseInt(limit):
            discard await b.bot.sendMessage(response.chat.id, "Get out of here", replyToMessageId = response.messageId)

            discard await kickChatMember(b.bot, $response.chat.id, response.fromUser.get().id, toUnix(getTime()).int - 31)



proc setFloodHandler*(b: TgManager, c: Command) {.async.} =
    let response = c.message

    if await isUserAdm(b, response.chat.id.int, response.fromUser.get.id):
        var text: string
        if ' ' in c.message.text.get:
            text = c.message.text.get.split(" ")[^1]
        if (text == "") or text.isAlpha or (parseInt(text) <= 0):
            return

        await b.db.setRedisKey("floodlimit" & $response.chat.id.int, text)

        discard await b.bot.sendMessage(response.chat.id, "Flood limit set to " & text, replyToMessageId = response.messageId)

proc clearFloodHandler*(b: TgManager, c: Command) {.async.} =
    let response = c.message

    if await isUserAdm(b, response.chat.id.int, response.fromUser.get.id):
        let limit = await b.db.getRedisKey("floodlimit" & $response.chat.id.int)
        if limit == redisNil:
            return
        else:
            await b.db.clearRedisKey("floodlimit" & $response.chat.id.int)

        discard await b.bot.sendMessage(response.chat.id, "Cleared flood limit!", replyToMessageId = response.messageId)

proc getFloodHandler*(b: TgManager, c: Command) {.async.} =
    let response = c.message

    if await isUserAdm(b, response.chat.id.int, response.fromUser.get.id):
        let limit = await b.db.getRedisKey("floodlimit" & $response.chat.id.int)
        if limit == redisNil:
            return
        else:
            discard await b.bot.sendMessage(response.chat.id, "Current flood limit: " & limit, replyToMessageId = response.messageId)
