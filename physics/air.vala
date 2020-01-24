namespace Dandy.Physics {

using Dandy;

internal class Air {
	// The viscosity has units of [L]^2/[T].
	private double _viscosity;
	// The damping factor has natural units, and indicates how quickly velocity
	// of the fluid dies out relative to the viscosity.
	private double _damping;

	private VectorField _vel;
	private VectorField _vel_next;

	private Field _pressure;
	private Field _vel_divergence;

	// TODO: Smoke for testing the behaviour of the fluid simulation.
	private Field _smoke;
	private Field _smoke_next;

	public double viscosity {
		get { return this._viscosity; }
	}

	public Util.Bounds bounds {
		get { return this._vel.bounds; }
	}
	public double width {
		get { return this._vel.width; }
	}
	public double height {
		get { return this._vel.height; }
	}
	public double area {
		get { return this._vel.area; }
	}

	public VectorField velocity {
		get { return this._vel; }
	}

	public Field pressure {
		get { return this._pressure; }
	}

	public Field smoke {
		get { return this._smoke; }
	}

	public Air(
			double viscosity,
			double damping,
			double width, double height,
			double max_cell_size) {
		this._viscosity = viscosity;
		this._damping = damping;
		uint count_x = (uint) Math.ceil(width / max_cell_size);
		uint count_y = (uint) Math.ceil(height / max_cell_size);
		this._vel = new VectorField(
			count_x, count_y,
			width, height,
			FieldBoundary.PERIODIC, FieldBoundary.OPEN,
			FieldBoundary.PERIODIC, FieldBoundary.FIXED);
		this._vel_next = new VectorField.clone(this._vel);
		this._pressure = new Field(
			count_x + 1, count_y + 1,
			width + this._vel.cell_width, height + this._vel.cell_height,
			FieldBoundary.OPEN, FieldBoundary.OPEN);
		this._vel_divergence = new Field.clone(this._pressure);
		this._smoke = new Field(
			count_x, count_y,
			width, height,
			FieldBoundary.PERIODIC, FieldBoundary.OPEN);
		this._smoke_next = new Field.clone(this._smoke);
	}

	public void update(double delta) {
		// Update smoke through advection and diffusion.
		this._smoke.advect_in_field(ref this._smoke_next, this._vel, delta);
		Util.swap(ref this._smoke, ref this._smoke_next);
		this._smoke.poisson_solve_in_field(
			ref this._smoke_next,
			-delta * this._viscosity,
			1);
		Util.swap(ref this._smoke, ref this._smoke_next);

		// Update velocity through advection, diffusion, and projection.
		this._vel.advect_in_field(ref this._vel_next, this._vel, delta);
		Util.swap(ref this._vel, ref this._vel_next);
		this._vel.poisson_solve_in_field(
			ref this._vel_next,
			-delta * this._viscosity,
			1 + 2 * delta * this._damping * this._viscosity / this._vel.cell_area);
		Util.swap(ref this._vel, ref this._vel_next);
		this._vel.project_in_field(
			ref this._vel_next,
			ref this._pressure,
			ref this._vel_divergence);
		Util.swap(ref this._vel, ref this._vel_next);
	}


}

}

