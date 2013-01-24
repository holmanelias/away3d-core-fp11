package away3d.primitives
{
	
	import flash.geom.Vector3D;
	import away3d.core.base.CompactSubGeometry;

	public class QuadrilateralGeometry extends PrimitiveBase
	{
		
		private var pts:Vector.<Vector3D>;
		//private var _segmentsH:int = 1;
		//private var _segmentsW:int = 1;
		
		public function QuadrilateralGeometry(pts: Vector.<Vector3D>)
		{
			this.pts = pts;
		}		
		
		/**
		 * Updates the vertex data. All vertex properties are contained in a single Vector, and the order is as follows:
		 * 0 - 2: vertex position X, Y, Z
		 * 3 - 5: normal X, Y, Z
		 * 6 - 8: tangent X, Y, Z
		 * 9 - 10: U V
		 * 11 - 12: Secondary U V
		 */
		protected override function buildGeometry(target : CompactSubGeometry) : void
		{
			var numVerts : uint = 4;
			var data : Vector.<Number>;
			var indices : Vector.<uint>;
			var stride:uint = target.vertexStride;
			var skip:uint = stride - 9;
			if (numVerts == target.numVertices) {
				data = target.vertexData; 
				indices = target.indexData;
			}
			else {
				data = new Vector.<Number>(numVerts * stride, true);
				indices = new Vector.<uint>(6, true);
				invalidateUVs();
			}
			numVerts = 0;
			var index : uint = target.vertexOffset;
			for(var i:int = 0; i < 4; i++) {
				var pt:Vector3D = pts[i]; 
				data[index++] = pt.x;
				data[index++] = pt.y;
				data[index++] = pt.z;
				data[index++] = 0;
				data[index++] = 0;
				data[index++] = 1;
				data[index++] = 1;
				data[index++] = 0;				
				data[index++] = 0;
				index += skip;
			}
			indices[0] = 0;
			indices[1] = 1;
			indices[2] = 2;
			indices[3] = 0;
			indices[4] = 2;
			indices[5] = 3;
			target.updateData(data);
			target.updateIndexData(indices);
		}
	
		override protected function buildUVs(target : CompactSubGeometry) : void
		{			
			var data : Vector.<Number>;
			var stride:uint = target.UVStride;
			var numUvs : uint = 8 * stride;
			var skip:uint = stride - 2;
			
			if (target.UVData && numUvs == target.UVData.length)
				data = target.UVData;
			else {
				data = new Vector.<Number>(numUvs, true);
				invalidateGeometry();
			}
			
			var index : uint = target.UVOffset;
			data[index++] = 0;
			data[index++] = 0;
			index += skip;
			data[index++] = 1;
			data[index++] = 0;
			index += skip;
			data[index++] = 1;
			data[index++] = 1;
			index += skip;
			data[index++] = 0;
			data[index++] = 1;
			target.updateData(data);
		}
	}
}