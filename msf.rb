#!/usr/bin/env ruby
# -*- coding: utf-8 -*-
# stream function
# 質量流線関数
#

require 'numru/ggraph'
require 'numru/gphys'
require File.expand_path(File.dirname(__FILE__)+"/lib/dcpam.rb")
require "optparse"
include Utiles
include NumRu
include Math


def calc_msf_local_time_mean(list)
  data_name = 'Strm'
  list.dir.each_index do |n|
    # file open
    gv = gpopen list.dir[n] + "V.nc"
    gps = gpopen list.dir[n] + "Ps.nc"
    sigm = gpopen list.dir[n] + "V.nc", "sigm"
    return if gv.nil? or gps.nil? or sigm.nil?

    # 座標データの取得
    lon = gv.axis("lon")
    lat = gv.axis("lat")
    
    if defined? HrInDay
      hr_in_day = HrInDay
    else
      hr_in_day = 24 / omega_ratio(list.name[n])
    end
    
    ave = 0
    GPhys.each_along_dims([gv,gps],'time') do 
      |vwind,ps|  
      #
      msf = calc_msf(vwind,ps,sigm)
      # local time mean
      ave += local_time(msf,hr_in_day)
    end
    
    ave = ave[false,0] if ave.axnames.include?("time")
    ave = ave/gv.axis("time").pos.length
    ofile = NetCDF.create(list.dir[n]+"MTlocal_"+data_name+".nc")
    GPhys::IO.write(ofile, ave)
    ofile.close
    print "[#{data_name}](#{list.dir[n]}) is created \n"
  end
end


opt = OptionParser.new
opt.on("-r","--rank") {Flag_rank = true}
opt.on("-h VAL","--hr_in_day=VAL") {|hr_in_day| HrInDay = hr_in_day.to_i}
opt.parse!(ARGV)
list = Utiles::Explist.new(ARGV[0])
HrInDay = 24 if list.id.include?("coriolis")

if defined? Flag_rank
  calc_msf_local_time_mean(list)
else
  list.dir.each{|dir| calc_msf(dir)}
end

