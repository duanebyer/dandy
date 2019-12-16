namespace Dandy.Physics {

using Dandy;

internal enum FieldBoundary {
	FIXED,
	OPEN,
	ANTI_OPEN,
	PERIODIC,
	ANTI_PERIODIC
}

internal class Field {
	private double[,] _vals;
	private FieldBoundary _boundary_x;
	private FieldBoundary _boundary_y;
	private double _cell_width;
	private double _cell_height;

	// Note that vals contains the boundary cells as well as the cells in the
	// bulk of the field. Generally, it is better to directly use the accessor
	// methods. If this property is used, then the boundaries must be updated.
	public double[,] vals {
		get { return this._vals; }
	}

	public Util.Bounds bounds {
		get { return Util.Bounds(0, 0, this.width, this.height); }
	}
	public double width {
		get { return this.count_x * this._cell_width; }
	}
	public double height {
		get { return this.count_y * this._cell_height; }
	}

	public uint count_x {
		get { return this._vals.length[0] - 2; }
	}
	public uint count_y {
		get { return this._vals.length[1] - 2; }
	}

	public double cell_width {
		get { return this._cell_width; }
	}
	public double cell_height {
		get { return this._cell_height; }
	}
	public double cell_area {
		get { return this._cell_width * this._cell_height; }
	}

	public FieldBoundary boundary_x {
		get { return this._boundary_x; }
	}
	public FieldBoundary boundary_y {
		get { return this._boundary_y; }
	}

	public Field.clone(Field other) {
		this._vals = new double[other._vals.length[0], other._vals.length[1]];
		this._cell_width = other._cell_width;
		this._cell_height = other._cell_height;
		this._boundary_x = other._boundary_x;
		this._boundary_y = other._boundary_y;
		this.copy_from(other);
	}

	public Field(
			uint count_x, uint count_y,
			double cell_width, double cell_height,
			FieldBoundary boundary_x = FieldBoundary.FIXED,
			FieldBoundary boundary_y = FieldBoundary.FIXED) {
		assert(count_x > 0 && count_y > 0);
		this._vals = new double[count_x + 2, count_y + 2];
		this._cell_width = cell_width;
		this._cell_height = cell_height;
		this._boundary_x = boundary_x;
		this._boundary_y = boundary_y;
		this.zero();
	}

	// Returns whether this field has the same parameters as another field.
	public bool compatible(Field other) {
		return this._vals.length[0] == other._vals.length[0]
			&& this._vals.length[1] == other._vals.length[1]
			&& this._cell_width == other._cell_width
			&& this._cell_height == other._cell_height
			&& this._boundary_x == other._boundary_x;
	}

	// Copies the data from a compatible field into this field.
	public void copy_from(Field other) {
		assert(this.compatible(other));
		Memory.copy(
			this._vals,
			other._vals,
			sizeof(double) * this._vals.length[0] * this._vals.length[1]);
	}

	public void zero() {
		// Having zeroes everywhere is compatible with every boundary condition.
		Memory.set(
			this._vals,
			0,
			sizeof(double) * this._vals.length[0] * this._vals.length[1]);
	}

	public double get_index(int i, int j) {
		int sign_i;
		int sign_j;
		i = Field.move_index_in_bounds(i, this.count_x, this._boundary_x, out sign_i);
		j = Field.move_index_in_bounds(j, this.count_y, this._boundary_y, out sign_j);
		return sign_i * sign_j * this._vals[i + 1, j + 1];
	}

	public void set_index(int i, int j, double value) {
		// TODO: Update the boundary cell (if you set an index right next to a
		// boundary cell).
		int sign_i;
		int sign_j;
		i = Field.move_index_in_bounds(i, this.count_x, this._boundary_x, out sign_i);
		j = Field.move_index_in_bounds(j, this.count_y, this._boundary_y, out sign_j);
		if (sign_i * sign_j != 0) {
			this._vals[i + 1, j + 1] = sign_i * sign_j * value;
		}
	}

	public void add_index(int i, int j, double value) {
		// TODO: Update the boundary cell (if you set an index right next to a
		// boundary cell).
		int sign_i;
		int sign_j;
		i = Field.move_index_in_bounds(i, this.count_x, this._boundary_x, out sign_i);
		j = Field.move_index_in_bounds(j, this.count_y, this._boundary_y, out sign_j);
		if (sign_i * sign_j != 0) {
			this._vals[i + 1, j + 1] += sign_i * sign_j * value;
		}
	}

	public void sub_index(int i, int j, double value) {
		// TODO: Update the boundary cell (if you set an index right next to a
		// boundary cell).
		int sign_i;
		int sign_j;
		i = Field.move_index_in_bounds(i, this.count_x, this._boundary_x, out sign_i);
		j = Field.move_index_in_bounds(j, this.count_y, this._boundary_y, out sign_j);
		if (sign_i * sign_j != 0) {
			this._vals[i + 1, j + 1] -= sign_i * sign_j * value;
		}
	}

	// Gets the cell which a certain position is located within.
	public Util.Vector local_cell_pos(Util.Vector pos, out int i, out int j) {
		double i_f = Math.floor(pos.x / this._cell_width);
		double j_f = Math.floor(pos.y / this._cell_height);
		// Ensure that the conversion to integers won't overflow.
		assert(!!(i_f > int.MIN && i_f < int.MAX));
		assert(!!(j_f > int.MIN && j_f < int.MAX));
		i = (int) i_f;
		j = (int) j_f;
		double x_c = pos.x - i * this._cell_width;
		double y_c = pos.y - j * this._cell_height;
		return Util.Vector(x_c, y_c);
	}

	public double get_pos(Util.Vector pos) {
		int i;
		int j;
		Util.Vector cell_pos = this.local_cell_pos(pos, out i, out j);
		double u = cell_pos.x / this.cell_width;
		double v = cell_pos.y / this.cell_height;
		return
			(1 - u) * (1 - v) * this.get_index(i, j)
			+ u * (1 - v) * this.get_index(i + 1, j)
			+ (1 - u) * v * this.get_index(i, j + 1)
			+ u * v * this.get_index(i + 1, j + 1);
	}

	public void set_pos(Util.Vector pos, double value) {
		double old_value = this.get_pos(pos);
		this.add_pos(pos, value - old_value);
	}

	// Makes the smallest possible change to the vector field near a given
	// point so that the value at the point increases by some value.
	public void add_pos(Util.Vector pos, double value) {
		int i;
		int j;
		Util.Vector cell_pos = this.local_cell_pos(pos, out i, out j);
		double u = cell_pos.x / this.cell_width;
		double v = cell_pos.y / this.cell_height;
		double norm = (1 - 2 * u + 2 * u * u) * (1 - 2 * v + 2 * v * v);
		this.add_index(i, j, value * (1 - u) * (1 - v) / norm);
		this.add_index(i + 1, j, value * u * (1 - v) / norm);
		this.add_index(i, j + 1, value * (1 - u) * v / norm);
		this.add_index(i + 1, j + 1, value * u * v / norm);
	}

	public void sub_pos(Util.Vector pos, double value) {
		this.add_pos(pos, -value);
	}

	// Returns the x gradient of the field at the point (i + 0.5, y).
	public double gradient_x(int i, int j) {
		return (this.get_index(i + 1, j) - this.get_index(i, j)) / this._cell_width;
	}

	// Returns the y gradient of the field at the point (i, j + 0.5).
	public double gradient_y(int i, int j) {
		return (this.get_index(i, j + 1) - this.get_index(i, j)) / this._cell_height;
	}

	public double laplacian(int i, int j) {
		double laplacian_x = (
				-2 * this.get_index(i, j)
				+ this.get_index(i - 1, j) + this.get_index(i + 1, j))
			/ Util.square(this._cell_width);
		double laplacian_y = (
				-2 * this.get_index(i, j)
				+ this.get_index(i, j - 1) + this.get_index(i, j + 1))
			/ Util.square(this._cell_height);
		return laplacian_x + laplacian_y;
	}

	// Returns the average of the field (excluding the boundary).
	public double average() {
		double result = 0.0;
		for (int j = 1; j < this._vals.length[1] - 1; ++j) {
			for (int i = 1; i < this._vals.length[0] - 1; ++i) {
				result += this._vals[i, j];
			}
		}
		result /= (this._vals.length[0] - 2) * (this._vals.length[1] - 2);
		return result;
	}

	// Returns the average of the boundary of the field.
	public double boundary_average() {
		double result =
			this._vals[0, 0]
			+ this._vals[0, this._vals.length[1] - 1]
			+ this._vals[this._vals.length[0] - 1, 0]
			+ this._vals[this._vals.length[0] - 1, this._vals.length[1] - 1];
		for (int i = 1; i < this._vals.length[0] - 1; ++i) {
			result += this._vals[i, 0];
			result += this._vals[i, this._vals.length[1] - 1];
		}
		for (int j = 1; j < this._vals.length[1] - 1; ++j) {
			result += this._vals[0, j];
			result += this._vals[this._vals.length[0] - 1, j];
		}
		result /=
			2 * this._vals.length[0]
			+ 2 * this._vals.length[1] - 4;
		return result;
	}

	// Diffusion allows the field to "spread out" at a rate given by the
	// diffusion coefficient.
	// 
	// The `initial_guess` parameter indicates whether the provided `result`
	// column will be taken as a starting point for finding the solution.
	// TODO: Remake this to be a special case of a general Poisson solver.
	public void diffuse(
			double diffusivity,
			ref Field? result,
			bool initial_guess = false) {
		if (result == null || !result.compatible(this)) {
			result = new Field.clone(this);
		}
		if (!initial_guess) {
			result.zero();
		}
		// Use the Gauss-Seidel method to solve the sparse linear equation:
		//   A = (I - diffusivity * nabla^2)
		//   b = this
		//   x = result
		// Solve Ax = b:
		// TODO: Choose omega in a smarter way.
		double omega = 1.8;
		double b = diffusivity;
		double a = 1 / (1
			+ 2 * b / Util.square(result.cell_width)
			+ 2 * b / Util.square(result.cell_height));
		// TODO: Replace the fixed iteration count with something based on the
		// convergence rate.
		for (uint iter = 0; iter < 40; ++iter) {
			for (int j = 1; j < this._vals.length[1] - 1; ++j) {
				for (int i = 1; i < this._vals.length[0] - 1; ++i) {
					double difference = this._vals[i, j] - result._vals[i, j];
					double laplacian_x = 1 / Util.square(result.cell_width)
						* (-2 * result.vals[i, j]
							+ result.vals[i - 1, j]
							+ result.vals[i + 1, j]);
					double laplacian_y = 1 / Util.square(result.cell_height)
						* (-2 * result.vals[i, j]
							+ result.vals[i, j - 1]
							+ result.vals[i, j + 1]);
					double laplacian = laplacian_x + laplacian_y;
					result._vals[i, j] += omega * a * (difference + b * laplacian);
				}
			}
			result.update_boundaries();
		}
	}

	// Takes an index and moves it in bounds, with a sign change if necessary.
	private static int move_index_in_bounds(
			int i,
			uint count,
			FieldBoundary boundary,
			out int sign) {
		if (i >= 0 && i < count) {
			sign = 1;
		} else {
			switch (boundary) {
			case FieldBoundary.FIXED:
				sign = 0;
				i = i.clamp(0, (int) (count - 1));
				break;
			case FieldBoundary.OPEN:
				sign = 1;
				i = i.clamp(0, (int) (count - 1));
				break;
			case FieldBoundary.ANTI_OPEN:
				sign = -1;
				i = i.clamp(0, (int) (count - 1));
				break;
			case FieldBoundary.PERIODIC:
				sign = 1;
				i = i % (int) count;
				if (i < 0) {
					i += (int) count;
				}
				break;
			case FieldBoundary.ANTI_PERIODIC:
				// TODO: Rewrite this in a way that doesn't potentially overflow
				// count.
				i = i % (int) (2 * count);
				if (i < 0) {
					i += (int) (2 * count);
				}
				if (i >= 0 && i < count) {
					sign = 1;
				} else {
					sign = -1;
					i -= (int) count;
				}
				break;
			}
		}
		return i;
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
			case FieldBoundary.FIXED:
				boundary_1 = 0;
				boundary_2 = 0;
				break;
			case FieldBoundary.OPEN:
				boundary_1 = value_1;
				boundary_2 = value_2;
				break;
			case FieldBoundary.ANTI_OPEN:
				boundary_1 = -value_1;
				boundary_2 = -value_2;
				break;
			case FieldBoundary.PERIODIC:
				boundary_1 = value_2;
				boundary_2 = value_1;
				break;
			case FieldBoundary.ANTI_PERIODIC:
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
			case FieldBoundary.FIXED:
				boundary_1 = 0;
				boundary_2 = 0;
				break;
			case FieldBoundary.OPEN:
				boundary_1 = value_1;
				boundary_2 = value_2;
				break;
			case FieldBoundary.ANTI_OPEN:
				boundary_1 = -value_1;
				boundary_2 = -value_2;
				break;
			case FieldBoundary.PERIODIC:
				boundary_1 = value_2;
				boundary_2 = value_1;
				break;
			case FieldBoundary.ANTI_PERIODIC:
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

}

