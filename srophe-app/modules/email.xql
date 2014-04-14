xquery version "3.0";

(:~
 : Builds dynamic nav menu based on url called by page.html
 :)


declare namespace xslt="http://exist-db.org/xquery/transform";
declare namespace tei="http://www.tei-c.org/ns/1.0";
declare namespace xlink = "http://www.w3.org/1999/xlink";
declare namespace mail="http://exist-db.org/xquery/mail";
declare namespace request="http://exist-db.org/xquery/request";
import module namespace recap = "http://www.exist-db.org/xquery/util/recapture" at "recaptcha.xqm";

declare option exist:serialize "method=xml media-type=text/xml indent=yes";

declare function local:recaptcha(){
let $recapture-private-key := "6Lf1uvESAAAAANlfEgUXBpEU95Bh83BoVtEz8gZE" 
return 
    recap:validate($recapture-private-key, 
    request:get-parameter("recaptcha_challenge_field", ()), 
    request:get-parameter("recaptcha_response_field",()))
};



declare function local:build-message(){
let $place := if(request:get-parameter('id','')) then concat('for ',request:get-parameter('id','')) else ''
let $place-uri := if(request:get-parameter('id','')) then concat('Place: http://syriaca.org/place/',request:get-parameter('id','')) else ''
return
  <mail>
    <from>Syriaca.org &lt;david.a.michelson@vanderbilt.edu&gt;</from>
    <!--<to>wsalesky@gmail.com</to>-->
    <!--<to>david.a.michelson@vanderbilt.edu</to>-->
    <!--<cc>tcarlson@princeton.edu</cc>-->
    <subject>{request:get-parameter('subject','')} for {request:get-parameter('place','')} [{request:get-parameter('id','')}]</subject>
    <message>
      <xhtml>
           <html>
               <head>
                 <title>{request:get-parameter('subject','')}</title>
               </head>
               <body>
                 <p>Name: {request:get-parameter('name','')}</p>
                 <p>e-mail: {request:get-parameter('email','')}</p>
                 <p>Subject: {request:get-parameter('subject','')} {$place}</p>
                 <p>{$place-uri}</p>
                 {request:get-parameter('comments','')}
              </body>
           </html>
      </xhtml>
    </message>
  </mail>
};

let $cache := 'change this value to force page refresh 33'
return 
    if(exists(request:get-parameter('email','')) and request:get-parameter('email','') != '') 
        then 
            if(exists(request:get-parameter('comments','')) and request:get-parameter('comments','') != '') 
              then
               if(local:recaptcha() = true()) then 
                 if (mail:send-email(local:build-message(),"library.vanderbilt.edu", ()) ) then
                   <h4>Thank you. Your message has been sent.</h4>
                 else
                   <h4>Could not send message.</h4>
                else 'Recaptcha fail'   
            else  <h4>Incomplete form.</h4>
   else  <h4>Incomplete form.</h4>            