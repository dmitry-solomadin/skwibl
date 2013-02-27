(function( $ ) {
  $.fn.toolbar = function() {

    MAX_WIDTH = 1065
    panelWidth = this.parent().width();

//     this.parent().resize(function(event) {
//       console.log(event);
//     });

    if(panelWidth < MAX_WIDTH) {
      this.append('<li><a href="#" class="tooltipize toolTypeChanger selectable" title="More" data-delay="1000" data-placement="bottom" data-tooltype="more" onclick="window.alert(this)"><img src="/images/room/new/instrument/pan.png" alt="More"/></a></li>');
      $(".instrument_history").remove();
      $(".tooltipize[data-tooltype='clear']").parent().remove();
      $(".tooltipize[data-tooltype='hideshow']").parent().remove();
    } else {
      console.log('restructure me back!');
    }

  };
})(jQuery);
