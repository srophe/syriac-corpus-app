// Script for dynamically changing sort order 
    $( function() {
            var URL = $(location).attr('href');
            $('#date').click( function() {
                event.preventDefault();
                $('#events-list').load(URL +  "&sort=date #events-list");
            });
            $('#manuscript').click( function() {
                event.preventDefault();
                $('#events-list').load(URL + " #events-list");
            });
        } );