# Unit Testing in DHF Applications

## Enabling XQuery Unit Testing

Add the following properties to your ``gradle-local.properties`` : 
```    
mlTestRestPort=<STAGING-HTTP-PORT|8010>
mlFinalTestDbName=unitTest-FINAL-TEST   
```
The database `unitTest-FINAL-TEST` is created by default it is a duplicate of `unitTest-FINAL`. Unfortunately for the moment it needs
to be manually kept in sync with `unitTest-FINAL` - its configuration definition is stored under `user-config/databases/final-test-database.json`.

One the properties above have been added you must execute `gradle mlDeploy` in order to have the unit test invocation
routine deployed. 

Unit test code should be placed in its own suite under `plugins/test/suites`. There are existing test suites as well as 
some samples. This is actually a clone of the MarkLogic Roxy 
unit testing framework, for more 
detail see [here](https://github.com/marklogic-community/roxy/wiki/Unit-Testing).

In order to execute the tests there are a few choices: 

1. in batch: execute `gradle mlUnitTest`
2. interactive: point your browser to `localhost:8010/test/default.xqy`. All your unit test suites will be displayed on 
this page and you can choose which to execute. You can also prevent test teardown from running if you want to inspect any
data.
3. Invoke them as a JUnit test from within Java. 

Here are some rules for developers

1. Keep configuration of `unitTest-FINAL-TEST` manually in sync with `unitTest-FINAL`
2. The app server `unitTest-FINAL-TEST` runs on port `8014`. You can use this for tests which need a rest endpoint. E.g. 
if you wish to search test content and run some assertions on the results then you can use this endpoint.
3. As a result of 2. you need to make sure that the search options and other rest artifacts are deployed to this app server. 
In order to do this execute the mlGradle task `mlDeploy` with `-PenvironmentName=test`. There is a special gradle
properties file with settings to achieve this.
4. It suits my project beset to run the tests under the STAGING (that is the context db) and make any test assertions in 
FINAL using `xdmp:invoke-function`

## Nice to Have

It would be nice if all the DBs (JOBS, TRACING, TRIGGERS, FINAL, STAGING) and the respective test application servers for 
STAGING and FINAL could be created and deployed automatically.

  


  
