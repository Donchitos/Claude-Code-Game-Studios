extends Control
## Original vector landscape and nexus seal, rendered at viewport resolution.
func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	resized.connect(queue_redraw)

func _draw() -> void:
	var w := size.x
	var h := size.y
	draw_rect(Rect2(Vector2.ZERO, size), Color("0c2429"))
	for i in 7:
		var points := PackedVector2Array([Vector2(0, h)])
		for j in 21:
			var x := w * j / 20.0
			var y := h * (0.45 + i * 0.06) + sin(j * 0.8 + i * 1.7) * h * 0.08 + sin(j * 1.8 + i) * h * 0.025
			points.append(Vector2(x, y))
		points.append(Vector2(w, h))
		draw_colored_polygon(points, Color(0.06 + i * .006, .18 + i * .006, .20 + i * .004))
	var center := Vector2(w * .66, h * .32)
	var radius := minf(w * .23, h * .25)
	for k in [1.0, .86, .69]:
		draw_arc(center, radius * k, 0, TAU, 120, Color("9c8e61"), 1.5, true)
	for i in 8:
		var a := TAU * i / 8.0 - PI / 2
		var v := Vector2.from_angle(a)
		draw_line(center + v * radius * .78, center + v * radius * 1.08, Color("dec58a"), 2, true)
		var tangent := v.orthogonal() * 6
		draw_line(center + v * radius * .94 - tangent, center + v * radius * .94 + tangent, Color("dec58a"), 3, true)
	var diamond := PackedVector2Array([center + Vector2(0, -radius * .58), center + Vector2(radius * .28, 0), center + Vector2(0, radius * .58), center + Vector2(-radius * .28, 0), center + Vector2(0, -radius * .58)])
	draw_polyline(diamond, Color("ecd49b"), 3, true)
	draw_circle(center, 7, Color("f5dfad"))
	for i in 40:
		var pos := Vector2(fmod(i * 127.7, maxf(w, 1)), fmod(i * 73.3, maxf(h * .62, 1)))
		draw_circle(pos, 1.2, Color(0.7, .75, .57, .25))
