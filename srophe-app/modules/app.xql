xquery version "3.0";

module namespace app="http://syriaca.org//templates";
(:~
 : General use xqueries for accross srophe app.
:)
import module namespace place="http://syriaca.org//place" at "place.xqm";
import module namespace teiDocs="http://syriaca.org//teiDocs" at "teiDocs/teiDocs.xqm";

import module namespace templates="http://exist-db.org/xquery/templates" ;
import module namespace config="http://syriaca.org//config" at "config.xqm";

declare namespace tei="http://www.tei-c.org/ns/1.0";
declare namespace xlink = "http://www.w3.org/1999/xlink";
declare namespace expath="http://expath.org/ns/pkg";

(:~
 : Transform tei to html
 : @param $node data passed to transform
:)
declare function app:tei2html($nodes as node()*) {
    transform:transform($nodes, doc('../resources/xsl/tei2html.xsl'),() )
};

declare %templates:wrap function app:set-data($node as node(), $model as map(*), $doc as xs:string){
    teiDocs:generate-docs('/db/apps/srophe/data/places/tei/78.xml')
};

(:~
 : Builds page title
 : Otherwise build based on page url
 : @param $metadata:id gets place id from url
 : NOTE: adjust to handle urls from /geo/87 and person/13 etc.
 :)
declare  %templates:wrap function app:page-title($node, $model, $collection){
    for $title in tokenize(request:get-uri(), '/')[last()]
    return
     if (starts-with($title,'place')) then concat($collection,': ',place:html-title())
     else if (starts-with($title,'browse')) then concat($collection,': Index')
     else if(starts-with($title,'index')) then $collection
     else concat($collection,': ',substring-before($title,'.html'))
};


(:~
 : Generic contact form can be added to any page by calling:
 : <div data-template="app:contact-form"/>
 : with a link to open it that looks like this: 
:)
declare %templates:wrap function app:contact-form($node as node(), $model as map(*))
{
    <div> 
        <div class="modal fade" id="feedback" tabindex="-1" role="dialog" aria-labelledby="feedbackLabel" aria-hidden="true">
            <div class="modal-dialog">
                <div class="modal-content">
                    <div class="modal-header">
                        <button type="button" class="close" data-dismiss="modal">
                            <span aria-hidden="true">x</span>
                            <span class="sr-only">Close</span>  
                        </button>
                        <h2 class="modal-title" id="feedbackLabel">Corrections/Additions?</h2>
                    </div>
                    <form action="/exist/apps/srophe/modules/email.xql" method="post" id="email" role="form">
                        <div class="modal-body" id="modal-body">
                            <input type="text" name="name" placeholder="Name" class="form-control" style="max-width:300px"/>
                            <br/>
                            <input type="text" name="email" placeholder="email" class="form-control" style="max-width:300px"/>
                            <br/>
                            <input type="text" name="subject" placeholder="subject" class="form-control" style="max-width:300px"/>
                            <br/>
                            <textarea name="comments" id="comments" rows="3" class="form-control" placeholder="Comments" style="max-width:500px"/>
                            <!-- start reCaptcha API-->
                            <script type="text/javascript" src="http://api.recaptcha.net/challenge?k=6Lf1uvESAAAAAPiMWhCCFcyDqj8LVNoBKwkROCia"/>
                            <noscript>
                                <iframe src="http://api.recaptcha.net/noscript?k=6Lf1uvESAAAAAPiMWhCCFcyDqj8LVNoBKwkROCia" height="100" width="100" frameborder="0"/>
                                <br/>
                                <textarea name="recaptcha_challenge_field" rows="3" cols="40"/>
                                <input type="hidden" name="recaptcha_response_field" value="manual_challenge"/>
                            </noscript>
                        </div>
                        <div class="modal-footer">
                            <button class="btn btn-default" data-dismiss="modal">Close</button>
                            <input id="email-submit" type="submit" value="Send e-mail" class="btn"/>
                        </div>
                  </form>
          </div>
       </div>
        </div>
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
            case comment() return ()
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

