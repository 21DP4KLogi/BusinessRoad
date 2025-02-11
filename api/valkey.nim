import ready
export ready

let valkey*: RedisPool = newRedisPool(4, "localhost", Port(5003))

