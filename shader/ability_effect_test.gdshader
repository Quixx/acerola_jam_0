shader_type canvas_item;

uniform sampler2D SCREEN_TEXTURE : hint_screen_texture, filter_linear_mipmap;

void fragment() {
	vec4 bg = texture(SCREEN_TEXTURE, SCREEN_UV);
	COLOR = vec4(bg.r, 0.0, 0.0, 1.0);
}
