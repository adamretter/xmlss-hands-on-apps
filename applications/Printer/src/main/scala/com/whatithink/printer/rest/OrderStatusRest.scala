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

import com.whatithink.printer.model.Item
import com.whatithink.printer.model.Order
import java.text.SimpleDateFormat
import java.util.Date
import net.liftweb.http.GetRequest
import net.liftweb.http.Req
import net.liftweb.http.S
import net.liftweb.http.rest.RestHelper
import net.liftweb.mapper.By
import net.liftweb.mapper.Descending
import net.liftweb.mapper.OrderBy
import java.util.GregorianCalendar
import javax.xml.datatype.DatatypeFactory

/**
 * @author Adam Retter <adam.retter@googlemail.com>
 */
object OrderStatusRest extends RestHelper {
  
  serve {
    //TODO come become case Req("order" :: "status" :: Nil, "xml", GetRequest) =>
    case Req("order" :: "status" :: Nil, _, GetRequest) =>
      for {
        requestId <- S.param("requestId") ?~ "requestId query string parameter missing" ~> 400
      } yield getStatus(requestId)
  }
  
  def getStatus(requestId : String)  =  
    <status xmlns="http://whatithink.com/printer/order/status">
      {
        val orders : List[Order] = Order.findAll(By(Order.request_id, requestId), OrderBy(Order.date_placed, Descending))
        orders.map(orderToXml)
      }
    </status>
  
  def orderToXml(order : Order) = {
      val item : Item = order.item.obj.open_!
      <order>
          <description>{item.description}</description>
          <quantity>{order.quantity}</quantity>
          <price>{item.price}</price>
          <date_placed>{toXmlDate(order.date_placed)}</date_placed>
          <dispatched>{order.dispatched}</dispatched>
      </order>
  }
  
  def toXmlDate(date : Date) = {
    val cal = new GregorianCalendar
    cal.setTime(date)
    val factory = DatatypeFactory.newInstance()
    val xmlCal = factory.newXMLGregorianCalendar(cal)
    
    xmlCal.toXMLFormat
  }
}