// Main javascript functions used by place pages
$(document).on('submit','form#email',function(e){
    e.preventDefault();
    $.ajax({
        type:'POST', 
        url: $('#email').attr('action'), 
        data: $('#email').serializeArray(),
        dataType: "html", 
        success: function(response) {
            var temp = response;
            $('div#modal-body').html(temp);
    }});
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

$('#email').validate(
    {
        rules: {
            name: {
                minlength: 2,
                required: true
             },
            comments: {
                minlength: 2,
                required: true
        },
        email: {
            required: true,
            email: true
        }
   }
});