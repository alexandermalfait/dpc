# To change this template, choose Tools | Templates
# and open the template in the editor.

class Icons
  def self.edit
    icon_url "page_white_edit"
  end

  def self.delete
    icon_url "page_white_delete"
  end

  def self.create
    icon_url "page_white_add"
  end

  def self.create_many
    icon_url "table_add"
  end

  def self.add
    icon_url "add"
  end

  def self.save
    icon_url "page_white_go"
  end

  def self.information
    icon_url "information"
  end

  def self.history
    icon_url "calendar_edit"
  end

  def self.back
    icon_url "arrow_left"
  end

  def self.go
    icon_url "application_go"
  end

  def self.no_access
    icon_url "stop"
  end

  def self.phone
    icon_url "telephone"
  end

  def self.email
    icon_url "email"
  end

  def self.follow_link
    icon_url "world_go"
  end

  def self.print
    icon_url "printer"
  end

  def self.excel
    icon_url "page_excel"
  end

  def self.search
    icon_url "zoom"
  end

  def self.big_help
    "/images/big_help.gif"
  end


  def self.icon_url(icon)
    "/images/icons/#{icon}.png"
  end
end
