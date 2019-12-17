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
			double cell_width, double cell_height,
			FieldBoundary boundary_xx = FieldBoundary.FIXED,
			FieldBoundary boundary_xy = FieldBoundary.OPEN,
			FieldBoundary boundary_yx = FieldBoundary.OPEN,
			FieldBoundary boundary_yy = FieldBoundary.FIXED) {
		this._field_x = new Field(
			count_x, count_y,
			cell_width, cell_height,
			boundary_xx, boundary_xy);
		this._field_y = new Field(
			count_x, count_y,
			cell_width, cell_height,
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
			this._field_x.cell_width, this._field_x.cell_height,
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
			double delta,
			double diffusivity) {
		VectorField result = new VectorField.clone(this);
		return this.diffuse_in_field(ref result, delta, diffusivity);
	}

	public VectorField diffuse_in_field(
			ref VectorField result,
			double delta,
			double diffusivity) {
		assert(result.compatible(this));
		assert(result.compatible_boundaries(this));
		this._field_x.diffuse_in_field(ref result._field_x, delta, diffusivity);
		this._field_y.diffuse_in_field(ref result._field_y, delta, diffusivity);
		return result;
	}

	public VectorField advect(double delta) {
		VectorField result = new VectorField(
			this.count_x, this.count_y,
			this._field_x.cell_width, this._field_x.cell_height,
			this._field_x.boundary_x, this._field_x.boundary_y,
			this._field_y.boundary_x, this._field_y.boundary_y);
		return this.advect_in_field(ref result, delta);
	}

	// Advects this vector field a small amount `delta` in time and puts the
	// result into another vector field.
	public VectorField advect_in_field(
			ref VectorField result,
			double delta) {
		assert(result.compatible(this));
		assert(result.compatible_boundaries(this));
		// Trace a particle backwards in the fluid by a time `delta`. Take the
		// velocity field at the particle's previous position, and set the
		// velocity at the current position to the new value.
		for (int j = 1; j < this._field_x.vals.length[1] - 1; ++j) {
			for (int i = 1; i < this._field_y.vals.length[0] - 1; ++i) {
				Util.Vector pos = Util.Vector(
					(i - 1) * this._field_x.cell_width,
					(j - 1) * this._field_y.cell_height);
				Util.Vector vel = Util.Vector(
					this._field_x.vals[i, j],
					this._field_y.vals[i, j]);
				Util.Vector pos_prev = pos.sub(vel.scale(delta));
				Util.Vector vel_prev = this.get_pos(pos_prev);
				result._field_x.vals[i, j] = vel_prev.x;
				result._field_y.vals[i, j] = vel_prev.y;
			}
		}
		result.update_boundaries();
		return result;
	}

	public VectorField project() {
		VectorField result = new VectorField.clone(this);
		VectorField laplacian_field = new VectorField(
			this.count_x, this.count_y,
			this._field_x.cell_width, this._field_x.cell_height,
			FieldBoundary.OPEN, FieldBoundary.OPEN,
			FieldBoundary.OPEN, FieldBoundary.OPEN);
		return this.project_in_field(ref result, ref laplacian_field);
	}

	// Finds the divergence-free part of this vector field.
	public VectorField project_in_field(
			ref VectorField result,
			ref VectorField laplacian_field) {
		assert(result.compatible(this));
		assert(result.compatible_boundaries(this));
		assert(laplacian_field.compatible(this));
		// We will calculate the curl of the curl of this vector field, and
		// store it in the `laplacian_field` variable.
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
	}

	public void update_boundaries() {
		this._field_x.update_boundaries();
		this._field_y.update_boundaries();
	}
}

}

