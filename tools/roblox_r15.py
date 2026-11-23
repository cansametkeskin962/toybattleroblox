# Rigli oyuncak FBX'i -> kollar asagi poz, R15 parcalarina + malzemeye bolunmus statik FBX.
# Nesne adi: <R15Parca>__R_RRGGBB_<n>
# Kullanim: blender -b -P tools/roblox_r15.py -- <girdi_SK.fbx> <cikti.fbx>
import bpy, sys, math, bmesh
from mathutils import Vector, Matrix, kdtree

args = sys.argv[sys.argv.index("--") + 1:]
girdi, cikti = args[0], args[1]
KOL_ACI = 70.0
ON_ACI = 10.0

PARCALAR = ["LowerTorso", "UpperTorso", "Head",
            "LeftUpperArm", "LeftLowerArm", "LeftHand",
            "RightUpperArm", "RightLowerArm", "RightHand",
            "LeftUpperLeg", "LeftLowerLeg", "LeftFoot",
            "RightUpperLeg", "RightLowerLeg", "RightFoot"]

def kemik_parca(ad):
    s = ""
    if ad.endswith("_l"): s = "Left"
    elif ad.endswith("_r"): s = "Right"
    b = ad[:-2] if s else ad
    if b == "upperarm": return s + "UpperArm"
    if b == "lowerarm": return s + "LowerArm"
    if b == "hand" or b == "weapon" or b.startswith(("thumb", "index", "middle", "ring", "pinky")):
        return s + "Hand"
    if b == "clavicle": return "UpperTorso"
    if b == "thigh": return s + "UpperLeg"
    if b == "calf": return s + "LowerLeg"
    if b in ("foot", "ball"): return s + "Foot"
    if b.startswith("head"): return "Head"
    if b.startswith(("spine", "neck")): return "UpperTorso"
    return "LowerTorso"   # pelvis, root, ik_*, bilinmeyen

bpy.ops.wm.read_factory_settings(use_empty=True)
bpy.ops.import_scene.fbx(filepath=girdi)
sahne = bpy.context.scene
arm = next(o for o in sahne.objects if o.type == 'ARMATURE')
meshler = [o for o in sahne.objects if o.type == 'MESH']

# 0) her yuz icin R15 parcasi: vertex'in en agir kemigi -> yuzde cogunluk (apply'dan ONCE)
for o in meshler:
    me = o.data
    vg_ad = {g.index: g.name for g in o.vertex_groups}
    vpar = []
    for v in me.vertices:
        if v.groups:
            g = max(v.groups, key=lambda x: x.weight)
            vpar.append(PARCALAR.index(kemik_parca(vg_ad[g.group])))
        else:
            vpar.append(-1)
    fpar = []
    for p in me.polygons:
        sayac = {}
        for vi in p.vertices:
            if vpar[vi] >= 0: sayac[vpar[vi]] = sayac.get(vpar[vi], 0) + 1
        fpar.append(max(sayac, key=sayac.get) if sayac else -1)
    # agirliksiz yuzler: ada cogunlugu, yoksa en yakin agirlikli yuz
    parent = list(range(len(me.polygons)))
    def bul(i):
        while parent[i] != i:
            parent[i] = parent[parent[i]]; i = parent[i]
        return i
    vyuz = {}
    for p in me.polygons:
        for vi in p.vertices:
            if vi in vyuz: parent[bul(p.index)] = bul(vyuz[vi])
            else: vyuz[vi] = p.index
    ada = {}
    for p in me.polygons:
        if fpar[p.index] >= 0:
            d = ada.setdefault(bul(p.index), {}); d[fpar[p.index]] = d.get(fpar[p.index], 0) + 1
    kd = kdtree.KDTree(len(me.polygons))
    for p in me.polygons: kd.insert(p.center, p.index)
    kd.balance()
    sey = 0
    for p in me.polygons:
        if fpar[p.index] < 0:
            d = ada.get(bul(p.index))
            if d: fpar[p.index] = max(d, key=d.get)
            else:
                for co, idx, dist in kd.find_n(p.center, 400):
                    if fpar[idx] >= 0 and bul(idx) != bul(p.index):
                        fpar[p.index] = fpar[idx]; break
            sey += 1
    print("AGIRLIKSIZ_YUZ", sey, "/", len(me.polygons))
    at = me.attributes.new("r15", 'INT', 'FACE')
    at.data.foreach_set("value", [max(f, 0) for f in fpar])

# 1) poz
bpy.context.view_layer.objects.active = arm
bpy.ops.object.mode_set(mode='POSE')
for ad, isaret in (("upperarm_l", 1), ("upperarm_r", -1)):
    pb = arm.pose.bones[ad]
    bas = pb.head.copy()
    R = Matrix.Rotation(math.radians(-ON_ACI), 4, 'X') @ Matrix.Rotation(math.radians(KOL_ACI * isaret), 4, 'Y')
    pb.matrix = Matrix.Translation(bas) @ R @ Matrix.Translation(-bas) @ pb.matrix
    bpy.context.view_layer.update()
bpy.ops.object.mode_set(mode='OBJECT')

# 2) modifier uygula, armature sil
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
for o in meshler: o.select_set(True)
bpy.context.view_layer.objects.active = meshler[0]
bpy.ops.object.transform_apply(location=True, rotation=True, scale=True)
if len(meshler) > 1: bpy.ops.object.join()
obj = bpy.context.view_layer.objects.active

# 3) on yonu
idxler = [i for i, s in enumerate(obj.material_slots) if s.material and any(a in s.material.name for a in ("Goz", "Burun", "Yanak"))]
toplam = Vector(); n = 0
for p in obj.data.polygons:
    if p.material_index in idxler:
        toplam += obj.matrix_world @ p.center; n += 1
govde = sum((obj.matrix_world @ v.co for v in obj.data.vertices), Vector()) / len(obj.data.vertices)
if n == 0: raise SystemExit("yuz malzemesi yok")
if (toplam / n).y - govde.y > 0:
    obj.rotation_euler = (0, 0, math.pi)
    bpy.ops.object.transform_apply(rotation=True)

# 4) boy 5.5, taban 0, ortala
koseler = [obj.matrix_world @ Vector(c) for c in obj.bound_box]
zmin = min(v.z for v in koseler); zmax = max(v.z for v in koseler)
cx = (min(v.x for v in koseler) + max(v.x for v in koseler)) / 2
cy = (min(v.y for v in koseler) + max(v.y for v in koseler)) / 2
olcek = 5.5 / max(zmax - zmin, 1e-4)
obj.location = (-cx, -cy, -zmin)
bpy.ops.object.transform_apply(location=True)
obj.scale = (olcek, olcek, olcek)
bpy.ops.object.transform_apply(scale=True)

# 5) (R15 parcasi, malzeme) ciftlerine gore yuz bazinda ayir
def renk(mat):
    if mat is None: return (0.8, 0.8, 0.8)
    if mat.use_nodes:
        for nd in mat.node_tree.nodes:
            if nd.type == 'BSDF_PRINCIPLED':
                c = nd.inputs['Base Color'].default_value
                return (c[0], c[1], c[2])
    c = mat.diffuse_color
    return (c[0], c[1], c[2])
def srgb(x):
    x = max(0.0, min(1.0, x))
    return x * 12.92 if x <= 0.0031308 else 1.055 * (x ** (1 / 2.4)) - 0.055

mats = [s.material for s in obj.material_slots]
rv = obj.data.attributes["r15"].data
ciftler = sorted({(rv[p.index].value, p.material_index) for p in obj.data.polygons})
ana = obj
sayac = 0
for (pi, mi) in ciftler:
    bpy.ops.object.mode_set(mode='OBJECT')
    bpy.ops.object.select_all(action='DESELECT')
    ana.select_set(True); bpy.context.view_layer.objects.active = ana
    bpy.ops.object.mode_set(mode='EDIT')
    bm = bmesh.from_edit_mesh(ana.data)
    lay = bm.faces.layers.int.get("r15")
    for f in bm.faces: f.select_set(False)
    secili = 0
    for f in bm.faces:
        if f[lay] == pi and f.material_index == mi:
            f.select_set(True); secili += 1
    bm.select_flush_mode(); bmesh.update_edit_mesh(ana.data)
    if secili == len(bm.faces):   # son kalan grup
        bpy.ops.object.mode_set(mode='OBJECT')
        yeni = ana
    else:
        bpy.ops.mesh.separate(type='SELECTED')
        bpy.ops.object.mode_set(mode='OBJECT')
        yeni = [o for o in bpy.context.selected_objects if o != ana][0]
    mat = mats[mi] if mi < len(mats) else None
    r, g, b = (int(round(srgb(v) * 255)) for v in renk(mat))
    yeni.name = "%s__R_%02X%02X%02X_%d" % (PARCALAR[pi], r, g, b, sayac)
    yeni.data.name = yeni.name
    sayac += 1
print("PARCA_SAYISI", sayac)
for o in bpy.context.scene.objects:
    if o.type == 'MESH' and "r15" in o.data.attributes:
        o.data.attributes.remove(o.data.attributes["r15"])

bpy.ops.export_scene.fbx(filepath=cikti, use_selection=False, object_types={'MESH'},
                         axis_forward='Z', axis_up='Y', apply_unit_scale=True,
                         global_scale=1.0, bake_space_transform=True, add_leaf_bones=False)
print("TAMAM", cikti)
