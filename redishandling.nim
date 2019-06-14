# Copyright (C) 2019 Rupansh Sekar
#
# Licensed under the Raphielscape Public License, Version 1.b (the "License");
# you may not use this file except in compliance with the License.
#

import config
import redis, asyncdispatch


proc asSaveRedis*() {.async.} =
    let redisClient = await openAsync(redisIp, redisPort.Port)

    await redisClient.bgsave()

proc appRedisList*(key: string, value: string) {.async.} =
    let redisClient = await openAsync(redisIp, redisPort.Port)

    discard await redisClient.rPush(key, value)

    await asSaveRedis()

proc getRedisList*(key: string): Future[RedisList] {.async.} =
    let redisClient = await openAsync(redisIp, redisPort.Port)

    return await redisClient.lRange(key, 0, -1)

proc rmRedisList*(key: string, value: string) {.async.} =
    let redisClient = await openAsync(redisIp, redisPort.Port)

    discard await redisClient.lRem(key, value)

    await asSaveRedis()

proc saveRedis* {.noconv.} =
    let redisClient = open(redisIp, redisPort.Port)
    redisClient.bgsave()