#!/usr/bin/env python3
"""Verify the local Rojo protocol tree and optionally its source file watcher.

Requires msgpack (cloud environment only; Roblox gameplay does not need Python).
This is not a Roblox Studio or engine test.
"""
import argparse
from pathlib import Path
import time
import urllib.request
import msgpack

ROOT = Path(__file__).resolve().parent.parent


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--port", type=int, default=34872)
    parser.add_argument("--check-reload", action="store_true")
    args = parser.parse_args()
    base = f"http://127.0.0.1:{args.port}"

    def get(path):
        with urllib.request.urlopen(base + path, timeout=10) as response:
            return msgpack.unpackb(response.read(), raw=False)

    info = get("/api/rojo")
    assert info["projectName"] == "rblx", "Another project owns this port"
    assert info["serverVersion"] == "7.7.1", "Unexpected Rojo version"

    def tree():
        instances = get("/api/read/" + info["rootInstanceId"])["instances"]
        return instances, instances[info["rootInstanceId"]]

    def at(instances, root, path):
        current = root
        for name in path:
            current = next(instances[i] for i in current["Children"] if instances[i]["Name"] == name)
        return current

    instances, root = tree()
    assert root["ClassName"] == "DataModel"
    count = 0
    for source in sorted((ROOT / "src").rglob("*.luau")):
        branch, *parts = source.relative_to(ROOT / "src").parts
        path = {"server": ["ServerScriptService", "Server"], "client": ["StarterPlayer", "StarterPlayerScripts", "Client"], "shared": ["ReplicatedStorage", "Shared"]}[branch]
        if not parts[-1].startswith("init."):
            path += parts[:-1] + [parts[-1].removesuffix(".luau")]
        instance = at(instances, root, path)
        expected_class = "Script" if source.name.endswith(".server.luau") else "LocalScript" if source.name.endswith(".client.luau") else "ModuleScript"
        assert instance["ClassName"] == expected_class, path
        assert instance["Properties"]["Source"]["String"] == source.read_text(), path
        count += 1
    for name in ("Action", "Input", "Snapshot", "Feedback"):
        assert at(instances, root, ["ReplicatedStorage", "Remotes", name])["ClassName"] == "RemoteEvent"
    assert at(instances, root, ["Workspace"])["Properties"]["StreamingEnabled"]["Bool"] is True
    print(f"PASS: live Rojo tree, {count} source files, remotes and streaming")

    if args.check_reload:
        source = ROOT / "src/shared/ProjectInfo.luau"
        original = source.read_text()
        changed = original + "\n-- temporary Rojo watcher verification\n"

        def await_source(expected):
            for _ in range(50):
                instances, root = tree()
                node = at(instances, root, ["ReplicatedStorage", "Shared", "ProjectInfo"])
                if node["Properties"]["Source"]["String"] == expected:
                    return
                time.sleep(0.1)
            raise AssertionError("Rojo file watcher did not apply the source update")

        try:
            source.write_text(changed)
            await_source(changed)
        finally:
            source.write_text(original)
            await_source(original)
        print("PASS: source edit reached Rojo API; original source restored and verified")


if __name__ == "__main__":
    main()
