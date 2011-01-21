module RDF
  class Repository
    include MonitorMixin
    include Parser  
  
    def initialize options={}
      super()
      
      # Assigns the default value to the options.
      @options = {:host=>"http://localhost", :port=>8080, :repository=>"memory", :format=>:ntriples}.merge(options)
    end
    
    # Extracts the data in sesame from the indicated repositories
    def data *contexts
      synchronize do
        params = ("?" + contexts.map{|context| "context=%3C#{CGI::escape(context)}%3E"}*"&&" if contexts.empty?)

        # Prepares the URL to request the data
        url = "#{repository_statements_url(@options[:repository])}?#{params}"

        # Asks for the data
        ntriples = RestClient.get url, :content_type=>content_type

        # Builds the graph
        Parser.parse :rdf, ntriples
      end
	 	end

	  # Gets the list of the sesame contexts
    def contexts
      synchronize do
        # The URL to get the context list from sesame
        url = "#{repository_url(@options[:repository])}/contexts"

        # Asks for the context list and parses it
        Nokogiri::XML( RestClient.get(url, :content_type=>'application/sparql-results+xml') ).search(:uri).map(&:text)
      end
    end

    # Adds data to sesame without removing the previous data
    def data= *args
      synchronize do
        # Retrieve arguments
        graph, context = if args.first.is_a?(Array)
            [args.first.first, args.first.last]
          else
            [args.first, ""]
          end
        
        # Prepares the dir to connect with the repository
        url = "#{repository_statements_url(@options[:repository])}?context=%3C#{CGI::escape(context)}%3E"
        data = graph.serialize :ntriples

        # Adds the data to Sesame
        RestClient.post url, data, :content_type=>content_type
      end
    end

    protected

    # Selects the type of data to send to sesame
    def content_type
      case @options[:format].to_sym
        when :rdfxml   then 'application/rdf+xml'
        when :ntriples then 'text/plain'
        when :turtle   then 'application/x-turtle'
        when :n3       then 'text/rdf+n3'
        when :trix     then 'application/trix'
        when :trig     then 'application/x-trig'
      end
    end
    
    def repositories_url
      "#{@options[:host]}:#{@options[:port]}/openrdf-sesame/repositories"
    end
    
    def repository_url repository
      "#{repositories_url}/#{repository}"
    end
    
    def repository_statements_url repository
      "#{repository_url(repository)}/statements"
    end
  end
end
