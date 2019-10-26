namespace Dandy.Physics {

using Dandy;

public class Air : Object {
	private double _viscosity;

	private Util.Bounds _bounds;
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
		get { return this._bounds; }
	}

	public VectorField velocity {
		get { return this._vel; }
	}

	public Field pressure {
		get { return this._pressure; }
	}

	public Air(double viscosity, Util.Bounds bounds, double max_cell_size) {
		this._bounds = bounds;
		this._count_x = (uint) Math.ceil(this._bounds.width() / max_cell_size);
		this._count_y = (uint) Math.ceil(this._bounds.height() / max_cell_size);
		this._cell_width = this._bounds.width() / this._count_x;
		this._cell_height = this._bounds.height() / this._count_y;
		this._vel = new VectorField(
			this._count_x, this._count_y,
			this._cell_width, this._cell_height,
			BoundaryCondition.ANTI_OPEN, BoundaryCondition.OPEN,
			BoundaryCondition.OPEN, BoundaryCondition.ANTI_OPEN);
		this._vel_next = new VectorField(
			this._count_x, this._count_y,
			this._cell_width, this._cell_height,
			BoundaryCondition.ANTI_OPEN, BoundaryCondition.OPEN,
			BoundaryCondition.OPEN, BoundaryCondition.ANTI_OPEN);
		this._pressure = new Field(
			this._count_x + 1, this._count_y + 1,
			this._cell_width, this._cell_height,
			BoundaryCondition.OPEN, BoundaryCondition.OPEN);

		this._viscosity = viscosity;
	}

	public void update(double delta) {
		this.advect(delta);
		this.diffuse(delta);
		this.project();
	}

	// Advection makes the velocity field move air from one place to another.
	private void advect(double delta) {
		// Trace a particle backwards in the fluid by a time `delta`. Take the
		// velocity field at the particle's previous position, and set the
		// velocity at the current position to the new value.
		for (uint j = 0; j < this._count_y; ++j) {
			for (uint i = 0; i < this._count_x; ++i) {
				Util.Vector pos = Util.Vector(
					i * this._cell_width,
					j * this._cell_height);
				Util.Vector vel = this._vel.get_index(i, j);
				Util.Vector pos_prev = pos.sub(vel.scale(delta));
				Util.Vector vel_prev = this._vel.get_pos(pos_prev);
				this._vel_next.set_index(i, j, vel_prev);
			}
		}
		this._vel_next.update_boundaries();
		Util.swap(ref this._vel_next, ref this._vel);
	}

	// Diffusion allows the velocity field to "spread out" at a rate given by
	// the visocosity.
	private void diffuse(double delta) {
		// Use the Gauss-Seidel method to solve the sparse linear equation:
		//   A = (I - visc * delta * nabla^2)
		//   b = vel
		//   x = vel_next
		// Solve Ax = b:
		double b = this._viscosity * delta;
		double a = 1 / (1 + 4 * b / (this._cell_width * this._cell_height));
		// TODO: Replace the fixed iteration count with something based on the
		// convergence rate.
		for (uint iter = 0; iter < 20; ++iter) {
			for (uint j = 0; j < this._count_y; ++j) {
				for (uint i = 0; i < this._count_x; ++i) {
					Util.Vector difference = this._vel.get_index(i, j)
						.sub(this._vel_next.get_index(i, j));
					Util.Vector laplacian = this._vel_next.laplacian(i, j);
					Util.Vector vel_next = this._vel_next.get_index(i, j)
						.add(difference.scale(a))
						.add(laplacian.scale(a * b));
					this._vel_next.set_index(i, j, vel_next);
				}
			}
			this._vel_next.update_boundaries();
		}
		Util.swap(ref this._vel_next, ref this._vel);
	}

	// Projection ensures that the fluid is incompressible, by removing any
	// divergences.
	private void project() {
		// Use the Gauss-Seidel method to solve the sparse linear equation:
		//   A = nabla^2
		//   b = div vel
		//   x = pressure
		// Solve Ax = b:
		double a = -this._cell_width * this._cell_height / 4;
		for (uint iter = 0; iter < 20; ++iter) {
			for (uint j = 0; j < this._count_y + 1; ++j) {
				for (uint i = 0; i < this._count_x + 1; ++i) {
					// Note that since the pressure field is offset from the
					// velocity field, the indices get shifted around.
					// TODO: Verify that these indices are correct.
					double laplacian = this._pressure.laplacian(i, j);
					double divergence = this._vel.divergence(i - 1, j - 1);
					double pressure = this._pressure.get_index(i, j)
						+ a * (divergence + laplacian);
					this._pressure.set_index(i, j, pressure);
				}
			}
			this._pressure.update_boundaries();
		}

		// Subtract the pressure gradient from the velocities to remove any
		// divergences (satisfying the incompressible condition).
		for (uint j = 0; j < this._count_y; ++j) {
			for (uint i = 0; i < this._count_x; ++i) {
				// TODO: Verify that these indices are correct.
				Util.Vector gradient = Util.Vector(
					this._pressure.gradient_x(i, j),
					this._pressure.gradient_y(i, j));
				Util.Vector vel = this._vel.get_index(i, j).sub(gradient);
				this._vel.set_index(i, j, vel);
			}
		}
		
		// The velocity boundary conditions should still be satisfied here, but
		// for peace of mind we can do it again.
		this._vel.update_boundaries();
	}
}

}

