# Copyright (C) 2019 Rupansh Sekar
#
# Licensed under the Raphielscape Public License, Version 1.b (the "License");
# you may not use this file except in compliance with the License.
#

import essentials
import htmlparser
import httpclient
import imageman
import math
import streams
import strformat
import strutils
import xmltree

import telebot, asyncdispatch, options, telebot/private/utils


proc getStickerHandler*(b: TgManager, c: Command) {.async.} =
    let response = c.message
    if response.replyToMessage.isSome and response.replyToMessage.get.sticker.isSome:
        let sticker = await getFile(b.bot, response.replyToMessage.get.sticker.get.fileId)
        discard await sendDocument(b, response.chat.id.int, sticker, response.messageId, forceDoc = true, "sticker.png")
    else:
        discard await b.bot.sendMessage(response.chat.id, "Reply to a sticker to get it!", replyToMessageId = response.messageId)

proc kangHandler*(b: TgManager, c: Command) {.async.} =
    let response = c.message
    if response.replyToMessage.isSome:
        let bot = await b.bot.getMe()
        var packname = fmt"hqhq{$response.fromUser.get.id}_by_{bot.username.get}"
        var title: string
        var msgTxt: string
        var tfailed = false
        var emoji = "🌚"

        if response.fromUser.get.username.isSome:
            title = fmt"@{response.fromUser.get.username.get}'s kang pack"
        else:
            title = fmt"{response.fromUser.get.firstName}'s kang pack"

        var emojiBypass = false
        if ' ' in response.text.get:
            let emojiarr = response.text.get.split(" ")
            if emojiarr.len > 1:
                emoji = emojiarr[^1]
                emojiBypass = true

        var sticker: telebot.File
        if response.replyToMessage.get.sticker.isSome:
            if (not emojiBypass) and response.replyToMessage.get.sticker.get.emoji.isSome:
                emoji = response.replyToMessage.get.sticker.get.emoji.get
            sticker = await ourUploadStickerFile(b, response.fromUser.get.id, response.replyToMessage.get.sticker.get.fileId) # needed to fool retarded api
        elif response.replyToMessage.get.photo.isSome:
            let photoFile = await getFile(b.bot, response.replyToMessage.get.photo.get[^1].fileId)
            let photoUrl = FILE_URL % @[b.bot.token, photoFile.filePath.get]
            let buf = saveBuf(photoUrl)[0].readAll
            let buf2 = cast[seq[char]](buf)
            var img = readImage[ColorRGBAU](buf2)
            if not (img.width <= 512 and img.height <= 512):
                var ratio: float
                var newWidth: int
                var newHeight: int
                if img.width > img.height:
                    ratio = 512/img.width
                    newWidth = 512
                    newHeight = floor(512*ratio).int
                else:
                    ratio = 512/img.height
                    newWidth = floor(512*ratio).int
                    newHeight = 512
                img = img.resizedNN(newWidth, newHeight)
            let pngImg = writePNG(img)
            sticker = await uploadStickerFileFromBuf(b, response.fromUser.get.id, cast[seq[byte]](pngImg))
        else:
            msgTxt = "Reply to a sticker/image to kang it!"
            tfailed = true

        if not tfailed:
            var client = newAsyncHttpClient()
            let stickReq = await client.get("https://t.me/addstickers/" & packname)
            var stickText = innerText(parseHtml(await stickReq.body).findAll("strong")[2])
            stickText.delete(7, 8) # i still can't figure out UTF8 strings kek

            var succs = false
            if "StickerSet" in stickText:
                try:
                    succs = await ourCreateNewStickerSet(b, response.fromUser.get.id, packname, title, sticker.fileId, emoji)
                except IOError as ioerr:
                    if "500" in ioerr.msg:
                        succs = true
            else:
                try:
                    succs = await ourAddStickerToSet(b, response.fromUser.get.id, packname, sticker.fileId, emoji)
                except IOError as ioerr:
                    if "500" in ioerr.msg:
                        succs = true

            msgTxt = if succs: fmt"Added sticker to your [pack](t.me/addstickers/{packname})" else: "Unknown Problem occured!"

        discard await b.bot.sendMessage(response.chat.id, msgTxt, parseMode = "markdown", replyToMessageId = response.messageId)