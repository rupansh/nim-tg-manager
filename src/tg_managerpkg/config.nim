# Copyright (C) 2019 Rupansh Sekar
#
# Licensed under the Raphielscape Public License, Version 1.b (the "License");
# you may not use this file except in compliance with the License.
#

import logging
import parsecfg
from strutils import parseInt, replace, split


var infodict* = loadConfig("config.ini")
var apiKey* = infodict.getSectionValue("tg-api", "API-KEY")
var owner* = infodict.getSectionValue("user", "OWNER_ID")
var sudos*: seq[int]
if ',' in infodict.getSectionValue("user", "SUDOS"):
    for sudo in infodict.getSectionValue("user", "SUDOS").split(","):
        if ' ' in sudo:
            sudos.add(parseInt(sudo.replace(" ", "")))
        else:
            sudos.add(parseInt(sudo))
else:
    sudos.add(parseInt(infodict.getSectionValue("user", "SUDOS")))
var dumpChannel* = infodict.getSectionValue("user", "CHANNEL_USER")
var redisIp* = infodict.getSectionValue("redis", "REDIS_IP")
var redisPort* = parseInt(infodict.getSectionValue("redis", "REDIS_PORT"))
var cmdList*: seq[string]
var fileLog* = newFileLogger("errors.log", levelThreshold=lvlError)