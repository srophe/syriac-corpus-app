xquery version "3.0";
(:
 : Build atom feed for all srophe modules
 : @param $collection selects data collection for feed, if no collection parameter records from all collections will be returned. 
 : @param $id return single entry matching xml:id
 : @param $start start paged results
 : @param $perpage default set to 50 can be changed via perpage param
:)
module namespace browse="http://syriaca.org//browse";

import module namespace config="http://syriaca.org//config" at "config.xqm";

declare namespace tei="http://www.tei-c.org/ns/1.0";
declare namespace atom="http://www.w3.org/2005/Atom";
declare namespace util="http://exist-db.org/xquery/util";
declare namespace request="http://exist-db.org/xquery/request";
declare namespace georss="http://www.georss.org/georss";

declare variable $browse:collection {request:get-parameter('collection', '')};
declare variable $browse:id {request:get-parameter('id', '')};
declare variable $browse:perpage {request:get-parameter('perpage', 50) cast as xs:integer};
declare variable $browse:start {request:get-parameter('start', 1) cast as xs:integer};

declare option exist:serialize "method=xml media-type=application/rss+xml omit-xml-declaration=no indent=yes";

(:Not complete, need to work on responsible persons function and add in contributors:)
declare function browse:build-entry($recs){
    for $rec in $recs
    let $doc-uri := base-uri($rec)
    let $doc-name := util:document-name($rec)
    let $collection := substring-before(substring-after($doc-uri,'/data/'),'/')
    let $rec-id := substring-before($doc-name,'.')
    let $title := string($rec//tei:titleStmt/tei:title[1])
    let $date := $rec//tei:publicationStmt[1]/tei:date[1]/text()
    let $rec-uri :=
                if(contains($collection,'places')) then concat('http://syriaca.org/place/',$rec-id)
                else if(starts-with($collection,'person')) then concat('http://syriaca.org/persons/',$rec-id)
                else 'http://syriaca.org/'
    let $geo := if($rec//tei:geo) then <georss:point>{string($rec//tei:geo)}</georss:point> else ()         
    let $res-pers :=  
                let $author-name := distinct-values($rec//tei:titleStmt/tei:editor) 
                for $author in $author-name
                return <author xmlns="http://www.w3.org/2005/Atom"><name>{$author}</name></author>
    let $summary := 
        if($rec//tei:desc[contains(@xml:id,'abstract')] 
        and string-length($rec//tei:desc[contains(@xml:id,'abstract')]) gt 1) then
            <summary xmlns="http://www.w3.org/2005/Atom">
                {
                for $sum in $rec//tei:desc[contains(@xml:id,'abstract')]/descendant-or-self::text()
                return
                    $sum
                  }
            </summary>
        else ''
    return    
    <entry xmlns="http://www.w3.org/2005/Atom" xmlns:georss="http://www.georss.org/georss">
        <title>{$title}</title>
        <link rel="alternate" type="text/html" href="{$rec-uri}"/>
        <link rel="self" type="application/atom+xml" href="http://syriaca.org/{$collection}/{$rec-id}/atom"/>
        <id>tag:syriaca.org,2013:{concat($collection,'/',$rec-id)}</id>
        {$geo}
        <updated>{local:format-dates($date)}</updated>
        {($summary, $res-pers)}
    </entry>   

};

declare function browse:get-place-entry(){
    for $item in collection($config:app-root || "/data")/id($id)
    let $rec := $item/ancestor::tei:TEI
    let $date := $rec/tei:teiHeader/tei:fileDesc/tei:publicationStmt[1]/tei:date[1]/text()
    return 
    (
    <updated xmlns="http://www.w3.org/2005/Atom">{local:format-dates($date)}</updated>,
    local:build-entry($rec)
    )
};
               
declare function browse:get-feed(){
   let $collection := 
        if($collection) then ($config:app-root || '/data/' || $collection || '/tei')
        else ($config:app-root || '/data')
   for $recs in subsequence(collection($collection),$start, $perpage)
   let $date := $recs[1]//tei:publicationStmt[1]/tei:date[1]/text()
   order by $date descending
   return $recs
};

declare function browse:updated-feed(){
    for $date in browse:get-feed()[1]
    let $date := $date//tei:publicationStmt[1]/tei:date[1]/text()
    return local:format-dates($date)
};

(:2013-11-07  to 2013-11-07T15:00:00Z:)
declare function browse:format-dates($date){
    if($date) then 
        if(string-length($date) = 10) then concat($date,'T12:00:00Z')
        else if(string-length($date) = 4) then concat($date,'01-01T12:00:00Z')
        else if(string-length($date) gt 10) then concat(substring($date,1,10),'T12:00:00Z')
        else ''
    else ''
};

declare function browse:build-feed(){
<feed xmlns="http://www.w3.org/2005/Atom" xmlns:georss="http://www.georss.org/georss"> 
    <title>The Syriac Gazetteer: Latest Updates</title>
    <link rel="self" type="application/atom+xml" href="http://syriaca.org/atom.xql"/>
    <id>tag:syriaca.org,2013:gazetteer-latest</id>
    <updated xmlns="http://www.w3.org/2005/Atom">{local:updated-feed()}</updated>
       {
        if(exists($id) and $id !='') then browse:get-place-entry()
        else browse:build-feed()
       }
</feed>


};
