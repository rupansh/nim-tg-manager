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
  redishandling,
  rules
]
import redis
import telebot, asyncdispatch, logging, options
import std/exitprocs
import sugar

proc main() {.async.} =
    let config = loadConfig()
    let manager = TgManager(
      bot: newTeleBot(config.apiKey),
      config: config,
      db: await redis.openAsync(config.redisIp, config.redisPort.Port)
    )

    let dc = config.dumpChannel

    # management
    manager.ourOnCommand("promote", promoteHandler)
    manager.ourOnCommand("demote", demoteHandler)
    manager.ourOnCommand("pin", pinHandler)
    manager.ourOnCommand("unpin", unpinHandler)
    manager.canDisableCommand("invite", inviteHandler)
    manager.canDisableCommand("admins", adminList)
    manager.ourOnCommand("safemode", safeHandler)

    # restrictictions
    manager.ourOnCommand("ban", banHandler)
    manager.ourOnCommand("tban", tbanHandler)
    manager.canDisableCommand("banme", banMeHandler)
    manager.ourOnCommand("unban", unbanHandler)
    manager.ourOnCommand("kick", kickHandler)
    manager.canDisableCommand("kickme", kickMeHandler)
    manager.ourOnCommand("mute", muteHandler)
    manager.ourOnCommand("tmute", tmuteHandler)
    manager.ourOnCommand("unmute", unmuteHandler)

    # information
    manager.canDisableCommand("id", idHandler)
    manager.canDisableCommand("info", infoHandler)
    manager.canDisableCommand("ping", pingHandler)

    # msg deleting
    manager.ourOnCommand("purge", purgeHandler)
    manager.ourOnCommand("del", delHandler)

    # stickers
    manager.canDisableCommand("getsticker", getStickerHandler)
    manager.canDisableCommand("kang", kangHandler)

    # blacklist
    manager.ourOnUpdate(blacklistListener)
    manager.ourOnCommand("addblacklist", addBlacklistHandler)
    manager.ourOnCommand("rmblacklist", rmBlacklistHandler)
    manager.canDisableCommand("getblacklist", getBlacklistHandler)

    # flood
    manager.ourOnUpdate(floodListener)
    manager.ourOnCommand("setflood", setFloodHandler)
    manager.ourOnCommand("clearflood", clearFloodHandler)
    manager.ourOnCommand("getflood", getFloodHandler)

    # notes
    manager.ourOnCommand("save", addNoteHandler)
    manager.canDisableCommand("get", getNoteHandler)
    manager.ourOnCommand("clear", rmNoteHandler)
    manager.canDisableCommand("saved", savedNotesHandler)

    # global restrictions
    manager.ourOnUpdate(grestrictListener)
    manager.ourOnCommand("gban", gbanHandler)
    manager.ourOnCommand("ungban", ungbanHandler)
    manager.ourOnCommand("gmute", gmuteHandler)
    manager.ourOnCommand("ungmute", ungmuteHandler)

    # rules
    manager.ourOnCommand("setrules", setRulesHandler)
    manager.canDisableCommand("rules", getRulesHandler)

    # intro
    manager.canDisableCommand("start", startHandler)
    manager.canDisableCommand("help", helpHandler)
    manager.ourOnUpdate(newUsrListener)
    manager.ourOnCommand("setwelcome", setwelcomeHandler)
    manager.ourOnCommand("clearwelcome", clearWelcomeHandler)

    # memes
    manager.canDisableCommand("owo", owoHandler)
    manager.canDisableCommand("stretch", stretchHandler)
    manager.canDisableCommand("vapor", vaporHandler)
    manager.canDisableCommand("mock", mockHandler)
    manager.canDisableCommand("zalgo", zalgoHandler)

    # disable
    manager.ourOnCommand("disable", disableHandler)
    manager.ourOnCommand("enable", enableHandler)
    manager.ourOnCommand("getdisabled", getDisabledHandler)

    # file logger
    addHandler(config.fileLog)
    # save redis server when we are done
    addExitProc(() => waitFor manager.db.asSaveRedis())

    echo "Nim TG Bot is Up!"

    await manager.bot.pollAsync(timeout=300)

when isMainModule:
    waitFor main()
