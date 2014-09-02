// Jquery to help select appropriate header. does not work would have to use session data instead
 $('#topnav').each(function(){
    var referrer =  document.referrer;
    if(!referrer) return; //returns default header in xquery
    if(referrer.toLowerCase().indexOf("geo") !== -1){ //returns default (relative links) header for gazetteer
         $(this).data('template','nav:build-documentation-nav');
    //alert('GEO!')
    }
    if(referrer.toLowerCase().indexOf("/place/") !== -1){ //returns abosloute links header for gazetteer
         $(this).data('template','nav:build-documentation-nav');
    //alert('GEO!')
    }    
    else{ //returns syraca.org header
         $(this).data('template','nav:build-nav-syr');
    } 
});