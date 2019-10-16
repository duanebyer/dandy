namespace Dandy.Util {

public struct Vector {
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

	public string to_string() {
		return "(" + x.to_string() + ", " + y.to_string() + ")";
	}
}

public struct Vector3 {
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

public struct Bounds {
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

	public double width() {
		return p2.x - p1.x;
	}

	public double height() {
		return p2.y - p1.y;
	}

	public Vector center() {
		return this.p2.sub(this.p1).scale(0.5).add(this.p1);
	}
}

}

