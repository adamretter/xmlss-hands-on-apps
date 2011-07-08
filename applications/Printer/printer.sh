#!/bin/bash

mvn -f `dirname $0`/pom.xml jetty:run
