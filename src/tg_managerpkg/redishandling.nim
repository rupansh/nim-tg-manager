# Copyright (C) 2019 Rupansh Sekar
#
# Licensed under the Raphielscape Public License, Version 1.b (the "License");
# you may not use this file except in compliance with the License.
#

import config
import redis, asyncdispatch


proc asSaveRedis*() {.async.} =
    let redisClient = await openAsync(redisIp, redisPort.Port)

    try:
        await redisClient.bgsave()
    except RedisError: # bg save in progress
        discard

proc appRedisList*(key: string, value: string) {.async.} =
    let redisClient = await openAsync(redisIp, redisPort.Port)

    try:
        discard await redisClient.rPush(key, value)
        await asSaveRedis()
    except ReplyError:
        discard

proc getRedisList*(key: string): Future[RedisList] {.async.} =
    let redisClient = await openAsync(redisIp, redisPort.Port)

    return await redisClient.lRange(key, 0, -1)

proc rmRedisList*(key: string, value: string) {.async.} =
    let redisClient = await openAsync(redisIp, redisPort.Port)

    try:
        discard await redisClient.lRem(key, value)
        await asSaveRedis()
    except ReplyError:
        discard

proc setRedisKey*(key: string, value: string) {.async.} =
    let redisClient = await openAsync(redisIp, redisPort.Port)

    try:
        await redisClient.setk(key, value)
        await asSaveRedis()
    except ReplyError:
        discard

proc getRedisKey*(key: string): Future[string] {.async.} =
    let redisClient = await openAsync(redisIp, redisPort.Port)

    return await redisClient.get(key)

proc clearRedisKey*(key: string) {.async.} =
    let redisClient = await openAsync(redisIp, redisPort.Port)

    discard await redisClient.del(@[key])

proc saveRedis* {.noconv.} =
    let redisClient = open(redisIp, redisPort.Port)
    redisClient.bgsave()