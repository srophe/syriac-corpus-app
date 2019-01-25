xquery version "3.0";
(: Get and build TEI relationships :)
module namespace rel="http://syriaca.org/srophe/related";
import module namespace config="http://syriaca.org/srophe/config" at "../config.xqm";
import module namespace global="http://syriaca.org/srophe/global" at "global.xqm";
import module namespace data="http://syriaca.org/srophe/data" at "data.xqm";
import module namespace maps="http://syriaca.org/srophe/maps" at "maps.xqm";
import module namespace tei2html="http://syriaca.org/srophe/tei2html" at "../content-negotiation/tei2html.xqm";

import module namespace functx="http://www.functx.com";
declare namespace tei="http://www.tei-c.org/ns/1.0";
declare namespace html="http://www.w3.org/1999/xhtml";

declare function rel:get-related($uris as xs:string?) as map(xs:string, function(*)){
    map:new(
        for $uri at $i in tokenize($uris,' ')
        let $data := data:get-document($uri)
        where not(empty($data))
        return
            map:entry($uri,$data), "?strength=primary"
    )
};

(:~
 : Get related record names
:)
declare function rel:get-names($uris as xs:string*,$related-map) {
    let $count := count(tokenize(string-join($uris,' '),' '))
    for $uri at $i in tokenize($uris,' ')
    let $rec :=  $related-map($uri)
    let $name := $rec/descendant::tei:titleStmt[1]/tei:title[1]/text()[1]
    let $name := if(contains($name, '—')) then substring-before($name,'—') else $name
    where not(empty($rec))
    return
        (
        if($i gt 1 and $count gt 2) then  
            ', '
        else if($i = $count and $count gt 1) then  
            ' and '
        else (),
        <a href="{$uri}">{normalize-space($name)}</a>
        )
};

(:~
 : Create relationship sentances
:)
declare function rel:relationship-sentence($relationship as node()*,$related-map){
    if($relationship/@ref) then 
        if($relationship/@mutual) then
            (rel:get-names($relationship/@mutual,$related-map), lower-case(rel:decode-relationship($relationship/@ref)),'.')
        else if($relationship/@active) then 
           (rel:get-names($relationship/@active,$related-map),lower-case(rel:decode-relationship($relationship/@ref)), rel:get-names($relationship/@passive,$related-map),'.') 
        else ()
    else 
        if($relationship/@mutual) then
            (rel:get-names($relationship/@mutual,$related-map), lower-case(rel:decode-relationship($relationship/@name)),'.')
        else if($relationship/@active) then 
           (rel:get-names($relationship/@active,$related-map),lower-case(rel:decode-relationship($relationship/@name)), rel:get-names($relationship/@passive,$related-map),'.') 
        else ()
};

(:~
 : Create relationship sentances, do not use related-map for lookup. Used by RDF and TTL generation
:)
declare function rel:relationship-sentence($relationship as node()*){
    let $uris := 
                string-join(
                for $r in $relationship/descendant-or-self::tei:relation
                return string-join(($r/@active/string(),$r/@passive/string(),$r/@mutual/string()),' '),' ')
            let $related-map := rel:get-related($uris)
    return        
        if($relationship/@ref) then 
            if($relationship/@mutual) then
                (rel:get-names($relationship/@mutual,$related-map), lower-case(rel:decode-relationship($relationship/@ref)),'.')
            else if($relationship/@active) then 
               (rel:get-names($relationship/@active,$related-map),lower-case(rel:decode-relationship($relationship/@ref)), rel:get-names($relationship/@passive,$related-map),'.') 
            else ()
        else 
            if($relationship/@mutual) then
                (rel:get-names($relationship/@mutual,$related-map), lower-case(rel:decode-relationship($relationship/@name)),'.')
            else if($relationship/@active) then 
               (rel:get-names($relationship/@active,$related-map),lower-case(rel:decode-relationship($relationship/@name)), rel:get-names($relationship/@passive,$related-map),'.') 
            else ()
};

(:~
 : Translate relationship type into English sentance.
 : @param $relationsip as string
:)
declare function rel:translate-relationship-type($rel-type as xs:string*) {
    if(global:odd2text('relation',$rel-type) != '') then global:odd2text('relation',$rel-type)    
    else rel:decode-relationship($rel-type)                    
};

(:~
 : Translate relationship types based on SPEAR spreadsheet.
 : Assumes active/passive SPEAR
 :)
declare function rel:decode-relationship($relationship as xs:string?){
    let $relationship-name := 
        if(contains($relationship,':')) then 
            substring-after($relationship,':')
        else $relationship
    return 
        switch ($relationship-name)
            (: @ana = 'clerical':)
            case "Baptism" return " was baptized by "
            case "BishopOver" return " was under the authority of bishop "
            case "BishopOverBishop" return " was a bishop under the authority of bishop "
            case "BishopOverClergy" return " was a clergyperson under the authority of the bishop "
            case "BishopOverMonk" return " was a monk under the authority of the bishop "
            case "Ordination" return " was ordained by "
            case "ClergyFor" return " as a clergyperson " (: Full @passive had @active as a clergyperson.:)
            case "CarrierOfLetterBetween" return " exchanged a letter carried by "
            case "EpistolaryReferenceTo" return " was referenced in a letter between "
            case "LetterFrom" return " received a letter from "
            case "SenderOfLetterTo" return " received a letter from "
            (: @ana = 'family':)
            case "GreatGrandparentOf" return " had a great grandparent "
            case "AncestorOf" return " was the descendant of "
            case "ChildOf" return " was the parent of "
            case "SiblingOf" return " were siblings"
            case "ChildOfSiblingOf" return " was the sibling of a parent of "
            case "descendantOf" return " was the ancestor of "
            case "GrandchildOf" return " was the grandparent of "
            case "GrandparentOf" return " was the grandchild of "
            case "ParentOf" return " was the child of "
            case "SiblingOfParentOf" return " was a child of a sibling of "
            (: @ana = 'general' :)
            case "EnmityFor" return " was the object of the enmity of "
            case "MemberOfGroup" return " contained "
            case "Citation" return " was cited by "
            case "FollowerOf" return " had as a follower "
            case "StudentOf" return " had as a teacher "
            case "Judged" return " was judged by "
            case "LegalChargesAgainst" return " was the subject of a legal action brought by "
            case "Petitioned" return " received a petition or a request for legal action from "
            case "CommandOver" return " was under the command of "
            case "MonasticHeadOver" return " was under the monastic authority of "
            case "Commemoration" return " was commemorated by "  
            case "FreedSlaveOf" return " was released from slavery to "
            case "HouseSlaveOf" return " was held as a house slave "   
            case "SlaveOf" return " held as a slave "      
            (: @ana 'event' :)
            case "SameAs" return " refer to the same event. "
            case "CloseConnection" return " deal with closely related events."
            default return concat(' ', functx:capitalize-first(functx:camel-case-to-words(replace($relationship-name,'-',' '),' ')),' ') 
};

(:~ 
 : Main div for HTML display 
 : @param $node all relationship elements
 : @param $idno record idno
:)
declare function rel:build-relationships($node as item()*,$idno as xs:string?, $relationship-type as xs:string?, $display as xs:string?, $map as xs:string?){ 
    <div class="panel panel-default relationships" xmlns="http://www.w3.org/1999/xhtml">
        <div class="panel-heading"><h3 class="panel-title">Relationships </h3></div>
        <div class="panel-body">
        {       
            let $uris := 
                string-join(
                if($relationship-type != '') then 
                    for $r in $node/descendant-or-self::tei:relation[@ref = $relationship-type or @name= $relationship-type]
                    return string-join(($r/@active/string(),$r/@passive/string(),$r/@mutual/string()),' ')
                else 
                    for $r in $node/descendant-or-self::tei:relation
                    return string-join(($r/@active/string(),$r/@passive/string(),$r/@mutual/string()),' '),' ')
            let $related-map := rel:get-related($uris)
            let $related-geo := 
                for $record in map:keys(rel:get-related($uris))
                where map:get($related-map,$record)//tei:geo
                return map:get($related-map,$record)
            return
                (if($map = 'map' and  $related-geo != '') then
                    maps:build-map($related-geo,count($related-geo//tei:geo))
                else (),
                for $related in $node/descendant-or-self::tei:relation
                let $rel-id := index-of($node, $related[1])
                let $rel-type := if($related/@ref) then $related/@ref else $related/@name
                group by $relationship := $rel-type
                return 
                    try{
                        if($display = 'list-description') then
                            let $names := string-join(($related/@active/string(),$related/@passive/string(),$related/@mutual/string()),' ')
                            let $count := count(tokenize($names,' ')[not(. = $idno)])
                            let $relationship-type := rel:translate-relationship-type($rel-type)
                            return 
                                (<span class="relationship-type">{rel:get-names($idno, $related-map)}&#160;{$relationship-type} ({$count})</span>,
                                 <div class="indent">
                                 {(
                                 for $r in subsequence(tokenize($names,' ')[not(. = $idno)],1,2)
                                 let $data := $related-map($r)
                                 where not(empty($data))
                                 return tei2html:summary-view($data, '', $r),
                                 if($count gt 2) then
                                        <span>
                                            <span class="collapse" id="showRel-{$rel-id}">{
                                                for $r in subsequence(tokenize($names,' ')[not(. = $idno)],3,$count)
                                                let $data := $related-map($r)
                                                return tei2html:summary-view($data, '', $r)
                                            }</span>
                                            <a class="togglelink btn btn-info" style="width:100%; margin-bottom:1em;" data-toggle="collapse" data-target="#showRel-{$rel-id}" data-text-swap="Hide"> See all {$count} &#160;<i class="glyphicon glyphicon-circle-arrow-right"></i></a>
                                        </span>
                                    else ()
                                 )}</div>
                                )
                         else <div>{rel:relationship-sentence($related,$related-map)}</div>    
                     } catch * { $related }   
            )}
        </div>
    </div>
};

(:~
 : Build external relationships, i.e, aggrigate all records which reference the current record, 
 : as opposed to rel:build-relationships which displays record information for records referenced in the current record.
 : @param $recID current record id 
 : @param $title current record title 
 : @param $relType relationship type
 : @param $collection current record collection
 : @param $sort sort on title or part number default to title
 : @param $count number of records to return, if empty defaults to 5 with a popup for more. 
:)
declare function rel:external-relationships($recid as xs:string, $title as xs:string?, $relationship-type as xs:string*, $sort as xs:string?, $count as xs:string?){
let $relationship-string := 
    if($relationship-type != '') then
        concat("[descendant::tei:relation[@passive[matches(.,'",$recid,"(\W.*)?$')] or @mutual[matches(.,'",$recid,"(\W.*)?$')]][@ref = '",$relationship-type ,"' or @name = '",$relationship-type ,"']]")
    else concat("[descendant::tei:relation[@passive[matches(.,'",$recid,"(\W.*)?$')] or @mutual[matches(.,'",$recid,"(\W.*)?$')]]]")
let $eval-string := concat("collection($config:data-root)/tei:TEI",$relationship-string)
let $related := util:eval($eval-string)
let $total := count($related)    
return
    if($total gt 0) then 
        <div class="panel panel-default external-relationships" xmlns="http://www.w3.org/1999/xhtml">
            <div class="panel-heading"><h3 class="panel-title">External relationships ({$total})</h3></div>
            <div class="panel-body">
            {
            if($total gt 5) then
                (
                for $r in subsequence($related,1,5)
                let $id := replace($r/descendant::tei:idno[1],'/tei','')
                return tei2html:summary-view($r, (), $id[1]),
                <a class="more" href="{$config:nav-base}/search.html?relationship-type={$relationship-type}&amp;relation-id={$recid}">See all</a>)
            else
                for $r in $related
                let $id := replace($r/descendant::tei:idno[1],'/tei','')
                return tei2html:summary-view($r, (), $id[1])
            }
            </div>  
        </div>
    else()
};

(: Syriaca.org specific functions :)
(:
 : HTML display of 'subject headings' using 'cited by' relationships
 : @param $idno bibl idno
:)
declare function rel:subject-headings($idno){
    let $hits := rel:get-cited(replace($idno[1]/text(),'/tei',''))?cited
    let $total := count($hits)
    return 
        if(exists($hits)) then
            <div class="well relation">
                <h4>Subject Headings:</h4>
                {
                    (
                    for $recs in subsequence($hits,1,20)
                    let $headword := substring-after($recs,'headword:=')
                    let $id := replace(substring-before($recs,'headword:='),'/tei','')
                    return 
                            <span class="sh pers-label badge">{replace($headword,' — ','')} 
                            <a href="search.html?subject={$id}" class="sh-search">
                            <span class="glyphicon glyphicon-search" aria-hidden="true"></span>
                            </a></span>
                            ,
                       if($total gt 20) then
                        (<div class="collapse" id="showAllSH">
                            {
                            for $recs in subsequence($hits,20,$total)
                            let $headword := substring-after($recs,'headword:=')
                            let $id := replace(substring-before($recs,'headword:='),'/tei','')
                            return 
                               <span class="sh pers-label badge">{replace($headword,' — ',' ')} 
                               <a href="search.html?subject={$id}" class="sh-search"> 
                               <span class="glyphicon glyphicon-search" aria-hidden="true">
                               </span></a></span>
                            }
                        </div>,
                        <a class="btn btn-info getData" style="width:100%; margin-bottom:1em;" data-toggle="collapse" data-target="#showAllSH" data-text-swap="Hide"> <span class="glyphicon glyphicon-plus" aria-hidden="true"></span> Show All </a>
                        )
                    else ()
                    )
                }
            </div>
        else ()
};

(:~ 
 : Get 'cited by' relationships. Used in bibl module. 
 : @param $idno bibl idno
:)
declare function rel:get-cited($idno){
let $data := 
    for $r in collection($config:data-root)//tei:body[.//@target[. = replace($idno[1],'/tei','')]]
    let $headword := replace($r/ancestor::tei:TEI/descendant::tei:title[1]/text()[1],' — ','')
    let $id := $r/ancestor::tei:TEI/descendant::tei:idno[@type='URI'][1]
    let $sort := global:build-sort-string($headword,'')
    where $sort != ''
    order by $sort
    return concat($id, 'headword:=', $headword)
return  map { "cited" := $data}    
};

(:~ 
 : HTML display of 'cited by' relationships. Used in bibl module. 
 : @param $idno bibl idno
:)
declare function rel:cited($idno, $start, $perpage){
    let $perpage := if($perpage) then $perpage else 5
    let $current-id := replace($idno[1]/text(),'/tei','')
    let $hits := rel:get-cited($current-id)?cited
    let $count := count($hits)
    return
        if(exists($hits)) then 
            <div class="well relation">
                <h4>Cited in:</h4>
                <span class="caveat">{$count} record(s) cite this work.</span> 
                {
                    if($count gt 5) then
                        for $rec in subsequence($hits,$start,$perpage)
                        let $id := substring-before($rec,'headword:=')
                        return 
                            tei2html:summary-view(collection($config:data-root)//tei:idno[@type='URI'][. = $id]/ancestor::tei:TEI, '', $id)                        
                    else 
                        for $rec in $hits
                        let $id := substring-before($rec,'headword:=')
                        return 
                            tei2html:summary-view(collection($config:data-root)//tei:idno[@type='URI'][. = $id]/ancestor::tei:TEI, '', $id)
                }
                { 
                     if($count gt 5) then
                        <div>
                            <a href="{$config:nav-base}/bibl/search.html?bibl={$current-id}&amp;perpage={$count}&amp;sort=alpha" style="width:100%; margin-bottom:1em;" class="btn btn-info">See all {$count} results</a>
                        <!--
                            <a href="#" class="btn btn-info" style="width:100%; margin-bottom:1em;" data-toggle="modal" data-target="#moreInfo" 
                            data-ref="../search.html?bibl={$current-id}&amp;perpage={$count}&amp;sort=alpha" 
                            data-label="See all {$count} results" id="moreInfoBtn">
                              See all {$count} results
                             </a>
                             -->
                        </div>
                     else ()
                 }
            </div>
        else ()
};
