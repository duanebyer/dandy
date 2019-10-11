namespace Dandy.Util {

public struct Point {
	double x;
	double y;

	public string to_string() {
		return "(" + x.to_string() + ", " + y.to_string() + ")";
	}
}

public struct Point3 {
	double x;
	double y;
	double z;

	public string to_string() {
		return "(" + x.to_string() + ", " + y.to_string() + ", " + z.to_string() + ")";
	}
}

public struct Bounds {
	double x1;
	double y1;
	double x2;
	double y2;
}

public double random_sym(double x = 1) {
	return Random.double_range(-x, x);
}

public double max(double x, double y) {
	if (x > y) {
		return x;
	} else {
		return y;
	}
}

public double min(double x, double y) {
	if (x < y) {
		return x;
	} else {
		return y;
	}
}

public double bound_angle(double alpha) {
	double result = Math.fmod(alpha, 2 * Math.PI);
	if (result > Math.PI) {
		result -= 2 * Math.PI;
	} else if (result < -Math.PI) {
		result += 2 * Math.PI;
	}
	return result;
}

public double lerp(double x1, double x2, double t) {
	return x1 * (1 - t) + x2 * t;
}

public double square(double x) {
	return x * x;
}

public double length(double delta_x, double delta_y) {
	return Math.sqrt(delta_x * delta_x + delta_y * delta_y);
}

public double length3(double delta_x, double delta_y, double delta_z) {
	return Math.sqrt(delta_x * delta_x + delta_y * delta_y + delta_z * delta_z);
}

}

