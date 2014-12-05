require 'sinatra'
require 'sinatra/activerecord'
require 'json'

ActiveRecord::Base.establish_connection(
  adapter:            'postgresql',
  host:               '',
  username:           '',
  password:           '',
  database:           'blotter',
  encoding:           'utf8',
  schema_search_path: 'blotter')


class Incident < ActiveRecord::Base
  self.primary_key = 'incidentid'
  self.table_name = 'incident'

  has_many :incident_descriptions, :foreign_key => 'incidentid'
end

class IncidentDescription < ActiveRecord::Base
  self.primary_key = 'incidentdescriptionid'
  self.table_name = 'incidentdescription'

  belongs_to :incident, :foreign_key => 'incidentid'
end


get '/' do
  redirect '/index.html'
end

get '/incidents' do
  content_type :json
  incident_search = Incident.where(incidentdate: params[:startDate] .. params[:endDate])
                            .where(incidenttime: params[:startTime] .. params[:endTime])
                            .includes(:incident_descriptions)
  incidents = incident_search.map do | incident |    
    {
      type:         incident.incidenttype,
      date:         incident.incidentdate,
      time:         incident.incidenttime,
      address:      incident.address,
      neighborhood: incident.neighborhood,
      lat:          incident.lat,
      lng:          incident.lng,
      zone:         incident.zone,
      age:          incident.age,
      gender:       incident.gender,
      charges:      incident.incident_descriptions.map { | charge | 
        { section: charge.section, description: charge.description } }
    }
  end

  incidents.to_json
end

get '/aggregate' do
  content_type :json
  aggregate_search = IncidentDescription.joins(:incident)
                                        .select('incidentdescription.description as description')
                                        .select('COUNT(incidentdescription.incidentdescriptionid) as total')
                                        .where('incident.incidentdate' => params[:startDate] .. params[:endDate])
                                        .where('incident.incidenttime' => params[:startTime] .. params[:endTime])
                                        .group('incidentdescription.description')
                                        .order('total DESC')
  aggregates = aggregate_search.map do | aggregate |
    { description: aggregate[:description], total: aggregate[:total] }
  end

  aggregates.to_json
end
