xquery version "3.0";
(: Build relationships. :)
module namespace rel="http://syriaca.org/related";
import module namespace page="http://syriaca.org/page" at "paging.xqm";
import module namespace global="http://syriaca.org/global" at "global.xqm";
import module namespace functx="http://www.functx.com";
declare namespace tei="http://www.tei-c.org/ns/1.0";
declare namespace html="http://www.w3.org/1999/xhtml";


(:~ 
 : Get names/titles for each uri
 : @param $uris passed as string, can contain multiple uris
 : @param $idno for parent record, can be blank. Used to filter current record from results list. 
 :)
declare function rel:get-uris($uris as xs:string*, $idno) as xs:string*{
    for $uri in distinct-values(tokenize($uris,' '))
    where ($uri != $idno and not(starts-with($uri,'#')))  
    return $uri
};

declare function rel:display($uri as xs:string*) as element(a)*{
    let $rec :=  global:get-rec($uri)  
    return global:display-recs-short-view($rec, '')
};

declare function rel:get-names($uris as xs:string?) {
    let $count := count(tokenize($uris,' '))
    for $uri at $i in tokenize($uris,' ')
    let $rec :=  global:get-rec($uri)
    let $name := 
                if(not(exists(global:get-rec($uri)))) then $uri
                else if(contains($uris,'/spear/')) then
                    let $string := normalize-space(string-join($rec/descendant::text(),' '))
                    let $last-words := tokenize($string, '\W+')[position() = 5]
                    return concat(substring-before($string, $last-words),'...')
                else substring-before($rec[1]/descendant::tei:titleStmt[1]/tei:title[1]/text()[1],' — ')
    return
        (
        if($i gt 1 and $count gt 2) then  
            ', '
        else if($i = $count and $count gt 1) then  
            ' and '
        else (),
        normalize-space($name)
        )
};

(:~ 
 : Get names/titles for each uri, for json output
 : @param $uris passed as string, can contain multiple uris
 :)
declare function rel:get-names-json($uris as xs:string?) as node()*{
    for $uri in tokenize($uris,' ')
    let $rec :=  global:get-rec($uri)
    let $name := 
                if(contains($uris,'/spear/')) then
                    let $string := normalize-space(string-join($rec/descendant::text(),' '))
                    let $last-words := tokenize($string, '\W+')[position() = 5]
                    return concat(substring-before($string, $last-words),'...')
                else substring-before($rec/descendant::tei:titleStmt[1]/tei:title[1]/text()[1],'—')
    return <name>{normalize-space($name)}</name>     
};

(:~ 
 : Describe relationship using tei:description or @name
 : @param $related relationship element 
 :)
declare function rel:decode-relationship($related as node()*){ 
    let $name := $related/@name | $related/@ref
    for $name in $name[1]
    let $subject-type := rel:get-subject-type($related/@passive)
    let $label := global:odd2text($related[1],string($name))
    return 
            if($label != '') then 
                $label
            else 
                if($name = 'dcterms:subject') then 
                    concat($subject-type, ' highlighted: ')
                else if($name = 'syriaca:commemorated') then
                    concat($subject-type,' commemorated:  ')    
                else  
                string-join(
                    for $w in tokenize($name,' ')
                    return functx:capitalize-first(substring-after(functx:camel-case-to-words($w,' '),':')),' ')
};


(:~ 
 : Subject type, based on uri of @passive uris
 : @param 'passive' $relationship attribute
:)
declare function rel:get-subject-type($rel as xs:string*) as xs:string*{
    if(contains($rel,'person') and contains($rel,'place')) then 'records'
    else if(contains($rel,'person')) then 
        if(contains($rel,' ')) then 'persons'
        else 'person'
    else if(contains($rel,'place')) then 
        if(contains($rel,' ')) then 'places'
        else 'place'
    else if(contains($rel,'work')) then 
        if(contains($rel,' ')) then 'works'
        else 'work'
    else string($rel)
};

(:~ 
 : Get 'cited by' relationships. Used in bibl module. 
 : @param $idno bibl idno
:)
declare function rel:get-cited($idno){
let $data := 
    for $r in collection('/db/apps/srophe-data/data')//tei:body[.//@target[. = replace($idno[1],'/tei','')]]
    let $headword := replace($r/ancestor::tei:TEI/descendant::tei:title[1]/text()[1],' — ','')
    let $id := $r/ancestor::tei:TEI/descendant::tei:idno[@type='URI'][1]
    let $sort := global:build-sort-string($headword,'')
    where $sort != ''
    order by $sort collation "?lang=en&lt;syr&amp;decomposition=full"
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
                            global:display-recs-short-view(collection($global:data-root)//tei:idno[@type='URI'][. = $id]/ancestor::tei:TEI,'')                        
                    else 
                        for $rec in $hits
                        let $id := substring-before($rec,'headword:=')
                        return 
                            global:display-recs-short-view(collection($global:data-root)//tei:idno[@type='URI'][. = $id]/ancestor::tei:TEI,'')
                }
                { 
                     if($count gt 5) then
                        <div>
                            <a href="#" class="btn btn-info getData" style="width:100%; margin-bottom:1em;" data-toggle="modal" data-target="#moreInfo" 
                            data-ref="../search.html?bibl={$current-id}&amp;perpage={$count}&amp;sort=alpha" 
                            data-label="See all {$count} results" id="moreInfoBtn">
                              See all {$count} results
                             </a>
                        </div>
                     else ()
                 }
            </div>
        else ()
        
};

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
 : Main div for HTML display 
 : @param $node all relationship elements
 : @param $idno record idno
:)
declare function rel:build-relationships($node,$idno){ 
<div class="relation well">
    <h3>Relationships</h3>
    <div class="indent">
    {       
        for $related in $node/descendant-or-self::tei:relation
        let $names := rel:get-uris(string-join(($related/@active/string(),$related/@passive/string(),$related/@mutual/string()),' '),$idno)
        let $count := count($names)
        let $rel-id := index-of($node, $related[1])
        let $rel-type := if($related/@name) then $related/@name else $related/@ref
        group by $relationship := $rel-type
        return
                (<p class="rel-label"> 
                    {
                      if($related/@mutual) then 
                        ('This ', rel:get-subject-type($related[1]/@mutual), ' ', 
                        rel:decode-relationship($related), ' ', 
                        $count, ' other ', rel:get-subject-type($related[1]/@mutual),'.')
                      else if($related/@active) then 
                        ('This ', rel:get-subject-type($related[1]/@active), ' ',
                        rel:decode-relationship($related), ' ', $count, ' ',
                        rel:get-subject-type($related[1]/@passive),'.')
                      else rel:decode-relationship($related)
                    }
                </p>,
                <div class="rel-list" id="showRel-{$rel-id}">{
                    for $r in subsequence($names,1,2)
                    return rel:display($r),
                    if($count gt 2) then
                        <span>
                            <span class="collapse" id="showRel-{$rel-id}">{
                                for $r in subsequence($names,3,$count)
                                return rel:display($r)
                            }</span>
                            <a class="togglelink btn btn-info" style="width:100%; margin-bottom:1em;" data-toggle="collapse" data-target="#showRel-{$rel-id}" data-text-swap="Hide"> See all {$count} &#160;<i class="glyphicon glyphicon-circle-arrow-right"></i></a>
                        </span>
                    else ()
                    (:for $r in $names
                    return 
                    <div class="short-rec rel indent">{rel:display($r)}</div>
                    :)
                }</div>)
        }
    </div>
</div>
};

(: Assumes active/passive SPEAR:)
declare function rel:decode-relationship-name($relationship){
let $relationship-name := 
    if(contains($relationship,':')) then 
        substring-after($relationship,':')
    else $relationship
return    
    switch ($relationship-name)
        (: @ana = 'clerical':)
        case "FellowClergy" return "  were fellow clergy" (: no recip needed:)
        case "Baptism" return " baptized "
        case "BishopOver" return " was a bishop with authority over "
        case "BishopOverBishop" return " was a bishop with authority over bishop "
        case "BishopOverClergy" return " was a bishop with authority over "
        case "BishopOverMonk" return "  was a bishop with authority over "
        case "Ordination" return " ordained "
        case "ClergyFor" return " was a clergyperson for "
        case "CarrierOfLetterBetween" return " carried a letter between "
        case "EpistolaryReferenceTo" return " refered to "
        case "LetterFrom" return " sent a letter to "
        case "SenderOfLetterTo" return " sent a letter to "
        (: @ana = 'family':)
        case "CousinOf" return " were cousins"
        case "ExtendedFamilyOf" return " were part of the same extended family"
        case "ExtendedHouseholdOf" return " were part of the same extended household"
        case "HouseholdOf" return " were part of the same household"
        case "KinOf" return " were kin"
        case "SiblingOf" return " were siblings"
        case "SpouseOf" return " were spouses"
        case "GreatGrandparentOf" return " was the great grandparent of "
        case "AncestorOf" return " was the ancestor of "
        case "ChildOf" return " was the child of "
        case "ChildOfSiblingOf" return " was the child of a sibling of "
        case "descendantOf" return " was a descendant of "
        case "GrandchildOf" return " was the grandchild of "
        case "GrandparentOf" return " was the grandparent of "
        case "ParentOf" return " was the parent of "
        case "SiblingOfParentOf" return " was the sibling of the parent of "
        (: @ana = 'general' :)
        case "EnmityFor" return " had enmity for  "
        case "MemberOfGroup" return " was part "
        case "Citation" return " refered to the writings of "
        case "FollowerOf" return " was a follower of "
        case "StudentOf" return " was the student of "
        case "LegallyRecognisedRelationshipWith" return " were part of a legally recognized relationship "
        case "Judged" return " heard a legal case against "
        case "LegalChargesAgainst" return " brought legal charges or a petition against "
        case "Petitioned" return " made a petition to or sought a legal ruling from "
        case "CommandOver" return " was a military commander over "
        case "FellowMonastics" return " were monks at the same monastery"
        case "MonasticHeadOver" return " was a monastic authority over "
        case "AcknowledgedFamilyRelationship" return " (Acknowledged family relationship) "
        case "AdoptedFamilyRelationship" return " (Adopted family relationship) "
        case "ClaimedFamilyRelationship" return " (Claimed family relationship) "
        case "FosterFamilyRelationship" return " (Foster family relationship) "
        case "HalfFamilyRelationship" return " (Half family relationship)  "
        case "InLawFamilyRelationship" return " (In law family relationship) "
        case "MaternalFamilyRelationship" return " (Maternal family relationship) "        
        case "PaternalFamilyRelationship" return " (Paternal family relationship) "
        case "StepFamilyRelationship" return " (Step family relationship) "  
        case "AllegedRelationship" return " (Alleged relationship) "
        case "RitualKinship" return " (Ritual kinship) "  
        case "AllianceWith" return " formed an alliance"
        case "CasualIntimateRelationshipWith" return " had a casual intimate relationship"  
        case "FriendshipFor" return " were friends"
        case "IntimateRelationshipWith" return "had an intimate relationship"  
        case "SeriousIntimateRelationshipWith" return " had a serious intimate relationship"
        case "ProfessionalRelationship" return " had a professional relationship"  
        case "CommuneTogether" return " shared the Eucharist"
        case "Commemoration" return " commemorated "  
        case "FreedSlaveOf" return " was a freed slave of "
        case "HouseSlaveOf" return " was a house slave of "   
        case "SlaveOf" return " was a slave of "   
        default return concat(' ', functx:camel-case-to-words($relationship-name,' '),' ') 
};

(: TODO build text for passive/active SPEAR:)
declare function rel:decode-relationship-passive($relationship){
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
        default return concat(' ', functx:camel-case-to-words($relationship-name,' '),' ') 
};

declare function rel:build-relationship-sentence($relationship,$uri){
(: Will have to add in some advanced prcessing that tests the current id (for aggrigate pages) and subs vocab for active/passive:)
if($relationship/@mutual) then
    concat(string-join(rel:get-names($relationship/@mutual),''), rel:decode-relationship-name($relationship/@name),'.')
else if($relationship/@active) then 
    concat(string-join(rel:get-names($relationship/@active),''), rel:decode-relationship-name($relationship/@name), string-join(rel:get-names($relationship/@passive),''),'.') 
else ()
};

(:~ 
 : Main div for HTML display for SPEAR relationships
 : @param $node all relationship elements
 : @param $idno record idno
:)
declare function rel:build-short-relationships-list($node,$idno){ 
    let $count := count($node/descendant-or-self::tei:relation)
    return 
        for $related in $node/descendant-or-self::tei:relation
        let $uri := string($related/ancestor::tei:div[@uri][1]/@uri)
        return
            <span class="short-relationships">
               {rel:build-short-relationships($related,$uri)} 
                &#160;<a href="factoid.html?id={$uri}">See factoid page <span class="glyphicon glyphicon-circle-arrow-right" aria-hidden="true"/></a>
            </span>
};

(:~ 
 : Main div for HTML display SPEAR relationships
 : @param $node all relationship elements
 : @param $idno record idno
:)
declare function rel:build-short-relationships($node,$uri){ 
    rel:build-relationship-sentence($node,$uri)
};