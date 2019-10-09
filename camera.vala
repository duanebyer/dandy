// This is a utility class that provides methods for projecting 3d points onto
// the 2d drawing surface.
public struct Dandy.Camera {
	Util.Point3 pos;
	double tilt;
	double fov;
	Util.Bounds viewport;

	public Camera(double viewport_width, double viewport_height) {
		this.pos = Util.Point3() { x = 0, y = 0, z = 0 };
		this.tilt = 0;
		this.fov = 60 * (Math.PI / 180);
		this.viewport = Util.Bounds() {
			x1 = -0.5 * viewport_width,
			x2 = 0.5 * viewport_width,
			y1 = -0.5 * viewport_height,
			y2 = 0.5 * viewport_height
		};
	}

	// Returns the scaling of an object along x at a certain z.
	public double scale_x(double z) {
		return this.transform(Util.Point3() { x = 1, y = 0, z = 0 }).x;
	}

	// Similarly to scale_x, returns the scaling of an object along y.
	public double scale_y(double z) {
		return this.transform(Util.Point3() { x = 0, y = 1, z = 0 }).y;
	}

	// Transforms a point from world coordinates into screen coordinates.
	public Util.Point3 transform(Util.Point3 point) {
		// Translate the point so that the camera is effectively at the origin.
		Util.Point3 translated_point = Util.Point3() {
			x = point.x - this.pos.x,
			y = point.y - this.pos.y,
			z = point.z - this.pos.z
		};
		// Rotate the point about the x-axis to account for the tilt of the
		// camera.
		double cos_tilt = Math.cos(tilt);
		double sin_tilt = Math.sin(tilt);
		Util.Point3 rotated_point = Util.Point3() {
			x = translated_point.x,
			y = cos_tilt * translated_point.y - sin_tilt * translated_point.z,
			z = sin_tilt * translated_point.y + cos_tilt * translated_point.z
		};
		// Perform the projection. The z-transform is written slightly
		// differently to ensure that it always returns a point between -1 and
		// 1, regardless of the actual z.
		double d = 1 / Math.tan(0.5 * this.fov);
		Util.Point3 projected_point = Util.Point3() {
			x = d / (d + rotated_point.z) * rotated_point.x,
			y = d / (d + rotated_point.z) * rotated_point.y,
			z = 1 / (1 + rotated_point.z) * rotated_point.z
		};
		// Finally, scale by the viewport size. If the viewport is rectangular,
		// use the larger of the two dimensions to set the scale.
		double width = this.viewport.x2 - this.viewport.x1;
		double height = this.viewport.y2 - this.viewport.y1;
		double xc = 0.5 * (this.viewport.x1 + this.viewport.x2);
		double yc = 0.5 * (this.viewport.y1 + this.viewport.y2);
		double scale = 0.5 * Util.max(width, height);
		Util.Point3 viewport_point = Util.Point3() {
			x = scale * projected_point.x + xc,
			y = -scale * projected_point.y + yc,
			z = z
		};

		return viewport_point;
	}
}

