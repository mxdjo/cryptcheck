#!/usr/bin/env ruby
$:.unshift File.expand_path File.join File.dirname(__FILE__), '../lib'
require 'rubygems'
require 'bundler/setup'
require 'logging'
require 'cryptcheck'

name = ARGV[0]
if name
	::CryptCheck::Logger.level = :info
	server = ::CryptCheck::Tls::Smtp::Server.new(ARGV[0], ARGV[1] || 25)
	grade = ::CryptCheck::Tls::Smtp::Grade.new server
	::CryptCheck::Logger.info { '' }
	grade.display
else
	::CryptCheck::Logger.level = :none
	::CryptCheck::Tls::Smtp.analyze_from_file 'output/smtp.yml', 'output/smtp.html'
end


