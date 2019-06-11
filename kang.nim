# Copyright (C) 2019 Rupansh Sekar
#
# Licensed under the Raphielscape Public License, Version 1.b (the "License");
# you may not use this file except in compliance with the License.
#

import essentials

import telebot, asyncdispatch, logging, options


proc getStickerHandler*(b: TeleBot, c: Command) {.async.} =
    let response = c.message
    if response.replyToMessage.isSome and response.replyToMessage.get.sticker.isSome:
        let sticker = await getFile(b, response.replyToMessage.get.sticker.get.fileId)
        discard await sendDocument(b, response.chat.id.int, sticker, response.messageId, forceDoc = true, "sticker.png")