#!/usr/bin/env python3
"""Blender visual review of geometry exported by export-scene.py. Not a Studio screenshot.
Run: blender -b -t 4 --python scripts/render-scene.py -- city docs/previews/city.png
"""
import json,math,sys
from pathlib import Path
import bpy
from mathutils import Matrix,Vector
ROOT=Path(__file__).resolve().parent.parent
args=sys.argv[sys.argv.index('--')+1:];view,out=args
objects=json.loads((ROOT/'build/scene.json').read_text())
bpy.ops.object.select_all(action='SELECT');bpy.ops.object.delete(use_global=False)
scene=bpy.context.scene;scene.render.engine='CYCLES';scene.cycles.samples=48
scene.cycles.use_denoising=False # This bundled CPU build has no OpenImageDenoise.
scene.render.resolution_x=1400;scene.render.resolution_y=900;scene.render.resolution_percentage=100
scene.world.color=(0.3,0.3,0.3)
scene.view_settings.view_transform='Standard';scene.view_settings.look='Medium High Contrast';scene.view_settings.exposure=0;scene.view_settings.gamma=1
world=bpy.data.worlds.new('Daylight');world.use_nodes=True;world.node_tree.nodes['Background'].inputs[0].default_value=(0.68,0.8,0.9,1);world.node_tree.nodes['Background'].inputs[1].default_value=0.7;scene.world=world
q=Matrix(((1,0,0),(0,0,-1),(0,1,0)))
def position(p):return q@Vector(p)
bpy.ops.mesh.primitive_cube_add(size=1);cube=bpy.context.object.data;temp=bpy.context.object;bpy.data.objects.remove(temp,do_unlink=True)
vertices=[]
for x in [-.5,.5]:
 for i in range(20):vertices.append((x,.5*math.cos(i*math.tau/20),.5*math.sin(i*math.tau/20)))
faces=[tuple(range(19,-1,-1)),tuple(range(20,40))]
for i in range(20):faces.append((i,(i+1)%20,(i+1)%20+20,i+20))
cylinder=bpy.data.meshes.new('NativeXAxisCylinder');cylinder.from_pydata(vertices,[],faces);cylinder.update()
bpy.ops.mesh.primitive_uv_sphere_add(segments=12,ring_count=6,radius=.5);ball=bpy.context.object.data;temp=bpy.context.object;bpy.data.objects.remove(temp,do_unlink=True)
materials={};parts={}
def material(color,kind,alpha):
 key=(*color,kind,alpha)
 if key not in materials:
  mat=bpy.data.materials.new(kind);mat.diffuse_color=(*color,1);mat.use_nodes=True
  bsdf=mat.node_tree.nodes.get('Principled BSDF');bsdf.inputs['Base Color'].default_value=(*color,1)
  bsdf.inputs['Roughness'].default_value=.65 if kind.endswith(('Grass','Concrete','Brick','WoodPlanks')) else .32
  bsdf.inputs['Metallic'].default_value=.5 if 'Metal' in kind else .05
  if kind.endswith('Neon'):bsdf.inputs['Emission Color' if 'Emission Color' in bsdf.inputs else 'Emission'].default_value=(*color,1);bsdf.inputs['Emission Strength'].default_value=.45
  if alpha>0:
   bsdf.inputs['Alpha'].default_value=1-alpha
   if hasattr(mat,'surface_render_method'):mat.surface_render_method='DITHERED'
   elif hasattr(mat,'blend_method'):mat.blend_method='BLEND'
   if hasattr(mat,'use_screen_refraction'):mat.use_screen_refraction=True
  materials[key]=mat
 return materials[key]
for p in objects:
 if 'Size' not in p or p['Transparency']>=.99:continue
 if view=='scooter' and p['Parent']!='Showroom_kukirin_g2':continue
 rot=Matrix((p['Rotation'][0:3],p['Rotation'][3:6],p['Rotation'][6:9]))
 mesh=ball if p['Shape'].endswith('Ball') else cylinder if p['Shape'].endswith('Cylinder') else cube
 obj=bpy.data.objects.new(p['Name'],mesh.copy());bpy.context.collection.objects.link(obj)
 obj.matrix_world=(q@rot).to_4x4();obj.location=position(p['Position']);obj.scale=Vector(p['Size'])
 obj.data.materials.append(material(p['Color'],p.get('Material') or '',p['Transparency']))
 parts[p['Id']]=(p,obj,rot)
font_path=Path('/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf');font=bpy.data.fonts.load(str(font_path)) if font_path.exists() else None
for entry in objects:
 if 'Text' not in entry or entry['Part'] not in parts or entry['Face'].endswith('Top'):continue
 p,obj,rot=parts[entry['Part']];text=entry['Text'];lines=text.splitlines() or ['']
 curve=bpy.data.curves.new('SignText','FONT');curve.body=text;curve.align_x='CENTER';curve.align_y='CENTER';curve.size=min(p['Size'][0]/max(map(len,lines))/.7,p['Size'][1]/len(lines)*.8)
 if font:curve.font=font
 label=bpy.data.objects.new('Sign: '+text,curve);bpy.context.collection.objects.link(label)
 label.matrix_world=(q@rot).to_4x4();label.location=position(Vector(p['Position'])+rot@Vector((0,0,p['Size'][2]/2+.05)))
 label.data.materials.append(material((.9,.96,.94),'Text',0))
bpy.ops.object.light_add(type='SUN',location=(0,0,500));sun=bpy.context.object;sun.data.energy=2.2;sun.rotation_euler=(math.radians(25),math.radians(-20),math.radians(-30));sun.data.angle=math.radians(15)
if view=='city':cam,target,scale=(-365,260,450),(-55,0,-35),660
elif view=='bridge':cam,target,scale=(1600,850,1250),(520,0,0),1700
elif view=='scooter':
 center=next(p['Position'] for p in objects if p.get('Parent')=='Showroom_kukirin_g2' and p.get('Name')=='Chassis')
 cam=(center[0]+7,center[1]+4.5,center[2]+7);target=(center[0],center[1]+1.3,center[2]);scale=8
 bpy.ops.mesh.primitive_plane_add(size=200,location=position((center[0],center[1]-.9,center[2])));bpy.context.object.data.materials.append(material((.11,.15,.19),'Stage',0))
else:raise ValueError(view)
bpy.ops.object.camera_add(location=position(cam));camera=bpy.context.object;camera.rotation_euler=(position(target)-camera.location).to_track_quat('-Z','Y').to_euler();camera.data.clip_end=10000;camera.data.type='ORTHO';camera.data.ortho_scale=scale;scene.camera=camera
output=ROOT/out;output.parent.mkdir(parents=True,exist_ok=True);scene.render.filepath=str(output);bpy.ops.wm.save_as_mainfile(filepath=str(ROOT/'build'/f'{view}.blend'));bpy.ops.render.render(write_still=True)
