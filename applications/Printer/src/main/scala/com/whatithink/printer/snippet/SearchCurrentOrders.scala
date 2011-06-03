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

package com.whatithink.printer.snippet

import net.liftweb._
import com.whatithink.printer.model.Customer
import com.whatithink.printer.model.Order
import http._
import net.liftweb.mapper.By
import net.liftweb.mapper.ByList
import net.liftweb.mapper.Descending
import net.liftweb.mapper.MaxRows
import net.liftweb.mapper.OrderBy
import util.Helpers._

/**
 * @author Adam Retter <adam.retter@googlemail.com>
 */
object SearchCurrentOrders extends OrderListTrait {
 
  def render =  {
  
    val surnameParamValues = S.param("surname").toList
    
    val orders = if(surnameParamValues.size == 0 || surnameParamValues(0).length == 0) {
      Order.findAll(By(Order.dispatched, false), OrderBy(Order.date_placed, Descending), MaxRows(20))
    } else {
      Customer.findAll(ByList(Customer.surname, surnameParamValues)).flatMap(customer => customer.orders(false))
    }
    
    "#searchTerms *" #> surnameParamValues &
    "#resultsCount *" #> orders.size.toString &
    renderOrderList(orders)
  }
}