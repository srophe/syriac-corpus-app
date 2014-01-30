$( "#moreInfo" ).click(function() {
  $( "#citation" ).toggle( "slow", function() {
    $( "#moreInfo" ).toggle();
  });
});

$("#less-relation").click(function(){
  $("#toggle-relation").hide();
});

$("#more-relation").click(function(){
  $("#toggle-relation").show();
});



if (navigator.appVersion.indexOf("Mac") > -1 || navigator.appVersion.indexOf("Linux") > -1) {
    $('.get-syriac').show();
}