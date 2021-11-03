$(document).ready(function() {
  $("form.delete").submit( function(event) {
    event.preventDefault();
    event.stopPropagation();

    var ok = confirm("Are you sure you want to permanently delete?")
    if (ok) {
      this.submit();
    }
  });
});