namespace Dandy.Draw {

using Dandy.Util;

public struct LandscapeParams {
	double curvature;
	Point3 vertex;

	public static double height(
			LandscapeParams landscape,
			double x,
			double z) {
		return landscape.vertex.y + landscape.curvature
			* (square(x - landscape.vertex.x) + square(z - landscape.vertex.z));
	}
}

public struct LandscapeDetails {
}

