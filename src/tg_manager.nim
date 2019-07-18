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
    bot.onCommand("promote", promoteHandler)
    bot.onCommand("demote", demoteHandler)
    bot.onCommand("pin", pinHandler)
    bot.onCommand("unpin", unpinHandler)
    bot.canDisableCommand("invite", inviteHandler)
    bot.canDisableCommand("admins", adminList)

    # restrictictions
    bot.onCommand("ban", banHandler)
    bot.onCommand("tban", tbanHandler)
    bot.canDisableCommand("banme", banMeHandler)
    bot.onCommand("unban", unbanHandler)
    bot.onCommand("kick", kickHandler)
    bot.canDisableCommand("kickme", kickMeHandler)
    bot.onCommand("mute", muteHandler)
    bot.onCommand("tmute", tmuteHandler)
    bot.onCommand("unmute", unmuteHandler)

    # information
    bot.canDisableCommand("id", idHandler)
    bot.canDisableCommand("info", infoHandler)
    bot.canDisableCommand("ping", pingHandler)

    # msg deleting
    bot.onCommand("purge", purgeHandler)
    bot.onCommand("del", delHandler)

    # stickers
    bot.canDisableCommand("getsticker", getStickerHandler)
    bot.canDisableCommand("kang", kangHandler)

    # blacklist
    bot.onUpdate(blacklistListener)
    bot.onCommand("addblacklist", addBlacklistHandler)
    bot.onCommand("rmblacklist", rmBlacklistHandler)
    bot.canDisableCommand("getblacklist", getBlacklistHandler)

    # flood
    bot.onUpdate(floodListener)
    bot.onCommand("setflood", setFloodHandler)
    bot.onCommand("clearflood", clearFloodHandler)
    bot.onCommand("getflood", getFloodHandler)

    # notes
    bot.onCommand("save", addNoteHandler)
    bot.canDisableCommand("get", getNoteHandler)
    bot.onCommand("clear", rmNoteHandler)
    bot.canDisableCommand("saved", savedNotesHandler)

    # global restrictions
    bot.onUpdate(grestrictListener)
    bot.onCommand("gban", gbanHandler)
    bot.onCommand("ungban", ungbanHandler)
    bot.onCommand("gmute", gmuteHandler)
    bot.onCommand("ungmute", ungmuteHandler)

    # rules
    bot.onCommand("setrules", setRulesHandler)
    bot.canDisableCommand("rules", getRulesHandler)

    # intro
    bot.canDisableCommand("start", startHandler)
    bot.canDisableCommand("help", helpHandler)

    # memes
    bot.canDisableCommand("owo", owoHandler)
    bot.canDisableCommand("stretch", stretchHandler)
    bot.canDisableCommand("vapor", vaporHandler)
    bot.canDisableCommand("mock", mockHandler)
    bot.canDisableCommand("zalgo", zalgoHandler)

    # disable
    bot.onCommand("disable", disableHandler)
    bot.onCommand("enable", enableHandler)
    bot.onCommand("getdisabled", getDisabledHandler)

    bot.poll(timeout=500)

    # save redis server when we are done
    addQuitProc(saveRedis)

when isMainModule:
    main()
