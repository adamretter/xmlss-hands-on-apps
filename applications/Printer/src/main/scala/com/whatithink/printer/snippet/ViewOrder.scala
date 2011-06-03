/**
 * Copyright 2011 Adam Retter
 * adam.retter@googlemail.com
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

package com.whatithink.printer.snippet

import net.liftweb._
import com.whatithink.printer.model.Order
import http._
import net.liftweb.http.js.JsCmd
import net.liftweb.http.js.JsCmds
import net.liftweb.mapper.By
import net.liftweb.util.CssSel
import scala.xml.NodeSeq
import scala.xml.Text
import util.Helpers._

/**
 * @author Adam Retter <adam.retter@googlemail.com>
 */
object ViewOrder extends OrderListTrait {
  
  def render =  {
  
    //state
    val viewId = S.param("id").toList
    
    def processDispatchOrderLink : JsCmd = {

      if(viewId.size == 0 || viewId(0).length == 0) {

        //no order id so redirect to root
        JsCmds.RedirectTo("/")

      } else {

        //find the order for the id
        val orders = Order.findByKey(viewId(0).toLong)
        orders.foreach(markOrderDispatched)

        JsCmds.Alert("Order has been dispatched") &
        JsCmds.RedirectTo("/order/" + viewId(0))
      }
    }
    
    def renderOrderNumber(order: Order) = "#orderNumber *" #> order.id.is
    def renderOrderPrice(order: Order) = "#orderPrice *" #> order.item.obj.open_!.price.is.toString
    def renderOrderQuantity(order: Order) = "#orderQuantity *" #> order.quantity.is
    def renderOrderDispatched(order: Order) = "#orderDispatched *" #> order.dispatched.is.toString
  
    def renderDispatchLink(order : Order) : CssSel = {
      if(!order.dispatched.is)
        ".dispatchLink" #> SHtml.a(processDispatchOrderLink _, Text("Dispatch Order"))
      else
        ".dispatchLink" #> NodeSeq.Empty
    }
    
    if(viewId.size == 0 || viewId(0).length == 0) {
      //no order id so redirect to root
      S.redirectTo("/")
    } else {
    
      //find the order for the id
      val orders = Order.findAll(By(Order.id, viewId(0).toLong))
      
      //check if we found an order
      if(orders.toList.size != 1)
        S.redirectTo("/") //no orders found
      else
        renderOrderList(orders, renderDispatchLink, renderOrderNumber, renderOrderPrice, renderOrderQuantity, renderOrderDispatched)
    }
  }
  
  def markOrderDispatched(order : Order) = {
        order.dispatched(true)
        order.save
  }
}