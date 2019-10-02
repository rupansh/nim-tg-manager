# Package

version       = "0.6.1"
author        = "rupansh"
description   = "Telegram group manager"
license       = "RPL-1.b"
srcDir        = "src"
bin           = @["tg_manager"]


# Dependencies

requires "nim >= 0.20.0"
requires "telebot >= 0.6.8", "redis >= 0.3.0", "imageman >= 0.6.3", "regex >= 0.11.2"
