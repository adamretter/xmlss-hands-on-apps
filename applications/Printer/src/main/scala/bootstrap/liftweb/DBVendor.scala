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

import net.liftweb.common.Full
import net.liftweb.mapper.{ConnectionIdentifier, ConnectionManager}
import com.mchange.v2.c3p0.ComboPooledDataSource
import java.sql.Connection

/**
 * @author Adam Retter <adam.retter@googlemail.com>
 */
object DBVendor extends ConnectionManager {
  
  def newConnection(name : ConnectionIdentifier) = {
    Full(connectionPool.getConnection)
  }
  
  def releaseConnection (conn : Connection) = { 
    conn.close
  }
  
  private lazy val connectionPool = {
    val cpds = new ComboPooledDataSource()
    cpds.setDriverClass("com.mysql.jdbc.Driver") //loads the jdbc driver
    cpds.setJdbcUrl("jdbc:mysql://localhost:3306/xmlss_printer")
    cpds.setUser("root")
    cpds.setPassword("")

    // the settings below are optional -- c3p0 can work with defaults
    cpds.setMinPoolSize(5)
    cpds.setAcquireIncrement(5)
    cpds.setMaxPoolSize(20)

    cpds
  }
  
  def cleanup() = {
    connectionPool.close
  }
}