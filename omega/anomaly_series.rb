#!/usr/bin/ruby
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

class Anomaly << Explist
  def ref_data
    @ref_data = gpopen list.dir[list.refnum]+data_name+".nc",data_name
    if @result.nil?
      print "Refarence file is not exist [#{list.dir[list.refnum]}](#{var_name})\n"
    end
  end

  def sample_data
    @sample_data = gpopen list.dir + data_name + ".nc", data_name
  end

  def del(data_name,list)
    anomaly = []
    list.dir.each do |n|
      anomaly << @ref_data - @gp
    end
    return anomaly
  end

end



opt = OptionParser.new
opt.on("-r","--rank") {Flag_rank = true}
opt.on("--ps") { IWS = 2}
opt.on("--png") { 
  DCL::swlset('lwnd',false)
  IWS = 4
}

anml = anomaly("Temp",list)
anml.each{|gp| Omega.lonlat(gp,list)}
