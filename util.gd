extends RefCounted

static func mat(c: Color, r := 0.9) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = c
	m.roughness = r
	return m

static func glow(c: Color) -> StandardMaterial3D:
	var m := mat(c)
	m.emission_enabled = true
	m.emission = c
	return m

# Панельная многоэтажка: текстура окон тайлится в мировых метрах (triplanar)
static func facade(tint: Color) -> StandardMaterial3D:
	var img := Image.create(128, 128, false, Image.FORMAT_RGB8)
	img.fill(tint)
	var rng := RandomNumberGenerator.new()
	rng.seed = 7
	for i in 4:
		for j in 4:
			var c := Color(0.97, 0.84, 0.5) if rng.randf() < 0.3 else Color(0.2, 0.25, 0.32)
			img.fill_rect(Rect2i(i * 32 + 8, j * 32 + 7, 16, 18), c)
	var m := StandardMaterial3D.new()
	m.albedo_texture = ImageTexture.create_from_image(img)
	m.uv1_triplanar = true
	m.uv1_scale = Vector3.ONE / 12.0
	m.roughness = 1.0
	return m

static func box(parent: Node, pos: Vector3, size: Vector3, m: Material, collide := true) -> Node3D:
	var mi := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = size
	mi.mesh = bm
	mi.material_override = m
	if not collide:
		mi.position = pos
		parent.add_child(mi)
		return mi
	var sb := StaticBody3D.new()
	sb.position = pos
	var cs := CollisionShape3D.new()
	var sh := BoxShape3D.new()
	sh.size = size
	cs.shape = sh
	sb.add_child(cs)
	sb.add_child(mi)
	parent.add_child(sb)
	return sb

static func label(parent: Node, text: String, pos: Vector3, px := 0.01, billboard := true, col := Color.WHITE) -> Label3D:
	var l := Label3D.new()
	l.text = text
	l.font_size = 48
	l.pixel_size = px
	l.outline_size = 12
	l.modulate = col
	if billboard:
		l.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	l.position = pos
	parent.add_child(l)
	return l

static func _mesh(parent: Node, mesh: Mesh, pos: Vector3, col: Color) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	mi.material_override = mat(col)
	mi.position = pos
	parent.add_child(mi)
	return mi

# Человечек из примитивов. Лицом смотрит в -Z.
static func make_person(shirt: Color, pants: Color, hair := Color(0.15, 0.1, 0.07), skin := Color(0.9, 0.72, 0.58)) -> Node3D:
	var r := Node3D.new()
	var tb := BoxMesh.new()
	tb.size = Vector3(0.5, 0.6, 0.28)
	_mesh(r, tb, Vector3(0, 1.15, 0), shirt)
	var hs := SphereMesh.new()
	hs.radius = 0.17
	hs.height = 0.34
	_mesh(r, hs, Vector3(0, 1.65, 0), skin)
	var hh := SphereMesh.new()
	hh.radius = 0.18
	hh.height = 0.24
	_mesh(r, hh, Vector3(0, 1.76, 0.02), hair)
	var es := SphereMesh.new()
	es.radius = 0.025
	es.height = 0.05
	_mesh(r, es, Vector3(-0.06, 1.68, -0.15), Color(0.05, 0.05, 0.05))
	_mesh(r, es, Vector3(0.06, 1.68, -0.15), Color(0.05, 0.05, 0.05))
	for s in [-1, 1]:
		var leg := Node3D.new()
		leg.name = "LegL" if s < 0 else "LegR"
		leg.position = Vector3(s * 0.13, 0.85, 0)
		var lb := BoxMesh.new()
		lb.size = Vector3(0.2, 0.85, 0.22)
		_mesh(leg, lb, Vector3(0, -0.42, 0), pants)
		r.add_child(leg)
		var arm := Node3D.new()
		arm.name = "ArmL" if s < 0 else "ArmR"
		arm.position = Vector3(s * 0.34, 1.42, 0)
		var ab := BoxMesh.new()
		ab.size = Vector3(0.14, 0.6, 0.16)
		_mesh(arm, ab, Vector3(0, -0.28, 0), shirt)
		r.add_child(arm)
	return r

static func animate(m: Node3D, t: float, spd: float, punch: float) -> void:
	var sw := sin(t * 9.0) * 0.7 * clampf(spd, 0.0, 1.0)
	var ll: Node3D = m.get_node("LegL")
	var lr: Node3D = m.get_node("LegR")
	var al: Node3D = m.get_node("ArmL")
	var ar: Node3D = m.get_node("ArmR")
	ll.rotation.x = sw
	lr.rotation.x = -sw
	al.rotation.x = -sw
	ar.rotation.x = 1.5 if punch > 0.0 else -sw
