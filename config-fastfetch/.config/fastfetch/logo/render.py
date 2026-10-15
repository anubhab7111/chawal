"""Render the 3D Arch logo turntable used by fastfetch.

Run headless (about 5 minutes on an RTX 3050 with OptiX):
    blender -b --factory-startup --python render.py -- OUT_DIR [FRAME ...]
    ./make-assets.sh OUT_DIR

With no FRAME arguments it renders the whole loop (frames 0..99, one full
turn) plus frame 100, which should match frame 0 (the seam check). Frames
are RGBA PNGs named NNN.png; make-assets.sh turns them into arch-spin.webp
and arch-front.png.
"""
import math
import os
import sys

import bpy

SVG = "/usr/share/pixmaps/archlinux-logo.svg"
STUDIO = os.path.join(bpy.utils.system_resource("DATAFILES"), "studiolights", "world", "studio.exr")
FRAMES = 100                         # 4 s at 25 fps
SIZE = 512                           # rendered at 2x the terminal box, then downscaled
ARCH_BLUE = (0.0086, 0.2918, 0.6376)  # #1793d1, converted to linear

args = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else []
out_dir = args[0] if args else os.path.join(os.getcwd(), "frames")
frames = [int(a) for a in args[1:]] or list(range(FRAMES + 1))
os.makedirs(out_dir, exist_ok=True)

bpy.ops.wm.read_factory_settings(use_empty=True)
scene = bpy.context.scene

# --- Model: the official logo outline, extruded and bevelled -----------------
bpy.ops.import_curve.svg(filepath=SVG)
curves = [o for o in scene.objects if o.type == "CURVE"]
logo = max(curves, key=lambda o: o.dimensions.x * o.dimensions.y)
for o in curves:
    if o is not logo:
        bpy.data.objects.remove(o)

bpy.ops.object.select_all(action="DESELECT")
logo.select_set(True)
bpy.context.view_layer.objects.active = logo
scale = 2.0 / max(logo.dimensions.x, logo.dimensions.y)   # ~2 units tall
logo.scale = (scale, scale, scale)
# properties=False keeps the curve point radii at 1, so the bevel isn't scaled up too.
bpy.ops.object.transform_apply(location=False, rotation=False, scale=True, properties=False)

curve = logo.data
curve.dimensions = "2D"
curve.fill_mode = "BOTH"
curve.extrude = 0.11
curve.bevel_depth = 0.025
curve.bevel_resolution = 5
curve.resolution_u = 32
bpy.ops.object.convert(target="MESH")
logo = bpy.context.view_layer.objects.active

# A 2D curve can't take a rotation, so stand it upright (facing -Y) as a mesh.
logo.rotation_euler = (math.radians(90), 0, 0)
bpy.ops.object.transform_apply(location=False, rotation=True, scale=False)
bpy.ops.object.origin_set(type="ORIGIN_GEOMETRY", center="BOUNDS")
logo.location = (0, 0, 0)
bpy.ops.object.shade_smooth_by_angle(angle=math.radians(35))

# --- Material: glossy lacquered Arch blue ------------------------------------
mat = bpy.data.materials.new("ArchBlue")
mat.use_nodes = True
bsdf = mat.node_tree.nodes["Principled BSDF"]
bsdf.inputs["Base Color"].default_value = (*ARCH_BLUE, 1.0)
bsdf.inputs["Roughness"].default_value = 0.22
bsdf.inputs["Coat Weight"].default_value = 0.8
bsdf.inputs["Coat Roughness"].default_value = 0.04
logo.data.materials.append(mat)

# --- Spin: linear in the frame number, so the loop has no ease at the seam ---
driver = logo.driver_add("rotation_euler", 2).driver
driver.type = "SCRIPTED"
driver.expression = f"frame / {FRAMES} * 2 * pi"

# --- Lighting: studio HDRI for reflections, plus key and rim lights ----------
world = bpy.data.worlds.new("Studio")
scene.world = world
world.use_nodes = True
env = world.node_tree.nodes.new("ShaderNodeTexEnvironment")
env.image = bpy.data.images.load(STUDIO)
bg = world.node_tree.nodes["Background"]
bg.inputs["Strength"].default_value = 0.35
world.node_tree.links.new(env.outputs["Color"], bg.inputs["Color"])


def area_light(name, energy, size, location, color=(1, 1, 1)):
    light = bpy.data.lights.new(name, "AREA")
    light.energy = energy
    light.size = size
    light.color = color
    obj = bpy.data.objects.new(name, light)
    obj.location = location
    track = obj.constraints.new("TRACK_TO")
    track.target = logo
    scene.collection.objects.link(obj)


area_light("Key", 220, 1.5, (-2.5, -3.5, 2.8))
area_light("Fill", 40, 4.0, (4.0, -3.0, 0.0))
area_light("Rim", 500, 1.5, (0.5, 4.0, 2.5), color=(0.75, 0.88, 1.0))

# --- Camera: long lens, framed so the logo never clips while it turns --------
cam_data = bpy.data.cameras.new("Camera")
cam_data.lens = 85
cam = bpy.data.objects.new("Camera", cam_data)
scene.collection.objects.link(cam)
cam.location = (0, -5.9, 0)                   # logo ~85% of the frame width face-on
cam.rotation_euler = (math.radians(90), 0, 0)
scene.camera = cam

# --- Render settings ---------------------------------------------------------
scene.render.engine = "CYCLES"
prefs = bpy.context.preferences.addons["cycles"].preferences
prefs.compute_device_type = "OPTIX"
prefs.refresh_devices()
for dev in prefs.devices:
    dev.use = dev.type == "OPTIX"
scene.cycles.device = "GPU"
print("RENDER_DEVICES", scene.cycles.device, [(d.name, d.type) for d in prefs.devices if d.use])

scene.cycles.samples = 96
scene.cycles.use_denoising = True
scene.cycles.seed = 7
scene.render.resolution_x = SIZE
scene.render.resolution_y = SIZE
scene.render.film_transparent = True
scene.view_settings.view_transform = "Standard"
scene.view_settings.look = "None"
scene.render.image_settings.file_format = "PNG"
scene.render.image_settings.color_mode = "RGBA"

bpy.context.view_layer.update()
print("MODEL", logo.name, "dims", tuple(round(v, 3) for v in logo.dimensions),
      "loc", tuple(round(v, 3) for v in logo.location), "camera", tuple(cam.location))

for f in frames:
    scene.frame_set(f)
    scene.render.filepath = os.path.join(out_dir, f"{f:03d}.png")
    bpy.ops.render.render(write_still=True)
    print("RENDERED", f, scene.render.filepath)
