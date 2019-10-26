namespace Dandy.Physics {

using Dandy;

public enum BoundaryCondition {
	FIXED,
	OPEN,
	ANTI_OPEN,
	PERIODIC,
	ANTI_PERIODIC
}

public class Field : Object {
	private double[,] _vals;
	private double _cell_width;
	private double _cell_height;
	private BoundaryCondition _boundary_x;
	private BoundaryCondition _boundary_y;

	public uint count_x {
		get { return this._vals.length[0]; }
	}
	public uint count_y {
		get { return this._vals.length[1]; }
	}

	public double cell_width {
		get { return this._cell_width; }
		set { this._cell_width = value; }
	}
	public double cell_height {
		get { return this._cell_height; }
		set { this._cell_height = value; }
	}

	public BoundaryCondition boundary_x {
		get { return this._boundary_x; }
		set { this._boundary_x = value; }
	}
	public BoundaryCondition boundary_y {
		get { return this._boundary_y; }
		set { this._boundary_y = value; }
	}

	public Field(
			uint count_x, uint count_y,
			double cell_width, double cell_height,
			BoundaryCondition boundary_x = BoundaryCondition.FIXED,
			BoundaryCondition boundary_y = BoundaryCondition.FIXED) {
		this._vals = new double[count_x + 2, count_y + 2];
		this._cell_width = cell_width;
		this._cell_height = cell_height;
		this._boundary_x = boundary_x;
		this._boundary_y = boundary_y;
		for (uint j = 1; j < count_x + 1; ++j) {
			for (uint i = 1; i < count_y + 1; ++i) {
				this._vals[i, j] = 0;
			}
		}
		this.update_boundaries();
	}

	public double get_index(uint i, uint j) {
		return this._vals[i + 1, j + 1];
	}

	public void set_index(uint i, uint j, double value) {
		this._vals[i + 1, j + 1] = value;
	}

	public double get_pos(Util.Vector pos) {
		uint i;
		uint j;
		double x = Math.remquo(pos.x, this._cell_width, out i);
		double y = Math.remquo(pos.y, this._cell_height, out j);
		i += 1;
		j += 1;
		return Util.lerp_2(
			this._vals[i, j],
			this._vals[i + 1, j],
			this._vals[i, j + 1],
			this._vals[i + 1, j + 1],
			x / this._cell_width, y / this._cell_height);
	}

	// Returns the x gradient of the field at the point (i + 0.5, y).
	public double gradient_x(uint i, uint j) {
		return (this.get_index(i + 1, j) - this.get_index(i, j)) / this._cell_width;
	}

	// Returns the y gradient of the field at the point (i, j + 0.5).
	public double gradient_y(uint i, uint j) {
		return (this.get_index(i, j + 1) - this.get_index(i, j)) / this._cell_height;
	}

	public double laplacian(uint i, uint j) {
		return (
				-4 * this.get_index(i, j)
				+ this.get_index(i - 1, j) + this.get_index(i + 1, j)
				+ this.get_index(i, j - 1) + this.get_index(i, j + 1))
			/ (this._cell_width * this._cell_height);
	}

	public void update_boundaries() {
		uint nx = this._vals.length[0];
		uint ny = this._vals.length[1];
		for (uint i = 1; i < nx - 1; ++i) {
			double value_1 = this._vals[i, 1];
			double value_2 = this._vals[i, ny - 2];
			double boundary_1 = 0;
			double boundary_2 = 0;
			switch (this._boundary_y) {
			case BoundaryCondition.FIXED:
				boundary_1 = 0;
				boundary_2 = 0;
				break;
			case BoundaryCondition.OPEN:
				boundary_1 = value_1;
				boundary_2 = value_2;
				break;
			case BoundaryCondition.ANTI_OPEN:
				boundary_1 = -value_1;
				boundary_2 = -value_2;
				break;
			case BoundaryCondition.PERIODIC:
				boundary_1 = value_2;
				boundary_2 = value_1;
				break;
			case BoundaryCondition.ANTI_PERIODIC:
				boundary_1 = -value_2;
				boundary_2 = -value_1;
				break;
			}
			this._vals[i, 0] = boundary_1;
			this._vals[i, ny - 1] = boundary_2;
		}

		for (uint j = 1; j < ny - 1; ++j) {
			double value_1 = this._vals[1, j];
			double value_2 = this._vals[nx - 2, j];
			double boundary_1 = 0;
			double boundary_2 = 0;
			switch (this._boundary_x) {
			case BoundaryCondition.FIXED:
				boundary_1 = 0;
				boundary_2 = 0;
				break;
			case BoundaryCondition.OPEN:
				boundary_1 = value_1;
				boundary_2 = value_2;
				break;
			case BoundaryCondition.ANTI_OPEN:
				boundary_1 = -value_1;
				boundary_2 = -value_2;
				break;
			case BoundaryCondition.PERIODIC:
				boundary_1 = value_2;
				boundary_2 = value_1;
				break;
			case BoundaryCondition.ANTI_PERIODIC:
				boundary_1 = -value_2;
				boundary_2 = -value_1;
				break;
			}
			this._vals[0, j] = boundary_1;
			this._vals[nx - 1, j] = boundary_2;
		}

		// Set the corner cells to an average of the ones bordering it.
		this._vals[0, 0] =
			0.5 * (this._vals[0, 1] + this._vals[1, 0]);
		this._vals[nx - 1, 0] =
			0.5 * (this._vals[nx - 1, 1] + this._vals[nx - 2, 0]);
		this._vals[0, ny - 1] =
			0.5 * (this._vals[0, ny - 2] + this._vals[1, ny - 1]);
		this._vals[nx - 1, ny - 1] =
			0.5 * (this._vals[nx - 1, ny - 2] + this._vals[nx - 2, ny - 1]);
	}
}

public class VectorField : Object {
	private Field _field_x;
	private Field _field_y;

	public uint count_x {
		get { return this._field_x.count_x; }
	}
	public uint count_y {
		get { return this._field_x.count_y; }
	}

	public double cell_width {
		get { return this._field_x.cell_width; }
		set {
			this._field_x.cell_width = value;
			this._field_y.cell_width = value;
		}
	}
	public double cell_height {
		get { return this._field_x.cell_height; }
		set {
			this._field_x.cell_height = value;
			this._field_y.cell_height = value;
		}
	}

	public Field x {
		get { return this._field_x; }
	}
	public Field y {
		get { return this._field_y; }
	}

	public VectorField(
			uint count_x, uint count_y,
			double cell_width, double cell_height,
			BoundaryCondition boundary_xx = BoundaryCondition.FIXED,
			BoundaryCondition boundary_xy = BoundaryCondition.OPEN,
			BoundaryCondition boundary_yx = BoundaryCondition.OPEN,
			BoundaryCondition boundary_yy = BoundaryCondition.FIXED) {
		this._field_x = new Field(
			count_x, count_y,
			cell_width, cell_height,
			boundary_xx, boundary_xy);
		this._field_y = new Field(
			count_x, count_y,
			cell_width, cell_height,
			boundary_yx, boundary_yy);
	}

	public Util.Vector get_index(uint i, uint j) {
		return Util.Vector(
			this._field_x.get_index(i, j),
			this._field_y.get_index(i, j));
	}

	public void set_index(uint i, uint j, Util.Vector value) {
		this._field_x.set_index(i, j, value.x);
		this._field_y.set_index(i, j, value.y);
	}

	public Util.Vector get_pos(Util.Vector pos) {
		return Util.Vector(
			this._field_x.get_pos(pos),
			this._field_y.get_pos(pos));
	}

	public Util.Vector gradient_x(uint i, uint j) {
		return Util.Vector(
			this._field_x.gradient_x(i, j),
			this._field_y.gradient_x(i, j));
	}

	public Util.Vector gradient_y(uint i, uint j) {
		return Util.Vector(
			this._field_x.gradient_y(i, j),
			this._field_y.gradient_y(i, j));
	}

	public Util.Vector laplacian(uint i, uint j) {
		return Util.Vector(
			this._field_x.laplacian(i, j),
			this._field_y.laplacian(i, j));
	}

	public double divergence(uint i, uint j) {
		double div_x_1 = this._field_x.gradient_x(i, j);
		double div_x_2 = this._field_x.gradient_x(i, j + 1);
		double div_y_1 = this._field_y.gradient_y(i, j);
		double div_y_2 = this._field_y.gradient_y(i + 1, j);
		return 0.5 * (div_x_1 + div_x_2 + div_y_1 + div_y_2);
	}

	public void update_boundaries() {
		this._field_x.update_boundaries();
		this._field_y.update_boundaries();
	}
}

}

