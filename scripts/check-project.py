#!/usr/bin/env python3
"""Run the actual Luau sources against deterministic mocks, Rojo and Roblox types."""
import argparse
import json
import os
from pathlib import Path
import subprocess
import sys
import xml.etree.ElementTree as ET

ROOT = Path(__file__).resolve().parent.parent


def run(command):
    print("Running:", " ".join(map(str, command)), flush=True)
    subprocess.run(list(map(str, command)), cwd=ROOT, check=True)


def wrapped(path, parameters, name="loadService"):
    return f"local function {name}({parameters})\n{(ROOT / path).read_text()}\nend\n"


def spec(path, arguments):
    return f"local runSpec = (function()\n{(ROOT / path).read_text()}\nend)()\nrunSpec({arguments})\n"


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--tools-dir", type=Path, default=Path(os.environ.get("RBLX_TOOLS_DIR", "/workspace/.tools")))
    args = parser.parse_args()
    ext = ".exe" if os.name == "nt" else ""
    rojo = args.tools_dir / "rojo/7.7.1" / ("rojo" + ext)
    luau = args.tools_dir / "luau/0.741" / ("luau" + ext)
    compiler = args.tools_dir / "luau/0.741" / ("luau-compile" + ext)
    analyzer = args.tools_dir / "luau-lsp/1.70.1" / ("luau-lsp" + ext)
    definitions = args.tools_dir / "luau-lsp/1.70.1/globalTypes.d.luau"
    for executable in (rojo, luau, compiler, analyzer, definitions):
        if not executable.is_file():
            parser.error(f"Missing {executable}; on Linux x86_64 run bash scripts/install-tools.sh first")
    build = ROOT / "build"
    generated = ROOT / "tests/.generated"
    build.mkdir(exist_ok=True)
    generated.mkdir(parents=True, exist_ok=True)
    sources = sorted(str(p.relative_to(ROOT)) for p in (ROOT / "src").rglob("*.luau"))
    assert sources, "No Luau sources"
    run([compiler, "--null", *sources])
    run([rojo, "build", "default.project.json", "--output", "build/rblx.rbxlx"])
    run([rojo, "sourcemap", "default.project.json", "--output", "build/sourcemap.json"])
    run([analyzer, "analyze", f"--definitions={definitions}", "--sourcemap=build/sourcemap.json", "--platform=roblox", "src"])
    document = ET.parse(build / "rblx.rbxlx").getroot()
    def child(element, name):
        return next(item for item in element.findall("Item") if item.find('./Properties/string[@name="Name"]').text == name)
    expected = {
        ("ServerScriptService", "Server"): ("Script", "src/server/init.server.luau"),
        ("StarterPlayer", "StarterPlayerScripts", "Client"): ("LocalScript", "src/client/init.client.luau"),
        ("ReplicatedStorage", "Shared", "Modules", "ProfileSchema"): ("ModuleScript", "src/shared/Modules/ProfileSchema.luau"),
    }
    for path, (class_name, source_path) in expected.items():
        current = document
        for name in path:
            current = child(current, name)
        assert current.attrib["class"] == class_name, path
        assert current.find('./Properties/*[@name="Source"]').text == (ROOT / source_path).read_text(), path
    for source_path in sources:
        relative = Path(source_path).relative_to("src")
        branch, *parts = relative.parts
        path = {"server": ["ServerScriptService", "Server"], "client": ["StarterPlayer", "StarterPlayerScripts", "Client"], "shared": ["ReplicatedStorage", "Shared"]}[branch]
        if parts[-1] not in ("init.server.luau", "init.client.luau"):
            path += parts[:-1] + [parts[-1].removesuffix(".luau")]
        current = document
        for name in path:
            current = child(current, name)
        expected_class = "Script" if source_path.endswith(".server.luau") else "LocalScript" if source_path.endswith(".client.luau") else "ModuleScript"
        assert current.attrib["class"] == expected_class, source_path
        assert current.find('./Properties/*[@name="Source"]').text == (ROOT / source_path).read_text(), source_path
    remotes = child(child(document, "ReplicatedStorage"), "Remotes")
    for name in ("Action", "Input", "Snapshot", "Feedback"):
        assert child(remotes, name).attrib["class"] == "RemoteEvent", name
    workspace = child(document, "Workspace")
    assert workspace.find('./Properties/bool[@name="StreamingEnabled"]').text == "true"
    map_folder = child(workspace, "Map")
    for name in ("SafeZone", "CombatZone", "FishingArea", "Roads", "Garage", "Shops", "Buildings", "Cover"):
        folder = child(map_folder, name)
        assert folder.attrib["class"] == "Folder" and not folder.findall("Item"), name
    preview = child(map_folder, "ScenePreview")
    preview_source = json.loads((ROOT / "assets/map-preview.model.json").read_text())
    assert len(preview.findall("Item")) == len(preview_source["Children"])
    for expected_part in preview_source["Children"]:
        part = child(preview, expected_part["Name"])
        assert part.attrib["class"] == "Part"
        assert part.find('./Properties/bool[@name="Anchored"]').text == "true"
        cf = part.find('./Properties/CoordinateFrame[@name="CFrame"]')
        assert all(abs(float(cf.find(axis).text) - value) < 0.001 for axis, value in zip(("X", "Y", "Z"), expected_part["Properties"]["CFrame"][:3]))
    storage = child(document, "ServerStorage")
    for name in ("ScooterModels", "EquipmentTemplates"):
        folder = child(storage, name)
        assert folder.attrib["class"] == "Folder" and not folder.findall("Item"), name
    print(f"Rojo structure verified; {len(sources)} source files compiled and type checked", flush=True)
    imports = "".join(f'local {name} = require("../../src/shared/{path}")\n' for name, path in {
        "StateRules": "Modules/StateRules", "ZoneRules": "Modules/ZoneRules", "SquadStore": "Modules/SquadStore", "FishingRules": "Modules/FishingRules",
        "EconomyConfig": "Config/EconomyConfig", "ZoneWorldConfig": "Config/ZoneWorldConfig",
        "Schema": "Modules/ProfileSchema", "Progression": "Modules/Progression",
        "Validation": "Modules/Validation", "RateLimiter": "Modules/RateLimiter",
        "GameConfig": "Config/GameConfig", "LevelConfig": "Config/LevelConfig",
        "ScooterConfig": "Config/ScooterConfig", "RewardConfig": "Config/RewardConfig",
        "WorldConfig": "Config/WorldConfig", "RoadConfig": "Config/RoadConfig",
        "QuestConfig": "Config/QuestConfig", "UpgradeConfig": "Config/UpgradeConfig",
        "Stats": "Modules/ScooterStats", "Layout": "Modules/WorldLayout",
        "CombatConfig": "Config/CombatConfig", "EquipmentConfig": "Config/EquipmentConfig",
        "FishingConfig": "Config/FishingConfig", "PvPRewardConfig": "Config/PvPRewardConfig", "ZoneConfig": "Config/ZoneConfig",
    }.items())
    suites = {
        "scooter-pose": wrapped("src/server/Modules/ScooterPose.luau", "Instance, Enum") + spec("tests/scooter-pose.spec.luau", "loadService"),
        "scooter-mount": wrapped("src/server/Modules/ScooterMount.luau", "game, CFrame, RaycastParams, Enum") + spec("tests/scooter-mount.spec.luau", "loadService"),
        "zone-world": wrapped("src/server/Services/MovementService.luau", "game, Vector3, CFrame, RaycastParams, Enum, os, warn", "loadMovement")
            + wrapped("src/server/Services/ObjectiveService.luau", "game, Vector3, os", "loadObjective")
            + spec("tests/zone-world.spec.luau", "loadMovement, loadObjective, GameConfig, ZoneWorldConfig, Validation"),
        "zone-gameplay": wrapped("src/server/Services/EquipmentService.luau", "game, os", "loadEquipment")
            + wrapped("src/server/Services/CombatService.luau", "game, Random, Vector3, RaycastParams, Enum, os", "loadCombat")
            + wrapped("src/server/Services/PvPRewardService.luau", "game, os", "loadRewards")
            + wrapped("src/server/Services/ReviveService.luau", "game, Vector3, RaycastParams, Enum, os", "loadRevive")
            + spec("tests/zone-gameplay.spec.luau", "loadEquipment, loadCombat, loadRewards, loadRevive, StateRules, Schema, GameConfig, CombatConfig, EquipmentConfig, PvPRewardConfig"),
        "zone-fishing": wrapped("src/server/Services/FishingService.luau", "game, Random, os")
            + spec("tests/zone-fishing.spec.luau", "loadService, Schema, GameConfig, FishingConfig, FishingRules"),
        "zone-rules": spec("tests/zone-rules.spec.luau", "StateRules, ZoneRules, SquadStore, FishingRules, CombatConfig, ZoneConfig, FishingConfig, Validation"),
        "zone-economy": wrapped("src/server/Services/EconomyService.luau", "game, Instance") + spec("tests/zone-economy.spec.luau", "loadService, Schema, GameConfig, RewardConfig, LevelConfig, EconomyConfig, Progression"),
        "shared": spec("tests/shared.spec.luau", "Progression, Schema, Validation, RateLimiter, LevelConfig, GameConfig"),
        "player-data": wrapped("src/server/Services/PlayerDataService.luau", "game, task, warn, os") + spec("tests/player-data.spec.luau", "loadService"),
        "economy": wrapped("src/server/Services/EconomyService.luau", "game, Instance") + spec("tests/economy.spec.luau", "loadService, Progression, RewardConfig, LevelConfig"),
        "network": wrapped("src/server/Services/NetworkService.luau", "game, os, warn") + spec("tests/network.spec.luau", "loadService, Validation, RateLimiter, GameConfig"),
        "snapshot": wrapped("src/server/Services/SnapshotService.luau", "game") + spec("tests/snapshot.spec.luau", "loadService, Schema, Progression, GameConfig, ScooterConfig, LevelConfig"),
        "input": wrapped("src/client/Controllers/InputController.luau", "game, Enum, task, require") + spec("tests/input.spec.luau", "loadService"),
        "shop": wrapped("src/server/Services/ShopService.luau", "") + spec("tests/shop.spec.luau", "loadService, Schema, GameConfig, ScooterConfig, UpgradeConfig, Stats"),
        "quest": wrapped("src/server/Services/QuestService.luau", "game, os") + spec("tests/quest.spec.luau", "loadService, Schema, GameConfig, QuestConfig, WorldConfig"),
        "world-stats": spec("tests/world-stats.spec.luau", "Layout, Stats, WorldConfig, RoadConfig, ScooterConfig, UpgradeConfig"),
        "foundation": wrapped("src/server/Services/SnapshotService.luau", "game") + spec("tests/foundation.spec.luau", "loadService, Schema, Progression, GameConfig, ScooterConfig, LevelConfig, {Combat = CombatConfig, Equipment = EquipmentConfig, Fishing = FishingConfig, PvPRewards = PvPRewardConfig, Zones = ZoneConfig}"),
        "player-state": wrapped("src/server/Services/PlayerStateService.luau", "game, task") + spec("tests/player-state.spec.luau", "loadService"),
    }
    for name, code in suites.items():
        target = generated / (name + ".luau")
        target.write_text(imports + code)
        run([luau, str(target.relative_to(ROOT))])
    run([sys.executable, "scripts/export-scene.py", str("--tools-dir"), args.tools_dir])
    run([sys.executable, "scripts/check-scene.py"])
    run([sys.executable, "scripts/generate-preview.py", "--check"])
    print(f"PASS: {len(suites)} deterministic Luau suites. Roblox Studio gameplay/physics are separate manual tests.", flush=True)


if __name__ == "__main__":
    main()
