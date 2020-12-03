# Copyright (C) 2019 Rupansh Sekar
#
# Licensed under the Raphielscape Public License, Version 1.b (the "License");
# you may not use this file except in compliance with the License.
#

import redis, asyncdispatch


proc asSaveRedis*(db: AsyncRedis) {.async.} =
    try:
        await db.bgsave()
    except RedisError: # bg save in progress
        discard

proc appRedisList*(db: AsyncRedis, key: string, value: string) {.async.} =
    discard await db.rPush(key, value)

proc getRedisList*(db: AsyncRedis, key: string): Future[RedisList] {.async.} =
    {.gcsafe.}: # TODO: Investigate why the compiler is crying here
        return await db.lRange(key, 0, -1)

proc rmRedisList*(db: AsyncRedis, key: string, value: string) {.async.} =
    discard await db.lRem(key, value)

proc setRedisKey*(db: AsyncRedis, key: string, value: string) {.async.} =
    await db.setk(key, value)

proc getRedisKey*(db: AsyncRedis, key: string): Future[string] {.async.} =
    return await db.get(key)

proc clearRedisKey*(db: AsyncRedis, key: string) {.async.} =
    discard await db.del(@[key])