require 'rubygems'
require 'bundler/setup'

require 'active_record'
require 'grape'
require 'grape-entity'
require 'json'

ActiveRecord::Base.establish_connection(
  adapter:            'postgresql',
  host:               '',
  username:           '',
  password:           '',
  database:           'blotter',
  encoding:           'utf8',
  schema_search_path: 'blotter')


# ---------------------------------------------------------------------------------------------------------------------
# ACTIVERECORD MODEL DEFINITIONS
# ---------------------------------------------------------------------------------------------------------------------

class Charge < ActiveRecord::Base
  self.primary_key = 'incidentdescriptionid'
  self.table_name = 'incidentdescription'

  belongs_to :incident, :foreign_key => 'incidentid'

  def self.aggregate_over(start_date, start_time, end_date, end_time)
    joins(:incident).select('incidentdescription.description as description')
                    .select('COUNT(incidentdescription.incidentdescriptionid) as total')
                    .where('incident.incidentdate' => start_date .. end_date)
                    .where('incident.incidenttime' => start_time .. end_time)
                    .group('incidentdescription.description')
                    .order('total DESC')
  end
end

class Incident < ActiveRecord::Base
  self.primary_key = 'incidentid'
  self.table_name = 'incident'

  has_many :charges, :foreign_key => 'incidentid'

  def self.in_range(start_date, start_time, end_date, end_time)
    where(incidentdate: start_date .. end_date).where(incidenttime: start_time .. end_time).includes(:charges)
  end
end


# ---------------------------------------------------------------------------------------------------------------------
# GRAPE-ENTITY REPRESENTER DEFINITIONS
# ---------------------------------------------------------------------------------------------------------------------

class ChargeEntity < Grape::Entity
  expose :section
  expose :description
end  

class IncidentEntity < Grape::Entity
  format_with(:friendly_timestamp) { |dt| dt.strftime("%l:%M %P")}

  expose :incidenttype, as: :type
  expose :incidentdate, as: :date
  expose :incidenttime, as: :time, format_with: :friendly_timestamp
  expose :address
  expose :neighborhood
  expose :lat
  expose :lng
  expose :zone
  expose :age
  expose :gender
  expose :charges, with: ChargeEntity
end

class AggregateEntity < Grape::Entity
  expose :description
  expose :total
end


# ---------------------------------------------------------------------------------------------------------------------
# API DEFINITION
# ---------------------------------------------------------------------------------------------------------------------

module Blotter
  class API < Grape::API
    format :json

    get :incidents do
      present Incident.in_range(params[:startDate], params[:startTime], params[:endDate], params[:endTime]), 
        with: IncidentEntity
    end

    get :aggregates do
      present Charge.aggregate_over(params[:startDate], params[:startTime], params[:endDate], params[:endTime]), 
        with: AggregateEntity
    end
  end
end
