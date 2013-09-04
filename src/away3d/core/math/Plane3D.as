package away3d.core.math {
	import flash.geom.Point;
	import flash.geom.Vector3D;
	
	import away3d.arcane;
	import away3d.containers.View3D;
	
	use namespace arcane;
	
	public class Plane3D
	{
		private var _a : Number;
		private var _b : Number;
		private var _c : Number;
		private var _d : Number;
		
		private var _maginv:Number; /* Keep track of inverse of (a,b,c) magnitude for distance measurements */
		private var maginvStale:Boolean = true;
		
		private function get maginv(): Number {
			if (maginvStale) {
				_maginv = 1 / Math.sqrt(a*a + b*b + c*c);
				maginvStale = false;
			}
			return _maginv;
		}
		
		arcane var _alignment : int;
		
		// indicates the alignment of the plane
		public static const ALIGN_ANY : int = 0;
		public static const ALIGN_XY_AXIS : int = 1;
		public static const ALIGN_YZ_AXIS : int = 2;
		public static const ALIGN_XZ_AXIS : int = 3;
		
		/**
		 * Create a Plane3D with ABCD coefficients (Ax + By + Cz = D)
		 */
		public function Plane3D(a : Number = 0, b : Number = 0, c : Number = 0, d : Number = 0)
		{
			this.a = a;
			this.b = b;
			this.c = c;
			this.d = d;
			if (a == 0 && b == 0) _alignment = ALIGN_XY_AXIS;
			else if (b == 0 && c == 0) _alignment = ALIGN_YZ_AXIS;
			else if (a == 0 && c == 0) _alignment = ALIGN_XZ_AXIS;
			else _alignment = ALIGN_ANY;
		}
		
		/**
		 * Fills this Plane3D with the coefficients from 3 points in 3d space.
		 * @param p0 Vector3D
		 * @param p1 Vector3D
		 * @param p2 Vector3D
		 */
		public function fromPoints(p0 : Vector3D, p1 : Vector3D, p2 : Vector3D) : void
		{
			var d1x : Number = p1.x - p0.x;
			var d1y : Number = p1.y - p0.y;
			var d1z : Number = p1.z - p0.z;
			
			var d2x : Number = p2.x - p0.x;
			var d2y : Number = p2.y - p0.y;
			var d2z : Number = p2.z - p0.z;
			
			a = d1y * d2z - d1z * d2y;
			b = d1z * d2x - d1x * d2z;
			c = d1x * d2y - d1y * d2x;
			d = a * p0.x + b * p0.y + c * p0.z;
			
			// not using epsilon, since a plane is infinite and a small incorrection can grow very large
			if (a == 0 && b == 0) _alignment = ALIGN_XY_AXIS;
			else if (b == 0 && c == 0) _alignment = ALIGN_YZ_AXIS;
			else if (a == 0 && c == 0) _alignment = ALIGN_XZ_AXIS;
			else _alignment = ALIGN_ANY;
		}
		
		/**
		 * Fills this Plane3D with the coefficients from the plane's normal and a point in 3d space.
		 * @param normal Vector3D
		 * @param point  Vector3D
		 */
		public function fromNormalAndPoint(normal : Vector3D, point : Vector3D) : void
		{
			a = normal.x;
			b = normal.y;
			c = normal.z;
			d = a * point.x + b * point.y + c * point.z;
			if (a == 0 && b == 0) _alignment = ALIGN_XY_AXIS;
			else if (b == 0 && c == 0) _alignment = ALIGN_YZ_AXIS;
			else if (a == 0 && c == 0) _alignment = ALIGN_XZ_AXIS;
			else _alignment = ALIGN_ANY;
		}
		
		/**
		 * Normalize this Plane3D.
		 * @return Plane3D This Plane3D.
		 */
		public function normalize() : Plane3D
		{
			var scale: Number = maginv;
			a *= scale;
			b *= scale;
			c *= scale;
			d *= scale;
			_maginv = 1;
			maginvStale = false;
			return this;
		}
		
		/**
		 * Returns the signed distance between this Plane3D and the point p.
		 * @param p Vector3D
		 * @returns Number
		 */
		public function distance(p : Vector3D) : Number
		{
			if (_alignment == ALIGN_YZ_AXIS)
				return (a*p.x - d)*maginv;
			else if (_alignment == ALIGN_XZ_AXIS)
				return (b*p.y - d)*maginv;
			else if (_alignment == ALIGN_XY_AXIS)
				return (c*p.z - d)*maginv;
			else
				return (a*p.x + b*p.y + c*p.z - d)*maginv;
		}
		
		/**
		 * Classify a point against this Plane3D. (in front, back or intersecting)
		 * @param p Vector3D
		 * @return int Plane3.FRONT or Plane3D.BACK or Plane3D.INTERSECT
		 */
		public function classifyPoint(p : Vector3D, epsilon : Number = 0.01) : int
		{
			// check NaN
			if (d != d) return PlaneClassification.FRONT;
			
			var len : Number = distance(p);
			
			if (len < -epsilon)
				return PlaneClassification.BACK;
			else if (len > epsilon)
				return PlaneClassification.FRONT;
			else
				return PlaneClassification.INTERSECT;
		}
		
		/**
		 * From the camera location for 'view,' shoot a line through a point, 'pt' -- where does the line hit the plane?
		 */
		public function getCurrentIntersection(pt: Point, view: View3D) : Vector3D {
			var direction:Vector3D = view.unproject(pt.x, pt.y);
			//var direction:Vector3D = view.getRay(pt.x, pt.y);
			var origin:Vector3D = new Vector3D(view.camera.x, view.camera.y, view.camera.z, 1);
			direction = direction.subtract(origin);
			direction.normalize();
			return intersects(origin, direction);
		}
		
		/**
		 * From a point, S, shoot a line in the direction of a vector, V -- where does the line hit the plane?
		 * Not finding the plane's intersection with the line that connects two points, S and V, but finding
		 * its intersection with the line that passes thru a point, S, going in a direction, V.
		 */
		public function intersects(S: Vector3D, V: Vector3D) : Vector3D {
			var ptOnPlane : Vector3D = new Vector3D(a, b, c);
			ptOnPlane.scaleBy(d*maginv*maginv);
			var normDotV : Number = a*V.x + b*V.y + c*V.z;
			// Vector is parallel to plane, they won't intersect at a point, sad trombone sound
			if (normDotV == 0) {
				return null;
			}
			var linePtToPlanePt : Vector3D = ptOnPlane.subtract(S);
			var scale : Number = (a*linePtToPlanePt.x + b*linePtToPlanePt.y + c*linePtToPlanePt.z) / normDotV;
			var scaledV : Vector3D = V.clone();
			scaledV.scaleBy(scale);
			return S.add(scaledV);
		}
		
		public function toString() : String
		{
			return "Plane3D [a:" + a + ", b:" + b + ", c:" + c + ", d:" + d + "].";
		}
		
		/**
		 * The A coefficient of this plane. (Also the x dimension of the plane normal)
		 */
		public function get a() : Number {
			return _a;
		}
		
		/**
		 * The B coefficient of this plane. (Also the y dimension of the plane normal)
		 */
		public function get b() : Number {
			return _b;
		}
		
		/**
		 * The C coefficient of this plane. (Also the z dimension of the plane normal)
		 */
		public function get c() : Number {
			return _c;
		}
		
		/**
		 * The D coefficient of this plane. (Also the dot product between normal vector (a,b,c) and any point on plane)
		 */
		public function get d() : Number {
			return _d;
		}
		
		public function set a(a:Number) : void {
			maginvStale = true;
			_a = a;
		}
		
		public function set b(b:Number) : void {
			maginvStale = true;
			_b = b;
		}
		
		public function set c(c:Number) : void {
			maginvStale = true;
			_c = c;
		}
		
		public function set d(d:Number) : void {
			maginvStale = true;
			_d = d;
		}
	}
}
