shader_type canvas_item;

uniform sampler2D SCREEN_TEXTURE : hint_screen_texture, filter_linear_mipmap;
uniform float water_top : hint_range(0.0, 1.0) = 0.6;

void fragment() {
    vec2 uv = SCREEN_UV;
    
    uv.y = 2.0 * water_top - SCREEN_UV.y;
    
    uv.x += sin(SCREEN_UV.y * 20.0 + TIME * 2.0) * 0.003;
    
    vec4 reflection = texture(SCREEN_TEXTURE, uv);
    COLOR = vec4(mix(reflection.rgb, vec4(0.0, 0.2, 0.4, 1.0).rgb, 0.15), 0.6);
}