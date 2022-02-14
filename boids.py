from pathlib import Path
from tkinter import N
from tkinter.messagebox import NO
import numpy
import moderngl
import moderngl_window

rng = numpy.random.default_rng()
MAX_TEX_WIDTH = 3350
NUM_BOIDS = 3350


class Boids(moderngl_window.WindowConfig):
    title = "Boids"
    resource_dir = (Path(__file__) / '..').absolute()
    boids_vao = []
    boids_buffer = []
    id = 0
    boid_co_coef = 16
    mouse_key = None
    mouse_press_poz = None
    bombs = numpy.zeros(300, dtype=float)
    bombs = []


    def __init__(self, *args, **kwargs):
        super().__init__(*args, **kwargs)

        self.boids_texture = self.ctx.texture((NUM_BOIDS, 3), components=2, dtype='f4')
        self.boids_texture.use(location=0)

        self.ctx.enable_only(moderngl.PROGRAM_POINT_SIZE | moderngl.BLEND)

        self.boids_render_program = self.load_program('boids_render_short.glsl')
        self.bombs_render_program = self.load_program('bombs_render.glsl')
        self.boids_transform_program = self.load_program('boids_transform.glsl')
        self.boids_transform_program['num_boids'].value = NUM_BOIDS
        self.boids_transform_program['tex_width'].value = MAX_TEX_WIDTH
        self.boids_transform_program['boid_co_coef'].value = self.boid_co_coef
        self.bomb_vao = moderngl_window.opengl.vao.VAO(name='bomb', mode=moderngl.POINTS)
        self.bomb_vao.buffer(self.ctx.buffer(numpy.zeros(1)), '2f', ['in_position'])

        self.reset_scene()
        self.resize(0, 0)

    def reset_scene(self):
        data = rng.normal(0, 3, NUM_BOIDS * 6)
        self.boids_vao.clear()
        self.boids_buffer.clear()
        for _ in range(2):
            self.boids_vao.append(moderngl_window.opengl.vao.VAO(name='boids_v', mode=moderngl.POINTS))
            self.boids_buffer.append(self.ctx.buffer(data.astype('f4').tobytes()))
            self.boids_vao[-1].buffer(self.boids_buffer[-1], '2f 2f 2f', ['in_position', 'in_velocity', 'in_speed'])

    def render(self, time, frame_time):
        if self.bombs and self.bombs[0] == 0:
            self.bombs.pop(0)
            self.bombs_render_program['bomb_active'].value = 0
            self.boids_transform_program['bomb_active'].value = 0
        elif self.bombs and self.bombs[0][0] < self.timer.time:
            bomb_t, mouse_coord = self.bombs[0]
            self.boids_transform_program['bomb_poz'].write(mouse_coord)
            self.boids_transform_program['bomb_active'].value = 1
            self.bombs_render_program['bomb_active'].value = 1
            self.bombs[0] = 0
        
        self.boids_transform_program['timedelta'].value = frame_time  # max(frame_time, 1.0 / 60.0)
        self.boids_vao[self.id].transform(self.boids_transform_program, self.boids_buffer[1 - self.id])
        self.id = 1 - self.id
        self.boids_vao[self.id].render(self.boids_render_program)
        self.bomb_vao.render(self.bombs_render_program, vertices=1)
        self.boids_texture.write(self.boids_buffer[self.id].read())

    def mouse_drag_event(self, x: int, y: int, dx: int, dy: int):
        self.boid_co_coef *= 1 + dx / 1000
        self.boids_transform_program['boid_co_coef'].value = self.boid_co_coef
        self.wnd.title = f"Boids. C1 = {self.boid_co_coef:.3f}"

    def mouse_position_event(self, x: int, y: int, dx: int, dy: int):
        mouse_coord = (x - self.wnd.width / 2, self.wnd.height / 2 - y)
        poz_data = numpy.array(mouse_coord, dtype='f4') / min(self.wnd.size) * 2
        self.boids_render_program['mouse_poz'].write(poz_data)
        
    def mouse_press_event(self, x: int, y: int, button: int):
        if button == 1:
            self.mouse_key = 1
            self.mouse_press_poz = x, y
    
    def mouse_release_event(self, x: int, y: int, button: int):
        if self.mouse_key == 1:
            if abs(self.mouse_press_poz[0] - x) < 10 and abs(self.mouse_press_poz[1] - y) < 10:
                mouse_coord = (x - self.wnd.width / 2, self.wnd.height / 2 - y)
                poz_data = numpy.array(mouse_coord, dtype='f4') / min(self.wnd.size) * 2
                self.bombs.append((self.timer.time + 1, poz_data))
                self.bombs_render_program['bomb_poz'].write(poz_data)
                self.bombs_render_program['bomb_active'].value = 1

    def key_event(self, key, action, modifiers):
        if key == self.wnd.keys.R and action == self.wnd.keys.ACTION_RELEASE:
            self.reset_scene()
            print("Reset")

    def resize(self, width: int, height: int):
        screen_scale = min(self.wnd.size) / numpy.array(self.wnd.size, dtype='f4')
        self.boids_render_program['screen_scale'].write(screen_scale)
        self.bombs_render_program['screen_scale'].write(screen_scale)


if __name__ == '__main__':
    moderngl_window.run_window_config(Boids)
