namespace Dandy.Physics {

using Dandy;

internal class Air {
	private double _viscosity;

	private VectorField _vel;
	private VectorField _vel_next;
	private VectorField _vel_laplacian;

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
	public VectorField velocity_laplacian {
		get { return this._vel_laplacian; }
	}

	public Air(
			double viscosity,
			double width, double height,
			double max_cell_size) {
		this._viscosity = viscosity;
		uint count_x = (uint) Math.ceil(width / max_cell_size);
		uint count_y = (uint) Math.ceil(height / max_cell_size);
		this._vel = new VectorField(
			count_x, count_y,
			width, height,
			FieldBoundary.OPEN, FieldBoundary.OPEN,
			FieldBoundary.OPEN, FieldBoundary.FIXED);
		this._vel_next = new VectorField.clone(this._vel);
		this._vel_laplacian = new VectorField.clone(this._vel);
	}

	public void update(double delta) {
		this._vel.advect_in_field(ref this._vel_next, this._vel, delta);
		Util.swap(ref this._vel, ref this._vel_next);
		this._vel.diffuse_in_field(ref this._vel_next, delta, this._viscosity);
		Util.swap(ref this._vel, ref this._vel_next);
		this._vel.project_in_field(ref this._vel_next, ref this._vel_laplacian);
		Util.swap(ref this._vel, ref this._vel_next);
	}


}

}

