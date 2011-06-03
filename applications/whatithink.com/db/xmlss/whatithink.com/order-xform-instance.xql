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
                    for $entry in mylist:get-entries() return
                        $entry
                }
            </feed>
        </Content>
    </Item>
    
</Order>