namespace Dandy.Actor {

using Dandy;

internal class Air : Clutter.Actor {
	private Physics.Air _air_physics;
	private Clutter.Canvas _canvas;
	private TimeoutSource _timeout;
	private Timer _timer;
	private Timer _mouse_timer;
	private Util.Vector _prev_mouse_pos;
	private bool _mouse_enter;

	// TODO: Rename some of these constants, and possibly move some to the Main
	// class.
	private const double CELL_SIZE = 50;
	private const double VISCOSITY = 5e2;
	private const double DAMPING = 0.5;
	private const double MOTION_WIND_STRENGTH = 0.4;
	private const double MOTION_WIND_RADIUS = 50;
	private const double MOTION_MAX_SPEED = 500;
	private const double CLICK_SMOKE_AMOUNT = 5;

	public Physics.Air physics {
		get { return this._air_physics; }
	}

	public Air(double width, double height, bool draw = false) {
		int pix_width = (int) Math.ceil(width);
		int pix_height = (int) Math.ceil(height);
		this._air_physics = new Physics.Air(
			VISCOSITY,
			DAMPING,
			width, height,
			CELL_SIZE);
		this._canvas = null;
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

	public void update(double delta) {
		this.update_physics(delta);
		this.update_visuals();
	}

	public void update_physics(double delta) {
		this._air_physics.update(delta);
	}

	public void update_visuals() {
		if (this._canvas != null) {
			this._canvas.invalidate();
		}
	}

	public void inject_wind(
			Util.Vector pos_start,
			Util.Vector pos_end,
			double delta) {
		Physics.VectorField vel_field = this._air_physics.velocity;
		Util.Vector pos_delta = pos_end.sub(pos_start);
		if (pos_delta.norm() == 0 || delta <= 0) {
			return;
		}
		int padding = (int) Math.ceil(
			3 * Air.MOTION_WIND_RADIUS / double.max(
				vel_field.cell_width,
				vel_field.cell_height));
		// Find the starting and ending cells of the motion.
		int i1;
		int j1;
		vel_field.local_cell_pos(pos_start, out i1, out j1);
		int i2;
		int j2;
		vel_field.local_cell_pos(pos_end, out i2, out j2);
		int i_min = int.min(i1, i2) - padding;
		int i_max = int.max(i1, i2) + padding;
		int j_min = int.min(j1, j2) - padding;
		int j_max = int.max(j1, j2) + padding;
		double sigma = Air.MOTION_WIND_RADIUS;
		double peak = 0.5 * Air.MOTION_WIND_STRENGTH;
		Util.Vector velocity = pos_delta.scale(1 / delta)
			.clamp(Air.MOTION_MAX_SPEED);
		for (int i = i_min; i <= i_max; ++i) {
			for (int j = j_min; j <= j_max; ++j) {
				// Apply a force to every cell along the path from the previous
				// position to the current position.
				Util.Vector cell_pos = Util.Vector(
					(i + 0.5) * vel_field.cell_width,
					(j + 0.5) * vel_field.cell_height);
				Util.Vector r = cell_pos.sub(pos_start);
				Util.Vector r_par = r.project(pos_delta);
				Util.Vector r_perp = r.sub(r_par);
				r = Util.Vector(r_par.norm(), r_perp.norm());
				double x_factor = Math.erf(r.x / (Math.sqrt(2) * sigma))
					- Math.erf((r.x - pos_delta.norm()) / (Math.sqrt(2) * sigma));
				double y_factor = Math.exp(-0.5 * r.y * r.y / (sigma * sigma));
				double factor = peak * x_factor * y_factor;
				vel_field.add_index(i, j, velocity.scale(factor));
			}
		}
	}

	public void inject_smoke(Util.Vector pos) {
		this._air_physics.smoke.add_pos(pos, Air.CLICK_SMOKE_AMOUNT);
	}

	private void on_draw(Cairo.Context ctx) {
		Physics.VectorField vel_field = this._air_physics.velocity;

		// Clear the existing canvas content.
		ctx.save();
		ctx.set_operator(Cairo.Operator.SOURCE);
		ctx.set_source_rgba(0, 0, 0, 0);
		ctx.paint();
		ctx.restore();

		// Draw smoke.
		ctx.save();
		for (int j = 0; j < vel_field.count_y; ++j) {
			ctx.save();
			for (int i = 0; i < vel_field.count_x; ++i) {
				double smoke = this._air_physics.smoke.get_index(i, j);
				ctx.set_source_rgba(0, 0, 0, smoke);
				ctx.rectangle(0, 0, vel_field.cell_width, vel_field.cell_height);
				ctx.fill();
				ctx.translate(vel_field.cell_width, 0);
			}
			ctx.restore();
			ctx.translate(0, vel_field.cell_height);
		}
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
}

}

