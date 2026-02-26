// Centralized navbar HTML
const navbarHTML = `

<nav class="navbar navbar-default navbar-fixed-top" role="navigation"> 
   <div class="navbar-header">
      <button type="button" class="navbar-toggle" data-toggle="collapse" data-target="#navbar-collapse-1">
         <span class="sr-only">Toggle navigation</span>
         <span class="icon-bar"></span>
         <span class="icon-bar"></span>
         <span class="icon-bar"></span>
      </button>
      <a class="navbar-brand banner-container" href="/index.html"> 
         <span class="banner-icon">
            <img src="/resources/images/syriac-corpus.svg" alt="" width="50px" />
         </span>
         <span class="banner-text">Digital Syriac Corpus</span>
      </a>
   </div>
   <div class="navbar-collapse collapse pull-right" id="navbar-collapse-1">
      <ul class="nav navbar-nav">
         <li>
            <a href="/browse.html" class="nav-text">Browse</a>
         </li>
         <li class="dropdown">
            <a href="#" class="dropdown-toggle lonely-caret" data-toggle="dropdown">About  <b class="caret"></b></a>
            <ul class="dropdown-menu pull-right">
               <li>
                  <a href="/about.html">About the Project</a>
               </li>
               <li role="presentation" class="divider"></li>
               <li>
                  <a href="/history.html">History of the Project</a>
               </li>
               <li role="presentation" class="divider"></li>
               <li>
                  <a href="/project-team.html">Project Team</a>
               </li>
               <li role="presentation" class="divider"></li>
               <li>
                  <a href="/submissions.html">Submissions to the Corpus</a>
               </li>
               <li role="presentation" class="divider"></li>
               <li>
                  <a href="/contact-us.html">Contact Us</a>
               </li>
               <li role="presentation" class="divider"></li>
               <li>
                  <a href="/documentation/index.html">Documentation</a>
               </li>
            </ul>
         </li>
         <li>
            <a href="/search.html" class="nav-text">Advanced Search</a>
         </li>
         <li>
            <div id="search-wrapper">
               <form class="navbar-form navbar-right search-box" role="search" action="/search.html" method="get">
                  <div class="form-group">
                     <input type="text" class="form-control keyboard" placeholder="search" name="fullText" id="keywordNav" />
                     <div class="keyboard-menu">
                        <button type="button" class="btn btn-default dropdown-toggle" data-toggle="dropdown" aria-haspopup="true" aria-expanded="false" title="Select Keyboard"> <span class="syriaca-icon syriaca-keyboard">  </span><span class="caret"></span></button>                                          
                        <ul class="dropdown-menu">                 
                           <li><a href="#" class="keyboard-select" id="syriac-phonetic" data-keyboard-id="keywordNav">Syriac Phonetic</a></li>                
                           <li><a href="#" class="keyboard-select" id="syriac-standard" data-keyboard-id="keywordNav">Syriac Standard</a></li>                 
                           <li><a href="#" class="keyboard-select" id="qwerty" data-keyboard-id="keywordNav">English QWERTY</a></li>             
                        </ul>        
                     </div>
                     <button class="btn btn-default search-btn" id="searchbtn" type="submit" title="Search">
                        <span class="glyphicon glyphicon-search"></span>
                     </button>                                    
                  </div>
               </form>
            </div>
         </li>
         <li>
            <div class="btn-nav">
               <button class="btn btn-default navbar-btn" id="font" data-toggle="dropdown" aria-haspopup="true" aria-expanded="false" title="Select Font">
                  <span class="glyphicon glyphicon-font"></span>
               </button>    
               <ul class="dropdown-menu dropdown-menu-right" id="swap-font">
                  <li>
                     <a href="#" class="swap-font" id="DefaultSelect" data-font-id="EstrangeloEdessa">Default</a>
                  </li>
                  <li>
                     <a href="#" class="swap-font" id="EstrangeloEdessaSelect" data-font-id="EstrangeloEdessa">Estrangelo Edessa</a>
                  </li>
                  <li>
                     <a href="#" class="swap-font" id="EastSyriacAdiabeneSelect" data-font-id="EastSyriacAdiabene">East Syriac Adiabene</a>
                  </li>
                  <li>
                     <a href="#" class="swap-font" id="SertoBatnanSelect" data-font-id="SertoBatnan">Serto Batnan</a>
                  </li>
                  <li>
                     <a href="/documentation/wiki.html?wiki-page=/How-to-view-Syriac-script&amp;wiki-uri=https://github.com/srophe/syriaca-data/wiki">Help <span class="glyphicon glyphicon-question-sign"></span></a>                           
                  </li>                        
               </ul>
            </div>
         </li>
      </ul>
   </div>
</nav>
`;

document.addEventListener('DOMContentLoaded', function() {
   document.body.insertAdjacentHTML('afterbegin', navbarHTML);
});
