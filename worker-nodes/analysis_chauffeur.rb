# Abstract class to communicate the state of the analysis. Currently only the
# Mongo communicator has been implemented/tested

class AnalysisChauffeur
  attr_accessor :communicate_object

  def initialize(uuid_or_path, library_path = '/mnt/openstudio', rails_model_path = '/mnt/openstudio/rails-models', communicate_method = 'communicate_mongo')
    if communicate_method == 'communicate_mongo'
      require "#{library_path}/#{communicate_method}.rb"

      require 'mongoid'
      require 'mongoid_paperclip'
      require 'delayed_job_mongoid'
      Dir["#{rails_model_path}/*.rb"].each { |f| require f }
      Mongoid.load!("#{rails_model_path}/mongoid.yml", :development)
    elsif communicate_method == 'communicate_local'
      require 'rubygems' if RUBY_VERSION <= '1.8.7'
      require 'active_support/core_ext'

      if library_path.empty?
        # TODO: Make this the default and make communicate_mongo the first option after uuid_or_path
        # (Too high risk to do right now.)
        library_path = File.dirname(__FILE__)
      end
      require "#{library_path}/#{communicate_method}"
    else
      fail "No Communicate Module found for #{communicate_method} in #{__FILE__}"
    end

    # @communicate_model = communicate_method.camelcase(:upper).constantize
    # neither camelcase nor constantize work locally - looks like those are rails-isms
    @communicate_module = communicate_method.camelcase(:upper).constantize
    @time = Time.now # make this a module method

    @communicate_object = @communicate_module.get_datapoint(uuid_or_path)
  end

  def datapoint
    @communicate_object
  end

  def communicate_started
    # communicate_method.camelize.constantize
    @communicate_module.communicate_started(@communicate_object)
  end

  def log_message(log_message, delta = false)
    @communicate_module.communicate_log_message(@communicate_object, log_message, delta, @time)
    @time = Time.now
  end

  def get_problem(format = 'json')
    @communicate_module.get_problem(@communicate_object, format)
  end

  def communicate_intermediate_result(h)
    @communicate_module.communicate_intermediate_result(@communicate_object, h)
  end

  def communicate_results(os_data_point, os_directory)
    @communicate_module.communicate_results(@communicate_object, os_data_point, os_directory)
  end

  def communicate_results_json(eplus_json, analysis_dir)
    @communicate_module.communicate_results_json(@communicate_object, eplus_json, analysis_dir)
  end

  def communicate_complete
    @communicate_module.communicate_complete(@communicate_object)
  end

  # Final state of the simulation. The os_directory is the run directory and may be needed to
  # zip up the results of the simuation.
  def communicate_failure(os_directory)
    @communicate_module.communicate_failure(@communicate_object, os_directory)
  end

  def reload
    @communicate_module.reload(@communicate_object)
  end
end
