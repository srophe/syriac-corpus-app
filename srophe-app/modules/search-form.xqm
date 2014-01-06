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
                             <input type="text" name="e-start" placeholder="Start Date" class="input-small"/>&#160;
                             <input type="text" name="e-end" placeholder="End Date" class="input-small"/>
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
                             <input type="text" name="a-start" placeholder="Start Date" class="input-small"/>&#160;
                             <input type="text" name="a-end" placeholder="End Date" class="input-small"/>
                             <p class="hint" style="margin:.5em; color: grey; font-style:italic;">* Dates should be entered as YYYY or YYYY-MM-DD</p>
                         </div>
                     </div>
                     <hr/>
                     <!-- Confessions -->
                     <div class="row-fluid">
                         <div class="span3">Confessions: </div>
                         <div class="span9"><input type="text" name="c"/></div>
                     </div>
                     <div class="row-fluid">
                         <div class="span3">Dates: </div>
                         <div class="span9 form-inline">    
                             <input type="text" name="c-start" placeholder="Start Date" class="input-small"/>&#160;
                             <input type="text" name="c-end" placeholder="End Date" class="input-small"/>
                             <p class="hint" style="margin:.5em; color: grey; font-style:italic;">* Dates should be entered as YYYY or YYYY-MM-DD</p>
                         </div>
                     </div>
                     <hr/>
                     <!-- Existence -->
                     <div class="row-fluid">
                         <div class="span3">Existence: </div>
                         <div class="span9"><input type="text" name="exist"/></div>
                     </div>
                     <div class="row-fluid">
                         <div class="span3">Dates: </div>
                         <div class="span9 form-inline">
                             <input type="text" name="exist-start" placeholder="Start Date" class="input-small"/>&#160;
                             <input type="text" name="exist-end" placeholder="End Date" class="input-small"/>
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
                                <option value="settlement">settlement</option>
                                <option value="monastery">monastery</option>
                                <option value="region">region</option>
                                <option value="province">province</option>
                                <option value="open-water">open-water</option>
                                <option value="fortification">fortification</option>
                                <option value="mountain">mountain</option>
                                <option value="quarter">quarter</option>
                                <option value="state">state</option>
                                <option value="building">building</option>
                                <option value="diocese">diocese</option>
                                <option value="island">island</option>
                                <option value="parish">parish</option>
                                <option value="unknown">unknown</option>
                            </select>
                    <hr/>
                    <!-- Language -->
                        <label>Language: </label>
                        <input type="radio" name="lang" value="en" class="offset1"/>English<br/>
                        <input type="radio" name="lang" value="ar" class="offset1"/>Arabic<br/>
                        <input type="radio" name="lang" value="syr" class="offset1"/>Syriac<br/>
                        
                            <!-- Engl/Arabic/Syriac 
                            <select name="lang" class="input-medium">
                                <option value="">- Select -</option>
                                <option value="en">English</option>
                                <option value="ar">Arabic</option>
                                <option value="syr">Syriac</option>
                            </select>
                            -->
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