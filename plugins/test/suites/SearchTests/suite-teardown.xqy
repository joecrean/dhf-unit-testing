xquery version "1.0-ml";

import module namespace cfg = "http://acme.com/unittest/config" at "/lib/config.xqy";

declare namespace error = "http://marklogic.com/xdmp/error";

xdmp:log("Search Suite Teardown STARTING....")

,
try {
	let $cleanup := function() {

		let $result :=
			for $i at $count in cts:uris()
			let $_ := xdmp:log(fn:concat("Search Suite Teardown : removing test file ",$count," uri = ", $i) )
			return (xdmp:document-delete($i),1)
		return xdmp:log(fn:concat("Search Suite Teardown: removed ",fn:count($result), " test files from db ",xdmp:database-name(xdmp:database()) ) )

	}
	return
		xdmp:invoke-function(
				$cleanup,
				<options xmlns="xdmp:eval">
					<database>{xdmp:database($cfg:FINAL-TEST-DB)}</database>
				</options>
		)


} catch ($ex) {
	  xdmp:log(fn:concat("Search teardown failed ", $ex/error:format-string/text() ), "error")

}

,

xdmp:log("Search Suite Teardown ENDING....")
