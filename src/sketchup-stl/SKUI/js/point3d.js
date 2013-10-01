/*******************************************************************************
 *
 * class Point3d
 *
 ******************************************************************************/


function Point3d( x, y, z ) {
  this.x = x;
  this.y = y;
  this.z = z;
}
Point3d.prototype.toString = function()
{
  // (!) Format numbers
  return 'Point3d(' + this.x + ', ' + this.y + ', ' + this.z + ')';
}
