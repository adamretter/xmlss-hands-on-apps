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

import java.math.MathContext
import net.liftweb.mapper.IdPK
import net.liftweb.mapper.LongKeyedMapper
import net.liftweb.mapper.MappedString
import net.liftweb.mapper.LongKeyedMetaMapper
import net.liftweb.mapper.MappedDecimal
import net.liftweb.mapper.MappedText

/**
 * @author Adam Retter <adam.retter@googlemail.com>
 */
class Item extends LongKeyedMapper[Item] with IdPK {
  
  def getSingleton = Item
  
  object description extends MappedString(this, 80)
  object price extends MappedDecimal(this, MathContext.DECIMAL64, 2)
  object content extends MappedText(this)
}

object Item extends Item with LongKeyedMetaMapper[Item] {
  override def fieldOrder = List(description, price, content)
}