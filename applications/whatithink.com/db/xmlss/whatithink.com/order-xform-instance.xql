(:
 Copyright 2011 Adam Retter

 Licensed under the Apache License, Version 2.0 (the "License");
 you may not use this file except in compliance with the License.
 You may obtain a copy of the License at

     http://www.apache.org/licenses/LICENSE-2.0

 Unless required by applicable law or agreed to in writing, software
 distributed under the License is distributed on an "AS IS" BASIS,
 WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 See the License for the specific language governing permissions and
 limitations under the License.
:)

(:~
: This module generates an XForms instance for the place order XForm
: It is this completed instance which can be sent to the Printers
: RESTful web service.
:
: @author Adam Retter <adam.retter@googlemail.com>
: @version 201109122029
:)
xquery version "1.0";

declare namespace atom = "http://www.w3.org/2005/Atom";
declare namespace exist = "http://exist.sourceforge.net/NS/exist";
declare namespace xf = "http://www.w3.org/2002/xforms";
declare namespace xh = "http://www.w3.org/1999/xhtml";
declare namespace order = "http://whatithink.com/order";

import module namespace util = "http://exist-db.org/xquery/util";

import module namespace entry = "http://whatithink.com/xquery/entry" at "entry.xqm";
import module namespace mylist = "http://whatithink.com/xquery/mylist" at "mylist.xqm";
import module namespace security = "http://whatithink.com/xquery/security" at "security.xqm";

<Order xmlns="http://whatithink.com/order">
    
    <RequestId>{security:get-username()}</RequestId>
    <Quantity>1</Quantity>
    <DatePlaced>someDate</DatePlaced>
    <PaymentMethod>Credit Card</PaymentMethod>
    
    <Customer>
        <Contact>
            <Title/>
            <Surname/>
            <Forename/>
            <Telephone/>
            <Fax/>
            <Email/>
        </Contact>
        <Address>
            <BuildingNumber/>
            <BuildingName/>
            <AddressLine/>
            <AddressLine/>
            <AddressLine/>
            <Postcode/>
            <Country/>
        </Address>
    </Customer>
    
    <Item> 
        <Description/>
        <Price>10.00</Price>
        
        <Content>
            <feed xmlns="http://www.w3.org/2005/Atom">
                <title>What I Think</title>
                <link href="http://whatithink.com/"/>
                <updated>{current-dateTime()}</updated>
                <author>
                    <name>{security:get-username()}</name>
                </author>
                <id>{fn:concat("urn:uuid:", util:uuid())}</id>
                {
                    (: add the currently logged in users
                    list of atom entries to the order :)
                    for $entry in mylist:get-entries() return
                        $entry
                }
            </feed>
        </Content>
    </Item>
    
</Order>