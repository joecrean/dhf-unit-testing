xquery version "1.0-ml";

import module namespace cfg = "http://acme.com/unittest/config" at "/lib/config.xqy";

declare namespace error = "http://marklogic.com/xdmp/error";

xdmp:log("Harmonise unitTest Suite Teardown STARTING....")

,
try {
	()

} catch ($ex) {
	  xdmp:log(fn:concat("Harmonise unitTest teardown failed ", $ex/error:format-string/text() ), "error")

}

,

xdmp:log("Harmonise unitTest Suite Teardown ENDING....")
