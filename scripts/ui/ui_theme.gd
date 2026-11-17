## Thème visuel commun : police Lilita One (SIL OFL, voir CREDITS.md), panneaux sombres, accent doré.
class_name UiTheme
extends RefCounted

const GOLD := Color(0.97, 0.78, 0.26)
const INK := Color(0.96, 0.94, 0.88)
const PANEL := Color(0.06, 0.07, 0.11, 0.88)
const DANGER := Color(0.86, 0.22, 0.25)

static var _font: Font
static var _theme: Theme

static func font() -> Font:
	if _font == null:
		_font = load("res://assets/fonts/lilita_one_regular.ttf") as Font
	return _font

static func panel_style(bg := PANEL, border := Color(1, 1, 1, 0.12), radius := 10, margin := 12) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = bg
	s.border_color = border
	s.set_border_width_all(2)
	s.set_corner_radius_all(radius)
	s.content_margin_left = margin
	s.content_margin_right = margin
	s.content_margin_top = margin * 0.6
	s.content_margin_bottom = margin * 0.6
	return s

static func theme() -> Theme:
	if _theme:
		return _theme
	var t := Theme.new()
	t.default_font = font()
	t.default_font_size = 20
	t.set_color("font_color", "Label", INK)
	t.set_color("font_outline_color", "Label", Color(0, 0, 0, 0.8))
	t.set_constant("outline_size", "Label", 4)
	t.set_stylebox("panel", "PanelContainer", panel_style())
	for state in ["normal", "hover", "pressed", "focus", "disabled"]:
		var bg := Color(0.14, 0.15, 0.22, 0.95)
		var border := Color(1, 1, 1, 0.15)
		if state == "hover" or state == "focus":
			bg = Color(0.22, 0.2, 0.12, 0.98)
			border = GOLD
		elif state == "pressed":
			bg = Color(0.3, 0.26, 0.1, 1)
			border = GOLD
		elif state == "disabled":
			bg = Color(0.1, 0.1, 0.13, 0.7)
		t.set_stylebox(state, "Button", panel_style(bg, border, 8, 16))
	t.set_color("font_color", "Button", INK)
	t.set_color("font_hover_color", "Button", GOLD)
	t.set_color("font_disabled_color", "Button", Color(1, 1, 1, 0.3))
	t.set_font_size("font_size", "Button", 24)
	var fill := StyleBoxFlat.new()
	fill.bg_color = DANGER
	fill.set_corner_radius_all(6)
	var back := StyleBoxFlat.new()
	back.bg_color = Color(0, 0, 0, 0.55)
	back.set_corner_radius_all(6)
	t.set_stylebox("fill", "ProgressBar", fill)
	t.set_stylebox("background", "ProgressBar", back)
	_theme = t
	return t
