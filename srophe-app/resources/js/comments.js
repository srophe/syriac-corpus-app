// Main javascript functions used by place pages
// validate contact forms
$.validator.setDefaults({
	submitHandler: function() { 
	//Ajax submit for contact form
    $.ajax({
            type:'POST', 
            url: $('#email').attr('action'), 
            data: $('#email').serializeArray(),
            dataType: "html", 
            success: function(response) {
                var temp = response;
                if(temp == 'Recaptcha fail') {
                    alert('please retry again');
                    Recaptcha.reload();
                }else {
                    $('div#modal-body').html(temp);
                    $('#email-submit').hide();
                    $('#email')[0].reset();
                }
               // $('div#modal-body').html(temp);
        }});
	}
});

$().ready(function() {
    $("#email").validate({
		rules: {
			recaptcha_challenge_field: "required",
			name: "required",
			email: {
				required: true,
				email: true
			},
			subject: {
				required: true,
				minlength: 2
			},
			comments: {
				required: true,
				minlength: 2
			}
		},
		messages: {
			name: "Please enter your name",
            subject: "Please enter a subject",
			comments: "Please enter a comment",
			email: "Please enter a valid email address",
			recaptcha_challenge_field: "Captcha helps prevent spamming. This field cannot be empty"
		}
    });
});