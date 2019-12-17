namespace Dandy.Actor {

using Dandy;

internal class Air : Clutter.Actor {
	private Physics.Air _air_physics;
	private Clutter.Canvas _canvas;
	private TimeoutSource _timeout;
	private Timer _timer;
	private Timer _mouse_timer;
	private Util.Vector _prev_mouse_pos;

	private const double DELTA = 0.05;
	private const double CELL_SIZE = 50;
	private const double VISCOSITY = 100.0;

	public Physics.Air physics {
		get { return this._air_physics; }
	}

	public Air(double width, double height, bool draw = false) {
		int pix_width = (int) Math.ceil(width);
		int pix_height = (int) Math.ceil(height);
		this._air_physics = new Physics.Air(VISCOSITY, width, height, CELL_SIZE);
		this._canvas = null;

		// The timer is used to provide more precise deltas to the simulation.
		this._timer = new Timer();
		this._timeout = new TimeoutSource((int) (Air.DELTA * 1000));
		this._timer.start();
		this._timeout.set_callback(() => {
			this.on_step(this._timer.elapsed());
			this._timer.start();
			return Source.CONTINUE;
		});
		this._timeout.attach(null);

		// Add wind on a mouse movement over the air.
		this._mouse_timer = new Timer();
		base.set_reactive(true);
		base.enter_event.connect((actor, e) => {
			float mouse_x;
			float mouse_y;
			base.transform_stage_point(e.x, e.y, out mouse_x, out mouse_y);
			this._prev_mouse_pos = Util.Vector(mouse_x, mouse_y);
			this._mouse_timer.start();
			return false;
		});
		base.motion_event.connect((actor, e) => {
			float mouse_x;
			float mouse_y;
			base.transform_stage_point(e.x, e.y, out mouse_x, out mouse_y);
			Util.Vector mouse_pos = Util.Vector(mouse_x, mouse_y);
			double delta = this._mouse_timer.elapsed();
			this.on_mouse_move(mouse_pos, this._prev_mouse_pos, delta);
			this._prev_mouse_pos = mouse_pos;
			this._mouse_timer.start();
			return false;
		});

		if (draw) {
			this._canvas = new Clutter.Canvas() {
				width = pix_width,
				height = pix_height
			};
			this._canvas.draw.connect((canvas, ctx, width, height) => {
				this.on_draw(ctx);
				return false;
			});
			this._canvas.invalidate();
			base.set_content(this._canvas);
			base.set_size(pix_width, pix_height);
		}
	}

	private void on_draw(Cairo.Context ctx) {
		Physics.VectorField vel_field = this._air_physics.velocity;

		// Clear the existing canvas content.
		ctx.save();
		ctx.set_operator(Cairo.Operator.SOURCE);
		ctx.set_source_rgba(0, 0, 0, 0);
		ctx.paint();
		ctx.restore();

		// Draw velocity vectors.
		ctx.save();
		ctx.translate(0.5 * vel_field.cell_width, 0.5 * vel_field.cell_height);
		ctx.new_path();
		for (int j = 0; j < vel_field.count_y; ++j) {
			ctx.save();
			for (int i = 0; i < vel_field.count_x; ++i) {
				Util.Vector vel = vel_field.get_index(i, j);
				ctx.move_to(0, 0);
				ctx.line_to(vel.x, vel.y);
				ctx.translate(vel_field.cell_width, 0);
			}
			ctx.restore();
			ctx.translate(0, vel_field.cell_height);
		}
		ctx.set_source_rgb(1, 0, 0);
		ctx.set_line_width(2);
		ctx.stroke();
		ctx.restore();
	}

	public void on_step(double delta) {
		delta = delta.clamp(0, 2 * Air.DELTA);
		this._air_physics.update(delta);
		if (this._canvas != null) {
			this._canvas.invalidate();
		}
	}

	public void on_mouse_move(
			Util.Vector pos,
			Util.Vector prev_pos,
			double delta) {
		Util.Vector delta_pos = pos.sub(prev_pos);
		this._air_physics.velocity.add_pos(pos, delta_pos.scale(1 / delta));
	}
}

}

