/*******************************************************************************
 *
 * class UI.Container
 *
 ******************************************************************************/


Container.prototype = new Control();
Container.prototype.constructor = Container;

function Container( jquery_element ) {
  Control.call( this, jquery_element );
}

UI.Container = Container;

Container.add = function( properties ) {
  // Build DOM objects.
  var $control = $('<div/>');
  $control.addClass('container control control-container');
  // Initialize wrapper.
  var control = new Container( $control );
  control.update( properties );
  // Attach to document.
  control.attach();
  return control;
}
