namespace Dandy.Physics {

using Dandy;

internal class Air {
	private double _viscosity;

	private double _width;
	private double _height;
	private uint _count_x;
	private uint _count_y;
	private double _cell_width;
	private double _cell_height;

	private VectorField _vel;
	private VectorField _vel_next;
	private VectorField _vel_laplacian;

	public double viscosity {
		get { return this._viscosity; }
		set { this._viscosity = value; }
	}

	public Util.Bounds bounds {
		get { return Util.Bounds(0, 0, this._width, this._height); }
	}
	public double width {
		get { return this._width; }
	}
	public double height {
		get { return this._height; }
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
		this._width = width;
		this._height = height;
		this._count_x = (uint) Math.ceil(this._width / max_cell_size);
		this._count_y = (uint) Math.ceil(this._height / max_cell_size);
		this._cell_width = this._width / this._count_x;
		this._cell_height = this._height / this._count_y;
		this._vel = new VectorField(
			this._count_x, this._count_y,
			this._cell_width, this._cell_height,
			FieldBoundary.OPEN, FieldBoundary.OPEN,
			FieldBoundary.OPEN, FieldBoundary.FIXED);
		this._vel_next = new VectorField.clone(this._vel);
		this._vel_laplacian = new VectorField.clone(this._vel);
		this._viscosity = viscosity;
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

