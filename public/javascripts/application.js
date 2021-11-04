$(document).ready(function() {

  $("form.delete").submit(function(event) {
    event.preventDefault();
    event.stopPropagation();

    var ok = confirm("Are you sure you want to permanently delete?")
    if (ok) {
      // this.submit();

      var form = $(this); // gives us access to form element
      
      var request = $.ajax({
        url: form.attr("action"),
        method: form.attr("method")
      });

      request.done(function(data, textStatus, jqXHR) {
        if (jqXHR.status === 204 ) {
          form.parent("li").remove();
        } else if (jqXHR.stauts === 200) {
          document.location = data;
        }
      });

      // request.fail(function() {});
    }
  });
});