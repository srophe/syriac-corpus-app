xquery version "3.0";

import module namespace srophe-util-date="http://srophe.org/ns/srophe-util-date" at "srophe-util-date.xql";
declare namespace tei="http://www.tei-c.org/ns/1.0";
declare namespace request="http://exist-db.org/xquery/request";

declare variable $resource-uri {request:get-parameter('resource', '')};
(
    xmldb:login('/db/apps/srophe/', 'admin', '', true()), srophe-util-date:custom-dates-doc($resource-uri)
)