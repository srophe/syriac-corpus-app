xquery version "3.0";
(:
 : Module Name: xqOAI
 : Module Version: 1.3
 : Updated: Sept. 19, 2014
 : Date: September, 2007
 : Copyright: Michael J. Giarlo and Winona Salesky
 : Proprietary XQuery Extensions Used: eXist-db
 : XQuery Specification: November 2005
 : Module Overview: Adapted from xqOAI to provide OAI-PMH data provider for 
 : TEI records. Output includes TEI, MADS, and RDF records.
 : NOTE: Should add a RDF option
 : NOTE: also add subcollection options? 
 :)

(:~
 : OAI-PMH data provider for TEI records within an eXist 
 :
 : @author Michael J. Giarlo
 : @author Winona Salesky
 : @since April, 2010
 : @version 1.3
 :)

(: declare namespaces for each metadata schema we care about :)
declare namespace rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#";
declare namespace xlink = "http://www.w3.org/1999/xlink";
declare namespace dc="http://purl.org/dc/elements/1.1/";
declare namespace mods = "http://www.loc.gov/mods/v3";
declare namespace dcterms = "http://purl.org/dc/terms/";
declare namespace xslt="http://exist-db.org/xquery/transform";
declare namespace tei = "http://www.tei-c.org/ns/1.0";
declare namespace oai_dc="http://www.openarchives.org/OAI/2.0/oai_dc/";
declare namespace request="http://exist-db.org/xquery/request";

declare option exist:serialize "method=xml media-type=text/xml omit-xml-declaration=no indent=yes";

(: configurable variables :)
declare variable $base-url           := 'http://syriaca.org/api/oai';
declare variable $repository-name    := 'Syriaca.org';
declare variable $admin-email        := 'david.a.michelson@vanderbilt.edu';
declare variable $hits-per-page      := 300;
declare variable $earliest-datestamp := '2012-01-01';
declare variable $_docs := collection('/db/appa/srophe/data')//tei:TEI;
declare variable $oai-domain         := 'syriaca.org';
declare variable $id-scheme          := 'oai';

(: params from OAI-PMH spec :)
declare variable $verb {request:request-parameter('verb', '')};
declare variable $identifier {request:request-parameter('identifier', '')};
declare variable $from {request:request-parameter('from', '')};
declare variable $until {request:request-parameter('until', '')};
declare variable $set {request:request-parameter('set', '')};
declare variable $start {request:request-parameter('resumptionToken', 1) cast as xs:integer};
declare variable $metadataPrefix {request:request-parameter('metadataPrefix', 'oai_dc') cast as xs:string};
declare variable $resumptionToken {request:request-parameter('resumptionToken', '')};

(: set to true in argstring for extra debugging information :)
declare variable $verbose {request:request-parameter('verbose', '')};

(:~
 : Print datetime of OAI response. 
 : - Uses substring and concat to get the date in the format OAI wants
 :
 : @return XML
 :)
declare function local:oai-response-date() {
    <responseDate>{ 
        concat(substring(current-dateTime() cast as xs:string, 1, 19), 'Z') 
    }</responseDate>
};

(:~
 : Build the OAI request element 
 :
 : @return XML
 :)
declare function local:oai-request() {
   element request {
       (
       if ($metadataPrefix != '')  then attribute metadataPrefix {$metadataPrefix}   else '',
       if ($verb != '')           then attribute verb {$verb}                       else '',
       if ($identifier != '')      then attribute identifier {$identifier}           else '',
       if ($from != '')            then attribute from {$from}                       else '',
       if ($until != '')           then attribute until {$until}                     else '',
       if ($set != '')             then attribute set {$set}                         else '',
       if ($resumptionToken != '') then attribute resumptionToken {$resumptionToken} else '')
   }
};
(:~
 : Get resumptionToken
 : - this is a stub
 : TO-DO: real resumptionTokens, using xquery update to store result sets in the db
 :
 : @return valid resumptionToken in appropriate format
 :)
declare function local:get-cursor-token() {
    if ($resumptionToken = '') then 
        1
    else 
        $resumptionToken cast as xs:integer
};

declare function local:validateParams(){
    let $parameters :=  request:get-parameter-names()
    for $param in $parameters
    return
        if($param = 'verb' or $param = 'identifier' or $param = 'from' or $param = 'until' or $param = 'set' or $param = 'metadataPrefix' or $param = 'resumptionToken' or $param = 'start') 
            then ''
        else <error code="badArgument">Invalid OAI-PMH parameter : {$param}</error>
};

declare function local:errorCheck(){
     if (exists($verb) and $verb = 'GetRecord') then
            (if(not(exists($identifier))) then <error code="badArgument">identifier is a required argument</error> else '',
            if (exists($identifier) and $identifier = '') then <error code="badArgument">identifier is a required argument</error> else '',
            if (exists($metadataPrefix) and $metadataPrefix != 'oai_dc') then <error code="cannotDisseminateFormat">only oai_dc is supported</error> else '',
             if (exists($metadataPrefix) and count($metadataPrefix) gt 1) then <error code="badArgument">Only one metadataPrefix argument acceptable</error> else '')
     else if (exists($verb) and $verb = 'ListIdentifiers' or $verb = 'ListRecords') then 
           (if(exists($resumptionToken) and $resumptionToken != '' and not(matches($resumptionToken, '^\d+$'))) then <error code="badResumptionToken">bad resumptionToken</error> else '',
            if(exists($metadataPrefix) and $metadataPrefix != 'oai_dc') then <error code="cannotDisseminateFormat">only oai_dc is supported</error> else '',
            if (exists($metadataPrefix) and count($metadataPrefix) gt 1) then <error code="badArgument">Only one metadataPrefix argument acceptable</error> else '',
            if(exists($from) and $from !='' or exists($until) and $until !='')  then
                if(local:validate-dates() = 'true') then 
                    if(exists($from) and $from lt $earliest-datestamp) then <error code="noRecordsMatch">Earliest date available is {$earliest-datestamp}</error> else ''
                else <error code="badArgument">From/until arguments are not valid</error>
            else ''   
            )  
     else ''
};

(:Begin Error checking, accept only valid paremters:)
declare function local:testParameters(){
let $error :=
    if(local:validateParams() != '') then  local:validateParams()
    else local:errorCheck()
return $error
};

(:~
 : Validate from and until params
 : - dates are valid only if they match date-pattern and are in same format
 : - note that date-pattern also matches an empty string
 :
 : @return boolean
 :)
declare function local:validate-dates() {
    let $date-pattern := '^(\d{4}-\d{2}-\d{2}){0,1}$'
    let $from-len     := string-length($from)
    let $until-len    := string-length($until)
    return
        if ($from-len > 0 and $until-len > 0 and $from-len != $until-len) then
            'false'
        else
            if(matches($from, $date-pattern) and matches($until, $date-pattern)) then 'true' else 'false'
 };

(:~
  : Modifies dates extracted from TEI records to be OAI compliant
:)

declare function local:modDate(){    
    let $date := string(tei:teiHeader/tei:publicationStmt/tei:date)
    let $shortDate :=  substring-before($date,'T')
    return if(exists($shortDate) and $shortDate != '') then $shortDate else '2006-01-01' 
};
(:~
 : Build xpath for selecting records based on date range or sets
 : NOTE: srophe currently does not support sets
:)
declare function local:buildPath(){
   if(exists($from) and $from != '' and exists($until) and $until != '') then
        if(exists($set) and $set !='') then  
            $_docs[local:modDate() gt $from and local:modDate() lt $until and .//mods:titleInfo[@ID = $set]] |
            $_docs[local:modDate() gt $from and local:modDate() lt $until and .//dcterms:isPartOf[@id = $set]]
        else
            $_docs[local:modDate() gt $from and local:modDate() lt $until]
    else if(exists($from) and $from != '' and exists($until) and $until = '') then 
        if(exists($set) and $set !='') then 
            $_docs[local:modDate() gt $from and .//mods:titleInfo[@ID = $set]] |
            $_docs[local:modDate() gt $from and .//dcterms:isPartOf[@id = $set]]
        else
            $_docs[local:modDate() gt $from]        
    else if(exists($from) and $from != '' and not(exists($until))) then
        if(exists($set) and $set !='') then 
            $_docs[local:modDate() gt $from and .//mods:titleInfo[@ID = $set]] | 
            $_docs[local:modDate() gt $from and .//dcterms:isPartOf[@id = $set]]
        else
            $_docs[local:modDate() gt $from]
    else if(exists($until) and $until != '') then 
        if(exists($set) and $set !='') then 
             $_docs[local:modDate() lt $until and .//mods:titleInfo[@ID = $set]] | 
             $_docs[local:modDate() lt $until and .//dcterms:isPartOf[@id = $set]]
        else
            $_docs[local:modDate() lt $until]
    else
        if(exists($set) and $set !='') then 
            $_docs[.//mods:titleInfo[@ID = $set]] |
            $_docs[.//dcterms:isPartOf[@id = $set]]
        else
            $_docs
};


(:~
 : Branch processing based on client-supplied "verb" param
 :
 : @param $_hits a sequence of XML docs
 : @param $_end an integer reflecting the last item in the current page of results
 : @param $_count an integer reflecting total hits in the result set
 : @return XML if errors, nothing if not
 :)
declare function local:oai-response() { 
    if (exists(local:testParameters()) and local:testParameters() !='') then local:testParameters()
    else 
            if      ($verb = 'ListSets')            then local:oai-list-sets()
            else if ($verb = 'ListRecords')         then local:oai-list-records()
            else if ($verb = 'ListIdentifiers')     then local:oai-list-identifiers()
            else if ($verb = 'GetRecord')           then local:oai-get-record()
            else if ($verb = 'ListMetadataFormats') then local:oai-list-metadata-formats()
            else if ($verb = 'Identify')            then local:oai-identify()
            else <error code="badVerb">Invalid OAI-PMH verb : { $verb }</error>        
};


(:~
 : Print a metadata record
 : - the mods/ead brancher is inelegant -- more abstraction may be helpful here
 : TO-DO: find a way to make this easier to extend, e.g., for new metadata formats
 :
 : @param $_record an XML record
 : @return XML
 :)
declare function local:oai-metadata($record) {
      <metadata>{local:buildDC($record)}</metadata>
};

(:~
 : Extract OAI identifier from MODS or EAD
 : - currently assumes only mods and ead are relevant
 : TO-DO: get rid of hard-coding
 :
 : @param $_record an XML record
 : @return a string representing an OAI identifier
 :)
declare function local:get-identifier($record) {
   let $id := string($record/@OBJID)
   let $oaiID := concat('oai:cdi.uvm.edu:',$id)
   return $oaiID
};

(:~
 : Print the resumptionToken
 : TO-DO: fix this up when resumptionToken support is built-in
 :
 : @param $_end integer, index of last item in current page of results
 : @param $_count integer, total number of hits in result set
 : @return XML or nothing
 :)
declare function local:print-token($_end, $_count) {
    if ($_end + 1 < $_count) then 
        let $token :=  $_end + 1  
        return
            <resumptionToken completeListSize="{ $_count }" cursor="{ $start - 1 }">{ $token }</resumptionToken>
    else ''
};

(:~
 : OAI GetRecord verb
 :
 : @param $_hits a sequence of XML docs
 : @return XML corresponding to a single OAI record
 :)
declare function local:oai-get-record() {
    let $docID := substring-after($identifier,'oai:cdi.uvm.edu:')
    let $_hits := $_docs[@OBJID = $docID]
    let $record := $_hits
    let $date := substring-before($record/mets:metsHdr/@LASTMODDATE,'T')
    let $oaiDate := concat(string($date),'Z')
    return 
        if($_hits !='') then
        <GetRecord>
            <record>{
                      if($record/mets:metsHdr/@RECORDSTATUS='deleted') then 
                        <header status='deleted'>
                        <identifier>{$identifier}</identifier>
                        <datestamp>{$oaiDate}</datestamp>
                        {
                        let $set := $record//dcterms:isPartOf | $record//mods:relatedItem[@type='host']
                        for $oaiSet in $set
                        let $setID := $oaiSet/mods:titleInfo/@ID | $oaiSet/@id
                        let $idString := string($setID)
                        return
                            <setSpec>{$idString}</setSpec>
                         }
                        </header>
                     else 
                        (<header>
                        <identifier>{$identifier}</identifier>
                        <datestamp>{$oaiDate}</datestamp>
                        {
                        let $set := $record//dcterms:isPartOf | $record//mods:relatedItem[@type='host']
                        for $oaiSet in $set
                        let $setID := $oaiSet/mods:titleInfo/@ID | $oaiSet/@id
                        let $idString := string($setID)
                        return
                            <setSpec>{$idString}</setSpec>
                         }
                    </header>, local:oai-metadata($record) )
            }</record>
            { 
                if ($verbose = 'true') then 
                    <debug>{ $record }</debug> 
                else ''
            }
        </GetRecord> 
        else
        <error code="idDoesNotExist">No Records matched your criteria.</error>
        
};

(:~
 : OAI Identify verb
 :
 : @return XML describing the OAI provider
 :)
declare function local:oai-identify() {
      <Identify>
        <repositoryName>{ $repository-name }</repositoryName>
        <baseURL>{ $base-url }</baseURL>
        <protocolVersion>2.0</protocolVersion>
        <adminEmail>{ $admin-email }</adminEmail>
        <earliestDatestamp>{ $earliest-datestamp }</earliestDatestamp>
        <deletedRecord>transient</deletedRecord>
        <granularity>YYYY-MM-DD</granularity>
        <compression>deflate</compression>
     </Identify>
};

(:~
 : OAI ListIdentifiers verb
 :
 : @param $_hits a sequence of XML docs
 : @param $_end integer, index of last item in page of results
 : @param $_count integer, total number of hits in result set
 : @return XML corresponding to a list of OAI identifier records
 :)
declare function local:oai-list-identifiers() {
let $_hits := local:buildPath()
let $_count := count($_hits)
let $max := $hits-per-page
let $_end := if ($start + $max - 1 < $_count) then 
                $start + $max - 1 
            else 
                $_count 
return           
    if($_count eq 0) then  <error code="noRecordsMatch">No Records matched your criteria.</error>
    else
    <ListIdentifiers>{
        for $i in $start to $_end
        let $record := $_hits[$i]
        let $date := substring-before($record/mets:metsHdr/@LASTMODDATE,'T')
        let $oaiDate := concat(string($date),'Z')
        let $status := $record/mets:metsHdr/@RECORDSTATUS
        return 
          (<header>
          <identifier>{local:get-identifier($record)}</identifier>
          <datestamp>{$oaiDate}</datestamp>
          {
             let $set := $record//dcterms:isPartOf | $record//mods:relatedItem[@type='host']
             for $oaiSet in $set
             let $setID := $oaiSet/mods:titleInfo/@ID | $oaiSet/@id
             let $idString := string($setID)
             return
                <setSpec>{$idString}</setSpec>
            }

         </header>
         )
         } 
         { local:print-token($_end, $_count)}
        </ListIdentifiers>
};

(:~
 : OAI ListMetadataFormats verb
 :
 : @return XML corresponding to a list of supported metadata formats
 :)
declare function local:oai-list-metadata-formats() {
    <ListMetadataFormats>
      <metadataFormat>
        <metadataPrefix>oai_dc</metadataPrefix>
        <schema>http://www.openarchives.org/OAI/2.0/oai_dc.xsd</schema>
        <metadataNamespace>http://www.openarchives.org/OAI/2.0/oai_dc/</metadataNamespace>
      </metadataFormat>
    </ListMetadataFormats>
};

(:~
 : OAI ListRecords verb
 :
 : @param $_hits a sequence of XML docs
 : @param $_end integer, index of last item in page of results
 : @param $_count integer, total number of hits in result set
 : @return XML corresponding to a list of full OAI records
 :)
declare function local:oai-list-records() {
let $_hits := local:buildPath()
let $_count := count($_hits)
let $max := $hits-per-page
let $_end := if ($start + $max - 1 < $_count) then 
                $start + $max - 1 
            else 
                $_count 
return 
    if($_count eq 0) then  <error code="noRecordsMatch">No Records matched your criteria.</error>
    else
    <ListRecords>{    
      for $i in $start to $_end
      let $record := $_hits[$i]
      let $date := substring-before($record/mets:metsHdr/@LASTMODDATE,'T')
      let $oaiDate := concat(string($date),'Z')
      let $status := $record/mets:metsHdr/@RECORDSTATUS
      return
          (<record>{ 
            <header>
              <identifier>{local:get-identifier($record)}</identifier>
              <datestamp>{$oaiDate}</datestamp>
                {
                 let $set := $record//dcterms:isPartOf | $record//mods:relatedItem[@type='host']
                 for $oaiSet in $set
                 let $setID := $oaiSet/mods:titleInfo/@ID | $oaiSet/@id
                 let $idString := string($setID)
                 return
                    <setSpec>{$idString}</setSpec>
                 }

            </header>,
            local:oai-metadata($record)
          }</record>
          )  
      }
      {local:print-token($_end, $_count) }
</ListRecords>
};

(:~
 : OAI ListSets verb
 :
 : @param $_hits a sequence of XML docs
 : @return XML corresponding to a list of OAI set records
 :)
declare function local:oai-list-sets() {
    <ListSets>
       {
        for $record in $_docs[@TYPE = 'collection']
        let $collectionID := $record/@OBJID
        let $title := if($record/@LABEL != '') then $record/@LABEL 
                      else $record//dc:title
        return
        <set>
            <setSpec>{string($collectionID)}</setSpec>
            <setName>{string($title)}</setName>
        </set>
        }
   </ListSets>
};

(:Creates DC title tags:)
declare function local:dcTitle($record) {
    let $title := $record//dc:title | $record//archdesc/did/unittitle | $record//mods:titleInfo/descendant::*
    for $dcTitle in $title
    return
        <dc:title>{string($dcTitle)}</dc:title>
};

(:Creates the DC Creator/Contributor tags:)
declare function local:dcCreator($record) {
    let $creator := $record//dc:creator | $record//dc:contributor | $record//archdesc/did/origination[@label = 'Creator']/descendant::* | $record//mods:name/mods:namePart
    for $dcCreator in $creator
    return
        <dc:creator>{string($dcCreator)}</dc:creator>
};

(:Creates DC subject tags:)
declare function local:dcSubject($record) {
    let $subject := $record//dc:subject | $record//archdesc/controlaccess/subject/descendant::* | $record//mods:subject/descendant::*
    for $dcSubject in $subject
    return
    <dc:subject>{string($dcSubject)}</dc:subject>
};

(:Creates DC description tags:)
declare function local:dcDescription($record) {
    let $description := $record//dc:description | $record//archdesc//abstract/descendant-or-self::* | $record//mods:abstract/descendant-or-self::*  | $record//mods:tableOfContents
    for $dcDescription in $description
    return
    <dc:description>{string($dcDescription)}</dc:description>
};

(:Creates DC date tags -- i did not include the dc:date, becuase we use that for creation of digital object:)
declare function local:dcDate($record) {
    let $date :=  $record//dcterms:temporal | $record//publicationstmt//date | $record//archdesc/unitdate | $record//mods:date  | $record//mods:dateCreated
    for $dcDate in $date
    return
    <dc:date>{string($dcDate)}</dc:date>
};

declare function local:rights($record) {
    let $rights :=  $record//dc:rights |  $record//mods:accessCondition
    for $dcRights in $rights
    return
    <dc:rights>{string($dcRights)}</dc:rights>
};
(:Creates DC record:)
declare function local:buildDC($record){
    <oai_dc:dc xmlns:oai_dc="http://www.openarchives.org/OAI/2.0/oai_dc/" xmlns:dc="http://purl.org/dc/elements/1.1/" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"  xsi:schemaLocation="http://www.openarchives.org/OAI/2.0/oai_dc/ http://www.openarchives.org/OAI/2.0/oai_dc.xsd">

    {
        (local:dcTitle($record), 
        local:dcCreator($record),
        local:dcSubject($record),
        local:dcDescription($record),
        local:dcDate($record),
        local:rights($record))
    }
    </oai_dc:dc> 
};

(: OAI-PMH wrapper for request and response elements :)
<OAI-PMH xmlns="http://www.openarchives.org/OAI/2.0/" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:schemaLocation="http://www.openarchives.org/OAI/2.0/ http://www.openarchives.org/OAI/2.0/OAI-PMH.xsd">
         { 
            (local:oai-response-date(),local:oai-request(), local:oai-response())
           }
</OAI-PMH>