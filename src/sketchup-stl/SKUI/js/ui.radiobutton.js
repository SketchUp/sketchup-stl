/*******************************************************************************
 *
 * class UI.RadioButton
 *
 ******************************************************************************/


RadioButton.prototype = new Checkbox();
RadioButton.prototype.constructor = RadioButton;

function RadioButton( jquery_element ) {
  Checkbox.call( this, jquery_element );
}

UI.RadioButton = RadioButton;

RadioButton.add = function( properties ) {
  // Build DOM objects.
  var $control = $('<label/>');
  $control.addClass('control control-radiobutton');
  var $label = $('<span/>');
  var $checkbox = $('<input type="radio" />');
  $checkbox.appendTo( $control );
  $label.appendTo( $control );
  // Initialize wrapper.
  var control = new RadioButton( $control );
  control.update( properties );
  // Set up events.
  UI.add_event( 'change', $control, $checkbox );
  // Attach to document.
  control.attach();
  return control;
}

RadioButton.init = function( properties ) {
  $(document).on('change', 'input[type=radio]', function () {
    if ( $(this).prop('checked') == true ) {
      $control = $(this).parent();
      $siblings = $control.siblings('.control-radiobutton');
      $radiobuttons = $siblings.children('input');
      $radiobuttons.prop('checked', false);
    }
  });
  return;
}
