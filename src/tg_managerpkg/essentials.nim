# Copyright (C) 2019 Rupansh Sekar
#
# Licensed under the Raphielscape Public License, Version 1.b (the "License");
# you may not use this file except in compliance with the License.
#

import httpclient
import redishandling
from sam import toBool
import streams
import strutils
import times
import config

import telebot, asyncdispatch, logging, options, telebot/utils


# Simplified tg api procs
template ourOnCommand*(bot: TeleBot, cmd: string, procName) =
    block:
        proc ourProc2(b: TeleBot, c: Command) {.async.} =
            try:
                await procName(b, c)
            except:
                let
                    e = getCurrentException()
                    msg = getCurrentExceptionMsg()
                let sendMsg = "Got Exception With Msg " & msg
                echo sendMsg
                discard await b.sendMessage(dumpChannel, sendMsg)

        bot.onCommand(cmd, ourProc2)

template ourOnUpdate*(bot: TeleBot, procName) =
    block:
        proc ourProc2(b: TeleBot, u: Update) {.async.} =
            try:
                await procName(b, u)
            except:
                let
                    e = getCurrentException()
                    msg = getCurrentExceptionMsg()
                let sendMsg = "Got Exception With Msg " & msg
                discard await b.sendMessage(dumpChannel, sendMsg)

        bot.onUpdate(ourProc2)

template canDisableCommand*(bot: TeleBot, cmd: string, procName) =
    cmdList &= cmd
    block:
        proc ourProc(b: TeleBot, c: Command) {.async.} =
            let ourName = cmd
            let response = c.message
            let disabled = await getRedisList("disabled" & $response.chat.id.int)
            if not (ourName in disabled):
                await procName(b, c)

        bot.ourOnCommand(cmd, ourProc)

template canBotX(procName, canProc) =
    proc procName*(b: TeleBot, m: Message): Future[bool] {.async.} =
        let bot = await b.getMe()
        let botChat = await getChatMember(b, $m.chat.id.int, bot.id)
        if botChat.canProc.isSome:
            return botChat.canProc.get


canBotX(canBotPromote, canPromoteMembers)
canBotX(canBotPin, canPinMessages)
canBotX(canBotInvite, canInviteUsers)
canBotX(canBotRestrict, canRestrictMembers)
canBotX(canBotDelete, canDeleteMessages)
canBotX(canBotInfo, canChangeInfo)

proc canBotRestrict2*(b: TeleBot, chat: string): Future[bool] {.async.} =
    let bot = await b.getMe()
    let botChat = await getChatMember(b, chat, bot.id)
    if botChat.canRestrictMembers.isSome:
        return botChat.canRestrictMembers.get

proc isUserInChat*(b: TeleBot, chat_id: int, user_id: int): Future[bool] {.async.} =
    let user = await getChatMember(b, $chat_id, user_id)
    return not (user.status in ["left", "kicked"])

proc isUserAdm*(b: TeleBot, chat_id: int, user_id: int): Future[bool] {.async.} =
    let user = await getChatMember(b, $chat_id, user_id)
    return (user.status in ["creator", "administrator"]) or (user_id in sudos) or (user_id == parseInt(config.owner))

proc getTime*(b: TeleBot, response: Message): int =
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
        var msg = newMessage(response.chat.id, "Invalid time")
        msg.replyToMessageId = response.messageId
        discard b.send(msg)
        result = 0
    else:
        result = (toUnix(getTime()).int + extratime*timeConst)


# not provided by nim libs
proc saveBuf*(fileUrl: string): (Stream, string) =
    var client = newHttpClient()
    let file = client.get(fileUrl)
    return (file.bodyStream, file.contentType)


# Our implementation of tg api methods
proc sendDocument*(b: TeleBot, chatId: int, document: telebot.File, replyToMessageId = 0, forceDoc = false, filename = ""): Future[Message] {.async.} =
    ## send Document from file
    END_POINT("sendDocument")
    var data = newMultipartData()
    data["chat_id"] = $chatId

    if replyToMessageId != 0:
        data["reply_to_message_id"] = $replyToMessageId

    if forceDoc:
        let fileUrl = FILE_URL % @[b.token, document.filePath.get]
        let buf = saveBuf(fileUrl)
        data["document"] = (filename, buf[1], buf[0].readAll)
    else:
        data["document"] = document.fileId

    let res = await makeRequest(b, endpoint % b.token, data)
    result = unmarshal(res, Message)

proc sendMessage*(b: TeleBot, chat: string, message: string, parseMode = "", replyToMessageId = 0): Future[Message] {.async.} =
    END_POINT("sendMessage")
    var data = newMultipartData()
    data["chat_id"] = chat
    data["text"] = message
    if parseMode != "":
        data["parse_mode"] = parseMode
    if replyToMessageId != 0:
        data["reply_to_message_id"] = $replyToMessageId

    let res = await makeRequest(b, endpoint % b.token, data)
    result = unmarshal(res, Message)

proc ourUploadStickerFile*(b: TeleBot, userId: int, stickId: string): Future[telebot.File] {.async.} =
    END_POINT("uploadStickerFile")
    var data = newMultipartData()
    data["user_id"] = $userId
    let sticker = await getFile(b, stickId)
    let fileUrl = FILE_URL % @[b.token, sticker.filePath.get]
    let buf = saveBuf(fileUrl)
    data["png_sticker"] = ("sticker.png", buf[1], buf[0].readAll)

    let res = await makeRequest(b, endpoint % b.token, data)
    result = unmarshal(res, telebot.File)

proc uploadStickerFileFromBuf*(b: TeleBot, userId: int, img: seq[byte]): Future[telebot.File] {.async.} =
    END_POINT("uploadStickerFile")
    var data = newMultipartData()
    data["user_id"] = $userId
    let buf = cast[string](img)
    data["png_sticker"] = ("sticker.png", "image/png", buf)

    let res = await makeRequest(b, endpoint % b.token, data)
    result = unmarshal(res, telebot.FIle)

proc ourAddStickerToSet*(b: TeleBot, userId: int, name: string, pngSticker: string, emojis: string): Future[bool] {.async.} =
    END_POINT("addStickerToSet")
    var data = newMultipartData()
    data["user_id"] = $userId
    data["name"] = name
    data["png_sticker"] = pngSticker
    data["emojis"] = emojis
    let res = await makeRequest(b, endpoint % b.token, data)
    result = res.toBool

proc ourCreateNewStickerSet*(b: TeleBot, userId: int, name: string, title: string, pngSticker: string, emojis: string): Future[bool] {.async.} =
    END_POINT("createNewStickerSet")
    var data = newMultipartData()
    data["user_id"] = $userId
    data["name"] = name
    data["title"] = title
    data["png_sticker"] = pngSticker
    data["emojis"] = emojis
    let res = await makeRequest(b, endpoint % b.token, data)
    result = res.toBool
