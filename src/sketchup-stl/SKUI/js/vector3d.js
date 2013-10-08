/*******************************************************************************
 *
 * class Vector3d
 *
 ******************************************************************************/


function Vector3d( x, y, z ) {
  this.x = x;
  this.y = y;
  this.z = z;
}
Vector3d.prototype.toString = function()
{
  // (!) Format numbers
  return 'Vector3d(' + this.x + ', ' + this.y + ', ' + this.z + ')';
}
