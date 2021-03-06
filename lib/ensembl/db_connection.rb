require 'rubygems'
require 'activerecord'

module Ensembl
  DB_ADAPTER = 'mysql'
  DB_HOST = 'ensembldb.ensembl.org'
  DB_USERNAME = 'anonymous'
  DB_PASSWORD = ''

  class OldDummyDBConnection < ActiveRecord::Base
    self.abstract_class = true
    
    establish_connection(
                        :adapter => Ensembl::DB_ADAPTER,
                        :host => Ensembl::DB_HOST,
                        :database => '',
                        :username => Ensembl::DB_USERNAME,
                        :password => Ensembl::DB_PASSWORD
                        )
  end

  class NewDummyDBConnection < ActiveRecord::Base
    self.abstract_class = true
    
    establish_connection(
                        :adapter => Ensembl::DB_ADAPTER,
                        :host => Ensembl::DB_HOST,
                        :database => '',
                        :username => Ensembl::DB_USERNAME,
                        :password => Ensembl::DB_PASSWORD,
                        :port => 5306
                        )
  end

  
  module Core
    # = DESCRIPTION
    # The Ensembl::Core::DBConnection is the actual connection established
    # with the Ensembl server.
    class DBConnection < ActiveRecord::Base
      self.abstract_class = true
      self.pluralize_table_names = false

      # = DESCRIPTION
      # The Ensembl::Core::DBConnection#connect method makes the connection
      # to the Ensembl core database for a given species. By default, it connects
      # to release 50 for that species. You _could_ use a lower number, but
      # some parts of the API might not work, or worse: give the wrong results.
      #
      # = USAGE
      #  # Connect to release 50 of human
      #  Ensembl::Core::DBConnection.connect('homo_sapiens')
      #
      #  # Connect to release 42 of chicken
      #  Ensembl::Core::DBConnection.connect('gallus_gallus')
      #
      # ---
      # *Arguments*:
      # * species:: species to connect to. Arguments should be in snake_case
      # * ensembl_release:: the release of the database to connect to
      #  (default = 50)
      def self.connect(species, release = Ensembl::ENSEMBL_RELEASE, args = {})
        dummy_dbconnection = ( release > 47 ) ? Ensembl::NewDummyDBConnection.connection : Ensembl::OldDummyDBConnection.connection
        db_name = nil
        
        if args[:database]
          db_name = args[:database]
        else  
          db_name = dummy_dbconnection.select_values('show databases').select{|v| v =~ /#{species}_core_#{release.to_s}/}[0]
        end

        if db_name.nil?
          warn "WARNING: No connection to database established. Check that the species is in snake_case (was: #{species})."
        else
          port = ( release > 47 ) ? 5306 : nil
          establish_connection(
                              :adapter => args[:adapter] || Ensembl::DB_ADAPTER,
                              :host => args[:host] || Ensembl::DB_HOST,
                              :database => args[:database] || db_name,
                              :username => args[:username] || Ensembl::DB_USERNAME,
                              :password => args[:password] || Ensembl::DB_PASSWORD,
                              :port => args[:port] || port
                            ) 
          self.retrieve_connection
          Ensembl::SESSION.seqlevel_id = Ensembl::Core::CoordSystem.find_seqlevel.id
          Ensembl::SESSION.toplevel_id = Ensembl::Core::CoordSystem.find_toplevel.id
        end
        
      end

    end

  end

  module Variation
    # = DESCRIPTION
    # The Ensembl::Variation::DBConnection is the actual connection established
    # with the Ensembl server.
    class DBConnection < ActiveRecord::Base
      self.abstract_class = true
      self.pluralize_table_names = false

      # = DESCRIPTION
      # The Ensembl::Variation::DBConnection#connect method makes the connection
      # to the Ensembl variation database for a given species. By default, it connects
      # to release 50 for that species. You _could_ use a lower number, but
      # some parts of the API might not work, or worse: give the wrong results.
      #
      # = USAGE
      #  # Connect to release 50 of human
      #  Ensembl::Variation::DBConnection.connect('homo_sapiens')
      #
      #  # Connect to release 42 of chicken
      #  Ensembl::Variation::DBConnection.connect('gallus_gallus')
      #
      # ---
      # *Arguments*:
      # * species:: species to connect to. Arguments should be in snake_case
      # * ensembl_release:: the release of the database to connect to
      #  (default = 50)
      def self.connect(species, release = Ensembl::ENSEMBL_RELEASE, args = {})
        dummy_dbconnection = ( release > 47 ) ? Ensembl::NewDummyDBConnection.connection : Ensembl::OldDummyDBConnection.connection
        db_name = nil
        if args[:database]
          db_name = args[:database]
        else  
          db_name = dummy_dbconnection.select_values('show databases').select{|v| v =~ /#{species}_variation_#{release.to_s}/}[0]
        end
        
        if db_name.nil?
          warn "WARNING: No connection to database established. Check that the species is in snake_case (was: #{species})."
        else
          port = ( release > 47 ) ? 5306 : nil
          establish_connection(
                              :adapter => Ensembl::DB_ADAPTER,
                              :host => args[:host] || Ensembl::DB_HOST,
                              :database => db_name,
                              :username => args[:username] || Ensembl::DB_USERNAME,
                              :password => args[:password] || Ensembl::DB_PASSWORD,
                              :port => args[:port] || port
                            )
          self.retrieve_connection                                                                                                                             
        end
        
      end

    end

  end
end
