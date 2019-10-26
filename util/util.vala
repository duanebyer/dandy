namespace Dandy.Util {

public void swap<T>(ref T a, ref T b) {
	T temp = a;
	a = b;
	b = temp;
}

public int compare(double a, double b) {
	if (a > b) {
		return 1;
	} else if (a < b) {
		return -1;
	} else {
		return 0;
	}
}

public double random_sym(double x = 1) {
	return Random.double_range(-x, x);
}

public double bound_angle(double angle) {
	double result = Math.fmod(angle, 2 * Math.PI);
	if (result > Math.PI) {
		result -= 2 * Math.PI;
	} else if (result < -Math.PI) {
		result += 2 * Math.PI;
	}
	return result;
}

public double lerp(double f1, double f2, double t) {
	return f1 * (1 - t) + f2 * t;
}

public double lerp_2(
		double f11, double f12, double f21, double f22,
		double t1, double t2) {
	return (1 - t1) * (1 - t2) * f11
		+ t1 * (1 - t2) * f12
		+ (1 - t1) * t2 * f21
		+ t1 * t2 * f22;
}

public double square(double x) {
	return x * x;
}

// I call the "cosc(x)" function to be:
// cosc(x) = (1 - cos(x)) / x^2
public double cosc(double x) {
	if (x.is_infinity() != 0) {
		return 0;
	} else if (x.is_nan()) {
		return x;
	} else {
		double cos_x = Math.cos(x);
		double result = (1 - cos_x) / (x * x);
		// For small x, we need to compute cosc using the series.
		if (x.abs() < 1 && !result.is_normal()) {
			result = 0;
			double x_pow = 1;
			double factorial = 2;
			double term = 0;
			uint next_factorial = 3;
			do {
				term = x_pow / factorial;
				x_pow = -x_pow;
				x_pow *= x;
				x_pow *= x;
				factorial *= next_factorial;
				factorial *= next_factorial + 1;
				next_factorial += 2;
				result += term;
			} while (term != 0);
		}
		return result;
	}
}

public double sinc(double x) {
	if (x.is_infinity() != 0) {
		return 0;
	} else if (x.is_nan()) {
		return x;
	} else {
		double sin_x = Math.sin(x);
		double result = sin_x / x;
		// For small x, we need to compute sinc using the series.
		if (x.abs() < 1 && !result.is_normal()) {
			result = 0;
			double x_pow = 1;
			double factorial = 1;
			double term = 0;
			uint next_factorial = 2;
			do {
				term = x_pow / factorial;
				x_pow = -x_pow;
				x_pow *= x;
				x_pow *= x;
				factorial *= next_factorial;
				factorial *= next_factorial + 1;
				next_factorial += 2;
				result += term;
			} while (term != 0);
		}
		return result;
	}
}

}

