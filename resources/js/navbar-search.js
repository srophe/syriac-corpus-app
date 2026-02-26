// Navbar search functionality
$(document).ready(function() {
    $('#searchbtn').on('click', function(e) {
        e.preventDefault();
        const keyword = $('#keywordNav').val();
        if (keyword) {
            window.location.href = '/search.html?fullText=' + encodeURIComponent(keyword);
        }
    });
    
    $('#keywordNav').on('keypress', function(e) {
        if (e.which === 13) {
            e.preventDefault();
            const keyword = $(this).val();
            if (keyword) {
                window.location.href = '/search.html?fullText=' + encodeURIComponent(keyword);
            }
        }
    });
});
