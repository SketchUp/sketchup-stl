/*******************************************************************************
 *
 * Utilities
 *
 ******************************************************************************/


Function.prototype.get_typename = function() {
  if (Function.prototype.name === undefined) {
    var funcNameRegex = /function\s([^(]{1,})\(/;
    var results = funcNameRegex.exec( this.toString() );
    return (results && results.length > 1) ? $.trim(results[1]) : "";
  } else {
    return this.name;
  }
}
