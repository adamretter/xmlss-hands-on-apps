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
import com.whatithink.printer.model.Order
import http._
import net.liftweb.util.CssSel
import util.Helpers._

/**
 * @author Adam Retter <adam.retter@googlemail.com>
 */
trait OrderListTrait {
  
  /**
   * @param orders The orders to render output for
   * @param fx Optional functions which render output for each order
   */
  def renderOrderList(orders : List[Order], fx : Order => CssSel*) = {
    "li *" #> orders.map(order => (
    
        "h4 *" #> order.customer.obj.map(customer => {
            customer.title.is + " " + customer.forename.is + " " + customer.surname.is}
        ) &
        
        
        //execute each optional function
        fx.map(f => f(order)).reduceLeftOption( _ & _ ).getOrElse("unknown" #> "unknown") &
      
        ".viewLink [href]" #> ("/order/" + order.id.is) &
        ".orderDescription *" #> order.item.obj.map(item => item.description.is) &
        "address *" #> order.customer.map(customer => {
          <span>{customer.building_name.is}</span> +:
          <span>{customer.building_number.is} {customer.address_line_1.is}</span> +:
          <span>{customer.address_line_2.is}</span> +:
          <span>{customer.address_line_3.is}</span> +:
          <span>{customer.postcode.is}</span> +:
          <span>{customer.country.is}</span>
        })
    ))
  }
 
}