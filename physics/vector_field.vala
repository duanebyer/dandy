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

	// Returns whether this field has the same parameters as another field.
	public bool compatible(VectorField other) {
		return this._field_x.compatible(other._field_x)
			&& this._field_y.compatible(other._field_y);
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

	public void diffuse(
			double diffusivity,
			ref VectorField? result,
			bool initial_guess = false) {
		if (result == null || !result.compatible(this)) {
			result = new VectorField.clone(this);
		}
		this._field_x.diffuse(diffusivity, ref result._field_x, initial_guess);
		this._field_y.diffuse(diffusivity, ref result._field_y, initial_guess);
	}

	// Advects this vector field a small amount `delta` in time and puts the
	// result into another vector field.
	public void advect(double delta, ref VectorField? result) {
		if (result == null || !result.compatible(this)) {
			result = new VectorField.clone(this);
		}
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
	}

	// Splits the field into a pure curl part and a pure divergence part. The
	// pure divergence part is returned in the form of a potential, the gradient
	// of which gives the pure divergence field.
	// 
	// The `initial_guess` parameter can be used to indicate whether the
	// provided potential is a starting guess at the true potential.
	public void project(
			ref VectorField? curl_part,
			ref Field? potential,
			bool initial_guess = false) {
		// There are several ways to handle the boundary conditions. Together,
		// the boundary conditions must combine to form the boundary conditions
		// of the original vector field. The easiest way to do this is to
		// require that the divergence part is zero at the boundaries, and that
		// the curl part matches the boundary conditions of the original field.
		if (curl_part == null || !curl_part.compatible(this)) {
			curl_part = new VectorField.clone(this);
		}
		if (potential == null
				|| potential.count_x != this._field_x.count_x + 1
				|| potential.count_y != this._field_x.count_y + 1
				|| potential.cell_width != this._field_x.cell_width
				|| potential.cell_height != this._field_x.cell_height
				|| potential.boundary_x != FieldBoundary.OPEN
				|| potential.boundary_y != FieldBoundary.OPEN) {
			potential = new Field(
				this.count_x + 1, this.count_y + 1,
				this._field_x.cell_width, this._field_x.cell_height,
				FieldBoundary.OPEN, FieldBoundary.OPEN);
		}
		if (!initial_guess) {
			potential.zero();
		}

		// We will use the x component of the curl field to temporarily store
		// the divergence of the field (to avoid another allocation).
		Field divergence_field = curl_part._field_x;
		for (int j = 0; j < this._field_x.vals.length[1] - 1; ++j) {
			for (int i = 0; i < this._field_x.vals.length[0] - 1; ++i) {
				double divergence_x = 1 / (2 * this._field_x.cell_width)
					* (this._field_x.vals[i + 1, j]
						+ this._field_x.vals[i + 1, j + 1]
						- this._field_x.vals[i, j]
						- this._field_x.vals[i, j + 1]);
				double divergence_y = 1 / (2 * this._field_x.cell_height)
					* (this._field_y.vals[i, j + 1]
						+ this._field_y.vals[i + 1, j + 1]
						- this._field_y.vals[i, j]
						- this._field_y.vals[i + 1, j]);
				divergence_field.vals[i, j] = divergence_x + divergence_y;
			}
		}
		// Use the Gauss-Seidel method to solve the sparse linear equation:
		//   A = nabla^2
		//   b = div this
		//   x = potential
		// This will give the potential for the pure divergence part.
		// Solve Ax = b:
		// TODO: Choose omega in a smarter way.
		double omega = 1.8;
		double a = -1 / (
			2 / Util.square(potential.cell_width)
			+ 2 / Util.square(potential.cell_height));
		for (uint iter = 0; iter < 40; ++iter) {
			for (int j = 1; j < this._field_x.vals.length[1]; ++j) {
				for (int i = 1; i < this._field_x.vals.length[0]; ++i) {
					double laplacian_x = 1 / Util.square(potential.cell_width)
						* (-2 * potential.vals[i, j]
							+ potential.vals[i - 1, j]
							+ potential.vals[i + 1, j]);
					double laplacian_y = 1 / Util.square(potential.cell_height)
						* (-2 * potential.vals[i, j]
							+ potential.vals[i, j - 1]
							+ potential.vals[i, j + 1]);
					double laplacian = laplacian_x + laplacian_y;
					double divergence = divergence_field.vals[i - 1, j - 1];
					potential.vals[i, j] += a * omega * (divergence - laplacian);
				}
			}
			potential.update_boundaries();
			// Since the potential can be shifted by a constant without changing
			// its gradient, fix the average of the boundary of the potential to
			// zero.
			double boundary_average = potential.boundary_average();
			for (int j = 0; j < potential.vals.length[1]; ++j) {
				for (int i = 0; i < potential.vals.length[0]; ++i) {
					potential.vals[i, j] -= boundary_average;
				}
			}
		}

		// Subtract the gradient of the potential from the velocity field to
		// remove any divergences, leaving only the curl part.
		for (int j = 0; j < potential.vals.length[1] - 1; ++j) {
			for (int i = 0; i < potential.vals.length[0] - 1; ++i) {
				Util.Vector divergence_part = Util.Vector(
					1 / (2 * potential.cell_width)
						* (potential.vals[i + 1, j]
							+ potential.vals[i + 1, j + 1]
							- potential.vals[i, j]
							- potential.vals[i, j + 1]),
					1 / (2 * potential.cell_height)
						* (potential.vals[i, j + 1]
							+ potential.vals[i + 1, j + 1]
							- potential.vals[i, j]
							- potential.vals[i + 1, j]));
				curl_part._field_x.vals[i, j] =
					this._field_x.vals[i, j] - divergence_part.x;
				curl_part._field_y.vals[i, j] =
					this._field_y.vals[i, j] - divergence_part.y;
			}
		}
		// The boundary conditions should be automatically satisfied on the curl
		// part, but do it here again anyway, just in case.
		curl_part.update_boundaries();
	}

	public void update_boundaries() {
		this._field_x.update_boundaries();
		this._field_y.update_boundaries();
	}
}

}

