#version 330

#if defined VERTEX_SHADER

in vec2 in_position;
in vec2 in_speed;
uniform vec2 mouse_poz;
uniform vec2 screen_scale;
out vec4 vert_color;
out vec2 out_velocity;

void main() {
	gl_Position = vec4(screen_scale * in_position, 1.0, 1.0);
    gl_PointSize = 55.0;
    vert_color = mod(vec4(7, 13, 23, 1) * gl_VertexID, 180) / 225 + .2;
    out_velocity = vec2(-1, 0) * in_speed * length(in_speed);
    gl_PointSize -= 30 * smoothstep(0, 1, 1 - length(mouse_poz - in_position) * 2);
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
    float speed_factor = dot(rel_point_coord, out_velocity * 4);
    outColor.a = 1.4 - len_sq * 7 - pow(len_from_center, 4 * speed_factor + 1.2) * 15;
}

#endif

