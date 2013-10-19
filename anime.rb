#!/usr/bin/env ruby
# -*- coding: utf-8 -*-
# 動画作成
# make animation
#
require "numru/ggraph"
require File.expand_path(File.dirname(__FILE__)+"/lib/make_figure.rb")
require 'optparse'
include MKfig
include NumRu


def tone_draw(gp,name,figopt={})
  intval = 6
  (gp.axis("time").length/intval).to_i.times do |n| 
    figopt["title"] = gp.name + name
    figopt["keep"] = true if n != 0
    GGraph.tone gp[false,n*intval], true, figopt
  end
end

def line_draw(gp,name,figopt={})
  intval = 6
  gp.axis("time").length/intval.to_i.times do |n| 
    figopt["keep"] = true if n != 0
    GGraph.tone gp[false,n*intval], true, figopt
  end
end

def convert_img(filename) # 画像結合
  dt = 17.6
  dt = Delay if defined?(Delay)
  Dir::mkdir("movie") if !Dir::entries("./").include?("movie")
  `mv dcl_*.png movie/`
  `mogrify -format gif movie/*.png`
  `convert -delay #{dt} movie/dcl_*.gif movie/#{filename}.gif`
  `rm movie/dcl_*.gif movie/dcl_*.png`
end

def make_movie(varname,list)
#  if defined?(FigOpt)
#    figopt = FigOpt
#  else
#    figopt = {"min"=>0,"max"=>2000,"nlev"=>40}
#  end

  figopt = {"min"=>-5e-7,"max"=>5e-7,"nlev"=>40,"color_bar"=>true}
  # DCL
  clrmp = 14  # カラーマップ
  DCL.sgscmn(clrmp)
  DCL::swlset('lwnd',false)
  #DCL.swpset('lalt',true) if save == false

  list.dir.each_index{|n|
    filename = varname+".nc"
    filename = FileName if defined?(FileName)
    gp = gpopen list.dir[n] + filename,varname
    next if gp.nil?

    hr_in_day = 24 / omega_ratio(list.name[n])
    hr_in_day = 24 if list.id.include?("coriolis")
    gp = cut_and_mean(gp,hr_in_day)

    # DCL
    DCL.gropn(4)
    DCL.sgpset('lcntl',false)
    #DCL.sgpset('lfull',true)
    DCL.uzfact(0.7)
    #DCL.sldiv('Y',1,2) 
    #DCL::gllset('LMISS', true)
    #DCL::glrget('RMISS')
    #rmiss = DCL.glpget('rmiss')

    # GGraph
    if defined?(Flag_line)
      line_draw(gp,list.name[n],figopt)
    else
      tone_draw(gp,list.name[n],figopt)
    end
    DCL.grcls
    ofilen = list.id+"_"+File.basename(__FILE__,".rb")+"_"+
                                    list.name[n]+"_"+varname
    convert_img(ofilen)
    print "[#{varname}](#{list.dir[n]})::#{__FILE__} is created\n"
  }
end

def omega_ratio(name)# 名前解析 nameからomega/omega_Eを抽出
  if name[0..4] == "omega" or name[0..4] == "Omega" then
    var = name.sub("omega","").sub("Omega","")
    if var.include?("-")
      var = var.split("-")
      var = var[1].to_f/var[0].to_f
    elsif var.include?("/")
      var = var.split("/") 
      var = var[0].to_f/var[1].to_f
    end
    ratio = var.to_f
  else
    print "ERROR: [#{name}] can't decode\n"
    ratio = 1.0
  end
  return ratio
end

def cut_and_mean(gp,hr_in_day)
  gp = gp[false,0..6*24*5]
  gp = gp.cut("lat"=>0)
#  gp = local_time(gp,hr_in_day)
  return gp
end

# option
opt = OptionParser.new
opt.on("-r","--rank") {Flag_rank = true}
opt.on("-n VAR","--name=VAR") {|name|
  char = name.split("@")
  VarName = char[-1]
  FileName = char[0] if char.size == 2 }
opt.on("-o OPT","--figopt=OPT") {|hash| Figopt = hash}
opt.on("--line"){Flag_line = true}
opt.parse!(ARGV)

list = Utiles_spe::Explist.new(ARGV[0])
varname = "Rain"
varname = VarName if defined?(VarName)

make_movie(varname,list)

