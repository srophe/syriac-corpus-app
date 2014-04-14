xquery version "3.0";

module namespace app="http://syriaca.org//templates";
(:~
 : General use xqueries for accross srophe app.
:)
import module namespace templates="http://exist-db.org/xquery/templates" ;
import module namespace config="http://syriaca.org//config" at "config.xqm";

declare namespace tei="http://www.tei-c.org/ns/1.0";
declare namespace xlink = "http://www.w3.org/1999/xlink";

(:~
 : Generic contact form can be added to any page by calling:
 : <div data-template="app:contact-form"/>
 : with a link to open it that looks like this: <a href="#contact" data-toggle="modal">Link text</a>
:)
declare %templates:wrap function app:contact-form($node as node(), $model as map(*))
{
    <div id="contact" class="modal hide fade" tabindex="-1" role="dialog" aria-labelledby="report-errors-label" aria-hidden="true">
        <div class="modal-header">
            <button type="button" class="close" data-dismiss="modal" aria-hidden="true">×</button>
            <h3 id="report-errors-label">Contact Us</h3>
        </div>
        <form action="/exist/apps/srophe/modules/email.xql" method="post" id="email">
            <div class="modal-body" id="modal-body">
                <!--<label>Name:</label>-->
                <input type="text" name="name" placeholder="Name"/><br/>
                <!--<label>e-mail address:</label>-->
                <input type="text" name="email" placeholder="email"/><br/>
                <!--<label>Subject:</label>--> 
                <input type="text" name="subject" placeholder="subject"/><br/>
                <textarea name="comments" id="comments" rows="5" class="span9" placeholder="Comments"/>
                <!-- start reCaptcha API-->
                <script type="text/javascript" src="http://api.recaptcha.net/challenge?k=6Lf1uvESAAAAAPiMWhCCFcyDqj8LVNoBKwkROCia"></script>
                <noscript>
                 <iframe src="http://api.recaptcha.net/noscript?k=6Lf1uvESAAAAAPiMWhCCFcyDqj8LVNoBKwkROCia"  height="100" width="100" frameborder="0"></iframe><br/>
                    <textarea name="recaptcha_challenge_field" rows="3" cols="40"></textarea>
                    <input type="hidden" name="recaptcha_response_field" value="manual_challenge"/>
                </noscript>
                <!-- end Client API reCaptcha code -->
            </div>
            <div class="modal-footer">
                <button class="btn" data-dismiss="modal" aria-hidden="true">Close</button>
                <input id="email-submit" type="submit" value="Send e-mail" class="btn"/>
            </div>
        </form>
    </div>
};

(:~
 : Grabs latest news for home page
 : http://syriaca.org/feed/
 :)
 
declare %templates:wrap function app:get-feed($node as node(), $model as map(*)){ 
   let $news := doc('http://syriaca.org/blog/feed/')/child::*
   for $latest at $n in subsequence($news//item, 1, 8)
   return 
   <li>
        <a href="{$latest/link/text()}">{$latest/title/text()}</a>
   </li>
};

(:~
 : Typeswitch to transform confessions.xml into nested list.
 : @param $node   
:)
declare function app:transform($nodes as node()*) as item()* {
    for $node in $nodes
    return 
        typeswitch($node)
            case text() return $node
            case comment() return $node
            case element(tei:list) return element ul {app:transform($node/node())}
            case element(tei:item) return element li {app:transform($node/node())}
            case element(tei:label) return element span {app:transform($node/node())}
            default return app:transform($node/node())
};

(:~
 : Pull confession data for confessions.html
:)
declare %templates:wrap function app:build-confessions($node as node(), $model as map(*)){
    let $confession := doc('/db/apps/srophe/documentation/confessions.xml')//tei:body/child::*[1]
    return app:transform($confession)
};

(:~
 : get editors as distinct values
:)
declare function app:get-editors(){
distinct-values(
    (for $editors in collection('/db/apps/srophe/data/places/tei')//tei:respStmt/tei:name/@ref
     return substring-after($editors,'#'),
     for $editors-change in collection('/db/apps/srophe/data/places/tei')//tei:change/@who
     return substring-after($editors-change,'#'))
    )
};

(:~
 : Build editor list. Sort alphabeticaly
:)
declare %templates:wrap function app:build-editor-list($node as node(), $model as map(*)){
    let $editors := doc('/db/apps/srophe/documentation/editors.xml')//tei:listPerson
    for $editor in app:get-editors()
    let $name := 
        for $editor-name in $editors//tei:person[@xml:id = $editor]
        return concat($editor-name/tei:persName/tei:forename,' ',$editor-name/tei:persName/tei:addName,' ',$editor-name/tei:persName/tei:surname)
    let $sort-name :=
        for $editor-name in $editors//tei:person[@xml:id = $editor] return $editor-name/tei:persName/tei:surname
    order by $sort-name
    return
        if($editor != '') then 
            if(normalize-space($name) != '') then 
            <li>{normalize-space($name)}</li>
            else ''
        else ''  
};