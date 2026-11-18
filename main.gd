extends Node3D

const U = preload("res://util.gd")
const FLAT := Vector3(1000, 0, 0)
const SHOP := Vector3(2000, 0, 0)
const GARAGES := Vector3(40, 0, 18)
const QUESTS := [
	"Поговорить с мамой на кухне",
	"Купить батон и молоко в «Продуктах» (юг двора)",
	"Отнести продукты маме домой (подъезд 3)",
	"Выйти во двор: Ильдар ищет тебя",
	"Сходить на спортплощадку, познакомиться с Рустемом",
	"Вечером прийти к гаражам (восток двора)",
	"Отбейся от парней с Азино!",
	"Поговорить с Рустемом",
	"Глава 1 пройдена. Гуляй по району",
]

var player
var ui
var sun: DirectionalLight3D
var env: Environment
var sky: ProceduralSkyMaterial
var m_trunk: StandardMaterial3D
var m_leaf: StandardMaterial3D
var lamps: Array = []
var tram: AnimatableBody3D
var doors: Array = []
var npcs := {}
var enemies: Array = []
var hour := 8.0
var q := 0
var respect := 0
var family := 0
var ded_done := false
var in_dialog := false
var cur_key := ""
var cur_target = null
var cur_npc = null
var loc := "flat"

var D := {
	"mom1": ["Мама", "Марат, сынок, сбегай в «Продукты»: батон и пакет молока. Вот рубль. Отец скоро с завода, а в доме ни крошки.", [["Хорошо, мам.", "", "money"], ["Мам, потом, меня ребята ждут...", "mom1b", ""]]],
	"mom1b": ["Мама", "Ребята его ждут! Отец с утра на смене, а ты по дворам. Сначала дело, потом гулянки.", [["Ладно, иду.", "", "money,fam-"]]],
	"mom2": ["Мама", "Умница, успел. Иди погуляй, только до темноты. Ильдар во дворе тебя искал, на лавочке сидит.", [["Хорошо, мам.", "", "goods_given"]]],
	"mom_idle": ["Мама", "Не гуляй допоздна, Марат. Слышишь? Время сейчас неспокойное.", []],
	"rosa1": ["Роза-апа (продавщица)", "Очередь, молодой человек! Что вам?", [["Батон и пакет молока, пожалуйста.", "rosa2", "buy"]]],
	"rosa2": ["Роза-апа", "Рубль десять... ладно, десять копеек не возьму, маму твою знаю. Фариде привет передавай.", [["Спасибо, Роза-апа!", "", ""]]],
	"rosa_idle": ["Роза-апа", "Хлеб привозят до обеда, потом хоть шаром покати. Приходи с утра.", []],
	"ded1": ["Дед Фёдор", "Сынок, пропусти, а? Ноги уже не те, стоять тяжело.", [["Проходите, дедушка.", "ded_ok", "resp+,ded"], ["Я тоже спешу.", "ded_no", "resp-,ded"]]],
	"ded_ok": ["Дед Фёдор", "Спасибо. Хороший парень, видно, воспитан. Не растеряй это.", []],
	"ded_no": ["Дед Фёдор", "Эх... В наше время старших пропускали. Ладно, постою.", []],
	"ild1": ["Ильдар", "Маратик, наконец-то! На площадке сегодня Рустем с ребятами. Пойдём, познакомлю. Только лишнего не ляпни — пацаны серьёзные.", [["Пойдём, интересно.", "", "q4"], ["Мне домой надо...", "ild1b", ""]]],
	"ild1b": ["Ильдар", "Да ладно, чего ты как мамкин? Десять минут.", [["Ладно, пошли.", "", "q4"]]],
	"ild_idle": ["Ильдар", "Рустем на спортплощадке. Не тяни.", []],
	"rus1": ["Рустем", "О, Ильдар кого-то привёл. Тебя как звать?", [["Марат. Из третьего подъезда.", "rus1b", "resp+"], ["А тебе зачем?", "rus1c", "resp-"]]],
	"rus1b": ["Рустем", "Слышал про тебя. Тихий, учишься. Это хорошо. Но во дворе одной учёбы мало — сам знаешь.", [["Понимаю.", "rus1d", ""]]],
	"rus1c": ["Рустем", "Смелый. Или глупый. Ладно, посмотрим, какой.", [["...", "rus1d", ""]]],
	"rus1d": ["Рустем", "Приходи вечером к гаражам. Посидим, поговорим. Не пожалеешь.", [["Ладно, приду.", "", "q5"], ["Подумаю.", "", "q5"]]],
	"rus_idle": ["Рустем", "Вечером к гаражам, не забыл?", []],
	"rus2": ["Рустем", "Видел, как ты стоял. Не побежал. Это дорогого стоит. Про тебя теперь будут знать — и наши, и азинские.", [["Я просто не дал бы Ильдара в обиду.", "rus2b", "resp+"], ["Мне это не нравится. Я не хотел драки.", "rus2c", "fam+"]]],
	"rus2b": ["Рустем", "Своих не сдают — запомни. Но и спрос потом будет. Когда решишь — найди меня.", [["...", "", "end"]]],
	"rus2c": ["Рустем", "Никто не хочет. Но драка сама тебя находит. Когда поймёшь — найди меня.", [["...", "", "end"]]],
}

func _ready() -> void:
	build_world()
	player = CharacterBody3D.new()
	player.set_script(preload("res://player.gd"))
	player.position = FLAT + Vector3(0, 0.3, 1.0)
	add_child(player)
	player.died.connect(on_died)
	var cl := CanvasLayer.new()
	add_child(cl)
	ui = Control.new()
	ui.set_script(preload("res://ui.gd"))
	cl.add_child(ui)
	player.ui = ui
	ui.action.connect(interact)
	ui.attack.connect(func(): player.attack())
	ui.choice.connect(on_choice)
	build_interiors()
	spawn_npcs()
	ui.toast("Казань, 1988 год. Обычный день. Слева — джойстик, справа — камера.", 6.0)

# ---------------------------------------------------------------- мир
func build_world() -> void:
	env = Environment.new()
	sky = ProceduralSkyMaterial.new()
	var sk := Sky.new()
	sk.sky_material = sky
	env.background_mode = Environment.BG_SKY
	env.sky = sk
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	env.fog_enabled = true
	env.fog_density = 0.003
	var we := WorldEnvironment.new()
	we.environment = env
	add_child(we)
	sun = DirectionalLight3D.new()
	sun.directional_shadow_max_distance = 60.0
	add_child(sun)
	m_trunk = U.mat(Color(0.3, 0.2, 0.12))
	m_leaf = U.mat(Color(0.2, 0.4, 0.16))
	var asph := U.mat(Color(0.16, 0.16, 0.17))
	var conc := U.mat(Color(0.55, 0.55, 0.52))
	U.box(self, Vector3(0, -0.5, 0), Vector3(280, 1, 280), U.mat(Color(0.34, 0.45, 0.27)))
	U.box(self, Vector3(0, -0.02, 41), Vector3(280, 0.1, 14), asph, false)
	U.box(self, Vector3(72, -0.02, 0), Vector3(12, 0.1, 280), asph, false)
	U.box(self, Vector3(0, -0.02, 3), Vector3(4, 0.1, 62), conc, false)
	U.box(self, Vector3(0, -0.02, 6), Vector3(60, 0.1, 3), conc, false)
	var f1 := U.facade(Color(0.66, 0.64, 0.58))
	var f2 := U.facade(Color(0.58, 0.52, 0.46))
	U.box(self, Vector3(0, 13, -34), Vector3(56, 26, 12), f1)
	U.box(self, Vector3(-36, 9, -4), Vector3(12, 18, 52), f2)
	U.box(self, Vector3(36, 14, -8), Vector3(12, 28, 40), f1)
	for p in [Vector3(-90, 14, -70), Vector3(100, 18, -60), Vector3(-100, 12, 30), Vector3(110, 14, 70), Vector3(-60, 16, 100)]:
		U.box(self, p, Vector3(14, p.y * 2.0, 50), f2)
	# ПТУ через дорогу
	U.box(self, Vector3(0, 6, 66), Vector3(44, 12, 16), U.facade(Color(0.75, 0.62, 0.45)))
	var sg := U.label(self, "ПТУ № 7", Vector3(0, 9.5, 57.9), 0.03, false)
	sg.rotation_degrees.y = 180.0
	# магазин «Продукты»
	U.box(self, Vector3(-10, 3, 28), Vector3(18, 6, 8), U.mat(Color(0.85, 0.8, 0.65)))
	U.box(self, Vector3(-10, 1.2, 23.95), Vector3(1.8, 2.4, 0.15), U.mat(Color(0.35, 0.22, 0.12)), false)
	var ss := U.label(self, "ПРОДУКТЫ", Vector3(-10, 4.6, 23.85), 0.02, false, Color(1, 0.9, 0.5))
	ss.rotation_degrees.y = 180.0
	# подъезд 3
	U.box(self, Vector3(-29.9, 1.2, -6), Vector3(0.15, 2.4, 1.6), U.mat(Color(0.35, 0.22, 0.12)), false)
	U.label(self, "ПОДЪЕЗД 3", Vector3(-29.0, 3.0, -6), 0.008)
	# гаражи
	for z in range(-18, 22, 6):
		var gi: int = posmod(z / 6 + 10, 3)
		var gc: Color = [Color(0.45, 0.3, 0.22), Color(0.3, 0.4, 0.3), Color(0.5, 0.5, 0.52)][gi]
		U.box(self, Vector3(48, 1.5, z), Vector3(5, 3, 5.5), U.mat(gc))
		U.box(self, Vector3(45.45, 1.2, z), Vector3(0.1, 2.4, 3), U.mat(Color(0.12, 0.12, 0.14)), false)
	U.label(self, "ГАРАЖНЫЙ КООПЕРАТИВ", Vector3(44, 4.2, 4), 0.01)
	# спортплощадка
	U.box(self, Vector3(16, 0.02, 12), Vector3(20, 0.06, 13), U.mat(Color(0.45, 0.3, 0.25)), false)
	for gx in [6.4, 25.6]:
		U.box(self, Vector3(gx, 1.1, 12), Vector3(0.15, 2.2, 3.0), U.mat(Color.WHITE))
	# песочница, лавочки
	U.box(self, Vector3(-8, 0.15, 16), Vector3(4, 0.3, 4), U.mat(Color(0.8, 0.7, 0.45)), false)
	for b in [Vector3(-4, 0.3, 9.4), Vector3(4, 0.3, -6), Vector3(-18, 0.3, -6), Vector3(12, 0.3, 22)]:
		U.box(self, b, Vector3(2, 0.6, 0.6), U.mat(Color(0.4, 0.28, 0.15)))
	for p in [Vector2(-22, -18), Vector2(-12, -22), Vector2(12, -22), Vector2(22, -18), Vector2(-22, 2), Vector2(-14, 12), Vector2(22, -8), Vector2(26, -4), Vector2(-24, 16), Vector2(8, 20), Vector2(24, 24), Vector2(-6, -12), Vector2(60, -30), Vector2(60, 30), Vector2(-50, 20)]:
		tree(Vector3(p.x, 0, p.y))
	car(Vector3(-20, 0, -25.5), 0.0, Color(0.85, 0.8, 0.6))
	car(Vector3(-14, 0, -25.5), 0.0, Color(0.7, 0.15, 0.15))
	car(Vector3(24, 0, -25.5), 0.0, Color(0.2, 0.4, 0.4))
	car(Vector3(-27.2, 0, 12), 90.0, Color(0.9, 0.9, 0.9))
	car(Vector3(-27.2, 0, 17), 90.0, Color(0.85, 0.45, 0.1))
	for p in [Vector3(-20, 0, -8), Vector3(20, 0, -10), Vector3(0, 0, 20), Vector3(-20, 0, 20), Vector3(38, 0, 22), Vector3(20, 0, 36)]:
		lamp(p)
	# трамвайные пути и трамвай
	var rail := U.mat(Color(0.3, 0.3, 0.32))
	U.box(self, Vector3(0, 0.05, 39.8), Vector3(280, 0.1, 0.12), rail, false)
	U.box(self, Vector3(0, 0.05, 41.2), Vector3(280, 0.1, 0.12), rail, false)
	U.box(self, Vector3(-30, 1.4, 36), Vector3(0.15, 2.8, 0.15), U.mat(Color(0.2, 0.2, 0.2)))
	U.label(self, "ТРАМВАЙ  № 5", Vector3(-30, 3.3, 36), 0.008)
	tram = AnimatableBody3D.new()
	tram.position = Vector3(-130, 1.7, 39.5)
	var tcs := CollisionShape3D.new()
	var tsh := BoxShape3D.new()
	tsh.size = Vector3(10, 3, 2.6)
	tcs.shape = tsh
	tram.add_child(tcs)
	U.box(tram, Vector3.ZERO, Vector3(10, 3, 2.6), U.mat(Color(0.75, 0.15, 0.12)), false)
	U.box(tram, Vector3(0, 0.3, 0), Vector3(9.6, 1.0, 2.7), U.mat(Color(0.15, 0.2, 0.28), 0.2), false)
	U.box(tram, Vector3(0, -0.9, 0), Vector3(10, 0.4, 2.7), U.mat(Color(0.9, 0.8, 0.3)), false)
	add_child(tram)

func tree(p: Vector3) -> void:
	var sb := StaticBody3D.new()
	sb.position = p
	var cs := CollisionShape3D.new()
	var sh := CylinderShape3D.new()
	sh.radius = 0.35
	sh.height = 3.0
	cs.shape = sh
	cs.position.y = 1.5
	sb.add_child(cs)
	var tm := CylinderMesh.new()
	tm.top_radius = 0.22
	tm.bottom_radius = 0.3
	tm.height = 3.0
	var tr := MeshInstance3D.new()
	tr.mesh = tm
	tr.material_override = m_trunk
	tr.position.y = 1.5
	sb.add_child(tr)
	var cm := SphereMesh.new()
	cm.radius = 2.0
	cm.height = 3.6
	var cr := MeshInstance3D.new()
	cr.mesh = cm
	cr.material_override = m_leaf
	cr.position.y = 4.4
	sb.add_child(cr)
	add_child(sb)

func car(p: Vector3, yaw: float, col: Color) -> void:
	var r := Node3D.new()
	r.position = p
	r.rotation_degrees.y = yaw
	add_child(r)
	U.box(r, Vector3(0, 0.7, 0), Vector3(4.1, 0.9, 1.7), U.mat(col, 0.4))
	U.box(r, Vector3(-0.2, 1.45, 0), Vector3(2.1, 0.7, 1.5), U.mat(Color(0.15, 0.2, 0.25), 0.2), false)
	for wx in [-1.3, 1.3]:
		for wz in [-0.85, 0.85]:
			U.box(r, Vector3(wx, 0.3, wz), Vector3(0.7, 0.6, 0.2), U.mat(Color(0.05, 0.05, 0.05)), false)

func lamp(p: Vector3) -> void:
	U.box(self, p + Vector3(0, 2.6, 0), Vector3(0.15, 5.2, 0.15), U.mat(Color(0.2, 0.2, 0.22)))
	U.box(self, p + Vector3(0, 5.3, 0), Vector3(0.6, 0.2, 0.6), U.glow(Color(1, 0.9, 0.6)), false)
	var l := OmniLight3D.new()
	l.position = p + Vector3(0, 5.0, 0)
	l.omni_range = 16.0
	l.light_color = Color(1, 0.85, 0.6)
	l.light_energy = 0.0
	add_child(l)
	lamps.append(l)

# ---------------------------------------------------------------- интерьеры
func room(o: Vector3, w: float, d: float, wall: Color, floor_c: Color) -> void:
	var h := 3.0
	var wm := U.mat(wall)
	U.box(self, o + Vector3(0, -0.1, 0), Vector3(w + 1, 0.2, d + 1), U.mat(floor_c))
	U.box(self, o + Vector3(0, h + 0.1, 0), Vector3(w + 1, 0.2, d + 1), U.mat(Color(0.85, 0.85, 0.8)))
	U.box(self, o + Vector3(0, h / 2, -d / 2 - 0.15), Vector3(w + 1, h, 0.3), wm)
	U.box(self, o + Vector3(0, h / 2, d / 2 + 0.15), Vector3(w + 1, h, 0.3), wm)
	U.box(self, o + Vector3(-w / 2 - 0.15, h / 2, 0), Vector3(0.3, h, d), wm)
	U.box(self, o + Vector3(w / 2 + 0.15, h / 2, 0), Vector3(0.3, h, d), wm)
	var l := OmniLight3D.new()
	l.position = o + Vector3(0, 2.5, 0)
	l.omni_range = maxf(w, d) * 1.2
	l.light_energy = 1.4
	add_child(l)
	U.box(self, o + Vector3(0, 1.1, d / 2 - 0.02), Vector3(1.3, 2.2, 0.08), U.mat(Color(0.35, 0.22, 0.12)), false)
	U.label(self, "ВЫХОД", o + Vector3(0, 2.6, d / 2 - 0.3), 0.008)

func build_interiors() -> void:
	# квартира: кухня-гостиная
	room(FLAT, 10.0, 8.0, Color(0.78, 0.7, 0.5), Color(0.45, 0.3, 0.2))
	var wood := U.mat(Color(0.5, 0.33, 0.18))
	U.box(self, FLAT + Vector3(-2.5, 0.4, -1.0), Vector3(1.6, 0.8, 1.0), wood)
	U.box(self, FLAT + Vector3(-3.5, 0.25, -1.0), Vector3(0.4, 0.5, 0.4), wood)
	U.box(self, FLAT + Vector3(-1.5, 0.25, -1.0), Vector3(0.4, 0.5, 0.4), wood)
	U.box(self, FLAT + Vector3(3.4, 0.3, -2.8), Vector3(2.0, 0.6, 1.2), U.mat(Color(0.3, 0.4, 0.6)))
	U.box(self, FLAT + Vector3(-4.3, 1.0, -3.2), Vector3(1.2, 2.0, 0.8), wood)
	U.box(self, FLAT + Vector3(0, 1.6, -3.92), Vector3(3, 1.8, 0.05), U.mat(Color(0.6, 0.12, 0.12)), false)
	U.box(self, FLAT + Vector3(3.8, 0.4, 1.5), Vector3(1.0, 0.8, 0.7), U.mat(Color(0.25, 0.25, 0.28)))
	doors.append({"pos": Vector3(-29.0, 0, -6), "dest": FLAT + Vector3(0, 0.3, 1.0), "loc": "flat", "label": "Войти: подъезд 3 (домой)"})
	doors.append({"pos": FLAT + Vector3(0, 0, 3.4), "dest": Vector3(-26.0, 0.3, -6), "loc": "out", "label": "Выйти во двор"})
	# магазин
	room(SHOP, 12.0, 8.0, Color(0.85, 0.85, 0.75), Color(0.55, 0.55, 0.5))
	U.box(self, SHOP + Vector3(0, 0.55, -1.2), Vector3(6, 1.1, 0.8), U.mat(Color(0.8, 0.75, 0.6)))
	for sx in [-4, -2, 0, 2, 4]:
		U.box(self, SHOP + Vector3(sx, 1.1, -3.6), Vector3(1.6, 2.2, 0.5), U.mat(Color(0.5, 0.5, 0.45)))
	U.label(self, "ХЛЕБ    МОЛОКО    КРУПА", SHOP + Vector3(0, 2.7, -3.3), 0.008)
	doors.append({"pos": Vector3(-10, 0, 22.9), "dest": SHOP + Vector3(0, 0.3, 1.0), "loc": "shop", "label": "Войти: магазин «Продукты»"})
	doors.append({"pos": SHOP + Vector3(0, 0, 3.4), "dest": Vector3(-10, 0.3, 19.5), "loc": "out", "label": "Выйти на улицу"})

# ---------------------------------------------------------------- люди
func add_npc(id: String, nm: String, shirt: Color, pants: Color, pos: Vector3, wander := true, radius := 5.0, barks: Array = [], hostile := false):
	var n = CharacterBody3D.new()
	n.set_script(preload("res://npc.gd"))
	n.setup(id, nm, shirt, pants, pos, wander, radius, barks)
	n.player = player
	n.hostile = hostile
	add_child(n)
	if not hostile:
		n.add_to_group("talk")
	npcs[id] = n
	return n

func spawn_npcs() -> void:
	add_npc("mom", "Мама", Color(0.7, 0.3, 0.35), Color(0.25, 0.2, 0.3), FLAT + Vector3(0.5, 0, -1.2), false)
	add_npc("rosa", "Роза-апа", Color(0.9, 0.9, 0.9), Color(0.3, 0.3, 0.35), SHOP + Vector3(0, 0, -2.2), false)
	add_npc("ded", "Дед Фёдор", Color(0.3, 0.35, 0.25), Color(0.2, 0.2, 0.2), SHOP + Vector3(2.5, 0, 0.2), false)
	add_npc("ildar", "Ильдар", Color(0.75, 0.55, 0.2), Color(0.2, 0.25, 0.4), Vector3(-4.5, 0.1, 8.2), false, 0.0, ["Марат, ну где ты?"])
	add_npc("rustem", "Рустем", Color(0.12, 0.12, 0.14), Color(0.3, 0.3, 0.3), Vector3(17, 0.1, 12), false, 0.0, ["Чё смотришь?", "Тихо у нас сегодня..."])
	add_npc("kamil", "Камиль", Color(0.5, 0.15, 0.15), Color(0.15, 0.2, 0.35), Vector3(14, 0.1, 14), false, 0.0, ["Слышал, азинские опять шумят."])
	add_npc("kolya", "Дядя Коля", Color(0.4, 0.4, 0.45), Color(0.25, 0.25, 0.2), Vector3(10, 0.1, -14), true, 8.0, ["Молодёжь... раньше на заводе пахали.", "Опять эти во дворе."])
	add_npc("zina", "Баба Зина", Color(0.5, 0.3, 0.5), Color(0.2, 0.2, 0.25), Vector3(-18, 0.1, -12), true, 6.0, ["Хлеб давали с утра, уже нету.", "Куда катится страна..."])
	for i in 2:
		var k = add_npc("kid%d" % i, "Пацанёнок", Color(0.8, 0.3, 0.2), Color(0.2, 0.3, 0.5), Vector3(-8 + i * 3, 0.1, 15), true, 4.0, ["Дядь, мяч не видел?", "Пасуй!"])
		k.model.scale = Vector3(0.7, 0.7, 0.7)
	add_npc("p1", "Прохожий", Color(0.3, 0.3, 0.35), Color(0.2, 0.2, 0.2), Vector3(-20, 0.1, 34), true, 12.0, ["Трамвая не дождёшься..."])
	add_npc("p2", "Прохожая", Color(0.2, 0.5, 0.4), Color(0.25, 0.25, 0.3), Vector3(20, 0.1, 34), true, 12.0, ["Опять очередь за колбасой."])

# ---------------------------------------------------------------- логика
func _physics_process(delta: float) -> void:
	hour = fposmod(hour + delta / 45.0, 24.0)
	update_sky()
	tram.position.x += 7.0 * delta
	if tram.position.x > 130.0:
		tram.position.x = -130.0
	var pp: Vector3 = player.global_position
	cur_target = null
	var best := 99.0
	var ptxt := ""
	if not in_dialog:
		for n in get_tree().get_nodes_in_group("talk"):
			var dd: float = n.global_position.distance_to(pp)
			if n.hp > 0 and dd < 2.8 and dd < best:
				best = dd
				cur_target = n
				ptxt = "Поговорить: " + n.npc_name
		for d in doors:
			var dp: Vector3 = d["pos"]
			var dd2 := dp.distance_to(pp)
			if dd2 < 2.2 and dd2 < best:
				best = dd2
				cur_target = d
				ptxt = d["label"]
	ui.prompt = ptxt
	ui.time_text = "%02d:%02d  •  Казань, 1988" % [int(hour), int(fposmod(hour, 1.0) * 60.0)]
	ui.quest = QUESTS[q]
	ui.respect = respect
	ui.family = family
	ui.hp = player.hp
	ui.combat = player.in_combat
	if q == 5 and loc == "out" and pp.distance_to(GARAGES) < 13.0:
		start_fight()
	if q == 6:
		player.in_combat = enemies.any(func(e): return is_instance_valid(e) and e.hp > 0)

func update_sky() -> void:
	var elev := (hour - 6.0) / 12.0 * PI
	var s := sin(elev)
	var day := clampf(s * 2.5 + 0.2, 0.0, 1.0)
	sun.rotation_degrees = Vector3(-rad_to_deg(elev), 35.0, 0.0)
	sun.light_energy = maxf(s, 0.0) * 1.2
	sun.light_color = Color(1.0, 0.6, 0.35).lerp(Color(1.0, 0.96, 0.88), clampf(s * 3.0, 0.0, 1.0))
	sun.shadow_enabled = s > 0.05
	var top := Color(0.03, 0.05, 0.12).lerp(Color(0.3, 0.52, 0.85), day)
	var hor := Color(0.08, 0.1, 0.18).lerp(Color(0.78, 0.82, 0.88), day)
	sky.sky_top_color = top
	sky.sky_horizon_color = hor
	sky.ground_horizon_color = hor
	sky.ground_bottom_color = hor.darkened(0.4)
	env.ambient_light_color = Color(0.2, 0.24, 0.4).lerp(Color(0.8, 0.82, 0.88), day)
	env.fog_light_color = hor
	for l in lamps:
		l.light_energy = (1.0 - day) * 2.0

func interact() -> void:
	if in_dialog or ui.end_card != "" or cur_target == null:
		return
	if cur_target is Dictionary:
		var d: Dictionary = cur_target
		player.global_position = d["dest"]
		player.velocity = Vector3.ZERO
		loc = d["loc"]
		cur_target = null
	else:
		talk(cur_target)

func talk(n) -> void:
	cur_npc = n
	n.frozen = true
	var key := ""
	if n.id == "mom":
		key = "mom1" if q == 0 else ("mom2" if q == 2 else "mom_idle")
	elif n.id == "rosa":
		key = "rosa1" if q == 1 else "rosa_idle"
	elif n.id == "ded" and q == 1 and not ded_done:
		key = "ded1"
	elif n.id == "ildar":
		key = "ild1" if q == 3 else "ild_idle"
	elif n.id == "rustem":
		key = "rus1" if q == 4 else ("rus2" if q == 7 else "rus_idle")
	if key == "":
		var line := "Эх, молодёжь..."
		if n.barks.size() > 0:
			line = n.barks.pick_random()
		D["_say"] = [n.npc_name, line, []]
		key = "_say"
	start(key)

func start(key: String) -> void:
	cur_key = key
	in_dialog = true
	player.locked = true
	var d: Array = D[key]
	var labels: Array = []
	for c in d[2]:
		labels.append(c[0])
	if labels.is_empty():
		labels = ["Дальше"]
	ui.open(d[0], d[1], labels)

func on_choice(i: int) -> void:
	if not in_dialog:
		return
	var d: Array = D[cur_key]
	if d[2].is_empty():
		close_dialog()
		return
	if i >= d[2].size():
		return
	var c: Array = d[2][i]
	for a in String(c[2]).split(",", false):
		act(a)
	if c[1] != "":
		start(c[1])
	else:
		close_dialog()

func close_dialog() -> void:
	in_dialog = false
	player.locked = false
	ui.close()
	if cur_npc and is_instance_valid(cur_npc):
		cur_npc.frozen = false
	cur_npc = null

func act(a: String) -> void:
	if a == "money":
		q = 1
		ui.toast("Рубль в кармане. Магазин — на юге двора.")
	elif a == "buy":
		q = 2
		ui.toast("Батон и молоко куплены. Теперь домой.")
	elif a == "goods_given":
		q = 3
	elif a == "q4":
		q = 4
	elif a == "q5":
		q = 5
		hour = 18.5
		ui.toast("Вечер. Рустем ждёт у гаражей...", 4.0)
	elif a == "resp+":
		respect += 1
		ui.toast("Уважение во дворе +1")
	elif a == "resp-":
		respect -= 1
		ui.toast("Уважение во дворе −1")
	elif a == "fam+":
		family += 1
	elif a == "fam-":
		family -= 1
		ui.toast("Мама недовольна...")
	elif a == "ded":
		ded_done = true
	elif a == "end":
		q = 8
		ui.end_card = "ГЛАВА 1 «ОБЫЧНАЯ ЖИЗНЬ» ПРОЙДЕНА\n\nМарат ещё не с ними. Но во дворе о нём уже знают.\n\nУважение во дворе: %d     Семья: %d\n\nДальше: глава 2 «Знакомство с улицей»" % [respect, family]

func start_fight() -> void:
	q = 6
	var il = npcs["ildar"]
	il.global_position = Vector3(37, 0.1, 19)
	il.home = il.global_position
	for i in 2:
		var e = add_npc("enemy%d" % i, "Парень с Азино", Color(0.08, 0.08, 0.1), Color(0.22, 0.26, 0.4), Vector3(36 + i * 5, 0.1, 29), false, 0.0, [], true)
		e.downed.connect(on_enemy_down)
		enemies.append(e)
	ui.toast("«Эй, Ильдар! Должок помнишь?» — парни с Азино. Бей кнопкой «Удар» (F).", 5.0)

func on_enemy_down(_n) -> void:
	if q != 6:
		return
	for e in enemies:
		if is_instance_valid(e) and e.hp > 0:
			return
	q = 7
	player.in_combat = false
	ui.toast("Отбился! К тебе идёт Рустем...", 4.0)
	var r = npcs["rustem"]
	r.global_position = Vector3(36, 0.1, 22)
	r.home = r.global_position
	for e in enemies:
		get_tree().create_timer(10.0).timeout.connect(func(): if is_instance_valid(e): e.queue_free())

func on_died() -> void:
	player.hp = player.max_hp
	player.global_position = Vector3(-4, 0.3, 11)
	loc = "out"
	ui.toast("Тебя вырубили. Очнулся во дворе. Они всё ещё там — отдышись и дай сдачи.", 5.0)
	for i in enemies.size():
		var e = enemies[i]
		if is_instance_valid(e) and e.hp > 0:
			e.hp = 4
			e.global_position = Vector3(36 + i * 5, 0.1, 29)
