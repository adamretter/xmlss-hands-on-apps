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

import net.liftweb.common.Box
import net.liftweb.http.rest.RestHelper
import net.liftweb.mapper.IdPK
import net.liftweb.mapper.LongKeyedMapper
import net.liftweb.mapper.MappedLongForeignKey
import net.liftweb.mapper.MappedString
import net.liftweb.mapper.MappedInt
import net.liftweb.mapper.LongKeyedMetaMapper
import net.liftweb.mapper.MappedDateTime
import net.liftweb.mapper.MappedBoolean

/**
 * @author Adam Retter <adam.retter@googlemail.com>
 */
class Order extends LongKeyedMapper[Order] with IdPK with RestHelper {
  def getSingleton = Order
  
  object customer extends MappedLongForeignKey(this, Customer) {
    override def dbColumnName = "customer_id"
  }
  object item extends MappedLongForeignKey(this, Item) {
    override def dbColumnName = "item_id"
  }
  object request_id extends MappedString(this, 15)
  object quantity extends MappedInt(this)
  object date_placed extends MappedDateTime(this)
  object payment_method extends MappedString(this, 20)
  object dispatched extends MappedBoolean(this)
}

object Order extends Order with LongKeyedMetaMapper[Order] /* with CRUDify[Long, Order] */ {
  override def fieldOrder = List(customer, item, request_id, quantity, date_placed, payment_method, dispatched)
}
