public class Dandy.Util {

	public struct Point {
		double x;
		double y;
	}
	
	public struct Bounds {
		double x1;
		double y1;
		double x2;
		double y2;
	}

	public static double random_sym(double x) {
		return Random.double_range(-x, x);
	}

	public static double min(double x, double y) {
		if (x < y) {
			return x;
		} else {
			return y;
		}
	}

	public static double bound_angle(double alpha) {
		double result = Math.fmod(alpha, 2 * Math.PI);
		if (result > Math.PI) {
			result -= 2 * Math.PI;
		} else if (result < -Math.PI) {
			result += 2 * Math.PI;
		}
		return result;
	}

	public static double lerp(double x1, double x2, double t) {
		return x1 * (1 - t) + x2 * t;
	}

	public static double square(double x) {
		return x * x;
	}

	public static double length(double delta_x, double delta_y) {
		return Math.sqrt(delta_x * delta_x + delta_y * delta_y);
	}

	public static double length_3d(double delta_x, double delta_y, double delta_z) {
		return Math.sqrt(delta_x * delta_x + delta_y * delta_y + delta_z * delta_z);
	}
}

