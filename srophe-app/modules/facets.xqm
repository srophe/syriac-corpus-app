xquery version "3.0";
(:~
 : Builds browse page for Syriac.org sub-collections 
 : Alphabetical English and Syriac Browse lists
 : Results output as TEI xml and are transformed by /srophe/resources/xsl/browselisting.xsl
 :)
 
module namespace facets="http://syriaca.org//facets";

import module namespace templates="http://syriaca.org//templates" at "templates.xql";
import module namespace config="http://syriaca.org//config" at "config.xqm";

import module namespace functx="http://www.functx.com";
declare namespace xslt="http://exist-db.org/xquery/transform";
declare namespace tei="http://www.tei-c.org/ns/1.0";
declare namespace xlink = "http://www.w3.org/1999/xlink";
declare namespace transform="http://exist-db.org/xquery/transform";
declare namespace util="http://exist-db.org/xquery/util";

(:
NOTES about facet module
Would probably function best if passed facets (elements to be faceted on)
Will have to have a special cases to handle the crazyness of @ref facets

:)
declare function facets:facets($node as node()*) {
    facets:pers-facet($node)
};

declare function facets:pers-facet($node as node()*) {
    for $pers in $node//tei:persName
    group by $persName := $pers/@ref
    order by $pers[1] ascending
    return 
        let $person := $pers[1]
        let $uri := string($person/@ref)
        return <li><a href="person.html?id={$uri}">{string($person)}</a> ({count($pers)}) {$uri}</li> 
};

declare function facets:event(){
    for $events in $node//tei:event
    group by $eventName := $events/@ref
    order by $events[1] ascending
    return 
        let $event := $events[1]
        let $uri := string($event/@ref)
        return <li><a href="person.html?id={$uri}">{string($event)}</a> ({count($events)}) {$uri}</li>
};

(:

declare function local:facet-speaker($hits as element()*) as element()*{
    for $speakers in $hits
    group by $speaker := $speakers/tei:speaker/text()
    order by count($speakers) descending
    return 
        <div count="{count($speakers)}">{$speaker}</div>
};

 : Build drop down menu for controlled keywords
declare function spears:keyword-menu(){
for $keywordURI in 
distinct-values(
    for $keyword in collection('/db/apps/srophe/data/spear/')//@ref[contains(.,'/keyword/')]
    return tokenize($keyword,' ')
    )
return
    <option value="{$keywordURI}">{lower-case(functx:camel-case-to-words(substring-after($keywordURI,'/keyword/'),' '))}</option>
};
:)
declare function facets:keyword-list($node){
    for $keyword in $node//@ref[contains(.,'/keyword/')]
    for $key in tokenize($keyword,' ')
    return <p>{string($key)}</p>
};

declare function facets:keyword($node){
    for $k in facets:keyword-list($node)
    group by $k := $k
    order by count($k) descending
    return
        let $khref := string($k[1])
        let $kpretty := lower-case(functx:camel-case-to-words(substring-after($k[1],'/keyword/'),' '))
        return
        <li><a href="{$khref}">{string($kpretty)}</a> [{count($k)}]</li>
};

declare function facets:display(
  $href as xs:string,
  $title as xs:string)
{
  <div class="facet" title="Remove {$title}">
    <a href="{$href}" class="close">
      <span class="close-icon"> X </span>
    </a>
    <div class="label" title="{$title}">{$title}</div>
  </div>
};