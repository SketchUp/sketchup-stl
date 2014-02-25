/*******************************************************************************
 *
 * class String
 *
 ******************************************************************************/


String.prototype.add_slashes = function() {
  var string = this;
  string = string.replace(/\\/g,"\\\\");
  string = string.replace(/\'/g,"\\'");
  string = string.replace(/\"/g,"\\\"");
  return string;
}

//String.prototype.to_css = String.prototype.toString; // Doesn't work.
String.prototype.to_css = function() { return this; }
