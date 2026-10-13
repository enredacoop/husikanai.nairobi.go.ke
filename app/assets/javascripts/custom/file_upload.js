(function() {
  "use strict";
  // Submits the form as soon as a file is chosen, so the (hidden) file input
  // only needs a button-like label to open the file picker
  App.FileUpload = {
    initialize: function() {
      $(".js-file-upload").off("change.fileUpload").on("change.fileUpload", function() {
        var label = $(this).closest(".file-upload-button");

        if (this.files.length > 0) {
          label.addClass("disabled").find("span").text(label.data("importing"));
          $(this).closest("form").trigger("submit");
        }
      });
    }
  };
}).call(this);
