require 'sinatra'
require 'rest-client'
require 'json'
require 'redcarpet'

# Index

get '/' do
  IndexHtml ||= html_for_index
end

def html_for_index
  @apps = library_apps
  html_for :index
end

# Enerteq MVX pages

get '/integration' do
  MeteringAndDataCaptureHtml ||= html_for :integration
end

get '/nodes' do
  SiteControlAndGatewayHtml ||= html_for :nodes
end

get '/apps' do
  AnalysisAndReportingHtml ||= html_for :apps
end

get '/support' do
  ServiceAndSupportHtml ||= html_for :support
end

# Company pages

get '/about' do
  AboutHtml ||= html_for :about
end

get '/contact' do
  ContactHtml ||= html_for :contact
end



# App library


def apps_json
  begin
    url = "#{engines_library_uri}"
    RestClient.get url
  rescue
    # Try again with invalid ssl
    p "Warning: The library certificate is invalid!"
    RestClient::Request.execute( method: :get, url: url, headers: {}, verify_ssl: false )
  end
end

def engines_library_uri
  ENV['ENERTEQ_LIBRARY_API_URI'] || "http://enerteqapps.engines.org/api/v0/apps"
end

def library_apps
  @@library_apps ||= apps_from_schema(JSON.parse(apps_json))
end

def apps_from_schema(library_apps_hash)
  return schema_0_1_apps(library_apps_hash) if library_apps_hash['schema'] == '0.1'
  p "Missing valid :schema #{library_apps_hash}"
  []
rescue
  p "Rescued apps_from_schema with [] - #{library_apps_hash}"
  []
end

def schema_0_1_apps(library_apps_hash)
  library_apps_hash['apps'] || []
end

def featured_apps
  library_apps.select{|app| app['featured']}
end

# Helpers

helpers do
  def markdown(text)
    options = {
      filter_html:     true,
      hard_wrap:       true,
      link_attributes: { rel: 'nofollow', target: "_blank" },
      space_after_headers: true,
      fenced_code_blocks: true
    }

    extensions = {
      autolink:           true,
      superscript:        true,
      disable_indented_code_blocks: true
    }

    renderer = Redcarpet::Render::HTML.new(options)
    markdown = Redcarpet::Markdown.new(renderer, extensions)

    markdown.render(text)
  end
end

def html_for(view, opts={})
  p "rendering erb view: #{view}"
  erb view, { layout: :layout }.merge(opts)
end
