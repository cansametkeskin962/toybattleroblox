# Export edilmis Roblox FBX'ini onden/yandan render eder. blender -b -P tools/onizle.py -- <fbx> <png_on_eki>
import bpy, sys, math
from mathutils import Vector
a = sys.argv[sys.argv.index("--")+1:]
bpy.ops.wm.read_factory_settings(use_empty=True)
# dosyayi oldugu gibi oku: raw -Z on: forward='Z' ile raw -Z -> Blender -Y
bpy.ops.import_scene.fbx(filepath=a[0], use_manual_orientation=True, axis_forward='Z', axis_up='Y')
sc = bpy.context.scene
for o in sc.objects:
    if o.type == 'MESH':
        h = o.name.split('_')[1]
        o.color = tuple(((int(h[i:i+2],16)/255)**2.2) for i in (0,2,4)) + (1,)
mn = Vector((1e9,)*3); mx = Vector((-1e9,)*3)
for o in sc.objects:
    if o.type == 'MESH':
        for c in o.bound_box:
            w = o.matrix_world @ Vector(c)
            mn = Vector(map(min, mn, w)); mx = Vector(map(max, mx, w))
print("BBOX", tuple(mn), tuple(mx))
cam = bpy.data.objects.new("c", bpy.data.cameras.new("c")); sc.collection.objects.link(cam)
cam.data.type = 'ORTHO'; cam.data.ortho_scale = 6.5; sc.camera = cam
sc.render.engine = 'BLENDER_WORKBENCH'
sc.display.shading.light = 'STUDIO'; sc.display.shading.color_type = 'OBJECT'
sc.render.resolution_x = sc.render.resolution_y = 512
sc.view_settings.view_transform = 'Standard'
sc.world = bpy.data.worlds.new("w"); sc.world.color = (0.8,0.85,0.9)
mid = (mn+mx)/2
for ad, konum, rot in (("on", (mid.x, mid.y-20, mid.z), (math.pi/2,0,0)), ("yan", (mid.x+20, mid.y, mid.z), (math.pi/2,0,math.pi/2))):
    cam.location = konum; cam.rotation_euler = rot
    sc.render.filepath = a[1] + "_" + ad + ".png"
    bpy.ops.render.render(write_still=True)
