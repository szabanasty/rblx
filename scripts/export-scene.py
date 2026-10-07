#!/usr/bin/env python3
"""Export actual procedural Luau geometry through a minimal API mock for visual review.
This is not Roblox rendering or a physics test. Output can be rendered by render-scene.py.
"""
import subprocess
import argparse
import os
from pathlib import Path
ROOT=Path(__file__).resolve().parent.parent
parser=argparse.ArgumentParser();parser.add_argument('--tools-dir',type=Path,default=Path(os.environ.get('RBLX_TOOLS_DIR','/workspace/.tools')));args=parser.parse_args()
MOCK='''local M = require("../tests/SceneMock")
local world = M.World()
local game, Instance, Vector3, CFrame, Color3, Enum, UDim2, PhysicalProperties = world.Game, world.Instance, M.Vector3, M.CFrame, M.Color3, M.Enum, M.UDim2, M.PhysicalProperties
'''
def load(path,name,prefix=''):
    return f'local {name}=(function()\n{prefix}\n{(ROOT/path).read_text()}\nend)()\n'
code=MOCK+load('src/server/Modules/WorldBuilder.luau','Builder')+load('src/server/Modules/SceneBuilder.luau','Scene','local script={Parent={WorldBuilder="Builder"}}; local require=function() return Builder end')
code+=load('src/server/Modules/CityScene.luau','City')+load('src/server/Modules/IslandScene.luau','Island')+load('src/server/Modules/ScooterFactory.luau','Factory')
code+=load('src/shared/Config/ZoneWorldConfig.luau','WorldConfig')+load('src/shared/Config/ZoneConfig.luau','Zones')+load('src/shared/Config/ScooterConfig.luau','Scooters')+load('src/shared/Modules/RateLimiter.luau','RateLimiter')
code+=load('src/server/Services/ZoneWorldService.luau','WorldService','local modules={SceneBuilder="Scene",CityScene="City",IslandScene="Island",ScooterFactory="Factory"}; local script={Parent={Parent={Modules=modules}}}; local require=function(k) return ({Scene=Scene,City=City,Island=Island,Factory=Factory})[k] end')
code+='WorldService:Init({Config={World=WorldConfig,Zones=Zones,Scooters=Scooters},Services={},RateLimiter=RateLimiter}); WorldService:Start(); M.Export(world)\n'
(ROOT/'build').mkdir(exist_ok=True)
path=ROOT/'build/export-scene.luau';path.write_text(code)
result=subprocess.run([str(args.tools_dir / 'luau/0.741' / ('luau.exe' if os.name == 'nt' else 'luau')),str(path)],cwd=ROOT,check=True,capture_output=True,text=True)
(ROOT/'build/scene.json').write_text(result.stdout)
print('Exported actual world and showroom geometry to build/scene.json (API mock, not Roblox)')
