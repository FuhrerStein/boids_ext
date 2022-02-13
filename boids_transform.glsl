#version 330

#if defined VERTEX_SHADER

in vec2 in_position;
in vec2 in_velocity;
in vec2 in_speed;

out vec2 out_position;
out vec2 out_velocity;
out vec2 out_speed;

uniform sampler2D data;
uniform float timedelta;
uniform int num_boids;
uniform int tex_width;
uniform float boid_co_coef;
uniform vec2 mouse_poz;

const float MAX_SPEED = 0.3;

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

    for (int i = 0; i < num_boids; i++) {
        if (i == gl_VertexID) {
            continue;
        }
        read_boid(tmp_pos, tmp_vel, i);
        float dist = distance(in_position, tmp_pos);
        gravity = 1 - smoothstep(0, 1, dist);
        boid_vel += tmp_vel * gravity;
        boid_co += tmp_pos * gravity * boid_co_coef;
        sum_veight += gravity;
    }
    boid_vel /= sum_veight * 500;
    boid_co /= sum_veight;
    boid_vel += in_position - boid_co;
    float poz_corr_x = smoothstep(0, 1, -in_position.x - .8) - smoothstep(0, 1, in_position.x - .8);
    float poz_corr_y = smoothstep(0, 1, -in_position.y - .8) - smoothstep(0, 1, in_position.y - .8);
    boid_vel += vec2(poz_corr_x, poz_corr_y) * 100;

    float speed = length(boid_vel);
    boid_vel *= mix(1, MAX_SPEED / speed, 1 - MAX_SPEED / speed);
    
    out_position = in_position + boid_vel * timedelta;
    out_velocity = in_velocity + boid_vel;
    out_speed = mix(boid_vel, in_speed, .9);
}

#endif
