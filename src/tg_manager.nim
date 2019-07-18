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
    bot.canDisableCommand("promote", promoteHandler)
    bot.canDisableCommand("demote", demoteHandler)
    bot.canDisableCommand("pin", pinHandler)
    bot.canDisableCommand("unpin", unpinHandler)
    bot.canDisableCommand("invite", inviteHandler)
    bot.canDisableCommand("admins", adminList)

    # restrictictions
    bot.canDisableCommand("ban", banHandler)
    bot.canDisableCommand("tban", tbanHandler)
    bot.canDisableCommand("banme", banMeHandler)
    bot.canDisableCommand("unban", unbanHandler)
    bot.canDisableCommand("kick", kickHandler)
    bot.canDisableCommand("kickme", kickMeHandler)
    bot.canDisableCommand("mute", muteHandler)
    bot.canDisableCommand("tmute", tmuteHandler)
    bot.canDisableCommand("unmute", unmuteHandler)

    # information
    bot.canDisableCommand("id", idHandler)
    bot.canDisableCommand("info", infoHandler)
    bot.canDisableCommand("ping", pingHandler)

    # msg deleting
    bot.canDisableCommand("purge", purgeHandler)
    bot.canDisableCommand("del", delHandler)

    # stickers
    bot.canDisableCommand("getsticker", getStickerHandler)
    bot.canDisableCommand("kang", kangHandler)

    # blacklist
    bot.onUpdate(blacklistListener)
    bot.canDisableCommand("addblacklist", addBlacklistHandler)
    bot.canDisableCommand("rmblacklist", rmBlacklistHandler)
    bot.canDisableCommand("getblacklist", getBlacklistHandler)

    # flood
    bot.onUpdate(floodListener)
    bot.canDisableCommand("setflood", setFloodHandler)
    bot.canDisableCommand("clearflood", clearFloodHandler)
    bot.canDisableCommand("getflood", getFloodHandler)

    # notes
    bot.canDisableCommand("save", addNoteHandler)
    bot.canDisableCommand("get", getNoteHandler)
    bot.canDisableCommand("clear", rmNoteHandler)
    bot.canDisableCommand("saved", savedNotesHandler)

    # global restrictions
    bot.onUpdate(grestrictListener)
    bot.canDisableCommand("gban", gbanHandler)
    bot.canDisableCommand("ungban", ungbanHandler)
    bot.canDisableCommand("gmute", gmuteHandler)
    bot.canDisableCommand("ungmute", ungmuteHandler)

    # rules
    bot.canDisableCommand("setrules", setRulesHandler)
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
