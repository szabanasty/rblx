#!/usr/bin/env python3
"""Check the exported actual procedural geometry, without pretending to simulate Roblox."""
import json,math
from pathlib import Path
ROOT=Path(__file__).resolve().parent.parent
items=json.loads((ROOT/'build/scene.json').read_text())
parts=[p for p in items if 'Size' in p]
def find(name,parent=None):return next(p for p in parts if p['Name']==name and (not parent or p['Parent']==parent))
def bounds(p):
 r=p['Rotation'];s=p['Size'];pos=p['Position'];half=[sum(abs(r[i*3+j])*s[j]/2 for j in range(3)) for i in range(3)]
 return [pos[i]-half[i] for i in range(3)],[pos[i]+half[i] for i in range(3)]
def contains_x(p,x):lo,hi=bounds(p);return lo[0]<=x<=hi[0]
assert 800<len(parts)<1300,len(parts)
for p in parts:
 assert all(math.isfinite(v) for v in p['Size']+p['Position']+p['Rotation']),p['Name']
 assert all(v>0 for v in p['Size']),p['Name']
water=find('RiverWater');west=find('WestLand');east=find('EastLand');deck=find('Deck','RiversideBridge')
assert bounds(west)[1][0]<=430 and bounds(east)[0][0]>=610
assert bounds(water)[0][0]==430 and bounds(water)[1][0]==610
assert bounds(deck)[0][0]<430 and bounds(deck)[1][0]>610 and deck['Solid']
for x in range(440,601,20):
 assert contains_x(deck,x) and not contains_x(west,x) and not contains_x(east,x),'river crossing requires actual bridge'
arena=find('ArenaPaving');assert arena['Position'][0]==1050 and bounds(arena)[0][0]>=800
assert arena['Position'][0]-520>500,'arena remains well beyond bridge'
for shop in ('Garage','ScooterShop','UpgradeShop','EquipmentShop','CosmeticsShop','FishBuyer'):
 floor=find('Floor',shop);marker=find('Interaction',shop);x=marker['Position'][0];z=marker['Position'][2]
 assert floor['Solid']
 # A normal avatar can pass the centered entrance and continue 24 studs inside.
 for offset in range(0,25,2):
  boxlo=(x-1.4,1,z-offset-1);boxhi=(x+1.4,6,z-offset+1)
  for part in parts:
   if part['Parent']!=shop or not part['Solid']:continue
   lo,hi=bounds(part)
   overlap=all(lo[i]<boxhi[i] and hi[i]>boxlo[i] for i in range(3))
   assert not overlap,(shop,offset,part['Name'])
for model in ('Showroom_kukirin_g2','Showroom_volt_city','Showroom_kukirin_g3','Showroom_volt_dual','Showroom_kukirin_g4'):
 assert sum(p['Parent']==model for p in parts)>=40
assert find('ScooterPickup')['Position'][0]<find('Interaction','Garage')['Position'][0]
print(f'PASS: actual scene geometry — {len(parts)} parts, {sum(p["Solid"] for p in parts)} collidable; river/bridge separation, distant arena, six clear storefront entrances, five detailed scooters')
