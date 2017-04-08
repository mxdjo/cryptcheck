require 'timeout'

module CryptCheck
	module Tls
		class AnalysisFailure
			attr_reader :error

			def initialize(error)
				@error = error
			end

			def to_s
				@error.to_s
			end
		end

		class TooLongAnalysis < AnalysisFailure
			def initialize
				super "Too long analysis (max #{Host::MAX_ANALYSIS_DURATION.humanize})"
			end
		end

		class Host
			MAX_ANALYSIS_DURATION = 600

			attr_reader :servers, :error

			def initialize(hostname, port)
				@hostname, @port = hostname, port

				first    = true
				@servers = resolve.collect do |args|
					_, ip, _, _ = args
					first ? (first = false) : Logger.info { '' }
					result = begin
						server = ::Timeout.timeout MAX_ANALYSIS_DURATION do
							server(*args)
						end
						grade server
					rescue Engine::TLSException, Engine::ConnectionError, Engine::Timeout => e
						AnalysisFailure.new e
					rescue ::Timeout::Error
						TooLongAnalysis.new
					end
					[[@hostname, ip, @port], result]
				end.to_h
			# rescue StandardError
			# 	raise
			rescue => e
				@error = e
			end

			def to_h
				target = {
						target: { hostname: @hostname, port: @port },
				}
				if @error
					target[:error] = @error
				else
					target[:hosts] = @servers.collect do |host, grade|
						hostname, ip, port = host
						host               = {
								hostname: hostname,
								ip:       ip,
								port:     port
						}
						case grade
							when Grade
								host[:analysis] = grade.server.to_h
								host[:status]   = grade.to_h
							else
								host[:error] = grade.message
						end
						host
					end
				end
				target
			end

			private
			def resolve
				begin
					ip = IPAddr.new @hostname
					return [[nil, ip.to_s, ip.family]]
				rescue IPAddr::InvalidAddressError
				end
				::Addrinfo.getaddrinfo(@hostname, nil, nil, :STREAM)
						.collect { |a| [@hostname, a.ip_address, a.afamily, @port] }
			end

			def server(*args)
				TcpServer.new *args
			end

			def grade(server)
				Grade.new server
			end
		end
	end
end