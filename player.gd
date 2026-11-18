extends CharacterBody3D

const U = preload("res://util.gd")
signal died

var ui
var hp := 100.0
var max_hp := 100.0
var yaw := 0.0
var pitch := -0.3
var pivot: Node3D
var arm: SpringArm3D
var cam: Camera3D
var model: Node3D
var t := 0.0
var atk_cd := 0.0
var punch_t := 0.0
var locked := false
var in_combat := false
var knock := Vector3.ZERO

func _ready() -> void:
	collision_layer = 2
	collision_mask = 1 | 4
	var cs := CollisionShape3D.new()
	var cap := CapsuleShape3D.new()
	cap.radius = 0.32
	cap.height = 1.75
	cs.shape = cap
	cs.position.y = 0.88
	add_child(cs)
	model = U.make_person(Color(0.22, 0.38, 0.6), Color(0.14, 0.14, 0.2), Color(0.1, 0.07, 0.05))
	add_child(model)
	pivot = Node3D.new()
	pivot.position.y = 1.6
	add_child(pivot)
	arm = SpringArm3D.new()
	arm.spring_length = 4.2
	arm.margin = 0.25
	arm.collision_mask = 1
	arm.add_excluded_object(get_rid())
	pivot.add_child(arm)
	cam = Camera3D.new()
	cam.fov = 72.0
	cam.far = 400.0
	arm.add_child(cam)
	cam.make_current()

func hit(dmg: float, from: Vector3) -> void:
	hp -= dmg
	var k := global_position - from
	k.y = 0.0
	knock = k.normalized() * 4.0
	if ui:
		ui.flash = 0.6
	if hp <= 0.0:
		died.emit()

func attack() -> void:
	if locked or atk_cd > 0.0:
		return
	atk_cd = 0.45
	punch_t = 0.25
	var best = null
	var bd := 2.6
	for n in get_tree().get_nodes_in_group("npc"):
		if n.hostile and n.hp > 0:
			var d: Vector3 = n.global_position - global_position
			d.y = 0.0
			if d.length() < bd:
				bd = d.length()
				best = n
	if best:
		var d2: Vector3 = best.global_position - global_position
		d2.y = 0.0
		model.rotation.y = atan2(-d2.x, -d2.z)
		if bd < 1.9:
			best.take_hit(1, global_position)

func _physics_process(delta: float) -> void:
	t += delta
	atk_cd -= delta
	punch_t = maxf(0.0, punch_t - delta)
	var inp := Vector2.ZERO
	if ui:
		inp = ui.stick
		yaw -= ui.look.x * 0.005
		pitch = clampf(pitch - ui.look.y * 0.004, -1.2, 0.3)
		ui.look = Vector2.ZERO
	inp += Vector2(float(Input.is_key_pressed(KEY_D)) - float(Input.is_key_pressed(KEY_A)), float(Input.is_key_pressed(KEY_S)) - float(Input.is_key_pressed(KEY_W)))
	inp = inp.limit_length(1.0)
	if locked:
		inp = Vector2.ZERO
	pivot.rotation = Vector3(pitch, yaw, 0.0)
	var dir := Vector3(inp.x, 0.0, inp.y).rotated(Vector3.UP, yaw)
	var spd := 2.0 + 3.5 * inp.length()
	velocity.x = dir.x * spd + knock.x
	velocity.z = dir.z * spd + knock.z
	knock = knock.move_toward(Vector3.ZERO, 12.0 * delta)
	if is_on_floor():
		velocity.y = -0.5
	else:
		velocity.y -= 24.0 * delta
	move_and_slide()
	if inp.length() > 0.1:
		model.rotation.y = lerp_angle(model.rotation.y, atan2(-dir.x, -dir.z), 12.0 * delta)
	U.animate(model, t, inp.length(), punch_t)
	if not in_combat and hp < max_hp:
		hp = minf(max_hp, hp + 5.0 * delta)
