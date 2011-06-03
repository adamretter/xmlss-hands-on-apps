Application notes

1) checkout from eXist trunk from svn
2) enable xslfo module in extensions/build.properties
3) ./build.sh
4) modify webapp/WEB-INF/web.xml so that XFormsFilter is filtering the path /apps/*
5) Enable xslfo module in conf.xml
6) Enable datetime module in conf.xml
7) bin/startup.sh

...

8) Restore the backup

NOTE managers need to be in the 'dba' group


--- KNOWN ISSUES ---
1) Login box does not work from Registration page (maybe not important)
2) Upload Ontology does not work at the moment (to be fixed)
3) Cannot output doctype declaration from XQuery on XForm pages as betterForm does like it (to be fixed)

--- OLD --
1) the group "whatithink.users" needs to be created
3) Collection /db/xmlss/whatithink.com/users needs to be created, owned by "admin":"whatithink.users", permissions "rwurwur--"