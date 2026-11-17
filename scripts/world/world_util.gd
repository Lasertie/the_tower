class_name WorldUtil
extends RefCounted

static func material(color: Color) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = color
	return m

## Damier en coordonnées monde (sans UV) : sols d'hôpital, herbe...
static func checker(c1: Color, c2: Color, tile: float) -> StandardMaterial3D:
	var img := Image.create(2, 2, false, Image.FORMAT_RGB8)
	img.set_pixel(0, 0, c1)
	img.set_pixel(1, 1, c1)
	img.set_pixel(1, 0, c2)
	img.set_pixel(0, 1, c2)
	var m := StandardMaterial3D.new()
	m.albedo_texture = ImageTexture.create_from_image(img)
	m.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	m.uv1_triplanar = true
	m.uv1_world_triplanar = true
	m.uv1_scale = Vector3.ONE * (0.5 / tile)
	return m

static func unshaded(color: Color) -> StandardMaterial3D:
	var m := material(color)
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	return m

## Boîte visible, avec collision par défaut.
static func box(parent: Node, size: Vector3, pos: Vector3, color: Color, collide := true,
		mat: Material = null) -> Node3D:
	var mesh := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = size
	mesh.mesh = bm
	mesh.material_override = mat if mat else material(color)
	var root: Node3D = mesh
	if collide:
		var body := StaticBody3D.new()
		var cs := CollisionShape3D.new()
		var bs := BoxShape3D.new()
		bs.size = size
		cs.shape = bs
		body.add_child(cs)
		body.add_child(mesh)
		root = body
	root.position = pos
	parent.add_child(root)
	return root

static func marker(parent: Node, pos: Vector3, color: Color, radius := 0.5) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var sm := SphereMesh.new()
	sm.radius = radius
	sm.height = radius * 2.0
	mi.mesh = sm
	mi.material_override = material(color)
	mi.position = pos
	parent.add_child(mi)
	return mi

## Dalle horizontale (footprint centré sur l'origine) avec un trou rectangulaire optionnel
## (hole en coordonnées x,z). Utilisée pour les sols/plafonds traversés par les escaliers.
static func slab(parent: Node, y_center: float, footprint: Vector2, thickness: float, color: Color,
		hole := Rect2(), collide := true, mat: Material = null) -> void:
	var x0 := -footprint.x * 0.5
	var x1 := footprint.x * 0.5
	var z0 := -footprint.y * 0.5
	var z1 := footprint.y * 0.5
	var rects: Array[Rect2] = []
	if hole.size == Vector2.ZERO:
		rects.append(Rect2(x0, z0, footprint.x, footprint.y))
	else:
		var hx0 := hole.position.x
		var hx1 := hole.end.x
		var hz0 := hole.position.y
		var hz1 := hole.end.y
		rects.append(Rect2(x0, z0, hx0 - x0, footprint.y))
		rects.append(Rect2(hx1, z0, x1 - hx1, footprint.y))
		rects.append(Rect2(hx0, z0, hx1 - hx0, hz0 - z0))
		rects.append(Rect2(hx0, hz1, hx1 - hx0, z1 - hz1))
	for r in rects:
		if r.size.x > 0.01 and r.size.y > 0.01:
			box(parent, Vector3(r.size.x, thickness, r.size.y),
				Vector3(r.position.x + r.size.x * 0.5, y_center, r.position.y + r.size.y * 0.5),
				color, collide, mat)

## Rampe dont la face supérieure relie a (bas) à b (haut). lateral/lift décalent la boîte (rails).
static func ramp(parent: Node, a: Vector3, b: Vector3, width: float, thickness: float, color: Color,
		lateral := 0.0, lift := 0.0, collide := true, mat: Material = null) -> Node3D:
	var d := b - a
	var length := d.length()
	var fwd := d / length
	var right := fwd.cross(Vector3.UP).normalized()
	var up := right.cross(fwd).normalized()
	var center := (a + b) * 0.5 - up * thickness * 0.5 + right * lateral + up * lift
	var holder := Node3D.new()
	holder.transform = Transform3D(Basis(right, up, -fwd), center)
	parent.add_child(holder)
	var size := Vector3(width, thickness, length)
	box(holder, size, Vector3.ZERO, color, collide, mat)
	return holder

## Mur modulaire (modèle Kenney) de a à b, avec une collision unique.
static func wall_line(parent: Node, a: Vector3, b: Vector3, height: float, thickness := 0.4) -> Node3D:
	var holder := Node3D.new()
	parent.add_child(holder)
	var d := b - a
	var length := d.length()
	if length < 0.1:
		return holder
	var n := maxi(1, roundi(length / (height / 1.29)))
	var piece_w := length / n
	var yaw := atan2(-d.z, d.x)
	var dir := d / length
	for i in n:
		var w := Assets.place("wall", height, &"height")
		var natural: float = (w.get_meta("size") as Vector3).x
		w.scale.x = piece_w / maxf(natural, 0.001)
		w.position = a + dir * (piece_w * (i + 0.5))
		w.rotation.y = yaw
		holder.add_child(w)
	var body := StaticBody3D.new()
	var cs := CollisionShape3D.new()
	var bs := BoxShape3D.new()
	bs.size = Vector3(length, height, thickness)
	cs.shape = bs
	body.add_child(cs)
	body.position = a + d * 0.5 + Vector3(0, height * 0.5, 0)
	body.rotation.y = yaw
	holder.add_child(body)
	return holder

## Mur de collision invisible (limites du monde).
static func invisible_wall(parent: Node, size: Vector3, pos: Vector3) -> StaticBody3D:
	var body := StaticBody3D.new()
	var cs := CollisionShape3D.new()
	var bs := BoxShape3D.new()
	bs.size = size
	cs.shape = bs
	body.add_child(cs)
	body.position = pos
	parent.add_child(body)
	return body

## Montagne simplifiée (cône bas-poly), preuve de concept des Bords du monde.
static func mountain(parent: Node, pos: Vector3, radius: float, height: float, color: Color) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var cm := CylinderMesh.new()
	cm.top_radius = 0.0
	cm.bottom_radius = radius
	cm.height = height
	cm.radial_segments = 7
	cm.rings = 1
	mi.mesh = cm
	mi.material_override = material(color)
	mi.position = pos + Vector3(0, height * 0.5, 0)
	parent.add_child(mi)
	return mi

const WATERFALL_SHADER := """
shader_type spatial;
render_mode unshaded, cull_disabled;
uniform vec3 base_color : source_color = vec3(0.55, 0.78, 1.0);
void fragment() {
	float s = sin(UV.x * 160.0 + sin(UV.y * 8.0 + TIME * 2.0)) * 0.5 + 0.5;
	float f = fract(UV.y * 7.0 - TIME * 1.7 + s * 0.35);
	float streak = smoothstep(0.15, 0.85, f);
	ALBEDO = mix(base_color * 0.65, vec3(1.0), streak * 0.85);
	ALPHA = 0.9;
}
"""

## Rideau d'eau qui tombe dans le vide (Bout du monde).
static func waterfall(parent: Node, pos: Vector3, size: Vector2) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var q := QuadMesh.new()
	q.size = size
	mi.mesh = q
	var sh := Shader.new()
	sh.code = WATERFALL_SHADER
	var m := ShaderMaterial.new()
	m.shader = sh
	mi.material_override = m
	mi.position = pos
	parent.add_child(mi)
	return mi

const MIST_SHADER := """
shader_type spatial;
render_mode unshaded, cull_disabled, depth_draw_never;
void fragment() {
	float n = sin(UV.x * 40.0 + TIME * 0.4) * 0.5 + 0.5;
	float a = pow(1.0 - UV.y, 1.6) * (0.55 + 0.35 * n);
	ALBEDO = vec3(0.92, 0.97, 1.0);
	ALPHA = clamp(a, 0.0, 0.9);
}
"""

## Brume d'embruns : une bande blanche qui s'estompe vers le haut (horizon du Bout du monde).
static func mist(parent: Node, pos: Vector3, size: Vector2) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var q := QuadMesh.new()
	q.size = size
	mi.mesh = q
	var sh := Shader.new()
	sh.code = MIST_SHADER
	var m := ShaderMaterial.new()
	m.shader = sh
	mi.material_override = m
	mi.position = pos
	parent.add_child(mi)
	return mi
