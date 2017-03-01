function onLoad(action) {
  $(document).ready(action);
  $(document).on('page:load', action);
  // $('body').on('shown.bs.modal', action);
}

$(document).ready(function() {
  $('a[disabled=disabled]').click(function(event){
    event.preventDefault();
  });
});
