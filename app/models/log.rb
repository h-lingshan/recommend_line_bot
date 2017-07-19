class Log < ActiveRecord::Base
  self.inheritance_column = :_type_disabled # この行を追加
end
