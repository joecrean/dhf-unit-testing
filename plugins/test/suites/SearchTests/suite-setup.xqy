xquery version "1.0-ml";

import module namespace test="http://marklogic.com/roxy/test-helper" at "/test/test-helper.xqy";
import module namespace sem = "http://marklogic.com/semantics" at "/MarkLogic/semantics.xqy";
import module namespace cfg = "http://acme.com/unittest/config" at "/lib/config.xqy";
import module namespace functx = "http://www.functx.com" at "/MarkLogic/functx/functx-1.0-nodoc-2007-01.xqy";
import module namespace tf = "http://acme.com/unittest/test-flows-lib" at "/lib/test-flows-lib.xqy";

declare variable $PERMISSIONS := $cfg:UNITTEST-USER-ROLE-DEFAULT-PERMISSIONS;


xdmp:log("Search Suite Setup STARTING....")

,

try {(
  let $host := "localhost"
  let $port := "8010"
  let $flow-name := "HarmonizePublicationsAcrossSources"
  let $entity := "Asset"
  let $db := $cfg:STAGING-DB
  let $target-db := $cfg:FINAL-TEST-DB
  return tf:run-harmonisation-flow($entity, $flow-name, $db, $target-db, $host, $port, (), ())
  ,
  let $load-triples := function() {
    let $filename := "triples.ttl"
    let $logit := function($triples as sem:triple*){
      let $_ := xdmp:log("Search Suite Setup - loading "||xdmp:quote($triples))
      return $triples
    }
    (:get document node for the triples document....:)
    (:.....parse sem:triple* out of the document node..... :)
    (:.....log them and then pass them on..... :)
    (:.....insert in-mem triples to the FINAL-TEST db:)
    return test:get-test-file($filename)
             => sem:rdf-parse(("graph="||$cfg:DEFAULT-GRAPH-NAME,"turtle") )
             => $logit()
             => sem:rdf-insert( (),($PERMISSIONS), ("MeSH",$cfg:DEFAULT-GRAPH-NAME) )
  }
  return
    xdmp:invoke-function(
          $load-triples,
          <options xmlns="xdmp:eval">
            <database>{xdmp:database($cfg:FINAL-TEST-DB)}</database>
          </options>
    )


)} catch  ($ex) {
    xdmp:log(xdmp:quote($ex),"error")
}

,

xdmp:log("Search Suite Setup COMPLETE....")
