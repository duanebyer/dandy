namespace Dandy {

using Util;

// This is a utility class that provides methods for projecting 3d points onto
// the 2d drawing surface.
public class Camera {
	Vector3 _pos;
	double _tilt;
	double _fov;
	double _z_near;
	double _z_far;
	Bounds _viewport;

	// This stores the z-coordinate of the back plane.
	double _fov_factor;
	// These store the rotation transformation applied to each basis vector.
	Vector3 _rot_x;
	Vector3 _rot_y;
	Vector3 _rot_z;

	public Vector3 pos {
		get { return this._pos; }
		set { this._pos = value; }
	}
	public double tilt {
		get { return this._tilt; }
		set {
			this._tilt = value;
			this._rot_x = Vector3.UNIT_X.rotate(Vector3.UNIT_X.scale(this._tilt));
			this._rot_y = Vector3.UNIT_Y.rotate(Vector3.UNIT_X.scale(this._tilt));
			this._rot_z = Vector3.UNIT_Z.rotate(Vector3.UNIT_X.scale(this._tilt));
		}
	}
	public double fov {
		get { return this._fov; }
		set {
			this._fov = value;
			this._fov_factor = 1 / Math.tan(0.5 * this._fov);
		}
	}
	public double z_near {
		get { return this._z_near; }
		set { this._z_near = value; }
	}
	public double z_far {
		get { return this._z_far; }
		set { this._z_far = value; }
	}
	public Bounds viewport {
		get { return this._viewport; }
		set { this._viewport = value; }
	}
	// The direction vectors can be calculated using the orthogonality of the
	// rotation transform.
	public Vector3 dir_x {
		get { return Vector3(this._rot_x.x, this._rot_y.x, this._rot_z.x); }
	}
	public Vector3 dir_y {
		get { return Vector3(this._rot_x.y, this._rot_y.y, this._rot_z.y); }
	}
	public Vector3 dir_z {
		get { return Vector3(this._rot_x.z, this._rot_y.z, this._rot_z.z); }
	}

	public Camera(
			Vector3 pos,
			double tilt,
			double fov,
			double z_near, double z_far,
			Bounds viewport) {
		this._pos = pos;
		this._z_near = z_near;
		this._z_far = z_far;
		this._viewport = viewport;
		// Set the properties of tilt and fov to ensure that the cached
		// variables also get updated correctly.
		this.tilt = tilt;
		this.fov = fov;
	}

	// Gives the bounds (in world space) at a certain z-coordinate (in world
	// space). Everything outside of the bounds will not be visible on the
	// camera, although some items inside the bounds may also not be visible.
	public Bounds bounds_at_z(double z) {
		// Find the corner rays of the camera.
		double aspect_ratio = viewport.width() / viewport.height();
		Vector3 viewport_x = this.dir_x;
		Vector3 viewport_y = this.dir_y.scale(1 / aspect_ratio);
		Vector3 viewport_z = this.dir_z.scale(this._fov_factor);
		Vector3 corner_11 = viewport_z.sub(viewport_x).sub(viewport_y);
		Vector3 corner_12 = viewport_z.sub(viewport_x).add(viewport_y);
		Vector3 corner_21 = viewport_z.add(viewport_x).sub(viewport_y);
		Vector3 corner_22 = viewport_z.add(viewport_x).add(viewport_y);
		double z_rel = z - this.pos.z;
		corner_11 = corner_11.scale(z_rel / corner_11.z);
		corner_12 = corner_12.scale(z_rel / corner_12.z);
		corner_21 = corner_21.scale(z_rel / corner_21.z);
		corner_22 = corner_22.scale(z_rel / corner_22.z);
		return Bounds(
			Math.fmin(corner_11.x, corner_12.x),
			Math.fmin(corner_11.y, corner_21.y),
			Math.fmax(corner_21.x, corner_22.x),
			Math.fmax(corner_12.y, corner_22.y));
	}

	// Transforms a point from world coordinates into screen coordinates.
	public Vector3 transform(Vector3 point) {
		Vector3 camera_point = this.camera_transform(point);
		Vector3 project_point = this.project_transform(camera_point);
		Vector3 viewport_point = this.viewport_transform(project_point);
		return viewport_point;
	}

	// Transforms a vector at a point from world coordinates into screen
	// coordinates. This can be used to, for example, find the scaling of the
	// camera at a certain point.
	public Vector3 transform_vector(Vector3 point, Vector3 vec) {
		Vector3 camera_point = this.camera_transform(point);
		Vector3 camera_vec = this.camera_transform_vector(vec);
		Vector3 project_vec = this.project_transform_vector(camera_point, camera_vec);
		Vector3 viewport_vec = this.viewport_transform_vector(project_vec);
		return viewport_vec;
	}

	// The transformation rules between points and vectors are subtlely
	// different. The basic principle is that for any transformation `T`, and
	// point `p` the following property must hold:
	// 
	//     d(T p) = T dp
	// 
	// Since `dp` is a vector formed from the differential of `p` with
	// components `(dx, dy, dz)`, this gives the transformation rule of a vector
	// in terms of the transformation rule of a point.
	private Vector3 camera_transform(Vector3 world_point) {
		return world_point.sub(this._pos)
			.transform(this._rot_x, this._rot_y, this._rot_z);
	}
	private Vector3 camera_transform_vector(Vector3 world_vec) {
		return world_vec
			.transform(this._rot_x, this._rot_y, this._rot_z);
	}

	private double project_transform_z(double z) {
		return (z - this._z_near) / (this._z_far - this._z_near);
	}
	private double project_transform_z_prime(double z) {
		return 1 / (this._z_far - this._z_near);
	}
	private Vector3 project_transform(Vector3 camera_point) {
		double scale_factor = this._fov_factor / camera_point.z;
		return Vector3(
			scale_factor * camera_point.x,
			scale_factor * camera_point.y,
			project_transform_z(camera_point.z));
	}
	private Vector3 project_transform_vector(
			Vector3 camera_point,
			Vector3 camera_vec) {
		double scale_factor = this._fov_factor / camera_point.z;
		return Vector3(
			scale_factor * (
				camera_vec.x - camera_point.x / camera_point.z * camera_vec.z),
			scale_factor * (
				camera_vec.y - camera_point.y / camera_point.z * camera_vec.z),
			project_transform_z_prime(camera_point.z) * camera_vec.z);
	}

	private Vector3 viewport_transform(Vector3 project_point) {
		Vector viewport_center = this._viewport.center();
		double scale = 0.5 * this._viewport.width();
		return Vector3(
			scale * project_point.x + viewport_center.x,
			-scale * project_point.y + viewport_center.y,
			project_point.z);
	}
	private Vector3 viewport_transform_vector(Vector3 project_vec) {
		double scale = 0.5 * this._viewport.width();
		return Vector3(
			scale * project_vec.x,
			-scale * project_vec.y,
			project_vec.z);
	}
}

}

