#!/usr/bin/env python3
"""Reproduce the editor-only preview from actual exported Luau geometry.
Runtime removes it before generating the interactive modular world.
"""
import argparse,json
from pathlib import Path
ROOT=Path(__file__).resolve().parent.parent
parser=argparse.ArgumentParser();parser.add_argument('--check',action='store_true');args=parser.parse_args()
objects=json.loads((ROOT/'build/scene.json').read_text());children=[];lookup={}
for p in objects:
 if 'Size' not in p:continue
 node={'Name':p['Name']+'_'+str(p['Id']),'ClassName':'Part','Properties':{'Anchored':True,'TopSurface':'Smooth','BottomSurface':'Smooth','CastShadow':p['CastShadow'],'CanCollide':p['Solid'],'CanTouch':False,'CanQuery':p['Solid'],'Size':p['Size'],'CFrame':p['Position']+p['Rotation'],'Color':p['Color'],'Material':p.get('Material','Material.SmoothPlastic').split('.')[-1],'Transparency':p['Transparency'],'Shape':p['Shape'].split('.')[-1]},'Children':[]}
 lookup[p['Id']]=node;children.append(node)
for p in objects:
 if 'Text' not in p:continue
 if p['Part'] not in lookup:continue
 lookup[p['Part']]['Children'].append({'Name':'PreviewLabel','ClassName':'SurfaceGui','Properties':{'Face':p['Face'].split('.')[-1],'SizingMode':'PixelsPerStud','PixelsPerStud':24},'Children':[{'Name':'Text','ClassName':'TextLabel','Properties':{'Size':{'UDim2':[[1,0],[1,0]]},'BackgroundTransparency':1,'Text':p['Text'],'TextColor3':[.88,.97,.93],'Font':'GothamBold','TextScaled':True,'TextWrapped':True}}]})
asset={'Name':'ScenePreview','ClassName':'Model','Children':children}
text=json.dumps(asset,ensure_ascii=False,separators=(',',':'))+'\n';path=ROOT/'assets/map-preview.model.json'
if args.check:
 assert path.read_text()==text,'Editor map is stale; run python3 scripts/export-scene.py && python3 scripts/generate-preview.py'
 print('PASS: editor map preview matches exported current Luau geometry')
else:
 path.parent.mkdir(exist_ok=True);path.write_text(text);print(f'Generated editor preview: {len(children)} parts')
