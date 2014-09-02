xquery version "3.0";

(:~
 : Builds dynamic nav menu based on url called by page.html
 :)

module namespace email="http://syriaca.org//email";

import module namespace config="http://syriaca.org//config" at "config.xqm";
import module namespace place="http://syriaca.org//place" at "place.xql";

declare namespace xslt="http://exist-db.org/xquery/transform";
declare namespace tei="http://www.tei-c.org/ns/1.0";
declare namespace xlink = "http://www.w3.org/1999/xlink";
declare namespace transform="http://exist-db.org/xquery/transform";
declare namespace mail="http://exist-db.org/xquery/mail";
(:
declare variable $message {
  <mail>
    <from>John Doe &lt;sender@domain.com&gt;</from>
    <to>recipient@otherdomain.com</to>
    <cc>cc@otherdomain.com</cc>
    <bcc>bcc@otherdomain.com</bcc>
    <subject>A new task is waiting your approval</subject>
    <message>
      <text>A plain ASCII text message can be placed inside the text elements.</text>
      <xhtml>
           <html>
               <head>
                 <title>HTML in an e-mail in the body of the document.</title>
               </head>
               <body>
                  <h1>Testing</h1>
                  <p>Test Message 1, 2, 3</p>
               </body>
           </html>
      </xhtml>
    </message>
  </mail>
};
 
if ( mail:send-email($message, 'mail server', ()) ) then
  <h1>Sent Message OK :-)</h1>
else
  <h1>Could not Send Message :-(</h1>
    :)

declare variable $message {
  <mail>
    <from>Winona &lt;wsalesky@gmail.com&gt;</from>
    <to>wsalesky@gmail.com</to>
    <subject>TEST mail function</subject>
    <message>
      <text>A plain ASCII text message can be placed inside the text elements.</text>
      <xhtml>
           <html>
               <head>
                 <title>HTML in an e-mail in the body of the document.</title>
               </head>
               <body>
                  <h1>Testing</h1>
                  <p>Test Message 1, 2, 3</p>
               </body>
           </html>
      </xhtml>
    </message>
  </mail>
};

let $cache := 'test'
return
if ( mail:send-email($message, 'mail server', ()) ) then
  <h1>Sent Message OK :-)</h1>
else
  <h1>Could not Send Message :-(</h1>