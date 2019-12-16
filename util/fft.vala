namespace Dandy.Util {

internal Vector[] fft(Vector[] data) {
	uint n = data.length;
	Vector[] transform = new Vector[n];
	fft_internal(data, transform, 1, 0, -1);
	return transform;
}

internal Vector[] ifft(Vector[] transform) {
	uint n = transform.length;
	Vector[] data = new Vector[n];
	fft_internal(transform, data, 1, 0, 1);
	for (int idx = 0; idx < data.length; ++idx) {
		data[idx] = data[idx].scale(1.0 / data.length);
	}
	return data;
}

private void fft_internal(
		Vector[] data,
		Vector[] transform,
		uint stride,
		uint offset,
		int exp_sign) {
	uint n = data.length / stride;
	if (n == 1) {
		transform[0] = data[offset];
	} else {
		fft_internal(
			data,
			transform[0:(n / 2)],
			2 * stride,
			offset,
			exp_sign);
		fft_internal(
			data,
			transform[(n / 2):n],
			2 * stride,
			offset + stride,
			exp_sign);
		for (uint k = 0; k < n / 2; ++k) {
			Vector x = transform[k];
			Vector y = transform[n / 2 + k];
			Vector exp = Vector.polar(1, 2 * exp_sign * Math.PI * k / n);
			transform[k] = x.add(exp.complex_mul(y));
			transform[n / 2 + k] = x.sub(exp.complex_mul(y));
		}
	}
}

}

