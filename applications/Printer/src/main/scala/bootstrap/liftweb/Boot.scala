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

package bootstrap.liftweb

import net.liftweb.util._
import com.whatithink.printer.rest.OrderRest
import com.whatithink.printer.rest.OrderStatusRest
import net.liftweb.common.Full
import net.liftweb.db.DefaultConnectionIdentifier
import net.liftweb.http._
import net.liftweb.sitemap._
import net.liftweb.mapper.DB
import net.liftweb.sitemap.Loc._
import Helpers._
 
/**
 * @author Adam Retter <adam.retter@googlemail.com>
 */
class Boot {
  def boot {
    
    // where to search snippet
    LiftRules.addToPackages("com.whatithink.printer")     

    
    // Build SiteMap
    def sitemap(): SiteMap = SiteMap(
      Menu.i("Home") / "index",
      Menu.i("Dispatched Orders") / "dispatched_orders" >> Hidden,
      Menu.i("Current Orders") / "current_orders" >> Hidden,
      Menu.i("Search Current Orders") / "search_orders" >> Hidden,
      Menu.i("Review Order") / "view" >> Hidden,
      
      Menu.i("CSS") / "css" / ** >> Hidden,
      Menu.i("Images") / "images" / ** >> Hidden
    )
    
    //URI rewrite rules
    LiftRules.rewrite.append {
     
      //rewrite /index onto /dispatched_orders
      case RewriteRequest(
          ParsePath("index" :: Nil, _, _, _), _, _
      ) => RewriteResponse("dispatched_orders" :: Nil, Map("max" -> "20"))
      
      // rewrite the uri /order/{id} onto /view
      case RewriteRequest(
          ParsePath("order" :: AsLong(id) :: Nil, _, _, _), _, _            //AsLong ensures that the parameter is a Long
      ) => RewriteResponse("view" :: Nil, Map("id" -> id.toString))
      
      // rewrite the URI /order/search onto /search_orders
      case RewriteRequest(
          ParsePath("order" :: "search" :: Nil, _, _, _), _, _
      ) => RewriteResponse("search_orders" :: Nil, Map.empty[String, String])
      
      // rewrite the URI /order/list/current onto /view_orders
      case RewriteRequest(
          ParsePath("order" :: "list" :: "current" :: Nil, _, _, _), _, _
      ) => RewriteResponse("current_orders" :: Nil, Map.empty[String, String])
      
      // rewrite the URI /order/list/dispatched onto /dispatched_orders
      case RewriteRequest(
          ParsePath("order" :: "list" :: "dispatched" :: Nil, _, _, _), _, _
      ) => RewriteResponse("dispatched_orders" :: Nil, Map.empty[String, String])
    }
    
    //REST Web Services
    LiftRules.statelessDispatchTable.append(OrderRest) // stateless — no session created
    LiftRules.statelessDispatchTable.append(OrderStatusRest) // stateless — no session created
    
    LiftRules.setSiteMapFunc(() => sitemap())
    
    DB.defineConnectionManager(DefaultConnectionIdentifier, DBVendor)
    
    LiftRules.unloadHooks.append(DBVendor.cleanup)
    
    //disabled as we are aiming for XHTML 1.1
    //LiftRules.xhtmlValidator = Full(StrictXHTML1_0Validator)
  }
}