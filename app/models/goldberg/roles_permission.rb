module Goldberg
  class RolesPermission < ActiveRecord::Base
    include Goldberg::Model

    validates_presence_of :role_id, :permission_id
    
    def RolesPermission.find_for_role(role_ids)
      querystr = <<-END
select rp.*, p.name 
from #{prefix}roles_permissions rp inner join #{prefix}permissions p 
  on rp.permission_id = p.id 
where role_id in (?) order by p.name
END
      return find_by_sql([querystr, role_ids])
    end
    
  end
end
