xquery version "3.0";

(:~
 : Provides html metadata. Passes data to page.html via config.xqm
 :)
module namespace search-form="http://syriaca.org//search-form";

import module namespace config="http://syriaca.org//config" at "config.xqm";
import module namespace place="http://syriaca.org//place" at "place.xql";

declare namespace xslt="http://exist-db.org/xquery/transform";
declare namespace tei="http://www.tei-c.org/ns/1.0";
declare namespace xlink = "http://www.w3.org/1999/xlink";
declare namespace transform="http://exist-db.org/xquery/transform";

(:~
 : Builds advanced search form
 :)
declare function search-form:show-form() {   
<form method="get" action="search.html" style="margin-top:2em;">
    <div class="well well-small">
        <div class="navbar-inner" style="margin:-.75em -.75em 1em;">
            <h3>Advanced Search</h3>
        </div>
        <div class="well well-small" style="background-color:white;">
            <div class="row-fluid">
                <div class="span8" style="border-right:1px solid #ccc;">
                    <div class="row-fluid" style="margin-top:1em;">
                    <div class="span3">Keyword: </div>
                    <div class="span9"><input type="text" name="q"/></div>
                    </div>
                    <!-- Place Name-->
                    <div class="row-fluid">
                        <div class="span3">Place Name: </div>
                        <div class="span9"><input type="text" name="p"/></div>
                    </div>
                    <!-- Location -->    
                    <div class="row-fluid">
                        <div class="span3">Location: </div>
                        <div class="span9"><input type="text" name="loc"/></div>
                        <!-- Will need to be worked out so a range can be searched 
                                        <label>Coords: </label>
                                        <input type="text" name="lat"/> - <input type="text" name="long"/> 
                                        --> 
                    </div>
                    <hr/>
                    <div class="row-fluid">
                         <div class="span3">Events: </div>
                         <div class="span9"><input type="text" name="e"/></div>
                     </div>
                     <div class="row-fluid">
                         <div class="span3">Dates: </div>
                         <div class="span9 form-inline">
                             <input type="text" name="eds" placeholder="Start Date" class="input-small"/>&#160;
                             <input type="text" name="ede" placeholder="End Date" class="input-small"/>
                             <p class="hint" style="margin:.5em; color: grey; font-style:italic;">* Dates should be entered as YYYY or YYYY-MM-DD</p>
                         </div>
                     </div>
                     <hr/>
                     <!-- Attestations -->
                     <div class="row-fluid">
                         <div class="span3">Attestations: </div>
                         <div class="span9"><input type="text" name="a"/></div>
                     </div>
                     <div class="row-fluid">
                         <div class="span3">Dates: </div>
                         <div class="span9 form-inline">
                             <input type="text" name="ads" placeholder="Start Date" class="input-small"/>&#160;
                             <input type="text" name="ade" placeholder="End Date" class="input-small"/>
                             <p class="hint" style="margin:.5em; color: grey; font-style:italic;">* Dates should be entered as YYYY or YYYY-MM-DD</p>
                         </div>
                     </div>
                     <hr/>
                     <!-- Confessions -->
                     <div class="row-fluid">
                         <div class="span3">Religious Communities: </div>
                         <div class="span9">
                         <select name="c">
                            <option value="">-- Select --</option>
                                {for $confession in doc('/db/apps/srophe/documentation/confessions.xml')//tei:item
                                 return 
                                 <option value="{$confession/child::tei:label}">
                                 {
                                    (for $confession-parent in $confession/ancestor::tei:item return '&#160;',
                                     $confession/child::tei:label)
                                 }
                                 </option>
                                }
                                
                        </select>
                         </div>
                     </div>
                     <div class="row-fluid">
                         <div class="span3">Dates: </div>
                         <div class="span9 form-inline">    
                             <input type="text" name="cds" placeholder="Start Date" class="input-small"/>&#160;
                             <input type="text" name="cde" placeholder="End Date" class="input-small"/>
                             <p class="hint" style="margin:.5em; color: grey; font-style:italic;">* Dates should be entered as YYYY or YYYY-MM-DD</p>
                         </div>
                     </div>
                     <hr/>
                     <!-- Existence -->
                     <div class="row-fluid">
                        <div class="span3">Existence </div>
                     </div>
                     <div class="row-fluid">
                         <div class="span3">Dates: </div>
                         <div class="span9 form-inline">
                             <input type="text" name="existds" placeholder="Start Date" class="input-small"/>&#160;
                             <input type="text" name="existde" placeholder="End Date" class="input-small"/>
                             <p class="hint" style="margin:.5em; color: grey; font-style:italic;">* Dates should be entered as YYYY or YYYY-MM-DD</p>
                         </div>
                     </div>
                     
                </div>
                <div class="span4">
                      <!-- Place Type -->
                    <div style="margin-top:1em; padding-left:.5em;">
                        <label>Place Type:</label>
                            <!-- Values from controlled vocab in https://docs.google.com/spreadsheet/ccc?key=0AnhFTnX2Mw6YdGFieExCX0xIQ3Q0WnBOQmlnclo0WlE&usp=sharing#gid=1-->
                            <select name="type" class="input-medium">
                                <option value="">- Select -</option>
                                <option value="building">building</option>
                                <option value="church">church</option>
                                <option value="diocese">diocese</option>
                                <option value="fortification">fortification</option>
                                <option value="island">island</option>
                                <option value="madrasa">madrasa</option>
                                <option value="monastery">monastery</option>
                                <option value="mosque">mosque</option>
                                <option value="mountain">mountain</option>
                                <option value="open-water">open-water</option>
                                <option value="parish">parish</option>
                                <option value="province">province</option>
                                <option value="quarter">quarter</option>
                                <option value="region">region</option>
                                <option value="river">river</option>
                                <option value="settlement">settlement</option>
                                <option value="state">state</option>
                                <option value="synagogue">synagogue</option>
                                <option value="temple">temple</option>
                                <option value="unknown">unknown</option>
                            </select>
                    <hr/>
                    <!-- Language -->
                        <label>Language: </label>
                        <div class="offset1">
                            <input type="checkbox" name="en" value="en"/> English<br/>
                            <input type="checkbox" name="ar" value="ar"/> Arabic<br/>
                            <input type="checkbox" name="syr" value="syr"/> Syriac<br/>
                        </div>

                    </div>
                </div>
            </div>
        </div>
        <div class="pull-right">
            <button type="submit" class="btn btn-info">Search</button>&#160;
            <button type="reset" class="btn">Clear</button>
        </div>
        <br class="clearfix"/><br/>
    </div>    
</form>
};

(:~
 : Builds advanced search form for persons
 :)
declare function search-form:persons() {   
<form method="get" action="search.html" id="search-form">
    <div class="well well-small">
        <div class="navbar-inner search-header">
            <h3>Advanced Search</h3>
        </div>
        <div class="well well-small search-inner">
            <div class="row-fluid">
                <div class="span12">
                    <div class="row-fluid" style="margin-top:1em;">
                        <div class="span2">Keyword: </div>
                        <div class="span10"><input type="text" name="q"/></div>
                    </div>
                    
                    <!-- Place Name-->
                    <div class="row-fluid">
                        <div class="span2">Person Name: </div>
                        <div class="span10 form-inline">
                            <input type="text" name="name"/>&#160;
                            <!--<select name="name-type" class="input-medium">
                                <option value="">- Select -</option>
                                <option value="any">any</option>
                                <option value="given">given</option>
                                <option value="family">family</option>
                                <option value="title">title</option>
                            </select>-->
                        </div>
                    </div>
                    <hr/>
                     <!-- Person Type-->
                    <div class="row-fluid">
                        <div class="span2">Person Type: </div>
                        <div class="span10 form-inline">
                        <select name="type" class="input-medium">
                            <option value="">- Select -</option>
                            <option value="any">any</option>
                            <option value="author">author</option>
                            <option value="saint">saint</option>
                        </select>
                       </div> 
                    </div>
                                        <!-- URI-->
                    <div class="row-fluid">
                        <div class="span2">URI: </div>
                        <div class="span10 form-inline">
                        <input type="text" name="uri"/>&#160;
                            <select name="uri-type" class="input-medium">
                                <option value="">- Select -</option>
                                <option value="any">any</option>
                                <option value="viaf">VIAF</option>
                                <option value="worldcat">WorldCat</option>
                                <option value="fihrist">Fihrist</option>
                                <option value="wikipedia">Wikipedia</option>
                            </select>
                        </div>
                    </div>
                    <!-- Date range-->
                    <div class="row-fluid">
                        <div class="span2">Date Range: </div>
                        <div class="span10 form-inline">
                             <input type="text" name="start-date" placeholder="Start Date" class="input-small"/>&#160;
                             <input type="text" name="end-date" placeholder="End Date" class="input-small"/>&#160;
                            <select name="date-type" class="input-medium">
                                <option value="">- Select -</option>
                                <option value="any">any</option>
                                <option value="birth">birth</option>
                                <option value="death">death</option>
                                <option value="floruit">floruit</option>
                                <option value="reign">reign</option>
                                <option value="other">other event</option>
                            </select>
                            <p class="hint" style="margin:.5em; color: grey; font-style:italic;">* Dates should be entered as YYYY or YYYY-MM-DD</p>
                        </div>
                    </div>
                    
                    <!-- Associated Places-->
                    <div class="row-fluid">
                        <div class="span2">Associated Places: </div>
                        <div class="span10 form-inline">
                            <input type="text" name="place-name"/>&#160;
                            <select name="place-type" class="input-medium">
                                <option value="">- Select -</option>
                                <option value="any">any</option>
                                <option value="birth">birth</option>
                                <option value="death">death</option>
                                <option value="venerated">venerated</option>
                                <option value="other">other</option>
                            </select>
                        </div>
                    </div>
                    
                    <!-- Related persons-->
                    <div class="row-fluid">
                        <div class="span2">Related Persons: </div>
                        <div class="span10"><input type="text" name="related-persons"/></div>
                    </div>
                    
                    <!-- Mentioned in Source-->
                    <div class="row-fluid">
                        <div class="span2">Mentioned in Source: </div>
                        <div class="span10"><input type="text" name="mentioned"/></div>
                    </div>
                </div>    
            </div>
        </div>
        <div class="pull-right">
            <button type="submit" class="btn btn-info">Search</button>&#160;
            <button type="reset" class="btn">Clear</button>
        </div>
        <br class="clearfix"/><br/>
    </div>    
</form>
};