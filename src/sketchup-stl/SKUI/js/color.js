/*******************************************************************************
 *
 * class Color
 *
 ******************************************************************************/


function Color( r, g, b, a ) {
  a = typeof a !== 'undefined' ? a : 255;
  this.r = r;
  this.g = g;
  this.b = b;
  this.a = a;
}
Color.prototype.toString = function()
{
  return 'Color('+this.r+', '+this.g+', '+this.b+', '+this.a+')';
}
Color.prototype.to_css = function()
{
  if ( this.a < 255 ) {
    css_alpha = this.a / 255.0;
    return 'rgba('+this.r+', '+this.g+', '+this.b+', '+css_alpha+')';
  } else {
    return 'rgb('+this.r+', '+this.g+', '+this.b+')';
  }
}
Color.prototype.opaque = function()
{
  return new Color( this.r, this.g, this.b );
}
