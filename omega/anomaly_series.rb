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

class anomaly
  def del(data_name,list)
    gp_ref = gpopen list.dir[list.refnum]+data_name+".nc",data_name
    if gp_ref.nil?
      print "Refarence file is not exist [#{list.dir[list.refnum]}](#{var_name})\n"
      return
    end
    anomaly = []
    list.dir.each do |n|
      gp = gpopen list.dir + data_name + ".nc", data_name
      next if gp.nil?
      anomaly << gp_ref - gp
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
