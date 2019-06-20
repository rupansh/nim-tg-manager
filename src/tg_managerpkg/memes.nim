# Copyright (C) 2019 Rupansh Sekar
#
# Licensed under the Raphielscape Public License, Version 1.b (the "License");
# you may not use this file except in compliance with the License.
#

from random import sample, rand
import re
from strutils import replace, repeat
import tables
import unicode

import telebot, asyncdispatch, logging, options


proc owoHandler*(b: TeleBot, c: Command) {.async.} =
    let response = c.message

    var replyText: string
    if not (response.replyToMessage.isSome and response.replyToMessage.get.text.isSome):
        replyText = "You must reply to a text message!"
    else:
        let faces = ["(・`ω´・)",";;w;;","owo","UwU",">w<","^w^","( ^ _ ^)∠☆",
        "(ô_ô)","~:o",";____;", "(*^*)", "(>_<)", "(♥_♥)", "*(^O^)*", "((+_+))"]
        replyText = replace(response.replyToMessage.get.text.get, re"[ｒｌ]", "ｗ")
        replyText = replace(reply_text, re"[RL]", "W")
        replyText = replace(reply_text, re"[ＲＬ]", "Ｗ")
        replyText = replacef(reply_text, re"n([aeiouａｅｉｏｕ])", "ny$1")
        replyText = replacef(reply_text, re"ｎ([ａｅｉｏｕ])", "ｎｙ$1")
        replyText = replacef(reply_text, re"N([aeiouAEIOU])", "Ny$1")
        replyText = replacef(reply_text, re"Ｎ([ａｅｉｏｕＡＥＩＯＵ])", "Ｎｙ$1", )
        replyText = replace(reply_text, re"\!+", " " & sample(faces))
        replyText = replace(reply_text, re"！+", " " & sample(faces))
        replyText = reply_text.replace("ove", "uv")
        replyText = reply_text.replace("ｏｖｅ", "ｕｖ")
        replyText &= " " & sample(faces)
        if validateUTF8(replyText) != -1:
            replyText = "Can't handle non ascii text properly yet!"
    
    var msg = newMessage(response.chat.id.int, replyText)
    msg.replyToMessageId = response.messageId
    discard await b.send(msg)

proc stretchHandler*(b: TeleBot, c: Command) {.async.} =
    let response = c.message
    var replyText: string
    if response.replyToMessage.isSome and response.replyToMessage.get.text.isSome:
        replyText = replacef(response.replyToMessage.get.text.get, re"([aeiouAEIOUａｅｉｏｕＡＥＩＯＵ])", repeat("$1", rand(3..10)))
        if validateUTF8(replyText) != -1:
            replyText = "Can't handle non ascii text properly yet!"
    else:
        replyText = "You must reply to a text message!"
    
    var msg = newMessage(response.chat.id.int, replyText)
    msg.replyToMessageId = response.messageId
    discard await b.send(msg)

proc vaporHandler*(b: TeleBot, c: Command) {.async.} =
    let response = c.message
    var replyText: string

    if response.replyToMessage.isSome and response.replyToMessage.get.text.isSome:
        for charac in response.replyToMessage.get.text.get:
            if ord(charac) in 0x21..0x7F:
                replyText &= toUTF8((ord(charac) + 0xFEE0).Rune)
            elif ord(charac) == 0x20:
                replyText &= toUTF8(0x3000.Rune)
            else:
                replyText &= charac

        if validateUTF8(replyText) != -1:
            replyText = "Can't handle non ascii text properly yet!"
    else:
        replyText = "You must reply to a text message!"
    
    var msg = newMessage(response.chat.id.int, replyText)
    msg.replyToMessageId = response.messageId
    discard await b.send(msg)

proc mockHandler*(b: TeleBot, c: Command) {.async.} =
    let response = c.message
    var replyText = ""
    if response.replyToMessage.isSome and response.replyToMessage.get.text.isSome:
        for char in response.replyToMessage.get.text.get:
            if sample([true, false]):
                replyText &= toUTF8(toUpper(ord(char).Rune))
            else:
                replyText &= char
        if validateUTF8(replyText) != -1:
            replyText = "Can't handle non ascii text properly yet!"
    else:
        replyText = "You must reply to a text message!"
    
    var msg = newMessage(response.chat.id.int, replyText)
    msg.replyToMessageId = response.messageId
    discard await b.send(msg)