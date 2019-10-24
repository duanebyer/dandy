namespace Dandy.DrawUtil {

public void orbit_to(
		Cairo.Context ctx,
		Util.Orbit orbit,
		uint seg_count) {
	double delta = 1.0 / (seg_count - 1);
	for (uint seg_idx = 0; seg_idx < seg_count; ++seg_idx) {
		double t = seg_idx * delta;
		Util.Vector next_point = orbit.at(t);
		ctx.line_to(next_point.x, next_point.y);
	}
}

public void blur_image_box(Cairo.ImageSurface image, double blur_rad) {
	// TODO: Check that image has the right format.
	image.flush();
	unowned uchar[] raw_data = image.get_data();
	int width = image.get_width();
	int height = image.get_height();
	int num_passes = 3;
	int blur_pix_rad = (int) Math.sqrt(
		(12 * Util.square(blur_rad) / num_passes + 1));
	for (int i = 0; i < num_passes; ++i) {
		blur_image_rows_box(raw_data, width, height, true, 4, blur_pix_rad);
		blur_image_rows_box(raw_data, width, height, false, 4, blur_pix_rad);
	}
	image.mark_dirty();
}

private void blur_image_rows_box(
		uchar[] data,
		int width,
		int height,
		bool along_x,
		int color_stride,
		int blur_rad) {
	// We call `x` the direction which we are iterating along.
	int x_max = along_x ? width : height;
	int y_max = along_x ? height : width;
	int x_stride = along_x ? 1 : width;
	int y_stride = along_x ? width : 1;
	// This ring buffer will store previous data values so that they can be used
	// together with the accumulator.
	int blur_diam = 2 * blur_rad + 1;
	uint[] data_ring = new uint[blur_diam];
	for (int c = 0; c < color_stride; ++c) {
		for (int y = 0; y < y_max; ++y) {
			for (int data_ring_idx = 0; data_ring_idx < blur_diam; ++data_ring_idx) {
				data_ring[data_ring_idx] = 0;
			}
			int data_ring_idx = 0;
			uint accumulator = 0;
			for (int x = -blur_rad; x < x_max + blur_rad; ++x) {
				int lead_x = x + blur_rad;
				uint new_term = 0;
				uint old_term = data_ring[data_ring_idx];
				if (lead_x >= 0 && lead_x < x_max) {
					int lead_idx =
						(lead_x * x_stride + y * y_stride) * color_stride + c;
					new_term = data[lead_idx];
				}
				accumulator += new_term;
				accumulator -= old_term;
				data_ring[data_ring_idx] = new_term;
				data_ring_idx = (data_ring_idx + 1) % blur_diam;
				if (x >= 0 && x < x_max) {
					int idx = (x * x_stride + y * y_stride) * color_stride + c;
					data[idx] = (uchar) (accumulator / blur_diam).clamp(0, 0xFF);
				}
			}
		}
	}
}

public void blur_image_gaussian(Cairo.ImageSurface image, double blur_rad) {
	// TODO: Check that image has the right format.
	image.flush();
	unowned uchar[] raw_data = image.get_data();
	uint width = image.get_width();
	uint height = image.get_height();
	blur_image_rows_gaussian(raw_data, width, height, true, 4, blur_rad);
	blur_image_rows_gaussian(raw_data, width, height, false, 4, blur_rad);
	image.mark_dirty();
}

private void blur_image_rows_gaussian(
		uchar[] raw_data,
		uint width,
		uint height,
		bool along_x,
		uint color_stride,
		double blur_rad) {
	// We call `x` the direction which we are iterating along.
	uint x_max = along_x ? width : height;
	uint y_max = along_x ? height : width;
	uint x_stride = along_x ? 1 : width;
	uint y_stride = along_x ? width : 1;
	// Calculate the length of a row, to the next largest power of 2.
	uint n_min = x_max;
	uint n = 1;
	while (n < n_min) {
		n *= 2;
	}
	// Calculate our blur function.
	Util.Vector[] gaussian_transform = new Util.Vector[n];
	double gaussian_sum = 0;
	for (uint x = 0; x < n; ++x) {
		double gaussian =
			Math.exp(-Util.square(x / (2 * blur_rad)))
			+ Math.exp(-Util.square((n - x) / (2 * blur_rad)));
		gaussian_transform[x] = Util.Vector(gaussian, 0);
		gaussian_sum += gaussian;
	}
	for (uint x = 0; x < n; ++x) {
		gaussian_transform[x] = gaussian_transform[x].scale(1 / gaussian_sum);
	}
	gaussian_transform = Util.fft(gaussian_transform);
	for (uint y = 0; y < y_max; ++y) {
		for (uint c = 0; c < color_stride; ++c) {
			// Format the data for the Fourier transform.
			Util.Vector[] data = new Util.Vector[n];
			for (uint x = 0; x < x_max; ++x) {
				uint idx = (x * x_stride + y * y_stride) * color_stride + c;
				data[x] = Util.Vector(raw_data[idx], 0);
			}
			for (uint x = x_max; x < n; ++x) {
				data[x] = Util.Vector(0, 0);
			}
			// Transform the data to the frequency domain.
			Util.Vector[] transform = Util.fft(data);
			// Apply a blur in the frequency domain.
			for (uint x = 0; x < n; ++x) {
				transform[x] = transform[x].complex_mul(gaussian_transform[x]);
			}
			// Transform the data back.
			data = Util.ifft(transform);
			// Write the results to the image.
			for (uint x = 0; x < x_max; ++x) {
				uint idx = (x * x_stride + y * y_stride) * color_stride + c;
				raw_data[idx] = (uchar) data[x].x.clamp(0, 0xFF);
			}
		}
	}
}

}

