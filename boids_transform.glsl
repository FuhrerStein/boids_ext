#version 330

#if defined VERTEX_SHADER

in vec2 in_position;
in vec2 in_speed;

out vec2 out_position;
out vec2 out_speed;

uniform sampler2D data;
uniform float timedelta;
uniform int num_boids;
uniform int tex_width;
uniform float boid_co_coef;
uniform vec2 mouse_poz;
uniform vec2 bomb_poz;
uniform float bomb_active;
uniform vec2 screen_scale;

const float MAX_SPEED = 0.4;

void read_boid(out vec2 pos, out vec2 vel, int i) {
    vec4 pos_vel = texelFetch(data, ivec2(i % tex_width, i / num_boids), 0);
    pos = pos_vel.rg;
    vel = pos_vel.ba;
}

void main() {
    vec2 tmp_pos = vec2(0.0);
    vec2 tmp_vel = vec2(0.0);

    vec2 boid_co = vec2(0.0);
    vec2 boid_vel = vec2(0.0);

    float sum_veight = 0.1;
    float gravity = 0.;
    float dist;

    for (int i = 0; i < num_boids; i++) {
        if (i == gl_VertexID) {continue;}
        read_boid(tmp_pos, tmp_vel, i);
        dist = distance(in_position, tmp_pos);
        // gravity = 1 - smoothstep(0, 3, dist * dist) - smoothstep(0, 1, 1 - dist * dist * dist);        
        gravity = 1 / dist * dist - 1 / dist * dist * dist;        
        // gravity = 1;
        // boid_co += (tmp_pos - in_position) * gravity + tmp_vel * gravity / 2000000;
        boid_co += (tmp_pos - in_position) * gravity;
        sum_veight += gravity;
    }
    boid_vel = in_speed + boid_co * boid_co_coef / sum_veight / 10000;
    // boid_vel += smoothstep(0, 1.5, -in_position * screen_scale - .4) * 20;
    boid_vel += smoothstep(0, 1.5, -in_position * screen_scale - .4) * .20;
    boid_vel -= smoothstep(0, 1.5, in_position * screen_scale - .4) * .20;

    float speed = length(boid_vel);
    // boid_vel *= mix(1, MAX_SPEED / speed, 1 - MAX_SPEED / speed / 15);

    dist = distance(in_position, bomb_poz);
    gravity = 1 - smoothstep(0, 1, dist);
    boid_vel += (in_position - bomb_poz) * gravity * gravity * 150 * bomb_active;
    
    out_position = in_position + boid_vel * timedelta;
    out_speed = mix(boid_vel, in_speed, .9);
}

#endif
