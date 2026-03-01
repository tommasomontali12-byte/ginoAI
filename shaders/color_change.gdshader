shader_type canvas_item;

// Controlli RGB
uniform float red_factor : hint_range(0.0, 2.0) = 1.0;
uniform float green_factor : hint_range(0.0, 2.0) = 1.0;
uniform float blue_factor : hint_range(0.0, 2.0) = 1.0;

// Controlli Saturazione, Contrasto, Luminosità e HUE
uniform float saturation : hint_range(0.0, 2.0) = 1.0;
uniform float brightness : hint_range(-1.0, 1.0) = 0.0;
uniform float contrast : hint_range(0.0, 2.0) = 1.0;
uniform float hue_shift : hint_range(-1.0, 1.0) = 0.0;
uniform float gamma : hint_range(0.1, 3.0) = 1.0;

// === RGB -> HSL ===
vec3 rgb2hsl(vec3 color) {
	float max_color = max(max(color.r, color.g), color.b);
	float min_color = min(min(color.r, color.g), color.b);
	float delta = max_color - min_color;
	
	float lightness = (max_color + min_color) * 0.5;
	float hue = 0.0;
	float sat = 0.0;
	
	// === STATMENTS ===
	if (delta > 0.0) {
		sat = (lightness < 0.5) ? (delta / (max_color + min_color)) : (delta / (2.0 - max_color - min_color));
		if (max_color == color.r) {
			hue = (color.g - color.b) / delta + (color.g < color.b ? 6.0 : 0.0);
		} else if (max_color == color.g) {
			hue = (color.b - color.r) / delta + 2.0;
		} else {
			hue = (color.r - color.g) / delta + 4.0;
		}
		hue /= 6.0;
	}
	return vec3(hue, sat, lightness);
}

// HSL -> RGB 
vec3 hsl2rgb(vec3 hsl) {
	float hue = hsl.x;
	float sat = hsl.y;
	float lightness = hsl.z;
	
	float chroma = (1.0 - abs(2.0 * lightness - 1.0)) * sat;
	float h = hue * 6.0;
	float x = chroma * (1.0 - abs(mod(h, 2.0) - 1.0));
	
	// Result
	vec3 result;
	
	if (h < 1.0) result = vec3(chroma, x, 0.0);
	else if (h < 2.0) result = vec3(x, chroma, 0.0);
	else if (h < 3.0) result = vec3(0.0, chroma, x);
	else if (h < 4.0) result = vec3(0.0, x, chroma);
	else if (h < 5.0) result = vec3(x, 0.0, chroma);
	else result = vec3(chroma, 0.0, x);
	
	// dati
	float m = lightness - chroma * 0.5;
	
	return result + vec3(m);
}

void fragment() {
	// Usiamo la texture dello Sprite2D
	vec4 tex_color = texture(TEXTURE, UV);
	
	// RGB Multipliers
	tex_color.r *= red_factor;
	tex_color.g *= green_factor;
	tex_color.b *= blue_factor;
	
	// Convert to HSL
	vec3 hsl = rgb2hsl(tex_color.rgb);
	
	// HUE Shift & Saturation
	hsl.x = mod(hsl.x + hue_shift, 1.0);
	hsl.y *= saturation;
	
	// To RGB
	vec3 final_rgb = hsl2rgb(hsl);
	
	// BRIGHTNESS, CONTRAS, GAMMA
	final_rgb = final_rgb * contrast + vec3(brightness);
	final_rgb = pow(final_rgb, vec3(gamma));
	
	COLOR = vec4(final_rgb, tex_color.a);
}
