// TODO: Rename this class. Trajectory?
public class Dandy.Util.Orbit : Object {

	public delegate Util.Point Parameterization(double t);
	public delegate double OffsetParameterization(double t);

	private Parameterization _f;
	
	public Orbit(owned Parameterization f) {
		this._f = (owned) f;
	}

	// This is a parabola parametrized in an odd way that's useful for a lot of
	// the drawing done by us. It's like a line that "droops" below a true line
	// by some fractional amount.
	public static Orbit line_with_droop(
			double slope_x,
			double slope_y,
			double length,
			double droop) {
		return new Orbit((t) => Util.Point() {
			x = slope_x * length * t,
			y = slope_y * length * t * (1 - droop * t)
		});
	}

	public static Orbit cubic_spline(
			double x0, double y0,
			double x1, double y1,
			double x2, double y2,
			double x3, double y3) {
		return new Orbit((t) => {
			double tp = 1 - t;
			double a = tp * tp * tp;
			double b = 3 * t * tp * tp;
			double c = 3 * t * t * tp;
			double d = t * t * t;
			double x = a * x0 + b * x1 + c * x2 + d * x3;
			double y = a * y0 + b * y1 + c * y2 + d * y3;
			return Util.Point() { x = x, y = y };
		});
	}

	public Util.Point at(double t) {
		return this._f(t);
	}

	public Orbit set_origin(double origin_x, double origin_y) {
		Util.Point old_origin = this._f(0);
		return new Orbit((t) => {
			Util.Point point = this._f(t);
			point.x += origin_x - old_origin.x;
			point.y += origin_y - old_origin.y;
			return point;
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
			Util.Point point = this._f(t);
			Util.Point next_point = this._f(t + delta);
			Util.Point prev_point = this._f(t - delta);
			double offset_x = next_point.y - prev_point.y;
			double offset_y = -(next_point.x - prev_point.x);
			double offset_normalization = Util.length(offset_x, offset_y);
			double offset_mag = offset_f(t);

			if (offset_normalization != 0) {
				point.x += offset_mag * offset_x / offset_normalization;
				point.y += offset_mag * offset_y / offset_normalization;
			}

			return point;
		});
	}

	public Orbit add(Orbit other) {
		return new Orbit((t) => {
			Util.Point point_a = this._f(t);
			Util.Point point_b = other._f(t);
			return Util.Point() {
				x = point_a.x + point_b.x,
				y = point_a.y + point_b.y
			};
		});
	}

	public Orbit subtract(Orbit other) {
		return new Orbit((t) => {
			Util.Point point_a = this._f(t);
			Util.Point point_b = other._f(t);
			return Util.Point() {
				x = point_a.x - point_b.x,
				y = point_a.y - point_b.y
			};
		});
	}
}

