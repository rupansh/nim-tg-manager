# Copyright (C) 2019 Rupansh Sekar
#
# Licensed under the Raphielscape Public License, Version 1.b (the "License");
# you may not use this file except in compliance with the License.
#

import logging
import parsecfg
from strutils import parseInt, replace, split

type BotConfig* = object
    apiKey*, owner*, dumpChannel*, redisIp*: string
    redisPort*: int
    sudos*: seq[int]
    fileLog*: FileLogger

proc loadConfig*(): BotConfig =
    let infodict = loadConfig("config.ini")
    let apiKey = infodict.getSectionValue("tg-api", "API-KEY")
    let owner = infodict.getSectionValue("user", "OWNER_ID")

    var sudos: seq[int]
    if ',' in infodict.getSectionValue("user", "SUDOS"):
        for sudo in infodict.getSectionValue("user", "SUDOS").split(","):
            if ' ' in sudo:
                sudos.add(parseInt(sudo.replace(" ", "")))
            else:
                sudos.add(parseInt(sudo))
    else:
        sudos.add(parseInt(infodict.getSectionValue("user", "SUDOS")))

    let dumpChannel = infodict.getSectionValue("user", "CHANNEL_USER")
    let redisIp = infodict.getSectionValue("redis", "REDIS_IP")
    let redisPort = parseInt(infodict.getSectionValue("redis", "REDIS_PORT"))
    let fileLog = newFileLogger("errors.log", levelThreshold=lvlError)

    return BotConfig(
        apiKey : apiKey,
        owner: owner,
        sudos: sudos,
        dumpChannel: dumpChannel,
        redisIp: redisIp,
        redisPort: redisPort,
        fileLog: fileLog
    )
