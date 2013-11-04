#!/usr/bin/env ruby
# -*- coding: undecided -*-
#
#

require File.expand_path(File.dirname(__FILE__)+"/"+"lib/utiles_spe.rb")
require 'optparse'
include Utiles_spe
include NumRu
include Math


filename = ARGV[0]
def cp_ncf(file)
  # GPhys 使用はできない
  # RubyNetCDFを使用すべし
  ofile = NetCDF.create("conv_"+file)
  GPhys::IO.var_names(file).each{ |varname|
    escape =["lon","lat","time","timestr",
             "sig","sigm","flag_rst","datetime",
             "lon_weight","lat_weight","sig_weight"]
    next if escape.include?(varname)
    p varname
    gp = gpopen(file,varname)
    GPhys::IO.write(ofile,gp)
  }
  ofile.close  
end

def search_rankfile(file)
  return Dir.glob(file.sub(".nc","_rank*.nc"))
end

rankfiles = search_rankfile(filename)
rankfiles.each do |file| 
  cp_ncf(file)  
end


