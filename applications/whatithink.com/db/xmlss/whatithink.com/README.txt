Application notes

1) checkout from eXist trunk from svn
2) enable xslfo module in extensions/build.properties
3) ./build.sh
4) modify webapp/WEB-INF/web.xml so that XFormsFilter is filtering the path /apps/*
5) Enable xslfo module in conf.xml
6) Enable datetime module in conf.xml
7) bin/startup.sh
8) Restore the database backup from SourceForge Subversion - https://seewhatithink.svn.sourceforge.net/svnroot/seewhatithink/trunk/applications/whatithink.com
9) bin/shutdown.sh
10) bin/startup.sh
11) Visit - http://localhost:8080/exist/apps/xmlss/whatithink.com/


NOTE managers need to be in the 'dba' group


--- KNOWN ISSUES ---
1) Upload Ontology does not work at the moment (to be fixed)



--- OLD (IGNORE) --
1) the group "whatithink.users" needs to be created
3) Collection /db/xmlss/whatithink.com/users needs to be created, owned by "admin":"whatithink.users", permissions "rwurwur--"