# Copyright (C) 2019 Rupansh Sekar
#
# Licensed under the Raphielscape Public License, Version 1.b (the "License");
# you may not use this file except in compliance with the License.
#

import config
import essentials
import redishandling
import strutils

import telebot, asyncdispatch, logging, options


proc addNoteHandler*(b: TeleBot, c: Command) {.async.} =
    let response = c.message
    if not response.replyToMessage.isSome:
        return
    if not (' ' in response.text.get):
        return
    if response.text.get.split(" ").len < 2:
        return

    if await isUserAdm(b, response.chat.id.int, response.fromUser.get.id):
        let noteName = response.text.get.split(" ")[1]
        let noteNames = waitFor getRedisList("noteNames" & $response.chat.id.int)
        let fwdList = waitFor getRedisList("notefwd" & $response.chat.id.int)
        var noteText: string
        var noteFwd = false
        if response.replyToMessage.get.text.isSome:
            noteText = response.replyToMessage.get.text.get
        else:
            let fwd = await b.forwardMessage(dumpChannel, $response.chat.id.int,
                            response.replyToMessage.get.messageId, true)
            noteText = $fwd.messageId
            noteFwd = true
        
        if not (noteName in noteNames):
            await appRedisList("noteNames" & $response.chat.id.int, noteName)
        if noteFwd and (not (noteName in fwdList)):
            await appRedisList("notefwd" & $response.chat.id.int, noteName)
        elif not noteFwd and (noteName in fwdList):
            await rmRedisList("notefwd" & $response.chat.id.int, noteName)

        await setRedisKey("note-" & noteName & $response.chat.id.int, noteText)

        var msg = newMessage(response.chat.id.int, "Added note " & noteName & "!")
        msg.replyToMessageId = response.messageId
        discard await b.send(msg)

proc getNoteHandler*(b: TeleBot, c: Command) {.async.} =
    let response = c.message
    if not (' ' in response.text.get):
        return
    if response.text.get.split(" ").len < 2:
        return

    let toGet = response.text.get.split(" ")[1]
    let noteNames = waitFor getRedisList("noteNames" & $response.chat.id.int)
    let noteFwd = waitFor getRedisList("notefwd" & $response.chat.id.int)

    if toGet in noteNames:
        let noteText = waitFor getRedisKey("note-" & toGet & $response.chat.id.int)
        if toGet in noteFwd:
            discard await b.forwardMessage($response.chat.id, dumpChannel, parseInt(noteText))
        else:
            var msg = newMessage(response.chat.id.int, noteText)
            msg.replyToMessageId = response.messageId
            discard await b.send(msg)
    else:
        var msg = newMessage(response.chat.id.int, "Note not found!")
        msg.replyToMessageId = response.messageId
        discard await b.send(msg)

proc rmNoteHandler*(b: TeleBot, c: Command) {.async.} =
    let response = c.message
    if not (' ' in response.text.get):
        return
    if response.text.get.split(" ").len < 2:
        return

    if await isUserAdm(b, response.chat.id.int, response.fromUser.get.id):
        let torm = response.text.get.split(" ")[1]
        let noteNames = waitFor getRedisList("noteNames" & $response.chat.id.int)
        let noteFwd = waitFor getRedisList("notefwd" & $response.chat.id.int)
        if torm in noteNames:
            if torm in noteFwd:
                await rmRedisList("notefwd" & $response.chat.id.int, torm)
            await rmRedisList("noteNames" & $response.chat.id, torm)
            await clearRedisKey("note-" & torm & $response.chat.id)
            
            var msg = newMessage(response.chat.id.int, "Removed " & torm)
            msg.replyToMessageId = response.messageId
            discard await b.send(msg)
    