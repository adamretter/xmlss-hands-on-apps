/**
 * Copyright 2011 Adam Retter
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

package com.whatithink.printer.rest

import com.whatithink.printer.model.Customer
import com.whatithink.printer.model.Item
import com.whatithink.printer.model.Order
import javax.xml.datatype.DatatypeFactory
import net.liftweb.http.BadResponse
import net.liftweb.http.InternalServerErrorResponse
import net.liftweb.http.ResponseWithReason
import net.liftweb.http.rest.RestHelper
import net.liftweb.mapper.KeyedMapper
import scala.xml.NodeSeq

/**
 * @author Adam Retter <adam.retter@googlemail.com>
 */
object OrderRest extends RestHelper { 
  
  val ORDER_NS = "http://whatithink.com/order"
  
  serve {
    //case Req("order" :: _, "xml", PostRequest) => <b>Static</b> 
    case XmlPost("order" :: Nil, (body, request)) => {
        
      //validate body xml if invalid return - BadResponse()

      val customerXml = body \ on("Customer")
      if(customerXml.isEmpty) {
        //Error
        ResponseWithReason(BadResponse(), "Could not extract Customer Element from Request")
      } else {

        val itemXml = body \ on("Item")
        if(itemXml.isEmpty) {
          ResponseWithReason(BadResponse(), "Could not extract Item Element from Request")
        } else {

          //create the objects
          val customer = createCustomer(customerXml)
          if(customer.isEmpty) {
              ResponseWithReason(InternalServerErrorResponse(), "Could not Create Customer entity")
          } else {

            val item = createItem(itemXml)
            if(item.isEmpty) {
              rollback(customer, item)
              ResponseWithReason(InternalServerErrorResponse(), "Could not Create Item entity")
            } else {

              val order = createOrder(body, customer.get, item.get)
              if(order.isEmpty) {
                rollback(order, item, customer)
                ResponseWithReason(InternalServerErrorResponse(), "Could not Create Order entity")
              } else {
                <order xmlns="http://whatithink.com/order"><id>{order.get.id.is}</id></order>
              }
            }
          }
        }
      }
    }
  }
  
  def rollback(mappers : Option[KeyedMapper[_, _]]*) = {
    mappers.filter(_.nonEmpty).filter(_.get.saved_?).foreach(_.get.delete_!)
  }
  
  /* create a node name for an order node **/
  //def on(localName : String) = "{" + ORDER_NS + "}" + localName
  def on(localName : String) = localName
  
  def xmlDateTimeToJavaDate(dateTime : String) : java.util.Date = DatatypeFactory.newInstance.newXMLGregorianCalendar(dateTime).toGregorianCalendar.getTime
  
  def createOrder(bodyXml : NodeSeq, customer : Customer, item : Item) : Option[Order] = {
    val order = Order.create
    
    order.customer(customer)
    order.item(item)
    
    order.request_id(bodyXml \ on("RequestId") text)
    order.quantity((bodyXml \ on("Quantity")).text.toInt)
    order.date_placed(xmlDateTimeToJavaDate(bodyXml \ on("DatePlaced") text))
    order.payment_method(bodyXml \ on("PaymentMethod") text)
    
    if(order.save)
      Some(order)
    else
      None
  }
  
  def createItem(itemXml : NodeSeq) : Option[Item] = {
    val item = Item.create
   
    item.description(itemXml \ on("Description") text) 
    item.price((itemXml \ on("Price")).text.toDouble)
    item.content(itemXml \ on("Content") toString)
    
    if(item.save)
      Some(item)
    else
      None
  }
  
  def createCustomer(customerXml : NodeSeq) : Option[Customer] = {
    val customer = Customer.create
    
    val contactXml = customerXml \ on("Contact")  
    customer.title(contactXml \ on("Title") text)
    customer.surname(contactXml \ on("Surname") text)
    customer.forename(contactXml \ on("Forename") text)
    (contactXml \ on("Telephone")).filter(_.text.nonEmpty).foreach(telephone => customer.telephone(telephone text)) //value is optional/nullable
    (contactXml \ on("Fax")).filter(_.text.nonEmpty).foreach(fax => customer.fax(fax text)) //value is optional/nullable
    customer.email(contactXml \ on("Email") text)
      
    val addressXml = customerXml \ on("Address")
    (addressXml \ on("BuildingNumber")).filter(_.text.nonEmpty).foreach(buildingNumber => customer.building_number(buildingNumber.text.toInt)) //value is optional/nullable
    (addressXml \ on("BuildingName")).filter(_.text.nonEmpty).foreach(buildingName => customer.building_name(buildingName text)) //value is optional/nullable
    
    val addressLinesXml = addressXml \ on("AddressLine")
    if(addressLinesXml.size >= 1 && !addressLinesXml(0).text.isEmpty) {
      customer.address_line_1(addressLinesXml(0) text)
    }
    if(addressLinesXml.size >= 2 && !addressLinesXml(1).text.isEmpty) {
      customer.address_line_2(addressLinesXml(1) text)
    }
    if(addressLinesXml.size >= 3 && !addressLinesXml(2).text.isEmpty) {
      customer.address_line_3(addressLinesXml(2) text)
    }
    customer.postcode(addressXml \ on("Postcode") text)
    (addressXml \ on("Country")).filter(_.text.nonEmpty).foreach(country => customer.country(country text)) //value is optional/nullable
    
    if(customer.save)
      Some(customer)
    else
      None
  }
}