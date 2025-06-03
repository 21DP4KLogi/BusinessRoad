# Business Road

A (to-be) Multiplayer Moneymaking Mischief game!

---

## About

This is a pile of code that is expected to conglomerate into a browser-based multiplayer game. Currently in *Early Access* and is missing some minor features, such as the game.

---

## Feature checklist

- [ ] Game
	- [ ] Multiplayer
	- [x] Moneymaking
	- [ ] Mischief
- [x] ~Nice~ GUI
	- [x] Color themes (Light, Dark, Gruvbox)
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

Acquire required containers from docker.io:
- nginx:stable-alpine-slim
- postgres:alpine
- valkey:alpine

Build the following atleast once to get started:
- `nimble build brPow`
- `nimble run brPage` - This writes the required files at runtime and then closes

And install the npm packages:
`npm i` while in the `./page` directory

With Tmux, running `./devall.sh` should launch everything in a nice 2x2 terminal grid! Shutting everything down has to be done manually though, as far as I know.

Without Tmux, you need to launch the following:
- The containers, can be done via `nimble devup`
- The API server, `nimble run -d:powNumberAlwaysZero brApi` (that definition makes the PoW challenge always first attempt)
- The script building, `nimble devpage`

Whenever you need to build the frontend: `nimble run brPage`

### For hosting

Requires
- Podman or Docker

Before the containers can run, an .env file needs to be created in `containers/`, the same directory as the compose file.
Take example from `containers/template.env`, infact, if you don't forward the postgres database, I'm pretty sure the data is irrelevant and you can just rename `template.env` to `.env` and just use it as is.

If Podman does not automatically pull images from docker.io, you can download them manually (all from docker.io):
- nimlang/nim:2.0.8-alpine
- nimlang/nim:2.0.8-regular (Needed for one build stage that the alpine one didn't work right with)
- \_/node:22-alpine
- \_/nginx:stable-alpine-slim
- \_/postgres:alpine
- \_/valkey:alpine

The compose file used here will be `containers/release.yaml`, the commands assume you are in the project root directory (where this README is).

`[program]` means either `podman-compose` or `docker compose`.

Build the containers:
`[program] -f containers/release.yaml build`

Run them (should also build them if not already built):
`[program] -f containers/release.yaml up -d`

Shut them down:
`[program] -f containers/release.yaml down`

Unless intended to be used only via localhost, this system is expected to be run behind a reverse proxy
(in addition to the one use internally) -
it is configured to run on port 5000 and does not provide HTTPS itself.

NOTE - some of the cached images during the build process might be quite large, use `[program] images` to view all images and `[program] image rm [id of unneeded image]` to remove them.

---

## License

GNU Affero General Public License version 3 or later
