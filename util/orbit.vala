namespace Dandy.Util {

// TODO: Rename this class. Trajectory?
internal class Orbit : Object {

	public delegate Vector Parameterization(double t);
	public delegate double OffsetParameterization(double t);

	private Parameterization _f;
	
	public Orbit(owned Parameterization f) {
		this._f = (owned) f;
	}

	// This is a parabola parametrized in an odd way that's useful for a lot of
	// the drawing done by us. It's like a line that "droops" below a true line
	// by some fractional amount.
	public static Orbit line_with_droop(Vector slope, double length, double droop) {
		return new Orbit((t) => Vector(
			slope.x * length * t,
			slope.y * length * t * (1 - droop * t)));
	}

	public static Orbit cubic_spline(Vector p0, Vector p1, Vector p2, Vector p3) {
		return new Orbit((t) => {
			double tp = 1 - t;
			double a = tp * tp * tp;
			double b = 3 * t * tp * tp;
			double c = 3 * t * t * tp;
			double d = t * t * t;
			return p0.scale(a).add(p1.scale(b)).add(p2.scale(c)).add(p3.scale(d));
		});
	}

	public Vector at(double t) {
		return this._f(t);
	}

	public Orbit set_origin(Vector origin) {
		Vector old_origin = this._f(0);
		return new Orbit((t) => {
			Vector point = this._f(t);
			return point.add(origin.sub(old_origin));
		});
	}

	public Orbit rescale(double t_start, double t_end) {
		return new Orbit((t) => this._f((t - t_start) / (t_end - t_start)));
	}

	public Orbit reverse() {
		return new Orbit((t) => this._f(1 - t));
	}

	public Orbit append(Orbit other) {
		return new Orbit((t) => {
			if (t < 0.5) {
				return this._f(2 * t);
			} else {
				return other._f(2 * t - 1);
			}
		});
	}

	public Orbit offset_fixed(double offset) {
		return this.offset((t) => offset);
	}

	// Applies an offset to a path perpendicular to the direction of the path
	// itself.
	public Orbit offset(OffsetParameterization offset_f) {
		double delta = 1e-4;
		return new Orbit((t) => {
			Vector point = this._f(t);
			Vector next_point = this._f(t + delta);
			Vector prev_point = this._f(t - delta);
			Vector offset = next_point.sub(prev_point).perp();
			if (offset.norm() != 0) {
				double offset_mag = offset_f(t);
				point = point.add(offset.unit().scale(offset_mag));
			}
			return point;
		});
	}

	public Orbit add(Orbit other) {
		return new Orbit((t) => {
			Vector point_a = this._f(t);
			Vector point_b = other._f(t);
			return point_a.add(point_b);
		});
	}

	public Orbit subtract(Orbit other) {
		return new Orbit((t) => {
			Vector point_a = this._f(t);
			Vector point_b = other._f(t);
			return point_a.sub(point_b);
		});
	}
}

}

