import parsecfg
from strutils import parseInt, replace, split
import telebot

var infodict* = loadConfig("config.ini")
var apiKey* = infodict.getSectionValue("tg-api", "API-KEY")
var owner* = infodict.getSectionValue("user", "OWNER_ID")
#[
//TODO
var sudos*: seq[int]
for sudo in infodict.getSectionValue("user", "SUDO").split(","):
    sudos.add(parseInt(sudo.replace(" ", "")))
]#
var allowGroup* = infodict.getSectionValue("user", "GROUP_ID") # useless rightnow