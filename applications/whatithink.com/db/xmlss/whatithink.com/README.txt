About
-----
This is the seewhatithink.com training Web Application
for the XML Summer School.

The application has been re-developed in a pure
XML application stack for 2011.
The following technologies and standards are used:
XQuery, XForms, XSLT, XSL-FO and XML.
The application run's atop the eXist-db
Native XML Database application
platform - www.exist-db.org

Author: Adam Retter <adam.retter@googlemail.com>
Licence: Apache License Version 2.0


Requirements
------------
Oracle/Sun Java JDK 1.6


How to Install
--------------
1) checkout eXist trunk from SourceForge Subversion e.g.

svn co https://exist.svn.sourceforge.net/svnroot/exist/trunk/eXist

2) Set an Environment Variable EXIST_HOME that points to the location where you just checked out eXist-db e.g.
export EXIST_HOME=/opt/eXist

3) enable xslfo module in $EXIST_HOME/extensions/build.properties e.g.

# XSL FO transformations (Uses Apache FOP)
include.module.xslfo = true

4) Build the eXist-db source code 
cd $EXIST_HOME
./build.sh

5) Modify $EXIST_HOME/webapp/WEB-INF/web.xml so that XFormsFilter is filtering the path /apps/* e.g.

<filter-mapping>
    <filter-name>XFormsFilter</filter-name>
    <url-pattern>/apps/*</url-pattern>
</filter-mapping>

6) Uncomment xslfo xquery extension module in $EXIST_HOME/conf.xml e.g.

<module uri="http://exist-db.org/xquery/xslfo" class="org.exist.xquery.modules.xslfo.XSLFOModule">
    <parameter name="processorAdapter" value="org.exist.xquery.modules.xslfo.ApacheFopProcessorAdapter"/>
</module>

7) Uncomment datetime module in $EXIST_HOME/conf.xml e.g.

<module uri="http://exist-db.org/xquery/datetime" class="org.exist.xquery.modules.datetime.DateTimeModule"/>


8) Checkout the database backup from SourceForge Subversion into a folder somewhere safe e.g.

svn co https://seewhatithink.svn.sourceforge.net/svnroot/seewhatithink/trunk/applications/whatithink.com

9) Startup the eXist-db database e.g.

cd $EXIST_HOME
bin/startup.sh

10) Restore the database backup from Step (8) e.g.

cd $EXIST_HOME
bin/backup.sh -u admin -r ../whatithink.com/db/__contents__.xml 

NOTE - the path to whatithink.com may need to be adjusted depending on where you checked this out to in Step (8). 

11) Shutdown the eXist-db database 
cd $EXIST_HOME
bin/shutdown.sh


12) Startup the eXist-db database 
cd $EXIST_HOME
bin/startup.sh

13) In a web browser visit thus URI - http://localhost:8080/exist/apps/xmlss/whatithink.com/


NOTES
-----
1) 'managers' of the whatithink.com need to be in the 'dba' group to see all of the management menu items in the webapp!
2) You can browse the content of the database using eXist-db's Java Admin client e.g. 
cd $EXIST_HOME
bin/client.sh