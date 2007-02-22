module Goldberg
  class RolesPermission < ActiveRecord::Base
    include GoldbergModel
    
    def RolesPermission.find_for_role(role_ids)
      return find_by_sql([%q{
select rp.*, p.name 
from #{prefix}roles_permissions rp inner join #{prefix}permissions p 
  on rp.permission_id = p.id 
where role_id in (?) order by p.name
}, role_ids])
    end
    
  end
end
