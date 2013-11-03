#!/usr/bin/env ruby
#
#

require File.expand_path(File.dirname(__FILE__)+"/"+"lib/utiles_spe.rb")
require 'optparse'
include Utiles_spe
include NumRu
include Math


filename = ARGV[0]
def cp_ncf(file)
  ofile = NetCDF.open("conv_"+file)
  GPhys::IO.var_names(file).each{ |varname|
    gp = gpopen(file,varname)
    ofile.write(gp)
  }
  ofile.close  
end

def search_rankfile(file)
  return Dir.glob(file.sub(".nc","_rank*.nc"))
end

rankfils = search_rankfile(filename)
rankfiles.each do |file| 
  cp_ncf(file)  
end


