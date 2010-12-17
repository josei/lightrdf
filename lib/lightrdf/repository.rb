module RDF
  class Repository
    include MonitorMixin
    include Parser  
  
    def initialize
      super()

      r_opt = {}
      # Looks for a configuration file in ~/.lightrdf
      r_opt = YAML::load_file("#{ENV["HOME"]}/.scrappy/config.yml") if File.exist?("#{ENV["HOME"]}/.lightrdf/config.yml")
      
      # Assigns the default value to the nil options.
      @options = {"host"=>"http://localhost", "port"=>"8080", "repo"=>"men-ses", "time"=>"15", "format"=>"ntriples"}.merge(r_opt)
    end
    
    # Extracts the data in sesame from the indicated repositories
    def get_data(contexts)
      synchronize do
      
        # Prepares the URL to request the data
        dir = "#{@options["host"]}:#{@options["port"]}/openrdf-sesame/repositories/#{@options["repo"]}/statements?#{prepare_req_contexts(contexts)}"

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
    def post_data(graph, context)
      synchronize do
        # Prepares the dir to connect with the repository
        dir = "#{@options["host"]}:#{@options["port"]}/openrdf-sesame/repositories/#{@options["repo"]}/statements?context=%3C#{CGI::escape(context)}%3E"
        data = graph.serialize(:ntriples)

        # Adds the data to Sesame
        RestClient.post dir, data, :content_type=>select_type
      end
    end

    protected

    # Makes the contexts to add to the request
    def prepare_req_contexts(contexts)
      result = ""
      if contexts[0] != nil
        i = 0
        while i < contexts.length
          result += "context=#{contexts[i]}"
          i += 1
          result += "&&" if i != contexts.length
        end
      end
      return result
    end

    # Selects the type of data to send to sesame
    def select_type
      type = case
        when @options["format"] == "rdfxml" then 'application/rdf+xml'
        when @options["format"] == "ntriples" then 'text/plain'
        when @options["format"] == "turtle" then 'application/x-turtle'
        when @options["format"] == "n3" then 'text/rdf+n3'
        when @options["format"] == "trix" then 'application/trix'
        when @options["format"] == "trig" then 'application/x-trig'
        else 'Unknown'
      end
      return type
    end
  end
end
