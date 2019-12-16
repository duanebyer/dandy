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
	private Field _pressure;

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
	public Field pressure {
		get { return this._pressure; }
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
			FieldBoundary.ANTI_OPEN, FieldBoundary.OPEN,
			FieldBoundary.OPEN, FieldBoundary.ANTI_OPEN);
		this._vel_next = new VectorField(
			this._count_x, this._count_y,
			this._cell_width, this._cell_height,
			FieldBoundary.ANTI_OPEN, FieldBoundary.OPEN,
			FieldBoundary.OPEN, FieldBoundary.ANTI_OPEN);
		this._pressure = new Field(
			this._count_x + 1, this._count_y + 1,
			this._cell_width, this._cell_height,
			FieldBoundary.OPEN, FieldBoundary.OPEN);
		this._viscosity = viscosity;
	}

	public void update(double delta) {
		this._vel.advect(delta, ref this._vel_next);
		Util.swap(ref this._vel, ref this._vel_next);
		this._vel.diffuse(this._viscosity, ref this._vel_next, true);
		Util.swap(ref this._vel, ref this._vel_next);
		this._vel.project(ref this._vel_next, ref this._pressure, true);
		Util.swap(ref this._vel, ref this._vel_next);
	}


}

}

