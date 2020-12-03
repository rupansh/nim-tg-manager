# Copyright (C) 2019 Rupansh Sekar
#
# Licensed under the Raphielscape Public License, Version 1.b (the "License");
# you may not use this file except in compliance with the License.
#

import httpclient
import redishandling
import redis
from sam import toBool
import sets
import streams
import strutils
import tables
import times
import config

import telebot, asyncdispatch, logging, options, telebot/private/utils


type TgManager* = ref object
    bot*: TeleBot
    config*: BotConfig
    db*: AsyncRedis

type CommandCb = proc(i0: TgManager, i1: Command): Future[void]

# Simplified tg api procs
template ourOnCommand*(manager: TgManager, cmd: string, procName: CommandCb) =
    block:
        proc ourProc2(b: TeleBot, c: Command): Future[bool] {.async.} =
            try:
                await procName(manager, c)
            except:
                let m = getCurrentExceptionMsg()
                error(m)
                discard await manager.ourSendMessage(dc, "Got Exception! Please check log!")

        manager.bot.onCommand(cmd, ourProc2)

template ourOnUpdate*(manager: TgManager, procName) =
    block:
        proc ourProc2(b: TeleBot, u: Update): Future[bool] {.async.} =
            try:
                await procName(manager, u)
            except:
                let m = getCurrentExceptionMsg()
                error(m)
                discard await manager.ourSendMessage(dc, "Got Exception! Please check log!")

        manager.bot.onUpdate(ourProc2)

template canDisableCommand*(manager: TgManager, cmd: string, procName) =
    block:
        proc ourProc(b: TgManager, c: Command) {.async.} =
            let response = c.message
            let disabled = await b.db.getRedisList("disabled" & $response.chat.id.int)
            if not (cmd in disabled):
                await procName(b, c)

        manager.ourOnCommand(cmd, ourProc)

template canBotX(procName, canProc) =
    proc procName*(b: TgManager, m: Message): Future[bool] {.async.} =
        let bot = await b.bot.getMe()
        let botChat = await getChatMember(b.bot, $m.chat.id.int, bot.id)
        if botChat.canProc.isSome:
            return botChat.canProc.get


canBotX(canBotPromote, canPromoteMembers)
canBotX(canBotPin, canPinMessages)
canBotX(canBotInvite, canInviteUsers)
canBotX(canBotRestrict, canRestrictMembers)
canBotX(canBotDelete, canDeleteMessages)
canBotX(canBotInfo, canChangeInfo)

proc canBotRestrict2*(b: TgManager, chat: string): Future[bool] {.async.} =
    let bot = await b.bot.getMe()
    let botChat = await getChatMember(b.bot, chat, bot.id)
    if botChat.canRestrictMembers.isSome:
        return botChat.canRestrictMembers.get

proc isUserInChat*(b: TgManager, chat_id: int, user_id: int): Future[bool] {.async.} =
    let user = await getChatMember(b.bot, $chat_id, user_id)
    return not (user.status in ["left", "kicked"])

proc isUserAdm*(b: TgManager, chat_id: int, user_id: int): Future[bool] {.async.} =
    let user = await getChatMember(b.bot, $chat_id, user_id)
    return (user.status in ["creator", "administrator"]) or (user_id in b.config.sudos) or (user_id == parseInt(b.config.owner))

proc getTime*(b: TgManager, response: Message): Future[int] {.async.} =
    var toRepl: string
    var timeConst: int
    var extratime: int

    if 'd' in response.text.get:
        toRepl = "d"
        timeConst = 86400
    elif 'h' in response.text.get:
        toRepl = "h"
        timeConst = 3600
    elif 'm' in response.text.get:
        toRepl = "m"
        timeConst = 60
    else:
        extratime = 0

    try:
        extratime = parseInt(response.text.get.split(" ")[^2].replace(toRepl, ""))
    except:
        extratime = 0

    if extratime <= 0:
        discard await b.bot.sendMessage(response.chat.id, "Invalid time", replyToMessageId = response.messageId)
        result = 0
    else:
        result = (toUnix(getTime()).int + extratime*timeConst)


# not provided by nim libs
proc saveBuf*(fileUrl: string): (Stream, string) =
    var client = newHttpClient()
    let file = client.get(fileUrl)
    return (file.bodyStream, file.contentType)


# Our implementation of tg api methods
proc sendDocument*(b: TgManager, chatId: int, document: telebot.File, replyToMessageId = 0, forceDoc = false, filename = ""): Future[Message] {.async.} =
    ## send Document from file
    END_POINT("sendDocument")
    var data = newMultipartData()
    data["chat_id"] = $chatId

    if replyToMessageId != 0:
        data["reply_to_message_id"] = $replyToMessageId

    if forceDoc:
        let fileUrl = FILE_URL % @[b.bot.token, document.filePath.get]
        let buf = saveBuf(fileUrl)
        data["document"] = (filename, buf[1], buf[0].readAll)
    else:
        data["document"] = document.fileId

    let res = await makeRequest(b.bot, endpoint % b.bot.token, data)
    result = unmarshal(res, Message)

proc ourSendMessage*(b: TgManager, chat: string, message: string, parseMode = "", replyToMessageId = 0): Future[Message] {.async.} =
    END_POINT("sendMessage")
    var data = newMultipartData()
    data["chat_id"] = chat
    data["text"] = message
    if parseMode != "":
        data["parse_mode"] = parseMode
    if replyToMessageId != 0:
        data["reply_to_message_id"] = $replyToMessageId

    let res = await makeRequest(b.bot, endpoint % b.bot.token, data)
    result = unmarshal(res, Message)

proc ourUploadStickerFile*(b: TgManager, userId: int, stickId: string): Future[telebot.File] {.async.} =
    END_POINT("uploadStickerFile")
    var data = newMultipartData()
    data["user_id"] = $userId
    let sticker = await getFile(b.bot, stickId)
    let fileUrl = FILE_URL % @[b.bot.token, sticker.filePath.get]
    let buf = saveBuf(fileUrl)
    data["png_sticker"] = ("sticker.png", buf[1], buf[0].readAll)

    let res = await makeRequest(b.bot, endpoint % b.bot.token, data)
    result = unmarshal(res, telebot.File)

proc uploadStickerFileFromBuf*(b: TgManager, userId: int, img: seq[byte]): Future[telebot.File] {.async.} =
    END_POINT("uploadStickerFile")
    var data = newMultipartData()
    data["user_id"] = $userId
    let buf = cast[string](img)
    data["png_sticker"] = ("sticker.png", "image/png", buf)

    let res = await makeRequest(b.bot, endpoint % b.bot.token, data)
    result = unmarshal(res, telebot.FIle)

proc ourAddStickerToSet*(b: TgManager, userId: int, name: string, pngSticker: string, emojis: string): Future[bool] {.async.} =
    END_POINT("addStickerToSet")
    var data = newMultipartData()
    data["user_id"] = $userId
    data["name"] = name
    data["png_sticker"] = pngSticker
    data["emojis"] = emojis
    let res = await makeRequest(b.bot, endpoint % b.bot.token, data)
    result = res.toBool

proc ourCreateNewStickerSet*(b: TgManager, userId: int, name: string, title: string, pngSticker: string, emojis: string): Future[bool] {.async.} =
    END_POINT("createNewStickerSet")
    var data = newMultipartData()
    data["user_id"] = $userId
    data["name"] = name
    data["title"] = title
    data["png_sticker"] = pngSticker
    data["emojis"] = emojis
    let res = await makeRequest(b.bot, endpoint % b.bot.token, data)
    result = res.toBool
