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
	private double _width;
	private double _height;
	private FieldBoundary _boundary_x;
	private FieldBoundary _boundary_y;

	// Note that vals contains the boundary cells as well as the cells in the
	// bulk of the field. Generally, it is better to directly use the accessor
	// methods. If this property is used, then the boundaries must be updated.
	public double[,] vals {
		get { return this._vals; }
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
	public double area {
		get { return this._width * this._height; }
	}

	public uint count_x {
		get { return this._vals.length[0] - 2; }
	}
	public uint count_y {
		get { return this._vals.length[1] - 2; }
	}

	public double cell_width {
		get { return this._width / this.count_x; }
	}
	public double cell_height {
		get { return this._height / this.count_y; }
	}
	public double cell_area {
		get { return this.cell_width * this.cell_height; }
	}

	public FieldBoundary boundary_x {
		get { return this._boundary_x; }
	}
	public FieldBoundary boundary_y {
		get { return this._boundary_y; }
	}

	public Field.clone(Field other) {
		this._vals = new double[other._vals.length[0], other._vals.length[1]];
		this._width = other._width;
		this._height = other._height;
		this._boundary_x = other._boundary_x;
		this._boundary_y = other._boundary_y;
		this.copy_from(other);
	}

	public Field(
			uint count_x, uint count_y,
			double width, double height,
			FieldBoundary boundary_x = FieldBoundary.FIXED,
			FieldBoundary boundary_y = FieldBoundary.FIXED) {
		assert(count_x > 0 && count_y > 0);
		this._vals = new double[count_x + 2, count_y + 2];
		this._width = width;
		this._height = height;
		this._boundary_x = boundary_x;
		this._boundary_y = boundary_y;
		this.zero();
	}

	// Returns whether this field has the same parameters as another field. Note
	// that two fields with different boundary conditions are still compatible.
	public bool compatible(Field other) {
		return this._vals.length[0] == other._vals.length[0]
			&& this._vals.length[1] == other._vals.length[1]
			&& this._width == other._width
			&& this._height == other._height;
	}

	public bool compatible_boundaries(Field other) {
		return this._boundary_x == other._boundary_x
			&& this._boundary_y == other._boundary_y;
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
		double i_f = Math.floor(pos.x / this.cell_width);
		double j_f = Math.floor(pos.y / this.cell_height);
		// Ensure that the conversion to integers won't overflow.
		assert(!!(i_f > int.MIN && i_f < int.MAX));
		assert(!!(j_f > int.MIN && j_f < int.MAX));
		i = (int) i_f;
		j = (int) j_f;
		double x_c = pos.x - i * this.cell_width;
		double y_c = pos.y - j * this.cell_height;
		return Util.Vector(x_c, y_c);
	}

	public double get_pos(Util.Vector pos) {
		int i;
		int j;
		Util.Vector offset = Util.Vector(
			-0.5 * this.cell_width,
			-0.5 * this.cell_height);
		Util.Vector cell_pos = this.local_cell_pos(pos.add(offset), out i, out j);
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
	// TODO: Reconsider whether this function should even exist at all. It has a
	// problem where adding a value to the field near a grid point causes the
	// grid point to be increased greater than the value. Often, this doesn't
	// make much physical sense.
	public void add_pos(Util.Vector pos, double value) {
		int i;
		int j;
		Util.Vector offset = Util.Vector(
			-0.5 * this.cell_width,
			-0.5 * this.cell_height);
		Util.Vector cell_pos = this.local_cell_pos(pos.add(offset), out i, out j);
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
		return (this.get_index(i + 1, j) - this.get_index(i, j)) / this.cell_width;
	}

	// Returns the y gradient of the field at the point (i, j + 0.5).
	public double gradient_y(int i, int j) {
		return (this.get_index(i, j + 1) - this.get_index(i, j)) / this.cell_height;
	}

	public double laplacian(int i, int j) {
		double laplacian_x = (
				-2 * this.get_index(i, j)
				+ this.get_index(i - 1, j) + this.get_index(i + 1, j))
			/ Util.square(this.cell_width);
		double laplacian_y = (
				-2 * this.get_index(i, j)
				+ this.get_index(i, j - 1) + this.get_index(i, j + 1))
			/ Util.square(this.cell_height);
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

	public Field poisson_solve(
			double alpha = 1,
			double beta = 0) {
		Field result = new Field(
			this.count_x, this.count_y,
			this._width, this._height,
			FieldBoundary.OPEN, FieldBoundary.OPEN);
		poisson_solve_in_field(ref result, alpha, beta);
		return result;
	}

	// Solves a Poisson equation of the form:
	//   (beta * I + alpha * nabla^2) result = this
	// 
	// The result will be stored in the provided field, which also acts as an
	// initial guess at the solution.
	public Field poisson_solve_in_field(
			ref Field result,
			double alpha = 1,
			double beta = 0) {
		assert(result.compatible(this));
		// Use the Gauss-Seidel method to solve the sparse linear equation:
		//   A = (beta * I + alpha * nabla^2)
		//   b = this
		//   x = result
		// Solve Ax = b:
		// TODO: Choose omega in a smarter way.
		double omega = 1.5;
		double norm = beta
			- 2 * alpha / Util.square(result.cell_width)
			- 2 * alpha / Util.square(result.cell_height);
		// TODO: Replace the fixed iteration count with something based on the
		// convergence rate.
		for (uint iter = 0; iter < 40; ++iter) {
			for (int j = 1; j < this._vals.length[1] - 1; ++j) {
				for (int i = 1; i < this._vals.length[0] - 1; ++i) {
					double target = this._vals[i, j];
					double identity = result._vals[i, j];
					double laplacian_x = 1 / Util.square(result.cell_width)
						* (-2 * result._vals[i, j]
							+ result._vals[i - 1, j]
							+ result._vals[i + 1, j]);
					double laplacian_y = 1 / Util.square(result.cell_height)
						* (-2 * result._vals[i, j]
							+ result._vals[i, j - 1]
							+ result._vals[i, j + 1]);
					double laplacian = laplacian_x + laplacian_y;
					result._vals[i, j] += omega / norm * (
						target - beta * identity - alpha * laplacian);
				}
			}
			// TODO: Should consider the case where the boundary conditions do
			// not exclude all harmonic fields (e.x. if both boundaries are
			// open, allowing for any constant to be added).
			result.update_boundaries();
		}
		return result;
	}

	public Field diffuse(
			double diffusivity,
			double delta) {
		Field result = new Field.clone(this);
		return this.diffuse_in_field(ref result, delta, diffusivity);
	}

	// Diffusion allows the field to "spread out" at a rate given by the
	// diffusion coefficient.
	public Field diffuse_in_field(
			ref Field result,
			double diffusivity,
			double delta) {
		assert(result.compatible(this));
		assert(result.compatible_boundaries(this));
		this.poisson_solve_in_field(ref result, -diffusivity * delta, 1);
		return result;
	}

	public Field advect(
			VectorField vel_field,
			double delta) {
		Field result = new Field.clone(this);
		return this.advect_in_field(ref result, vel_field, delta);
	}

	// Transports the contents of this field through the provided flow.
	public Field advect_in_field(
			ref Field result,
			VectorField vel_field,
			double delta) {
		assert(result.compatible(this));
		assert(result.compatible_boundaries(this));
		// Trace backwards in the flow by a time `delta`.
		for (int j = 1; j < this._vals.length[1] - 1; ++j) {
			for (int i = 1; i < this._vals.length[0] - 1; ++i) {
				Util.Vector pos = Util.Vector(
					(i - 0.5) * this.cell_width,
					(j - 0.5) * this.cell_height);
				Util.Vector vel = Util.Vector(
					vel_field.x._vals[i, j],
					vel_field.y._vals[i, j]);
				Util.Vector pos_prev = pos.sub(vel.scale(delta));
				result._vals[i, j] = this.get_pos(pos_prev);
			}
		}
		result.update_boundaries();
		return result;
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

