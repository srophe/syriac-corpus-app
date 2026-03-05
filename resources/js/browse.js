console.log('browse.js loaded!');
console.log('jQuery loaded?', typeof $ !== 'undefined');

let allData = [];

async function loadData() {
    const response = await fetch('/manuscripts.json');
    allData = await response.json();
}

function browseAlphaMenu() {
    const params = new URLSearchParams(window.location.search);
    const lang = params.get('lang') || 'en';
    
    const engAlphabet = 'A B C D E F G H I J K L M N O P Q R S T U V W X Y Z';
    const syrAlphabet = 'ܐ ܒ ܓ ܕ ܗ ܘ ܙ ܚ ܛ ܝ ܟ ܠ ܡ ܢ ܣ ܥ ܦ ܩ ܪ ܫ ܬ';
    
    const alphabet = (lang === 'syr') ? syrAlphabet : engAlphabet;
    const menuContainer = document.getElementById('abcMenu');
    
    console.log('Menu container:', menuContainer);
    console.log('Language:', lang);
    console.log('Alphabet:', alphabet);
    
    if (!menuContainer) {
        console.error('abcMenu element not found!');
        return;
    }
    
    menuContainer.innerHTML = '';
    menuContainer.style.direction = (lang === 'syr') ? 'rtl' : 'ltr';
    
    alphabet.split(' ').forEach(letter => {
        const li = document.createElement('li');
        const a = document.createElement('a');
        a.href = '#';
        a.textContent = letter;
        a.onclick = (e) => {
            e.preventDefault();
            getBrowse(letter);
        };
        li.appendChild(a);
        menuContainer.appendChild(li);
    });
    
    console.log('Added', menuContainer.children.length, 'letters');
    }


function getBrowse(letter) {
    const params = new URLSearchParams(window.location.search);
    const view = params.get('view') || 'author';

    const lang = params.get('lang') || 'en';
    
    let grouped = {};
    let authorCounts = {};
    let catalogCounts = {};
    
    allData.forEach(item => {
        let key;
        if (view === 'title' && item.title || lang === 'syr' && item.title) {
            key = Array.isArray(item.title) ? item.title[0] : item.title;
        } else if (item.author) {
            key = Array.isArray(item.author) ? item.author[0] : item.author;
        } else {
            key = Array.isArray(item.title) ? item.title[0] : item.title;
        }
        console.log("key",key);
        
        // Filter by letter if provided
          if (letter && key) {
            const params = new URLSearchParams(window.location.search);
            const lang = params.get('lang');
            
            if (lang === 'syr') {
                // For Syriac, match last letter (rightmost)
                const lastChar = key.charAt(key.length - 1);
                console.log("lastchar", lastChar);
                if (lastChar !== letter) {
                    return;
                }
            } else {
                // For English, match first letter
                const firstChar = key.charAt(0).toLowerCase();
                if (firstChar !== letter.toLowerCase()) {
                    return;
                }
            }
        }

        if (key) {
            if (!grouped[key]) grouped[key] = [];
            grouped[key].push(item);
        }
        
        // Count authors
        const authors = Array.isArray(item.author) ? item.author : [item.author];
        authors.forEach(a => {
            if (a) authorCounts[a] = (authorCounts[a] || 0) + 1;
        });
        
        // Count catalogs
        if (item.catalogName) {
            catalogCounts[item.catalogName] = (catalogCounts[item.catalogName] || 0) + 1;
        }
    });
    
    // Populate author facets
    const authorFacets = document.getElementById('author-facets');
    authorFacets.innerHTML = Object.entries(authorCounts)
        .sort((a, b) => b[1] - a[1])
        .map(([author, count]) => `<li><a href="#" data-author="${author}" style="color:#337ab7;">${author} (${count})</a></li>`)
        .join('');
    
    // Add click handlers for author facets
    authorFacets.querySelectorAll('a').forEach(link => {
        link.onclick = (e) => {
            e.preventDefault();
            filterByAuthor(link.dataset.author);
        };
    });
    
    // Populate catalog facets
    const catalogFacets = document.getElementById('catalog-facets');
    catalogFacets.innerHTML = Object.entries(catalogCounts)
        .sort((a, b) => b[1] - a[1])
        .map(([name, count]) => `<li><a href="#" data-catalog="${name}" style="color:#337ab7;">${name} (${count})</a></li>`)
        .join('');
    
    // Add click handlers for catalog facets
    catalogFacets.querySelectorAll('a').forEach(link => {
        link.onclick = (e) => {
            e.preventDefault();
            filterByCatalog(link.dataset.catalog);
        };
    });
    
    const sorted = Object.keys(grouped).sort();
    let html = '';
    
    sorted.forEach(key => {
        const items = grouped[key];
        html += `<div class="browse-group" style="margin-bottom:20px;">
            <h3>${key}</h3>`;
        
        items.forEach(item => {
            const title = Array.isArray(item.title) ? item.title.join('. ') : item.title;
            const author = Array.isArray(item.author) ? item.author.join(', ') : item.author;
            html += `<div style="padding:10px; border-bottom:1px solid #eee;">
                <strong>${title || 'Untitled'}</strong><br>
                <em>${item.catalogName || 'Untitled'}</em><br>

                ${item.corpusUri ? `<a href="${item.corpusUri}" target="_blank">${item.corpusUri}</a>` : ''}
            </div>`;
        });
        
        html += '</div>';
    });
    
    document.getElementById('search-results').innerHTML = html;
    const resultCount = Object.values(grouped).reduce((sum, items) => sum + items.length, 0);
    document.getElementById('search-info').innerHTML = `<p>Found ${resultCount} works</p>`;
}


function filterByAuthor(author) {
    let html = '';
    const filtered = allData.filter(item => {
        const authors = Array.isArray(item.author) ? item.author : [item.author];
        return authors.includes(author);
    });
    
    filtered.forEach(item => {
        const title = Array.isArray(item.title) ? item.title.join('. ') : item.title;
        html += `<div style="padding:10px; border-bottom:1px solid #eee;">
            <strong>${title || 'Untitled'}</strong><br>
            ${item.corpusUri ? `<a href="${item.corpusUri}" target="_blank">${item.corpusUri}</a>` : ''}
        </div>`;
    });
    
    document.getElementById('search-results').innerHTML = html;
    document.getElementById('search-info').innerHTML = `<p>Found ${filtered.length} works by ${author}</p>`;
}

function filterByCatalog(catalog) {
    let html = '';
    const filtered = allData.filter(item => item.catalogName === catalog);
    
    filtered.forEach(item => {
        const title = Array.isArray(item.title) ? item.title.join('. ') : item.title;
        html += `<div style="padding:10px; border-bottom:1px solid #eee;">
            <strong>${title || 'Untitled'}</strong><br>
            ${item.corpusUri ? `<a href="${item.corpusUri}" target="_blank">${item.corpusUri}</a>` : ''}
        </div>`;
    });
    
    document.getElementById('search-results').innerHTML = html;
    document.getElementById('search-info').innerHTML = `<p>Found ${filtered.length} works in ${catalog}</p>`;
}
