# R15 gruplarina gore boyayip render eder. blender -b -P tools/onizle_r15.py -- <fbx> <png_eki>
import bpy, sys, math
from mathutils import Vector
a = sys.argv[sys.argv.index("--")+1:]
PAL = {'LowerTorso':(.5,.5,.5),'UpperTorso':(.9,.2,.2),'Head':(.95,.9,.2),'LeftUpperArm':(.2,.8,.2),'LeftLowerArm':(.1,.5,.1),'LeftHand':(.7,1,.7),'RightUpperArm':(.2,.4,1),'RightLowerArm':(.1,.2,.7),'RightHand':(.6,.8,1),'LeftUpperLeg':(1,.5,0),'LeftLowerLeg':(.7,.3,0),'LeftFoot':(1,.8,.4),'RightUpperLeg':(.8,.2,.9),'RightLowerLeg':(.5,.1,.6),'RightFoot':(.9,.6,1)}
bpy.ops.wm.read_factory_settings(use_empty=True)
bpy.ops.import_scene.fbx(filepath=a[0], use_manual_orientation=True, axis_forward='Z', axis_up='Y')
sc = bpy.context.scene
sayac = {}
for o in sc.objects:
    if o.type == 'MESH':
        g = o.name.split('__')[0]
        sayac[g] = sayac.get(g, 0) + 1
        o.color = PAL[g] + (1,)
print("GRUPLAR", sayac)
cam = bpy.data.objects.new("c", bpy.data.cameras.new("c")); sc.collection.objects.link(cam)
cam.data.type = 'ORTHO'; cam.data.ortho_scale = 6.5; sc.camera = cam
sc.render.engine = 'BLENDER_WORKBENCH'
sc.display.shading.light = 'STUDIO'; sc.display.shading.color_type = 'OBJECT'
sc.render.resolution_x = sc.render.resolution_y = 512
sc.view_settings.view_transform = 'Standard'
sc.world = bpy.data.worlds.new("w"); sc.world.color = (0.8,0.85,0.9)
cam.location = (0, -20, 2.75); cam.rotation_euler = (math.pi/2,0,0)
sc.render.filepath = a[1] + "_r15.png"
bpy.ops.render.render(write_still=True)
