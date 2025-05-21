import std/[os, strutils]
import mummy

let
  DB_HOST* = getEnv("DB_HOST", "localhost:5002")
  DB_USER* = getEnv("DB_USER", "businessman")
  DB_PASS* = getEnv("DB_PASS", "hunter2")
  DB_NAME* = getEnv("DB_NAME", "BusinessRoadDev")
  VK_HOST* = getEnv("VK_HOST", "localhost")
  VK_PORT* = Port(getEnv("VK_PORT", "5003").parseInt)
  API_HOST* = getEnv("API_HOST", "localhost")
  API_PORT* = Port(getEnv("API_PORT", "5001").parseInt)

if not existsEnv("DB_HOST"): putEnv("DB_HOST", "localhost:5002")
if not existsEnv("DB_USER"): putEnv("DB_USER", "businessman")
if not existsEnv("DB_PASS"): putEnv("DB_PASS", "hunter2")
if not existsEnv("DB_NAME"): putEnv("DB_NAME", "BusinessRoadDev")
