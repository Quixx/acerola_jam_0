shader_type spatial;
render_mode unshaded, cull_disabled;

uniform sampler2D character_viewport;
uniform sampler2D walls_viewport;
uniform sampler2D screen_texture : hint_screen_texture, filter_linear_mipmap;

uniform vec4 character_color: source_color;
uniform bool show_character_depth = false;
uniform bool show_wall_depth = false;

void vertex() {
  POSITION = vec4(VERTEX, 1.0);
}

void fragment() {
	vec3 screen_color = texture(screen_texture, SCREEN_UV).rgb;
	vec4 character_depth = texture(character_viewport, SCREEN_UV);
	vec4 walls_depth = texture(walls_viewport, SCREEN_UV);
	
	// ALBEDO = vec3(linear_depth);
	// ALBEDO = vec3(linear_depth * 0.01);
	ALBEDO = vec3(screen_color);
	ALPHA = 1.0;

	if (character_depth.a > 0.0 && walls_depth.a > 0.0)
	{
		if( walls_depth.x < character_depth.x )
		{
			ALBEDO = character_color.rgb;
			ALPHA = character_color.a;
		}
	}
}
