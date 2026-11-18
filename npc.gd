extends CharacterBody3D

const U = preload("res://util.gd")
signal downed(n)

var id := ""
var npc_name := ""
var home := Vector3.ZERO
var wander := true
var radius := 6.0
var target := Vector3.ZERO
var wait := 0.0
var move_t := 0.0
var t := 0.0
var hostile := false
var hp := 4
var player
var atk_cd := 1.0
var punch_t := 0.0
var frozen := false
var knock := Vector3.ZERO
var barks: Array = []
var bark_t := 6.0
var bark_l: Label3D
var model: Node3D

func setup(i: String, n: String, shirt: Color, pants: Color, pos: Vector3, w: bool, r: float, b: Array) -> void:
	id = i
	npc_name = n
	wander = w
	radius = r
	barks = b
	position = pos
	home = pos
	target = pos
	collision_layer = 4
	collision_mask = 1 | 2 | 4
	var cs := CollisionShape3D.new()
	var cap := CapsuleShape3D.new()
	cap.radius = 0.32
	cap.height = 1.75
	cs.shape = cap
	cs.position.y = 0.88
	add_child(cs)
	model = U.make_person(shirt, pants)
	add_child(model)
	U.label(self, n, Vector3(0, 2.15, 0), 0.004)
	bark_l = U.label(self, "", Vector3(0, 2.5, 0), 0.006, true, Color(1, 0.95, 0.6))
	bark_l.visible = false
	add_to_group("npc")

func face(d: Vector3, delta: float) -> void:
	if d.length() > 0.01:
		model.rotation.y = lerp_angle(model.rotation.y, atan2(-d.x, -d.z), 10.0 * delta)

func take_hit(dmg: int, from: Vector3) -> void:
	if hp <= 0:
		return
	hp -= dmg
	var kb := global_position - from
	kb.y = 0.0
	knock = kb.normalized() * 5.0
	if hp <= 0:
		model.rotation.x = -1.45
		model.position.y = 0.2
		collision_layer = 0
		collision_mask = 1
		downed.emit(self)

func _physics_process(delta: float) -> void:
	t += delta
	punch_t = maxf(0.0, punch_t - delta)
	if hp <= 0:
		return
	var dir := Vector3.ZERO
	var spd := 1.4
	if frozen and player:
		face(player.global_position - global_position, delta)
	elif hostile and player:
		var dv: Vector3 = player.global_position - global_position
		dv.y = 0.0
		if dv.length() > 1.5:
			dir = dv.normalized()
			spd = 3.4
		else:
			face(dv, delta)
			atk_cd -= delta
			if atk_cd <= 0.0:
				atk_cd = 1.3
				punch_t = 0.25
				player.hit(7.0, global_position)
	elif wander:
		if wait > 0.0:
			wait -= delta
		else:
			var dw := target - global_position
			dw.y = 0.0
			move_t += delta
			if dw.length() < 0.5 or move_t > 8.0:
				target = home + Vector3(randf_range(-radius, radius), 0.0, randf_range(-radius, radius))
				wait = randf_range(1.5, 5.0)
				move_t = 0.0
			else:
				dir = dw.normalized()
	velocity.x = dir.x * spd + knock.x
	velocity.z = dir.z * spd + knock.z
	knock = knock.move_toward(Vector3.ZERO, 14.0 * delta)
	if is_on_floor():
		velocity.y = -0.5
	else:
		velocity.y -= 24.0 * delta
	move_and_slide()
	if dir.length() > 0.1:
		face(dir, delta)
	U.animate(model, t, 1.0 if dir.length() > 0.1 else 0.0, punch_t)
	bark_t -= delta
	if bark_t <= 0.0:
		bark_t = randf_range(9.0, 18.0)
		if barks.size() > 0 and player and global_position.distance_to(player.global_position) < 9.0:
			bark_l.text = barks.pick_random()
			bark_l.visible = true
			get_tree().create_timer(3.0).timeout.connect(func(): if is_instance_valid(bark_l): bark_l.visible = false)
