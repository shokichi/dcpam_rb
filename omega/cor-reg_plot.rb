#!/usr/bin/ruby
# -*- coding: utf-8 -*-
#
#

require 'numru/ggraph'
require 'numru/gphys'
require File.expand_path(File.dirname(__FILE__)+"/utiles_omega.rb")
require 'optparse'
require 'csv'
include Utiles_spe
include NumRu
include Math

opt = OptionParser.new
opt.on("-r","--rank") {Flag_rank = true}
opt.on("--cor=FILE") {|file| CorFile = file}
opt.on("--reg=FILE") {|file| RegFile = file}
opt.on("--ps") { IWS = 2}
opt.on("--png") { 
  DCL::swlset('lwnd',false)
  IWS = 4
}
opt.parse!(ARGV)

cor = CVS.table(CorFile,col_sep:"\t")
reg = CVS.table(RegFile,col_sep:"\t")

omega = cor[:rotation_rate]
legend = 14

# DCL set
IWS = 1 if !defined?(IWS)
clrmp = 14  # カラーマップ
DCL.sgscmn(clrmp)
DCL.gropn(IWS)
# DCL.sldiv('Y',2,1)
DCL.sgpset('lcntl',true)
DCL.sgpset('isub', 96)
DCL.uzfact(0.9) # 文字の大きさ

GGraph.set_fig('window'=>[0.01,10,0,1])

[:d, :c, :dc].each do |key|
  coef = Utiles_spe.array2gp(omega,cor[key])
  size = reg[key]
  plot(coef,size,legend)
  legend += 1
end

def plot(gp,size,legend)
  omega = gp.axis(0).to_gphys
  gp.length.times do |n|
    figopt ={"legend"=>legend,"size"=>size[n]*0.1+0.01,"type"=>6}
    if !Flag_init
      GGraph.scatter omega[n..n],gp[n..n],true,figopt
    else
      GGraph.scatter omega[n..n],gp[n..n],false,figopt
    end
  end
end
 
DCL.grcls
rename_img_file("",__FILE__)
