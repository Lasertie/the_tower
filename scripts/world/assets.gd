## Catalogue de modèles 3D libres (voir CREDITS.md) + utilitaires d'ajustement.
## Pour remplacer un modèle (ex : maison médiévale Quaternius), changez simplement son chemin ici.
class_name Assets
extends RefCounted

const M := "res://assets/models/"
const PATHS := {
	# Personnages (Kenney, CC0)
	"character": M + "characters/character.glb",
	"monster": M + "monsters/enemy-flying.glb",
	# Village (Kenney City Kit, CC0)
	"house_a": M + "village/building-small-a.glb",
	"house_b": M + "village/building-small-b.glb",
	"house_c": M + "village/building-small-c.glb",
	"house_d": M + "village/building-small-d.glb",
	"garage": M + "village/building-garage.glb",
	"trees": M + "village/grass-trees.glb",
	"trees_tall": M + "village/grass-trees-tall.glb",
	"pavement": M + "village/pavement.glb",
	"fountain": M + "village/pavement-fountain.glb",
	"lamppost_road": M + "village/road-straight-lightposts.glb",
	"coin": M + "misc/coin.glb",
	"flag": M + "misc/flag.glb",
	"cloud": M + "misc/cloud.glb",
	# Asile (Kenney Furniture Kit + KayKit Furniture Bits, CC0)
	"wall": M + "props/wall.glb",
	"wall_doorway": M + "props/wallDoorway.glb",
	"wall_window": M + "props/wallWindow.glb",
	"bed": M + "props/bedSingle.glb",
	"bed_bunk": M + "props/bedBunk.glb",
	"bookcase": M + "props/bookcaseClosed.glb",
	"cabinet": M + "props/cabinetBedDrawer.glb",
	"toilet": M + "props/toilet.glb",
	"bathtub": M + "props/bathtub.glb",
	"sink": M + "props/bathroomSink.glb",
	"lamp_floor": M + "props/lampRoundFloor.glb",
	"lamp_ceiling": M + "props/lampSquareCeiling.glb",
	"chair_desk": M + "props/chairDesk.glb",
	"desk": M + "props/desk.glb",
	"plant": M + "props/pottedPlant.glb",
	"trashcan": M + "props/trashcan.glb",
	"radio": M + "props/radio.glb",
	"box": M + "props/cardboardBoxClosed.glb",
	"box_open": M + "props/cardboardBoxOpen.glb",
	"books": M + "props/books.glb",
	"table_round": M + "props/tableRound.glb",
	"sofa": M + "props/loungeSofa.glb",
	"side_table": M + "props/sideTable.glb",
	"stool": M + "props/stoolBar.glb",
	"bench": M + "props/bench.glb",
	"armchair": M + "props/kaykit_armchair.glb",
	"cabinet_small": M + "props/kaykit_cabinet-small.glb",
	"shelf": M + "props/kaykit_shelf-b-large.glb",
	"lamp_standing": M + "props/kaykit_lamp-standing.glb",
	"picture": M + "props/kaykit_pictureframe-medium.glb",
}

static var _cache: Dictionary = {}

static func scene(key: String) -> PackedScene:
	if not _cache.has(key):
		var path: String = PATHS.get(key, "")
		_cache[key] = load(path) if path != "" and ResourceLoader.exists(path) else null
	return _cache[key]

## Instance brute du modèle, ou une boîte grise de secours si le fichier manque.
static func instance(key: String) -> Node3D:
	var ps := scene(key)
	if ps:
		return ps.instantiate() as Node3D
	var mi := MeshInstance3D.new()
	var bm := BoxMesh.new()
	mi.mesh = bm
	mi.material_override = WorldUtil.material(Color(0.6, 0.6, 0.6))
	var root := Node3D.new()
	root.add_child(mi)
	return root

static func _collect(n: Node, xf: Transform3D, acc: Array) -> void:
	var t := xf
	if n is Node3D:
		t = xf * (n as Node3D).transform
	if n is MeshInstance3D:
		var bb: AABB = t * (n as MeshInstance3D).get_aabb()
		acc[0] = bb if acc[0] == null else (acc[0] as AABB).merge(bb)
	for c in n.get_children():
		_collect(c, t, acc)

static func aabb_of(root: Node3D) -> AABB:
	var acc: Array = [null]
	_collect(root, Transform3D.IDENTITY, acc)
	return acc[0] if acc[0] != null else AABB(Vector3.ZERO, Vector3.ONE)

## Retourne un Node3D dont l'origine est au centre du pied du modèle, mis à l'échelle.
## mode "height" : size = hauteur ; "width" : size = plus grande dimension horizontale.
static func place(key: String, size: float, mode := &"height") -> Node3D:
	var model := instance(key)
	var bb := aabb_of(model)
	var ref := bb.size.y if mode == &"height" else maxf(bb.size.x, bb.size.z)
	var s := size / maxf(ref, 0.0001)
	model.scale = Vector3.ONE * s
	model.position = Vector3(
		-(bb.position.x + bb.size.x * 0.5) * s,
		-bb.position.y * s,
		-(bb.position.z + bb.size.z * 0.5) * s)
	var wrapper := Node3D.new()
	wrapper.name = key
	wrapper.add_child(model)
	wrapper.set_meta("size", bb.size * s)
	return wrapper

## Ajoute une collision boîte épousant le modèle.
static func make_solid(wrapper: Node3D, shrink := 0.9) -> StaticBody3D:
	var sz: Vector3 = wrapper.get_meta("size", Vector3.ONE)
	var body := StaticBody3D.new()
	var cs := CollisionShape3D.new()
	var bs := BoxShape3D.new()
	bs.size = Vector3(sz.x * shrink, sz.y, sz.z * shrink)
	cs.shape = bs
	cs.position.y = sz.y * 0.5
	body.add_child(cs)
	wrapper.add_child(body)
	return body

## Place un décor dans le monde en une ligne.
static func prop(parent: Node, key: String, size: float, pos: Vector3, yaw_deg := 0.0,
		mode := &"height", solid := true) -> Node3D:
	var w := place(key, size, mode)
	w.position = pos
	w.rotation_degrees.y = yaw_deg
	parent.add_child(w)
	if solid:
		make_solid(w)
	return w

## Multiplie la couleur d'albédo de tous les matériaux du modèle.
static func tint(node: Node, color: Color) -> void:
	if node is MeshInstance3D:
		var mi := node as MeshInstance3D
		for i in mi.get_surface_override_material_count():
			var m := mi.get_active_material(i)
			if m is StandardMaterial3D:
				var d := (m as StandardMaterial3D).duplicate() as StandardMaterial3D
				d.albedo_color = d.albedo_color * color
				mi.set_surface_override_material(i, d)
	for c in node.get_children():
		tint(c, color)
