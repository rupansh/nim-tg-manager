# Copyright (C) 2019 Rupansh Sekar
#
# Licensed under the Raphielscape Public License, Version 1.b (the "License");
# you may not use this file except in compliance with the License.
#

import tg_managerpkg/[
  blacklist,
  config,
  floodcheck,
  grestrict,
  information,
  kang,
  manage,
  msgdel,
  notes,
  restrict,
  rules
]
from tg_managerpkg/redishandling import saveRedis

import telebot, asyncdispatch, logging, options


proc main() =
    let bot = newTeleBot(apiKey)

    # management
    bot.onCommand("promote", promoteHandler)
    bot.onCommand("demote", demoteHandler)
    bot.onCommand("pin", pinHandler)
    bot.onCommand("unpin", unpinHandler)
    bot.onCommand("invite", inviteHandler)
    bot.onCommand("admins", adminList)

    # restrictictions
    bot.onCommand("ban", banHandler)
    bot.onCommand("tban", tbanHandler)
    bot.onCommand("banme", banMeHandler)
    bot.onCommand("unban", unbanHandler)
    bot.onCommand("kick", kickHandler)
    bot.onCommand("kickme", kickMeHandler)
    bot.onCommand("mute", muteHandler)
    bot.onCommand("tmute", tmuteHandler)
    bot.onCommand("unmute", unmuteHandler)

    # information
    bot.onCommand("id", idHandler)
    bot.onCommand("info", infoHandler)
    bot.onCommand("ping", pingHandler)

    # msg deleting
    bot.onCommand("purge", purgeHandler)
    bot.onCommand("del", delHandler)

    # stickers
    bot.onCommand("getsticker", getStickerHandler)
    bot.onCommand("kang", kangHandler)

    # blacklist
    bot.onUpdate(blacklistListener)
    bot.onCommand("addblacklist", addBlacklistHandler)
    bot.onCommand("rmblacklist", rmBlacklistHandler)
    bot.onCommand("getblacklist", getBlacklistHandler)

    # flood
    bot.onUpdate(floodListener)
    bot.onCommand("setflood", setFloodHandler)
    bot.onCommand("clearflood", clearFloodHandler)
    bot.onCommand("getflood", getFloodHandler)

    # notes
    bot.onCommand("save", addNoteHandler)
    bot.onCommand("get", getNoteHandler)
    bot.onCommand("clear", rmNoteHandler)
    bot.onCommand("saved", savedNotesHandler)

    # global restrictions
    bot.onUpdate(grestrictListener)
    bot.onCommand("gban", gbanHandler)
    bot.onCommand("ungban", ungbanHandler)
    bot.onCommand("gmute", gmuteHandler)
    bot.onCommand("ungmute", ungmuteHandler)

    # rules
    bot.onCommand("setrules", setRulesHandler)
    bot.onCommand("rules", getRulesHandler)

    bot.poll(timeout=500)

    # save redis server when we are done
    addQuitProc(saveRedis)

when isMainModule:
    main()
