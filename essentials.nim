# Copyright (C) 2019 Rupansh Sekar
#
# Licensed under the Raphielscape Public License, Version 1.b (the "License");
# you may not use this file except in compliance with the License.
#

from strutils import parseInt, replace, split
import times
import config

import telebot, asyncdispatch, logging, options


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

proc isUserInChat*(b: TeleBot, chat_id: int, user_id: int): Future[bool] {.async.} =
    let user = await getChatMember(b, $chat_id, user_id)
    return not (user.status in ["left", "kicked"])

proc isUserAdm*(b: TeleBot, chat_id: int, user_id: int): Future[bool] {.async.} =
    let user = await getChatMember(b, $chat_id, user_id)
    return (user.status in ["creator", "administrator"]) or (user_id in sudos) or (user_id == parseInt(owner))

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
        extratime = parseInt(response.text.get.split(" ")[^1].replace(toRepl, ""))
    except:
        extratime = 0

    if extratime <= 0:
        var msg = newMessage(response.chat.id, "Invalid time")
        msg.replyToMessageId = response.messageId
        discard b.send(msg)
        result = 0
    else:
        result = (toUnix(getTime()).int + extratime*timeConst)