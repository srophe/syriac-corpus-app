let allData = [];

// Number of characters of content shown before the Show more/Show less toggle kicks in
const CONTENT_TRUNCATE_LENGTH = 500;

// Full content text for the results currently on screen, keyed by their index on
// the page. Kept here rather than in a data- attribute so the whole document text
// isn't duplicated into the DOM (and doesn't need HTML-escaping to survive there).
let pageContentText = {};

function escapeHtml(str) {
    return $('<div>').text(str).html();
}

// Determine base URL based on environment
const getBaseUrl = () => {
    const hostname = window.location.hostname;
    if (hostname === 'localhost' || hostname === '127.0.0.1') {
        return 'http://127.0.0.1:5500/exampleData';
    } else if (hostname.includes('dev') || hostname.includes('d2tcgfyrf82nxz')) {
        return 'https://d2tcgfyrf82nxz.cloudfront.net';
    } else if (hostname.includes('bl.syriac.uk')) {
        return 'https://bl.syriac.uk';
    } else {
        return '';
    }
};
const BASE_URL = getBaseUrl();

async function loadData() {
    const response = await fetch('/manuscripts.json');
    allData = await response.json();
}

function normalize(str) {
    if (!str) return '';
    return str.toLowerCase().replace(/\s+/g, ' ').trim();
}

function matchesField(item, field, query) {
    const value = item[field];
    if (!value) return false;
    const normQuery = normalize(query);
    if (Array.isArray(value)) {
        return value.some(v => normalize(v).includes(normQuery));
    }
    return normalize(value).includes(normQuery);
}

function searchData(params) {
    return allData.filter(item => {
        if (params.fullText && !Object.values(item).some(v => 
            (Array.isArray(v) ? v.join(' ') : String(v || '')).toLowerCase().includes(params.fullText.toLowerCase())
        )) return false;
        if (params.author && !matchesField(item, 'author', params.author)) return false;
        if (params.title && !matchesField(item, 'title', params.title)) return false;
        if (params.syriacText && !(
            matchesField(item, 'fullText', params.syriacText) ||
            matchesField(item, 'rubric', params.syriacText)
        )) return false;
        if (params.corpusUri && !matchesField(item, 'corpusUri', params.corpusUri)) return false;
        if (params.syriacaUri && !matchesField(item, 'workUri', params.syriacaUri)) return false;
        if (params.persName && !matchesField(item, 'persName', params.persName)) return false;
        if (params.catalog && !matchesField(item, 'catalog', params.catalog)) return false;
        if (params.startDate || params.endDate) {
            const itemStart = item.dateFrom || item.dateWhen;
            const itemEnd = item.dateTo || item.dateWhen;
            if (!itemStart && !itemEnd) return false;
            if (params.startDate && itemEnd && parseInt(itemEnd) < parseInt(params.startDate)) return false;
            if (params.endDate && itemStart && parseInt(itemStart) > parseInt(params.endDate)) return false;
        }
        return true;
    });
}

function displayResults(results, page = 1, perPage = 20) {
    const start = (page - 1) * perPage;
    const end = start + perPage;
    const pageResults = results.slice(start, end);
    pageContentText = {};
    $('#search-info').html(`<p>Found ${results.length} results</p>`);
    
    const html = pageResults.map((item, index) => {
        const formatValue = (val, key) => {
            if (!Array.isArray(val)) return val;
            const periodFields = ['title'];
            return periodFields.includes(key) ? val.join('. ') : val.join(', ');
        };
        
        // Build content from sections and rubric
        let contentSummary = '';
        if (item.sections && Array.isArray(item.sections)) {
            contentSummary = item.sections.map(s => s.text).join(' ');
        }
        if (item.rubric) {
            contentSummary += ' ' + item.rubric;
        }
        contentSummary = contentSummary.trim().replace(/<[^>]*>/g, '');
const truncated = contentSummary.length > CONTENT_TRUNCATE_LENGTH;
const displayContent = truncated
    ? contentSummary.substring(0, CONTENT_TRUNCATE_LENGTH)
    : contentSummary;

// Store the full text outside the DOM
pageContentText[index] = contentSummary;
        const msUrl = item.idno || item.corpusUri || '#';
        
        return `
            <div class="result-item" style="padding:15px; border:1px solid #ddd; margin-bottom:10px; border-radius:5px;">
                ${item.title ? `<p><strong>Title:</strong> ${formatValue(item.title, 'title')}</p>` : ''}
                ${item.author ? `<p><strong>Author:</strong> ${formatValue(item.author, 'author')}</p>` : ''}
${contentSummary ? `
    <p>
        <strong>Content:</strong>
        <span class="content-text" id="content-${index}">${escapeHtml(displayContent)}${truncated ? '...' : ''}</span>
        ${truncated ? `
            <a href="#"
               class="content-toggle"
               data-index="${index}"
               data-expanded="false">Show more</a>
        ` : ''}
    </p>
` : ''}                ${item.corpusUri ? `<p><strong>Corpus Uri:</strong> <a href="${item.corpusUri}" target="_blank">${item.corpusUri}</a></p>` : ''}
                ${item.workUri ? `<p><strong>Syriaca URI:</strong> <a href="${item.workUri}" target="_blank">${item.workUri}</a></p>` : ''}
                ${item.catalogName ? `<p><strong>Catalog:</strong> ${item.catalogName}</p>` : ''}
                <small class="text-muted">
                    ${item.origDate ? `Date: ${item.origDate} | ` : ''}
                    ${item.langUsage ? `Languages: ${item.langUsage.map(l => l.language).join(', ')} | ` : ''}
                    ${item.persName ? `Persons: ${formatValue(item.persName, 'persName')}` : ''}
                </small>
            </div>
        `;
    }).join('');
    
    $('#search-results').html(html || '<p>No results found</p>');
    
$('.content-toggle').on('click', function(e) {
    e.preventDefault();

    const $link = $(this);
    const index = $link.data('index');
    const $content = $(`#content-${index}`);
    const isExpanded = $link.attr('data-expanded') === 'true';

    if (isExpanded) {
        // Collapse
        const shortText = pageContentText[index]
            .substring(0, CONTENT_TRUNCATE_LENGTH);

        $content.text(shortText + '...');
        $link.text('Show more');
        $link.attr('data-expanded', 'false');
    } else {
        // Expand
        $content.text(pageContentText[index]);
        $link.text('Show less');
        $link.attr('data-expanded', 'true');
    }
});
    
    renderPagination(results.length, perPage, page, function(newPage) {
        displayResults(results, newPage, perPage);
    });
}


function createPaginationButton(pageNumber, onClick) {
    const listItem = document.createElement('li');
    listItem.className = 'page-item';

    const pageLink = document.createElement('a');
    pageLink.href = '#';
    pageLink.className = 'page-link';
    pageLink.dataset.page = String(pageNumber);
    pageLink.textContent = String(pageNumber);
    pageLink.addEventListener('click', function(e) {
        e.preventDefault();
        onClick(pageNumber);
    });

    listItem.appendChild(pageLink);
    return listItem;
}

// Render pagination buttons
function renderPagination(totalResults, resultsPerPage, currentPage, onPageChange) {
    const totalPages = Math.ceil(totalResults / resultsPerPage);
    const paginationContainers = document.getElementsByClassName('searchPagination');

    const maxPageNumbers = 5;

    let startPage = Math.max(1, currentPage - Math.floor(maxPageNumbers / 2));
    let endPage = Math.min(totalPages, startPage + maxPageNumbers - 1);

    if (endPage - startPage + 1 < maxPageNumbers) {
        startPage = Math.max(1, endPage - maxPageNumbers + 1);
    }

    Array.from(paginationContainers).forEach(container => {
        container.innerHTML = '';

        for (let page = startPage; page <= endPage; page++) {
            const pageButton = createPaginationButton(page, () => onPageChange(page));
            if (page === currentPage) {
                pageButton.classList.add('active');
            }
            container.appendChild(pageButton);
        }
    });
}

// JSON search
async function runSearch() {
    await loadData();
    
    const params = new URLSearchParams(window.location.search);
    const searchParams = {
        fullText: params.get('fullText'),
        author: params.get('author'),
        title: params.get('title'),
        catalog: params.get('catalog'),
        lang: params.get('lang'),
        startDate: params.get('startDate'),
        endDate: params.get('endDate'),
        section: params.get('section'),
        persName: params.get('persName'),
        placeName: params.get('placeName'),
        syriacText: params.get('syriacText'),
        corpusUri: params.get('corpusUri'),
        syriacaUri: params.get('syriacaUri')
    };
    

    
    const results = searchData(searchParams);
    displayResults(results);
}
