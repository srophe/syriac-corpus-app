xquery version "3.1";

(:~
 : Build email from form returns error or sucess message to ajax function
 :)

declare namespace xslt="http://exist-db.org/xquery/transform";
declare namespace tei="http://www.tei-c.org/ns/1.0";
declare namespace xlink = "http://www.w3.org/1999/xlink";
declare namespace mail="http://exist-db.org/xquery/mail";
declare namespace request="http://exist-db.org/xquery/request";
import module namespace global="http://syriaca.org/global" at "lib/global.xqm";
import module namespace recap = "http://www.exist-db.org/xquery/util/recapture" at "recaptcha.xqm";

declare option exist:serialize "method=xml media-type=text/xml indent=yes";

(: Access recaptcha-api configuration file :) 
declare variable $config := doc($global:app-root || '/config.xml');

(: Private key for authentication :)
declare variable $secret-key := if($config//*:recaptcha-secret-key-variable != '') then 
                                    environment-variable($config//*:recaptcha-secret-key-variable/text())
                                 else $config//*:recaptcha-secret-key/text();

(:request:get-parameter("recaptcha_response_field",()):)
declare function local:recaptcha(){
let $recapture-private-key := string($secret-key)
return 
    recap:validate($recapture-private-key, request:get-parameter("g-recaptcha-response",()))
};

declare function local:email-list(){
let $list := 
    if(request:get-parameter('formID','') != '') then 
        request:get-parameter('formID','') 
    else if(request:get-parameter('collection','') != '') then 
        request:get-parameter('collection','') 
    else ()
return 
if($list != '') then 
    if($config/descendant::contact[@listID =  $list]) then 
        for $contact in $config/descendant::contact[@listID =  $list]/child::*
        return element { fn:local-name($contact) } {$contact/text()}
    else 
        for $contact in $config/descendant::contact[1]/child::*
        return element { fn:local-name($contact) } {$contact/text()}
else 
    for $contact in $config/descendant::contact[1]/child::*
    return 
         element { fn:local-name($contact) } {$contact/text()}
};

declare function local:build-message(){
let $rec-uri := if(request:get-parameter('id','')) then concat('for ',request:get-parameter('id','')) else ()
return
    <mail>
    <from>{$global:app-title} &#160;{concat('&lt;',$config//*:contact[not(@listID)]/child::*[1]//text(),'&gt;')}</from>
    {local:email-list()}
    <subject>{request:get-parameter('subject','')}&#160; {$rec-uri}</subject>
    <message>
      <xhtml>
           <html xmlns="http://www.w3.org/1999/xhtml">
               <head>
                 <title>{request:get-parameter('subject','')}</title>
               </head>
               <body>
                 <p>Name: {request:get-parameter('name','')}</p>
                 <p>e-mail: {request:get-parameter('email','')}</p>
                 <p>Subject: {request:get-parameter('subject','')}&#160; {$rec-uri}</p>
                 <p>{$rec-uri}</p>
                 <p>{request:get-parameter('comments','')}</p>
              </body>
           </html>
      </xhtml>
    </message>
  </mail>
};

let $cache := current-dateTime()
return 
    if(exists(request:get-parameter('email','')) and request:get-parameter('email','') != '')  then 
        if(exists(request:get-parameter('comments','')) and request:get-parameter('comments','') != '') then 
            if(local:recaptcha() = true()) then 
               let $mail := local:build-message()
               return 
                   if (mail:send-email($mail,'localhost', ()) ) then
                   <h4>Thank you. Your message has been sent.</h4>
                   else
                   <h4>Could not send message.</h4>
            else 'Recaptcha fail'
        else  <h4>Incomplete form.</h4>
   else  <h4>Incomplete form.</h4>