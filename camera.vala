namespace Dandy {

using Util;

// This is a utility class that provides methods for projecting 3d points onto
// the 2d drawing surface.
public struct Camera {
	Vector3 pos;
	double tilt;
	double fov;
	Bounds viewport;
	// The distance from the camera at which drawing happens with a scale of
	// one.
	double reference_distance;

	// Returns the scaling of an object along x at a certain point.
	public double scale_x(Vector3 point) {
		return this.transform(point).x;
	}

	// Similarly to scale_x, returns the scaling of an object along y.
	public double scale_y(Vector3 point) {
		return this.transform(point).y;
	}

	// Transforms a point from world coordinates into screen coordinates.
	// TODO: incorporate the reference distance into this function. At the
	// reference distance, a camera with no tilt should identically return the
	// same point that it was given in.
	public Vector3 transform(Vector3 point) {
		// Translate the point so that the camera is effectively at the origin.
		Vector3 translated_point = point.sub(this.pos);
		// Rotate the point about the x-axis to account for the tilt of the
		// camera.
		double cos_tilt = Math.cos(tilt);
		double sin_tilt = Math.sin(tilt);
		Vector3 rotated_point = translated_point.rotate(
			Vector3.UNIT_X.scale(this.tilt));
		// Perform the projection. The z-transform is written slightly
		// differently to ensure that it always returns a point between -1 and
		// 1, regardless of the actual z.
		double d = 1 / Math.tan(0.5 * this.fov);
		Vector3 projected_point = Vector3(
			d / (d + rotated_point.z) * rotated_point.x,
			d / (d + rotated_point.z) * rotated_point.y,
			1 / (1 + rotated_point.z) * rotated_point.z);
		// Finally, scale by the viewport size. If the viewport is rectangular,
		// use the larger of the two dimensions to set the scale.
		double width = this.viewport.width();
		double height = this.viewport.height();
		Vector viewport_center = this.viewport.center();
		double scale = 0.5 * double.max(width, height);
		Vector3 viewport_point = Vector3(
			scale * projected_point.x + viewport_center.x,
			-scale * projected_point.y + viewport_center.y,
			projected_point.z);

		return viewport_point;
	}
}

}

