xquery version "1.0-ml";

import module namespace cfg = "http://acme.com/unittest/config" at "/lib/config.xqy";
import module namespace tf = "http://acme.com/unittest/test-flows-lib" at "/lib/test-flows-lib.xqy";

declare variable $PERMISSIONS := $cfg:UNITTEST-USER-ROLE-DEFAULT-PERMISSIONS;


xdmp:log("Harmonise unittest Suite Setup STARTING....")

,

try {(
  (:remove any pre-existing unittest documents from the STAGING db:)
  xdmp:invoke-function(
    function() {
      cts:uri-match("/content/unittest/*") => xdmp:document-delete()
    },
    <options xmlns="xdmp:eval">
      <isolation>different-transaction</isolation>
      <transaction-mode>update-auto-commit</transaction-mode>
    </options>

  )
  ,
  xdmp:log("XXX number of unittest docs ="||fn:count(cts:uri-match("/content/unittest/*")) )
  ,
  let $host := "localhost"
  let $port := "8010"
  let $flow-name := "unittest"
  let $entity := "Asset"
  let $db := $cfg:STAGING-DB
  let $target-db := $cfg:STAGING-DB
  return tf:run-harmonisation-flow($entity, $flow-name, $db, $target-db, $host, $port, (), ())


)} catch  ($ex) {
    xdmp:log(xdmp:quote($ex),"error")
}

,

xdmp:log("Harmonise unittest Suite Setup COMPLETE....")
