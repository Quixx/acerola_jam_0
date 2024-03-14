shader_type canvas_item;

uniform lowp sampler2D screen_texture : hint_screen_texture, filter_nearest_mipmap, repeat_enable;
uniform lowp float alpha : hint_range(0.0, 1.0);
uniform lowp float scale : hint_range(0.0, 2.0);

uniform float vignette_intensity = 0.4;
uniform float vignette_opacity : hint_range(0.0, 1.0) = 0.5;

uniform lowp float red_shift;
uniform lowp float blue_shift;
uniform lowp float green_shift;

uniform lowp float red_mult = 1;

float vignette(vec2 uv){
	uv *= 1.0 - uv.xy;
	float vignette = uv.x * uv.y * 15.0;
	return pow(vignette, vignette_intensity * vignette_opacity);
}

void fragment() {
	vec2 uvs = SCREEN_UV * scale;
	vec4 final_texture  = texture(screen_texture, uvs);
	
	float r = texture(screen_texture, uvs + vec2(SCREEN_PIXEL_SIZE*red_shift), 0.0).r * red_mult;
	float g = texture(screen_texture, uvs + vec2(SCREEN_PIXEL_SIZE*green_shift), 0.0).g;
	float b = texture(screen_texture, uvs + vec2(SCREEN_PIXEL_SIZE*blue_shift), 0.0).b;
	
	float str = 1.0 - vignette(SCREEN_UV);
	vec3 screen_color = vec3(r - str, g - str, b - str);
	// vec3 vignette = vignette_rgb.rgb * (1.0 - vignette(SCREEN_UV));
	// screen_color *= vignette;
	
	COLOR = vec4(screen_color.rgb, alpha);
}