# Package

version       = "0.1.0"
author        = "21DP4KLogi"
description   = "A Multiplayer Moneymaking Mischief game"
license       = "AGPL-3.0-or-later"
namedBin = {
  "page/main": "brPage",
  "api/main": "brApi",
  "pow/main": "brPow", # Path is determined by ./pow/main.nim.cfg
}.toTable()

# Tasks

task devup, "Start development containers":
  exec "podman-compose -f containers/development.yaml up -d"
  echo "\nDevelopment containers started, use 'nimble devdown' to stop."

task devdown, "Stop development containers":
  exec "podman-compose -f containers/development.yaml down"
  echo "\nDevelopment containers stopped."

task devvalkey, "Enter valkey-cli in dev container":
  exec "podman exec -ti brDev_valkey valkey-cli"

task devpsql, "Enter psql in dev container":
  exec "podman exec -ti brDev_psql psql -U businessman BusinessRoadDev"

task devwipepsql, "Wipe psql database":
  exec "podman exec brDev_psql bash -c \"dropdb -U businessman BusinessRoadDev && createdb -U businessman BusinessRoadDev\""

task devpage, "Start ESBuild in page/ for development":
  exec "(cd page && npm run dev)"

# Dependencies

requires "nim >= 2.0.8"
# API server
requires "mummy"
requires "ready"
requires "norm"
# Frontend
requires "dekao"
# PoW challenge
requires "nimcrypto"
