let allData = [];

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
    return str.toLowerCase().replace(/[^a-z0-9]/g, '');
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
        if (params.startDate && item.dateWhen && parseInt(item.dateWhen) < parseInt(params.startDate)) return false;
        if (params.endDate && item.dateWhen && parseInt(item.dateWhen) > parseInt(params.endDate)) return false;
        return true;
    });
}

function displayResults(results, page = 1, perPage = 20) {
    const start = (page - 1) * perPage;
    const end = start + perPage;
    const pageResults = results.slice(start, end);
    
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
        const truncated = contentSummary.length > 500;
        const displayContent = truncated ? contentSummary.substring(0, 500) : contentSummary;
        
        const msUrl = item.idno || item.corpusUri || '#';
        
        return `
            <div class="result-item" style="padding:15px; border:1px solid #ddd; margin-bottom:10px; border-radius:5px;">
                ${item.title ? `<p><strong>Title:</strong> ${formatValue(item.title, 'title')}</p>` : ''}
                ${item.author ? `<p><strong>Author:</strong> ${formatValue(item.author, 'author')}</p>` : ''}
                ${contentSummary ? `<p><strong>Content:</strong> <span class="content-text" id="content-${index}">${displayContent}${truncated ? '...' : ''}</span>${truncated ? ` <a href="#" class="show-more" data-index="${index}" data-full="${contentSummary.replace(/"/g, '&quot;')}">Show more</a>` : ''}</p>` : ''}
                ${item.corpusUri ? `<p><strong>Corpus Uri:</strong> <a href="${item.corpusUri}" target="_blank">${item.corpusUri}</a></p>` : ''}
                ${item.workUri ? `<p><strong>Syriaca URI:</strong> <a href="${item.workUri}" target="_blank">${item.workUri}</a></p>` : ''}
                ${item.catalogName ? `<p><strong>Catalog:</strong> ${item.catalogName}</p>` : ''}
                <small class="text-muted">
                    ${item.origDate ? `Date: ${item.origDate} | ` : ''}
                    ${item.langUsage ? `Languages: ${item.langUsage.map(l => l.description).join(', ')} | ` : ''}
                    ${item.persName ? `Persons: ${formatValue(item.persName, 'persName')}` : ''}
                </small>
            </div>
        `;
    }).join('');
    
    $('#search-results').html(html || '<p>No results found</p>');
    
    $('.show-more').on('click', function(e) {
        e.preventDefault();
        const index = $(this).data('index');
        const full = $(this).data('full');
        $(`#content-${index}`).text(full);
        $(this).remove();
    });
    
    const totalPages = Math.ceil(results.length / perPage);
    let paginationHtml = '';
    for (let i = 1; i <= totalPages; i++) {
        paginationHtml += `<li class="${i === page ? 'active' : ''}"><a href="#" data-page="${i}">${i}</a></li>`;
    }
    $('.searchPagination').html(paginationHtml);
    
    $('.searchPagination a').on('click', function(e) {
        e.preventDefault();
        const newPage = parseInt($(this).data('page'));
        displayResults(results, newPage, perPage);
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
