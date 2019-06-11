# Copyright (C) 2019 Rupansh Sekar
#
# Licensed under the Raphielscape Public License, Version 1.b (the "License");
# you may not use this file except in compliance with the License.
#

import essentials
import strformat
import strutils

import telebot, asyncdispatch, logging, options


proc getStickerHandler*(b: TeleBot, c: Command) {.async.} =
    let response = c.message
    if response.replyToMessage.isSome and response.replyToMessage.get.sticker.isSome:
        let sticker = await getFile(b, response.replyToMessage.get.sticker.get.fileId)
        discard await sendDocument(b, response.chat.id.int, sticker, response.messageId, forceDoc = true, "sticker.png")
    else:
        var msg = newMessage(response.chat.id.int, "Reply to a sticker to get it!")
        msg.replyToMessageId = response.messageId
        b.send(msg)

proc kangHandler*(b: TeleBot, c: Command) {.async.} =
    let response = c.message
    if response.replyToMessage.isSome:
        let bot = await b.getMe()
        var packname = fmt"hqhq{$response.fromUser.get.id}_by_{bot.username.get}"
        var title: string
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

        if (not emojiBypass) and response.replyToMessage.get.sticker.get.emoji.isSome:
            emoji = response.replyToMessage.get.sticker.get.emoji.get

        if response.replyToMessage.get.sticker.isSome:
            var succ: bool
            let sticker = await ourUploadStickerFile(b, response.fromUser.get.id, response.replyToMessage.get.sticker.get.fileId) # needed to fool retarded api
            try:
                succ = await ourAddStickerToSet(b, response.fromUser.get.id, packname, sticker.fileId, emoji)
            except IOError:
                succ = await ourCreateNewStickerSet(b, response.fromUser.get.id, packname, title, sticker.fileId, emoji)

            if succ:
                var msg = newMessage(response.chat.id, fmt"Added sticker to your [pack](t.me/addstickers/{packname})")
                msg.replyToMessageId = response.messageId
                msg.parseMode = "markdown"
                discard await b.send(msg)
            else:
                var msg = newMessage(response.chat.id, "Unknown Problem occured!")
                msg.replyToMessageId = response.messageId
                discard await b.send(msg)
            return

    var msg = newMessage(response.chat.id, "Reply to a sticker to kang it!")
    msg.replyToMessageId = response.messageId
    discard await b.send(msg)
