#!/usr/bin/env python3
"""Contract-check TortoiseGM presets against the server command registry.

This intentionally uses Python stdlib only. It fetches the Chat.cpp registry from
Shyalya's playerbots-integration-gh branch, which is the default source built by
TortoiseWoWServer.

Override TORTOISE_CHAT_CPP_URL to validate against a pinned/custom server source.
"""

from __future__ import annotations

import os
import pathlib
import re
import sys
import urllib.request

CHAT_CPP_URL = os.environ.get(
    "TORTOISE_CHAT_CPP_URL",
    "https://raw.githubusercontent.com/Shyalya/tortoise-wow/"
    "playerbots-integration-gh/src/game/Chat/Chat.cpp",
)
DATA_PATH = pathlib.Path(__file__).resolve().parents[1] / "Data.lua"

SECURITY_LABELS = {
    "SEC_PLAYER": "Player",
    "SEC_OBSERVER": "Observer",
    "SEC_MODERATOR": "Moderator",
    "SEC_GAMEMASTER": "GM",
    "SEC_DEVELOPER": "Developer",
    "SEC_ADMINISTRATOR": "Administrator",
    "SEC_CONSOLE": "Console",
}


def fetch_registry() -> str:
    request = urllib.request.Request(
        CHAT_CPP_URL,
        headers={"User-Agent": "TortoiseGM-contract-test"},
    )
    with urllib.request.urlopen(request, timeout=30) as response:
        return response.read().decode("utf-8", "replace")


def extract_arrays(source: str) -> dict[str, list[tuple[str, str, str]]]:
    arrays: dict[str, list[tuple[str, str, str]]] = {}
    header = re.compile(r"static\s+ChatCommand\s+(\w+)\[\]\s*=\s*\{")

    for match in header.finditer(source):
        name = match.group(1)
        start = match.end()
        depth = 1
        cursor = start
        while cursor < len(source) and depth:
            if source[cursor] == "{":
                depth += 1
            elif source[cursor] == "}":
                depth -= 1
            cursor += 1

        body = source[start : cursor - 1]
        entries: list[tuple[str, str, str]] = []
        for line in body.splitlines():
            entry = re.search(r'\{\s*"([^"]*)"\s*,\s*(SEC_\w+|0)\s*,', line)
            child = re.search(r",\s*(\w+|nullptr)\s*\}\s*,?\s*$", line)
            if entry and child:
                entries.append((entry.group(1), entry.group(2), child.group(1)))
        arrays[name] = entries

    return arrays


def flatten_registry(
    arrays: dict[str, list[tuple[str, str, str]]],
    array_name: str = "commandTable",
    prefix: str = "",
) -> list[tuple[str, str]]:
    routes: list[tuple[str, str]] = []
    for command_name, security, child in arrays.get(array_name, []):
        path = f"{prefix} {command_name}".strip()
        if child != "nullptr" and child in arrays:
            routes.extend(flatten_registry(arrays, child, path))
        elif command_name:
            routes.append((f".{path}", security))
        elif prefix:
            routes.append((f".{prefix}", security))
    return routes


def longest_route(command: str, routes: list[tuple[str, str]]) -> tuple[str, str] | None:
    candidates = [
        route
        for route in routes
        if command == route[0] or command.startswith(route[0] + " ")
    ]
    return max(candidates, key=lambda value: len(value[0]), default=None)


def extract_presets(data: str) -> list[tuple[int, str, str, str]]:
    presets: list[tuple[int, str, str, str]] = []
    for line_number, line in enumerate(data.splitlines(), 1):
        if "command =" not in line or "access =" not in line:
            continue
        command = re.search(r'\bcommand\s*=\s*"([^"]+)"', line)
        access = re.search(r'\baccess\s*=\s*"([^"]+)"', line)
        label = re.search(r'\blabel\s*=\s*"([^"]+)"', line)
        if command and access:
            presets.append(
                (
                    line_number,
                    label.group(1) if label else command.group(1),
                    command.group(1),
                    access.group(1),
                )
            )
    return presets


def extract_lookup_commands(data: str) -> list[tuple[int, str]]:
    results: list[tuple[int, str]] = []
    for line_number, line in enumerate(data.splitlines(), 1):
        for match in re.finditer(r'\blookupCommand\s*=\s*"([^"]+)"', line):
            results.append((line_number, match.group(1)))
    return results


def main() -> int:
    source = fetch_registry()
    arrays = extract_arrays(source)
    routes = flatten_registry(arrays)
    routes.sort(key=lambda value: len(value[0]), reverse=True)

    if not routes:
        print("FAIL: could not parse any server command routes", file=sys.stderr)
        return 1

    data = DATA_PATH.read_text(encoding="utf-8")
    failures: list[str] = []
    ids: set[str] = set()

    # Every catalogue row is addressable independently of its mutable command
    # text and explicitly declares its structured/legacy metadata.
    for line_number, line in enumerate(data.splitlines(), 1):
        if "command =" not in line or "access =" not in line:
            continue
        identifier = re.search(r'\bid\s*=\s*"([^"]+)"', line)
        if not identifier or "arguments =" not in line or "legacyCommands =" not in line:
            failures.append(
                f"Data.lua:{line_number}: preset lacks id/arguments/legacyCommands metadata"
            )
        elif identifier.group(1) in ids:
            failures.append(
                f"Data.lua:{line_number}: duplicate stable id {identifier.group(1)!r}"
            )
        else:
            ids.add(identifier.group(1))

    for line_number, label, command, access in extract_presets(data):
        route = longest_route(command, routes)
        if not route:
            failures.append(
                f"Data.lua:{line_number}: {label}: {command} has no route in server registry"
            )
            continue

        expected_access = SECURITY_LABELS.get(route[1], route[1])
        if access != expected_access:
            failures.append(
                f"Data.lua:{line_number}: {label}: access {access!r} != "
                f"server {expected_access!r} via {route[0]}"
            )

    for line_number, command in extract_lookup_commands(data):
        if not longest_route(command, routes):
            failures.append(
                f"Data.lua:{line_number}: FIND command {command} has no route in server registry"
            )

    if failures:
        print("FAIL: server catalogue contract")
        for failure in failures:
            print(" - " + failure)
        return 1

    print(
        "PASS: server catalogue contract "
        f"({len(extract_presets(data))} presets, "
        f"{len(extract_lookup_commands(data))} FIND mappings, "
        f"{len(routes)} server routes)"
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
