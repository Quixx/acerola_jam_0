shader_type spatial;
render_mode unshaded, cull_disabled;

uniform sampler2D screen_texture : hint_screen_texture, filter_linear_mipmap;
uniform sampler2D depth_texture : source_color, hint_depth_texture;

void vertex() {
  POSITION = vec4(VERTEX, 1.0);
}

void fragment() {
	float depth = texture(depth_texture, SCREEN_UV).x;
	vec3 screen_color = texture(screen_texture, SCREEN_UV).xyz;
	vec3 ndc = vec3(SCREEN_UV * 2.0 - 1.0, depth);
	vec4 view = INV_PROJECTION_MATRIX * vec4(ndc, 1.0);
	view.xyz /= view.w;
	float linear_depth = -view.z;
	
	ALBEDO = vec3(depth * 0.01); 
	ALBEDO = screen_color; 
	// ALPHA = SCREEN_UV.x < 0.5 ? 1.0 : 0.0;
	ALPHA = 1.0;
	/*
	if( depth >= 1.0 )
	{
		ALPHA = 0.0;
	}*/
}

/*
void fragment() {
	// vec4 bg = texture(SCREEN_TEXTURE, SCREEN_UV);
	// COLOR = vec4(bg.r, 0.0, 0.0, 1.0);
  	float depth = texture(depth_texture, SCREEN_UV).x;
	vec3 ndc = vec3(SCREEN_UV * 2.0 - 1.0, depth);
	vec4 view = INV_PROJECTION_MATRIX * vec4(ndc, 1.0);
  	view.xyz /= view.w;
  	float linear_depth = -view.z;
	ALBEDO = vec3(linear_depth, linear_depth, linear_depth);
	ALPHA = 1.0;
}*/
