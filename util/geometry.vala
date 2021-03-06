namespace Dandy.Util {

internal struct Vector {
	double x;
	double y;

	public const Vector ZERO = { 0, 0 };
	public const Vector UNIT_X = { 1, 0 };
	public const Vector UNIT_Y = { 0, 1 };

	public Vector(double x, double y) {
		this.x = x;
		this.y = y;
	}

	public Vector.polar(double len, double angle) {
		this.x = len * Math.cos(angle);
		this.y = len * Math.sin(angle);
	}

	public Vector3 as_vector3() {
		return Vector3(this.x, this.y, 0);
	}

	public double dot(Vector other) {
		return this.x * other.x + this.y * other.y;
	}

	public double cross(Vector other) {
		return this.x * other.y - this.y * other.x;
	}

	public double norm() {
		return Math.hypot(this.x, this.y);
	}

	public Vector clamp(double len) {
		if (this.norm() > len) {
			return this.unit().scale(len);
		}
		else {
			return this;
		}
	}

	public Vector negate() {
		return Vector(-this.x, -this.y);
	}

	public Vector unit() {
		return this.scale(1 / this.norm());
	}

	public Vector perp() {
		return Vector(-this.y, this.x);
	}

	public Vector project(Vector other) {
		Vector dir = other.unit();
		return dir.scale(this.dot(dir));
	}

	public Vector rotate(double angle) {
		double cos_angle = Math.cos(angle);
		double sin_angle = Math.sin(angle);
		return Vector(
			this.x * cos_angle - this.y * sin_angle,
			this.x * sin_angle + this.y * cos_angle);
	}

	public Vector transform(Vector unit_x, Vector unit_y) {
		return unit_x.scale(this.x).add(unit_y.scale(this.y));
	}

	public Vector scale(double scale) {
		return Vector(
			scale * this.x,
			scale * this.y);
	}

	public Vector add(Vector other) {
		return Vector(
			this.x + other.x,
			this.y + other.y);
	}

	public Vector sub(Vector other) {
		return Vector(
			this.x - other.x,
			this.y - other.y);
	}

	public Vector complex_mul(Vector other) {
		return Vector(
			this.x * other.x - this.y * other.y,
			this.x * other.y + this.y * other.x);
	}

	public string to_string() {
		return "(" + x.to_string() + ", " + y.to_string() + ")";
	}
}

internal struct Vector3 {
	double x;
	double y;
	double z;

	public const Vector3 ZERO = { 0, 0, 0 };
	public const Vector3 UNIT_X = { 1, 0, 0 };
	public const Vector3 UNIT_Y = { 0, 1, 0 };
	public const Vector3 UNIT_Z = { 0, 0, 1 };

	public Vector3(double x, double y, double z) {
		this.x = x;
		this.y = y;
		this.z = z;
	}

	public Vector as_vector() {
		return Vector(this.x, this.y);
	}

	public double dot(Vector3 other) {
		return this.x * other.x + this.y * other.y + this.z * other.z;
	}

	public Vector3 cross(Vector3 other) {
		return Vector3(
			this.y * other.z - this.z * other.y,
			this.z * other.x - this.x * other.z,
			this.x * other.y - this.y * other.x);
	}

	public double norm() {
		return Math.hypot(Math.hypot(this.x, this.y), this.z);
	}

	public Vector3 clamp(double len) {
		if (this.norm() > len) {
			return this.unit().scale(len);
		}
		else {
			return this;
		}
	}

	public Vector3 negate() {
		return Vector3(-this.x, -this.y, -this.z);
	}

	public Vector3 unit() {
		return this.scale(1 / this.norm());
	}

	public Vector3 project(Vector3 other) {
		Vector3 dir = other.unit();
		return dir.scale(this.dot(dir));
	}

	public Vector3 rotate(Vector3 rotation) {
		Vector3 par = rotation.scale(this.dot(rotation));
		Vector3 perp = rotation.cross(this);
		double angle = rotation.norm();
		Vector3 term_par = par.scale(cosc(angle));
		Vector3 term_perp = perp.scale(-sinc(angle));
		Vector3 term_vec = this.scale(Math.cos(angle));
		Vector3 result = term_vec.add(term_par).add(term_perp);
		return result;
	}

	public Vector3 transform(Vector3 unit_x, Vector3 unit_y, Vector3 unit_z) {
		return unit_x.scale(this.x)
			.add(unit_y.scale(this.y))
			.add(unit_z.scale(this.z));
	}

	public Vector3 scale(double scale) {
		return Vector3(
			scale * this.x,
			scale * this.y,
			scale * this.z);
	}

	public Vector3 add(Vector3 other) {
		return Vector3(
			this.x + other.x,
			this.y + other.y,
			this.z + other.z);
	}

	public Vector3 sub(Vector3 other) {
		return Vector3(
			this.x - other.x,
			this.y - other.y,
			this.z - other.z);
	}

	public string to_string() {
		return "(" + x.to_string() + ", " + y.to_string() + ", " + z.to_string() + ")";
	}
}

internal struct Bounds {
	Vector p1;
	Vector p2;

	public Bounds(double x1, double y1, double x2, double y2) {
		this.p1 = Vector(x1, y1);
		this.p2 = Vector(x2, y2);
	}

	public Bounds.from_points(Vector p1, Vector p2) {
		this.p1 = p1;
		this.p2 = p2;
	}

	public Bounds3 as_bounds3() {
		return Bounds3.from_points(this.p1.as_vector3(), this.p2.as_vector3());
	}

	public double width() {
		return p2.x - p1.x;
	}
	public double height() {
		return p2.y - p1.y;
	}

	public Vector center() {
		return this.p2.sub(this.p1).scale(0.5).add(this.p1);
	}

	public Bounds add(Vector offset) {
		return Bounds.from_points(p1.add(offset), p2.add(offset));
	}

	public Bounds sub(Vector offset) {
		return Bounds.from_points(p1.sub(offset), p2.sub(offset));
	}

	public Bounds pad(double padding) {
		return Bounds(
			this.p1.x - padding, this.p1.y - padding,
			this.p2.x + padding, this.p2.y + padding);
	}

	public Bounds positive() {
		Bounds result = Util.Bounds(0, 0, 0, 0);
		result.p1.x = Math.fmin(this.p1.x, this.p2.x);
		result.p1.y = Math.fmin(this.p1.y, this.p2.y);
		result.p2.x = Math.fmax(this.p1.x, this.p2.x);
		result.p2.y = Math.fmax(this.p1.y, this.p2.y);
		return result;
	}

	public Bounds pixelize() {
		Bounds result = this.positive();
		result.p1.x = Math.floor(result.p1.x);
		result.p1.y = Math.floor(result.p1.y);
		result.p2.x = Math.ceil(result.p2.x);
		result.p2.y = Math.ceil(result.p2.y);
		return result;
	}

	public Bounds union(Bounds other) {
		return Bounds(
			Math.fmin(this.p1.x, other.p1.x),
			Math.fmin(this.p1.y, other.p1.y),
			Math.fmax(this.p2.x, other.p2.x),
			Math.fmax(this.p2.y, other.p2.y));
	}

	public Bounds intersection(Bounds other) {
		return Bounds(
			Math.fmax(this.p1.x, other.p1.x),
			Math.fmax(this.p1.y, other.p1.y),
			Math.fmin(this.p2.x, other.p2.x),
			Math.fmin(this.p2.y, other.p2.y));
	}
}

internal struct Bounds3 {
	Vector3 p1;
	Vector3 p2;

	public Bounds3(
			double x1, double y1, double z1,
			double x2, double y2, double z2) {
		this.p1 = Vector3(x1, y1, z1);
		this.p2 = Vector3(x2, y2, z2);
	}

	public Bounds3.from_points(Vector3 p1, Vector3 p2) {
		this.p1 = p1;
		this.p2 = p2;
	}

	public Bounds as_bounds() {
		return Bounds.from_points(this.p1.as_vector(), this.p2.as_vector());
	}

	public double width() {
		return p2.x - p1.x;
	}
	public double height() {
		return p2.y - p1.y;
	}
	public double depth() {
		return p2.z - p1.z;
	}

	public Vector3 center() {
		return this.p2.sub(this.p1).scale(0.5).add(this.p1);
	}

	public Bounds3 add(Vector3 offset) {
		return Bounds3.from_points(p1.add(offset), p2.add(offset));
	}

	public Bounds3 sub(Vector3 offset) {
		return Bounds3.from_points(p1.sub(offset), p2.sub(offset));
	}

	public Bounds3 pad(double padding) {
		return Bounds3(
			this.p1.x - padding, this.p1.y - padding, this.p1.z - padding,
			this.p2.x + padding, this.p2.y + padding, this.p2.z + padding);
	}

	public Bounds3 positive() {
		Bounds3 result = Util.Bounds3(0, 0, 0, 0, 0, 0);
		result.p1.x = Math.fmin(this.p1.x, this.p2.x);
		result.p1.y = Math.fmin(this.p1.y, this.p2.y);
		result.p1.z = Math.fmin(this.p1.z, this.p2.z);
		result.p2.x = Math.fmax(this.p1.x, this.p2.x);
		result.p2.y = Math.fmax(this.p1.y, this.p2.y);
		result.p2.z = Math.fmax(this.p1.z, this.p2.z);
		return result;
	}

	public Bounds3 union(Bounds3 other) {
		return Bounds3(
			Math.fmin(this.p1.x, other.p1.x),
			Math.fmin(this.p1.y, other.p1.y),
			Math.fmin(this.p1.z, other.p1.z),
			Math.fmax(this.p2.x, other.p2.x),
			Math.fmax(this.p2.y, other.p2.y),
			Math.fmax(this.p2.z, other.p2.z));
	}

	public Bounds3 intersection(Bounds3 other) {
		return Bounds3(
			Math.fmax(this.p1.x, other.p1.x),
			Math.fmax(this.p1.y, other.p1.y),
			Math.fmax(this.p1.z, other.p1.z),
			Math.fmin(this.p2.x, other.p2.x),
			Math.fmin(this.p2.y, other.p2.y),
			Math.fmin(this.p2.z, other.p2.z));
	}
}

}

