# Business Road

A (to-be) Multiplayer Moneymaking Mischief game!

---

## About

This is a pile of code that is expected to conglomerate into a browser-based multiplayer game. Currently in *Early Access* and is missing some minor features, such as the game.

---

## Feature checklist

- [ ] Game
	- [ ] Multiplayer
	- [ ] Moneymaking
	- [ ] Mischief
- [ ] Nice GUI
	- [ ] Color themes (Light, Dark, Gruvbox)
- [ ] Security

---

## Building

### For development

Requires:
- Nim
- Emscripten
- Podman (Docker would probably work if I didn't hardcode it otherwise)
- Node/NPM
- Tmux (Optional)

Aqcuire required containers:
- nginx:stable-alpine-slim
- postgres:alpine
- valkey:alpine

Build the following atleast once to get started:
- `nimble build brPow`
- `nimble run brPage` - This writes files at runtime and then closes
And install the npm packages:
`npm i` while in the `./page` directory

With Tmux, running `./devall.sh` should launch everything in a nice 2x2 terminal grid! Shutting everything down has to be done manually though, as far as I know.

Without Tmux, you need to launch the following:
- The containers, can be done via `nimble devup`
- The API server, `nimble run -d:powNumberAlwaysZero brApi` (that definition makes the PoW challenge always first attempt)
- The script building, `nimble devpage`

Whenever you need to build the frontend: `nimble run brPage`

### For hosting
Uhh, once there is something to host, I will make the Container composing files.

---

## License

GNU Affero General Public License version 3 or later