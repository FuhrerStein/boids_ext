#version 330

#if defined VERTEX_SHADER

in vec2 in_position;
uniform vec2 screen_scale;
out vec4 vert_color;
out vec2 out_velocity;
uniform vec2 bomb_poz;
uniform float bomb_active;

void main() {
	gl_Position = vec4(screen_scale * bomb_poz, 1.0, 1.0);
    gl_PointSize = 55.0;
    vert_color = vec4(1);
    vert_color.a = bomb_active;
}

#elif defined FRAGMENT_SHADER

in vec2 out_velocity;
in vec4 vert_color;
out vec4 outColor;

void main() {
    outColor = vert_color;
    vec2 rel_point_coord = gl_PointCoord.xy - .5;
    float len_from_center = length(rel_point_coord);
    float len_sq = pow(len_from_center, 2);
    outColor.a *= 1.4 - len_sq * 8;
}

#endif

