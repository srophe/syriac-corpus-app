xquery version "3.0";
(:
 : Build atom feed for all syrica.org modules
 : Module is used by atom.xql and rest.xqm 
 : @param $collection selects data collection for feed 
 : @param $id return single entry matching xml:id
 : @param $start start paged results
 : @param $perpage default set to 25 can be changed via perpage param
:)
module namespace feed="http://syriaca.org//atom";

import module namespace config="http://syriaca.org//config" at "config.xqm";

declare namespace tei="http://www.tei-c.org/ns/1.0";
declare namespace atom="http://www.w3.org/2005/Atom";
declare namespace util="http://exist-db.org/xquery/util";
declare namespace request="http://exist-db.org/xquery/request";
declare namespace georss="http://www.georss.org/georss";

declare option exist:serialize "method=xml media-type=application/rss+xml omit-xml-declaration=no indent=yes";

(:~
 : Build path to subcollection for atom feed
 : @param $collection name of syriaca.org subcollection 
:)
declare function feed:get-feed($collection as xs:string?) as node()*{
    let $collection-path := 
        if($collection != '') then 
            if($collection = 'place') then '/places' else ('/' || $collection)
         else '' 
    let $path := ($config:app-root || '/data' || $collection-path) 
    for $feed in collection($path)/tei:TEI 
    let $date := $feed[1]//tei:publicationStmt[1]/tei:date[1]/text()
    order by $date descending
    return $feed   
};

(:~
 : Return subsequence of full feed
 : @param $collection name of syriaca.org subcollection 
 : @param $start start position for results
 : @param $perpage number of pages to return 
 : @return An atom entry element
:)
declare function feed:process-feed($collection as xs:string?,$start as xs:integer?, $perpage as xs:integer?) as element(entry)*{
    let $recs := feed:get-feed($collection)
    for $rec in subsequence($recs,$start, $perpage)
    return feed:build-entry($rec)
};

(:~
 : Get most recently updated date from feed results
 : @param $collection name of syriaca.org subcollection 
 : @return A string
:)
declare function feed:updated-date($collection as xs:string?) as xs:string?{
    for $recent in feed:get-feed($collection)[1]
    let $date := $recent//tei:publicationStmt[1]/tei:date[1]/text()
    return $date
};

(:~
 : Correctly format dates in the TEI
 : @param $date date passed from TEI records
 : @return A string
:)
declare function feed:format-dates($date as xs:string?) as xs:string{
    if($date) then 
        if(string-length($date) = 10) then concat($date,'T12:00:00Z')
        else if(string-length($date) = 4) then concat($date,'01-01T12:00:00Z')
        else if(string-length($date) gt 10) then concat(substring($date,1,10),'T12:00:00Z')
        else ''
    else ''
};

(:~
 : Get single entry 
 : @param $collection name of syriaca.org subcollection 
 : @param $id record id
 : @return As atom feed element
:)
declare function feed:get-entry($collection as xs:string, $id as xs:string?) as element(feed)?{
    let $collection-path :=  
        if($collection = 'place') then '/places' else ('/' || $collection || '/tei/') 
    let $path := ($config:app-root || '/data' || $collection-path || $id || '.xml') 
    for $feed in doc($path)/tei:TEI
    let $date := $feed[1]//tei:publicationStmt[1]/tei:date[1]/text()
    return
    <feed xmlns="http://www.w3.org/2005/Atom" xmlns:georss="http://www.georss.org/georss"> 
        <title>The Syriac Gazetteer: Latest Updates</title>
        <link rel="self" type="application/atom+xml" href="http://syriaca.org/atom.xql"/>
        <id>tag:syriaca.org,2013:gazetteer-latest</id>
        <updated xmlns="http://www.w3.org/2005/Atom">{feed:format-dates($date)}</updated>
        {feed:build-entry($feed)}
    </feed>  
};

(:~
 : Build atom entry from TEI record data
 : @param $rec TEI record
 : @return A atom entry element
:)
declare function feed:build-entry($rec as element()*) as element(entry){
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
        <updated>{feed:format-dates($date)}</updated>
        {($summary, $res-pers)}
    </entry>  
};

(:~
 : Build atom feed
 : @param $collection name of syriaca.org subcollection 
 : @param $start
 : @param $perpage
 : @return A atom feed element
:)
declare function feed:build-feed($collection as xs:string?, $start as xs:integer?, $perpage as xs:integer?) as element(feed)?{
    <feed xmlns="http://www.w3.org/2005/Atom" xmlns:georss="http://www.georss.org/georss"> 
        <title>The Syriac Gazetteer: Latest Updates</title>
        <link rel="self" type="application/atom+xml" href="http://syriaca.org/atom.xql"/>
        <id>tag:syriaca.org,2013:gazetteer-latest</id>
        <updated xmlns="http://www.w3.org/2005/Atom">{feed:updated-date($collection)}</updated>
        {feed:process-feed($collection,$start,$perpage)}
    </feed>
};