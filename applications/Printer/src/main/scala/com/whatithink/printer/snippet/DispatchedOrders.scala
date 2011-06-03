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

import com.whatithink.printer.model.Order
import net.liftweb.http.S
import net.liftweb.mapper.By
import net.liftweb.mapper.Descending
import net.liftweb.mapper.MaxRows
import net.liftweb.mapper.OrderBy

import net.liftweb._
import common._
import util.Helpers._

/**
 * @author Adam Retter <adam.retter@googlemail.com>
 */
class DispatchedOrders extends OrderListTrait {
  
  def render = {
    
    val orders : List[Order] = if(S.param("max").isEmpty) {
      Order.findAll(By(Order.dispatched, true), OrderBy(Order.date_placed, Descending))
    } else {
      Order.findAll(By(Order.dispatched, true), OrderBy(Order.date_placed, Descending), MaxRows(S.param("max").get.toInt))
    }
    
    renderOrderList(orders)
  }
}