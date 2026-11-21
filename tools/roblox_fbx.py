# Oyuncak FBX'lerini Roblox'a uygun hale getirir:
# - her malzeme ayri parca olur, adi "R_RRGGBB" (kod rengi buradan okur, gri kalmaz)
# - ayakta durur (Y yukari), boy ~5.5, taban 0'da, ortada
# Kullanim: blender -b -P tools/roblox_fbx.py -- <girdi.fbx> <cikti.fbx>
import bpy, sys
from mathutils import Vector

args = sys.argv[sys.argv.index("--") + 1:]
girdi, cikti = args[0], args[1]

bpy.ops.wm.read_factory_settings(use_empty=True)
bpy.ops.import_scene.fbx(filepath=girdi)

# armature/bos nesneleri at, sadece mesh kalsin (donusumu uygula)
meshler = [o for o in bpy.context.scene.objects if o.type == 'MESH']
for o in bpy.context.scene.objects:
    o.select_set(False)
for o in meshler:
    for m in list(o.modifiers):
        if m.type == 'ARMATURE':
            o.modifiers.remove(m)
bpy.context.view_layer.objects.active = meshler[0]
for o in meshler:
    o.select_set(True)
    mw = o.matrix_world.copy()
    o.parent = None
    o.matrix_world = mw
bpy.ops.object.transform_apply(location=True, rotation=True, scale=True)
for o in list(bpy.context.scene.objects):
    if o.type != 'MESH':
        bpy.data.objects.remove(o, do_unlink=True)

# tek mesh yap, sonra malzemeye gore ayir
bpy.ops.object.select_all(action='SELECT')
bpy.context.view_layer.objects.active = meshler[0]
if len(meshler) > 1:
    bpy.ops.object.join()
obj = bpy.context.view_layer.objects.active

# boyut: Blender Z yukari; boyu 5.5 yap, tabani 0'a, ortaya al
koseler = [obj.matrix_world @ Vector(c) for c in obj.bound_box]
zmin = min(v.z for v in koseler); zmax = max(v.z for v in koseler)
cx = (min(v.x for v in koseler) + max(v.x for v in koseler)) / 2
cy = (min(v.y for v in koseler) + max(v.y for v in koseler)) / 2
olcek = 5.5 / max(zmax - zmin, 1e-4)
obj.location = (-cx, -cy, -zmin)
bpy.ops.object.transform_apply(location=True)
obj.scale = (olcek, olcek, olcek)
bpy.ops.object.transform_apply(scale=True)

bpy.ops.object.mode_set(mode='EDIT')
bpy.ops.mesh.select_all(action='SELECT')
bpy.ops.mesh.separate(type='MATERIAL')
bpy.ops.object.mode_set(mode='OBJECT')

def renk(mat):
    if mat is None:
        return (0.8, 0.8, 0.8)
    if mat.use_nodes:
        for n in mat.node_tree.nodes:
            if n.type == 'BSDF_PRINCIPLED':
                c = n.inputs['Base Color'].default_value
                return (c[0], c[1], c[2])
    c = mat.diffuse_color
    return (c[0], c[1], c[2])

def srgb(x):
    x = max(0.0, min(1.0, x))
    return x * 12.92 if x <= 0.0031308 else 1.055 * (x ** (1 / 2.4)) - 0.055

for i, o in enumerate([o for o in bpy.context.scene.objects if o.type == 'MESH']):
    mat = o.material_slots[0].material if o.material_slots else None
    r, g, b = (int(round(srgb(v) * 255)) for v in renk(mat))
    o.name = "R_%02X%02X%02X_%d" % (r, g, b, i)
    o.data.name = o.name

# Roblox: Y yukari, -Z ileri
bpy.ops.export_scene.fbx(filepath=cikti, use_selection=False, object_types={'MESH'},
                         axis_forward='-Z', axis_up='Y', apply_unit_scale=True,
                         global_scale=1.0, bake_space_transform=True, add_leaf_bones=False)
print("TAMAM", cikti)
