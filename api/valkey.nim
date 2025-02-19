import ready
export ready

let valkeyPool*: RedisPool = newRedisPool(4, "localhost", Port(5003))
let valkeySingle*: RedisConn = newRedisConn("localhost", Port(5003))
