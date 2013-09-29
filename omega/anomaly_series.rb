#!/usr/bin/env ruby
# -*- coding: utf-8 -*-
# 実験シリーズの偏差
# A-C, A-D
#

require 'numru/ggraph'
require 'numru/gphys'
require File.expand_path(File.dirname(__FILE__)+"/utiles_omega.rb")
require 'optparse'
include Utiles_spe
include NumRu
include Math


class Anomaly
  def initialize(data_name,list)
    @list = list
    @data_name = data_name
    get_refdata
    get_anomaly
  end

  def get_refdata
    @@ref_data = gpopen @list.dir[@list.refnum]+@data_name+".nc"
    if @@ref_data.nil?
      print "Refarence file is not exist [#{@list.dir[list.refnum]}](#{@data_name})\n"
    end
  end

  def get_anomaly
    result = []
    @list.dir.each do |dir|
      gp = gpopen dir + @data_name+".nc" 
      if gp.nil? then
        result << nil
      else
        result << gp - @@ref_data
      end
    end
    @anomaly = result
  end

  public
  attr_reader :list, :data_name, :anomaly
end

def delt(gpa1,gpa2)
  result = []
  gpa1.anomaly.each_index{|n|
    gp1 = gpa1.anomaly[n]
    n2 = gpa2.list.name.index(gpa1.list.name[n])
    next if n2.nil
    gp2 = gpa2.anomaly[n2]
    result << gp2 - gp1
  }
  return result
end

def fig_lonlat_anml(var_name,lists)
  all = Anomaly.new(var_name,lists["all"])
  diurnal = Anomaly.new(var_name,lists["diurnal"])
  coriois = Anomaly.new(var_name,lists["coriolis"])
  delt(all,diurnal).each{|gp| Omega.lonlat(gp,list,hash)}
  delt(all,coriolis).each{|gp| Omega.lonlat(gp,list,hash)}
end



opt = OptionParser.new
opt.on("-r","--rank") {Flag_rank = true}
opt.on("--ps") { IWS = 2}
opt.on("--png") { 
  DCL::swlset('lwnd',false)
  IWS = 4
}
a_list = "/home/ishioka/link/all/fig/list/omega_all_MTlocal.list"
d_list = "/home/ishioka/link/diurnal/fig/list/omega_diurnal_MTlocal.list"
c_list = "/home/ishioka/link/coriolis/fig/list/omega_coriolis_MTlocal.list"

lists={
  "all"=>Utiles::Explist.new(a_list),
  "diurnal"=>Utiles::Explist.new(d_list),
  "coriolis"=>Utiles::Explist.new(c_list)
}

fig_lonlat_anml("Temp",lists)
