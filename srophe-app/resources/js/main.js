// Toggle for citation
$( "#moreInfo" ).click(function() {
  $( "#citation" ).toggle( "slow", function() {
    $( "#moreInfo" ).toggle();
  });
});

// Toggel for related places
$( "#more-relation" ).click(function() {
  $(this).text($(this).text() == '(see list)' ? '(hide list)' : '(see list)'); 
  $( "#toggle-relation" ).toggle( "slow");
});

//hide related places
$("#less-relation").click(function(){
  $("#toggle-relation").hide();
});


if (navigator.appVersion.indexOf("Mac") > -1 || navigator.appVersion.indexOf("Linux") > -1) {
    $('.get-syriac').show();
}

