#!/usr/bin/env ruby
# -*- coding: utf-8 -*-
# 可降水量
#

require 'numru/ggraph'
require 'numru/gphys'
require File.expand_path(File.dirname(__FILE__)+"/"+"lib/utiles_spe.rb")
include Utiles_spe
include NumRu
include Math


def calc_prcwtr(dir)
  data_name = 'PrcWtr'
  # file open
  begin
    gqv = gpopen(dir + "QVap.nc", "QVap")
    gps = gpopen(dir + "Ps.nc", "Ps")
    sig_weight = gpopen(dir + "QVap.nc", "sig_weight")
  rescue
    print "NOT CREATED [#{data_name}](#{dir}) \n"
    return
  end

  # constant
  grav = UNumeric[9.8, "m.s-2"]

  ofile = NetCDF.create( dir + data_name + '.nc')
  GPhys::NetCDF_IO.each_along_dims_write([gqv,gps], ofile, 'time') { 
    |qvap,ps|  

    qc = qvap * ps * sig_weight
    qc = qc.sum("sig") / grav
    qc.units = 'kg.m-2'
    qc.long_name = 'precipitable water'
    qc.name = data_name

    [qc]
   }
  ofile.close
  print "CREATED [#{data_name}](#{dir}) \n"
end

def calc_prcwtr_rank(dir)
  rank = ["rank000006.nc","rank000004.nc","rank000002.nc","rank000000.nc",
          "rank000001.nc","rank000003.nc","rank000005.nc","rank000007.nc"]
  data_name = 'PrcWtr'
  rank.each do |footer|
    # file open
    begin
      gqv = gpopen(dir + "QVap_" + footer, "QVap")
      gps = gpopen(dir + "Ps_" + footer, "Ps")
      sig_weight = gpopen(dir + "QVap_" + footer, "sig_weight")
    rescue
      print "NOT CREATED [#{data_name}](#{dir}) \n"
      return
    end
  
    # constant
    grav = UNumeric[9.8, "m.s-2"]
  
    ofile = NetCDF.create( dir + data_name + footer)
    GPhys::NetCDF_IO.each_along_dims_write([gqv,gps], ofile, 'time') { 
      |qvap,ps|  
  
      qc = qvap * ps * sig_weight
      qc = qc.sum("sig") / grav
      qc.units = 'kg.m-2'
      qc.long_name = 'precipitable water'
      qc.name = data_name
  
      [qc]
     }
    ofile.close
    print "CREATED [#{data_name}](#{dir}) \n"
  end
end

list = Utiles_spe::Explist.new(ARGV[0])

if ARGV.index("-rank")
  list.dir.each{|dir| calc_prcwtr_rank(dir)}
else
  list.dir.each{|dir| calc_prcwtr(dir)}
end
