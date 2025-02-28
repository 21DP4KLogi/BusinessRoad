import mummy, mummy/routers
export mummy, routers

# Mummy router definition
var router*: Router

# Templates for Jester syntax
template get*(endpoint: string, body: untyped) =
  router.get(endpoint, RequestHandler(proc (request {.inject.}: Request) {.gcsafe.} =
    var headers {.inject.}: HttpHeaders
    body
  ))

template post*(endpoint: string, body: untyped) =
  router.post(endpoint, RequestHandler(proc (request {.inject.}: Request) {.gcsafe.} =
    var headers {.inject.}: HttpHeaders
    body
  ))

template resp*(code: int, body: sink string) = # I don't really know what the 'sink' does, but that is what Mummy uses.
  request.respond(code, headers, body)
  return

template resp*(code: int) =
  request.respond(code, headers)
  return
