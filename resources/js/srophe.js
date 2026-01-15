$(document).ready(function() {
// Main javascript functions used by place pages
// validate contact forms
$.validator.setDefaults({
	submitHandler: function() {
	   if($('input#url').val().length == 0)
         { 
       	//Ajax submit for contact form
           $.ajax({
                   type:'POST', 
                   url: $('#email').attr('action'), 
                   data: $('#email').serializeArray(),
                   dataType: "html", 
                   success: function(response) {
                       var temp = response;
                       if(temp == 'Recaptcha fail') {
                           alert('please try again');
                           Recaptcha.reload();
                       }else {
                           $('div#modal-body').html(temp);
                           $('#email-submit').hide();
                           $('#email')[0].reset();
                       }
                      // $('div#modal-body').html(temp);
               }});
        }
        return false;
	}
});

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

//Expand works authored-by in persons page
$('a.getData').click(function(event) {
    event.preventDefault();
    var title = $(this).data('label');
    var URL = $(this).data('ref');
    $("#moreInfoLabel").text(title);
    $('#moreInfo-box').load(URL + " #search-results");
});
    
$('#showSection').click(function(event) {
    event.preventDefault();
    $('#recComplete').load('/documentation/faq.html #selection');
});

//Changes text on toggle buttons, toggle funtion handled by Bootstrap
$('.togglelink').click(function(e){
    e.preventDefault();
    var el = $(this);
    if (el.text() == el.data("text-swap")) {
          el.text(el.data("text-original"));
        } else {
          el.data("text-original", el.text());
          el.text(el.data("text-swap"));
        }
});           

//Load dynamic content
$('.dynamicContent').each(function(index, element) { 
    var url = $(this).data('url');
    var current = $(this) 
    $.get(url, function(data) {
        $(current).html(data);    
    }); 
   });

//hide spinner on load
$('.spinning').hide();

//Load dynamic content
$('.getContent').click(function(index, element) { 
    var url = $(this).data('url');
    var current = $(this) 
    $('.spinning').show();
    $.get(url, function(data) {
        $(current).html(data);
        $('.spinning').hide();
        console.log('Getting data...')
    }); 
   });

 
//RDF
$('#getRDF').children('form').each(function () {
    var url = $(this).attr('action');
    $.get(url, $(this).serialize(), function (data) {
        var showOtherResources = $("#showRDF");
        var dataArray = data.results.bindings;
        if (! jQuery.isArray(dataArray)) dataArray =[dataArray];
        $.each(dataArray, function (currentIndex, currentElem) {
            var relatedResources = 'Resources related to <a href="' + currentElem.uri.value + '">' + currentElem.label.value + '</a> '
            var relatedSubjects = (currentElem.subjects) ? '<div class="indent">' + currentElem.subjects.value + ' related subjects</div>': ''
            var relatedCitations = (currentElem.citations) ? '<div class="indent">' + currentElem.citations.value + ' related citations</div>': ''
            showOtherResources.append('<div>' + relatedResources + relatedCitations + relatedSubjects + '</div>');
        });
    }).fail(function (jqXHR, textStatus, errorThrown) {
                    console.log(textStatus);
    });      
});

//TOC Toggle options

$('input.toggleDisplay').click(function() {
    var display = $(this).data("element");
    $('.'+ display).toggle();
    var section = $('.'+ display).hasClass("tei-head");
    //Change checkbox to active
    $(this).toggleClass( "active" );
        console.log(display);
    });
    
$('button.toggleHead').click(function() {
    $('.head').toggleClass( "hidden" );
    });
    
$('a.sedra').click(function(e) {
    e.stopPropagation();
    e.preventDefault();
    var href = $(this).attr('href');
    $('#sedraDisplay').css('display','block');
    $.get(href, function( data ) {
        $( "#sedraContent div.content" ).html( data );
    }).fail(function() {
        $('#sedraContent div.content').empty();
        $( "#sedraContent div.content" ).html( 'There are no results for this word. Please try using the <a href="http://sedra.bethmardutho.org/">Syriac Dictionary Lookup</a>' );
    });
});
                
$('html').click(function() {
    $('#sedraDisplay').hide();
    $('#footnoteDisplay').hide();
    $('#sedraContent div.content').empty();
    $('#footnoteDisplay div.content').empty();
    })
    
$('#rightCol').click(function(e){
    e.stopPropagation();
    });
                
$('.footnote-ref a').click(function(e) {
    e.stopPropagation();
    e.preventDefault();
    var link = $(this);
    var href = $(this).attr('href');
    var content = $(href).html()
        $('#footnoteDisplay').css('display','block');
        $('#footnoteDisplay').css({'top':e.pageY-50,'left':e.pageX+25, 'position':'absolute'});
        $('#footnoteDisplay div.content').html( content );    
});

//END TOC
if (navigator.appVersion.indexOf("Mac") > -1 || navigator.appVersion.indexOf("Linux") > -1) {
    $('.get-syriac').show();
}

$(function () {
  $('[data-toggle="tooltip"]').tooltip()
})

//Clipboard function for any buttons with clipboard class. Uses clipboard.js
var clipboard = new Clipboard('.clipboard');

clipboard.on('success', function(e) {
    console.info('Action:', e.action);
    console.info('Text:', e.text);
    console.info('Trigger:', e.trigger);
    e.clearSelection();
});

clipboard.on('error', function(e) {
    console.error('Action:', e.action);
    console.error('Trigger:', e.trigger);
});

//add active class to browse tabs
var params = window.location.search;
if(params !== 'undefined' && params !== ''){
    $('.nav-tabs a[href*="' + params + '"]').parents('li').addClass('active');
} else {
    $('.nav-tabs li').first().addClass('active');
}


});