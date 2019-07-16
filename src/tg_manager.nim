# Copyright (C) 2019 Rupansh Sekar
#
# Licensed under the Raphielscape Public License, Version 1.b (the "License");
# you may not use this file except in compliance with the License.
#

import tg_managerpkg/[
  blacklist,
  config,
  disablecmd,
  essentials,
  floodcheck,
  grestrict,
  information,
  intro,
  kang,
  manage,
  memes,
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
    bot.ourOnCommand("promote", promoteHandler)
    bot.ourOnCommand("demote", demoteHandler)
    bot.ourOnCommand("pin", pinHandler)
    bot.ourOnCommand("unpin", unpinHandler)
    bot.ourOnCommand("invite", inviteHandler)
    bot.ourOnCommand("admins", adminList)

    # restrictictions
    bot.ourOnCommand("ban", banHandler)
    bot.ourOnCommand("tban", tbanHandler)
    bot.ourOnCommand("banme", banMeHandler)
    bot.ourOnCommand("unban", unbanHandler)
    bot.ourOnCommand("kick", kickHandler)
    bot.ourOnCommand("kickme", kickMeHandler)
    bot.ourOnCommand("mute", muteHandler)
    bot.ourOnCommand("tmute", tmuteHandler)
    bot.ourOnCommand("unmute", unmuteHandler)

    # information
    bot.ourOnCommand("id", idHandler)
    bot.ourOnCommand("info", infoHandler)
    bot.ourOnCommand("ping", pingHandler)

    # msg deleting
    bot.ourOnCommand("purge", purgeHandler)
    bot.ourOnCommand("del", delHandler)

    # stickers
    bot.ourOnCommand("getsticker", getStickerHandler)
    bot.ourOnCommand("kang", kangHandler)

    # blacklist
    bot.onUpdate(blacklistListener)
    bot.ourOnCommand("addblacklist", addBlacklistHandler)
    bot.ourOnCommand("rmblacklist", rmBlacklistHandler)
    bot.ourOnCommand("getblacklist", getBlacklistHandler)

    # flood
    bot.onUpdate(floodListener)
    bot.ourOnCommand("setflood", setFloodHandler)
    bot.ourOnCommand("clearflood", clearFloodHandler)
    bot.ourOnCommand("getflood", getFloodHandler)

    # notes
    bot.ourOnCommand("save", addNoteHandler)
    bot.ourOnCommand("get", getNoteHandler)
    bot.ourOnCommand("clear", rmNoteHandler)
    bot.ourOnCommand("saved", savedNotesHandler)

    # global restrictions
    bot.onUpdate(grestrictListener)
    bot.ourOnCommand("gban", gbanHandler)
    bot.ourOnCommand("ungban", ungbanHandler)
    bot.ourOnCommand("gmute", gmuteHandler)
    bot.ourOnCommand("ungmute", ungmuteHandler)

    # rules
    bot.ourOnCommand("setrules", setRulesHandler)
    bot.ourOnCommand("rules", getRulesHandler)

    # intro
    bot.ourOnCommand("start", startHandler)
    bot.ourOnCommand("help", helpHandler)

    # memes
    bot.ourOnCommand("owo", owoHandler)
    bot.ourOnCommand("stretch", stretchHandler)
    bot.ourOnCommand("vapor", vaporHandler)
    bot.ourOnCommand("mock", mockHandler)
    bot.ourOnCommand("zalgo", zalgoHandler)

    # disable
    bot.onCommand("disable", disableHandler)
    bot.onCommand("enable", enableHandler)
    bot.onCommand("getdisabled", getDisabledHandler)

    bot.poll(timeout=500)

    # save redis server when we are done
    addQuitProc(saveRedis)

when isMainModule:
    main()
