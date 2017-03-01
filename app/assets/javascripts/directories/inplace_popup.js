function inplaceResetChildren(children) {
  //debugger;
  $(children).each(function(index,elem) {
    $(`#${elem}_id`).val('').trigger('change');
    if (!$(`#${elem}_remove`).hasClass('hide')) {
        $(`#${elem}_remove`).addClass('hide');
    }
    $(`#${elem}_value`).val('');
  });
}




onLoad(function() {
  //multimodals
  $(document).on('show.bs.modal', '.modal', function () {
    var zIndex = 1040 + (10 * $('.modal:visible').length);
    $(this).css('z-index', zIndex);
    setTimeout(function() {
        $('.modal-backdrop').not('.modal-stack').css('z-index', zIndex - 1).addClass('modal-stack');
      }, 0);
  });


  $(document).on('hidden.bs.modal', '.modal', function () {
      $('.modal:visible').length && $(document.body).addClass('modal-open');
  });

});


function loadPopup(url, _filters, field_id, popup_id, valueInput, removeInput, id, value_field) {

  if ( $(`#${popup_id}`).length > 0)  {
    //$(`#${popup_id}`).modal({ 'backdrop': 'static' });
    $(`#${popup_id}`).modal('hide');
    $(`#${popup_id}`).remove();
  }

    $.ajax({
      url: url+'.js?'+`popup_id=${popup_id}&`+`field_id=${field_id}&`+`value_field=${value_field}&`+_filters,
      method: 'GET',
      dataType: 'script'
    });
}
