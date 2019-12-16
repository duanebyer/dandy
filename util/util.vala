namespace Dandy.Util {

internal void swap<T>(ref T a, ref T b) {
	T temp = a;
	a = b;
	b = temp;
}

internal int compare(double a, double b) {
	if (a > b) {
		return 1;
	} else if (a < b) {
		return -1;
	} else {
		return 0;
	}
}

internal double random_sym(double x = 1) {
	return Random.double_range(-x, x);
}

internal double bound_angle(double angle) {
	double result = Math.fmod(angle, 2 * Math.PI);
	if (result > Math.PI) {
		result -= 2 * Math.PI;
	} else if (result < -Math.PI) {
		result += 2 * Math.PI;
	}
	return result;
}

internal double lerp(double f1, double f2, double t) {
	return f1 * (1 - t) + f2 * t;
}

internal double square(double x) {
	return x * x;
}

// I define the "cosc(x)" function to be analogous to the sinc(x) function:
// cosc(x) = (1 - cos(x)) / x^2
internal double cosc(double x) {
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

internal double sinc(double x) {
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

