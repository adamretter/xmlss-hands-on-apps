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

package com.whatithink.printer.model

import net.liftweb.mapper.LongKeyedMapper
import net.liftweb.mapper.By
import net.liftweb.mapper.IdPK
import net.liftweb.mapper.MappedString
import net.liftweb.mapper.MappedInt
import net.liftweb.mapper.LongKeyedMetaMapper

/**
 * @author Adam Retter <adam.retter@googlemail.com>
 */
class Customer extends LongKeyedMapper[Customer] with IdPK {
  
  def getSingleton = Customer
  
  object title extends MappedString(this, 4)
  
  object surname extends MappedString(this, 20) {
    override def dbIndexed_? = true
  }
  
  object forename extends MappedString(this, 20)
  object telephone extends MappedString(this, 15)
  object fax extends MappedString(this, 15)
  object email extends MappedString(this, 30)
  
  object building_number extends MappedInt(this)  
  object building_name extends MappedString(this, 30)
  object address_line_1 extends MappedString(this, 30)
  object address_line_2 extends MappedString(this, 30)
  object address_line_3 extends MappedString(this, 30)
  object postcode extends MappedString(this, 7)
  object country extends MappedString(this, 20)
  
  def orders(dispatched : Boolean) = Order.findAll(By(Order.customer, this.id), By(Order.dispatched, dispatched))
}

object Customer extends Customer with LongKeyedMetaMapper[Customer] {
  override def fieldOrder = List(title, forename, surname, telephone, fax, email,
                                 building_number, building_name, address_line_1,
                                 address_line_2, address_line_3, postcode, country)
}