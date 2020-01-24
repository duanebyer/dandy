namespace Dandy.Physics {

using Dandy;

internal class VectorField {
	private Field _field_x;
	private Field _field_y;

	public Util.Bounds bounds {
		get { return this._field_x.bounds; }
	}
	public double width {
		get { return this._field_x.width; }
	}
	public double height {
		get { return this._field_x.height; }
	}
	public double area {
		get { return this._field_x.area; }
	}

	public uint count_x {
		get { return this._field_x.count_x; }
	}
	public uint count_y {
		get { return this._field_x.count_y; }
	}

	public double cell_width {
		get { return this._field_x.cell_width; }
	}
	public double cell_height {
		get { return this._field_x.cell_height; }
	}
	public double cell_area {
		get { return this._field_x.cell_area; }
	}

	public Field x {
		get { return this._field_x; }
	}
	public Field y {
		get { return this._field_y; }
	}

	public VectorField.clone(VectorField other) {
		this._field_x = new Field.clone(other._field_x);
		this._field_y = new Field.clone(other._field_y);
	}

	public VectorField(
			uint count_x, uint count_y,
			double width, double height,
			FieldBoundary boundary_xx = FieldBoundary.FIXED,
			FieldBoundary boundary_xy = FieldBoundary.OPEN,
			FieldBoundary boundary_yx = FieldBoundary.OPEN,
			FieldBoundary boundary_yy = FieldBoundary.FIXED) {
		this._field_x = new Field(
			count_x, count_y,
			width, height,
			boundary_xx, boundary_xy);
		this._field_y = new Field(
			count_x, count_y,
			width, height,
			boundary_yx, boundary_yy);
	}

	public bool compatible(VectorField other) {
		return this._field_x.compatible(other._field_x)
			&& this._field_y.compatible(other._field_y);
	}

	public bool compatible_boundaries(VectorField other) {
		return this._field_x.compatible_boundaries(other._field_x)
			&& this._field_y.compatible_boundaries(other._field_y);
	}

	public void copy_from(VectorField other) {
		assert(this.compatible(other));
		this._field_x.copy_from(other._field_x);
		this._field_y.copy_from(other._field_y);
	}

	public void zero() {
		this._field_x.zero();
		this._field_y.zero();
	}

	public Util.Vector get_index(int i, int j) {
		return Util.Vector(
			this._field_x.get_index(i, j),
			this._field_y.get_index(i, j));
	}

	public void set_index(int i, int j, Util.Vector value) {
		this._field_x.set_index(i, j, value.x);
		this._field_y.set_index(i, j, value.y);
	}

	public void add_index(int i, int j, Util.Vector value) {
		this._field_x.add_index(i, j, value.x);
		this._field_y.add_index(i, j, value.y);
	}

	public void sub_index(int i, int j, Util.Vector value) {
		this._field_x.sub_index(i, j, value.x);
		this._field_y.sub_index(i, j, value.y);
	}

	public Util.Vector local_cell_pos(Util.Vector pos, out int i, out int j) {
		return this._field_x.local_cell_pos(pos, out i, out j);
	}

	public Util.Vector get_pos(Util.Vector pos) {
		return Util.Vector(
			this._field_x.get_pos(pos),
			this._field_y.get_pos(pos));
	}

	public void set_pos(Util.Vector pos, Util.Vector value) {
		this._field_x.set_pos(pos, value.x);
		this._field_y.set_pos(pos, value.y);
	}

	public void add_pos(Util.Vector pos, Util.Vector value) {
		this._field_x.add_pos(pos, value.x);
		this._field_y.add_pos(pos, value.y);
	}

	public void sub_pos(Util.Vector pos, Util.Vector value) {
		this._field_x.sub_pos(pos, value.x);
		this._field_y.sub_pos(pos, value.y);
	}

	public Util.Vector gradient_x(int i, int j) {
		return Util.Vector(
			this._field_x.gradient_x(i, j),
			this._field_y.gradient_x(i, j));
	}

	public Util.Vector gradient_y(int i, int j) {
		return Util.Vector(
			this._field_x.gradient_y(i, j),
			this._field_y.gradient_y(i, j));
	}

	public Util.Vector laplacian(int i, int j) {
		return Util.Vector(
			this._field_x.laplacian(i, j),
			this._field_y.laplacian(i, j));
	}

	public double divergence(int i, int j) {
		double grad_x1 = this._field_x.gradient_x(i, j);
		double grad_x2 = this._field_x.gradient_x(i, j + 1);
		double grad_y1 = this._field_y.gradient_y(i, j);
		double grad_y2 = this._field_y.gradient_y(i + 1, j);
		return 0.5 * (grad_x1 + grad_x2 + grad_y1 + grad_y2);
	}

	public double curl(int i, int j) {
		double grad_x1 = this._field_y.gradient_x(i, j);
		double grad_x2 = this._field_y.gradient_x(i, j + 1);
		double grad_y1 = this._field_x.gradient_y(i, j);
		double grad_y2 = this._field_x.gradient_y(i + 1, j);
		return 0.5 * ((grad_x1 + grad_x2) - (grad_y1 + grad_y2));
	}

	public Util.Vector average() {
		return Util.Vector(
			this._field_x.average(),
			this._field_y.average());
	}

	public Util.Vector boundary_average() {
		return Util.Vector(
			this._field_x.boundary_average(),
			this._field_y.boundary_average());
	}

	public VectorField poisson_solve(
			double alpha = 1,
			double beta = 0) {
		VectorField result = new VectorField(
			this.count_x, this.count_y,
			this._field_x.width, this._field_x.height,
			FieldBoundary.OPEN, FieldBoundary.OPEN,
			FieldBoundary.OPEN, FieldBoundary.OPEN);
		return this.poisson_solve_in_field(ref result, alpha, beta);
	}

	public VectorField poisson_solve_in_field(
			ref VectorField result,
			double alpha = 1,
			double beta = 0) {
		assert(result.compatible(this));
		this._field_x.poisson_solve_in_field(ref result._field_x, alpha, beta);
		this._field_y.poisson_solve_in_field(ref result._field_y, alpha, beta);
		return result;
	}

	public VectorField diffuse(
			double diffusivity,
			double delta) {
		VectorField result = new VectorField.clone(this);
		return this.diffuse_in_field(ref result, delta, diffusivity);
	}

	public VectorField diffuse_in_field(
			ref VectorField result,
			double diffusivity,
			double delta) {
		assert(result.compatible(this));
		assert(result.compatible_boundaries(this));
		this._field_x.diffuse_in_field(ref result._field_x, delta, diffusivity);
		this._field_y.diffuse_in_field(ref result._field_y, delta, diffusivity);
		return result;
	}

	public VectorField advect(
			VectorField vel_field,
			double delta) {
		VectorField result = new VectorField(
			this.count_x, this.count_y,
			this._field_x.width, this._field_x.height,
			this._field_x.boundary_x, this._field_x.boundary_y,
			this._field_y.boundary_x, this._field_y.boundary_y);
		return this.advect_in_field(ref result, vel_field, delta);
	}

	// Advects this vector field a small amount `delta` in time and puts the
	// result into another vector field.
	public VectorField advect_in_field(
			ref VectorField result,
			VectorField vel_field,
			double delta) {
		assert(result.compatible(this));
		assert(result.compatible_boundaries(this));
		this._field_x.advect_in_field(ref result._field_x, vel_field, delta);
		this._field_y.advect_in_field(ref result._field_y, vel_field, delta);
		return result;
	}

	public VectorField project() {
		VectorField result = new VectorField.clone(this);
		Field pressure = new Field(
			this.count_x + 1, this.count_y + 1,
			this.width + this.cell_width, this.height + this.cell_height,
			FieldBoundary.OPEN, FieldBoundary.OPEN);
		Field divergence = new Field.clone(pressure);
		return this.project_in_field(ref result, ref pressure, ref divergence);
	}

	// Finds the divergence-free part of this vector field.
	public VectorField project_in_field(
			ref VectorField result,
			ref Field pressure,
			ref Field divergence) {
		assert(result.compatible(this));
		assert(result.compatible_boundaries(this));
		// TODO: Eliminate the magic number tolerance here.
		assert(
			pressure.count_x == this.count_x + 1
			&& pressure.count_y == this.count_y + 1);
		assert(
			Math.fabs(pressure.width - this.width - this.cell_width) < 0.01 * this.cell_width
			&& Math.fabs(pressure.height - this.height - this.cell_height) < 0.01 * this.cell_height);
		assert(
			pressure.boundary_x == FieldBoundary.OPEN
			&& pressure.boundary_y == FieldBoundary.OPEN);
		assert(pressure.compatible(divergence));

		for (int j = 0; j < divergence.count_y; ++j) {
			for (int i = 0; i < divergence.count_x; ++i) {
				divergence.set_index(i, j, this.divergence(i - 1, j - 1));
			}
		}
		divergence.poisson_solve_in_field(ref pressure);
		for (int j = 0; j < result.count_y; ++j) {
			for (int i = 0; i < result.count_x; ++i) {
				result.set_index(i, j, this.get_index(i, j).sub(pressure.gradient(i, j)));
			}
		}
		result.update_boundaries();
		return result;
		// TODO: Remove this.
		// An alternate method of projecting the field that doesn't work as
		// well, but has the advantage of more naturally respecting the boundary
		// conditions.
		/*
		for (int j = 1; j < this._field_x.vals.length[1] - 1; ++j) {
			for (int i = 1; i < this._field_x.vals.length[0] - 1; ++i) {
				double v_xx = -1 / (4 * Util.square(this._field_x.cell_height))
					* (this._field_x.vals[i - 1, j - 1]
						- 2 * this._field_x.vals[i - 1, j]
						+ this._field_x.vals[i - 1, j + 1]
						+ 2 * this._field_x.vals[i, j - 1]
						- 4 * this._field_x.vals[i, j]
						+ 2 * this._field_x.vals[i, j + 1]
						+ this._field_x.vals[i + 1, j - 1]
						- 2 * this._field_x.vals[i + 1, j]
						+ this._field_x.vals[i + 1, j + 1]);
				double v_xy = 1 / (4 * this._field_x.cell_area)
					* (this._field_y.vals[i - 1, j - 1]
						- this._field_y.vals[i - 1, j + 1]
						- this._field_y.vals[i + 1, j - 1]
						+ this._field_y.vals[i + 1, j + 1]);
				double v_yx = 1 / (4 * this._field_x.cell_area)
					* (this._field_x.vals[i - 1, j - 1]
						- this._field_x.vals[i + 1, j - 1]
						- this._field_x.vals[i - 1, j + 1]
						+ this._field_x.vals[i + 1, j + 1]);
				double v_yy = -1 / (4 * Util.square(this._field_x.cell_width))
					* (this._field_y.vals[i - 1, j - 1]
						- 2 * this._field_y.vals[i, j - 1]
						+ this._field_y.vals[i + 1, j - 1]
						+ 2 * this._field_y.vals[i - 1, j]
						- 4 * this._field_y.vals[i, j]
						+ 2 * this._field_y.vals[i + 1, j]
						+ this._field_y.vals[i - 1, j + 1]
						- 2 * this._field_y.vals[i, j + 1]
						+ this._field_y.vals[i + 1, j + 1]);
				laplacian_field._field_x.vals[i, j] = -(v_xx + v_xy);
				laplacian_field._field_y.vals[i, j] = -(v_yx + v_yy);
			}
		}
		return laplacian_field.poisson_solve_in_field(ref result);
		*/
	}

	public void update_boundaries() {
		this._field_x.update_boundaries();
		this._field_y.update_boundaries();
	}

	public void update_boundary_corners() {
		this._field_x.update_boundary_corners();
		this._field_y.update_boundary_corners();
	}

	public void update_boundary_y_index(int i) {
		this._field_x.update_boundary_y_index(i);
		this._field_y.update_boundary_y_index(i);
	}

	public void update_boundary_x_index(int j) {
		this._field_x.update_boundary_x_index(j);
		this._field_y.update_boundary_x_index(j);
	}
}

}

