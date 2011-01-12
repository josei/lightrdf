module RDF
  class Repository
    include MonitorMixin
    include Parser  
  
    def initialize(r_opt={})
      super()
      
      # Assigns the default value to the nil options.
      @options = {"host"=>"http://localhost", "port"=>"8080", "repo"=>"men-ses", "time"=>"15", "format"=>"ntriples"}.merge(r_opt)
    end
    
    # Extracts the data in sesame from the indicated repositories
    def get_data(contexts=["all"])
      synchronize do
      
        # Prepares the URL to request the data
        context = contexts.map{|context| "context=#{context}"}*"&&"
        dir = "#{@options["host"]}:#{@options["port"]}/openrdf-sesame/repositories/#{@options["repo"]}/statements?#{context}"

        # Asks for the data
        ntriples = RestClient.get dir, :content_type=>select_type

        # Makes the graph to return.
        Parser.parse(:rdf, ntriples)
      end
	 	end

	  # Gets the list of the sesame contexts
    def get_context
      synchronize do
        # The URL to get the context list from sesame
        dir = "#{@options["host"]}:#{@options["port"]}/openrdf-sesame/repositories/#{@options["repo"]}/contexts"

        # Asks for the context list
        RestClient.get dir, :content_type=>'application/sparql-results+xml'
      end
    end

    # Adds data to sesame without removing the previous data
    def post_data(graph, context="")
      synchronize do
        # Prepares the dir to connect with the repository
        dir = "#{@options["host"]}:#{@options["port"]}/openrdf-sesame/repositories/#{@options["repo"]}/statements?context=%3C#{CGI::escape(context)}%3E"
        data = graph.serialize(:ntriples)

        # Adds the data to Sesame
        RestClient.post dir, data, :content_type=>select_type
      end
    end

    protected

    # Selects the type of data to send to sesame
    def select_type
      case @options["format"]
        when "rdfxml" then 'application/rdf+xml'
        when "ntriples" then 'text/plain'
        when "turtle" then 'application/x-turtle'
        when "n3" then 'text/rdf+n3'
        when "trix" then 'application/trix'
        when "trig" then 'application/x-trig'
        else 'Unknown'
      end
    end
  end
end
