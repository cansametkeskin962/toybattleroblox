# Rigli oyuncak FBX'ini "kollar asagi" pozuna sokar, statik Roblox mesh'i olarak export eder.
# Kullanim: blender -b -P tools/roblox_poz.py -- <girdi_SK.fbx> <cikti.fbx>
# Kemikler (UE iskeleti): upperarm_l/r dondurulur (omuz etrafinda). Alt kol/el zincirle gelir.
import bpy, sys, math
from mathutils import Vector, Matrix

args = sys.argv[sys.argv.index("--") + 1:]
girdi, cikti = args[0], args[1]
KOL_ACI = 70.0     # derece, kollar govdenin yanina
ON_ACI = 10.0      # derece, eller hafif onde

bpy.ops.wm.read_factory_settings(use_empty=True)
bpy.ops.import_scene.fbx(filepath=girdi)
sahne = bpy.context.scene
arm = next(o for o in sahne.objects if o.type == 'ARMATURE')
meshler = [o for o in sahne.objects if o.type == 'MESH']

# 1) poz: omuzdan (upperarm) dondur. Armature uzayinda; sol kol +X, sag kol -X
bpy.context.view_layer.objects.active = arm
bpy.ops.object.mode_set(mode='POSE')
for ad, isaret in (("upperarm_l", 1), ("upperarm_r", -1)):
    pb = arm.pose.bones[ad]
    bas = pb.head.copy()
    R = Matrix.Rotation(math.radians(-ON_ACI), 4, 'X') @ Matrix.Rotation(math.radians(KOL_ACI * isaret), 4, 'Y')
    T = Matrix.Translation(bas) @ R @ Matrix.Translation(-bas)
    pb.matrix = T @ pb.matrix
    bpy.context.view_layer.update()
bpy.ops.object.mode_set(mode='OBJECT')

# 2) armature modifier'ini uygula (poz halinde dondur), armature'u sil
for o in meshler:
    bpy.context.view_layer.objects.active = o
    for m in list(o.modifiers):
        if m.type == 'ARMATURE':
            bpy.ops.object.modifier_apply(modifier=m.name)
for o in list(sahne.objects):
    if o.type != 'MESH':
        bpy.data.objects.remove(o, do_unlink=True)
for o in meshler:
    mw = o.matrix_world.copy(); o.parent = None; o.matrix_world = mw
bpy.ops.object.select_all(action='DESELECT')
for o in meshler:
    o.select_set(True)
bpy.context.view_layer.objects.active = meshler[0]
bpy.ops.object.transform_apply(location=True, rotation=True, scale=True)
if len(meshler) > 1:
    bpy.ops.object.join()
obj = bpy.context.view_layer.objects.active

# 3) on yonu bul: goz malzemesinin (yoksa burun/yuz) agirlik merkezi hangi Y tarafinda
def malzeme_merkezi(anahtarlar):
    idxler = [i for i, s in enumerate(obj.material_slots) if s.material and any(a in s.material.name for a in anahtarlar)]
    if not idxler:
        return None
    toplam = Vector(); n = 0
    for p in obj.data.polygons:
        if p.material_index in idxler:
            toplam += obj.matrix_world @ p.center; n += 1
    return toplam / n if n else None
mrk = malzeme_merkezi(("Goz", "Burun", "Yanak"))
govde = sum((obj.matrix_world @ v.co for v in obj.data.vertices), Vector()) / len(obj.data.vertices)
if mrk is None:
    raise SystemExit("yuz malzemesi bulunamadi")
on_y = mrk.y - govde.y
print("YUZ_FARKI_Y", on_y)
if on_y > 0:   # yuz +Y'de ise 180 derece cevir -> -Y
    obj.rotation_euler = (0, 0, math.pi)
    bpy.ops.object.transform_apply(rotation=True)
    print("Z 180 dondurüldü")

# 4) boy 5.5, taban 0, ortala (roblox_fbx.py ile ayni)
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

# Blender -Y (on) -> Roblox -Z: axis_forward='Z' (Blender +Y -> +Z), axis_up='Y'
bpy.ops.export_scene.fbx(filepath=cikti, use_selection=False, object_types={'MESH'},
                         axis_forward='Z', axis_up='Y', apply_unit_scale=True,
                         global_scale=1.0, bake_space_transform=True, add_leaf_bones=False)
print("TAMAM", cikti)
