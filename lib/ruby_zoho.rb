require 'zoho_api'
require 'api_utils'


module RubyZoho

  class Configuration
    attr_accessor :api, :api_key

    def initialize
      self.api_key = nil
      self.api = nil
    end
  end

  class << self
    attr_accessor :configuration
  end

  def self.configure
    self.configuration ||= Configuration.new
    yield(configuration) if block_given?
    self.configuration.api = ZohoApi::Crm.new(self.configuration.api_key)
  end


  module Crm

    def attr_writers
      self.methods.grep(/\w=$/)
    end

    def self.create_accessor(klass, names)
      names.each do |name|
        n = name
        n = name.to_s if name.class == Symbol
        create_getter(klass, n)
        create_setter(klass, n)
      end
      names
    end

    def self.create_getter(klass, *names)
      names.each do |name|
        klass.send(:define_method, "#{name}") { instance_variable_get("@#{name}") }
      end
    end

    def self.create_setter(klass, *names)
      names.each do |name|
        klass.send(:define_method, "#{name}=") { |val| instance_variable_set("@#{name}", val) }
      end
    end

    def create(object_attribute_hash)
      initialize(object_attribute_hash)
      save
    end

    def save
      h = {}
      @fields.each { |f| h.merge!({ f => eval("self.#{f.to_s}") }) }
      RubyZoho.configuration.api.add_record(@module_name, h)
    end


    class Account
      include RubyZoho::Crm

      attr_reader :fields

      def initialize(object_attribute_hash = {})
        @module_name = 'Accounts'
        @fields = RubyZoho.configuration.api.module_fields[:accounts]
        RubyZoho::Crm.create_accessor(RubyZoho::Crm::Account, @fields)
        object_attribute_hash.map { |(k, v)| public_send("#{k}=", v) }
      end
    end


    class Contact
      include RubyZoho::Crm

      attr_reader :fields

      def initialize(object_attribute_hash = {})
        @module_name = 'Contacts'
        @fields = RubyZoho.configuration.api.module_fields[
            ApiUtils.string_to_symbol(@module_name)]
        RubyZoho::Crm.create_accessor(RubyZoho::Crm::Contact, @fields)
        object_attribute_hash.map { |(k, v)| public_send("#{k}=", v) }
      end

      def self.all         #TODO Refactor into low level API
        result = []
        i = 1
        begin
          batch = RubyZoho.configuration.api.some('Contacts', i, 2)
          i += 2
          result.concat(batch) unless batch.nil?
        end while !batch.nil?
        result.collect { |r| new(r) }
      end

      def self.delete(id)
        RubyZoho.configuration.api.delete_record('Contacts', id)
      end

      def self.method_missing(meth, *args, &block)
        if meth.to_s =~ /^find_by_(.+)$/
          run_find_by_method($1, *args, &block)
        else
          super
        end
      end

      def self.run_find_by_method(attrs, *args, &block)
        attrs = attrs.split('_and_')
        conditions = Array.new(args.size, '=')
        h = RubyZoho.configuration.api.find_records(
            'Contacts', ApiUtils.string_to_symbol(attrs[0]), conditions[0], args[0]
        )
        return h.collect { |r| new(r) } unless h.nil?
        nil
      end
    end


    class Lead
      include RubyZoho::Crm

      attr_reader :fields

      def initialize(object_attribute_hash = {})
        @module_name = 'Leads'
        @fields = RubyZoho.configuration.api.module_fields[:leads]
        RubyZoho::Crm.create_accessor(RubyZoho::Crm::Lead, @fields)
        object_attribute_hash.map { |(k, v)| public_send("#{k}=", v) }
      end
    end

    class Potential
      include RubyZoho::Crm

      attr_reader :fields

      def initialize(object_attribute_hash = {})
        @module_name = 'Potentials'
        @fields = RubyZoho.configuration.api.module_fields[:potentials]
        RubyZoho::Crm.create_accessor(RubyZoho::Crm::Potential, @fields)
        object_attribute_hash.map { |(k, v)| public_send("#{k}=", v) }
      end
    end

    class Quote
      include RubyZoho::Crm

      attr_reader :fields

      def initialize(object_attribute_hash = {})
        @module_name = 'Quotes'
        @fields = RubyZoho.configuration.api.module_fields[:quotes]
        RubyZoho::Crm.create_accessor(RubyZoho::Crm::Quote, @fields)
        object_attribute_hash.map { |(k, v)| public_send("#{k}=", v) }
      end
    end

  end

end
