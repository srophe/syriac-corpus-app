$( "#moreInfo" ).click(function() {
  $( "#citation" ).toggle( "slow", function() {
    $( "#moreInfo" ).toggle();
  });
});

if (navigator.appVersion.indexOf("Mac") > -1 || navigator.appVersion.indexOf("Linux") > -1) {
    $('.get-syriac').show();
}