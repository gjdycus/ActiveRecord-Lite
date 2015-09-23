require_relative '02_searchable'
require 'active_support/inflector'

# Phase IIIa
class AssocOptions
  attr_accessor(
    :foreign_key,
    :class_name,
    :primary_key
  )

  ActiveSupport::Inflector.inflections do |inflect|
    inflect.irregular 'human', 'humans'
  end

  def model_class
    self.class_name.constantize
  end

  def table_name
    self.class_name.underscore.pluralize
  end
end

class BelongsToOptions < AssocOptions
  def initialize(name, options = {})
    @foreign_key = options[:foreign_key] || "#{name}_id".to_sym
    @primary_key = options[:primary_key] || :id
    @class_name = options[:class_name] || name.to_s.camelcase
  end
end

class HasManyOptions < AssocOptions
  def initialize(name, self_class_name, options = {})
    @foreign_key = options[:foreign_key] || "#{self_class_name.underscore}_id".to_sym
    @primary_key = options[:primary_key] || :id
    @class_name = options[:class_name] || name.to_s.singularize.camelcase
  end
end

module Associatable
  # Phase IIIb
  def belongs_to(name, options = {})
    @assoc_options = { name => BelongsToOptions.new(name, options) }

    define_method(name) do
      foreign_key_val = self.send(self.class.assoc_options[name].foreign_key)
      self.class.assoc_options[name].model_class.where({ self.class.assoc_options[name].primary_key => foreign_key_val }).first
    end
  end

  def has_many(name, options = {})
    options = HasManyOptions.new(name, self.to_s, options)

    define_method(name) do
      primary_key_val = self.send(options.primary_key)
      options.model_class.where({ options.foreign_key => primary_key_val })
    end
  end

  def assoc_options
    @assoc_options ||= {}
  end
end

class SQLObject
  extend Associatable
end
