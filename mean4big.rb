#!/usr/bin/ruby
# -*- coding: utf-8 -*-
#  
# 

require 'numru/ggraph'
require 'numru/gphys'
require File.expand_path(File.dirname(__FILE__)+"/"+"lib/utiles_spe.rb")
require 'narray'
require "narray_miss"
include NumRu
include Math


def big_mean(dir,data_name)
  for n in 0..dir.length-1
    begin
      gphys = GPhys::IO.open(dir[n] + data_name + '.nc',data_name)
    rescue
      print "[#{data_name}](#{dir[n]}) is not exist\n"
      next
    end
    ntime = gphys.axis('time').length
    ave = gphys[false,0]
    for i in 1..ntime-1
      ave = ave + gphys[false,i]
    end
    ave = ave/ntime
    ave = ave.mean('lon')
    ofile = NetCDF.create(dir[n] + 'M' + data_name + '.nc')
    GPhys::IO.write(ofile, ave)
    ofile.close
  end
end

def time_mean(dir,data_name)
  for n in 0..dir.length-1
    begin
      gphys = GPhys::IO.open(dir[n] + data_name + '.nc',data_name)
    rescue
      print "[#{data_name}](#{dir[n]}) is not exist\n"
      next
    end
    ntime = gphys.axis('time').length
    ave = 0
    GPhys.each_along_dims(gphys,"time") do |gp|
      ave = ave + gp
    end
    ave = ave/ntime
    ofile2 = NetCDF.create(dir[n] + 'MT' + data_name + '.nc')
    GPhys::IO.write(ofile2, ave)
    ofile2.close
  end
end

def lon_mean(dir,data_name)
  for n in 0..dir.length-1
    begin
      gphys = GPhys::IO.open(dir[n] + data_name + '.nc',data_name)
    rescue
      print "[#{data_name}](#{dir[n]}) is not exist\n"
      next
    end
    ofile2 = NetCDF.create(dir[n] + 'ML' + data_name + '.nc')
    GPhys::NetCDF_IO.each_along_dims_write(gphys, ofile2, 'time') { 
      |sub|  
      subm = sub.mean('lon')
      [submean]
    }
    ofile2.close
  end
end

dir, name = Utiles_spe.explist(ARGV[0])
var_name = ARGV[1]

if ARGV.index('-t') 
  time_mean(dir,var_name)
elsif ARGV.index('-l')
  lon_mean(dir,var_name)
else
  big_mean(dir,var_name)
end

=begin
def time_mean_range(dir,data_name)
  gphys = GPhys::IO.open(dir + 'Up' + data_name + '.nc',data_name)
  rmiss = 0
  ntime = gphys.axis('time').length
  
  ave = NArrayMiss.to_nam(gphys[false,0].to_a,gphys[false,0].gt(rmiss))
  for i in 0..ntime-1
    ave = ave + NArrayMiss.to_nam(gphys[false,i].to_a,gphys[false,i].gt(rmiss))
  end
#  ave = ave/ntime
  ave = ave.mean(0)

  # NArray to GPhys
  gpave = GPhys.new(gphys[0,false,0].grid_copy,VArray.new(ave))
  gpave.name = data_name
  # write file
  ofile2 = NetCDF.create(dir + 'M' + 'Up'+ data_name + '.nc')
  GPhys::IO.write(ofile2, gpave)
  ofile2.close
end

def lon_mean(dir,data_name)
  gphys = GPhys::IO.open(dir + 'Mt' + data_name + '.nc',data_name)
  gphys = gphys.mean('lon')
  ofile2 = NetCDF.create(dir + 'M' + data_name + '.nc')
  GPhys::IO.write(ofile2, gphys)
  ofile2.close
end
=end


