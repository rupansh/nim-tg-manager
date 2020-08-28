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
    bot.canDisableCommand("invite", inviteHandler)
    bot.canDisableCommand("admins", adminList)
    bot.ourOnCommand("safemode", safeHandler)

    # restrictictions
    bot.ourOnCommand("ban", banHandler)
    bot.ourOnCommand("tban", tbanHandler)
    bot.canDisableCommand("banme", banMeHandler)
    bot.ourOnCommand("unban", unbanHandler)
    bot.ourOnCommand("kick", kickHandler)
    bot.canDisableCommand("kickme", kickMeHandler)
    bot.ourOnCommand("mute", muteHandler)
    bot.ourOnCommand("tmute", tmuteHandler)
    bot.ourOnCommand("unmute", unmuteHandler)

    # information
    bot.canDisableCommand("id", idHandler)
    bot.canDisableCommand("info", infoHandler)
    bot.canDisableCommand("ping", pingHandler)

    # msg deleting
    bot.ourOnCommand("purge", purgeHandler)
    bot.ourOnCommand("del", delHandler)

    # stickers
    bot.canDisableCommand("getsticker", getStickerHandler)
    bot.canDisableCommand("kang", kangHandler)

    # blacklist
    bot.ourOnUpdate(blacklistListener)
    bot.ourOnCommand("addblacklist", addBlacklistHandler)
    bot.ourOnCommand("rmblacklist", rmBlacklistHandler)
    bot.canDisableCommand("getblacklist", getBlacklistHandler)

    # flood
    bot.ourOnUpdate(floodListener)
    bot.ourOnCommand("setflood", setFloodHandler)
    bot.ourOnCommand("clearflood", clearFloodHandler)
    bot.ourOnCommand("getflood", getFloodHandler)

    # notes
    bot.ourOnCommand("save", addNoteHandler)
    bot.canDisableCommand("get", getNoteHandler)
    bot.ourOnCommand("clear", rmNoteHandler)
    bot.canDisableCommand("saved", savedNotesHandler)

    # global restrictions
    bot.ourOnUpdate(grestrictListener)
    bot.ourOnCommand("gban", gbanHandler)
    bot.ourOnCommand("ungban", ungbanHandler)
    bot.ourOnCommand("gmute", gmuteHandler)
    bot.ourOnCommand("ungmute", ungmuteHandler)

    # rules
    bot.ourOnCommand("setrules", setRulesHandler)
    bot.canDisableCommand("rules", getRulesHandler)

    # intro
    bot.canDisableCommand("start", startHandler)
    bot.canDisableCommand("help", helpHandler)
    bot.ourOnUpdate(newUsrListener)
    bot.ourOnCommand("setwelcome", setwelcomeHandler)
    bot.ourOnCommand("clearwelcome", clearWelcomeHandler)

    # memes
    bot.canDisableCommand("owo", owoHandler)
    bot.canDisableCommand("stretch", stretchHandler)
    bot.canDisableCommand("vapor", vaporHandler)
    bot.canDisableCommand("mock", mockHandler)
    bot.canDisableCommand("zalgo", zalgoHandler)

    # disable
    bot.ourOnCommand("disable", disableHandler)
    bot.ourOnCommand("enable", enableHandler)
    bot.ourOnCommand("getdisabled", getDisabledHandler)

    # file logger
    addHandler(fileLog)
    # save redis server when we are done
    addQuitProc(saveRedis)

    echo "Nim TG Bot is Up!"

    bot.poll(timeout=100)

when isMainModule:
    main()
