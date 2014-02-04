xquery version "3.0";

(:~
 : Builds dynamic nav menu based on url called by page.html
 :)


declare namespace xslt="http://exist-db.org/xquery/transform";
declare namespace tei="http://www.tei-c.org/ns/1.0";
declare namespace xlink = "http://www.w3.org/1999/xlink";
declare namespace mail="http://exist-db.org/xquery/mail";
declare namespace request="http://exist-db.org/xquery/request";

declare option exist:serialize "method=xml media-type=text/xml indent=yes";

declare function local:build-message-test(){
  <mail>
    <from>Syriaca.org &lt;david.a.michelson@vanderbilt.edu&gt;</from>
    <to>david.a.michelson@vanderbilt.edu</to>
    <cc>tcarlson@princeton.edu</cc>
    <subject>{request:get-parameter('subject','')} for {request:get-parameter('id','')}</subject>
    <message>
      <xhtml>
           <html>
               <head>
                 <title>test mail funciton</title>
               </head>
               <body>
                 <p>Name: {request:get-parameter('name','')}</p>
                 <p>e-mail: {request:get-parameter('email','')}</p>
                 <p>Subject: {request:get-parameter('subject','')} for {request:get-parameter('id','')}</p>
                 <p>Place: http://syriaca.org//place/{request:get-parameter('id','')}</p>
                 {request:get-parameter('comments','')}
              </body>
           </html>
      </xhtml>
    </message>
  </mail>
};

let $cache := 'change this value to force page refresh 33'
return 
    if ( mail:send-email(local:build-message-test(),"library.vanderbilt.edu", ()) ) then
      <h4>Thank you. Your message has been sent.</h4>
    else
      <h4>Could not send message.</h4>
