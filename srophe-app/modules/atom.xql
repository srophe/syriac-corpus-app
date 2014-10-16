xquery version "3.0";
(:
 : Build atom feed for all srophe modules 
 : @param $collection selects data collection for feed, if no collection parameter records from all collections will be returned. 
 : @param $id return single entry matching xml:id
 : @param $start start paged results
 : @param $perpage default set to 50 can be changed via perpage param
:)
import module namespace feed="http://syriaca.org//atom" at "atom.xqm";

declare namespace xslt="http://exist-db.org/xquery/transform";
declare namespace tei="http://www.tei-c.org/ns/1.0";
declare namespace atom="http://www.w3.org/2005/Atom";
declare namespace xlink = "http://www.w3.org/1999/xlink";
declare namespace util="http://exist-db.org/xquery/util";
declare namespace request="http://exist-db.org/xquery/request";
declare namespace georss="http://www.georss.org/georss";

declare variable $collection {request:get-parameter('collection', '')};
declare variable $id {request:get-parameter('id', '')};
declare variable $perpage {request:get-parameter('perpage', 25) cast as xs:integer};
declare variable $start {request:get-parameter('start', 1) cast as xs:integer};

declare option exist:serialize "method=xml media-type=application/rss+xml omit-xml-declaration=no indent=yes";

(:Not complete, need to work on responsible persons function and add in contributors:)
declare function local:build-entry($recs){
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

declare function local:get-place-entry(){
    for $item in collection("/db/apps/srophe/data")/id($id)
    let $rec := $item/ancestor::tei:TEI
    let $date := $rec/tei:teiHeader/tei:fileDesc/tei:publicationStmt[1]/tei:date[1]/text()
    return 
    (
    <updated xmlns="http://www.w3.org/2005/Atom">{local:format-dates($date)}</updated>,
    local:build-entry($rec)
    )
};
               
declare function local:get-feed(){
   let $collection := 
        if($collection) then concat('/db/apps/srophe/data/',$collection,'/tei')
        else "/db/apps/srophe/data"
   for $recs in subsequence(collection($collection),$start, $perpage)
   let $date := $recs[1]//tei:publicationStmt[1]/tei:date[1]/text()
   order by $date descending
   return $recs
};

declare function local:updated-feed(){
    for $date in local:get-feed()[1]
    let $date := $date//tei:publicationStmt[1]/tei:date[1]/text()
    return local:format-dates($date)
};

(:2013-11-07  to 2013-11-07T15:00:00Z:)
declare function local:format-dates($date){
    if($date) then 
        if(string-length($date) = 10) then concat($date,'T12:00:00Z')
        else if(string-length($date) = 4) then concat($date,'01-01T12:00:00Z')
        else if(string-length($date) gt 10) then concat(substring($date,1,10),'T12:00:00Z')
        else ''
    else ''
};

declare function local:build-feed(){
    for $recs in local:get-feed()
    return local:build-entry($recs)
};

feed:build-feed($collection,$start,$perpage)
(:
<feed xmlns="http://www.w3.org/2005/Atom" xmlns:georss="http://www.georss.org/georss"> 
    <title>The Syriac Gazetteer: Latest Updates</title>
    <link rel="self" type="application/atom+xml" href="http://syriaca.org/atom.xql"/>
    <id>tag:syriaca.org,2013:gazetteer-latest</id>
    <updated xmlns="http://www.w3.org/2005/Atom">{local:updated-feed()}</updated>
       {
        if(exists($id) and $id !='') then local:get-place-entry()
        else local:build-feed()
       }
</feed>
:)
