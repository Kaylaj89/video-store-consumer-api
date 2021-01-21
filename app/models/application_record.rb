class ApplicationRecord < ActiveRecord::Base
  self.abstract_class = true
  
  def self.parameterized_list(sort = "id", n = 10, p = 1)
    return self.all.order(sort).paginate(page: p, per_page: n)
  end
end
